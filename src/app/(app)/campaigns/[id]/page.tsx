// src/app/(app)/campaigns/[id]/page.tsx
// Campaign detail (server): fetch campaign, forecast, deals, pipelines, stages,
// party types -> hand off to the client which provides campaign edit + in-page
// Deal Party CRUD (add company, move stage, remove).

import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { CampaignDetailClient } from './campaign-detail-client';

export const dynamic = 'force-dynamic';

type Campaign = {
  id: string; name: string; campaign_type: string | null; description: string | null;
  status: string; start_date: string | null; end_date: string | null; color: string | null;
};
type DealRow = {
  id: string; deal_name: string; value_amount: number | null; value_currency: string | null;
  status: string; current_stage_id: string | null; pipeline_id: string | null;
  deal_parties: Array<{ party_id: string; parties: { party_name: string } | null }> | null;
};

export default async function CampaignDetailPage({ params }: { params: { id: string } }) {
  const supabase = await createSupabaseServerClient();

  const { data: campaignData } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .select('id, name, campaign_type, description, status, start_date, end_date, color')
    .eq('id', params.id)
    .maybeSingle();

  const campaign = (campaignData ?? null) as Campaign | null;
  if (!campaign) notFound();

  const [{ data: forecastData }, { data: dealsData }, { data: stagesData }, { data: pipelinesData }, { data: partyTypes }] =
    await Promise.all([
      supabase.schema('app').from('campaign_forecast' as never)
        .select('deal_count, total_value, weighted_forecast').eq('campaign_id', params.id).maybeSingle(),
      supabase.schema('app').from('deals' as never)
        .select('id, deal_name, value_amount, value_currency, status, current_stage_id, pipeline_id, deal_parties ( party_id, parties ( party_name ) )')
        .eq('campaign_id', params.id).is('deleted_at', null)
        .order('value_amount', { ascending: false, nullsFirst: false }),
      supabase.schema('app').from('stages' as never)
        .select('id, name, pipeline_id, sort_order').eq('is_active', true),
      supabase.schema('app').from('pipelines' as never)
        .select('id, code, name, sort_order').eq('is_active', true).order('sort_order', { ascending: true }),
      supabase.schema('app').from('party_types' as never).select('id, code'),
    ]);

  const forecast = (forecastData ?? { deal_count: 0, total_value: 0, weighted_forecast: 0 }) as
    { deal_count: number; total_value: number; weighted_forecast: number };

  const deals = ((dealsData ?? []) as unknown as DealRow[]).map((d) => ({
    id: d.id,
    deal_name: d.deal_name,
    value_amount: d.value_amount,
    value_currency: d.value_currency,
    status: d.status,
    current_stage_id: d.current_stage_id,
    pipeline_id: d.pipeline_id,
    companies: (d.deal_parties ?? []).map((p) => p.parties?.party_name).filter(Boolean) as string[],
  }));

  // party ids already in this campaign -> hidden from the Add-company search
  const existingPartyIds = Array.from(new Set(
    ((dealsData ?? []) as unknown as DealRow[])
      .flatMap((d) => (d.deal_parties ?? []).map((p) => p.party_id))
      .filter(Boolean) as string[],
  ));

  const pipelines = ((pipelinesData ?? []) as unknown as Array<{ id: string; code: string; name: string; sort_order: number }>)
    .map((p) => ({ id: p.id, code: p.code, name: p.name }));

  const stages = ((stagesData ?? []) as unknown as Array<{ id: string; name: string; pipeline_id: string; sort_order: number }>);

  const partyTypeMap = Object.fromEntries(
    ((partyTypes ?? []) as unknown as Array<{ id: number; code: string }>).map((t) => [t.id, t.code]),
  );

  return (
    <CampaignDetailClient
      campaign={campaign}
      forecast={forecast}
      deals={deals}
      pipelines={pipelines}
      stages={stages}
      partyTypeMap={partyTypeMap}
      existingPartyIds={existingPartyIds}
    />
  );
}
