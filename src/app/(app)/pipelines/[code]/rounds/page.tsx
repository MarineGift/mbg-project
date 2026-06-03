// src/app/(app)/pipelines/[code]/rounds/page.tsx
//
// Round management screen (Investor pipeline only).
//   - Lists fundraising rounds (app.rounds) with derived rollups:
//     committed total, deal count, target progress, per-stage breakdown.
//   - Create / edit / delete rounds via lib/actions/rounds.ts.
//
// Rounds are an Investor-only dimension (only investor deals carry round_id),
// so any non-investor [code] 404s. Reached from the board header "Rounds" link.

import { notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { listRoundsWithRollup } from '@/lib/queries/rounds';
import { RoundsClient } from './rounds-client';

interface Props {
  params: { code: string };
}

export default async function RoundsPage({ params }: Props) {
  // Rounds only make sense for the investor pipeline.
  if (params.code !== 'investor') notFound();

  const supabase = await createSupabaseServerClient();

  // Confirm the pipeline exists + is visible under RLS (and get its name).
  const { data: pipelineRow, error: pipelineErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name')
    .eq('code', params.code)
    .eq('is_active', true)
    .maybeSingle();

  if (pipelineErr || !pipelineRow) notFound();
  const pipeline = pipelineRow as unknown as {
    id: string;
    code: string;
    name: string;
  };

  const rounds = await listRoundsWithRollup();

  return <RoundsClient pipelineName={pipeline.name} rounds={rounds} />;
}
