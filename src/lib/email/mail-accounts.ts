// src/lib/email/mail-accounts.ts
//
// Multi-Account Mail Hub Step 3 (2026-06-12)
// app.inbound_mailboxes lookups + outbound From-account routing.
//
// From routing rule (confirmed with user 2026-06-12):
//   explicit accountId from the caller (Step 4 UI) always wins.
//   reply (inReplyTo present, original communication found):
//     - original is OUR outbound -> continue with its mail_account_id (thread continuity)
//     - original is inbound:
//       R1. if to_addresses/cc contains the is_default account address -> default
//           (multi-account delivery races: which carrier persisted first is
//            non-deterministic, so prefer the default deterministically)
//       R2. else the account recorded on communications.mail_account_id (Step 2)
//       R3. else reverse-match to_addresses (+cc) against active accounts
//   new mail: is_default account.
//   no active smtp-ready accounts at all -> null
//   (caller falls back to the legacy env/TABS_MAILER SMTP path).
//
// NOTE: app.inbound_mailboxes / decrypt RPC are not in the generated
// Database types yet, so this module uses the established `as never`
// cast pattern (see send-outbound.ts).

import type { SbClient } from '@/lib/supabase/server';

/* ============================================================
 * Types
 * ============================================================ */

export interface MailAccount {
  id: string;
  address: string;
  displayName: string | null;
  smtpHost: string;
  smtpPort: number;
  smtpUseTls: boolean;
  smtpUsername: string;
  /** PostgREST bytea -> hex string ("\\x..."). Decrypt via decryptMailAccountSmtpPassword. */
  smtpPasswordEncrypted: string;
  smtpAuthMethod: string | null;
  isDefault: boolean;
}

interface MailAccountRaw {
  id: string;
  address: string;
  display_name: string | null;
  smtp_host: string | null;
  smtp_port: number | null;
  smtp_use_tls: boolean | null;
  smtp_username: string | null;
  smtp_password_encrypted: string | null;
  smtp_auth_method: string | null;
  is_default: boolean | null;
}

export interface ResolveOutboundAccountOptions {
  /** Explicit account chosen by the caller (Step 4 From dropdown). Wins over everything. */
  explicitAccountId?: string | null;
  /** RFC 5322 In-Reply-To message id - triggers the reply routing rule. */
  inReplyTo?: string | null;
}

/* ============================================================
 * Lookups
 * ============================================================ */

const ACCOUNT_COLUMNS =
  'id, address, display_name, smtp_host, smtp_port, smtp_use_tls, smtp_username, smtp_password_encrypted, smtp_auth_method, is_default';

function toMailAccount(raw: MailAccountRaw): MailAccount | null {
  // smtp-ready guard: rows without backfilled SMTP info cannot send.
  if (!raw.smtp_host || !raw.smtp_port || !raw.smtp_username || !raw.smtp_password_encrypted) {
    return null;
  }
  return {
    id: raw.id,
    address: raw.address.toLowerCase(),
    displayName: raw.display_name,
    smtpHost: raw.smtp_host,
    smtpPort: raw.smtp_port,
    smtpUseTls: raw.smtp_use_tls ?? false,
    smtpUsername: raw.smtp_username,
    smtpPasswordEncrypted: raw.smtp_password_encrypted,
    smtpAuthMethod: raw.smtp_auth_method,
    isDefault: raw.is_default ?? false,
  };
}

/** All active, smtp-ready accounts for the org. */
export async function fetchActiveMailAccounts(
  supabase: SbClient,
  organizationId: string,
): Promise<MailAccount[]> {
  const { data, error } = await supabase
    .schema('app')
    .from('inbound_mailboxes' as never)
    .select(ACCOUNT_COLUMNS)
    .eq('organization_id', organizationId)
    .eq('is_active', true);
  if (error) {
    throw new Error(`mail accounts lookup failed: ${error.message}`);
  }
  return ((data ?? []) as unknown as MailAccountRaw[])
    .map(toMailAccount)
    .filter((a): a is MailAccount => a !== null);
}

/* ============================================================
 * From routing
 * ============================================================ */

interface OriginalCommRow {
  direction: string | null;
  mail_account_id: string | null;
  to_addresses: string[] | null;
  cc_addresses: string[] | null;
}

/**
 * Resolve which DB mail account an outbound send should use as From.
 * Returns null when no active smtp-ready accounts exist (legacy env fallback)
 * or when an explicit/recorded account id no longer resolves.
 */
export async function resolveOutboundMailAccount(
  supabase: SbClient,
  organizationId: string,
  opts: ResolveOutboundAccountOptions = {},
): Promise<MailAccount | null> {
  const accounts = await fetchActiveMailAccounts(supabase, organizationId);
  if (accounts.length === 0) return null;

  const byId = new Map(accounts.map((a) => [a.id, a]));
  const byAddress = new Map(accounts.map((a) => [a.address, a]));
  const defaultAccount = accounts.find((a) => a.isDefault) ?? null;

  // [0] explicit caller choice wins (Step 4 UI)
  if (opts.explicitAccountId) {
    const explicit = byId.get(opts.explicitAccountId);
    if (explicit) return explicit;
    // explicit id no longer active/smtp-ready -> fall through to rules below
  }

  // [1] reply routing
  if (opts.inReplyTo) {
    const { data: origRaw, error } = await supabase
      .schema('app')
      .from('communications' as never)
      .select('direction, mail_account_id, to_addresses, cc_addresses')
      .eq('organization_id', organizationId)
      .eq('message_id', opts.inReplyTo)
      .maybeSingle();

    if (!error && origRaw) {
      const orig = origRaw as unknown as OriginalCommRow;

      // [1a] replying in a thread we started: keep the same sending account
      if (orig.direction === 'outbound' && orig.mail_account_id) {
        const cont = byId.get(orig.mail_account_id);
        if (cont) return cont;
      }

      if (orig.direction === 'inbound') {
        const recipients = [
          ...(orig.to_addresses ?? []),
          ...(orig.cc_addresses ?? []),
        ].map((a) => a.toLowerCase());

        // R1: default account was among the recipients -> default (deterministic
        //     winner for multi-account simultaneous delivery)
        if (defaultAccount && recipients.includes(defaultAccount.address)) {
          return defaultAccount;
        }

        // R2: the account that actually persisted the inbound row (Step 2)
        if (orig.mail_account_id) {
          const persisted = byId.get(orig.mail_account_id);
          if (persisted) return persisted;
        }

        // R3: reverse-match recipients against our accounts (legacy rows
        //     ingested before Step 2 have mail_account_id NULL)
        for (const addr of recipients) {
          const matched = byAddress.get(addr);
          if (matched) return matched;
        }
      }
    }
    // original not found / unmatched -> fall through to default
  }

  // [2] new mail (or unresolvable reply): default account
  return defaultAccount;
}

/* ============================================================
 * SMTP password decryption
 * ============================================================ */

/**
 * Decrypt smtp_password_encrypted (bytea, pgp_sym_encrypt) via the same RPC
 * and key used for the IMAP password (see mailcarrier.ts decryptAccountPassword).
 * SMTP passwords were backfilled as copies of the IMAP password (Step 1),
 * so the shared RPC applies.
 */
export async function decryptMailAccountSmtpPassword(
  supabase: SbClient,
  account: Pick<MailAccount, 'id' | 'smtpPasswordEncrypted'>,
): Promise<string> {
  const encKey = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY;
  if (!encKey) {
    throw new Error(
      'CALENDAR_TOKEN_ENCRYPTION_KEY not set (required to decrypt mail account SMTP password)',
    );
  }
  const rpcClient = supabase.schema('app') as unknown as {
    rpc: (
      fn: string,
      args: Record<string, unknown>,
    ) => Promise<{ data: unknown; error: { message: string } | null }>;
  };
  const { data, error } = await rpcClient.rpc('decrypt_inbound_mailbox_password', {
    encrypted: account.smtpPasswordEncrypted,
    enc_key: encKey,
  });
  if (error || typeof data !== 'string') {
    throw new Error(
      `SMTP password decrypt failed (account=${account.id}): ${error?.message ?? 'no data'}`,
    );
  }
  return data;
}
