// src/lib/party/tier-cascade.ts
// Phase 7-b-1: auto-compute tier based on parent_party_id
// party_level DB constraint: 'group_hq' | 'country_entity' | 'plant'

// ──────────────────────────────────────────────
// Types
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

/** values allowed by the DB constraint (parties_party_level_check) */
export type PartyLevel = 'group_hq' | 'country_entity' | 'plant'

// ──────────────────────────────────────────────
// tier cascade
// ──────────────────────────────────────────────

/** auto-compute parent tier -> child tier */
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
// industry tier_role -> app mapping
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
 * Infer the child party_level based on the parent party_level
 *   group_hq       → country_entity
 *   country_entity → plant
 *   plant          -> plant  (goes no lower)
 */
export function deriveChildPartyLevel(
  parentLevel: string | null | undefined,
): PartyLevel {
  if (parentLevel === 'group_hq') return 'country_entity'
  if (parentLevel === 'country_entity') return 'plant'
  return 'plant'
}

// ──────────────────────────────────────────────
// display labels
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
