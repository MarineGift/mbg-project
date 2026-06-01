// src/app/(app)/pipelines/[code]/deals/[id]/checklist-actions.ts
//
// Deal-scoped checklist Server Actions (app.deal_checklists):
//   addChecklistItem    -- "+ Add item"
//   toggleChecklistItem -- check / uncheck
//   deleteChecklistItem -- soft delete
//
// Mirrors ./actions.ts conventions:
//   - RLS-scoped server client; organization_id pulled from the deal row
//     (multi-tenant-safe). created_by / completed_by from auth.uid().
//   - revalidatePath refreshes the deal detail page after each mutation.
//   - app.deal_checklists columns: id, deal_id, organization_id, title,
//     is_complete, completed_at, completed_by, sort_order, deleted_at,
//     created_by, updated_by, created_at, updated_at.

'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';

type Result<T = {}> = ({ ok: true } & T) | { ok: false; error: string };

function dealPath(pipelineCode: string, dealId: string): string {
  return '/pipelines/' + pipelineCode + '/deals/' + dealId;
}

async function getUserId(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
): Promise<string | null> {
  const { data } = await supabase.auth.getUser();
  return data.user?.id ?? null;
}

// ============================================================
// addChecklistItem
// ============================================================

interface AddChecklistItemInput {
  pipelineCode: string;
  dealId: string;
  title: string;
}

export async function addChecklistItem(
  input: AddChecklistItemInput,
): Promise<Result<{ id: string }>> {
  const title = (input.title ?? '').trim();
  if (!title) return { ok: false, error: 'Title is required' };
  if (!input.dealId) return { ok: false, error: 'Missing deal' };

  const supabase = await createSupabaseServerClient();

  // Pull deal for organization_id (RLS-safe, multi-tenant correct).
  const { data: dealRow, error: dErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, organization_id')
    .eq('id', input.dealId)
    .is('deleted_at', null)
    .maybeSingle();
  if (dErr || !dealRow) return { ok: false, error: 'Deal not found or inaccessible' };
  const deal = dealRow as unknown as { id: string; organization_id: string };

  // Next sort_order = current max + 1 (keep new items at the bottom).
  const { data: lastRow } = await supabase
    .schema('app')
    .from('deal_checklists' as never)
    .select('sort_order')
    .eq('deal_id', deal.id)
    .is('deleted_at', null)
    .order('sort_order', { ascending: false, nullsFirst: false })
    .limit(1)
    .maybeSingle();
  const lastOrder = (lastRow as { sort_order: number | null } | null)?.sort_order ?? 0;

  const userId = await getUserId(supabase);

  const { data, error } = await supabase
    .schema('app')
    .from('deal_checklists' as never)
    .insert({
      organization_id: deal.organization_id,
      deal_id: deal.id,
      title,
      is_complete: false,
      sort_order: lastOrder + 1,
      created_by: userId,
    } as never)
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };

  revalidatePath(dealPath(input.pipelineCode, input.dealId));
  return { ok: true, id: (data as { id: string }).id };
}

// ============================================================
// toggleChecklistItem
// ============================================================

interface ToggleChecklistItemInput {
  pipelineCode: string;
  dealId: string;
  itemId: string;
  isComplete: boolean; // target state
}

export async function toggleChecklistItem(
  input: ToggleChecklistItemInput,
): Promise<Result> {
  if (!input.itemId) return { ok: false, error: 'Missing item' };
  const supabase = await createSupabaseServerClient();
  const userId = await getUserId(supabase);

  const { error } = await supabase
    .schema('app')
    .from('deal_checklists' as never)
    .update({
      is_complete: input.isComplete,
      completed_at: input.isComplete ? new Date().toISOString() : null,
      completed_by: input.isComplete ? userId : null,
      updated_by: userId,
    } as never)
    .eq('id', input.itemId)
    .eq('deal_id', input.dealId)
    .is('deleted_at', null);

  if (error) return { ok: false, error: error.message };

  revalidatePath(dealPath(input.pipelineCode, input.dealId));
  return { ok: true };
}

// ============================================================
// deleteChecklistItem (soft delete)
// ============================================================

interface DeleteChecklistItemInput {
  pipelineCode: string;
  dealId: string;
  itemId: string;
}

export async function deleteChecklistItem(
  input: DeleteChecklistItemInput,
): Promise<Result> {
  if (!input.itemId) return { ok: false, error: 'Missing item' };
  const supabase = await createSupabaseServerClient();
  const userId = await getUserId(supabase);

  const { error } = await supabase
    .schema('app')
    .from('deal_checklists' as never)
    .update({
      deleted_at: new Date().toISOString(),
      updated_by: userId,
    } as never)
    .eq('id', input.itemId)
    .eq('deal_id', input.dealId)
    .is('deleted_at', null);

  if (error) return { ok: false, error: error.message };

  revalidatePath(dealPath(input.pipelineCode, input.dealId));
  return { ok: true };
}
