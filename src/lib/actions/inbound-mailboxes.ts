// src/lib/actions/inbound-mailboxes.ts
"use server";
import { revalidatePath } from "next/cache";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

const ORG_ID = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID!;
const ENC_KEY = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY!;

export type InboundMailbox = {
  id: string;
  address: string;
  label: string | null;
  imap_host: string;
  imap_port: number;
  use_tls: boolean;
  is_active: boolean;
  created_at: string;
  // SMTP (sending) - smtp_password_encrypted is never sent to the client; only its presence (has_smtp_pw).
  smtp_host: string | null;
  smtp_port: number | null;
  smtp_use_tls: boolean | null;
  smtp_username: string | null;
  has_smtp_pw: boolean;
};

// list - never expose smtp_password_encrypted ciphertext to the client; only has_smtp_pw.
export async function listMailboxes(): Promise<InboundMailbox[]> {
  const sb = createSupabaseAdminClient();
  const { data } = await sb
    .schema("app")
    .from("inbound_mailboxes")
    .select(
      "id, address, label, imap_host, imap_port, use_tls, is_active, created_at, smtp_host, smtp_port, smtp_use_tls, smtp_username, smtp_password_encrypted",
    )
    .eq("organization_id", ORG_ID)
    .order("created_at", { ascending: true });
  type Row = Omit<InboundMailbox, "has_smtp_pw"> & { smtp_password_encrypted: string | null };
  return ((data || []) as unknown as Row[]).map((r) => {
    const { smtp_password_encrypted, ...rest } = r;
    return { ...rest, has_smtp_pw: !!smtp_password_encrypted } as InboundMailbox;
  });
}

// add/update - the password flows only on the server and is immediately encrypted via RPC (pgp_sym_encrypt).
// upsert_inbound_mailbox may not be in types/database.ts yet, so call it directly + cast instead of the rpc helper.
export async function addMailbox(
  address: string,
  host: string,
  port: number,
  label: string,
  useTls: boolean,
  password: string,
): Promise<{ ok: boolean; error?: string }> {
  const addr = address.trim().toLowerCase();
  if (!addr || !addr.includes("@")) return { ok: false, error: "Please enter a valid email address" };
  if (!host.trim()) return { ok: false, error: "Please enter the IMAP host" };
  if (!password) return { ok: false, error: "Please enter a password" };
  if (!Number.isFinite(port) || port <= 0) return { ok: false, error: "Invalid port" };

  const sb = createSupabaseAdminClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (sb.schema("app").rpc as any)("upsert_inbound_mailbox", {
    p_organization_id: ORG_ID,
    p_address: addr,
    p_label: label.trim() || null,
    p_imap_host: host.trim(),
    p_imap_port: port,
    p_use_tls: useTls,
    p_password: password,
    p_enc_key: ENC_KEY,
  });
  if (error) return { ok: false, error: error.message };
  revalidatePath("/settings/email-mailboxes");
  return { ok: true };
}

// update an existing mailbox. Uses the same upsert RPC keyed on address, so
// host/port/tls/label/password are all replaced. Password is required (the
// RPC always re-encrypts); to change only host/port, re-enter the password.
export async function updateMailbox(
  address: string,
  host: string,
  port: number,
  label: string,
  useTls: boolean,
  password: string,
): Promise<{ ok: boolean; error?: string }> {
  // identical backend path to addMailbox (upsert keyed on address)
  return addMailbox(address, host, port, label, useTls, password);
}

// Save the SMTP (sending) settings for an existing mailbox. Independent of the
// IMAP upsert: the SMTP app-password is optional (empty = keep the stored one),
// so host/port/TLS/username can be changed without re-entering the password.
// Encryption mirrors the IMAP path: pgp_sym_encrypt(..., ENC_KEY) via RPC,
// decryptable by the same decrypt_inbound_mailbox_password used for sending.
export async function updateMailboxSmtp(
  address: string,
  smtpHost: string,
  smtpPort: number,
  smtpUseTls: boolean,
  smtpUsername: string,
  smtpPassword: string,
): Promise<{ ok: boolean; error?: string }> {
  const addr = address.trim().toLowerCase();
  if (!addr || !addr.includes("@")) return { ok: false, error: "Invalid mailbox address" };
  if (!smtpHost.trim()) return { ok: false, error: "Please enter the SMTP host" };
  if (!Number.isFinite(smtpPort) || smtpPort <= 0) return { ok: false, error: "Invalid SMTP port" };

  const sb = createSupabaseAdminClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (sb.schema("app").rpc as any)("update_inbound_mailbox_smtp", {
    p_organization_id: ORG_ID,
    p_address: addr,
    p_smtp_host: smtpHost.trim(),
    p_smtp_port: smtpPort,
    p_smtp_use_tls: smtpUseTls,
    p_smtp_username: smtpUsername.trim() || addr,
    p_smtp_password: smtpPassword ? smtpPassword : null,
    p_enc_key: ENC_KEY,
  });
  if (error) return { ok: false, error: error.message };
  revalidatePath("/settings/email-mailboxes");
  return { ok: true };
}

export async function toggleMailbox(id: string, active: boolean): Promise<{ ok: boolean }> {
  const sb = createSupabaseAdminClient();
  await sb
    .schema("app")
    .from("inbound_mailboxes")
    .update({ is_active: active } as never)
    .eq("id", id)
    .eq("organization_id", ORG_ID);
  revalidatePath("/settings/email-mailboxes");
  return { ok: true };
}

export async function deleteMailbox(id: string): Promise<{ ok: boolean }> {
  const sb = createSupabaseAdminClient();
  await sb
    .schema("app")
    .from("inbound_mailboxes")
    .delete()
    .eq("id", id)
    .eq("organization_id", ORG_ID);
  revalidatePath("/settings/email-mailboxes");
  return { ok: true };
}
