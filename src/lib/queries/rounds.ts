/**
 * lib/queries/rounds.ts
 *
 * Read API for fundraising rounds (app.rounds).
 *
 * Org scoping is handled by RLS (the rounds_* policies + organization_id
 * default = app.current_organization_id()), so no explicit organization_id
 * filter is applied here -- matching the rest of the pipelines/queries stack.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { Round, RoundStatus } from '@/types/round';

interface RawRoundRow {
  id: string;
  organization_id: string;
  name: string;
  round_type: string | null;
  target_amount: string | null;
  pre_money_valuation: string | null;
  currency: string;
  status: RoundStatus;
  opened_at: string | null;
  closed_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

const ROUND_SELECT =
  'id, organization_id, name, round_type, target_amount, ' +
  'pre_money_valuation, currency, status, opened_at, closed_at, ' +
  'notes, created_at, updated_at';

function mapRound(r: RawRoundRow): Round {
  return {
    id: r.id,
    organizationId: r.organization_id,
    name: r.name,
    roundType: r.round_type,
    targetAmount: r.target_amount,
    preMoneyValuation: r.pre_money_valuation,
    currency: r.currency,
    status: r.status,
    openedAt: r.opened_at,
    closedAt: r.closed_at,
    notes: r.notes,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}

/** All rounds for the caller's org, newest first. */
export async function listRounds(): Promise<Round[]> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('rounds' as never)
    .select(ROUND_SELECT)
    .order('created_at', { ascending: false });

  return ((data ?? []) as unknown as RawRoundRow[]).map(mapRound);
}

/** Single round by id (null if not found / not visible under RLS). */
export async function getRound(roundId: string): Promise<Round | null> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('rounds' as never)
    .select(ROUND_SELECT)
    .eq('id', roundId)
    .maybeSingle();

  return data ? mapRound(data as unknown as RawRoundRow) : null;
}
