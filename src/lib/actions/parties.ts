/**
 * lib/actions/parties.ts
 *
 * Party Server Actions - create, update, delete.
 *
 * Delete is a soft delete (deleted_at = now()). A trigger handles the audit log automatically.
 *
 * Change history:
 *   - 2026-05-11: removed the industry column, use only the industry_tags / interest_tags arrays.
 *   - 2026-05-12: removed a reference to the nonexistent deleted_by column in deleteParty.
 *   - 2026-05-25 (Phase C): module → party_type, party_type → party_kind rename.
 *                 The TS schema is camelCase (partyType, partyKind); DB columns are snake_case.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { PARTY_TYPES, type PartyType } from '@/types/party-type';

export interface PartyActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'not_found' | 'database';
  errorMessage?: string;
  /** the new party id on successful create */
  partyId?: string;
}

const partySchema = z.object({
  name: z.string().min(1, 'Name is required').max(200),
  legalName: z.string().max(200).optional().nullable(),
  // business category
  // Tracks app.party_types via the canonical PARTY_TYPES list (see types/party-type.ts).
  partyType: z.enum(PARTY_TYPES as unknown as [PartyType, ...PartyType[]]),
  // legal entity form
  partyKind: z
    .enum(['company', 'organization', 'individual', 'fund', 'government'])
    .default('company'),
  tier: z.enum(['tier_1', 'tier_2', 'tier_3', 'cold']).optional().nullable(),
  countryCode: z
    .string()
    .length(2, 'Country code must be 2 letters')
    .optional()
    .nullable()
    .or(z.literal('').transform(() => null)),
  region: z.string().max(80).optional().nullable(),
  city: z.string().max(120).optional().nullable(),
  website: z
    .string()
    .url('Must be a valid URL')
    .max(500)
    .optional()
    .nullable()
    .or(z.literal('').transform(() => null)),
  industryTags: z.array(z.string().max(40)).max(20).optional().default([]),
  interestTags: z.array(z.string().max(40)).max(20).optional().default([]),
  source: z.string().max(120).optional().nullable(),
  notes: z.string().max(10_000).optional().nullable(),
});

export async function createParty(input: z.input<typeof partySchema>): Promise<PartyActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = partySchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // D6-5e: lookup party_type code -> party_type_id (smallint FK)
  const { data: ptRow } = await supabase
    .schema('app')
    .from('party_types' as never)
    .select('id')
    .eq('code' as never, parsed.data.partyType)
    .maybeSingle();
  if (!ptRow) {
    return { ok: false, errorCode: 'database', errorMessage: `Unknown party_type: ${parsed.data.partyType}` };
  }
  const partyTypeId = (ptRow as { id: number }).id;

  // D6-5e: lookup party_kind code -> entity_type_id (smallint FK)
  const { data: etRow } = await supabase
    .schema('app')
    .from('entity_types' as never)
    .select('id')
    .eq('code' as never, parsed.data.partyKind)
    .maybeSingle();
  if (!etRow) {
    return { ok: false, errorCode: 'database', errorMessage: `Unknown party_kind: ${parsed.data.partyKind}` };
  }
  const entityTypeId = (etRow as { id: number }).id;

  // D6-5e: dropped from INSERT (not in app.parties): legal_name, tier, industry_tags(array).
  // industry_tag_id is a single FK; form-array -> FK mapping deferred to T4b.
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    party_name: parsed.data.name.trim(),
    party_type_id: partyTypeId,
    entity_type_id: entityTypeId,
    country_code: parsed.data.countryCode || null,
    region: parsed.data.region?.trim() || null,
    city: parsed.data.city?.trim() || null,
    website: parsed.data.website || null,
    interest_tags: parsed.data.interestTags ?? [],
    source: parsed.data.source?.trim() || null,
    notes: parsed.data.notes?.trim() || null,
    created_by: auth.userId,
  };

  const { data, error } = await supabase
    .schema('app')
    .from('parties' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (error || !data) {
    console.error('[parties.createParty] insert error:', error);
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error?.message ?? 'Insert failed',
    };
  }
  const partyId = (data as { id: string }).id;

  revalidatePath(`/${parsed.data.partyType}/parties`);
  return { ok: true, partyId };
}

const updateSchema = partySchema.extend({
  partyId: z.string().uuid(),
});

export async function updateParty(
  input: z.input<typeof updateSchema>,
): Promise<PartyActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = updateSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // D6-5e: lookup party_type code -> party_type_id
  const { data: ptRow } = await supabase
    .schema('app')
    .from('party_types' as never)
    .select('id')
    .eq('code' as never, parsed.data.partyType)
    .maybeSingle();
  if (!ptRow) {
    return { ok: false, errorCode: 'database', errorMessage: `Unknown party_type: ${parsed.data.partyType}` };
  }
  const partyTypeId = (ptRow as { id: number }).id;

  // D6-5e: lookup party_kind code -> entity_type_id
  const { data: etRow } = await supabase
    .schema('app')
    .from('entity_types' as never)
    .select('id')
    .eq('code' as never, parsed.data.partyKind)
    .maybeSingle();
  if (!etRow) {
    return { ok: false, errorCode: 'database', errorMessage: `Unknown party_kind: ${parsed.data.partyKind}` };
  }
  const entityTypeId = (etRow as { id: number }).id;

  // D6-5e: dropped: legal_name, tier, industry_tags(array). See createParty notes.
  const updates: Record<string, unknown> = {
    party_name: parsed.data.name.trim(),
    party_type_id: partyTypeId,
    entity_type_id: entityTypeId,
    country_code: parsed.data.countryCode || null,
    region: parsed.data.region?.trim() || null,
    city: parsed.data.city?.trim() || null,
    website: parsed.data.website || null,
    interest_tags: parsed.data.interestTags ?? [],
    source: parsed.data.source?.trim() || null,
    notes: parsed.data.notes?.trim() || null,
    updated_by: auth.userId,
  };

  const { error, data } = await supabase
    .schema('app')
    .from('parties' as never)
    .update(updates as never)
    .eq('id', parsed.data.partyId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error) {
    console.error('[parties.updateParty] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) {
    return { ok: false, errorCode: 'not_found' };
  }

  // D6-5e: use input party_type code for revalidation (was reading removed DB col).
  revalidatePath(`/${parsed.data.partyType}/parties/${parsed.data.partyId}`);
  revalidatePath(`/${parsed.data.partyType}/parties`);
  return { ok: true, partyId: parsed.data.partyId };
}

const deleteSchema = z.object({
  partyId: z.string().uuid(),
});

export async function deleteParty(input: { partyId: string }): Promise<PartyActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = deleteSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('parties' as never)
    .update({
      deleted_at: new Date().toISOString(),
    } as never)
    .eq('id', parsed.data.partyId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('party_type_id, party_types(code)')
    .maybeSingle();

  if (error) {
    console.error('[parties.deleteParty] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };

  // D6-5e: party_type column gone; resolve via party_types(code) FK join.
  const ptJoin = (data as { party_types?: { code?: string } | { code?: string }[] }).party_types;
  const partyType = (
    (Array.isArray(ptJoin) ? ptJoin[0]?.code : ptJoin?.code) ?? 'paper_mill'
  ) as PartyType;

  revalidatePath(`/${partyType}/parties`);
  redirect(`/${partyType}/parties`);
}
