import type { SupabaseClient } from '@supabase/supabase-js';

export type DealForecast = {
  id: string;
  organization_id: string;
  campaign_id: string | null;
  stage_id: string | null;
  amount: number | null;
  effective_probability: number;
  forecast_value: number;
};

export type CampaignForecast = {
  campaign_id: string;
  organization_id: string;
  name: string;
  deal_count: number;
  total_value: number;
  weighted_forecast: number;
};

// --- reads ---------------------------------------------------
export async function getDealForecasts(
  supabase: SupabaseClient,
  organizationId: string,
  opts?: { campaignId?: string },
): Promise<DealForecast[]> {
  let q = supabase
    .schema('app')
    .from('deal_forecast' as never)
    .select('*')
    .eq('organization_id', organizationId);
  if (opts?.campaignId) q = q.eq('campaign_id', opts.campaignId);
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as unknown as DealForecast[];
}

export async function getCampaignForecasts(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<CampaignForecast[]> {
  const { data, error } = await supabase
    .schema('app')
    .from('campaign_forecast' as never)
    .select('*')
    .eq('organization_id', organizationId);
  if (error) throw error;
  return (data ?? []) as unknown as CampaignForecast[];
}

// --- writes --------------------------------------------------
// Set/clear a per-deal probability override (null => inherit stage default).
export async function setDealProbability(
  supabase: SupabaseClient,
  organizationId: string,
  dealId: string,
  probability: number | null,
): Promise<void> {
  const { error } = await supabase
    .schema('app')
    .from('deals' as never)
    .update({ probability } as never)
    .eq('organization_id', organizationId)
    .eq('id', dealId);
  if (error) throw error;
}

// Set a stage's default probability. NOTE: stages may not carry organization_id
// (they belong to pipelines), so this is keyed by stage id only.
export async function setStageDefaultProbability(
  supabase: SupabaseClient,
  stageId: string,
  probability: number,
): Promise<void> {
  const { error } = await supabase
    .schema('app')
    .from('stages' as never)
    .update({ default_probability: probability } as never)
    .eq('id', stageId);
  if (error) throw error;
}
