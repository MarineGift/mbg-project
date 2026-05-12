/**
 * lib/queries/communications.ts
 *
 * 단일 communications 행의 상세 조회.
 *   - inbound인 경우: 생성된 AI 초안들 함께 fetch
 *   - outbound인 경우: aiDraftId 그대로 노출 (drafts 페이지로 이동 가능)
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { CommunicationDetail } from '@/types/communication-detail';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
} from '@/types/inbox';
import type { ModuleType } from '@/types/ai';

interface RawCommRow {
  id: string;
  organization_id: string;
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  status: CommunicationStatus;
  from_address: string | null;
  from_name: string | null;
  to_addresses: string[] | null;
  cc_addresses: string[] | null;
  bcc_addresses: string[] | null;
  subject: string | null;
  body_plain: string | null;
  body_html: string | null;
  message_id: string | null;
  thread_id: string | null;
  in_reply_to: string | null;
  references: string[] | null;
  occurred_at: string;
  sent_at: string | null;
  received_at: string | null;
  error_message: string | null;
  attachment_count: number | null;
  ai_generated: boolean;
  ai_draft_id: string | null;
  party_id: string | null;
  contact_id: string | null;
}

export async function fetchCommunicationDetail(
  communicationId: string,
): Promise<CommunicationDetail | null> {
  const supabase = await createSupabaseServerClient();

  const { data: raw, error } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('*')
    .eq('id', communicationId)
    .maybeSingle();

  if (error || !raw) return null;
  const c = raw as unknown as RawCommRow;

  // 거래처·컨택트·생성된 초안 병렬 fetch
  const [partyRes, contactRes, draftsRes] = await Promise.all([
    c.party_id
      ? supabase
          .schema('app')
          .from('parties' as never)
          .select('id, name, module')
          .eq('id', c.party_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    c.contact_id
      ? supabase
          .schema('app')
          .from('contacts' as never)
          .select('id, full_name, email')
          .eq('id', c.contact_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    c.direction === 'inbound'
      ? supabase
          .schema('ai')
          .from('drafts' as never)
          .select('id, status, classification_category, confidence_score')
          .eq('inbound_communication_id', c.id)
      : Promise.resolve({ data: [], error: null }),
  ]);

  const party = mapParty(partyRes?.data as unknown);
  const contact = mapContact(contactRes?.data as unknown);
  const generatedDrafts = mapDrafts(
    (draftsRes?.data ?? []) as unknown[],
  );

  return {
    id: c.id,
    organizationId: c.organization_id,
    channel: c.channel,
    direction: c.direction,
    status: c.status,
    fromAddress: c.from_address,
    fromName: c.from_name,
    toAddresses: c.to_addresses ?? [],
    ccAddresses: c.cc_addresses ?? [],
    bccAddresses: c.bcc_addresses ?? [],
    subject: c.subject,
    bodyPlain: c.body_plain,
    bodyHtml: c.body_html,
    messageId: c.message_id,
    threadId: c.thread_id,
    inReplyTo: c.in_reply_to,
    references: c.references ?? [],
    occurredAt: c.occurred_at,
    sentAt: c.sent_at,
    receivedAt: c.received_at,
    errorMessage: c.error_message,
    attachmentCount: c.attachment_count ?? 0,
    aiGenerated: c.ai_generated,
    aiDraftId: c.ai_draft_id,
    party,
    contact,
    generatedDrafts,
  };
}

function mapParty(raw: unknown): CommunicationDetail['party'] {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    name: (r.name as string) ?? '',
    module: r.module as ModuleType,
  };
}

function mapContact(raw: unknown): CommunicationDetail['contact'] {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    fullName: (r.full_name as string | null) ?? null,
    email: (r.email as string | null) ?? null,
  };
}

function mapDrafts(raws: unknown[]): CommunicationDetail['generatedDrafts'] {
  return raws.map((raw) => {
    const r = raw as Record<string, unknown>;
    return {
      id: r.id as string,
      status: (r.status as string) ?? '',
      classificationCategory:
        (r.classification_category as string | null) ?? null,
      confidenceScore:
        typeof r.confidence_score === 'number'
          ? r.confidence_score
          : r.confidence_score != null
            ? Number(r.confidence_score)
            : null,
    };
  });
}
