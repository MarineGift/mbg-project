// src/app/(app)/pipelines/[code]/page.tsx
// Server component: resolves the pipeline by code (RLS scopes to org),
// fetches stages + deals, hands off to the client kanban.
//
// Round dimension (2026-06-05 fix):
//   - We deliberately do NOT use a PostgREST embed for the round
//     (previously: round:rounds(id, name) via deals.round_id). deals<->rounds
//     has more than one FK path, so PostgREST treats the embed as AMBIGUOUS and
//     fails the WHOLE select -> the investor board showed 0 deals even though
//     deals existed. We now select the raw round_id and join the round name in
//     memory from the rounds list that the investor board already fetches.
//
// Multi-company / Stage 1-B (2026-06-02):
//   - Companies live in app.deal_parties (M:N), each row carrying role +
//     commitment_amount. The deal embeds them as deal_parties(...). The card
//     shows every company + the summed commitment.

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

  // 3) deals in this pipeline, with their companies (deal_parties).
  // NOTE: round is joined in memory below (no embed) to avoid the ambiguous
  // deals<->rounds relationship that zeroed out the investor board.
  // NOTE: app.deals has NO round_id column (verified against information_schema).
  // Selecting it returned PostgREST 42703 (undefined column), which failed the
  // WHOLE deals query -> the board rendered 0 deals even though the deals exist
  // and are correctly staged. Until a real round linkage (column or junction)
  // is added, we drop round_id here and treat round as null below.
  const dealSelect =
    'id, deal_name, current_stage_id, value_amount, value_currency, campaign_id, ' +
    'start_date, end_date, expected_close_date, ' +
    'last_activity_at, status, ' +
    'deal_parties ( id, party_id, role, commitment_amount, currency, ' +
    '  parties ( party_name, country_code ) )';

  const { data: dealsData, error: dealsErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .select(dealSelect)
    .eq('pipeline_id', pipeline.id)
    .is('deleted_at', null)
    .order('last_activity_at', { ascending: false, nullsFirst: false });

  if (dealsErr) {
    // Surface the real reason in the server log instead of silently showing 0.
    console.error('[pipeline board] deals query failed:', dealsErr.message);
  }

  // 4) Investor pipeline only: rounds list for the filter + modal selector.
  const rounds =
    pipeline.code === 'investors'
      ? (await listRounds()).map((r) => ({ id: r.id, name: r.name }))
      : [];

  // Round name join: app.deals has no round_id, so there is nothing to join on.
  // Set round to null for every deal (the round filter defaults to 'all', so the
  // board still shows everything). Re-enable this once a round linkage exists.
  void rounds; // kept for the filter UI / New Deal modal selector
  const deals = ((dealsData ?? []) as Array<Record<string, unknown>>).map((d) => ({
    ...d,
    round: null as { id: string; name: string } | null,
  }));

  // Campaigns (all pipelines) for the New Deal modal + board filter.
  const { data: campaignsData } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .select('id, name, color, start_date, end_date')
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  const campaigns = (campaignsData ?? []) as unknown as Array<{
    id: string; name: string; color: string | null; start_date: string | null; end_date: string | null;
  }>;

  return (
    <KanbanClient
      pipeline={pipeline}
      rounds={rounds}
      campaigns={campaigns}
      stages={(stagesData ?? []) as unknown as Array<{
        id: string; code: string; name: string; sort_order: number;
      }>}
      deals={deals as unknown as Array<{
        id: string;
        deal_name: string;
        current_stage_id: string;
        value_amount: number | null;
        value_currency: string;
        last_activity_at: string | null;
        status: string;
        campaign_id: string | null;
        start_date: string | null;
        end_date: string | null;
        expected_close_date: string | null;
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
