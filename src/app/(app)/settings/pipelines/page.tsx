// src/app/(app)/settings/pipelines/page.tsx
// v5.9 Step C-3: Pipeline Stages Admin Page (Server Component)
//
// Fix (2026-06-10): rewritten for the normalized schema (D9 cleanup).
//   - Old code queried app.pipeline_definitions / app.pipeline_stages,
//     which DO NOT exist (verified against information_schema) -> both
//     fetches errored -> empty partyTypeGroups -> the admin UI (which is
//     fully built in PipelinesAdminClient + StageFormDialog) never showed.
//   - Live schema: app.pipelines (code/name/is_default/is_active/sort_order)
//     -> app.stages (pipeline_id FK, is_active soft delete, NO deleted_at,
//     NO stage_type). Same model already used by the kanban board and by
//     actions/pipeline-stages.ts.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { PipelinesAdminClient } from './PipelinesAdminClient'
import type { Definition, Stage } from './PipelinesAdminClient'

export const dynamic = 'force-dynamic'

interface RawPipeline {
  id: string
  organization_id: string
  code: string
  name: string
  description: string | null
  is_default: boolean
  is_active: boolean
  sort_order: number
}

export default async function PipelinesAdminPage() {
  const supabase = await createSupabaseServerClient()

  // 1) pipelines (RLS scopes to the user's organization)
  const { data: pipelinesData, error: pipelinesErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, organization_id, code, name, description, is_default, is_active, sort_order')
    .order('sort_order', { ascending: true })
    .order('name', { ascending: true })

  if (pipelinesErr) {
    console.error('[PipelinesAdminPage] pipelines fetch error:', pipelinesErr)
  }

  const pipelines = (pipelinesData ?? []) as unknown as RawPipeline[]
  const pipelineIds = pipelines.map((p) => p.id)

  // 2) active stages for all pipelines at once
  //    (delete is soft: is_active=false -- see actions/pipeline-stages.ts)
  let stages: Stage[] = []
  if (pipelineIds.length > 0) {
    const { data: stagesData, error: stagesErr } = await supabase
      .schema('app')
      .from('stages' as never)
      .select(
        'id, pipeline_id, code, name, description, sort_order, ' +
          'default_probability_pct, is_terminal, is_won, is_lost, color_hex',
      )
      .in('pipeline_id', pipelineIds)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })

    if (stagesErr) {
      console.error('[PipelinesAdminPage] stages fetch error:', stagesErr)
    }
    stages = (stagesData ?? []) as unknown as Stage[]
  }

  // 3) group stages by pipeline
  const stagesByPipeline: Record<string, Stage[]> = {}
  for (const s of stages) {
    if (!stagesByPipeline[s.pipeline_id]) {
      stagesByPipeline[s.pipeline_id] = []
    }
    stagesByPipeline[s.pipeline_id]!.push(s)
  }

  // 4) shape for the client (Definition.module <- pipelines.code)
  const partyTypeGroups = pipelines.map((p) => ({
    definition: {
      id: p.id,
      organization_id: p.organization_id,
      module: p.code,
      name: p.name,
      description: p.description,
      is_default: p.is_default,
      is_active: p.is_active,
    } satisfies Definition,
    stages: stagesByPipeline[p.id] ?? [],
  }))

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-3xl font-bold">Pipeline Stages</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Manage engagement pipeline stages per module. Each module can have its own distinct stage flow.
        </p>
      </div>

      <PipelinesAdminClient partyTypeGroups={partyTypeGroups} />
    </div>
  )
}
