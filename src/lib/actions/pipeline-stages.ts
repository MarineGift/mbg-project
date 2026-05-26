// src/lib/actions/pipeline-stages.ts
// v5.9 Step C-3: Pipeline Stages admin CRUD server actions
'use server'

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export type StageInput = {
  code: string
  name: string
  description: string
  stage_type: string
  sort_order: number
  default_probability_pct: number
  is_terminal: boolean
  is_won: boolean
  is_lost: boolean
  color_hex: string
}

// ────────────────────────────────────────────────────────────────────────
// CREATE
// ────────────────────────────────────────────────────────────────────────
export async function createStage(
  input: StageInput & { pipeline_definition_id: string },
) {
  const supabase = await createSupabaseServerClient()

  // organization_id를 definition에서 lookup
  const { data: defn, error: defnErr } = await supabase
    .schema('app')
    .from('pipeline_definitions' as never)
    .select('organization_id')
    .eq('id', input.pipeline_definition_id)
    .single()

  if (defnErr || !defn) {
    return { error: 'Pipeline definition not found' }
  }

  const { error } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .insert({
      organization_id: (defn as any).organization_id,
      pipeline_definition_id: input.pipeline_definition_id,
      code: input.code,
      name: input.name,
      description: input.description || null,
      stage_type: input.stage_type as never,
      sort_order: input.sort_order,
      default_probability_pct: input.default_probability_pct,
      is_terminal: input.is_terminal,
      is_won: input.is_won,
      is_lost: input.is_lost,
      color_hex: input.color_hex,
    })

  if (error) {
    console.error('[createStage]', error)
    return { error: error.message }
  }

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ────────────────────────────────────────────────────────────────────────
// UPDATE
// ────────────────────────────────────────────────────────────────────────
export async function updateStage(stageId: string, input: StageInput) {
  const supabase = await createSupabaseServerClient()

  const { error } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .update({
      code: input.code,
      name: input.name,
      description: input.description || null,
      stage_type: input.stage_type as never,
      sort_order: input.sort_order,
      default_probability_pct: input.default_probability_pct,
      is_terminal: input.is_terminal,
      is_won: input.is_won,
      is_lost: input.is_lost,
      color_hex: input.color_hex,
    })
    .eq('id', stageId)

  if (error) {
    console.error('[updateStage]', error)
    return { error: error.message }
  }

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ────────────────────────────────────────────────────────────────────────
// DELETE (soft)
// ────────────────────────────────────────────────────────────────────────
export async function deleteStage(stageId: string) {
  const supabase = await createSupabaseServerClient()

  const { error } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', stageId)

  if (error) {
    console.error('[deleteStage]', error)
    return { error: error.message }
  }

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ────────────────────────────────────────────────────────────────────────
// REORDER — Move stage up
// ────────────────────────────────────────────────────────────────────────
export async function moveStageUp(stageId: string) {
  const supabase = await createSupabaseServerClient()

  // 1) 현재 stage 정보
  const { data: current, error: currentErr } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .select('id, pipeline_definition_id, sort_order')
    .eq('id', stageId)
    .single()

  if (currentErr || !current) return { error: 'Stage not found' }
  const c = current as any

  // 2) 바로 위 stage 찾기 (sort_order < 현재값 중 최대)
  const { data: above } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .select('id, sort_order')
    .eq('pipeline_definition_id', c.pipeline_definition_id)
    .is('deleted_at', null)
    .lt('sort_order', c.sort_order)
    .order('sort_order', { ascending: false })
    .limit(1)
    .single()

  if (!above) return { success: true } // 이미 맨 위

  const a = above as any
  await swapSortOrder(supabase, c.id, c.sort_order, a.id, a.sort_order)

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ────────────────────────────────────────────────────────────────────────
// REORDER — Move stage down
// ────────────────────────────────────────────────────────────────────────
export async function moveStageDown(stageId: string) {
  const supabase = await createSupabaseServerClient()

  const { data: current, error: currentErr } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .select('id, pipeline_definition_id, sort_order')
    .eq('id', stageId)
    .single()

  if (currentErr || !current) return { error: 'Stage not found' }
  const c = current as any

  const { data: below } = await supabase
    .schema('app')
    .from('pipeline_stages')
    .select('id, sort_order')
    .eq('pipeline_definition_id', c.pipeline_definition_id)
    .is('deleted_at', null)
    .gt('sort_order', c.sort_order)
    .order('sort_order', { ascending: true })
    .limit(1)
    .single()

  if (!below) return { success: true }

  const b = below as any
  await swapSortOrder(supabase, c.id, c.sort_order, b.id, b.sort_order)

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ────────────────────────────────────────────────────────────────────────
// Helper: 두 stage의 sort_order swap (unique constraint 가능성 대비 temp 사용)
// ────────────────────────────────────────────────────────────────────────
async function swapSortOrder(
  supabase: any,
  idA: string,
  orderA: number,
  idB: string,
  orderB: number,
) {
  // A를 임시 값으로
  await supabase
    .schema('app')
    .from('pipeline_stages')
    .update({ sort_order: -1 })
    .eq('id', idA)

  // B를 A의 원래 값으로
  await supabase
    .schema('app')
    .from('pipeline_stages')
    .update({ sort_order: orderA })
    .eq('id', idB)

  // A를 B의 원래 값으로
  await supabase
    .schema('app')
    .from('pipeline_stages')
    .update({ sort_order: orderB })
    .eq('id', idA)
}
