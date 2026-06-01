'use server';

/**
 * src/app/actions/delete-task.ts
 * Task soft-delete - same pattern as delete-communication.ts
 */

import { revalidatePath } from 'next/cache';
import { createClient } from '@supabase/supabase-js';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { env } from '@/lib/env';

export type DeleteTaskResult =
  | { success: true }
  | { success: false; error: string };

// extract orgId from the JWT
async function getSessionOrgId(): Promise<{ orgId: string } | null> {
  const supabase = await createSupabaseServerClient();
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;
  try {
    const payload = JSON.parse(
      Buffer.from(session.access_token.split('.')[1] ?? '', 'base64').toString()
    );
    const orgId: string | undefined =
      payload.organization_id ??
      payload.organization_id ??
      payload.app_metadata?.organization_id;
    if (!orgId) return null;
    return { orgId };
  } catch {
    return null;
  }
}

// app-schema-only admin client (bypasses RLS)
function makeAdminAppClient() {
  return createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: { autoRefreshToken: false, persistSession: false },
      db: { schema: 'app' },
    },
  );
}

export async function deleteTask(id: string): Promise<DeleteTaskResult> {
  const session = await getSessionOrgId();
  if (!session) return { success: false, error: 'Not authenticated' };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const tasks = makeAdminAppClient().from('tasks') as any;

  const { error } = await tasks
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .eq('organization_id', session.orgId)
    .is('deleted_at', null);

  if (error) return { success: false, error: (error as any).message };

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
