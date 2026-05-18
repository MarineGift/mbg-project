'use server';

/**
 * src/app/actions/delete-communication.ts
 *
 * Communication 삭제 Server Action.
 * - inbound: IMAP 서버에서 메시지 삭제 (message_id SEARCH → messageDelete)
 * - outbound: DB soft-delete만 수행 (서버에 원본 없음)
 * - IMAP 실패는 non-fatal: 이미 서버에서 삭제됐을 수 있으므로 DB 삭제는 항상 진행
 */

import { revalidatePath } from 'next/cache';
import { ImapFlow } from 'imapflow';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { env } from '@/lib/env';

// ── 타입 ──────────────────────────────────────────────────────────────────
export type DeleteCommunicationResult =
  | { success: true }
  | { success: false; error: string };

// ── IMAP 계정 kind별 credentials ──────────────────────────────────────────
function getImapCreds(kind: string): { username: string; password: string } | null {
  switch (kind) {
    case 'personal':
      if (!env.MAIL_PERSONAL_USERNAME || !env.MAIL_PERSONAL_PASSWORD) return null;
      return { username: env.MAIL_PERSONAL_USERNAME, password: env.MAIL_PERSONAL_PASSWORD };
    case 'role':
      if (!env.MAIL_ROLE_USERNAME || !env.MAIL_ROLE_PASSWORD) return null;
      return { username: env.MAIL_ROLE_USERNAME, password: env.MAIL_ROLE_PASSWORD };
    default: // 'shared' or unknown
      if (!env.MAIL_SHARED_USERNAME || !env.MAIL_SHARED_PASSWORD) return null;
      return { username: env.MAIL_SHARED_USERNAME, password: env.MAIL_SHARED_PASSWORD };
  }
}

// ── IMAP에서 Message-ID로 메시지 찾아 삭제 ────────────────────────────────
async function deleteFromImap(
  messageId: string,
  accountKind: string,
): Promise<void> {
  const creds = getImapCreds(accountKind);
  if (!creds) {
    console.warn(`[deleteComm] No IMAP creds for kind=${accountKind}, skipping IMAP delete`);
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
    socketTimeout: 30_000, // 30s (빠른 단일 작업)
  });

  await client.connect();

  const lock = await client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);
  try {
    // Message-ID 헤더로 UID 검색
    const uids = await (client as any).search(
      { header: { 'message-id': messageId } },
      { uid: true },
    ) as number[];

    if (!uids || uids.length === 0) {
      console.log(`[deleteComm] Message-ID not found on server (already deleted?): ${messageId}`);
      return;
    }

    // messageDelete = \Deleted flag + EXPUNGE (ImapFlow 통합 메서드)
    const uidRange = uids.join(',');
    await (client as any).messageDelete(uidRange, { uid: true });
    console.log(`[deleteComm] IMAP deleted uid(s)=${uidRange} for message_id=${messageId}`);
  } finally {
    lock.release();
    try { await client.logout(); } catch { /* ignore logout errors */ }
  }
}

// ── 메인 Server Action ────────────────────────────────────────────────────
export async function deleteCommunication(
  id: string,
): Promise<DeleteCommunicationResult> {
  const supabase = await createSupabaseServerClient();

  // 1. 메시지 조회 (이미 삭제됐거나 없으면 early return)
  const { data: comm, error: fetchError } = await supabase
    .schema('app')
    .from('communications')
    .select('id, message_id, direction, external_data')
    .eq('id', id)
    .is('deleted_at', null)
    .single();

  if (fetchError || !comm) {
    return { success: false, error: 'Message not found or already deleted' };
  }

  // 2. IMAP 서버에서 삭제 (inbound + message_id 있는 경우만)
  if (comm.direction === 'inbound' && comm.message_id) {
    const extData = (comm.external_data ?? {}) as Record<string, unknown>;
    const accountKind =
      typeof extData.mailcarrier_account_kind === 'string'
        ? extData.mailcarrier_account_kind
        : 'shared'; // fallback

    try {
      await deleteFromImap(comm.message_id, accountKind);
    } catch (imapErr) {
      // IMAP 실패는 non-fatal — DB 삭제는 계속 진행
      // (서버에서 이미 삭제된 경우 등)
      console.error('[deleteComm] IMAP delete failed (non-fatal):', imapErr);
    }
  }

  // 3. DB soft-delete
  const { error: deleteError } = await supabase
    .schema('app')
    .from('communications')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .is('deleted_at', null); // 이중 실행 방지

  if (deleteError) {
    return { success: false, error: deleteError.message };
  }

  // 4. 캐시 무효화
  revalidatePath('/inbox');
  revalidatePath(`/inbox/${id}`);

  return { success: true };
}

// ── 일괄 삭제 (체크박스 선택) ─────────────────────────────────────────────
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
  return { deleted, errors };
}
