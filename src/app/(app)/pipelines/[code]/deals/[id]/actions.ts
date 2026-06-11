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
  // Optional Task this activity belongs to (engagements.task_id FK -> app.tasks).
  // null = activity sits directly on the deal timeline (HubSpot-style optional
  // association, not a hard parent-child).
  task_id?: string | null;
  // Optional attendees/participants for meeting/call/message/consultation.
  // Each is either a registered contact (contact_id) or a free-typed person
  // (name/email). Stored in app.engagement_participants after the engagement
  // is created. Empty/omitted = "attendees unknown" (attach later).
  participants?: Array<{
    contact_id?: string | null;
    name?: string | null;
    email?: string | null;
  }>;
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

  // If a task was chosen, verify it belongs to THIS deal (not soft-deleted)
  // before linking. null = activity stays directly on the deal timeline.
  let taskId: string | null = null;
  if (input.task_id) {
    const { data: tRow } = await supabase
      .schema('app')
      .from('tasks' as never)
      .select('id')
      .eq('id', input.task_id)
      .eq('deal_id', deal.id)
      .is('deleted_at', null)
      .maybeSingle();
    if (!tRow) return { ok: false, error: 'Task not found on this deal' };
    taskId = (tRow as { id: string }).id;
  }

  const { data, error } = await supabase
    .schema('app')
    .from('engagements' as never)
    .insert({
      organization_id: deal.organization_id,
      deal_id: deal.id,
      party_id: leadPartyId,
      task_id: taskId,
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

  const engagementId = (data as any).id as string;

  // Save participants (best-effort; never fail the whole log on a participant
  // hiccup). Only rows with a contact_id OR a name/email are kept.
  const rawParts = input.participants ?? [];
  const partRows = rawParts
    .map((p) => ({
      organization_id: deal.organization_id,
      engagement_id: engagementId,
      contact_id: p.contact_id ?? null,
      email: (p.email ?? '').trim() || null,
      name: (p.name ?? '').trim() || null,
    }))
    .filter((p) => p.contact_id || p.email || p.name);
  if (partRows.length > 0) {
    const { error: partErr } = await supabase
      .schema('app')
      .from('engagement_participants' as never)
      .insert(partRows as never);
    if (partErr) {
      // keep the engagement; surface a soft warning via console
      console.error('[logEngagement] participants insert error:', partErr.message);
    }
  }

  await supabase
    .schema('app')
    .from('deals' as never)
    .update({ last_activity_at: input.occurred_at } as never)
    .eq('id', deal.id);

  revalidatePath('/pipelines/' + input.pipelineCode + '/deals/' + input.dealId);
  revalidatePath('/pipelines/' + input.pipelineCode);
  return { ok: true, engagementId };
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
  // Optional Checklist item this task belongs to (tasks.checklist_id FK
  // -> app.deal_checklists). null = standalone ("Other tasks").
  checklist_id?: string | null;
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

  // If a checklist item was chosen, verify it belongs to THIS deal (and is
  // not soft-deleted) before linking, so a task can't point at another deal's
  // checklist item.
  let checklistId: string | null = null;
  if (input.checklist_id) {
    const { data: clRow } = await supabase
      .schema('app')
      .from('deal_checklists' as never)
      .select('id')
      .eq('id', input.checklist_id)
      .eq('deal_id', deal.id)
      .is('deleted_at', null)
      .maybeSingle();
    if (!clRow) return { ok: false, error: 'Checklist item not found on this deal' };
    checklistId = (clRow as { id: string }).id;
  }

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
      checklist_id: checklistId,
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

// Party-scoped contact search for the Activity composer's participant picker.
// Returns the given company's contacts (optionally filtered by query).
export async function searchPartyContacts(
  partyId: string,
  query: string,
): Promise<ContactResult[]> {
  if (!partyId) return [];
  const supabase = await createSupabaseServerClient();
  const q = (query ?? '').trim();

  let qb = supabase
    .schema('app')
    .from('contacts' as never)
    .select(
      'id, full_name, given_name, family_name, email, title_text, ' +
      'firm:parties!party_id(party_name)'
    )
    .eq('party_id', partyId)
    .is('deleted_at', null)
    .eq('is_active', true);

  if (q) {
    const pattern = '%' + q + '%';
    qb = qb.or(
      'full_name.ilike.' + pattern +
      ',given_name.ilike.' + pattern +
      ',family_name.ilike.' + pattern +
      ',email.ilike.' + pattern
    );
  }

  const { data } = await qb
    .order('is_primary', { ascending: false })
    .order('full_name', { ascending: true, nullsFirst: false })
    .limit(20);

  return (data ?? []) as unknown as ContactResult[];
}

interface UpdateTaskInput {
  pipelineCode: string;
  dealId: string;
  taskId: string;
  title?: string;
  description?: string | null;
  priority?: 'low' | 'medium' | 'high';
  due_at?: string | null; // ISO or null
  checklist_id?: string | null; // re-parent to a checklist (or detach with null)
}

export async function updateTask(
  input: UpdateTaskInput
): Promise<{ ok: true } | { ok: false; error: string }> {
  if (!input.taskId) return { ok: false, error: 'Missing task' };
  if (!input.dealId) return { ok: false, error: 'Missing deal' };

  const supabase = await createSupabaseServerClient();

  // If re-parenting, verify the checklist belongs to THIS deal.
  let checklistId: string | null | undefined = undefined;
  if (input.checklist_id !== undefined) {
    if (input.checklist_id) {
      const { data: clRow } = await supabase
        .schema('app')
        .from('deal_checklists' as never)
        .select('id')
        .eq('id', input.checklist_id)
        .eq('deal_id', input.dealId)
        .is('deleted_at', null)
        .maybeSingle();
      if (!clRow) return { ok: false, error: 'Checklist item not found on this deal' };
      checklistId = (clRow as { id: string }).id;
    } else {
      checklistId = null;
    }
  }

  const updates: Record<string, unknown> = {};
  if (input.title !== undefined) {
    const t = input.title.trim();
    if (!t) return { ok: false, error: 'Title is required' };
    updates.title = t;
  }
  if (input.description !== undefined) updates.description = (input.description ?? '').trim() || null;
  if (input.priority !== undefined) updates.priority = input.priority;
  if (input.due_at !== undefined) updates.due_at = input.due_at ?? null;
  if (checklistId !== undefined) updates.checklist_id = checklistId;

  if (Object.keys(updates).length === 0) return { ok: true };

  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update(updates as never)
    .eq('id', input.taskId)
    .eq('deal_id', input.dealId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  if (!data) return { ok: false, error: 'Task not found on this deal' };

  revalidatePath('/pipelines/' + input.pipelineCode + '/deals/' + input.dealId);
  return { ok: true };
}

// ============================================================
// toggleTaskInDeal  (status pending <-> completed)
// ============================================================

interface ToggleTaskInput {
  pipelineCode: string;
  dealId: string;
  taskId: string;
  completed: boolean; // target state
}

export async function toggleTaskInDeal(
  input: ToggleTaskInput
): Promise<{ ok: true } | { ok: false; error: string }> {
  if (!input.taskId) return { ok: false, error: 'Missing task' };
  if (!input.dealId) return { ok: false, error: 'Missing deal' };

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({
      status: input.completed ? 'completed' : 'pending',
      completed_at: input.completed ? new Date().toISOString() : null,
    } as never)
    .eq('id', input.taskId)
    .eq('deal_id', input.dealId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  if (!data) return { ok: false, error: 'Task not found on this deal' };

  revalidatePath('/pipelines/' + input.pipelineCode + '/deals/' + input.dealId);
  return { ok: true };
}

// ============================================================
// deleteTaskInDeal  (soft delete)
// ============================================================

export async function deleteTaskInDeal(
  input: { pipelineCode: string; dealId: string; taskId: string }
): Promise<{ ok: true } | { ok: false; error: string }> {
  if (!input.taskId) return { ok: false, error: 'Missing task' };
  if (!input.dealId) return { ok: false, error: 'Missing deal' };

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({ deleted_at: new Date().toISOString() } as never)
    .eq('id', input.taskId)
    .eq('deal_id', input.dealId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  if (!data) return { ok: false, error: 'Task not found on this deal' };

  revalidatePath('/pipelines/' + input.pipelineCode + '/deals/' + input.dealId);
  return { ok: true };
}
