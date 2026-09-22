"use server";
/**
 * lib/actions/register-recipient.ts
 *
 * 2026-09-21: "recipient not in whitelist" on send -> the compose dialog asks
 * "Register <addr> in the whitelist and Investors contacts?" and, on OK,
 * calls registerRecipientAsInvestor() and retries the send.
 *
 * Party resolution (first hit wins, never moves an existing contact):
 *   1. an active contact with this exact email -> its party
 *   2. the party the dialog was opened from (hintPartyId)
 *   3. an INVESTOR party that already has a contact on the same company domain
 *   4. an INVESTOR party whose website contains the registrable domain
 *   5. otherwise create a new investor party (name = domain, website = domain)
 * Domain matching is limited to investor-type parties on purpose: paper-mill /
 * filler-supplier domains legitimately span many separate party records.
 *
 * Then registerAddressEntry() upserts the contact and adds the address to
 * app.email_whitelist (kind='address').
 */
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { createParty } from "@/lib/actions/parties";
import { registerAddressEntry } from "@/lib/actions/email-whitelist";
import { revalidatePath } from "next/cache";

const PUBLIC_DOMAINS = new Set([
  "gmail.com", "googlemail.com", "yahoo.com", "hotmail.com", "outlook.com",
  "live.com", "msn.com", "icloud.com", "me.com", "aol.com", "proton.me",
  "protonmail.com", "naver.com", "daum.net", "hanmail.net", "kakao.com",
  "qq.com", "163.com", "126.com",
]);

export type RecipientPartyPlan = {
  email: string;
  /** existing party the contact will be linked to (null -> a new one is created) */
  partyId: string | null;
  partyName: string;
  partyTypeCode: string | null;
  willCreateParty: boolean;
};

export type RegisterRecipientResult =
  | { ok: true; partyId: string; partyName: string; contactId: string | null; createdParty: boolean }
  | { ok: false; error: string };

function splitDomain(email: string) {
  const domain = email.split("@")[1]?.toLowerCase() ?? "";
  const parts = domain.split(".");
  const registrable = parts.length > 2 ? parts.slice(-2).join(".") : domain;
  const isPublic = PUBLIC_DOMAINS.has(domain) || PUBLIC_DOMAINS.has(registrable);
  return { domain, registrable, isPublic };
}

async function resolvePlan(
  email: string,
  hintPartyId: string | null | undefined,
  fullName: string | null | undefined,
): Promise<RecipientPartyPlan> {
  const auth = await requireAuth();
  const orgId = auth.organizationId;
  const sb = await createSupabaseServerClient();
  const { domain, registrable, isPublic } = splitDomain(email);

  const { data: ptRows } = await sb.schema("app")
    .from("party_types" as never)
    .select("id, code");
  const types = (ptRows ?? []) as Array<{ id: number; code: string }>;
  const codeOf = new Map(types.map((t) => [t.id, t.code]));
  const investorTypeId = types.find((t) => t.code === "investor")?.id ?? null;

  const partyById = async (id: string) => {
    const { data } = await sb.schema("app")
      .from("parties" as never)
      .select("id, party_name, party_type_id")
      .eq("id" as never, id as never)
      .is("deleted_at" as never, null)
      .maybeSingle();
    return data as { id: string; party_name: string | null; party_type_id: number | null } | null;
  };
  const planFor = (p: { id: string; party_name: string | null; party_type_id: number | null }) => ({
    email,
    partyId: p.id,
    partyName: p.party_name ?? "",
    partyTypeCode: p.party_type_id != null ? (codeOf.get(p.party_type_id) ?? null) : null,
    willCreateParty: false,
  });

  // [1] exact contact
  const { data: ex } = await sb.schema("app")
    .from("contacts" as never)
    .select("party_id")
    .eq("organization_id" as never, orgId as never)
    .eq("email" as never, email as never)
    .is("deleted_at" as never, null)
    .not("party_id" as never, "is", null)
    .order("updated_at" as never, { ascending: false })
    .limit(1)
    .maybeSingle();
  const exPartyId = (ex as { party_id?: string } | null)?.party_id;
  if (exPartyId) {
    const p = await partyById(exPartyId);
    if (p) return planFor(p);
  }

  // [2] hint party (dialog context)
  if (hintPartyId) {
    const p = await partyById(hintPartyId);
    if (p) return planFor(p);
  }

  // [3]/[4] investor party on the same company domain
  if (!isPublic && domain && investorTypeId != null) {
    const { data: sameDomain } = await sb.schema("app")
      .from("contacts" as never)
      .select("party_id")
      .eq("organization_id" as never, orgId as never)
      .ilike("email" as never, `%@${domain}` as never)
      .is("deleted_at" as never, null)
      .not("party_id" as never, "is", null)
      .limit(50);
    const ids = Array.from(new Set(
      ((sameDomain ?? []) as Array<{ party_id: string }>).map((r) => r.party_id),
    ));
    if (ids.length > 0) {
      const { data: inv } = await sb.schema("app")
        .from("parties" as never)
        .select("id, party_name, party_type_id")
        .in("id" as never, ids as never)
        .eq("party_type_id" as never, investorTypeId as never)
        .is("deleted_at" as never, null)
        .limit(1)
        .maybeSingle();
      if (inv) return planFor(inv as { id: string; party_name: string | null; party_type_id: number | null });
    }

    const { data: byWeb } = await sb.schema("app")
      .from("parties" as never)
      .select("id, party_name, party_type_id")
      .eq("organization_id" as never, orgId as never)
      .eq("party_type_id" as never, investorTypeId as never)
      .is("deleted_at" as never, null)
      .ilike("website" as never, `%${registrable}%` as never)
      .limit(1)
      .maybeSingle();
    if (byWeb) return planFor(byWeb as { id: string; party_name: string | null; party_type_id: number | null });
  }

  // [5] new investor party
  return {
    email,
    partyId: null,
    partyName: isPublic ? (fullName?.trim() || email) : registrable,
    partyTypeCode: "investor",
    willCreateParty: true,
  };
}

/** Read-only: what registration would do (used for the confirm message). */
export async function previewRecipientRegistration(input: {
  email: string;
  hintPartyId?: string | null;
  fullName?: string | null;
}): Promise<{ ok: true; plan: RecipientPartyPlan } | { ok: false; error: string }> {
  const email = input.email.trim().toLowerCase();
  if (!/^\S+@\S+\.\S+$/.test(email)) return { ok: false, error: "Invalid email" };
  try {
    return { ok: true, plan: await resolvePlan(email, input.hintPartyId, input.fullName) };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Lookup failed" };
  }
}

/** Register the address: contact under the resolved (or new investor) party + whitelist. */
export async function registerRecipientAsInvestor(input: {
  email: string;
  hintPartyId?: string | null;
  fullName?: string | null;
}): Promise<RegisterRecipientResult> {
  const email = input.email.trim().toLowerCase();
  if (!/^\S+@\S+\.\S+$/.test(email)) return { ok: false, error: "Invalid email" };

  let plan: RecipientPartyPlan;
  try {
    plan = await resolvePlan(email, input.hintPartyId, input.fullName);
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Lookup failed" };
  }

  let partyId = plan.partyId;
  let createdParty = false;
  if (!partyId) {
    const { registrable, isPublic } = splitDomain(email);
    const created = await createParty({
      name: plan.partyName,
      partyType: "investor",
      partyKind: isPublic ? "individual" : "company",
      website: isPublic ? null : `https://${registrable}`,
      source: "reply_register",
      notes: `Auto-created when replying to ${email}. Rename / complete the profile.`,
    });
    if (!created.ok || !created.partyId) {
      return { ok: false, error: created.errorMessage ?? "Could not create investor party" };
    }
    partyId = created.partyId;
    createdParty = true;
  }

  const reg = await registerAddressEntry({
    email,
    partyId,
    fullName: input.fullName ?? undefined,
    notes: "Added from reply (investor contact)",
  });
  if (!reg.ok) {
    return { ok: false, error: "error" in reg ? reg.error : "Contact is linked to another party" };
  }

  const sb = await createSupabaseServerClient();
  const { data: c } = await sb.schema("app")
    .from("contacts" as never)
    .select("id")
    .eq("email" as never, email as never)
    .eq("party_id" as never, partyId as never)
    .is("deleted_at" as never, null)
    .limit(1)
    .maybeSingle();

  revalidatePath("/investor/parties");
  return {
    ok: true,
    partyId,
    partyName: reg.partyName || plan.partyName,
    contactId: (c as { id?: string } | null)?.id ?? null,
    createdParty,
  };
}
