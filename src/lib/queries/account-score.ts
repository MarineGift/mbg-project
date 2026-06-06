/**
 * lib/queries/account-score.ts  (Feature A: ABM account scoring)
 *
 * Reads the per-account score + A/B/C tier from app.v_account_scores
 * (backed by app.account_scores, recomputed by app.recompute_all_account_scores).
 *
 * This SUPERSEDES the old lead-score path (parties.module_data->'lead_score'
 * via the get_lead_scores_many RPC) for the directory list pages. The account
 * model blends Fit/ICP + recency + frequency + meetings + deal momentum into a
 * single 0..100 score and a tier, which is what the directory now sorts/filters by.
 */
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export type AccountTier = 'A' | 'B' | 'C';

export interface AccountScore {
  score: number;       // 0..100
  tier: AccountTier;
}

// PostgREST .in() goes in the URL; a 700-id list would blow the URL length
// limit. Chunk the lookups (mirrors the defensive per-type counting elsewhere).
const IN_CHUNK = 200;

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

/**
 * Fetch account scores + tiers for many parties at once.
 * Returns a Record keyed by party id. Missing parties are simply absent
 * (callers should treat absent as score 0 / tier 'C').
 */
export async function fetchAccountScoresMany(
  partyIds: string[],
): Promise<Record<string, AccountScore>> {
  if (!partyIds || partyIds.length === 0) return {};

  const supabase = await createSupabaseServerClient();
  const result: Record<string, AccountScore> = {};

  for (const ids of chunk(partyIds, IN_CHUNK)) {
    // Gotcha #45: .schema('app') no cast, .from('TABLE' as never) cast.
    const { data, error } = await supabase
      .schema('app')
      .from('v_account_scores' as never)
      .select('party_id, score, tier')
      .in('party_id' as never, ids);

    if (error) {
      console.warn('[fetchAccountScoresMany] error:', error.message);
      continue; // graceful: partial map is better than throwing the page
    }

    for (const row of (data ?? []) as Array<{ party_id: string; score: number; tier: string }>) {
      if (!row?.party_id) continue;
      const tier: AccountTier = row.tier === 'A' || row.tier === 'B' ? row.tier : 'C';
      result[row.party_id] = { score: Number(row.score ?? 0), tier };
    }
  }

  return result;
}
