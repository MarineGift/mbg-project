'use server';

/**
 * src/app/actions/delete-communication.ts
 */

import { revalidatePath } from 'next/cache';
import { ImapFlow } from 'imapflow';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createSupabaseAdminClient } from '@/lib/supabase/admin';
import { env } from '@/lib/env';
import { createClient } from '@supabase/supabase-js';

/* ------------------------------------------------------------------
 * IMAP timeout budget (2026-06-11)
 * Previously the bulk path allowed a 60s IMAP budget and connect() had
 * no timeout. Selecting test messages that do not exist on the server
 * (e.g. "Microsoft Outlook test message") made every search return empty
 * while the request stayed pending for ~1 min, so the delete looked stuck.
 * IMAP cleanup is best-effort; the DB soft-delete must not wait on it.
 * ------------------------------------------------------------------ */
const IMAP_CONNECT_TIMEOUT_MS = 5_000;
const IMAP_SOCKET_TIMEOUT_MS = 8_000;
const IMAP_SINGLE_BUDGET_MS = 8_000;
const IMAP_BULK_BUDGET_MS = 8_000;

function withTimeout<T>(p: Promise<T>, ms: number, label: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(
      () => reject(new Error(`${label} timed out after ${ms}ms`)),
      ms,
    );
  });
  return Promise.race([p, timeout]).finally(() => {
    if (timer) clearTimeout(timer);
  }) as Promise<T>;
}

export type DeleteCommunicationResult =
  | { success: true }
  | { success: false; error: string };

function getImapCreds(kind: string): { username: string; password: string } | null {
  switch (kind) {
    case 'personal':
      if (!env.MAIL_PERSONAL_USERNAME || !env.MAIL_PERSONAL_PASSWORD) return null;
      return { username: env.MAIL_PERSONAL_USERNAME, password: env.MAIL_PERSONAL_PASSWORD };
    case 'role':
      if (!env.MAIL_ROLE_USERNAME || !env.MAIL_ROLE_PASSWORD) return null;
      return { username: env.MAIL_ROLE_USERNAME, password: env.MAIL_ROLE_PASSWORD };
    default:
      if (!env.MAIL_SHARED_USERNAME || !env.MAIL_SHARED_PASSWORD) return null;
      return { username: env.MAIL_SHARED_USERNAME, password: env.MAIL_SHARED_PASSWORD };
  }
}

async function deleteFromImap(messageId: string, accountKind: string): Promise<void> {
  const creds = getImapCreds(accountKind);
  if (!creds) {
    console.warn(`[deleteComm] No IMAP creds for kind=${accountKind}, skipping`);
    return;
  }
  // MAILCARRIER_HOST is worker-only/optional in env; without it we cannot open
  // IMAP, so skip the server-side delete (the DB soft-delete still proceeds).
  const host = env.MAILCARRIER_HOST;
  if (!host) {
    console.warn('[deleteComm] MAILCARRIER_HOST unset, skipping IMAP delete');
    return;
  }
  const isImplicitTls = env.MAILCARRIER_PORT === 993;
  const client = new ImapFlow({
    host,
    port: env.MAILCARRIER_PORT,
    secure: isImplicitTls,
    auth: { user: creds.username, pass: creds.password },
    tls: { rejectUnauthorized: env.MAILCARRIER_TLS_REJECT_UNAUTHORIZED ?? true },
    logger: false,
    socketTimeout: IMAP_SOCKET_TIMEOUT_MS,
  });
  await withTimeout(client.connect(), IMAP_CONNECT_TIMEOUT_MS, 'IMAP connect');
  const lock = await client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);
  try {
    const uids = await (client as any).search(
      { header: { 'message-id': messageId } },
      { uid: true },
    ) as number[];
    if (!uids || uids.length === 0) {
      console.log(`[deleteComm] Message-ID not found on server: ${messageId}`);
      return;
    }
    await (client as any).messageDelete(uids.join(','), { uid: true });
    console.log(`[deleteComm] IMAP deleted uid(s)=${uids.join(',')} for ${messageId}`);
  } finally {
    lock.release();
    try { await client.logout(); } catch { /* ignore */ }
  }
}

export async function deleteCommunication(id: string): Promise<DeleteCommunicationResult> {
  console.log('[deleteComm] START id=', id);

  // 1. extract orgId from the session + JWT decode
  const supabase = await createSupabaseServerClient();
  const { data: { session }, error: sessErr } = await supabase.auth.getSession();

  console.log('[deleteComm] sessErr=', sessErr?.message ?? 'none');
  console.log('[deleteComm] has_session=', !!session);

  if (!session) return { success: false, error: 'Not authenticated' };

  let orgId: string | undefined;
  try {
    const payload = JSON.parse(
      Buffer.from(session.access_token.split('.')[1]!!, 'base64url').toString()
    );
    console.log('[deleteComm] JWT keys=', Object.keys(payload).join(','));
    orgId =
      payload.organization_id ??
      payload.organization_id ??
      payload.app_metadata?.organization_id ??
      payload.user_metadata?.organization_id;
    console.log('[deleteComm] orgId=', orgId ?? 'NOT FOUND');
  } catch (e) {
    console.error('[deleteComm] JWT decode err', e);
  }

  if (!orgId) return { success: false, error: 'Organization context missing' };

  // 2. admin client - bypasses RLS (security kept via double organization_id filter)
  // changed - app-schema-only client
  const admin = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: { autoRefreshToken: false, persistSession: false },
      db: { schema: 'app' },
    }
  );
  const adminComms = admin.from('communications') as any;

  // 3. look up the message
  const { data: comm, error: fetchError } = await adminComms
    .select('id, message_id, direction, external_data')
    .eq('id', id)
    .is('deleted_at', null)
    .single() as {
      data: {
        id: string;
        message_id: string | null;
        direction: string;
        external_data: Record<string, unknown> | null;
      } | null;
      error: unknown;
    };

  console.log('[deleteComm] fetchError=', fetchError ?? 'none', 'comm=', comm?.id ?? 'null');
  console.log('[deleteComm] comm.org=', (comm as any)?.organization_id, 'jwt.org=', orgId);

  if (fetchError || !comm) {
    return { success: false, error: 'Message not found or already deleted' };
  }

  // 4. IMAP delete (only when inbound + message_id present)
  if (comm.direction === 'inbound' && comm.message_id) {
    const extData = (comm.external_data ?? {}) as Record<string, unknown>;
    const accountKind =
      typeof extData.mailcarrier_account_kind === 'string'
        ? extData.mailcarrier_account_kind
        : 'shared';
    try {
      await withTimeout(
        deleteFromImap(comm.message_id, accountKind),
        IMAP_SINGLE_BUDGET_MS,
        'IMAP single delete',
      );
    } catch (imapErr) {
      console.error('[deleteComm] IMAP delete failed (non-fatal):', imapErr);
    }
  }

  // 5. DB soft-delete
  const { error: deleteError } = await adminComms
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .eq('organization_id', orgId)
    .is('deleted_at', null);

  console.log('[deleteComm] deleteError=', deleteError ?? 'none');

  if (deleteError) {
    return { success: false, error: (deleteError as any).message };
  }

  revalidatePath('/inbox');
  revalidatePath(`/inbox/${id}`);
  revalidatePath('/', 'layout');

  return { success: true };
}

/* ============================================================
 * Bulk delete
 *
 * Fix (2026-06-10): the previous implementation ran
 * Promise.allSettled(ids.map(deleteCommunication)), opening one IMAP
 * connection PER message in parallel. Selecting 20+ inbound messages
 * meant 20+ simultaneous connections + mailbox-lock contention against
 * MailCarrier, which hangs at connect() until socket timeouts -> the
 * "Deleting..." dialog froze for minutes.
 *
 * New flow:
 *   1. one fetch for all target rows (org-scoped)
 *   2. ONE IMAP connection per account kind, message-ids deleted
 *      sequentially inside it, whole phase time-budgeted + non-fatal
 *   3. ONE bulk DB soft-delete via .in('id', ids)
 * ============================================================ */

/** Delete many messages from one mailbox over a SINGLE IMAP connection. */
async function deleteManyFromImap(
  messageIds: string[],
  accountKind: string,
): Promise<void> {
  if (messageIds.length === 0) return;

  const creds = getImapCreds(accountKind);
  if (!creds) {
    console.warn(`[deleteCommBulk] No IMAP creds for kind=${accountKind}, skipping`);
    return;
  }
  const host = env.MAILCARRIER_HOST;
  if (!host) {
    console.warn('[deleteCommBulk] MAILCARRIER_HOST unset, skipping IMAP delete');
    return;
  }

  const isImplicitTls = env.MAILCARRIER_PORT === 993;
  const client = new ImapFlow({
    host,
    port: env.MAILCARRIER_PORT,
    secure: isImplicitTls,
    auth: { user: creds.username, pass: creds.password },
    tls: { rejectUnauthorized: env.MAILCARRIER_TLS_REJECT_UNAUTHORIZED ?? true },
    logger: false,
    socketTimeout: IMAP_SOCKET_TIMEOUT_MS,
  });

  await withTimeout(client.connect(), IMAP_CONNECT_TIMEOUT_MS, 'IMAP connect');
  const lock = await client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);
  try {
    for (const messageId of messageIds) {
      try {
        const uids = await (client as any).search(
          { header: { 'message-id': messageId } },
          { uid: true },
        ) as number[];
        if (!uids || uids.length === 0) {
          console.log(`[deleteCommBulk] Message-ID not found on server: ${messageId}`);
          continue;
        }
        await (client as any).messageDelete(uids.join(','), { uid: true });
        console.log(`[deleteCommBulk] IMAP deleted uid(s)=${uids.join(',')} for ${messageId}`);
      } catch (msgErr) {
        // one bad message must not abort the rest of the batch
        console.error(`[deleteCommBulk] IMAP delete failed for ${messageId}:`, msgErr);
      }
    }
  } finally {
    lock.release();
    try { await client.logout(); } catch { /* ignore */ }
  }
}

export async function deleteCommunicationsBulk(
  ids: string[],
): Promise<{ deleted: number; errors: string[] }> {
  if (ids.length === 0) return { deleted: 0, errors: [] };

  console.log('[deleteCommBulk] START count=', ids.length);

  // 1. auth + orgId (same scheme as deleteCommunication)
  const supabase = await createSupabaseServerClient();
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { deleted: 0, errors: ['Not authenticated'] };

  let orgId: string | undefined;
  try {
    const payload = JSON.parse(
      Buffer.from(session.access_token.split('.')[1]!!, 'base64url').toString()
    );
    orgId =
      payload.organization_id ??
      payload.app_metadata?.organization_id ??
      payload.user_metadata?.organization_id;
  } catch (e) {
    console.error('[deleteCommBulk] JWT decode err', e);
  }
  if (!orgId) return { deleted: 0, errors: ['Organization context missing'] };

  // 2. admin client (app schema), org-scoped on every query
  const admin = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: { autoRefreshToken: false, persistSession: false },
      db: { schema: 'app' },
    }
  );
  const adminComms = admin.from('communications') as any;

  // 3. fetch all target rows in one query
  const { data: comms, error: fetchError } = await adminComms
    .select('id, message_id, direction, external_data')
    .in('id', ids)
    .eq('organization_id', orgId)
    .is('deleted_at', null) as {
      data: Array<{
        id: string;
        message_id: string | null;
        direction: string;
        external_data: Record<string, unknown> | null;
      }> | null;
      error: unknown;
    };

  if (fetchError || !comms) {
    const msg = (fetchError as any)?.message ?? 'Fetch failed';
    console.error('[deleteCommBulk] fetch error:', msg);
    return { deleted: 0, errors: [msg] };
  }

  // 4. group inbound message-ids by mail account kind
  const idsByKind = new Map<string, string[]>();
  for (const comm of comms) {
    if (comm.direction !== 'inbound' || !comm.message_id) continue;
    const extData = (comm.external_data ?? {}) as Record<string, unknown>;
    const accountKind =
      typeof extData.mailcarrier_account_kind === 'string'
        ? extData.mailcarrier_account_kind
        : 'shared';
    const list = idsByKind.get(accountKind) ?? [];
    list.push(comm.message_id);
    idsByKind.set(accountKind, list);
  }

  // 5. IMAP phase: ONE connection per account kind, sequential, time-budgeted.
  //    Failures are non-fatal -- the platform-side soft delete still proceeds
  //    (same semantics as the single-message path).
  for (const [kind, messageIds] of idsByKind) {
    try {
      await withTimeout(
        deleteManyFromImap(messageIds, kind),
        IMAP_BULK_BUDGET_MS,
        `IMAP bulk delete (${kind})`,
      );
    } catch (imapErr) {
      console.error('[deleteCommBulk] IMAP phase failed (non-fatal):', imapErr);
    }
  }

  // 6. ONE bulk soft-delete
  const { data: updated, error: deleteError } = await adminComms
    .update({ deleted_at: new Date().toISOString() })
    .in('id', ids)
    .eq('organization_id', orgId)
    .is('deleted_at', null)
    .select('id') as { data: Array<{ id: string }> | null; error: unknown };

  const errors: string[] = [];
  if (deleteError) {
    errors.push((deleteError as any).message ?? 'Bulk delete failed');
  }
  const deleted = updated?.length ?? 0;
  console.log('[deleteCommBulk] DONE deleted=', deleted, 'errors=', errors.length);

  revalidatePath('/inbox');
  revalidatePath('/', 'layout');
  return { deleted, errors };
}
