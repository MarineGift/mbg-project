// src/app/(app)/tasks/actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient } from '@/lib/supabase/server'

type Result<T = {}> = ({ ok: true } & T) | { ok: false; error: string }

// due_at is stored as UTC noon so the calendar date survives any tz offset
function toUtcNoon(dateStr: string | null | undefined): string | null {
  if (!dateStr) return null
  const [y, m, d] = dateStr.split('-').map(Number)
  if (!y || !m || !d) return null
  return new Date(Date.UTC(y, m - 1, d, 12, 0, 0)).toISOString()
}

/**
 * Flip a task between pending <-> completed.
 * Re-used by both /tasks and the deal-detail Tasks tab (pass dealPath to revalidate it).
 */
export async function toggleTaskStatus(
  taskId: string,
  newStatus: 'pending' | 'completed',
  dealPath?: string
): Promise<Result> {
  const supabase = await createSupabaseServerClient()

  const { error } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({
      status: newStatus,
      completed_at: newStatus === 'completed' ? new Date().toISOString() : null,
    } as never)
    .eq('id', taskId)

  if (error) return { ok: false, error: error.message }

  revalidatePath('/tasks')
  if (dealPath) revalidatePath(dealPath)
  else revalidatePath('/pipelines', 'layout')
  return { ok: true }
}

export type AddTaskInput = {
  title: string
  dealId: string
  dueDate?: string | null // 'YYYY-MM-DD'
  priority: 'low' | 'medium' | 'high'
  assigneeContactId?: string | null
  description?: string | null
}

export async function addTask(input: AddTaskInput): Promise<Result<{ id: string }>> {
  const supabase = await createSupabaseServerClient()

  const title = input.title.trim()
  if (!title) return { ok: false, error: 'Title is required.' }
  if (!input.dealId) return { ok: false, error: 'Pick a deal for this task.' }

  // organization_id is always pulled from the related row (RLS-safe / multi-tenant-ready)
  const { data: deal, error: dealErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, organization_id')
    .eq('id', input.dealId)
    .single()

  if (dealErr || !deal) {
    return { ok: false, error: dealErr?.message ?? 'Deal not found.' }
  }

  const payload = {
    title,
    deal_id: input.dealId,
    organization_id: (deal as any).organization_id,
    priority: input.priority,
    status: 'pending',
    due_at: toUtcNoon(input.dueDate),
    assigned_to_contact_id: input.assigneeContactId || null,
    description: input.description?.trim() || null,
  }

  const { data, error } = await supabase
    .schema('app')
    .from('tasks' as never)
    .insert([payload] as any)
    .select('id')
    .single()

  if (error) return { ok: false, error: error.message }

  revalidatePath('/tasks')
  revalidatePath('/pipelines', 'layout')
  return { ok: true, id: (data as any).id }
}

export type DealHit = {
  id: string
  deal_name: string
  pipeline: { code: string; name: string } | null
}

export async function searchDeals(query: string): Promise<DealHit[]> {
  const q = query.trim()
  if (q.length < 1) return []
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, deal_name, pipeline:pipelines!pipeline_id(code, name)')
    .ilike('deal_name', `%${q}%`)
    .limit(8)

  if (error) return []
  return (data ?? []) as unknown as DealHit[]
}

export type ContactHit = {
  id: string
  full_name: string | null
  given_name: string | null
  family_name: string | null
  title_text: string | null
  firm: { party_name: string | null } | null
}

export async function searchContacts(query: string): Promise<ContactHit[]> {
  const q = query.trim()
  if (q.length < 1) return []
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select(
      'id, full_name, given_name, family_name, title_text, firm:parties!party_id(party_name)'
    )
    .or(`full_name.ilike.%${q}%,title_text.ilike.%${q}%`)
    .eq('is_active', true)
    .limit(8)

  if (error) return []
  return (data ?? []) as unknown as ContactHit[]
}
