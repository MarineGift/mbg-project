/**
 * lib/actions/communications.ts
 *
 * Outbound 메일 수동 발송 Server Action.
 * TABS Mailer를 사용해 SMTP 발송 + communications 행 기록.
 *
 * 흐름:
 *   1. user의 sending_email 확인
 *   2. communications INSERT (status='sending')
 *   3. createEmailTracking() → injectedHtml 획득 (픽셀 + 추적 링크)
 *   4. tabs-mailer.sendOne(bodyHtml: injectedHtml) → message-id 획득
 *   5. communications UPDATE (status='sent', message_id, sent_at)
 *   6. 실패 시 status='failed' + error_message
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { sendOutboundEmail } from '@/lib/email/send-outbound';
import type { SendingAddressKind } from '@/types/email';

/* ──────────────────────────────────────────────────────────
 * Plain text → HTML 변환 (픽셀 삽입을 위한 최소 변환)
 * ────────────────────────────────────────────────────────── */

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * plain text를 최소한의 HTML로 변환.
 * 빈 줄은 단락 구분, 일반 줄은 <p> 태그로 감싼다.
 */
function plainToHtml(text: string): string {
  const lines = text.split('\n');
  const parts: string[] = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === '') {
      parts.push('<br>');
    } else {
      parts.push(
        `<p style="margin:0 0 8px 0">${escapeHtml(trimmed)}</p>`,
      );
    }
  }
  return (
    `<div style="font-family:sans-serif;font-size:14px;line-height:1.6;color:#333">` +
    parts.join('\n') +
    `</div>`
  );
}

/* ──────────────────────────────────────────────────────────
 * 결과 타입 + 입력 스키마
 * ────────────────────────────────────────────────────────── */

export interface ComposeResult {
  ok: boolean;
  errorCode?:
    | 'unauthorized'
    | 'validation'
    | 'no_sending_email'
    | 'send_failed'
    | 'database'
    | 'not_whitelisted'
    | 'not_found';
  errorMessage?: string;
  /** 성공 시 outbound communications row id */
  communicationId?: string;
}

const composeSchema = z.object({
  to: z.string().email('Invalid recipient email').max(255),
  cc: z.string().max(2000).optional().or(z.literal('')),
  subject: z.string().min(1, 'Subject is required').max(500),
  bodyPlain: z.string().min(1, 'Body is required').max(50_000),
  /** 리치 텍스트 에디터가 있는 경우 HTML 직접 전달 가능 (없으면 bodyPlain → 자동 변환) */
  bodyHtml: z.string().max(200_000).optional().nullable(),
  /** 거래처 연결 (있으면 communications.party_id에 저장) */
  partyId: z.string().uuid().optional().nullable(),
  contactId: z.string().uuid().optional().nullable(),
  /** 새로운 thread 시작 — null이면 자동 생성된 message-id가 thread 시작 */
  inReplyTo: z.string().max(500).optional().nullable(),
  threadId: z.string().max(500).optional().nullable(),
  /** D6-7b-2: which sending account to send from (default: shared = contact@) */
  fromKind: z.enum(['personal', 'role', 'shared']).optional().default('shared'),
  attachments: z
    .array(
      z.object({
        path: z.string().max(500),
        filename: z.string().max(255),
        size: z.number().int().nonnegative(),
        mimeType: z.string().max(255),
      }),
    )
    .optional()
    .default([]),
});

/* ──────────────────────────────────────────────────────────
 * sendOutboundManual
 * ────────────────────────────────────────────────────────── */


/* ============================================================
 * D6-7b-2: kind-aware sender info resolution
 * ============================================================ */
type SenderInfo = { username: string; displayName: string };

function resolveSenderInfoForKind(kind: SendingAddressKind): SenderInfo {
  switch (kind) {
    case 'personal':
      return {
        username:    process.env.MAIL_PERSONAL_USERNAME ?? '',
        displayName: process.env.MAIL_PERSONAL_DISPLAY_NAME ?? 'YunYoung Heo',
      };
    case 'role':
      return {
        username:    process.env.MAIL_ROLE_USERNAME ?? '',
        displayName: process.env.MAIL_ROLE_DISPLAY_NAME ?? 'CEO',
      };
    case 'shared':
    default:
      return {
        username:    process.env.MAIL_SHARED_USERNAME ?? '',
        displayName: process.env.MAIL_SHARED_DISPLAY_NAME ?? 'Marinebio Group',
      };
  }
}
export async function sendOutboundManual(
  input: z.input<typeof composeSchema>,
): Promise<ComposeResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = composeSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // From identity (kind-aware; env MAIL_* with user-row fallback).
  const { data: userRaw } = await supabase
    .schema('app')
    .from('users' as never)
    .select('sending_email, full_name, email')
    .eq('id', auth.userId)
    .maybeSingle();
  const userRow = userRaw as
    | { sending_email: string | null; full_name: string; email: string }
    | null;

  const kind: SendingAddressKind = parsed.data.fromKind ?? 'shared';
  const senderInfo = resolveSenderInfoForKind(kind);
  const fromAddress =
    senderInfo.username || (userRow?.sending_email ?? userRow?.email ?? auth.email);
  const fromName =
    senderInfo.displayName || (userRow?.full_name ?? auth.email.split('@')[0] ?? 'Sender');

  const ccAddresses = (parsed.data.cc ?? '')
    .split(/[,;]/)
    .map((s) => s.trim())
    .filter((s) => /\S+@\S+\.\S+/.test(s));

  // Delegate to the shared outbound core (Stage B). Whitelist, tracking,
  // insert(sending), sendOne, sent/failed update and attachment records all
  // live in the core now. Manual compose exposes no template/signature.
  const result = await sendOutboundEmail({
    supabase,
    organizationId: auth.organizationId,
    sentByUserId: auth.userId,
    to: parsed.data.to,
    cc: ccAddresses,
    fromName,
    fromAddress,
    sendingAddressKind: kind,
    subject: parsed.data.subject,
    bodyHtml: parsed.data.bodyHtml?.trim()
      ? parsed.data.bodyHtml
      : plainToHtml(parsed.data.bodyPlain),
    bodyText: parsed.data.bodyPlain,
    useSignature: false,
    inReplyTo: parsed.data.inReplyTo ?? undefined,
    references: parsed.data.inReplyTo ? [parsed.data.inReplyTo] : undefined,
    partyId: parsed.data.partyId ?? null,
    contactId: parsed.data.contactId ?? null,
    threadId: parsed.data.threadId ?? null,
    attachments: parsed.data.attachments ?? [],
    traceLabel: `manual-compose:${auth.userId}`,
  });

  revalidatePath('/inbox');
  if (parsed.data.partyId) {
    revalidatePath(`/`, 'layout');
  }

  if (!result.ok) {
    const errorCode: ComposeResult['errorCode'] =
      result.errorCode === 'not_whitelisted'
        ? 'not_whitelisted'
        : result.errorCode === 'database'
          ? 'database'
          : 'send_failed';
    return { ok: false, errorCode, errorMessage: result.errorMessage };
  }

  return { ok: true, communicationId: result.communicationId };
}
