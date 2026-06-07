// src/app/(app)/campaigns/page.tsx
// Campaign management: list with deal-count / total / weighted-forecast rollup
// (from app.campaign_forecast) + create (with company selection) / edit / delete.
// RLS scopes to the org. Pipelines + party types are passed to the client so the
// create dialog can place selected companies as deals at the pipeline's 1st stage.

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { CampaignsClient } from './campaigns-client';

export const dynamic = 'force-dynamic';

export default async function CampaignsPage() {
  const supabase = await createSupabaseServerClient();

  const { data: campaigns } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .select('id, name, campaign_type, description, status, start_date, end_date, color')
    .order('created_at', { ascending: false });

  const { data: forecasts } = await supabase
    .schema('app')
    .from('campaign_forecast' as never)
    .select('campaign_id, deal_count, total_value, weighted_forecast');

  // Pipelines for the "place deals in" selector (active only, in sidebar order).
  const { data: pipelines } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name, sort_order')
    .eq('is_active', true)
    .order('sort_order', { ascending: true });

  // Party types -> label map for the company picker.
  const { data: partyTypes } = await supabase
    .schema('app')
    .from('party_types' as never)
    .select('id, code');

  const fmap = new Map(
    ((forecasts ?? []) as unknown as Array<{
      campaign_id: string; deal_count: number; total_value: number; weighted_forecast: number;
    }>).map((f) => [f.campaign_id, f]),
  );

  const rows = ((campaigns ?? []) as unknown as Array<{
    id: string; name: string; campaign_type: string | null; description: string | null;
    status: string; start_date: string | null; end_date: string | null; color: string | null;
  }>).map((c) => {
    const f = fmap.get(c.id);
    return {
      ...c,
      deal_count: f?.deal_count ?? 0,
      total_value: f?.total_value ?? 0,
      weighted_forecast: f?.weighted_forecast ?? 0,
    };
  });

  const pipelineOpts = ((pipelines ?? []) as unknown as Array<{
    id: string; code: string; name: string; sort_order: number;
  }>).map((p) => ({ code: p.code, name: p.name }));

  const partyTypeMap = Object.fromEntries(
    ((partyTypes ?? []) as unknown as Array<{ id: number; code: string }>).map((t) => [t.id, t.code]),
  );

  return (
    <CampaignsClient
      initialCampaigns={rows}
      pipelines={pipelineOpts}
      partyTypeMap={partyTypeMap}
    />
  );
}
