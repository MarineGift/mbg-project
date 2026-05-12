/**
 * lib/actions/contacts.ts
 *
 * Contact CRUD Server Actions.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface ContactActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'not_found' | 'validation' | 'database';
  errorMessage?: string;
  contactId?: string;
}

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
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    party_id: parsed.data.partyId,
    full_name: parsed.data.fullName.trim(),
    given_name: parsed.data.givenName?.trim() || null,
    family_name: parsed.data.familyName?.trim() || null,
    title: parsed.data.title?.trim() || null,
    department: parsed.data.department?.trim() || null,
    email: parsed.data.email?.trim() || null,
    phone: parsed.data.phone?.trim() || null,
    linkedin_url: parsed.data.linkedinUrl || null,
    decision_role: parsed.data.decisionRole,
    seniority: parsed.data.seniority || null,
    preferred_language: parsed.data.preferredLanguage || null,
    is_primary: parsed.data.isPrimary,
    notes: parsed.data.notes?.trim() || null,
    created_by: auth.userId,
  };

  const { data, error } = await supabase
    .schema('app')
    .from('contacts' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (error || !data) {
    return { ok: false, errorCode: 'database', errorMessage: error?.message ?? 'Insert failed' };
  }

  // is_primary=true이면 같은 party의 다른 contacts는 false로 (트리거가 없으면 수동)
  if (parsed.data.isPrimary) {
    await supabase
      .schema('app')
      .from('contacts' as never)
      .update({ is_primary: false } as never)
      .eq('party_id', parsed.data.partyId)
      .neq('id', (data as { id: string }).id);
  }

  // party 모듈 fetch는 비용이 큼 — module 기반 redirect는 호출자가 처리
  revalidatePath(`/`, 'layout');
  return { ok: true, contactId: (data as { id: string }).id };
}

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
  const updates: Record<string, unknown> = {
    full_name: parsed.data.fullName.trim(),
    given_name: parsed.data.givenName?.trim() || null,
    family_name: parsed.data.familyName?.trim() || null,
    title: parsed.data.title?.trim() || null,
    department: parsed.data.department?.trim() || null,
    email: parsed.data.email?.trim() || null,
    phone: parsed.data.phone?.trim() || null,
    linkedin_url: parsed.data.linkedinUrl || null,
    decision_role: parsed.data.decisionRole,
    seniority: parsed.data.seniority || null,
    preferred_language: parsed.data.preferredLanguage || null,
    is_primary: parsed.data.isPrimary,
    notes: parsed.data.notes?.trim() || null,
    updated_by: auth.userId,
  };

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

  revalidatePath(`/`, 'layout');
  return { ok: true, contactId: parsed.data.contactId };
}

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
