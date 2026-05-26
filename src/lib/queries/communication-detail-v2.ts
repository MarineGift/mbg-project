// src/lib/queries/communication-detail-v2.ts
// Replacement for fetchCommunicationDetail that returns properly mapped CommunicationDetail
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { CommunicationDetail } from '@/types/communication-detail';

export async function fetchCommunicationDetailV2(
  id: string,
): Promise<CommunicationDetail | null> {
  const supabase = await createSupabaseServerClient();

  const { data: raw, error } = await supabase
    .schema('app')
    .from('communications' as never)
    .select(
      'id, organization_id, channel, direction, status, ' +
      'from_address, from_name, to_addresses, cc_addresses, ' +
      'subject, body_plain, body_html, ' +
      'message_id, thread_id, in_reply_to, ' +
      'occurred_at, sent_at, received_at, ai_generated, ' +
      'external_data, ' +
      'parties:party_id ( id, name, party_type ), ' +
      'contacts:contact_id ( id, given_name, family_name, email )',
    )
    .eq('id', id)
    .is('deleted_at', null)
    .maybeSingle();

  if (error || !raw) return null;

  const r = raw as any;
  const party   = Array.isArray(r.parties)  ? r.parties[0]  : r.parties;
  const contact = Array.isArray(r.contacts) ? r.contacts[0] : r.contacts;
  const ext     = r.external_data ?? {};

  // Fetch AI drafts generated from this communication (best-effort)
  let drafts: any[] = [];
  try {
    const { data } = await supabase
      .schema('ai')
      .from('drafts' as never)
      .select('id, status, classification_category, confidence_score')
      .eq('source_communication_id' as never, id)
      .order('created_at', { ascending: false })
      .limit(10);
    drafts = data ?? [];
  } catch {
    drafts = [];
  }

  return {
    id:               r.id,
    organizationId:   r.organization_id,
    channel:          r.channel,
    direction:        r.direction,
    status:           r.status,
    fromAddress:      r.from_address    ?? null,
    fromName:         r.from_name       ?? null,
    toAddresses:      r.to_addresses    ?? [],
    ccAddresses:      r.cc_addresses    ?? [],
    bccAddresses:     [],
    subject:          r.subject         ?? null,
    bodyPlain:        r.body_plain      ?? null,
    bodyHtml:         r.body_html       ?? null,
    messageId:        r.message_id      ?? null,
    threadId:         r.thread_id       ?? null,
    inReplyTo:        r.in_reply_to     ?? null,
    references:       ext.references    ?? [],
    occurredAt:       r.occurred_at     ?? r.received_at ?? r.created_at,
    sentAt:           r.sent_at         ?? null,
    receivedAt:       r.received_at     ?? null,
    errorMessage:     r.error_message   ?? ext.error_message ?? null,
    attachmentCount:  0,
    aiGenerated:      r.ai_generated    ?? false,
    aiDraftId:        r.ai_draft_id     ?? null,
    party:   party   ? { id: party.id,   name: party.name,   partyType: party.party_type } : null,
    contact: contact ? {
      id:       contact.id,
      fullName: [contact.given_name, contact.family_name].filter(Boolean).join(' ') || null,
      email:    contact.email ?? null,
    } : null,
    generatedDrafts: drafts.map((d: any) => ({
      id:                     d.id,
      status:                 d.status,
      classificationCategory: d.classification_category ?? null,
      confidenceScore:        d.confidence_score        ?? null,
    })),
  };
}
