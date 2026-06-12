/**
 * lib/actions/contacts.ts
 *
 * Contact CRUD Server Actions.
 *
 * Change history:
 *   - 2026-06-12: column mapping fixed against the live app.contacts schema
 *     (verified via information_schema; the table has NO check constraints):
 *       title              -> title_text
 *       phone              -> phone_e164
 *       decision_role      -> role_category (text) + is_decision_maker (bool)
 *       seniority          -> seniority_level
 *       preferred_language -> extra_data.preferred_language (no dedicated column)
 *     Added contact_type_id (NOT NULL in DB; default 1 = employee).
 *     Previous code inserted nonexistent columns, so dialog saves failed at runtime.
 *   - 2026-06-12: auto-register the contact's email in app.email_whitelist
 *     (kind=address) on create/update. Routing party is already exact via
 *     contacts.email match, so this only grants inbound acceptance.
 *   - 2026-06-12: on update, fields NOT exposed by the contact dialog
 *     (given/family name, department, linkedin, seniority, role) are only
 *     written when explicitly provided, so SQL-enriched data
 *     (e.g. is_decision_maker on investor contacts) is not clobbered by
 *     a UI edit that always sends decisionRole='unknown'.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { rpc } from '@/lib/rpc/typed-rpc';

export interface ContactActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'not_found' | 'validation' | 'database';
  errorMessage?: string;
  contactId?: string;
}

const DEFAULT_CONTACT_TYPE_ID = 1; // app.contact_types: 1=employee

const contactSchema = z.object({
  partyId: z.string().uuid(),
  fullName: z.string().min(1, 'Required').max(160),
  givenName: z.string().max(80).optional().or(z.literal('').transform(() => undefined)),
  familyName: z.string().max(80).optional().or(z.literal('').transform(() => undefined)),
  title: z.string().max(120).optional().or(z.literal('').transform(() => undefined)),
  department: z.string().max(120).optional().or(z.literal('').transform(() => undefined)),
  email: z
    .string()
    .email()
    .max(255)
    .optional()
    .or(z.literal('').transform(() => undefined)),
  phone: z.string().max(40).optional().or(z.literal('').transform(() => undefined)),
  linkedinUrl: z
    .string()
    .url()
    .max(500)
    .optional()
    .or(z.literal('').transform(() => undefined)),
  decisionRole: z
    .enum(['decision_maker', 'influencer', 'gatekeeper', 'user', 'champion', 'unknown'])
    .default('unknown'),
  seniority: z
    .enum(['c_level', 'vp', 'director', 'manager', 'staff', 'intern', 'other'])
    .optional()
    .or(z.literal('').transform(() => undefined)),
  preferredLanguage: z
    .enum(['ko', 'en', 'ja', 'zh-CN'])
    .optional()
    .or(z.literal('').transform(() => undefined)),
  isPrimary: z.boolean().default(false),
  notes: z.string().max(5000).optional().or(z.literal('').transform(() => undefined)),
});

/* ============================================================
 * Auto-whitelist helper (2026-06-12)
 * ============================================================ */

/**
 * Best-effort: register the contact's email address in app.email_whitelist
 * so inbound mail from this person is accepted automatically.
 * Never throws / never fails the contact save; duplicates are tolerated.
 * (Exact addresses are safe to whitelist even on free-mail domains.)
 */
async function autoWhitelistContactEmail(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  organizationId: string,
  email: string | null | undefined,
  fullName: string,
): Promise<void> {
  const normalized = email?.trim().toLowerCase();
  if (!normalized || !normalized.includes('@')) return;
  try {
    const { error } = await rpc(supabase, 'add_email_whitelist', {
      p_org_id: organizationId,
      p_pattern: normalized,
      p_kind: 'address',
      p_notes: `auto: contact (${fullName})`,
    });
    if (error && !/duplicate|unique|already|exists/i.test(error.message)) {
      console.warn('[contacts.autoWhitelistContactEmail] add failed:', error.message);
    }
  } catch (e) {
    console.warn('[contacts.autoWhitelistContactEmail] unexpected:', e);
  }
}

/* ============================================================
 * Create
 * ============================================================ */

export async function createContact(
  input: z.input<typeof contactSchema>,
): Promise<ContactActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = contactSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const fullName = parsed.data.fullName.trim();
  const email = parsed.data.email?.trim().toLowerCase() || null;

  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    party_id: parsed.data.partyId,
    contact_type_id: DEFAULT_CONTACT_TYPE_ID,
    full_name: fullName,
    given_name: parsed.data.givenName?.trim() || null,
    family_name: parsed.data.familyName?.trim() || null,
    title_text: parsed.data.title?.trim() || null,
    department: parsed.data.department?.trim() || null,
    email,
    phone_e164: parsed.data.phone?.trim() || null,
    linkedin_url: parsed.data.linkedinUrl || null,
    role_category: parsed.data.decisionRole !== 'unknown' ? parsed.data.decisionRole : null,
    is_decision_maker: parsed.data.decisionRole === 'decision_maker',
    seniority_level: parsed.data.seniority || null,
    is_primary: parsed.data.isPrimary,
    notes: parsed.data.notes?.trim() || null,
    source: 'contact_form_ui',
  };
  if (parsed.data.preferredLanguage) {
    insertRow.extra_data = { preferred_language: parsed.data.preferredLanguage };
  }

  const { data, error } = await supabase
    .schema('app')
    .from('contacts' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (error || !data) {
    return { ok: false, errorCode: 'database', errorMessage: error?.message ?? 'Insert failed' };
  }

  // if is_primary=true, set the party's other contacts to false (manual if there is no trigger)
  if (parsed.data.isPrimary) {
    await supabase
      .schema('app')
      .from('contacts' as never)
      .update({ is_primary: false } as never)
      .eq('party_id', parsed.data.partyId)
      .neq('id', (data as { id: string }).id);
  }

  // 2026-06-12: auto-register the contact's email in the whitelist.
  await autoWhitelistContactEmail(supabase, auth.organizationId, email, fullName);

  // fetching the party module is costly - the caller handles module-based redirects
  revalidatePath(`/`, 'layout');
  return { ok: true, contactId: (data as { id: string }).id };
}

/* ============================================================
 * Update
 * ============================================================ */

const updateContactSchema = contactSchema.extend({
  contactId: z.string().uuid(),
});

export async function updateContact(
  input: z.input<typeof updateContactSchema>,
): Promise<ContactActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = updateContactSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const fullName = parsed.data.fullName.trim();
  const email = parsed.data.email?.trim().toLowerCase() || null;

  // Fields exposed by the contact dialog: always written (dialog prefills them).
  const updates: Record<string, unknown> = {
    full_name: fullName,
    title_text: parsed.data.title?.trim() || null,
    email,
    phone_e164: parsed.data.phone?.trim() || null,
    is_primary: parsed.data.isPrimary,
    updated_at: new Date().toISOString(),
  };
  if (parsed.data.notes?.trim()) updates.notes = parsed.data.notes.trim();

  // Fields NOT exposed by the dialog: only write when explicitly provided,
  // so SQL-enriched values are never clobbered by a UI edit.
  if (parsed.data.givenName) updates.given_name = parsed.data.givenName.trim();
  if (parsed.data.familyName) updates.family_name = parsed.data.familyName.trim();
  if (parsed.data.department) updates.department = parsed.data.department.trim();
  if (parsed.data.linkedinUrl) updates.linkedin_url = parsed.data.linkedinUrl;
  if (parsed.data.seniority) updates.seniority_level = parsed.data.seniority;
  if (parsed.data.decisionRole !== 'unknown') {
    updates.role_category = parsed.data.decisionRole;
    updates.is_decision_maker = parsed.data.decisionRole === 'decision_maker';
  }
  if (parsed.data.preferredLanguage) {
    // merge into extra_data without losing other keys
    const { data: cur } = await supabase
      .schema('app')
      .from('contacts' as never)
      .select('extra_data')
      .eq('id', parsed.data.contactId)
      .maybeSingle();
    const curExtra = ((cur as { extra_data?: Record<string, unknown> } | null)?.extra_data) ?? {};
    updates.extra_data = { ...curExtra, preferred_language: parsed.data.preferredLanguage };
  }

  const { error, data } = await supabase
    .schema('app')
    .from('contacts' as never)
    .update(updates as never)
    .eq('id', parsed.data.contactId)
    .eq('organization_id', auth.organizationId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  if (parsed.data.isPrimary) {
    await supabase
      .schema('app')
      .from('contacts' as never)
      .update({ is_primary: false } as never)
      .eq('party_id', parsed.data.partyId)
      .neq('id', parsed.data.contactId);
  }

  // 2026-06-12: keep the whitelist in sync when an email is added/changed.
  await autoWhitelistContactEmail(supabase, auth.organizationId, email, fullName);

  revalidatePath(`/`, 'layout');
  return { ok: true, contactId: parsed.data.contactId };
}

/* ============================================================
 * Delete
 * ============================================================ */

export async function deleteContact(input: {
  contactId: string;
}): Promise<ContactActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = z.object({ contactId: z.string().uuid() }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('contacts' as never)
    .delete()
    .eq('id', parsed.data.contactId)
    .eq('organization_id', auth.organizationId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  revalidatePath(`/`, 'layout');
  return { ok: true };
}
