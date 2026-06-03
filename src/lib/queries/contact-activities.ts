/**
 * lib/queries/contact-activities.ts
 *
 * Per-contact engagement activity for the party Contacts 2-panel.
 *
 * engagements has no contact_id (party/deal/task scoped); the contact link lives
 * on app.engagement_attendees (engagement_id + contact_id + role/attended/response).
 * So we fetch the party's engagements, then their attendees, and group by contact
 * in JS (flat select + tally -- same pattern as the rest of the codebase, avoids
 * embedded-filter pitfalls). Returns a map keyed by contact_id.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface ContactActivity {
  engagementId: string;
  title: string | null;
  summary: string | null;
  occurredAt: string | null;
  channel: string | null;
  direction: string | null;
  status: string | null;
  /** from engagement_attendees */
  role: string | null;
  attended: boolean | null;
  response: string | null;
}

interface RawEngagement {
  id: string;
  title: string | null;
  summary: string | null;
  occurred_at: string | null;
  channel: string | null;
  direction: string | null;
  status: string | null;
}

interface RawAttendee {
  engagement_id: string;
  contact_id: string;
  role: string | null;
  attended: boolean | null;
  response: string | null;
}

export async function fetchContactActivities(
  partyId: string,
): Promise<Record<string, ContactActivity[]>> {
  const supabase = await createSupabaseServerClient();

  // 1) engagements for this party
  const { data: engData } = await supabase
    .schema('app')
    .from('engagements' as never)
    .select('id, title, summary, occurred_at, channel, direction, status')
    .eq('party_id', partyId)
    .is('deleted_at', null)
    .order('occurred_at', { ascending: false, nullsFirst: false });

  const engagements = (engData ?? []) as unknown as RawEngagement[];
  if (engagements.length === 0) return {};

  const engById = new Map<string, RawEngagement>();
  for (const e of engagements) engById.set(e.id, e);
  const engIds = engagements.map((e) => e.id);

  // 2) attendees linking those engagements to contacts
  const { data: attData } = await supabase
    .schema('app')
    .from('engagement_attendees' as never)
    .select('engagement_id, contact_id, role, attended, response')
    .in('engagement_id', engIds);

  const attendees = (attData ?? []) as unknown as RawAttendee[];

  // 3) group by contact_id
  const byContact: Record<string, ContactActivity[]> = {};
  for (const a of attendees) {
    const e = engById.get(a.engagement_id);
    if (!e) continue;
    const item: ContactActivity = {
      engagementId: e.id,
      title: e.title,
      summary: e.summary,
      occurredAt: e.occurred_at,
      channel: e.channel,
      direction: e.direction,
      status: e.status,
      role: a.role,
      attended: a.attended,
      response: a.response,
    };
    if (!byContact[a.contact_id]) byContact[a.contact_id] = [];
    byContact[a.contact_id].push(item);
  }

  // 4) sort each contact's list newest-first (attendee row order isn't guaranteed)
  for (const k of Object.keys(byContact)) {
    byContact[k].sort((x, y) => {
      const tx = x.occurredAt ? Date.parse(x.occurredAt) : 0;
      const ty = y.occurredAt ? Date.parse(y.occurredAt) : 0;
      return ty - tx;
    });
  }

  return byContact;
}
