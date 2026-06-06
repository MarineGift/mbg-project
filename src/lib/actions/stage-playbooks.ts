/**
 * lib/actions/stage-playbooks.ts
 *
 * Server Actions for the Stage Playbook editor (Feature B): CRUD over
 * app.stage_checklist_templates and app.stage_task_templates.
 *
 * Follows lib/actions/rounds.ts: 'use server' + zod + requireAuth + a typed
 * result. organization_id is NOT set on insert -- the column default
 * app.current_organization_id() fills it, and RLS enforces org isolation.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface PlaybookActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'database' | 'unknown';
  errorMessage?: string;
  id?: string;
}

// The editor lives under the dynamic pipeline route; revalidate every instance.
function revalidatePlaybook() {
  revalidatePath('/pipelines/[code]/playbook', 'page');
}

async function authed(): Promise<boolean> {
  try {
    await requireAuth();
    return true;
  } catch {
    return false;
  }
}

const priorityEnum = z.enum(['low', 'medium', 'high']);

/* ============================================================
 * Checklist templates
 * ============================================================ */

const checklistCreate = z.object({
  stageId: z.string().uuid(),
  title: z.string().min(1, 'Title is required').max(200),
  sortOrder: z.number().int().min(0).max(9999).default(0),
});

export async function createChecklistTemplate(
  input: z.input<typeof checklistCreate>,
): Promise<PlaybookActionResult> {
  if (!(await authed())) return { ok: false, errorCode: 'unauthorized' };
  const parsed = checklistCreate.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('stage_checklist_templates' as never)
    .insert({
      stage_id: parsed.data.stageId,
      title: parsed.data.title.trim(),
      sort_order: parsed.data.sortOrder,
    } as never)
    .select('id')
    .single();
  if (error || !data) return { ok: false, errorCode: 'database', errorMessage: error?.message ?? 'Insert failed' };
  revalidatePlaybook();
  return { ok: true, id: (data as { id: string }).id };
}

const checklistUpdate = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).max(200).optional(),
  sortOrder: z.number().int().min(0).max(9999).optional(),
  isActive: z.boolean().optional(),
});

export async function updateChecklistTemplate(
  input: z.input<typeof checklistUpdate>,
): Promise<PlaybookActionResult> {
  if (!(await authed())) return { ok: false, errorCode: 'unauthorized' };
  const parsed = checklistUpdate.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const patch: Record<string, unknown> = {};
  if (parsed.data.title !== undefined) patch.title = parsed.data.title.trim();
  if (parsed.data.sortOrder !== undefined) patch.sort_order = parsed.data.sortOrder;
  if (parsed.data.isActive !== undefined) patch.is_active = parsed.data.isActive;
  if (Object.keys(patch).length === 0) return { ok: true, id: parsed.data.id };

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('stage_checklist_templates' as never)
    .update(patch as never)
    .eq('id' as never, parsed.data.id);
  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  revalidatePlaybook();
  return { ok: true, id: parsed.data.id };
}

export async function deleteChecklistTemplate(id: string): Promise<PlaybookActionResult> {
  if (!(await authed())) return { ok: false, errorCode: 'unauthorized' };
  if (!z.string().uuid().safeParse(id).success) return { ok: false, errorCode: 'validation' };
  const supabase = await createSupabaseServerClient();
  // Tasks referencing this checklist template have ON DELETE SET NULL, so this
  // never cascades into orphaned task rows.
  const { error } = await supabase
    .schema('app')
    .from('stage_checklist_templates' as never)
    .delete()
    .eq('id' as never, id);
  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  revalidatePlaybook();
  return { ok: true, id };
}

/* ============================================================
 * Task templates
 * ============================================================ */

const taskCreate = z.object({
  stageId: z.string().uuid(),
  title: z.string().min(1, 'Title is required').max(200),
  description: z.string().max(2000).optional().nullable(),
  defaultPriority: priorityEnum.default('medium'),
  dueInDays: z.number().int().min(0).max(365).default(3),
  sortOrder: z.number().int().min(0).max(9999).default(0),
  checklistTemplateId: z.string().uuid().optional().nullable(),
});

export async function createTaskTemplate(
  input: z.input<typeof taskCreate>,
): Promise<PlaybookActionResult> {
  if (!(await authed())) return { ok: false, errorCode: 'unauthorized' };
  const parsed = taskCreate.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('stage_task_templates' as never)
    .insert({
      stage_id: parsed.data.stageId,
      title: parsed.data.title.trim(),
      description: parsed.data.description?.trim() || null,
      default_priority: parsed.data.defaultPriority,
      due_in_days: parsed.data.dueInDays,
      sort_order: parsed.data.sortOrder,
      checklist_template_id: parsed.data.checklistTemplateId || null,
    } as never)
    .select('id')
    .single();
  if (error || !data) return { ok: false, errorCode: 'database', errorMessage: error?.message ?? 'Insert failed' };
  revalidatePlaybook();
  return { ok: true, id: (data as { id: string }).id };
}

const taskUpdate = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).optional().nullable(),
  defaultPriority: priorityEnum.optional(),
  dueInDays: z.number().int().min(0).max(365).optional(),
  sortOrder: z.number().int().min(0).max(9999).optional(),
  checklistTemplateId: z.string().uuid().optional().nullable(),
  isActive: z.boolean().optional(),
});

export async function updateTaskTemplate(
  input: z.input<typeof taskUpdate>,
): Promise<PlaybookActionResult> {
  if (!(await authed())) return { ok: false, errorCode: 'unauthorized' };
  const parsed = taskUpdate.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const patch: Record<string, unknown> = {};
  if (parsed.data.title !== undefined) patch.title = parsed.data.title.trim();
  if (parsed.data.description !== undefined) patch.description = parsed.data.description?.trim() || null;
  if (parsed.data.defaultPriority !== undefined) patch.default_priority = parsed.data.defaultPriority;
  if (parsed.data.dueInDays !== undefined) patch.due_in_days = parsed.data.dueInDays;
  if (parsed.data.sortOrder !== undefined) patch.sort_order = parsed.data.sortOrder;
  if (parsed.data.checklistTemplateId !== undefined) patch.checklist_template_id = parsed.data.checklistTemplateId || null;
  if (parsed.data.isActive !== undefined) patch.is_active = parsed.data.isActive;
  if (Object.keys(patch).length === 0) return { ok: true, id: parsed.data.id };

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('stage_task_templates' as never)
    .update(patch as never)
    .eq('id' as never, parsed.data.id);
  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  revalidatePlaybook();
  return { ok: true, id: parsed.data.id };
}

export async function deleteTaskTemplate(id: string): Promise<PlaybookActionResult> {
  if (!(await authed())) return { ok: false, errorCode: 'unauthorized' };
  if (!z.string().uuid().safeParse(id).success) return { ok: false, errorCode: 'validation' };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('stage_task_templates' as never)
    .delete()
    .eq('id' as never, id);
  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  revalidatePlaybook();
  return { ok: true, id };
}
