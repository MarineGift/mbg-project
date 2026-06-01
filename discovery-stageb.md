===== C:\dev\mbg-project\src\lib\actions\communications.ts =====
```ts
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

  // [whitelist] 2a: enforce recipient whitelist (parity with dialog sendEmail).
  // Checks 'to' against active app.email_whitelist patterns by exact address OR
  // domain. Fail fast before any DB writes. (cc not checked - decision 2a.)
  const toDomain = parsed.data.to.split('@')[1]?.toLowerCase();
  if (toDomain) {
    const { data: wlRows, error: wlErr } = await supabase
      .schema('app')
      .from('email_whitelist' as never)
      .select('id')
      .eq('organization_id', auth.organizationId)
      .eq('is_active', true)
      .in('pattern', [toDomain, parsed.data.to.toLowerCase()])
      .limit(1);
    if (wlErr) {
      return {
        ok: false,
        errorCode: 'database',
        errorMessage: `Whitelist lookup failed: ${wlErr.message}`,
      };
    }
    if (!wlRows || (wlRows as unknown[]).length === 0) {
      return {
        ok: false,
        errorCode: 'not_whitelisted',
        errorMessage: `Recipient not in whitelist: ${parsed.data.to}`,
      };
    }
  }

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
    // resolve outbound attachments from storage (download -> Buffer for nodemailer)
    const mailAttachments: { filename: string; content: Buffer; contentType?: string }[] = [];
    for (const att of parsed.data.attachments ?? []) {
      const { data: fileData, error: dlErr } = await supabase.storage
        .from('email-attachments')
        .download(att.path);
      if (dlErr || !fileData) {
        console.error('[communications] attachment download failed:', att.path, dlErr);
        continue;
      }
      mailAttachments.push({
        filename: att.filename || (att.path.split('/').pop() ?? 'attachment'),
        content: Buffer.from(await fileData.arrayBuffer()),
        contentType: att.mimeType || undefined,
      });
    }

    const mailer = await createTabsMailer();
    const sendResult = await mailer.sendOne({
      to: { address: parsed.data.to },
      cc: ccAddresses.map((a) => ({ address: a })),
      fromName,
      fromAddress,
      subject: parsed.data.subject,
      bodyText: parsed.data.bodyPlain,   // plain text (fallback)
      bodyHtml: injectedHtml,            // HTML with tracking pixel ← NEW
      inReplyTo: parsed.data.inReplyTo ?? undefined,
      references: parsed.data.inReplyTo ? [parsed.data.inReplyTo] : undefined,
      urmHeaders: {
        communicationId: outboundId,
        autoSend: false,
      },
      attachments: mailAttachments,
      sendingAddressKind: kind,  // D6-7b-2: kind-aware SMTP credential selection
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

    if (parsed.data.attachments && parsed.data.attachments.length > 0) {
      const attachmentRows = parsed.data.attachments.map((m) => ({
        organization_id: auth.organizationId,
        entity_type: 'communication',
        entity_id: outboundId,
        file_name: m.filename,
        file_size_bytes: m.size ?? 0,
        mime_type: m.mimeType || 'application/octet-stream',
        storage_provider: 'supabase',
        storage_bucket: 'email-attachments',
        storage_path: m.path,
      }));
      const { error: attErr } = await supabase
        .schema('app')
        .from('attachments' as never)
        .insert(attachmentRows as never);
      if (attErr) console.error('[communications] attachment record error:', attErr);
    }

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

```

===== C:\dev\mbg-project\src\lib\actions\drafts.ts =====
```ts
/**
 * lib/actions/drafts.ts
 *
 * AI 초안 검토 화면의 Server Actions.
 *
 * 보안·통합 원칙:
 *   - 모든 액션 첫 줄에 requireAuth() 호출
 *   - RLS가 organization_id로 자동 격리 (별도 .eq 필요하지 않지만 명시적으로도 추가)
 *   - status 검증: pending_review 한정 approve/reject/edit 가능
 *   - audit 로그는 DB 트리거로 자동
 *
 * 발송 전략 (Phase 1):
 *   - approveDraft({ sendImmediately: true })   → 즉시 동기 SMTP 발송
 *   - approveDraft({ sendImmediately: false })  → status='approved'만, 발송은 추후 처리
 *   - bulkApproveDrafts(ids)                    → 일괄 'approved'만, 발송 안 함 (안전성)
 *
 * 발신 주소 (Step 1.2):
 *   - sendingAddressKind: 'personal' | 'role' | 'shared'
 *   - 사용자의 email_personal / email_role / email_shared 컬럼에서 From 결정
 *   - tabs-mailer가 같은 kind 자격증명으로 SMTP 인증 (SPF/DKIM 일관성)
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createTabsMailer } from '@/lib/email/tabs-mailer';
import type { RejectReason } from '@/types/draft-detail';
import type { SendingAddressKind } from '@/types/email';

/* ============================================================
 * 공용 타입
 * ============================================================ */

export interface ActionResult<T = void> {
  ok: boolean;
  data?: T;
  errorCode?:
    | 'unauthorized'
    | 'not_found'
    | 'invalid_status'
    | 'validation'
    | 'send_failed'
    | 'database'
    | 'unknown';
  errorMessage?: string;
}

export interface BulkActionResult {
  ok: boolean;
  succeeded: string[];
  failed: Array<{ id: string; errorCode: string; errorMessage: string }>;
}

/* ============================================================
 * 1. saveDraftEdits — 본문·제목 편집 저장
 * ============================================================ */

const saveDraftEditsSchema = z.object({
  draftId: z.string().uuid(),
  subject: z.string().min(1).max(500).optional().nullable(),
  bodyPlain: z.string().min(1).max(50_000),
});

export async function saveDraftEdits(input: {
  draftId: string;
  subject?: string | null;
  bodyPlain: string;
}): Promise<ActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = saveDraftEditsSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // 상태 검증 — pending_review만 편집 가능
  const { data: current, error: fetchErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .select('status')
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();

  if (fetchErr || !current) {
    return { ok: false, errorCode: 'not_found' };
  }
  if ((current as { status: string }).status !== 'pending_review') {
    return {
      ok: false,
      errorCode: 'invalid_status',
      errorMessage: 'Draft is not in pending_review status',
    };
  }

  // edit_distance는 013 마이그레이션 트리거가 자동 계산
  const { error: updateErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      final_subject: parsed.data.subject ?? null,
      final_body_plain: parsed.data.bodyPlain,
    } as never)
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId);

  if (updateErr) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: updateErr.message,
    };
  }

  revalidatePath(`/drafts/${parsed.data.draftId}`);
  revalidatePath('/drafts');
  return { ok: true };
}

/* ============================================================
 * 2. approveDraft — 승인 (옵션: 즉시 발송)
 * ============================================================ */

const approveDraftSchema = z.object({
  draftId: z.string().uuid(),
  sendImmediately: z.boolean().default(false),
  sendingAddressKind: z.enum(['personal', 'role', 'shared']).optional(),
});

export async function approveDraft(input: {
  draftId: string;
  sendImmediately?: boolean;
  sendingAddressKind?: SendingAddressKind;
}): Promise<ActionResult<{ sent: boolean; outboundCommunicationId?: string }>> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = approveDraftSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // 현재 상태 + 발송에 필요한 모든 필드 fetch
  const { data, error: fetchErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .select(
      'id, status, subject, final_subject, body_plain, final_body_plain, body_html, inbound_communication_id, party_id',
    )
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();

  if (fetchErr || !data) {
    return { ok: false, errorCode: 'not_found' };
  }
  const row = data as {
    id: string;
    status: string;
    subject: string | null;
    final_subject: string | null;
    body_plain: string;
    final_body_plain: string | null;
    body_html: string | null;
    inbound_communication_id: string | null;
    party_id: string | null;
  };

  if (row.status !== 'pending_review') {
    return {
      ok: false,
      errorCode: 'invalid_status',
      errorMessage: `Draft status is ${row.status}; only pending_review can be approved`,
    };
  }

  // [A] status='approved' 우선 갱신
  const nowIso = new Date().toISOString();
  const { error: approveErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'approved',
      reviewed_by_user_id: auth.userId,
      reviewed_at: nowIso,
    } as never)
    .eq('id', row.id)
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review'); // 동시성 가드 — 다른 요청이 먼저 변경했으면 0행

  if (approveErr) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: approveErr.message,
    };
  }

  // [B] 즉시 발송 안 함 → 종료
  if (!parsed.data.sendImmediately) {
    revalidatePath(`/drafts/${row.id}`);
    revalidatePath('/drafts');
    return { ok: true, data: { sent: false } };
  }

  // [C] 즉시 발송 — 인바운드가 있어야 수신 대상이 결정됨
  if (!row.inbound_communication_id) {
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage:
        'Cannot send: original inbound message is unknown (no inbound_communication_id)',
    };
  }

  // 발송 시도 (선택된 kind 전달)
  const sendResult = await sendApprovedDraft(
    supabase,
    auth,
    row,
    parsed.data.sendingAddressKind,
  );
  if (!sendResult.ok) {
    // status는 'approved' 머무름 — 사용자가 재시도 가능
    return sendResult;
  }

  revalidatePath(`/drafts/${row.id}`);
  revalidatePath('/drafts');
  return {
    ok: true,
    data: {
      sent: true,
      outboundCommunicationId: sendResult.data?.outboundCommunicationId,
    },
  };
}

/* ============================================================
 * 3. rejectDraft — 거부 (사유 preset 4 + 'other')
 * ============================================================ */

const rejectDraftSchema = z.object({
  draftId: z.string().uuid(),
  reason: z.enum(['outdated_request', 'off_topic', 'wrong_tone', 'incorrect_info', 'other']),
  notes: z.string().max(2000).optional(),
});

export async function rejectDraft(input: {
  draftId: string;
  reason: RejectReason;
  notes?: string;
}): Promise<ActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = rejectDraftSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  // review_notes — preset + custom 합쳐서 저장 (DB 컬럼 없음 → Q5 결정 따라)
  const reviewNotes = [
    `[${parsed.data.reason}]`,
    parsed.data.notes?.trim() ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  const supabase = await createSupabaseServerClient();
  const { error, count } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'rejected',
      reviewed_by_user_id: auth.userId,
      reviewed_at: new Date().toISOString(),
      review_notes: reviewNotes,
    } as never)
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review');

  if (error) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error.message,
    };
  }
  // count가 0이면 다른 사람이 이미 처리한 경우 (race)
  if (count === 0) {
    return {
      ok: false,
      errorCode: 'invalid_status',
      errorMessage: 'Draft already processed',
    };
  }

  revalidatePath(`/drafts/${parsed.data.draftId}`);
  revalidatePath('/drafts');
  return { ok: true };
}

/* ============================================================
 * 4. bulkApproveDrafts / bulkRejectDrafts — 일괄 액션
 *    발송은 하지 않음. 안전성 우선.
 *    편집 중인 행(final_body_plain not null)은 제외해야 하지만
 *    호출처(UI)가 이미 제외한 ID 배열만 전달.
 * ============================================================ */

const bulkIdsSchema = z.array(z.string().uuid()).min(1).max(100);

export async function bulkApproveDrafts(
  draftIds: readonly string[],
): Promise<BulkActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return {
      ok: false,
      succeeded: [],
      failed: draftIds.map((id) => ({
        id,
        errorCode: 'unauthorized',
        errorMessage: 'Sign-in required',
      })),
    };
  }

  const parsed = bulkIdsSchema.safeParse(draftIds);
  if (!parsed.success) {
    return {
      ok: false,
      succeeded: [],
      failed: draftIds.map((id) => ({
        id,
        errorCode: 'validation',
        errorMessage: 'Invalid id list',
      })),
    };
  }

  const supabase = await createSupabaseServerClient();
  const nowIso = new Date().toISOString();

  // 단일 UPDATE 로 가능한 행만 변경되고 나머지는 RETURNING으로 확인
  const { data: updated, error } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'approved',
      reviewed_by_user_id: auth.userId,
      reviewed_at: nowIso,
    } as never)
    .in('id', parsed.data as string[])
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review')
    .select('id');

  if (error) {
    return {
      ok: false,
      succeeded: [],
      failed: parsed.data.map((id) => ({
        id,
        errorCode: 'database',
        errorMessage: error.message,
      })),
    };
  }

  const succeededIds = new Set(
    ((updated ?? []) as Array<{ id: string }>).map((r) => r.id),
  );
  const failed = parsed.data
    .filter((id) => !succeededIds.has(id))
    .map((id) => ({
      id,
      errorCode: 'invalid_status',
      errorMessage: 'Already processed or not in pending_review',
    }));

  revalidatePath('/drafts');
  return {
    ok: failed.length === 0,
    succeeded: Array.from(succeededIds),
    failed,
  };
}

const bulkRejectSchema = z.object({
  draftIds: z.array(z.string().uuid()).min(1).max(100),
  reason: z.enum(['outdated_request', 'off_topic', 'wrong_tone', 'incorrect_info', 'other']),
  notes: z.string().max(2000).optional(),
});

export async function bulkRejectDrafts(input: {
  draftIds: readonly string[];
  reason: RejectReason;
  notes?: string;
}): Promise<BulkActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return {
      ok: false,
      succeeded: [],
      failed: input.draftIds.map((id) => ({
        id,
        errorCode: 'unauthorized',
        errorMessage: 'Sign-in required',
      })),
    };
  }

  const parsed = bulkRejectSchema.safeParse({
    draftIds: input.draftIds,
    reason: input.reason,
    notes: input.notes,
  });
  if (!parsed.success) {
    return {
      ok: false,
      succeeded: [],
      failed: input.draftIds.map((id) => ({
        id,
        errorCode: 'validation',
        errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
      })),
    };
  }

  const reviewNotes = [`[${parsed.data.reason}]`, parsed.data.notes?.trim() ?? '']
    .filter(Boolean)
    .join(' ');

  const supabase = await createSupabaseServerClient();
  const { data: updated, error } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'rejected',
      reviewed_by_user_id: auth.userId,
      reviewed_at: new Date().toISOString(),
      review_notes: reviewNotes,
    } as never)
    .in('id', parsed.data.draftIds as string[])
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review')
    .select('id');

  if (error) {
    return {
      ok: false,
      succeeded: [],
      failed: parsed.data.draftIds.map((id) => ({
        id,
        errorCode: 'database',
        errorMessage: error.message,
      })),
    };
  }

  const succeededIds = new Set(
    ((updated ?? []) as Array<{ id: string }>).map((r) => r.id),
  );
  const failed = parsed.data.draftIds
    .filter((id) => !succeededIds.has(id))
    .map((id) => ({
      id,
      errorCode: 'invalid_status',
      errorMessage: 'Already processed or not in pending_review',
    }));

  revalidatePath('/drafts');
  return {
    ok: failed.length === 0,
    succeeded: Array.from(succeededIds),
    failed,
  };
}

/* ============================================================
 * 5. 발송 헬퍼 — Approve & Send
 *    TABS Mailer 호출 + outbound communication INSERT + draft status='sent' 갱신
 *
 *    Step 1.2 변경:
 *    - sendingAddressKind 파라미터 받음
 *    - 사용자 행에서 email_personal/role/shared 컬럼 조회
 *    - kind 기반 fromAddress 결정 (fallback 체인 포함)
 *    - mailer.sendOne 호출 시 sendingAddressKind 전달
 * ============================================================ */

interface DraftSendableRow {
  id: string;
  subject: string | null;
  final_subject: string | null;
  body_plain: string;
  final_body_plain: string | null;
  body_html: string | null;
  inbound_communication_id: string | null;
  party_id: string | null;
}

interface SendApprovedResult
  extends ActionResult<{ sent: boolean; outboundCommunicationId: string }> {}

/**
 * kind 기반 발신 주소 결정.
 * kind가 명시되고 해당 컬럼에 값이 있으면 그것 사용.
 * 그 외엔 fallback 체인: personal → role → shared → sending_email → email → auth.email
 */
function resolveFromAddress(
  kind: SendingAddressKind | undefined,
  userRow: {
    email_personal: string | null;
    email_role: string | null;
    email_shared: string | null;
    sending_email: string | null;
    email: string;
  } | null,
  authEmail: string,
): string {
  if (kind === 'personal' && userRow?.email_personal) return userRow.email_personal;
  if (kind === 'role' && userRow?.email_role) return userRow.email_role;
  if (kind === 'shared' && userRow?.email_shared) return userRow.email_shared;

  return (
    userRow?.email_personal ??
    userRow?.email_role ??
    userRow?.email_shared ??
    userRow?.sending_email ??
    userRow?.email ??
    authEmail
  );
}

async function sendApprovedDraft(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  auth: AuthContext,
  draft: DraftSendableRow,
  sendingAddressKind?: SendingAddressKind,
): Promise<SendApprovedResult> {
  if (!draft.inbound_communication_id) {
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: 'No inbound communication linked',
    };
  }

  // 1. inbound communication 정보 조회 (수신자·thread·subject)
  const { data: inboundRaw } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('from_address, from_name, subject, message_id, thread_id, channel')
    .eq('id', draft.inbound_communication_id)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();

  const inbound = inboundRaw as
    | {
        from_address: string | null;
        from_name: string | null;
        subject: string | null;
        message_id: string | null;
        thread_id: string | null;
        channel: string;
      }
    | null;

  if (!inbound || !inbound.from_address) {
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: 'Inbound recipient address unknown',
    };
  }

  // 2. 현재 사용자의 발신 자격 조회 (3개 kind 컬럼 포함)
  const { data: userRaw } = await supabase
    .schema('app')
    .from('users' as never)
    .select(
      'email, sending_email, full_name, email_personal, email_role, email_shared',
    )
    .eq('id', auth.userId)
    .maybeSingle();
  const userRow = userRaw as
    | {
        email: string;
        sending_email: string | null;
        full_name: string | null;
        email_personal: string | null;
        email_role: string | null;
        email_shared: string | null;
      }
    | null;

  // kind 기반 from 결정 (fallback 체인 포함)
  const fromAddress = resolveFromAddress(sendingAddressKind, userRow, auth.email);
  const fromName = userRow?.full_name ?? auth.email.split('@')[0] ?? 'Sender';

  // 3. 본문·제목 결정 — 편집본 우선
  const finalSubject =
    draft.final_subject ?? draft.subject ?? `Re: ${inbound.subject ?? ''}`;
  const finalBody = draft.final_body_plain ?? draft.body_plain;

  // 4. outbound communication 행 미리 INSERT (PROCESSING) → Message-ID 미정 상태로
  //    이 DB 트리거가 audit 로그 자동 기록
  const placeholderOutbound = (await supabase
    .schema('app')
    .from('communications' as never)
    .insert({
      organization_id: auth.organizationId,
      channel: 'email',
      direction: 'outbound',
      party_id: draft.party_id,
      from_address: fromAddress,
      from_name: fromName,
      to_addresses: [inbound.from_address],
      subject: finalSubject,
      body_plain: finalBody,
      body_html: draft.body_html,
      thread_id: inbound.thread_id,
      in_reply_to: inbound.message_id,
      status: 'sending',
      ai_draft_id: draft.id,
      ai_generated: true,
      occurred_at: new Date().toISOString(),
      sent_by_user_id: auth.userId,
    } as never)
    .select('id')
    .single()) as { data: { id: string } | null; error: { message: string } | null };

  if (placeholderOutbound.error || !placeholderOutbound.data) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: `Failed to insert outbound row: ${placeholderOutbound.error?.message}`,
    };
  }
  const outboundId = (placeholderOutbound.data as { id: string }).id;

  // 5. TABS Mailer로 실제 발송 (kind 전달)
  let mailer;
  try {
    mailer = await createTabsMailer();
  } catch (e) {
    await markOutboundFailed(supabase, outboundId, auth.organizationId, e);
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: e instanceof Error ? e.message : 'Mailer init failed',
    };
  }

  try {
    const sendResult = await mailer.sendOne({
      to: { address: inbound.from_address },
      fromName,
      fromAddress,
      subject: finalSubject,
      bodyText: finalBody,
      bodyHtml: draft.body_html ?? undefined,
      urmHeaders: {
        communicationId: outboundId,
        autoSend: false,
      },
      traceLabel: `approve-and-send:${draft.id}`,
      sendingAddressKind, // ← Step 1.2 추가: kind 전달
    });

    // 6. outbound communication 상태 갱신 — Message-ID, sent_at
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

    // 7. draft 상태 → 'sent' + sent_communication_id 링크
    await supabase
      .schema('ai')
      .from('drafts' as never)
      .update({
        status: 'sent',
        sent_communication_id: outboundId,
      } as never)
      .eq('id', draft.id)
      .eq('organization_id', auth.organizationId);

    return {
      ok: true,
      data: { sent: true, outboundCommunicationId: outboundId },
    };
  } catch (e) {
    await markOutboundFailed(supabase, outboundId, auth.organizationId, e);
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: e instanceof Error ? e.message : 'SMTP send failed',
    };
  }
}

async function markOutboundFailed(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  outboundId: string,
  organizationId: string,
  err: unknown,
): Promise<void> {
  try {
    await supabase
      .schema('app')
      .from('communications' as never)
      .update({
        status: 'failed',
        notes: err instanceof Error ? err.message : String(err),
      } as never)
      .eq('id', outboundId)
      .eq('organization_id', organizationId);
  } catch {
    // 실패 표시 자체가 실패하더라도 상위 호출자에게 send_failed가 이미 반환됨
  }
}

```

