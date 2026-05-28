// src/app/(app)/pipelines/[code]/page.tsx
// Server component: resolves the pipeline by code (RLS scopes to org),
// fetches stages + deals, hands off to the client kanban.

import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
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

  // 3) deals in this pipeline, joined to the counterparty (party) for the card
  const { data: dealsData } = await supabase
    .schema('app')
    .from('deals' as never)
    .select(
      'id, deal_name, current_stage_id, value_amount, value_currency, ' +
      'last_activity_at, status, primary_contact_id, ' +
      'party:parties(id, party_name, country_code)'
    )
    .eq('pipeline_id', pipeline.id)
    .is('deleted_at', null)
    .order('last_activity_at', { ascending: false, nullsFirst: false });

  return (
    <KanbanClient
      pipeline={pipeline}
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
        primary_contact_id: string | null;
        party: { id: string; party_name: string; country_code: string | null } | null;
      }>}
    />
  );
}