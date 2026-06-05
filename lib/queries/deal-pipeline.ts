import type { SupabaseClient } from '@supabase/supabase-js';

// --- types ---------------------------------------------------
export type FunnelStage = {
  organization_id: string;
  stage_id: string | null;
  stage_name: string | null;
  sort_order: number | null;
  deal_count: number;
  total_value: number;
  weighted_value: number;
};

export type DealAging = {
  id: string;
  organization_id: string;
  stage_id: string | null;
  stage_name: string | null;
  amount: number | null;
  last_touch: string | null;
  days_in_stage: number;
  days_since_touch: number;
  is_closed: boolean;
  is_stale: boolean;
};

export type PipelineSummary = {
  organization_id: string;
  open_count: number;
  won_count: number;
  lost_count: number;
  open_value: number;
  avg_won_value: number;
  win_rate_pct: number;
  avg_cycle_days: number;
};

// --- reads ---------------------------------------------------
export async function getPipelineFunnel(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<FunnelStage[]> {
  const { data, error } = await supabase
    .schema('app')
    .from('pipeline_funnel' as never)
    .select('*')
    .eq('organization_id', organizationId)
    .order('sort_order', { ascending: true });
  if (error) throw error;
  return (data ?? []) as unknown as FunnelStage[];
}

export async function getPipelineSummary(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<PipelineSummary | null> {
  const { data, error } = await supabase
    .schema('app')
    .from('pipeline_summary' as never)
    .select('*')
    .eq('organization_id', organizationId)
    .maybeSingle();
  if (error) throw error;
  return (data ?? null) as unknown as PipelineSummary | null;
}

export async function getDealAging(
  supabase: SupabaseClient,
  organizationId: string,
  opts?: { staleOnly?: boolean },
): Promise<DealAging[]> {
  let q = supabase
    .schema('app')
    .from('deal_aging' as never)
    .select('*')
    .eq('organization_id', organizationId);
  if (opts?.staleOnly) q = q.eq('is_stale', true);
  const { data, error } = await q.order('days_since_touch', { ascending: false });
  if (error) throw error;
  return (data ?? []) as unknown as DealAging[];
}

// Derived single-number velocity (daily $) from the summary view.
export function salesVelocityPerDay(s: PipelineSummary): number {
  if (!s || s.avg_cycle_days <= 0) return 0;
  return Math.round(
    (s.open_count * s.avg_won_value * (s.win_rate_pct / 100)) / s.avg_cycle_days,
  );
}

// --- writes (deal lifecycle) --------------------------------
async function patchDeal(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabase
    .schema('app')
    .from('deals' as never)
    .update(patch as never)
    .eq('organization_id', organizationId)
    .eq('id', dealId);
  if (error) throw error;
}

export const setDealOwner = (sb: SupabaseClient, org: string, id: string, ownerId: string | null) =>
  patchDeal(sb, org, id, { owner_id: ownerId });

export const setDealPriority = (sb: SupabaseClient, org: string, id: string, priority: string | null) =>
  patchDeal(sb, org, id, { priority });

export const setExpectedCloseDate = (sb: SupabaseClient, org: string, id: string, date: string | null) =>
  patchDeal(sb, org, id, { expected_close_date: date });

export const setNextStep = (
  sb: SupabaseClient, org: string, id: string, text: string | null, date: string | null,
) => patchDeal(sb, org, id, { next_step: text, next_step_date: date });

// Mark last touch = now (call from your activity/email logging).
export const touchDealActivity = (sb: SupabaseClient, org: string, id: string) =>
  patchDeal(sb, org, id, { last_activity_at: new Date().toISOString() });

// Close a deal: move to a won/lost stage (trigger sets closed_at) + capture reason.
// Enforce "reason required on loss" here in app logic.
export async function closeDeal(
  sb: SupabaseClient,
  org: string,
  dealId: string,
  args: { stageId: string; outcome: 'won' | 'lost'; reason?: string },
): Promise<void> {
  if (args.outcome === 'lost' && !args.reason) {
    throw new Error('A lost reason is required when closing a deal as lost.');
  }
  await patchDeal(sb, org, dealId, {
    stage_id: args.stageId,
    won_reason: args.outcome === 'won' ? (args.reason ?? null) : null,
    lost_reason: args.outcome === 'lost' ? (args.reason ?? null) : null,
  });
}
