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
import type {
  Round,
  RoundStatus,
  RoundWithRollup,
  RoundStageBreakdown,
} from '@/types/round';

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

/** PostgREST numeric -> number (strings preserve precision); null/NaN -> 0. */
function num(v: string | number | null | undefined): number {
  if (v == null) return 0;
  const n = typeof v === 'number' ? v : parseFloat(v);
  return Number.isFinite(n) ? n : 0;
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

/* ============================================================
 * listRoundsWithRollup
 *
 * Rounds + derived aggregates over their Investor deals:
 *   - committedTotal = sum(deal_parties.commitment_amount) across deals
 *   - dealCount      = distinct non-deleted deals attached to the round
 *   - progressPct    = committedTotal / target_amount * 100 (null if no target)
 *   - stageBreakdown = per-stage deal count + committed (stages with >=1 deal)
 *
 * Three small reads (rounds, investor stages, investor deals+parties), then a
 * pure-JS join. Deliberately avoids a deals<->deal_parties flat join (which
 * would inflate deal counts by company count) -- commitments are nested.
 * Single-currency (USD) assumption: amounts are summed without FX conversion.
 * ============================================================ */

interface RawDealForRollup {
  id: string;
  round_id: string | null;
  current_stage_id: string | null;
  deal_parties: Array<{ commitment_amount: string | number | null }> | null;
}

interface RawStageRow {
  id: string;
  name: string;
  sort_order: number;
}

export async function listRoundsWithRollup(): Promise<RoundWithRollup[]> {
  const supabase = await createSupabaseServerClient();

  // 1) rounds (RLS-scoped, newest first)
  const { data: roundData } = await supabase
    .schema('app')
    .from('rounds' as never)
    .select(ROUND_SELECT)
    .order('created_at', { ascending: false });

  const rounds = ((roundData ?? []) as unknown as RawRoundRow[]).map(mapRound);
  if (rounds.length === 0) return [];

  // 2) resolve the investor pipeline (rounds only attach to investor deals)
  const { data: pipelineRow } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id')
    .eq('code', 'investor')
    .eq('is_active', true)
    .maybeSingle();

  const pipelineId = (pipelineRow as { id: string } | null)?.id ?? null;

  // No investor pipeline -> rounds exist but carry no deals.
  if (!pipelineId) {
    return rounds.map((r) => ({
      ...r,
      dealCount: 0,
      committedTotal: 0,
      progressPct: r.targetAmount != null ? 0 : null,
      stageBreakdown: [],
    }));
  }

  // 3) investor stages (for breakdown names + ordering)
  const { data: stageData } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, name, sort_order')
    .eq('pipeline_id', pipelineId);

  const stages = (stageData ?? []) as unknown as RawStageRow[];
  const stageById = new Map<string, RawStageRow>();
  for (const s of stages) stageById.set(s.id, s);

  // 4) investor deals that carry a round, with their commitments (nested)
  const { data: dealData } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, round_id, current_stage_id, deal_parties ( commitment_amount )')
    .eq('pipeline_id', pipelineId)
    .is('deleted_at', null)
    .not('round_id', 'is', null);

  const deals = (dealData ?? []) as unknown as RawDealForRollup[];

  // 5) aggregate in JS
  //    roundAcc: round_id -> { committed, dealCount, perStage: stageId -> {count, committed} }
  interface StageAcc {
    dealCount: number;
    committed: number;
  }
  interface RoundAcc {
    committed: number;
    dealCount: number;
    perStage: Map<string, StageAcc>;
  }
  const acc = new Map<string, RoundAcc>();

  for (const d of deals) {
    if (!d.round_id) continue;
    let ra = acc.get(d.round_id);
    if (!ra) {
      ra = { committed: 0, dealCount: 0, perStage: new Map() };
      acc.set(d.round_id, ra);
    }
    const dealCommitted = (d.deal_parties ?? []).reduce(
      (sum, p) => sum + num(p.commitment_amount),
      0,
    );
    ra.committed += dealCommitted;
    ra.dealCount += 1;

    const sid = d.current_stage_id ?? '__none__';
    let sa = ra.perStage.get(sid);
    if (!sa) {
      sa = { dealCount: 0, committed: 0 };
      ra.perStage.set(sid, sa);
    }
    sa.dealCount += 1;
    sa.committed += dealCommitted;
  }

  // 6) shape the result
  return rounds.map((r) => {
    const ra = acc.get(r.id);
    const committedTotal = ra?.committed ?? 0;
    const dealCount = ra?.dealCount ?? 0;

    const target = r.targetAmount != null ? num(r.targetAmount) : null;
    const progressPct =
      target != null && target > 0
        ? Math.round((committedTotal / target) * 1000) / 10 // 0.1% precision
        : target === 0
          ? 0
          : null;

    const stageBreakdown: RoundStageBreakdown[] = [];
    if (ra) {
      for (const [stageId, sa] of ra.perStage) {
        const meta = stageById.get(stageId);
        stageBreakdown.push({
          stageId,
          stageName: meta?.name ?? 'Unknown',
          sortOrder: meta?.sort_order ?? 9999,
          dealCount: sa.dealCount,
          committed: sa.committed,
        });
      }
      stageBreakdown.sort((a, b) => a.sortOrder - b.sortOrder);
    }

    return {
      ...r,
      dealCount,
      committedTotal,
      progressPct,
      stageBreakdown,
    };
  });
}
