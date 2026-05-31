// src/lib/actions/inbound-mailboxes.ts
"use server";
import { revalidatePath } from "next/cache";
import { createSupabaseServerClient } from "@/lib/supabase/server";

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

// 목록 — password_encrypted 는 절대 select 하지 않는다 (평문/암호문 모두 클라이언트로 안 감)
export async function listMailboxes(): Promise<InboundMailbox[]> {
  const sb = await createSupabaseServerClient();
  const { data } = await sb
    .from("inbound_mailboxes")
    .select("id, address, label, imap_host, imap_port, use_tls, is_active, created_at")
    .eq("organization_id", ORG_ID)
    .order("created_at", { ascending: true });
  return (data || []) as unknown as InboundMailbox[];
}

// 추가/갱신 — 비번은 서버에서만 흐르고 RPC(pgp_sym_encrypt)로 즉시 암호화 저장.
// upsert_inbound_mailbox 는 types/database.ts 에 아직 없을 수 있어 rpc 헬퍼 대신 직접 호출 + 캐스팅.
export async function addMailbox(
  address: string,
  host: string,
  port: number,
  label: string,
  useTls: boolean,
  password: string,
): Promise<{ ok: boolean; error?: string }> {
  const addr = address.trim().toLowerCase();
  if (!addr || !addr.includes("@")) return { ok: false, error: "유효한 이메일 주소를 입력하세요" };
  if (!host.trim()) return { ok: false, error: "IMAP 호스트를 입력하세요" };
  if (!password) return { ok: false, error: "비밀번호를 입력하세요" };
  if (!Number.isFinite(port) || port <= 0) return { ok: false, error: "포트가 올바르지 않습니다" };

  const sb = await createSupabaseServerClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (sb.rpc as any)("upsert_inbound_mailbox", {
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
  const sb = await createSupabaseServerClient();
  await sb
    .from("inbound_mailboxes")
    .update({ is_active: active } as never)
    .eq("id", id)
    .eq("organization_id", ORG_ID);
  revalidatePath("/settings/email-mailboxes");
  return { ok: true };
}

export async function deleteMailbox(id: string): Promise<{ ok: boolean }> {
  const sb = await createSupabaseServerClient();
  await sb
    .from("inbound_mailboxes")
    .delete()
    .eq("id", id)
    .eq("organization_id", ORG_ID);
  revalidatePath("/settings/email-mailboxes");
  return { ok: true };
}
