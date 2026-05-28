// src/app/(app)/pipelines/[code]/actions.ts
//
// Server Actions for the pipeline kanban:
//   moveDealStage  -- drag-and-drop stage updates (existing)
//   createDeal     -- "+ New deal" modal in the kanban header
//   searchParties  -- debounced counterparty lookup in the modal
//
// All actions use RLS-scoped supabase server client; revalidatePath
// refreshes the kanban for the calling pipeline.

'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';

// ============================================================
// moveDealStage  (drag-and-drop)
// ============================================================

export async function moveDealStage(
  dealId: string,
  newStageId: string,
  pipelineCode: string
): Promise<{ ok: true } | { ok: false; error: string }> {
  if (!dealId || !newStageId || !pipelineCode) {
    return { ok: false, error: 'Missing required argument' };
  }

  const supabase = await createSupabaseServerClient();
  const nowIso = new Date().toISOString();

  const { error } = await supabase
    .schema('app')
    .from('deals' as never)
    .update({
      current_stage_id: newStageId,
      last_activity_at: nowIso,
    } as never)
    .eq('id', dealId);

  if (error) return { ok: false, error: error.message };

  revalidatePath('/pipelines/' + pipelineCode);
  return { ok: true };
}

// ============================================================
// createDeal  (New deal modal)
// ============================================================

interface CreateDealInput {
  pipelineCode: string;
  deal_name: string;
  party_id: string;
  current_stage_id: string;
  value_amount?: number | null;
  value_currency?: string;
}

export async function createDeal(
  input: CreateDealInput
): Promise<{ ok: true; dealId: string } | { ok: false; error: string }> {
  // Basic input validation -- the modal does this too, server-side is the
  // authoritative guard.
  const name = (input.deal_name ?? '').trim();
  if (!name) return { ok: false, error: 'Deal name is required' };
  if (!input.party_id) return { ok: false, error: 'Counterparty is required' };
  if (!input.current_stage_id) return { ok: false, error: 'Stage is required' };
  if (!input.pipelineCode) return { ok: false, error: 'Pipeline is required' };

  const supabase = await createSupabaseServerClient();

  // Resolve pipeline -> get id + organization_id in one shot. RLS scopes this
  // to the user's org, so the returned organization_id is guaranteed to be
  // the user's. No hardcoding.
  const { data: pipelineRow, error: pErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, organization_id')
    .eq('code', input.pipelineCode)
    .eq('is_active', true)
    .maybeSingle();

  if (pErr || !pipelineRow) {
    return { ok: false, error: 'Pipeline not found or inactive' };
  }
  const pipeline = pipelineRow as unknown as { id: string; organization_id: string };

  const nowIso = new Date().toISOString();

  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .insert({
      organization_id: pipeline.organization_id,
      pipeline_id: pipeline.id,
      current_stage_id: input.current_stage_id,
      party_id: input.party_id,
      deal_name: name,
      value_amount: input.value_amount ?? null,
      value_currency: input.value_currency ?? 'USD',
      last_activity_at: nowIso,
      source: 'manual',
      // status/priority/module_data fall back to their column defaults
    } as never)
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };

  revalidatePath('/pipelines/' + input.pipelineCode);
  return { ok: true, dealId: (data as any).id };
}

// ============================================================
// searchParties  (counterparty lookup in modal)
// ============================================================

export async function searchParties(query: string): Promise<
  Array<{ id: string; party_name: string; country_code: string | null }>
> {
  const supabase = await createSupabaseServerClient();
  const q = (query ?? '').trim();

  let req = supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name, country_code')
    .is('deleted_at', null)
    .order('party_name', { ascending: true })
    .limit(20);

  if (q) {
    req = req.ilike('party_name', '%' + q + '%');
  }

  const { data } = await req;
  return (data ?? []) as Array<{ id: string; party_name: string; country_code: string | null }>;
}
