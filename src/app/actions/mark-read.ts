'use server';

/**
 * src/app/actions/mark-read.ts
 * Mark inbound communications as read / unread (read_at column).
 * Same auth + admin-app-client pattern as delete-task.ts / delete-communication.ts.
 *
 * Unread is defined as: direction='inbound' AND read_at IS NULL AND deleted_at IS NULL.
 * Outbound (sent) messages are never counted as unread.
 */

import { revalidatePath } from 'next/cache';
import { createClient } from '@supabase/supabase-js';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { env } from '@/lib/env';

export type MarkReadResult =
  | { success: true }
  | { success: false; error: string };

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
      payload.app_metadata?.organization_id;
    if (!orgId) return null;
    return { orgId };
  } catch {
    return null;
  }
}

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

/** Mark a single inbound message read. No-op if already read or outbound. */
export async function markCommunicationRead(id: string): Promise<MarkReadResult> {
  const session = await getSessionOrgId();
  if (!session) return { success: false, error: 'Not authenticated' };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const comms = makeAdminAppClient().from('communications') as any;
  const { error } = await comms
    .update({ read_at: new Date().toISOString() })
    .eq('id', id)
    .eq('organization_id', session.orgId)
    .eq('direction', 'inbound')
    .is('read_at', null);

  if (error) return { success: false, error: (error as any).message };

  revalidatePath('/inbox');
  revalidatePath('/', 'layout');
  return { success: true };
}

/** Mark many inbound messages read in one call (e.g. all messages in a thread). */
export async function markCommunicationsRead(
  ids: string[],
): Promise<{ updated: number; error?: string }> {
  if (!ids || ids.length === 0) return { updated: 0 };
  const session = await getSessionOrgId();
  if (!session) return { updated: 0, error: 'Not authenticated' };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const comms = makeAdminAppClient().from('communications') as any;
  const { data, error } = await comms
    .update({ read_at: new Date().toISOString() })
    .in('id', ids)
    .eq('organization_id', session.orgId)
    .eq('direction', 'inbound')
    .is('read_at', null)
    .select('id');

  if (error) return { updated: 0, error: (error as any).message };

  revalidatePath('/inbox');
  revalidatePath('/', 'layout');
  return { updated: Array.isArray(data) ? data.length : 0 };
}

/** Mark a single message unread (clears read_at). */
export async function markCommunicationUnread(id: string): Promise<MarkReadResult> {
  const session = await getSessionOrgId();
  if (!session) return { success: false, error: 'Not authenticated' };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const comms = makeAdminAppClient().from('communications') as any;
  const { error } = await comms
    .update({ read_at: null })
    .eq('id', id)
    .eq('organization_id', session.orgId)
    .eq('direction', 'inbound');

  if (error) return { success: false, error: (error as any).message };

  revalidatePath('/inbox');
  revalidatePath('/', 'layout');
  return { success: true };
}

/** Mark every unread inbound message in the org as read. Returns count updated. */
export async function markAllInboxRead(): Promise<{ updated: number; error?: string }> {
  const session = await getSessionOrgId();
  if (!session) return { updated: 0, error: 'Not authenticated' };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const comms = makeAdminAppClient().from('communications') as any;
  const { data, error } = await comms
    .update({ read_at: new Date().toISOString() })
    .eq('organization_id', session.orgId)
    .eq('direction', 'inbound')
    .is('read_at', null)
    .is('deleted_at', null)
    .select('id');

  if (error) return { updated: 0, error: (error as any).message };

  revalidatePath('/inbox');
  revalidatePath('/', 'layout');
  return { updated: Array.isArray(data) ? data.length : 0 };
}
