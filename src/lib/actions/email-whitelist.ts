"use server";
/**
 * lib/actions/email-whitelist.ts
 *
 * Email whitelist management + party-aware address registration.
 *
 * Why party-aware: inbound routing (matchSenderToContactAndParty) resolves
 * party by exact contacts.email match first. A domain like omya.com spans
 * multiple parties (Omya HQ / Omya Korea), so address-level registration
 * must create/relink the contact under the correct party to make routing
 * deterministic.
 */
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { rpc } from "@/lib/rpc/typed-rpc";
import { revalidatePath } from "next/cache";

const ORG_ID = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID!;
const SOURCE_TAG = "whitelist_ui";

export type WhitelistEntry = {
  id: string;
  pattern: string;
  kind: string;
  notes: string | null;
  is_active: boolean;
  created_at: string;
};
export type UnregisteredDomain = {
  domain: string;
  party_names: string;
  contact_count: number;
};
export type PartyOption = {
  id: string;
  name: string;
  country: string | null;
  typeCode: string | null;
};
export type AddressAssignment = {
  contactId: string;
  partyId: string;
  partyName: string;
  fullName: string | null;
};
export type RegisterAddressResult =
  | { ok: true; partyName: string; action: "created" | "linked" | "moved"; warning?: string }
  | { ok: false; error: string }
  | { ok: false; conflict: { contactId: string; partyId: string; partyName: string } };

/* ============================================================
 * Existing CRUD (unchanged behavior)
 * ============================================================ */

export async function listWhitelist() {
  const sb = await createSupabaseServerClient();
  const { data } = await rpc(sb, "list_email_whitelist", { p_org_id: ORG_ID });
  return (data || []) as unknown as WhitelistEntry[];
}

export async function getUnregisteredDomains() {
  const sb = await createSupabaseServerClient();
  const { data } = await rpc(sb, "get_unregistered_party_domains", { p_org_id: ORG_ID });
  return (data || []) as unknown as UnregisteredDomain[];
}

export async function addWhitelistEntry(
  pattern: string,
  kind: "domain" | "address",
  notes: string,
): Promise<{ ok: boolean; error?: string }> {
  const p = pattern.trim().toLowerCase();
  if (!p) return { ok: false, error: "empty" };
  if (kind === "domain" && p.includes("@")) return { ok: false, error: "Enter the domain without @" };
  if (kind === "address" && !p.includes("@")) return { ok: false, error: "Enter the address including @" };
  const sb = await createSupabaseServerClient();
  const { error } = await rpc(sb, "add_email_whitelist", {
    p_org_id: ORG_ID, p_pattern: p, p_kind: kind, p_notes: notes || undefined,
  });
  if (error) return { ok: false, error: error.message };
  revalidatePath("/settings/email-whitelist");
  return { ok: true };
}

export async function bulkAddDomains(
  domains: Array<{ domain: string; notes: string }>,
): Promise<{ ok: boolean; added: number }> {
  const sb = await createSupabaseServerClient();
  let added = 0;
  for (const { domain, notes } of domains) {
    const { error } = await rpc(sb, "add_email_whitelist", {
      p_org_id: ORG_ID, p_pattern: domain.toLowerCase().trim(), p_kind: "domain", p_notes: notes || undefined,
    });
    if (!error) added++;
  }
  revalidatePath("/settings/email-whitelist");
  return { ok: true, added };
}

export async function toggleWhitelistEntry(id: string, active: boolean) {
  const sb = await createSupabaseServerClient();
  await rpc(sb, "toggle_email_whitelist", { p_id: id, p_active: active });
  revalidatePath("/settings/email-whitelist");
  return { ok: true };
}

export async function deleteWhitelistEntry(id: string) {
  const sb = await createSupabaseServerClient();
  await rpc(sb, "delete_email_whitelist", { p_id: id });
  revalidatePath("/settings/email-whitelist");
  return { ok: true };
}

/* ============================================================
 * Party-aware address registration (new)
 * ============================================================ */

/** Type-ahead search across ALL party types (the /api/parties/search route
 *  is fixed to one type, so the whitelist screen uses this instead). */
export async function searchPartiesForWhitelist(q: string): Promise<PartyOption[]> {
  const query = q.trim();
  if (query.length < 2) return [];
  const sb = await createSupabaseServerClient();

  // party_types is a small lookup table; map id -> code for labels
  const { data: ptRows } = await sb.schema("app")
    .from("party_types" as never)
    .select("id, code");
  const typeCode = new Map<number, string>(
    ((ptRows ?? []) as Array<{ id: number; code: string }>).map(r => [r.id, r.code]),
  );

  const { data, error } = await sb.schema("app")
    .from("parties" as never)
    .select("id, party_name, country_code, party_type_id")
    .eq("organization_id" as never, ORG_ID as never)
    .ilike("party_name" as never, `%${query}%` as never)
    .is("deleted_at" as never, null)
    .order("party_name" as never)
    .limit(12);

  if (error) return [];
  return ((data ?? []) as Array<{
    id: string; party_name: string | null; country_code: string | null; party_type_id: number | null;
  }>).map(r => ({
    id: r.id,
    name: r.party_name ?? "",
    country: r.country_code ?? null,
    typeCode: r.party_type_id != null ? (typeCode.get(r.party_type_id) ?? null) : null,
  }));
}

/** Resolve which party each whitelisted address currently belongs to
 *  (via active contacts.email exact match — same source of truth the
 *  inbound matcher uses). Keys are lowercased emails. */
export async function getAddressAssignments(
  emails: string[],
): Promise<Record<string, AddressAssignment>> {
  const list = Array.from(new Set(emails.map(e => e.trim().toLowerCase()).filter(Boolean)));
  if (list.length === 0) return {};
  const sb = await createSupabaseServerClient();

  const { data: contacts, error } = await sb.schema("app")
    .from("contacts" as never)
    .select("id, email, full_name, party_id, updated_at")
    .eq("organization_id" as never, ORG_ID as never)
    .in("email" as never, list as never)
    .is("deleted_at" as never, null)
    .order("updated_at" as never, { ascending: false });

  if (error || !contacts) return {};
  const rows = contacts as Array<{
    id: string; email: string | null; full_name: string | null; party_id: string | null;
  }>;

  const partyIds = Array.from(new Set(rows.map(r => r.party_id).filter((v): v is string => !!v)));
  const partyName = new Map<string, string>();
  if (partyIds.length > 0) {
    const { data: parties } = await sb.schema("app")
      .from("parties" as never)
      .select("id, party_name")
      .in("id" as never, partyIds as never);
    for (const p of (parties ?? []) as Array<{ id: string; party_name: string | null }>) {
      partyName.set(p.id, p.party_name ?? "");
    }
  }

  const out: Record<string, AddressAssignment> = {};
  for (const r of rows) {
    const key = (r.email ?? "").toLowerCase();
    if (!key || out[key] || !r.party_id) continue; // first hit = most recently updated
    out[key] = {
      contactId: r.id,
      partyId: r.party_id,
      partyName: partyName.get(r.party_id) ?? "(unknown)",
      fullName: r.full_name,
    };
  }
  return out;
}

/**
 * Register an email address with an explicit party:
 *   1. upsert the contact under that party (exact-match routing source)
 *   2. add the address to the whitelist (duplicate tolerated)
 *
 * If the email already belongs to a DIFFERENT party and force=false,
 * returns a conflict so the UI can ask before moving the contact.
 */
export async function registerAddressEntry(input: {
  email: string;
  partyId: string;
  fullName?: string;
  contactTypeId?: number; // app.contact_types: 1 employee (default), 2 partner, 5 executive ...
  notes?: string;
  force?: boolean;
}): Promise<RegisterAddressResult> {
  const email = input.email.trim().toLowerCase();
  if (!email.includes("@")) return { ok: false, error: "Enter the address including @" };
  if (!input.partyId) return { ok: false, error: "Select a party" };
  const fullName = input.fullName?.trim() || null;
  const contactTypeId = input.contactTypeId ?? 1;

  const sb = await createSupabaseServerClient();

  // target party name (also validates the id)
  const { data: targetParty } = await sb.schema("app")
    .from("parties" as never)
    .select("id, party_name")
    .eq("id" as never, input.partyId as never)
    .maybeSingle();
  const targetName = (targetParty as { party_name?: string } | null)?.party_name;
  if (!targetName && targetName !== "") return { ok: false, error: "Party not found" };

  // existing active contact with this exact email?
  const { data: existing } = await sb.schema("app")
    .from("contacts" as never)
    .select("id, party_id, full_name")
    .eq("organization_id" as never, ORG_ID as never)
    .eq("email" as never, email as never)
    .is("deleted_at" as never, null)
    .order("updated_at" as never, { ascending: false })
    .limit(1)
    .maybeSingle();

  const ex = existing as { id: string; party_id: string | null; full_name: string | null } | null;

  let action: "created" | "linked" | "moved";

  if (ex && ex.party_id && ex.party_id !== input.partyId && !input.force) {
    const { data: curParty } = await sb.schema("app")
      .from("parties" as never)
      .select("party_name")
      .eq("id" as never, ex.party_id as never)
      .maybeSingle();
    return {
      ok: false,
      conflict: {
        contactId: ex.id,
        partyId: ex.party_id,
        partyName: (curParty as { party_name?: string } | null)?.party_name ?? "(unknown)",
      },
    };
  }

  if (ex) {
    // same party (link) or force move; backfill full_name if it was empty
    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (ex.party_id !== input.partyId) patch.party_id = input.partyId;
    if (fullName && !ex.full_name) patch.full_name = fullName;
    const { error: upErr } = await sb.schema("app")
      .from("contacts" as never)
      .update(patch as never)
      .eq("id" as never, ex.id as never);
    if (upErr) return { ok: false, error: upErr.message };
    action = ex.party_id === input.partyId ? "linked" : "moved";
  } else {
    const { error: insErr } = await sb.schema("app")
      .from("contacts" as never)
      .insert({
        organization_id: ORG_ID,
        party_id: input.partyId,
        contact_type_id: contactTypeId,
        email,
        full_name: fullName,
        source: SOURCE_TAG,
      } as never);
    if (insErr) return { ok: false, error: insErr.message };
    action = "created";
  }

  // whitelist entry (tolerate duplicates — the address may already be listed)
  let warning: string | undefined;
  const { error: wlErr } = await rpc(sb, "add_email_whitelist", {
    p_org_id: ORG_ID, p_pattern: email, p_kind: "address", p_notes: input.notes || undefined,
  });
  if (wlErr && !/duplicate|unique|already|exists/i.test(wlErr.message)) {
    warning = `Contact saved, but whitelist add failed: ${wlErr.message}`;
  }

  revalidatePath("/settings/email-whitelist");
  return { ok: true, partyName: targetName ?? "", action, warning };
}
