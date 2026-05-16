// src/lib/party/tier-cascade.ts
// Phase 7-b-1: parent_party_id 기반 tier 자동 계산
// party_level DB constraint: 'group_hq' | 'country_entity' | 'plant'

// ──────────────────────────────────────────────
// 타입
// ──────────────────────────────────────────────
export type TierLevel = 'tier_1' | 'tier_2' | 'tier_3' | 'tier_4' | 'tier_5'

export type TierRole =
  | 'HQ'
  | 'Regional_HQ'
  | 'Country_HQ'
  | 'Country'
  | 'Subsidiary'
  | 'JV'
  | 'Associate'
  | 'Branch'

/** DB constraint 허용값 (parties_party_level_check) */
export type PartyLevel = 'group_hq' | 'country_entity' | 'plant'

// ──────────────────────────────────────────────
// tier cascade
// ──────────────────────────────────────────────

/** parent tier → child tier 자동 계산 */
export function cascadeTier(parentTier: TierLevel | null | undefined): TierLevel {
  if (!parentTier) return 'tier_1'
  const map: Record<TierLevel, TierLevel> = {
    tier_1: 'tier_2',
    tier_2: 'tier_3',
    tier_3: 'tier_4',
    tier_4: 'tier_5',
    tier_5: 'tier_5',
  }
  return map[parentTier]
}

// ──────────────────────────────────────────────
// industry tier_role → app 매핑
// ──────────────────────────────────────────────

/** industry.tier_role → app.tier_level */
export function tierRoleToLevel(role: TierRole): TierLevel {
  const map: Record<TierRole, TierLevel> = {
    HQ:          'tier_1',
    Regional_HQ: 'tier_2',
    Country_HQ:  'tier_2',
    Country:     'tier_3',
    Subsidiary:  'tier_3',
    JV:          'tier_3',
    Associate:   'tier_4',
    Branch:      'tier_4',
  }
  return map[role] ?? 'tier_3'
}

/**
 * industry.tier_role → app.parties.party_level
 * DB constraint: 'group_hq' | 'country_entity' | 'plant'
 *
 *   HQ / Regional_HQ / Country_HQ  → group_hq
 *   Country / Subsidiary / JV /
 *   Associate / Branch              → country_entity
 */
export function tierRoleToPartyLevel(role: TierRole): PartyLevel {
  const map: Record<TierRole, PartyLevel> = {
    HQ:          'group_hq',
    Regional_HQ: 'group_hq',
    Country_HQ:  'group_hq',
    Country:     'country_entity',
    Subsidiary:  'country_entity',
    JV:          'country_entity',
    Associate:   'country_entity',
    Branch:      'country_entity',
  }
  return map[role] ?? 'country_entity'
}

/**
 * 부모 party_level 기반으로 자식 party_level 추론
 *   group_hq       → country_entity
 *   country_entity → plant
 *   plant          → plant  (더 이상 내려가지 않음)
 */
export function deriveChildPartyLevel(
  parentLevel: string | null | undefined,
): PartyLevel {
  if (parentLevel === 'group_hq') return 'country_entity'
  if (parentLevel === 'country_entity') return 'plant'
  return 'plant'
}

// ──────────────────────────────────────────────
// 표시용 레이블
// ──────────────────────────────────────────────

export function partyLevelLabel(level: string | null | undefined): string {
  const map: Record<string, string> = {
    group_hq:       'Group / HQ',
    country_entity: 'Country Entity',
    plant:          'Plant / Mill',
  }
  return map[level ?? ''] ?? level ?? '—'
}

export function tierLevelLabel(tier: TierLevel): string {
  const map: Record<TierLevel, string> = {
    tier_1: 'Tier 1',
    tier_2: 'Tier 2',
    tier_3: 'Tier 3',
    tier_4: 'Tier 4',
    tier_5: 'Tier 5',
  }
  return map[tier] ?? tier
}
