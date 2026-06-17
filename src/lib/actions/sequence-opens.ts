'use server';
// src/lib/actions/sequence-opens.ts
// Open-tracking ("수신확인") report for a single sequence.
// Joins app.communications (filtered by external_data->>sequence_id)
// to app.email_tracking, then resolves party names.

import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface SequenceOpenRow {
  recipient:     string;
  partyName:     string | null;
  subject:       string | null;
  openCount:     number;
  firstOpenedAt: string | null;
  clickCount:    number;
}

export interface SequenceOpenReport {
  sent:     number;
  opened:   number;
  clicked:  number;
  openRate: number; // percent, one decimal
  rows:     SequenceOpenRow[];
}

export async function getSequenceOpenReport(
  sequenceId: string,
): Promise<SequenceOpenReport | { error: string }> {
  const supabase = await createSupabaseServerClient();

  // 1) communications belonging to this sequence
  const { data: comms, error: cErr } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('id')
    .filter('external_data->>sequence_id', 'eq', sequenceId);
  if (cErr) return { error: cErr.message };

  const commIds = ((comms ?? []) as { id: string }[]).map((c) => c.id);
  if (commIds.length === 0) {
    return { sent: 0, opened: 0, clicked: 0, openRate: 0, rows: [] };
  }

  // 2) tracking rows for those communications
  const { data: tracks, error: tErr } = await supabase
    .schema('app')
    .from('email_tracking' as never)
    .select('communication_id, sent_to, subject, open_count, first_opened_at, click_count, party_id')
    .in('communication_id', commIds);
  if (tErr) return { error: tErr.message };

  const trackList = ((tracks ?? []) as {
    sent_to:         string;
    subject:         string | null;
    open_count:      number | null;
    first_opened_at: string | null;
    click_count:     number | null;
    party_id:        string | null;
  }[]);

  // 3) resolve party names
  const partyIds = [...new Set(trackList.map((t) => t.party_id).filter(Boolean))] as string[];
  const nameById: Record<string, string> = {};
  if (partyIds.length) {
    const { data: parties } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, party_name')
      .in('id', partyIds);
    for (const p of (parties ?? []) as { id: string; party_name: string }[]) {
      nameById[p.id] = p.party_name;
    }
  }

  const rows: SequenceOpenRow[] = trackList.map((t) => ({
    recipient:     t.sent_to,
    partyName:     t.party_id ? nameById[t.party_id] ?? null : null,
    subject:       t.subject,
    openCount:     t.open_count ?? 0,
    firstOpenedAt: t.first_opened_at,
    clickCount:    t.click_count ?? 0,
  }));

  // opened first, then earliest open
  rows.sort((a, b) =>
    b.openCount - a.openCount ||
    (a.firstOpenedAt ?? '\uffff').localeCompare(b.firstOpenedAt ?? '\uffff'),
  );

  const sent    = rows.length;
  const opened  = rows.filter((r) => r.openCount > 0).length;
  const clicked = rows.filter((r) => r.clickCount > 0).length;

  return {
    sent,
    opened,
    clicked,
    openRate: sent ? Math.round((opened / sent) * 1000) / 10 : 0,
    rows,
  };
}
