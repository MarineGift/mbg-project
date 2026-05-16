// src/app/(app)/settings/pipelines/page.tsx
// v5.9 Step C-3: Pipeline Stages Admin Page (Server Component)

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { PipelinesAdminClient } from './PipelinesAdminClient'

export const dynamic = 'force-dynamic'

export default async function PipelinesAdminPage() {
  const supabase = await createSupabaseServerClient()

  // 1) pipeline_definitions fetch
  const { data: definitions, error: defnErr } = await supabase
    .schema('app' as never)
    .from('pipeline_definitions')
    .select('id, organization_id, module, name, description, is_default, is_active')
    .is('deleted_at', null)
    .order('module', { ascending: true })

  if (defnErr) {
    console.error('[PipelinesAdminPage] definitions fetch error:', defnErr)
  }

  const defns = (definitions ?? []) as any[]
  const defnIds = defns.map((d) => d.id)

  // 2) pipeline_stages fetch (모든 정의의 stages 한 번에)
  let stages: any[] = []
  if (defnIds.length > 0) {
    const { data: stagesRaw, error: stagesErr } = await supabase
      .schema('app' as never)
      .from('pipeline_stages')
      .select(
        `id, pipeline_definition_id, code, name, description, stage_type,
         sort_order, default_probability_pct,
         is_terminal, is_won, is_lost, color_hex`,
      )
      .in('pipeline_definition_id', defnIds)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true })

    if (stagesErr) {
      console.error('[PipelinesAdminPage] stages fetch error:', stagesErr)
    }
    stages = stagesRaw ?? []
  }

  // 3) definition별로 stages 그룹화
  const stagesByDef: Record<string, any[]> = {}
  for (const s of stages) {
    if (!stagesByDef[s.pipeline_definition_id]) {
      stagesByDef[s.pipeline_definition_id] = []
    }
    stagesByDef[s.pipeline_definition_id].push(s)
  }

  const moduleGroups = defns.map((d) => ({
    definition: d,
    stages: stagesByDef[d.id] ?? [],
  }))

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-3xl font-bold">Pipeline Stages</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Manage engagement pipeline stages per module. Each module can have its own distinct stage flow.
        </p>
      </div>

      <PipelinesAdminClient moduleGroups={moduleGroups} />
    </div>
  )
}
