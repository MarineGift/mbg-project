/**
 * lib/actions/tasks.ts
 *
 * Task Server Actions.
 *   - markTaskComplete:    status='done' + completed_at=now()
 *   - markTaskIncomplete:  status='todo' + completed_at=null
 *   - updateTaskStatus:    임의 상태 변경 (in_progress, blocked, cancelled 등)
 *   - createTask:          신규 task 생성
 *   - updateTaskDetails:   상세 수정 (title, description, priority, due_at)
 *   - deleteTask:          soft delete (deleted_at = now())
 *
 * 변경 이력:
 *   - 2026-05-12: deleteTask에서 존재하지 않는 deleted_by 컬럼 참조 제거.
 *                 (parties와 동일한 패턴 — actor 추적은 audit log에 위임)
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
    .select('id, party_id, party_type')
    .maybeSingle();

  if (error) {
    console.error('[tasks.markTaskComplete] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  const updated = data as { id: string; party_id: string | null; party_type: string | null };
  revalidatePath('/tasks');
  // task에 module이 있으면 그 모듈 경로로 revalidate (이전에 임시로 'investor' 하드코딩)
  if (updated.party_id && updated.party_type) {
    revalidatePath(`/${updated.party_type}/parties/${updated.party_id}`);
  }
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
    .select('id, party_id, party_type')
    .maybeSingle();

  if (error) {
    console.error('[tasks.markTaskIncomplete] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  const updated = data as { id: string; party_id: string | null; party_type: string | null };
  revalidatePath('/tasks');
  if (updated.party_id && updated.party_type) {
    revalidatePath(`/${updated.party_type}/parties/${updated.party_id}`);
  }
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

export async function createTask(
  input: z.input<typeof createTaskSchema>,
): Promise<TaskActionResult & { taskId?: string }> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = createTaskSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    title: parsed.data.title.trim(),
    description: parsed.data.description?.trim() || null,
    status: 'todo',
    priority: parsed.data.priority,
    due_at: parsed.data.dueAt || null,
    party_id: parsed.data.partyId || null,
    engagement_id: parsed.data.engagementId || null,
    contact_id: parsed.data.contactId || null,
    module: parsed.data.module || null,
    assigned_to_user_id: auth.userId,
    created_by: auth.userId,
  };

  const { data, error } = await supabase
    .schema('app')
    .from('tasks' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (error || !data) {
    console.error('[tasks.createTask] insert error:', error);
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error?.message ?? 'Insert failed',
    };
  }

  revalidatePath('/tasks');
  if (parsed.data.partyId && parsed.data.module) {
    revalidatePath(`/${parsed.data.module}/parties/${parsed.data.partyId}`);
  }
  if (parsed.data.engagementId) {
    revalidatePath(`/engagements/${parsed.data.engagementId}`);
  }
  return { ok: true, taskId: (data as { id: string }).id };
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
    .select('id, party_id, party_type')
    .maybeSingle();

  if (error) {
    console.error('[tasks.updateTaskDetails] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  const updated = data as { id: string; party_id: string | null; party_type: string | null };
  revalidatePath('/tasks');
  if (updated.party_id && updated.party_type) {
    revalidatePath(`/${updated.party_type}/parties/${updated.party_id}`);
  }
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
  // soft delete — audit log 트리거가 actor 자동 기록.
  // app.tasks 스키마에 deleted_by 컬럼이 존재하지 않으므로 deleted_at만 설정.
  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update({
      deleted_at: new Date().toISOString(),
    } as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, party_id, party_type')
    .maybeSingle();

  if (error) {
    console.error('[tasks.deleteTask] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  const updated = data as { id: string; party_id: string | null; party_type: string | null };
  revalidatePath('/tasks');
  if (updated.party_id && updated.party_type) {
    revalidatePath(`/${updated.party_type}/parties/${updated.party_id}`);
  }
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
  }

  const { error, data } = await supabase
    .schema('app')
    .from('tasks' as never)
    .update(updates as never)
    .eq('id', parsed.data.taskId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, party_id, party_type')
    .maybeSingle();

  if (error) {
    console.error('[tasks.updateTaskStatus] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  const updated = data as { id: string; party_id: string | null; party_type: string | null };
  revalidatePath('/tasks');
  if (updated.party_id && updated.party_type) {
    revalidatePath(`/${updated.party_type}/parties/${updated.party_id}`);
  }
  return { ok: true };
}
