/**
 * lib/queries/lead-score.ts (v2 — Stage 13d 적용)
 *
 * Lead scoring queries. Returns 0-100 score per party.
 * v2: app.lead_scores 테이블은 더 이상 존재하지 않음 (Stage 13d 이후).
 *     parties.module_data->'lead_score' 에 저장되며
 *     public.get_lead_scores_many(uuid[]) RPC 가 호환 wrapper 제공.
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
    .rpc('get_lead_scores_many' as never, { p_party_ids: partyIds });

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