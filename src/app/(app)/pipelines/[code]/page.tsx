// src/app/(app)/pipelines/[code]/page.tsx
// Server component: resolves the pipeline by code (RLS scopes to org),
// fetches stages + deals, hands off to the client kanban.
//
// Round dimension (2026-06-02):
//   - deals embeds round:rounds(id, name) via deals.round_id FK.
//   - Investor pipeline only: full rounds list passed down (filter + selector).
//
// Multi-company / Stage 1-B (2026-06-02):
//   - deals.party_id was dropped. Companies now live in app.deal_parties (M:N),
//     each row carrying role + commitment_amount. The deal embeds them as
//     deal_parties(...). The card shows every company + the summed commitment.

import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { listRounds } from '@/lib/queries/rounds';
import { KanbanClient } from './kanban-client';

interface Props {
  params: { code: string };
}

export default async function PipelinePage({ params }: Props) {
  const supabase = await createSupabaseServerClient();

  // 1) pipeline by code (RLS auto-scopes to the user's organization)
  const { data: pipelineRow, error: pipelineErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name, description')
    .eq('code', params.code)
    .eq('is_active', true)
    .maybeSingle();

  if (pipelineErr || !pipelineRow) notFound();
  const pipeline = pipelineRow as unknown as {
    id: string; code: string; name: string; description: string | null;
  };

  // 2) stages for this pipeline (kanban columns)
  const { data: stagesData } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, code, name, sort_order')
    .eq('pipeline_id', pipeline.id)
    .order('sort_order', { ascending: true });

  // 3) deals in this pipeline, with their companies (deal_parties) + round.
  // round:rounds(...) embeds via deals.round_id, which is Investor-only and may
  // be absent from the live table. Embedding it on a non-investor board makes
  // PostgREST fail the whole select (-> 0 deals). So include it only for the
  // investor pipeline.
  const isInvestor = pipeline.code === 'investor';
  const dealSelect =
    'id, deal_name, current_stage_id, value_amount, value_currency, campaign_id, ' +
    'last_activity_at, status, ' +
    'deal_parties ( id, party_id, role, commitment_amount, currency, ' +
    '  parties ( party_name, country_code ) )' +
    (isInvestor ? ', round:rounds(id, name)' : '');

  const { data: dealsData } = await supabase
    .schema('app')
    .from('deals' as never)
    .select(dealSelect)
    .eq('pipeline_id', pipeline.id)
    .is('deleted_at', null)
    .order('last_activity_at', { ascending: false, nullsFirst: false });

  // 4) Investor pipeline only: rounds list for the filter + modal selector.
  const rounds =
    pipeline.code === 'investor'
      ? (await listRounds()).map((r) => ({ id: r.id, name: r.name }))
      : [];

  // 5) Campaigns (all pipelines): for the New Deal modal standalone/campaign choice.
  const { data: campaignsData } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .select('id, name, color')
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  const campaigns = (campaignsData ?? []) as unknown as Array<{
    id: string; name: string; color: string | null;
  }>;

  return (
    <KanbanClient
      pipeline={pipeline}
      rounds={rounds}
      campaigns={campaigns}
      stages={(stagesData ?? []) as unknown as Array<{
        id: string; code: string; name: string; sort_order: number;
      }>}
      deals={(dealsData ?? []) as unknown as Array<{
        id: string;
        deal_name: string;
        current_stage_id: string;
        value_amount: number | null;
        value_currency: string;
        last_activity_at: string | null;
        status: string;
        campaign_id: string | null;
        deal_parties: Array<{
          id: string;
          party_id: string;
          role: string;
          commitment_amount: number | string | null;
          currency: string;
          parties: { party_name: string; country_code: string | null } | null;
        }> | null;
        round: { id: string; name: string } | null;
      }>}
    />
  );
}
