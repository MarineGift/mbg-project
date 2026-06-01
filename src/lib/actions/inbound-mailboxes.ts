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
};

// list - never select password_encrypted (neither plaintext nor ciphertext goes to the client)
export async function listMailboxes(): Promise<InboundMailbox[]> {
  const sb = createSupabaseAdminClient();
  const { data } = await sb
    .schema("app")
    .from("inbound_mailboxes")
    .select("id, address, label, imap_host, imap_port, use_tls, is_active, created_at")
    .eq("organization_id", ORG_ID)
    .order("created_at", { ascending: true });
  return (data || []) as unknown as InboundMailbox[];
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
