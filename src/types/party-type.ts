/**
 * types/party-type.ts
 *
 * 두 차원의 party 분류:
 *
 *   PartyType  - 비즈니스 카테고리 (urm.party_types 기반)
 *     investor, paper_mill, filler_supplier, buyer, customer, partner, government_grant
 *
 *   PartyKind  - 법인 형태 (app.party_kind enum 기반)
 *     company, organization, individual, fund, government
 *
 * Naming policy (2026-05-25 Phase C):
 *   - TS type 이름: PartyType, PartyKind (PascalCase)
 *   - TS property / variable / form field: partyType, partyKind (camelCase, React/Next.js 컨벤션)
 *   - DB column: party_type, party_kind (snake_case)
 *
 * Source of truth:
 *   - urm.party_types (7 rows) ← PartyType
 *   - app.party_kind enum (5 values) ← PartyKind
 */

// ============================================================
// PartyType - 비즈니스 카테고리
// ============================================================

export type PartyType =
  | 'investor'
  | 'paper_mill'
  | 'filler_supplier'
  | 'buyer'
  | 'customer'
  | 'partner'
  | 'government_grant';

/** Legacy alias. 새 코드는 PartyType 직접 사용. */
export type PartyTypeCode = PartyType;

/** 전체 PartyType 배열. */
export const PARTY_TYPES: readonly PartyType[] = [
  'investor',
  'paper_mill',
  'filler_supplier',
  'buyer',
  'customer',
  'partner',
  'government_grant',
] as const;

/** Legacy alias. */
export const PARTY_TYPE_CODES: readonly PartyType[] = PARTY_TYPES;

/**
 * urm.party_types.id (smallint) ↔ code 매핑.
 */
export const PARTY_TYPE_ID_BY_CODE: Record<PartyType, number> = {
  investor: 1,
  paper_mill: 2,
  filler_supplier: 3,
  buyer: 4,
  customer: 5,
  partner: 6,
  government_grant: 7,
};

export const PARTY_TYPE_CODE_BY_ID: Record<number, PartyType> = {
  1: 'investor',
  2: 'paper_mill',
  3: 'filler_supplier',
  4: 'buyer',
  5: 'customer',
  6: 'partner',
  7: 'government_grant',
};

/** 다국어 표시명. */
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
};

/** Type guard. */
export function isPartyType(v: unknown): v is PartyType {
  return typeof v === 'string' && PARTY_TYPES.includes(v as PartyType);
}

export const isPartyTypeCode = isPartyType;

// ============================================================
// PartyKind - 법인 형태
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
