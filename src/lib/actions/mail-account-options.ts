// src/lib/actions/mail-account-options.ts
//
// Multi-Account Mail Hub Step 4 (2026-06-12)
// Server actions backing the compose dialog From dropdown.
// Exposes only id/address/display_name/is_default - never SMTP/IMAP
// credentials or encrypted passwords.
'use server';

import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import {
  fetchActiveMailAccounts,
  resolveOutboundMailAccount,
} from '@/lib/email/mail-accounts';

export interface MailAccountOption {
  id: string;
  address: string;
  displayName: string | null;
  isDefault: boolean;
}

/**
 * Active smtp-ready accounts for the From dropdown.
 * Empty list -> the dialog falls back to the legacy env-kind selector.
 */
export async function listMailAccountOptions(): Promise<{
  ok: boolean;
  accounts: MailAccountOption[];
}> {
  try {
    const auth = await requireAuth();
    const supabase = await createSupabaseServerClient();
    const accounts = await fetchActiveMailAccounts(supabase, auth.organizationId);
    return {
      ok: true,
      accounts: accounts
        .map((a) => ({
          id: a.id,
          address: a.address,
          displayName: a.displayName,
          isDefault: a.isDefault,
        }))
        // default first, then alphabetical - stable dropdown order
        .sort((x, y) =>
          x.isDefault === y.isDefault
            ? x.address.localeCompare(y.address)
            : x.isDefault
              ? -1
              : 1,
        ),
    };
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn('[mail-account-options] list failed:', err instanceof Error ? err.message : err);
    return { ok: false, accounts: [] };
  }
}

/**
 * Reply preselect: runs the same routing rule the send core uses
 * (default-in-recipients > persisting account > reverse-match > default)
 * so what the dropdown shows matches what would actually be sent.
 */
export async function getReplyFromAccountId(
  inReplyToMessageId: string,
): Promise<string | null> {
  try {
    const auth = await requireAuth();
    const supabase = await createSupabaseServerClient();
    const account = await resolveOutboundMailAccount(supabase, auth.organizationId, {
      inReplyTo: inReplyToMessageId,
    });
    return account?.id ?? null;
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn('[mail-account-options] reply preselect failed:', err instanceof Error ? err.message : err);
    return null;
  }
}
