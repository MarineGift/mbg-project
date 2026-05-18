'use server';

/**
 * src/app/actions/delete-task.ts
 * Task soft-delete (deleted_at) + bulk delete
 */

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createSupabaseAdminClient } from '@/lib/supabase/admin';

export type DeleteTaskResult =
  | { success: true }
  | { success: false; error: string };

async function getOrgId(): Promise<string | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;
  try {
    const payload = JSON.parse(
      Buffer.from(session.access_token.split('.')[1], 'base64' as BufferEncoding).toString()
    );
    return (
      payload.organization_id ??
      payload.org_id ??
      payload.app_metadata?.organization_id ??
      null
    );
  } catch {
    return null;
  }
}

export async function deleteTask(id: string): Promise<DeleteTaskResult> {
  const orgId = await getOrgId();
  if (!orgId) return { success: false, error: 'Not authenticated' };

  const admin = createSupabaseAdminClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const adminTasks = (admin as any).schema('app').from('tasks');

  const { error } = await adminTasks
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .eq('organization_id', orgId)
    .is('deleted_at', null);

  if (error) {
    if ((error as any).code === '42703') {
      const { error: e2 } = await adminTasks
        .update({ status: 'cancelled' })
        .eq('id', id)
        .eq('organization_id', orgId);
      if (e2) return { success: false, error: (e2 as any).message };
    } else {
      return { success: false, error: (error as any).message };
    }
  }

  revalidatePath('/tasks');
  revalidatePath('/', 'layout');
  return { success: true };
}

export async function deleteTasksBulk(
  ids: string[],
): Promise<{ deleted: number; errors: string[] }> {
  if (ids.length === 0) return { deleted: 0, errors: [] };

  const results = await Promise.allSettled(ids.map(deleteTask));

  let deleted = 0;
  const errors: string[] = [];

  for (const r of results) {
    if (r.status === 'fulfilled' && r.value.success) {
      deleted++;
    } else {
      errors.push(
        r.status === 'rejected'
          ? String(r.reason)
          : (r.value as { error: string }).error,
      );
    }
  }

  revalidatePath('/tasks');
  revalidatePath('/', 'layout');
  return { deleted, errors };
}
