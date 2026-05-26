/**
 * party_type → party_type_id (FK) Migration Patterns
 *
 * 출처: handoff §6 #2, §A4 의 매핑 표
 * 작성: Stage 29-c (2026-05-24)
 *
 * 배경:
 *   V1: app.parties.party_type (enum) — "company" | "organization" | "individual" | "fund" | "government"
 *   V2: urm.parties.party_type_id (FK to urm.party_types) — 1..7
 *
 *   urm.party_types lookup:
 *     1 investor
 *     2 paper_mill
 *     3 filler_supplier
 *     4 buyer
 *     5 customer
 *     6 partner
 *     7 government_grant
 *
 * 핵심 변경:
 *   - app enum 값 ('company') 와 urm code ('investor') 가 1:1 매핑 안 됨
 *   - urm 측에서 "어떤 종류의 party 인지" 는 profile 테이블의 존재로 판별
 *   - caller 가 사용한 'company' 분류는 6 가지 sub-type (investor/paper_mill/filler_supplier/buyer/customer/partner) 중 하나로 정밀화됨
 *
 * 이 파일은 caller code 의 수동 변환 패턴을 예시로 제공.
 * 실제 코드 적용 시: audit script A4 결과의 매치 사이트 case-by-case 처리.
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database";

type SbUrm = SupabaseClient<Database, "urm">;
type SbApp = SupabaseClient<Database, "app">;

// =============================================================================
// §1. party_types lookup 상수 (한 번만 정의, caller 전역 사용)
// =============================================================================

/**
 * urm.party_types 의 7 코드. id 는 실제 DB row 확인 후 채울 것.
 *
 * 측정 SQL:
 *   SELECT id, code FROM urm.party_types ORDER BY id;
 */
export const PARTY_TYPE = {
  INVESTOR: 1,
  PAPER_MILL: 2,
  FILLER_SUPPLIER: 3,
  BUYER: 4,
  CUSTOMER: 5,
  PARTNER: 6,
  GOVERNMENT_GRANT: 7,
} as const;

export type PartyTypeCode =
  | "investor"
  | "paper_mill"
  | "filler_supplier"
  | "buyer"
  | "customer"
  | "partner"
  | "government_grant";

export const PARTY_TYPE_CODE_TO_ID: Record<PartyTypeCode, number> = {
  investor: PARTY_TYPE.INVESTOR,
  paper_mill: PARTY_TYPE.PAPER_MILL,
  filler_supplier: PARTY_TYPE.FILLER_SUPPLIER,
  buyer: PARTY_TYPE.BUYER,
  customer: PARTY_TYPE.CUSTOMER,
  partner: PARTY_TYPE.PARTNER,
  government_grant: PARTY_TYPE.GOVERNMENT_GRANT,
};

export const PARTY_TYPE_ID_TO_CODE: Record<number, PartyTypeCode> =
  Object.entries(PARTY_TYPE_CODE_TO_ID).reduce<Record<number, PartyTypeCode>>(
    (acc, [code, id]) => {
      acc[id] = code as PartyTypeCode;
      return acc;
    },
    {}
  );

// =============================================================================
// §2. 변환 패턴 (각 V1 → V2)
// =============================================================================

// -----------------------------------------------------------------------------
// 패턴 P1: .eq('party_type', '<enum>') 단일 filter
// -----------------------------------------------------------------------------

// V1:
//   const { data } = await sbApp
//     .from('parties')
//     .select('*')
//     .eq('party_type', 'company');

// V2 (urm):
async function p1_filter_by_type(sbUrm: SbUrm) {
  // 1. 단순 변환 (만약 'company' 가 다 investor 라면)
  const { data: investors } = await sbUrm
    .from("parties")
    .select("*")
    .eq("party_type_id", PARTY_TYPE.INVESTOR);

  // 2. 더 정확: profile 테이블 join 으로 "company 가 어느 sub-type 인지" 판별
  //    예) investor 만 추출
  const { data: investorsWithProfile } = await sbUrm
    .from("parties")
    .select("*, investor_profile!inner(*)")
    .order("name");

  // 3. 또는 여러 sub-type 한꺼번에 (만약 'company' 가 6 sub-type 모두 포함이라면)
  const { data: allCorporateParties } = await sbUrm
    .from("parties")
    .select("*")
    .in("party_type_id", [
      PARTY_TYPE.INVESTOR,
      PARTY_TYPE.PAPER_MILL,
      PARTY_TYPE.FILLER_SUPPLIER,
      PARTY_TYPE.BUYER,
      PARTY_TYPE.CUSTOMER,
      PARTY_TYPE.PARTNER,
    ]);

  return { investors, investorsWithProfile, allCorporateParties };
}

// -----------------------------------------------------------------------------
// 패턴 P2: .in('party_type', ['fund', 'individual']) — 매핑 없는 enum
// -----------------------------------------------------------------------------

// V1:
//   const { data } = await sbApp
//     .from('parties')
//     .select('*')
//     .in('party_type', ['fund', 'individual']);

// V2 (urm):
//   urm.party_types 에 fund / individual 부재.
//   - fund: ε hard-delete 완료 (0 row)
//   - individual: 모두 soft-deleted (urm 측 0 row)
//   → 이 query 자체가 빈 결과 반환. 코드 제거 후보.
//
//   만약 어쩔 수 없이 carry 해야 한다면 app.* 로 격리:
async function p2_dead_filter(sbApp: SbApp) {
  // Stage 29-d 까지의 app.* carry. soft-deleted 까지 포함 필요한 경우만.
  const { data } = await sbApp
    .from("parties")
    .select("*")
    .in("party_type", ["fund", "individual"]); // app enum (V1 carry)
  // 운영상 0~118 row (모두 soft-deleted)
  return data;
}

// -----------------------------------------------------------------------------
// 패턴 P3: object property 비교 (TS code, runtime check)
// -----------------------------------------------------------------------------

interface PartyV1 {
  party_type: "company" | "organization" | "individual" | "fund" | "government";
}

interface PartyV2 {
  party_type_id: number;
}

// V1:
//   if (party.party_type === 'fund') { ... }

// V2:
function p3_runtime_check_v2(party: PartyV2) {
  const code = PARTY_TYPE_ID_TO_CODE[party.party_type_id];
  if (code === "investor") {
    // investor 처리
  }
  // fund / individual / organization 는 V2 에 없음. 분기 자체 제거 가능.
}

// =============================================================================
// §3. select() 의 join 패턴 (party_types.code 함께 가져오기)
// =============================================================================

// V1:
//   const { data } = await sbApp.from('parties').select('id, name, party_type');
//   // data: { id, name, party_type: 'company' }[]

// V2 (PostgREST 의 nested select):
async function v2_select_with_type_code(sbUrm: SbUrm) {
  const { data } = await sbUrm
    .from("parties")
    .select(`
      id,
      name,
      party_type_id,
      party_type:party_types(code)
    `);
  // data 의 row 형태:
  //   { id, name, party_type_id: 1, party_type: { code: 'investor' } }

  // 만약 caller 가 flat 한 'party_type' 문자열을 원하면 매핑:
  const flat = data?.map((row) => ({
    id: row.id,
    name: row.name,
    party_type_id: row.party_type_id,
    party_type: PARTY_TYPE_ID_TO_CODE[row.party_type_id],
  }));

  return flat;
}

// =============================================================================
// §4. INSERT 패턴
// =============================================================================

// V1:
//   await sbApp.from('parties').insert({
//     name: 'Acme',
//     party_type: 'company',
//     module: 'investor',
//     organization_id: ORG_ID,
//   });

// V2 (urm — organization_id 없음, party_type_id 사용):
async function v2_insert(sbUrm: SbUrm) {
  await sbUrm.from("parties").insert({
    name: "Acme",
    party_type_id: PARTY_TYPE.INVESTOR, // 직접 ID
    // organization_id: 없음 (urm 은 single-tenant, handoff §8)
  } as Database["urm"]["Tables"]["parties"]["Insert"]);
}

// =============================================================================
// §5. UPDATE 패턴
// =============================================================================

// V1:
//   await sbApp.from('parties').update({ party_type: 'fund' }).eq('id', id);

// V2:
//   urm 에 'fund' 없음. update 자체 제거 또는 다른 sub-type 으로:
async function v2_update_avoid_fund(sbUrm: SbUrm, id: string) {
  // 잘못된 V1 패턴 ('fund' 로 변경) 은 V2 에서 의미 없음.
  // 만약 의도가 "다른 분류로 reclassify" 라면 명확히 6 sub-type 중 하나:
  await sbUrm
    .from("parties")
    .update({ party_type_id: PARTY_TYPE.PARTNER })
    .eq("id", id);
}

// =============================================================================
// §6. RPC 호출에서의 party_type
// =============================================================================

// V1 RPC 시그니처:
//   public.get_parties_by_type(p_party_type text)
//   → 내부에서 WHERE party_type = p_party_type::party_type_enum

// V2 RPC 시그니처 (DB 측 함수 V2 재작성 필요):
//   public.get_parties_by_type(p_party_type_id int)
//   또는
//   public.get_parties_by_type(p_party_type_code text)
//   → 내부에서 JOIN urm.party_types ON code = p_party_type_code

// caller 측:
async function v2_rpc(sbUrm: SbUrm) {
  // 만약 V2 RPC 가 code 받음
  const { data } = await sbUrm.rpc("get_parties_by_type", {
    p_party_type_code: "investor",
  } as never); // 타입 확정 후 as never 제거

  // 또는 id 받음
  const { data: data2 } = await sbUrm.rpc("get_parties_by_type", {
    p_party_type_id: PARTY_TYPE.INVESTOR,
  } as never);

  return { data, data2 };
}

// =============================================================================
// §7. helper functions (caller 가 자주 쓰는 분류 logic)
// =============================================================================

/** party 가 investor 인지 (urm 기반) */
export async function isInvestor(sbUrm: SbUrm, partyId: string): Promise<boolean> {
  const { data } = await sbUrm
    .from("investor_profile")
    .select("party_id")
    .eq("party_id", partyId)
    .maybeSingle();
  return !!data;
}

/** party 의 sub-type 코드 추출 (profile 테이블 join) */
export async function getPartyTypeCode(
  sbUrm: SbUrm,
  partyId: string
): Promise<PartyTypeCode | null> {
  const { data: party } = await sbUrm
    .from("parties")
    .select("party_type_id")
    .eq("id", partyId)
    .maybeSingle();
  if (!party) return null;
  return PARTY_TYPE_ID_TO_CODE[party.party_type_id] ?? null;
}

/** 사용자에게 표시할 party_type 한국어 라벨 */
export const PARTY_TYPE_DISPLAY_KO: Record<PartyTypeCode, string> = {
  investor: "투자자",
  paper_mill: "제지사",
  filler_supplier: "충전제 공급사",
  buyer: "구매자",
  customer: "고객",
  partner: "파트너",
  government_grant: "정부지원",
};
