/**
 * lib/queries/meetings.ts
 *
 * Party meetings query. Currently stub - returns empty list.
 * TODO: implement once `meetings` table is added.
 */
import 'server-only';

export interface PartyMeeting {
  id: string;
  party_id: string;
  title: string;
  scheduled_at: string;
  duration_minutes?: number | null;
  location?: string | null;
  notes?: string | null;
  status?: 'scheduled' | 'completed' | 'cancelled' | null;
  created_at?: string;
}

export async function fetchPartyMeetings(_partyId: string): Promise<PartyMeeting[]> {
  // Stub: no meetings table yet
  return [];
}