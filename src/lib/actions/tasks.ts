/**
 * lib/actions/tasks.ts
 *
 * Task Server Actions (app.tasks — deal-scoped).
 *
 * D6 schema reality (database.ts): app.tasks columns are
 *   id, organization_id, deal_id(NOT NULL), checklist_id, title, description,
 *   notes, status, priority, due_at, started_at, completed_at, deleted_at,
 *   assigned_to_contact_id, assigned_to_user_id, estimated_minutes,
 *   actual_minutes, extra_data, created_by, updated_by, created_at, updated_at.
 *
 * There is NO party_id / engagement_id / party_type / module column.
 *
 * 2026-06-01 cleanup:
 *   - Removed all references to nonexistent columns (party_id/party_type) from
 *     post-mutation .select(); now selects id, deal_id and revalidates the deal
 *     surfaces. The UPDATEs themselves were already schema-valid.
 *   - createTask: standalone (deal-less) creation is impossible because deal_id
 *     is NOT NULL. Task creation now lives in the deal Tasks tab
 *     (pipelines/[code]/deals/[id]/actions.ts -> addTask). createTask here
 *     returns a clear validation error instead of failing at the DB.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { TaskStatus } from '@/types/task';

export interface TaskActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'not_found' | 'validation' | 'database' | 'unknown';
  errorMessage?: string;
}

const idSchema = z.object({ taskId: z.string().uuid() });
const statusSchema = z.object({
  taskId: z.string().uuid(),
  status: z.enum(['todo', 'in_progress', 'blocked', 'done', 'cancelled']),
});

type UpdatedTaskRow = { id: string; deal_id: string | null };

/** Revalidate the surfaces a task can appear on. */
function revalidateTaskSurfaces() {
  revalidatePath('/tasks');
  // Deal detail Tasks tab + kanban (layout-level to cover any /pipelines route).
  revalidatePath('/pipelines', 'layout');
}

export async function markTaskComplete(input: {
  taskId: string;
}): Promise<TaskActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = idSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const nowIso = new Date().toISOString();
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({ status: 'done', completed_at: nowIso } as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, deal_id')
    .maybeSingle();

  if (error) {
    console.error('[tasks.markTaskComplete] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  void (data as UpdatedTaskRow);
  revalidateTaskSurfaces();
  return { ok: true };
}

export async function markTaskIncomplete(input: {
  taskId: string;
}): Promise<TaskActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = idSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({ status: 'todo', completed_at: null } as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, deal_id')
    .maybeSingle();

  if (error) {
    console.error('[tasks.markTaskIncomplete] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  void (data as UpdatedTaskRow);
  revalidateTaskSurfaces();
  return { ok: true };
}

/* ============================================================
 * createTask / updateTaskDetails / deleteTask
 * ============================================================ */

const createTaskSchema = z.object({
  title: z.string().min(1, 'Required').max(500),
  description: z.string().max(5000).optional().nullable(),
  priority: z.enum(['low', 'medium', 'high', 'urgent']).default('medium'),
  dueAt: z.string().optional().nullable(),
  partyId: z.string().uuid().optional().nullable(),
  engagementId: z.string().uuid().optional().nullable(),
  contactId: z.string().uuid().optional().nullable(),
  module: z
    .enum([
      'investor',
      'paper_mill',
      'partner',
      'customer',
      'filler_supplier',
    ])
    .optional()
    .nullable(),
});

/**
 * Standalone task creation is not supported: app.tasks.deal_id is NOT NULL, so a
 * task must be created from a deal. Use the deal detail "Tasks" tab
 * (pipelines/[code]/deals/[id] -> addTask). Returns a validation error so any
 * legacy caller fails gracefully instead of hitting a DB constraint error.
 */
export async function createTask(
  _input: z.input<typeof createTaskSchema>,
): Promise<TaskActionResult & { taskId?: string }> {
  void _input;
  return {
    ok: false,
    errorCode: 'validation',
    errorMessage: 'Tasks must be created from a deal. Open the deal and use the Tasks tab.',
  };
}

const updateTaskDetailsSchema = createTaskSchema.extend({
  taskId: z.string().uuid(),
});

export async function updateTaskDetails(
  input: z.input<typeof updateTaskDetailsSchema>,
): Promise<TaskActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = updateTaskDetailsSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  // Only schema-valid columns. party/engagement/module inputs are ignored
  // (no such columns on app.tasks).
  const updates: Record<string, unknown> = {
    title: parsed.data.title.trim(),
    description: parsed.data.description?.trim() || null,
    priority: parsed.data.priority,
    due_at: parsed.data.dueAt || null,
    updated_by: auth.userId,
  };

  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update(updates as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, deal_id')
    .maybeSingle();

  if (error) {
    console.error('[tasks.updateTaskDetails] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  void (data as UpdatedTaskRow);
  revalidateTaskSurfaces();
  return { ok: true };
}

export async function deleteTask(input: { taskId: string }): Promise<TaskActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = z.object({ taskId: z.string().uuid() }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  // soft delete — audit log trigger records the actor.
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({
      deleted_at: new Date().toISOString(),
    } as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, deal_id')
    .maybeSingle();

  if (error) {
    console.error('[tasks.deleteTask] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  void (data as UpdatedTaskRow);
  revalidateTaskSurfaces();
  return { ok: true };
}

/* ============================================================
 * updateTaskNotes — free-form notes, used as the blocker reason
 * ============================================================ */

const notesSchema = z.object({
  taskId: z.string().uuid(),
  notes: z.string().max(5000).nullable(),
});

export async function updateTaskNotes(input: {
  taskId: string;
  notes: string | null;
}): Promise<TaskActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = notesSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({ notes: parsed.data.notes?.trim() || null, updated_by: auth.userId } as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, deal_id')
    .maybeSingle();

  if (error) {
    console.error('[tasks.updateTaskNotes] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  void (data as UpdatedTaskRow);
  revalidateTaskSurfaces();
  return { ok: true };
}

export async function updateTaskStatus(input: {
  taskId: string;
  status: TaskStatus;
}): Promise<TaskActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = statusSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const updates: Record<string, unknown> = { status: parsed.data.status };
  if (parsed.data.status === 'done') {
    updates.completed_at = new Date().toISOString();
  } else if (parsed.data.status === 'todo') {
    updates.completed_at = null;
  } else if (parsed.data.status === 'in_progress') {
    // stamp started_at on first transition into in_progress (used by diagnostics)
    updates.started_at = new Date().toISOString();
  }

  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update(updates as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, deal_id')
    .maybeSingle();

  if (error) {
    console.error('[tasks.updateTaskStatus] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  void (data as UpdatedTaskRow);
  revalidateTaskSurfaces();
  return { ok: true };
}
