// src/app/(app)/pipelines/[code]/deals/[id]/actions.ts
//
// Deal-scoped Server Actions:
//   logEngagement   -- Activity tab "Log activity" modal
//   addTask         -- Tasks tab "Add task" modal
//   searchContacts  -- contact lookup used as assignee selector
//
// All actions use the RLS-scoped server client. revalidatePath refreshes
// the specific deal detail page (and kanban where relevant).

'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';

// ============================================================
// logEngagement
// ============================================================

interface LogEngagementInput {
  pipelineCode: string;
  dealId: string;
  engagement_type_id: number;
  title: string;
  occurred_at: string;
  direction?: string | null;
  summary?: string | null;
  notes?: string | null;
}

export async function logEngagement(
  input: LogEngagementInput
): Promise<{ ok: true; engagementId: string } | { ok: false; error: string }> {
  const title = (input.title ?? '').trim();
  if (!title) return { ok: false, error: 'Title is required' };
  if (!input.dealId) return { ok: false, error: 'Missing deal' };
  if (!input.engagement_type_id) return { ok: false, error: 'Activity type is required' };
  if (!input.occurred_at) return { ok: false, error: 'Time is required' };

  const supabase = await createSupabaseServerClient();

  const { data: dealRow, error: dErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, organization_id')
    .eq('id', input.dealId)
    .is('deleted_at', null)
    .maybeSingle();

  if (dErr || !dealRow) return { ok: false, error: 'Deal not found or inaccessible' };
  const deal = dealRow as unknown as { id: string; organization_id: string };

  // engagements.party_id is denormalized. deals.party_id was dropped; the deal's
  // companies now live in app.deal_parties. Use the lead/primary company.
  const { data: dpRows } = await supabase
    .schema('app')
    .from('deal_parties' as never)
    .select('party_id, role')
    .eq('deal_id', deal.id);
  const roleRank: Record<string, number> = {
    lead: 0, co_investor: 1, participant: 2, advisor: 3, primary: 4,
  };
  const leadPartyId =
    ((dpRows ?? []) as Array<{ party_id: string; role: string }>)
      .slice()
      .sort((a, b) => (roleRank[a.role] ?? 9) - (roleRank[b.role] ?? 9))[0]?.party_id ?? null;

  const { data, error } = await supabase
    .schema('app')
    .from('engagements' as never)
    .insert({
      organization_id: deal.organization_id,
      deal_id: deal.id,
      party_id: leadPartyId,
      engagement_type_id: input.engagement_type_id,
      title,
      occurred_at: input.occurred_at,
      direction: input.direction ?? null,
      summary: (input.summary ?? '').trim() || null,
      notes: (input.notes ?? '').trim() || null,
    } as never)
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };

  await supabase
    .schema('app')
    .from('deals' as never)
    .update({ last_activity_at: input.occurred_at } as never)
    .eq('id', deal.id);

  revalidatePath('/pipelines/' + input.pipelineCode + '/deals/' + input.dealId);
  revalidatePath('/pipelines/' + input.pipelineCode);
  return { ok: true, engagementId: (data as any).id };
}

// ============================================================
// addTask
// ============================================================

interface AddTaskInput {
  pipelineCode: string;
  dealId: string;
  title: string;
  due_at?: string | null;          // ISO timestamp or null
  priority?: 'low' | 'medium' | 'high';
  assigned_to_contact_id?: string | null;
  description?: string | null;
}

export async function addTask(
  input: AddTaskInput
): Promise<{ ok: true; taskId: string } | { ok: false; error: string }> {
  const title = (input.title ?? '').trim();
  if (!title) return { ok: false, error: 'Title is required' };
  if (!input.dealId) return { ok: false, error: 'Missing deal' };

  const supabase = await createSupabaseServerClient();

  // Pull deal to get organization_id (RLS-safe). tasks.organization_id has
  // a default of the marinebiogroup org id, but pulling it from the deal is
  // safer for multi-tenant correctness.
  const { data: dealRow, error: dErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, organization_id')
    .eq('id', input.dealId)
    .is('deleted_at', null)
    .maybeSingle();

  if (dErr || !dealRow) return { ok: false, error: 'Deal not found or inaccessible' };
  const deal = dealRow as unknown as { id: string; organization_id: string };

  const { data, error } = await supabase
    .schema('app')
    .from('tasks' as never)
    .insert({
      organization_id: deal.organization_id,
      deal_id: deal.id,
      title,
      status: 'pending',
      priority: input.priority ?? 'medium',
      due_at: input.due_at ?? null,
      assigned_to_contact_id: input.assigned_to_contact_id ?? null,
      description: (input.description ?? '').trim() || null,
    } as never)
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };

  revalidatePath('/pipelines/' + input.pipelineCode + '/deals/' + input.dealId);
  return { ok: true, taskId: (data as any).id };
}

// ============================================================
// searchContacts  (assignee selector)
// ============================================================

interface ContactResult {
  id: string;
  full_name: string | null;
  given_name: string | null;
  family_name: string | null;
  email: string | null;
  title_text: string | null;
  firm: { party_name: string | null } | null;
}

export async function searchContacts(query: string): Promise<ContactResult[]> {
  const supabase = await createSupabaseServerClient();
  const q = (query ?? '').trim();

  // Empty query => return nothing. UX prompt "Type to search..." in the input.
  if (!q) return [];

  // Match on any of name fields or email
  const pattern = '%' + q + '%';
  const { data } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select(
      'id, full_name, given_name, family_name, email, title_text, ' +
      'firm:parties!party_id(party_name)'
    )
    .is('deleted_at', null)
    .eq('is_active', true)
    .or(
      'full_name.ilike.' + pattern +
      ',given_name.ilike.' + pattern +
      ',family_name.ilike.' + pattern +
      ',email.ilike.' + pattern
    )
    .order('full_name', { ascending: true, nullsFirst: false })
    .limit(20);

  return (data ?? []) as unknown as ContactResult[];
}
