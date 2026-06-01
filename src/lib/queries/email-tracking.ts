/**
 * lib/queries/email-tracking.ts
 *
 * Query email tracking data.
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { rpc } from '@/lib/rpc/typed-rpc';
import type {
  EmailTracking,
  EmailTrackingEvent,
  DraftTrackingSummary,
} from '@/types/phase21';

/* ──────────────────────────────────────────────────────────
 * single-record query
 * ────────────────────────────────────────────────────────── */

/** Look up the tracking record by communication_id (for manual sends) */
export async function fetchTrackingForCommunication(
  communicationId: string,
): Promise<EmailTracking | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking')
    .select('*')
    .eq('communication_id', communicationId)
    .order('sent_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data;
}

/** Look up the tracking record by draft_id (for draft-based sends) */
export async function fetchTrackingForDraft(
  draftId: string,
): Promise<EmailTracking | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking')
    .select('*')
    .eq('draft_id', draftId)
    .order('sent_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data;
}

/** Look up the entire send history of a party by party_id */
export async function fetchTrackingForParty(
  partyId: string,
): Promise<EmailTracking[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking')
    .select('*')
    .eq('party_id', partyId)
    .order('sent_at', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

/** single event-log query */
export async function fetchTrackingEvents(
  trackingId: string,
): Promise<EmailTrackingEvent[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_tracking_events')
    .select('*')
    .eq('tracking_id', trackingId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

/* ──────────────────────────────────────────────────────────
 * batch query (for inbox list badges)
 * ────────────────────────────────────────────────────────── */

/**
 * Batch-look up tracking summaries by an array of communication_id.
 * Used to show a badge per row in the inbox Sent tab.
 * Returns Map<communicationId, DraftTrackingSummary>.
 */
export async function fetchTrackingMapForCommunications(
  communicationIds: string[],
): Promise<Map<string, DraftTrackingSummary>> {
  if (!communicationIds.length) return new Map();

  const supabase = await createSupabaseServerClient();
  const { data, error } = await rpc(supabase, 
    'get_tracking_for_communications',
    { p_communication_ids: communicationIds },
  );
  if (error) throw error;

  const map = new Map<string, DraftTrackingSummary>();
  for (const row of (data ?? []) as Array<{
    communication_id: string;
    tracking_id: string;
    open_count: number;
    click_count: number;
    first_opened_at: string | null;
    sent_at: string;
  }>) {
    if (row.communication_id) {
      map.set(row.communication_id, {
        draft_id: row.communication_id,   // reuse - used as the id field
        tracking_id: row.tracking_id,
        open_count: row.open_count,
        click_count: row.click_count,
        first_opened_at: row.first_opened_at,
        sent_at: row.sent_at,
      });
    }
  }
  return map;
}

/** batch query by an array of draft_id (backward compatibility) */
export async function fetchTrackingMapForDrafts(
  draftIds: string[],
): Promise<Map<string, DraftTrackingSummary>> {
  if (!draftIds.length) return new Map();

  const supabase = await createSupabaseServerClient();
  const { data, error } = await rpc(supabase, 'get_tracking_for_drafts', {
    p_draft_ids: draftIds,
  });
  if (error) throw error;

  const map = new Map<string, DraftTrackingSummary>();
  for (const row of (data ?? []) as unknown as DraftTrackingSummary[]) {
    if (row.draft_id) map.set(row.draft_id, row);
  }
  return map;
}
