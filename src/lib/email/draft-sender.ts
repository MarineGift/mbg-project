import 'server-only';
import type { SupabaseClient } from '@supabase/supabase-js';
import { TabsMailerClient, TabsMailerError } from './tabs-mailer';
import { env } from '@/lib/env';
import { randomUUID } from 'node:crypto';

export interface SendDraftOverrides {
  subject?: string;
  bodyPlain?: string;
  bodyHtml?: string;
}

export interface SendDraftResult {
  outboundCommunicationId: string;
  messageId: string;
  mocked: boolean;
}

export class DraftSendError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'DraftSendError';
  }
}

/**
 * ai.drafts.id를 받아 다음을 수행:
 *   1. draft 행 + 원본 inbound communication 조회
 *   2. 승인 가능 상태 검증 (status='pending' 등)
 *   3. outbound communication 행 INSERT (status='queued', ai_draft_id=draftId)
 *   4. TabsMailerClient.sendOne()로 전송
 *   5. 성공 시 outbound communication.status='sent', sent_at, draft.status='sent' 업데이트
 *   6. 실패 시 outbound communication.status='failed' 업데이트 (draft은 'pending'으로 둠)
 *
 * 호출자(API 라우트)는 인증된 사용자 ID를 sentByUserId로 전달한다.
 */
export async function sendDraft(
  supabase: SupabaseClient,
  organizationId: string,
  draftId: string,
  sentByUserId: string,
  overrides: SendDraftOverrides = {},
): Promise<SendDraftResult> {
  // 1. draft 조회
  const { data: draftRow, error: draftErr } = await supabase
    .schema('ai')
    .from('drafts')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', draftId)
    .maybeSingle();

  if (draftErr || !draftRow) {
    throw new DraftSendError(
      `Draft not found: ${draftId} (${draftErr?.message ?? 'no row'})`,
    );
  }
  const draft = draftRow as Record<string, unknown>;

  if (draft.status && draft.status !== 'pending') {
    throw new DraftSendError(
      `Draft is not pending (current status=${String(draft.status)})`,
    );
  }

  const inboundCommunicationId = String(draft.communication_id);

  // 2. inbound communication 조회 (회신 헤더 + 수신자 결정용)
  const { data: inboundRow, error: inboundErr } = await supabase
    .schema('app')
    .from('communications')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', inboundCommunicationId)
    .maybeSingle();

  if (inboundErr || !inboundRow) {
    throw new DraftSendError(
      `Inbound communication not found: ${inboundCommunicationId}`,
    );
  }
  const inbound = inboundRow as Record<string, unknown>;

  // 3. outbound 페이로드 준비
  const subject = overrides.subject ?? prefixReSubject(String(inbound.subject ?? ''));
  const bodyPlain = overrides.bodyPlain ?? String(draft.body_plain ?? '');
  const bodyHtml = overrides.bodyHtml ?? (draft.body_html ? String(draft.body_html) : undefined);

  if (!bodyPlain && !bodyHtml) {
    throw new DraftSendError('Draft has no body to send');
  }

  const toAddress = String(inbound.from_address ?? '');
  if (!toAddress) {
    throw new DraftSendError('Inbound message has no from_address');
  }
  const toName = inbound.from_name ? String(inbound.from_name) : undefined;

  const fromAddress = env.TABS_MAILER_FROM_DEFAULT
    ?? `noreply@${env.TABS_MAILER_FROM_DOMAIN}`;

  const inboundReferences = Array.isArray(
    (inbound.external_data as { references?: string[] } | null)?.references,
  )
    ? ((inbound.external_data as { references: string[] }).references ?? [])
    : [];
  const inboundMessageId = inbound.message_id ? String(inbound.message_id) : null;
  const references = inboundMessageId
    ? [...inboundReferences, inboundMessageId]
    : inboundReferences;

  const threadId = inbound.thread_id ? String(inbound.thread_id) : undefined;
  const partyId = inbound.party_id ? String(inbound.party_id) : undefined;
  const engagementId = inbound.engagement_id ? String(inbound.engagement_id) : undefined;

  // 4. outbound communication 행 사전 INSERT (status='queued')
  const outboundMessageId = `<urm-${randomUUID()}@${env.TABS_MAILER_FROM_DOMAIN}>`;

  const { data: outboundRow, error: outboundErr } = await supabase
    .schema('app')
    .from('communications')
    .insert({
      organization_id: organizationId,
      party_id: partyId ?? null,
      contact_id: inbound.contact_id ?? null,
      engagement_id: engagementId ?? null,
      module: inbound.module ?? null,
      message_id: outboundMessageId,
      thread_id: threadId ?? null,
      in_reply_to: inboundMessageId,
      direction: 'outbound',
      channel: 'email',
      from_address: fromAddress,
      to_addresses: [toAddress],
      cc_addresses: [],
      bcc_addresses: [],
      subject,
      body_plain: bodyPlain,
      body_html: bodyHtml ?? null,
      language_detected: draft.language ?? null,
      status: 'queued',
      occurred_at: new Date().toISOString(),
      external_data: {
        draft_id: draftId,
        references,
        approved_by: sentByUserId,
      },
      ai_classification: null,
      ai_draft_id: draftId,
      ai_generated: true,
      ai_processing_status: 'processed',
      sent_by_user_id: sentByUserId,
      pii_masked: false,
      is_starred: false,
      is_important: false,
    })
    .select('id')
    .single();

  if (outboundErr || !outboundRow) {
    throw new DraftSendError(
      `Outbound communications INSERT failed: ${outboundErr?.message}`,
      outboundErr,
    );
  }

  const outboundCommunicationId = String((outboundRow as { id: string }).id);

  // 5. TABS Mailer로 발송
  const mailer = new TabsMailerClient(supabase);
  let sentResult;
  try {
    sentResult = await mailer.sendOne({
      to: { name: toName, address: toAddress },
      from: { address: fromAddress },
      subject,
      text: bodyPlain,
      html: bodyHtml,
      messageId: outboundMessageId,
      inReplyTo: inboundMessageId ?? undefined,
      references,
      urmHeaders: {
        communicationId: outboundCommunicationId,
        engagementId,
        partyId,
        threadId,
        autoSend: false,
      },
    });
  } catch (err) {
    // 발송 실패 시 outbound 행 status='failed'로 업데이트
    await supabase
      .schema('app')
      .from('communications')
      .update({
        status: 'failed',
        bounce_reason: (err as Error).message,
      })
      .eq('id', outboundCommunicationId);

    if (err instanceof TabsMailerError) {
      throw new DraftSendError(`Send failed: ${err.message}`, err);
    }
    throw new DraftSendError(`Send failed (unknown): ${(err as Error).message}`, err);
  } finally {
    mailer.close();
  }

  // 6. 성공 시 상태 업데이트
  const sentAt = new Date().toISOString();
  await supabase
    .schema('app')
    .from('communications')
    .update({ status: 'sent', sent_at: sentAt })
    .eq('id', outboundCommunicationId);

  await supabase
    .schema('ai')
    .from('drafts')
    .update({
      status: 'sent',
      sent_at: sentAt,
      sent_communication_id: outboundCommunicationId,
    })
    .eq('id', draftId);

  return {
    outboundCommunicationId,
    messageId: sentResult.messageId,
    mocked: sentResult.mocked,
  };
}

function prefixReSubject(subject: string): string {
  if (!subject) return '(no subject)';
  return /^re:\s*/i.test(subject) ? subject : `Re: ${subject}`;
}
