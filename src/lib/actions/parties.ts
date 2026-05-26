/**
 * lib/actions/parties.ts
 *
 * Party Server Actions — 생성, 수정, 삭제.
 *
 * 삭제는 soft delete (deleted_at = now()). 트리거가 audit log 자동.
 *
 * 변경 이력:
 *   - 2026-05-11: industry 컬럼 제거, industry_tags / interest_tags 배열만 사용.
 *   - 2026-05-12: deleteParty에서 미존재 deleted_by 컬럼 참조 제거.
 *   - 2026-05-25 (Phase C): module → party_type, party_type → party_kind rename.
 *                 TS schema 는 camelCase (partyType, partyKind), DB column 은 snake_case.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { PartyType } from '@/types/party-type';

export interface PartyActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'not_found' | 'database';
  errorMessage?: string;
  /** create 성공 시 새 party id */
  partyId?: string;
}

const partySchema = z.object({
  name: z.string().min(1, 'Name is required').max(200),
  legalName: z.string().max(200).optional().nullable(),
  // 비즈니스 카테고리
  partyType: z.enum([
    'investor',
    'paper_mill',
    'filler_supplier',
    'buyer',
    'customer',
    'partner',
    'government_grant',
  ]),
  // 법인 형태
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
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    name: parsed.data.name.trim(),
    legal_name: parsed.data.legalName?.trim() || null,
    party_type: parsed.data.partyType,
    party_kind: parsed.data.partyKind,
    tier: parsed.data.tier ?? 'tier_3',
    country_code: parsed.data.countryCode || null,
    region: parsed.data.region?.trim() || null,
    city: parsed.data.city?.trim() || null,
    website: parsed.data.website || null,
    industry_tags: parsed.data.industryTags ?? [],
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
  const updates: Record<string, unknown> = {
    name: parsed.data.name.trim(),
    legal_name: parsed.data.legalName?.trim() || null,
    party_type: parsed.data.partyType,
    party_kind: parsed.data.partyKind,
    tier: parsed.data.tier ?? 'tier_3',
    country_code: parsed.data.countryCode || null,
    region: parsed.data.region?.trim() || null,
    city: parsed.data.city?.trim() || null,
    website: parsed.data.website || null,
    industry_tags: parsed.data.industryTags ?? [],
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
    .select('id, party_type')
    .maybeSingle();

  if (error) {
    console.error('[parties.updateParty] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) {
    return { ok: false, errorCode: 'not_found' };
  }
  const updated = data as { id: string; party_type: PartyType };

  revalidatePath(`/${updated.party_type}/parties/${parsed.data.partyId}`);
  revalidatePath(`/${updated.party_type}/parties`);
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
    .select('party_type')
    .maybeSingle();

  if (error) {
    console.error('[parties.deleteParty] update error:', error);
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) return { ok: false, errorCode: 'not_found' };
  const partyType = (data as { party_type: PartyType }).party_type;

  revalidatePath(`/${partyType}/parties`);
  redirect(`/${partyType}/parties`);
}
