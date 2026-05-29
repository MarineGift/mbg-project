// src/lib/actions/pipeline-stages.ts
// Pipeline stage admin CRUD server actions. Rewritten for the normalized
// `stages` model (D9 cleanup): stages.pipeline_id -> pipelines.id.
// Notes: `stages` has no `stage_type` column and no `deleted_at`
// (soft-delete uses is_active=false).
'use server'

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export type StageInput = {
  code: string
  name: string
  description: string
  sort_order: number
  default_probability_pct: number
  is_terminal: boolean
  is_won: boolean
  is_lost: boolean
  color_hex: string
}

// ---------------------------------------------------------------------------
// CREATE
// ---------------------------------------------------------------------------
export async function createStage(
  input: StageInput & { pipeline_id: string },
) {
  const supabase = await createSupabaseServerClient()

  // look up organization_id from the parent pipeline
  const { data: pipeline, error: pipelineErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('organization_id')
    .eq('id', input.pipeline_id)
    .single()

  if (pipelineErr || !pipeline) {
    return { error: 'Pipeline not found' }
  }

  const { error } = await supabase
    .schema('app')
    .from('stages' as never)
    .insert({
      organization_id: (pipeline as { organization_id: string }).organization_id,
      pipeline_id: input.pipeline_id,
      code: input.code,
      name: input.name,
      description: input.description || null,
      sort_order: input.sort_order,
      default_probability_pct: input.default_probability_pct,
      is_terminal: input.is_terminal,
      is_won: input.is_won,
      is_lost: input.is_lost,
      color_hex: input.color_hex,
    } as never)

  if (error) {
    console.error('[createStage]', error)
    return { error: error.message }
  }

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ---------------------------------------------------------------------------
// UPDATE
// ---------------------------------------------------------------------------
export async function updateStage(stageId: string, input: StageInput) {
  const supabase = await createSupabaseServerClient()

  const { error } = await supabase
    .schema('app')
    .from('stages' as never)
    .update({
      code: input.code,
      name: input.name,
      description: input.description || null,
      sort_order: input.sort_order,
      default_probability_pct: input.default_probability_pct,
      is_terminal: input.is_terminal,
      is_won: input.is_won,
      is_lost: input.is_lost,
      color_hex: input.color_hex,
    } as never)
    .eq('id', stageId)

  if (error) {
    console.error('[updateStage]', error)
    return { error: error.message }
  }

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ---------------------------------------------------------------------------
// DELETE (soft) -- stages has no deleted_at; use is_active = false
// ---------------------------------------------------------------------------
export async function deleteStage(stageId: string) {
  const supabase = await createSupabaseServerClient()

  const { error } = await supabase
    .schema('app')
    .from('stages' as never)
    .update({ is_active: false } as never)
    .eq('id', stageId)

  if (error) {
    console.error('[deleteStage]', error)
    return { error: error.message }
  }

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ---------------------------------------------------------------------------
// REORDER -- move stage up
// ---------------------------------------------------------------------------
export async function moveStageUp(stageId: string) {
  const supabase = await createSupabaseServerClient()

  const { data: current, error: currentErr } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, pipeline_id, sort_order')
    .eq('id', stageId)
    .single()

  if (currentErr || !current) return { error: 'Stage not found' }
  const c = current as { id: string; pipeline_id: string; sort_order: number }

  // find the nearest active stage above (largest sort_order < current)
  const { data: above } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, sort_order')
    .eq('pipeline_id', c.pipeline_id)
    .eq('is_active', true)
    .lt('sort_order', c.sort_order)
    .order('sort_order', { ascending: false })
    .limit(1)
    .single()

  if (!above) return { success: true } // already first

  const a = above as { id: string; sort_order: number }
  await swapSortOrder(supabase, c.id, c.sort_order, a.id, a.sort_order)

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ---------------------------------------------------------------------------
// REORDER -- move stage down
// ---------------------------------------------------------------------------
export async function moveStageDown(stageId: string) {
  const supabase = await createSupabaseServerClient()

  const { data: current, error: currentErr } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, pipeline_id, sort_order')
    .eq('id', stageId)
    .single()

  if (currentErr || !current) return { error: 'Stage not found' }
  const c = current as { id: string; pipeline_id: string; sort_order: number }

  const { data: below } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, sort_order')
    .eq('pipeline_id', c.pipeline_id)
    .eq('is_active', true)
    .gt('sort_order', c.sort_order)
    .order('sort_order', { ascending: true })
    .limit(1)
    .single()

  if (!below) return { success: true }

  const b = below as { id: string; sort_order: number }
  await swapSortOrder(supabase, c.id, c.sort_order, b.id, b.sort_order)

  revalidatePath('/settings/pipelines')
  return { success: true }
}

// ---------------------------------------------------------------------------
// Helper: swap sort_order of two stages (temp -1 to avoid unique collisions)
// ---------------------------------------------------------------------------
async function swapSortOrder(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  idA: string,
  orderA: number,
  idB: string,
  orderB: number,
) {
  await supabase.schema('app').from('stages' as never)
    .update({ sort_order: -1 } as never).eq('id', idA)
  await supabase.schema('app').from('stages' as never)
    .update({ sort_order: orderA } as never).eq('id', idB)
  await supabase.schema('app').from('stages' as never)
    .update({ sort_order: orderB } as never).eq('id', idA)
}
