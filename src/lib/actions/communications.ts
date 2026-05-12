/**
 * lib/actions/communications.ts
 *
 * Outbound 메일 수동 발송 Server Action.
 * TABS Mailer를 사용해 SMTP 발송 + communications 행 기록.
 *
 * 흐름:
 *   1. user의 sending_email 확인
 *   2. communications INSERT (status='sending')
 *   3. tabs-mailer.sendOne() 호출 → message-id 획득
 *   4. communications UPDATE (status='sent', message_id, sent_at)
 *   5. 실패 시 status='failed' + error_message
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createTabsMailer } from '@/lib/email/tabs-mailer';

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
  /** 거래처 연결 (있으면 communications.party_id에 저장) */
  partyId: z.string().uuid().optional().nullable(),
  contactId: z.string().uuid().optional().nullable(),
  /** 새로운 thread 시작 — null이면 자동 생성된 message-id가 thread 시작 */
  inReplyTo: z.string().max(500).optional().nullable(),
  threadId: z.string().max(500).optional().nullable(),
});

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

  const fromAddress = userRow?.sending_email ?? userRow?.email ?? auth.email;
  const fromName = userRow?.full_name ?? auth.email.split('@')[0] ?? 'Sender';

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
    const mailer = await createTabsMailer();
    const sendResult = await mailer.sendOne({
      to: { address: parsed.data.to },
      cc: ccAddresses.map((a) => ({ address: a })),
      fromName,
      fromAddress,
      subject: parsed.data.subject,
      bodyText: parsed.data.bodyPlain,
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
      revalidatePath(`/`, 'layout'); // module을 모르므로 광범위 revalidate
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
