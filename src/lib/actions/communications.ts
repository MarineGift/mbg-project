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
import { createTabsMailer } from '@/lib/email/tabs-mailer';
import type { SendingAddressKind } from '@/types/email';
import { createEmailTracking } from '@/lib/actions/email-tracking';

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

  // 사용자 발신 자격 조회
  const { data: userRaw } = await supabase
    .schema('app')
    .from('users' as never)
    .select('sending_email, full_name, email')
    .eq('id', auth.userId)
    .maybeSingle();

  const userRow = userRaw as
    | { sending_email: string | null; full_name: string; email: string }
    | null;
  // D6-7b-2: kind-aware From determination
  const kind: SendingAddressKind = parsed.data.fromKind ?? 'shared';
  const senderInfo = resolveSenderInfoForKind(kind);
  const fromAddress = senderInfo.username    || (userRow?.sending_email ?? userRow?.email ?? auth.email);
  const fromName    = senderInfo.displayName || (userRow?.full_name ?? auth.email.split('@')[0] ?? 'Sender');

  // cc 파싱
  const ccAddresses = (parsed.data.cc ?? '')
    .split(/[,;]/)
    .map((s) => s.trim())
    .filter((s) => /\S+@\S+\.\S+/.test(s));

  // [A] outbound communications INSERT (status='sending')
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    channel: 'email',
    direction: 'outbound',
    party_id: parsed.data.partyId || null,
    contact_id: parsed.data.contactId || null,
    from_address: fromAddress,
      sendingAddressKind: kind,  // D6-7b-2: kind-aware SMTP credential selection
    from_name: fromName,
    to_addresses: [parsed.data.to],
    cc_addresses: ccAddresses,
    subject: parsed.data.subject,
    body_plain: parsed.data.bodyPlain,
    thread_id: parsed.data.threadId || null,
    in_reply_to: parsed.data.inReplyTo || null,
    status: 'sending',
    ai_generated: false,
    occurred_at: new Date().toISOString(),
    sent_by_user_id: auth.userId,
  };

  const { data: insertData, error: insertError } = await supabase
    .schema('app')
    .from('communications' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (insertError || !insertData) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: insertError?.message ?? 'Insert failed',
    };
  }
  const outboundId = (insertData as { id: string }).id;

  // [B] TABS Mailer 발송
  try {
    // ── [B-1] 이메일 추적 레코드 생성 + HTML 픽셀 주입 ──────────────
    // bodyHtml이 직접 전달되면 그것을 사용, 없으면 bodyPlain → HTML 변환
    const baseHtml = parsed.data.bodyHtml?.trim()
      ? parsed.data.bodyHtml
      : plainToHtml(parsed.data.bodyPlain);

    let injectedHtml: string = baseHtml;
    try {
      const trackingResult = await createEmailTracking({
        orgId:           auth.organizationId,
        communicationId: outboundId,
        partyId:         parsed.data.partyId  ?? undefined,
        contactId:       parsed.data.contactId ?? undefined,
        subject:         parsed.data.subject,
        sentTo:          parsed.data.to,
        htmlBody:        baseHtml,
      });
      injectedHtml = trackingResult.injectedHtml;
    } catch (trackingErr) {
      // 추적 실패 시 발송은 계속 진행 (non-blocking)
      console.warn('[communications] tracking setup failed:', trackingErr);
    }

    // ── [B-2] TABS Mailer 발송 ──────────────────────────────────────
    const mailer = await createTabsMailer();
    const sendResult = await mailer.sendOne({
      to: { address: parsed.data.to },
      cc: ccAddresses.map((a) => ({ address: a })),
      fromName,
      fromAddress,
      subject: parsed.data.subject,
      bodyText: parsed.data.bodyPlain,   // plain text (fallback)
      bodyHtml: injectedHtml,            // HTML with tracking pixel ← NEW
      urmHeaders: {
        communicationId: outboundId,
        autoSend: false,
      },
      traceLabel: `manual-compose:${auth.userId}`,
    });

    // [C] communications 갱신 — message_id + sent_at + status='sent'
    await supabase
      .schema('app')
      .from('communications' as never)
      .update({
        message_id: sendResult.messageId,
        status: 'sent',
        sent_at: sendResult.sentAt,
      } as never)
      .eq('id', outboundId)
      .eq('organization_id', auth.organizationId);

    revalidatePath('/inbox');
    if (parsed.data.partyId) {
      revalidatePath(`/`, 'layout');
    }
    return { ok: true, communicationId: outboundId };
  } catch (e) {
    const errMsg = e instanceof Error ? e.message : String(e);
    await supabase
      .schema('app')
      .from('communications' as never)
      .update({
        status: 'failed',
        error_message: errMsg,
      } as never)
      .eq('id', outboundId)
      .eq('organization_id', auth.organizationId);

    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: errMsg,
    };
  }
}
