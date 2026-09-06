/**
 * types/party-type.ts
 *
 * Two dimensions of party classification:
 *
 *   PartyType  - business category (based on urm.party_types)
 *     investor, paper_mill, filler_supplier, buyer, customer, partner, government_grant
 *
 *   PartyKind  - legal entity form (based on the app.party_kind enum)
 *     company, organization, individual, fund, government
 *
 * Naming policy (2026-05-25 Phase C):
 *   - TS type names: PartyType, PartyKind (PascalCase)
 *   - TS property / variable / form field: partyType, partyKind (camelCase, React/Next.js convention)
 *   - DB column: party_type, party_kind (snake_case)
 *
 * Source of truth:
 *   - urm.party_types (7 rows) ← PartyType
 *   - app.party_kind enum (5 values) ← PartyKind
 */

// ============================================================
// PartyType - business category
// ============================================================

export type PartyType =
  | 'investor'
  | 'paper_mill'
  | 'filler_supplier'
  | 'buyer'
  | 'customer'
  | 'partner'
  | 'government_grant'
  | 'consultant'
  | 'crowdfunding_platform'
  | 'mentor'
  | 'self';

/** Legacy alias. New code uses PartyType directly. */
export type PartyTypeCode = PartyType;

/** Array of all PartyType values. */
export const PARTY_TYPES: readonly PartyType[] = [
  'investor',
  'paper_mill',
  'filler_supplier',
  'buyer',
  'customer',
  'partner',
  'government_grant',
  'consultant',
  'crowdfunding_platform',
  'mentor',
  'self',
] as const;

/** Legacy alias. */
export const PARTY_TYPE_CODES: readonly PartyType[] = PARTY_TYPES;

/**
 * party_type id <-> code mapping is NO LONGER hardcoded here. It is read from
 * app.party_types at runtime (and cached) via `fetchPartyTypeMaps()` in
 * lib/party-type-maps.ts, so adding a party_type in the database needs no code
 * change. The old PARTY_TYPE_ID_BY_CODE / PARTY_TYPE_CODE_BY_ID constants were
 * removed to prevent the id drift that broke new types (e.g. 'mentor').
 */

/** Localized display names. */
export const PARTY_TYPE_DISPLAY: Record<
  PartyType,
  { en: string; ko: string; ja: string }
> = {
  investor: { en: 'Investor', ko: '투자자', ja: '投資家' },
  paper_mill: { en: 'Paper Mill', ko: '제지사', ja: '製紙会社' },
  filler_supplier: {
    en: 'Filler Supplier',
    ko: '광물공급사',
    ja: 'フィラーサプライヤー',
  },
  buyer: { en: 'Buyer', ko: '구매사', ja: '購買会社' },
  customer: { en: 'Customer', ko: '고객사', ja: '顧客' },
  partner: { en: 'Partner', ko: '협력사', ja: 'パートナー' },
  government_grant: {
    en: 'Government Grant',
    ko: '정부지원',
    ja: '政府補助',
  },
  consultant: { en: 'Consultant', ko: '컨설턴트', ja: 'コンサルタント' },
  crowdfunding_platform: {
    en: 'Crowdfunding Platform',
    ko: '크라우드 펀딩 운영사',
    ja: 'クラウドファンディング運営会社',
  },
  self: { en: 'MarineBio Group', ko: '자사', ja: '自社' },
  mentor: { en: 'Mentor', ko: '멘토', ja: 'メンター' },
};

/** Type guard. */
export function isPartyType(v: unknown): v is PartyType {
  return typeof v === 'string' && PARTY_TYPES.includes(v as PartyType);
}

export const isPartyTypeCode = isPartyType;

// ============================================================
// PartyKind - legal entity form
// ============================================================

export type PartyKind =
  | 'company'
  | 'organization'
  | 'individual'
  | 'fund'
  | 'government';

export const PARTY_KINDS: readonly PartyKind[] = [
  'company',
  'organization',
  'individual',
  'fund',
  'government',
] as const;

export const PARTY_KIND_DISPLAY: Record<
  PartyKind,
  { en: string; ko: string; ja: string }
> = {
  company: { en: 'Company', ko: '회사', ja: '会社' },
  organization: { en: 'Organization', ko: '단체', ja: '団体' },
  individual: { en: 'Individual', ko: '개인', ja: '個人' },
  fund: { en: 'Fund', ko: '펀드', ja: 'ファンド' },
  government: { en: 'Government', ko: '정부', ja: '政府' },
};

export function isPartyKind(v: unknown): v is PartyKind {
  return typeof v === 'string' && PARTY_KINDS.includes(v as PartyKind);
}
