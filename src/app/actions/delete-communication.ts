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
  const isImplicitTls = env.MAILCARRIER_PORT === 993;
  const client = new ImapFlow({
    host: env.MAILCARRIER_HOST,
    port: env.MAILCARRIER_PORT,
    secure: isImplicitTls,
    auth: { user: creds.username, pass: creds.password },
    tls: { rejectUnauthorized: env.MAILCARRIER_TLS_REJECT_UNAUTHORIZED ?? true },
    logger: false,
    socketTimeout: 30_000,
  });
  await client.connect();
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

  // 1. 세션 + JWT 디코딩으로 orgId 추출
  const supabase = await createSupabaseServerClient();
  const { data: { session }, error: sessErr } = await supabase.auth.getSession();

  console.log('[deleteComm] sessErr=', sessErr?.message ?? 'none');
  console.log('[deleteComm] has_session=', !!session);

  if (!session) return { success: false, error: 'Not authenticated' };

  let orgId: string | undefined;
  try {
    const payload = JSON.parse(
      Buffer.from(session.access_token.split('.')[1], 'base64url').toString()
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

  // 2. admin client — RLS 우회 (organization_id 이중 필터로 보안 유지)
  // 변경 — app 스키마 전용 client
  const admin = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: { autoRefreshToken: false, persistSession: false },
      db: { schema: 'app' },
    }
  );
  const adminComms = admin.from('communications') as any;

  // 3. 메시지 조회
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

  // 4. IMAP 삭제 (inbound + message_id 있는 경우만)
  if (comm.direction === 'inbound' && comm.message_id) {
    const extData = (comm.external_data ?? {}) as Record<string, unknown>;
    const accountKind =
      typeof extData.mailcarrier_account_kind === 'string'
        ? extData.mailcarrier_account_kind
        : 'shared';
    try {
      await deleteFromImap(comm.message_id, accountKind);
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

export async function deleteCommunicationsBulk(
  ids: string[],
): Promise<{ deleted: number; errors: string[] }> {
  if (ids.length === 0) return { deleted: 0, errors: [] };

  const results = await Promise.allSettled(ids.map(deleteCommunication));

  let deleted = 0;
  const errors: string[] = [];

  for (const r of results) {
    if (r.status === 'fulfilled' && r.value.success) {
      deleted++;
    } else {
      const msg =
        r.status === 'rejected'
          ? String(r.reason)
          : (r.value as { error: string }).error;
      errors.push(msg);
    }
  }

  revalidatePath('/inbox');
  revalidatePath('/', 'layout');
  return { deleted, errors };
}
