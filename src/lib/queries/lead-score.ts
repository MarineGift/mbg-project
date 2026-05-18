/**
 * lib/queries/lead-score.ts
 *
 * Lead scoring queries. Returns 0-100 score per party.
 */
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

/**
 * Fetch lead scores for many parties at once.
 * Returns a Record keyed by party id with score values (0-100).
 * Missing parties default to 0.
 */
export async function fetchLeadScoresMany(
  partyIds: string[],
): Promise<Record<string, number>> {
  if (!partyIds || partyIds.length === 0) return {};

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('lead_scores' as never)
    .select('party_id, score')
    .in('party_id' as never, partyIds);

  if (error) {
    console.warn('[fetchLeadScoresMany] error:', error.message);
    return {};
  }

  const result: Record<string, number> = {};
  for (const row of (data ?? []) as any[]) {
    if (row?.party_id && typeof row.score === 'number') {
      result[row.party_id] = row.score;
    }
  }
  return result;
}