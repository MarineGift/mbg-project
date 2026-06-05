// src/app/(app)/campaigns/[id]/page.tsx
// Campaign detail: info, forecast rollup, and the deals that belong to it.

import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ChevronLeft } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

type Campaign = {
  id: string; name: string; campaign_type: string | null; description: string | null;
  status: string; start_date: string | null; end_date: string | null; color: string | null;
};
type Forecast = { deal_count: number; total_value: number; weighted_forecast: number };
type DealRow = {
  id: string; deal_name: string; value_amount: number | null; value_currency: string | null;
  status: string; current_stage_id: string | null; pipeline_id: string | null;
};

const fmtMoney = (n: number | null, cur: string | null) =>
  (cur ? cur + ' ' : '') + (n ?? 0).toLocaleString();

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

  const [{ data: forecastData }, { data: dealsData }, { data: stagesData }, { data: pipelinesData }] =
    await Promise.all([
      supabase.schema('app').from('campaign_forecast' as never)
        .select('deal_count, total_value, weighted_forecast').eq('campaign_id', params.id).maybeSingle(),
      supabase.schema('app').from('deals' as never)
        .select('id, deal_name, value_amount, value_currency, status, current_stage_id, pipeline_id')
        .eq('campaign_id', params.id).is('deleted_at', null)
        .order('value_amount', { ascending: false, nullsFirst: false }),
      supabase.schema('app').from('stages' as never).select('id, name'),
      supabase.schema('app').from('pipelines' as never).select('id, code, name'),
    ]);

  const forecast = (forecastData ?? { deal_count: 0, total_value: 0, weighted_forecast: 0 }) as Forecast;
  const deals = (dealsData ?? []) as unknown as DealRow[];
  const stageName = new Map(
    ((stagesData ?? []) as unknown as Array<{ id: string; name: string }>).map((s) => [s.id, s.name]),
  );
  const pipeline = new Map(
    ((pipelinesData ?? []) as unknown as Array<{ id: string; code: string; name: string }>).map((p) => [p.id, p]),
  );

  return (
    <div className="flex h-full flex-col">
      <div className="border-b bg-background px-6 py-4">
        <Link href="/campaigns" className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground">
          <ChevronLeft className="h-3 w-3" /> Campaigns
        </Link>
        <h1 className="mt-1 flex items-center gap-2 text-xl font-semibold text-foreground">
          <span className="h-3 w-3 rounded-full" style={{ backgroundColor: campaign.color ?? '#94a3b8' }} />
          {campaign.name}
        </h1>
        <div className="mt-1 flex flex-wrap items-center gap-x-2 text-xs text-muted-foreground">
          <span>{campaign.campaign_type ?? 'campaign'}</span>
          <span className="opacity-40">·</span>
          <span>{campaign.status}</span>
          <span className="opacity-40">·</span>
          <span>{campaign.start_date ?? '?'} ~ {campaign.end_date ?? '?'}</span>
        </div>
        {campaign.description ? (
          <p className="mt-2 max-w-2xl text-sm text-muted-foreground">{campaign.description}</p>
        ) : null}
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="mb-6 grid grid-cols-3 gap-3">
          <Stat label="Deals" value={String(forecast.deal_count)} />
          <Stat label="Total value" value={fmtMoney(forecast.total_value, null)} />
          <Stat label="Weighted forecast" value={fmtMoney(forecast.weighted_forecast, null)} />
        </div>

        <div className="rounded-lg border bg-card">
          <div className="border-b px-4 py-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Deals in this campaign
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/30 text-xs text-muted-foreground">
              <tr>
                <th className="px-4 py-2 text-left font-medium">Deal</th>
                <th className="px-4 py-2 text-left font-medium">Pipeline</th>
                <th className="px-4 py-2 text-left font-medium">Stage</th>
                <th className="px-4 py-2 text-left font-medium">Status</th>
                <th className="px-4 py-2 text-right font-medium">Value</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {deals.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">No deals linked yet.</td></tr>
              )}
              {deals.map((d) => {
                const p = d.pipeline_id ? pipeline.get(d.pipeline_id) : undefined;
                return (
                  <tr key={d.id} className="hover:bg-muted/30">
                    <td className="px-4 py-2 font-medium">
                      {p ? (
                        <Link href={'/pipelines/' + p.code + '/deals/' + d.id} className="hover:underline">
                          {d.deal_name}
                        </Link>
                      ) : d.deal_name}
                    </td>
                    <td className="px-4 py-2 text-muted-foreground">{p?.name ?? '-'}</td>
                    <td className="px-4 py-2 text-muted-foreground">{d.current_stage_id ? (stageName.get(d.current_stage_id) ?? '-') : '-'}</td>
                    <td className="px-4 py-2 text-muted-foreground">{d.status}</td>
                    <td className="px-4 py-2 text-right tabular-nums">{fmtMoney(d.value_amount, d.value_currency)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border bg-card p-4">
      <div className="text-xs uppercase tracking-wider text-muted-foreground">{label}</div>
      <div className="mt-1 text-2xl font-semibold tabular-nums text-foreground">{value}</div>
    </div>
  );
}
