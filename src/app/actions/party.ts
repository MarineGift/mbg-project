'use server'
// src/app/actions/party.ts
// Phase 7-b: CRM party 생성 / tier cascade / mill & company promote

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import {
  cascadeTier,
  deriveChildPartyLevel,
  tierRoleToLevel,
  tierRoleToPartyLevel,
  TierLevel,
  TierRole,
  PartyLevel,
} from '@/lib/party/tier-cascade'

// ──────────────────────────────────────────────
// 상수
// ──────────────────────────────────────────────
const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169'

// ──────────────────────────────────────────────
// 타입
// ──────────────────────────────────────────────
export type PartyType = 'company' | 'organization' | 'individual' | 'fund' | 'government'

export interface CreatePartyInput {
  name: string
  legal_name?: string
  party_type?: PartyType
  module: string
  country_code?: string
  region?: string
  city?: string
  address?: string
  website?: string
  linkedin_url?: string
  notes?: string

  // 계층 관계
  parent_party_id?: string | null
  tier_role?: TierRole
  party_level?: PartyLevel          // DB 허용값만: 'group_hq' | 'country_entity' | 'plant'

  // industry DB 연결
  industry_paper_company_id?: number | null
  industry_paper_mill_id?: number | null
  industry_filler_supplier_id?: number | null
}

// ──────────────────────────────────────────────
// createParty
// ──────────────────────────────────────────────
export async function createParty(input: CreatePartyInput) {
  const supabase = await createSupabaseServerClient()

  // tier / party_level 결정 우선순위:
  //   1. tier_role 직접 지정
  //   2. parent_party_id cascade
  //   3. 기본값 (tier_1 / group_hq)
  let tier: TierLevel = 'tier_1'
  let party_level: PartyLevel = input.party_level ?? 'group_hq'

  if (input.tier_role) {
    tier = tierRoleToLevel(input.tier_role)
    party_level = input.party_level ?? tierRoleToPartyLevel(input.tier_role)
  } else if (input.parent_party_id) {
    const { data: parent } = await supabase
      .schema('app')
      .from('parties')
      .select('tier, party_level')
      .eq('id', input.parent_party_id)
      .single()

    if (parent) {
      const p = parent as { tier: string; party_level: string }
      tier = cascadeTier(p.tier as TierLevel)
      party_level = input.party_level ?? deriveChildPartyLevel(p.party_level)
    }
  }

  const { data, error } = await supabase
    .schema('app')
    .from('parties')
    .insert({
      organization_id:             ORG_ID,
      name:                        input.name,
      legal_name:                  input.legal_name ?? null,
      party_type:                  (input.party_type ?? 'partner') as never,
      module:                      input.module,
      country_code:                input.country_code ?? null,
      region:                      input.region ?? null,
      city:                        input.city ?? null,
      address:                     input.address ?? null,
      website:                     input.website ?? null,
      linkedin_url:                input.linkedin_url ?? null,
      notes:                       input.notes ?? null,
      parent_party_id:             input.parent_party_id ?? null,
      tier,
      party_level,
      industry_paper_company_id:   input.industry_paper_company_id ?? null,
      industry_paper_mill_id:      input.industry_paper_mill_id ?? null,
      industry_filler_supplier_id: input.industry_filler_supplier_id ?? null,
    })
    .select()
    .single()

  if (error) return { success: false as const, error: error.message }

  revalidatePath('/paper_mill')
  revalidatePath('/filler')
  return { success: true as const, data }
}

// ──────────────────────────────────────────────
// updateParty (tier cascade 포함)
// ──────────────────────────────────────────────
export async function updateParty(
  partyId: string,
  input: Partial<CreatePartyInput>,
) {
  const supabase = await createSupabaseServerClient()
  const updates: Record<string, unknown> = { ...input }

  if ('parent_party_id' in input) {
    if (input.parent_party_id) {
      const { data: parent } = await supabase
        .schema('app')
        .from('parties')
        .select('tier, party_level')
        .eq('id', input.parent_party_id)
        .single()

      if (parent) {
        const p = parent as { tier: string; party_level: string }
        updates.tier = cascadeTier(p.tier as TierLevel)
        updates.party_level = input.party_level ?? deriveChildPartyLevel(p.party_level)
      }
    } else {
      updates.tier = 'tier_1'
      updates.party_level = input.party_level ?? 'group_hq'
    }
  }

  const { data, error } = await supabase
    .schema('app')
    .from('parties')
    .update(updates)
    .eq('id', partyId)
    .select()
    .single()

  if (error) return { success: false as const, error: error.message }

  revalidatePath('/paper_mill')
  return { success: true as const, data }
}

// ──────────────────────────────────────────────
// promoteMillToParty  (Phase 7-b-2)
// industry.paper_mills → app.parties 승격
// ──────────────────────────────────────────────
export async function promoteMillToParty(millId: number) {
  const supabase = await createSupabaseServerClient()

  // 중복 확인
  const { data: existing } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name')
    .eq('industry_paper_mill_id' as never, millId)
    .maybeSingle()

  if (existing) {
    const e = existing as { id: string; name: string }
    return { success: false as const, error: 'already_promoted', party_id: e.id, party_name: e.name }
  }

  // industry.paper_mills 조회
  const { data: mill, error: millError } = await supabase
    .schema('industry' as never)
    .from('paper_mills')
    .select('id, mill_name, market_code, city, paper_company_id')
    .eq('id', millId)
    .single()

  if (millError || !mill) return { success: false as const, error: 'mill_not_found' }

  const m = mill as {
    id: number
    mill_name: string
    market_code: string | null
    city: string | null
    paper_company_id: number | null
  }

  // 상위 company party 탐색
  let parent_party_id: string | null = null
  let parent_tier: TierLevel | null = null

  if (m.paper_company_id) {
    const { data: parentParty } = await supabase
      .schema('app')
      .from('parties')
      .select('id, tier')
      .eq('industry_paper_company_id' as never, m.paper_company_id)
      .maybeSingle()

    if (parentParty) {
      const pp = parentParty as { id: string; tier: string }
      parent_party_id = pp.id
      parent_tier = pp.tier as TierLevel
    }
  }

  const tier: TierLevel = parent_tier ? cascadeTier(parent_tier) : 'tier_4'

  const { data: party, error } = await supabase
    .schema('app')
    .from('parties')
    .insert({
      organization_id:        ORG_ID,
      name:                   m.mill_name,
      party_type:             'paper_mill',
      module:                 'paper_mill',
      city:                   m.city ?? null,
      country_code:           null,       // market_code는 ISO 형식 아님
      parent_party_id,
      tier,
      party_level:            'plant' satisfies PartyLevel,
      industry_paper_mill_id: millId,
    })
    .select()
    .single()

  if (error) return { success: false as const, error: error.message }

  revalidatePath(`/industry/paper-mills/${millId}`)
  revalidatePath('/paper_mill')
  return { success: true as const, data: party as { id: string; name: string } }
}

// ──────────────────────────────────────────────
// promoteCompanyToParty  (Phase 7-b-2)
// industry.paper_companies → app.parties 승격
// ──────────────────────────────────────────────
export async function promoteCompanyToParty(companyId: number) {
  const supabase = await createSupabaseServerClient()

  // 중복 확인
  const { data: existing } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name')
    .eq('industry_paper_company_id' as never, companyId)
    .maybeSingle()

  if (existing) {
    const e = existing as { id: string; name: string }
    return { success: false as const, error: 'already_promoted', party_id: e.id, party_name: e.name }
  }

  // industry.paper_companies 조회
  const { data: company, error: companyError } = await supabase
    .schema('industry' as never)
    .from('paper_companies')
    .select('id, name, tier_role')
    .eq('id', companyId)
    .single()

  if (companyError || !company) return { success: false as const, error: 'company_not_found' }

  const c = company as { id: number; name: string; tier_role: string | null }

  const role = (c.tier_role ?? 'HQ') as TierRole
  const tier = tierRoleToLevel(role)
  const party_level = tierRoleToPartyLevel(role)

  const { data: party, error } = await supabase
    .schema('app')
    .from('parties')
    .insert({
      organization_id:           ORG_ID,
      name:                      c.name,
      party_type:                'paper_mill',
      module:                    'paper_mill',
      country_code:              null,
      tier,
      party_level,
      industry_paper_company_id: companyId,
    })
    .select()
    .single()

  if (error) return { success: false as const, error: error.message }

  revalidatePath(`/industry/paper-companies/${companyId}`)
  revalidatePath('/paper_mill')
  return { success: true as const, data: party as { id: string; name: string } }
}

// ──────────────────────────────────────────────
// 조회 헬퍼
// ──────────────────────────────────────────────
export async function getPartyByMillId(millId: number) {
  const supabase = await createSupabaseServerClient()
  const { data } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name, tier, party_level, status, parent_party_id')
    .eq('industry_paper_mill_id' as never, millId)
    .maybeSingle()
  return (data as { id: string; name: string; tier: string; party_level: string; status: string; parent_party_id: string | null } | null) ?? null
}

export async function getPartyByCompanyId(companyId: number) {
  const supabase = await createSupabaseServerClient()
  const { data } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name, tier, party_level, status, parent_party_id')
    .eq('industry_paper_company_id' as never, companyId)
    .maybeSingle()
  return (data as { id: string; name: string; tier: string; party_level: string; status: string; parent_party_id: string | null } | null) ?? null
}

export async function getChildParties(parentPartyId: string) {
  const supabase = await createSupabaseServerClient()
  const { data } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name, tier, party_level, party_type, country_code, status')
    .eq('parent_party_id', parentPartyId)
    .is('deleted_at', null)
    .order('name')
  return (data ?? []) as unknown as Array<{
    id: string
    name: string
    tier: string
    party_level: string
    module: string
    country_code: string | null
    status: string
  }>
}
