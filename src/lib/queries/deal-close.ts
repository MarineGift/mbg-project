import type { SupabaseClient } from '@supabase/supabase-js';

export type CloseOutcome = 'won' | 'lost';

export type CloseReason = { id: string; outcome: CloseOutcome; label: string; sort_order: number };

// --- reasons (close dialog dropdown) ------------------------
export async function getCloseReasons(
  supabase: SupabaseClient, organizationId: string, outcome: CloseOutcome,
): Promise<CloseReason[]> {
  const { data, error } = await supabase.schema('app').from('deal_close_reasons' as never)
    .select('id, outcome, label, sort_order')
    .eq('organization_id', organizationId).eq('outcome', outcome).eq('active', true)
    .order('sort_order', { ascending: true });
  if (error) throw error;
  return (data ?? []) as unknown as CloseReason[];
}

// --- close / reopen (REAL columns) --------------------------
// Outcome is determined by the won/lost stage you move to; the reason text
// goes into the single won_lost_reason column. Trigger sets actual_close_date.
export async function closeDeal(
  supabase: SupabaseClient, organizationId: string, dealId: string,
  args: { stageId: string; outcome: CloseOutcome; reason: string; finalAmount?: number; closedDate?: string },
): Promise<void> {
  if (!args.reason) throw new Error('A close reason is required.');
  const patch: Record<string, unknown> = {
    current_stage_id: args.stageId,
    won_lost_reason: args.reason,
  };
  if (args.finalAmount !== undefined) patch.value_amount = args.finalAmount;
  if (args.closedDate) patch.actual_close_date = args.closedDate; // else trigger sets today
  const { error } = await supabase.schema('app').from('deals' as never)
    .update(patch as never).eq('organization_id', organizationId).eq('id', dealId);
  if (error) throw error;
}

export async function reopenDeal(
  supabase: SupabaseClient, organizationId: string, dealId: string, openStageId: string,
): Promise<void> {
  const { error } = await supabase.schema('app').from('deals' as never)
    .update({ current_stage_id: openStageId, won_lost_reason: null } as never)
    .eq('organization_id', organizationId).eq('id', dealId);
  if (error) throw error; // trigger clears actual_close_date on move to an open stage
}

// --- searchable archive (closed_deals view, already aliased) -
export type ClosedDealRow = {
  id: string; organization_id: string; name: string | null; amount: number | null;
  party_id: string | null; campaign_id: string | null; stage_id: string | null;
  stage_name: string | null; outcome: CloseOutcome | null; close_reason: string | null;
  closed_at: string | null; created_at: string; cycle_days: number | null;
};

export async function searchClosedDeals(
  supabase: SupabaseClient, organizationId: string,
  filters?: { outcome?: CloseOutcome; reason?: string; campaignId?: string; partyId?: string;
              from?: string; to?: string; text?: string },
): Promise<ClosedDealRow[]> {
  let q = supabase.schema('app').from('closed_deals' as never)
    .select('*').eq('organization_id', organizationId);
  if (filters?.outcome)    q = q.eq('outcome', filters.outcome);
  if (filters?.reason)     q = q.eq('close_reason', filters.reason);
  if (filters?.campaignId) q = q.eq('campaign_id', filters.campaignId);
  if (filters?.partyId)    q = q.eq('party_id', filters.partyId);
  if (filters?.from)       q = q.gte('closed_at', filters.from);
  if (filters?.to)         q = q.lte('closed_at', filters.to);
  if (filters?.text)       q = q.ilike('name', `%${filters.text}%`);
  const { data, error } = await q.order('closed_at', { ascending: false });
  if (error) throw error;
  return (data ?? []) as unknown as ClosedDealRow[];
}
