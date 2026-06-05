// src/app/(app)/campaigns/page.tsx
// Campaign management: list with deal-count / total / weighted-forecast rollup
// (from app.campaign_forecast) + create/delete. RLS scopes to the org.

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

  return <CampaignsClient initialCampaigns={rows} />;
}
