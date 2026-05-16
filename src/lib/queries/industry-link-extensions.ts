// src/lib/queries/industry-link-extensions.ts
// v5.8 Step B2/B3 — 영업용 cross-country 컨텍스트 query
//
// 추가된 함수 2개:
//   - getCountryFillerSuppliers(marketCode): 같은 국가의 filler supplier 리스트
//   - getCountryPaperMills(marketCode): 같은 국가의 paper mill 리스트
//
// 활용:
//   - Paper Mill detail에서 "같은 국가 공급사 후보" 표시
//   - Filler Supplier detail에서 "같은 국가 잠재 고객" 표시
//   - Paper Company detail에서 "같은 국가 공급사 후보" 표시 (옵션)
//
// 주의: 이 파일은 industry-link.ts에 추가하거나 별도 파일로 두 어느 쪽이든 가능.
//       권장: industry-link.ts 마지막에 append (single import source).

import { createSupabaseServerClient } from '@/lib/supabase/server'

/* ============================================================
 * Country Filler Suppliers (paper mill detail에서 사용)
 * ============================================================ */

export interface CountryFillerSupplierRow {
  id: number
  name: string
  marketCode: string | null
  supplierType: string | null
  marketRole: string | null
  relevantFillerTypes: string[]
  supplyModel: string | null
  evidenceLevel: string | null
  /** 이 supplier가 해당 paper mill과 이미 거래 중인지 여부 (UI에 "거래 중" 라벨) */
  hasExistingLinkage: boolean
}

/**
 * 같은 국가의 filler suppliers 리스트.
 *
 * @param marketCode - paper mill의 market_code (예: 'germany', 'finland')
 * @param excludeFromMillId - 옵션: 이 mill과 이미 매핑된 supplier 표시 위한 reference
 *                            (제외하지 않고 hasExistingLinkage 플래그만 설정)
 */
export async function getCountryFillerSuppliers(
  marketCode: string,
  paperMillId?: number,
): Promise<CountryFillerSupplierRow[]> {
  const supabase = await createSupabaseServerClient()

  // 1) 해당 국가의 filler suppliers fetch
  const { data: suppliersRaw, error } = await supabase
    .schema('industry' as never)
    .from('filler_suppliers')
    .select(
      'id, name, market_code, supplier_type, market_role, relevant_filler_types, supply_model, evidence_level',
    )
    .eq('market_code', marketCode)
    .order('id', { ascending: true })

  if (error) {
    console.error(
      '[industry-link-extensions.getCountryFillerSuppliers] supplier fetch:',
      error,
    )
    return []
  }

  const suppliers = (suppliersRaw ?? []) as Array<{
    id: number
    name: string
    market_code: string | null
    supplier_type: string | null
    market_role: string | null
    relevant_filler_types: string[] | null
    supply_model: string | null
    evidence_level: string | null
  }>

  if (suppliers.length === 0) return []

  // 2) (옵션) 이 mill과 이미 매핑된 supplier id set 조회
  let existingSupplierIds = new Set<number>()
  if (paperMillId) {
    const { data: linkagesRaw } = await supabase
      .schema('industry' as never)
      .from('supplier_mill_linkages')
      .select('filler_supplier_id')
      .eq('paper_mill_id', paperMillId)

    existingSupplierIds = new Set(
      ((linkagesRaw ?? []) as Array<{ filler_supplier_id: number | null }>)
        .map((l) => l.filler_supplier_id)
        .filter((v): v is number => v != null),
    )
  }

  return suppliers.map((s) => ({
    id: s.id,
    name: s.name,
    marketCode: s.market_code,
    supplierType: s.supplier_type,
    marketRole: s.market_role,
    relevantFillerTypes: s.relevant_filler_types ?? [],
    supplyModel: s.supply_model,
    evidenceLevel: s.evidence_level,
    hasExistingLinkage: existingSupplierIds.has(s.id),
  }))
}

/* ============================================================
 * Country Paper Mills (filler supplier detail에서 사용)
 * ============================================================ */

export interface CountryPaperMillRow {
  id: number
  millName: string
  city: string | null
  marketCode: string | null
  paperCompanyId: number | null
  paperCompanyName: string | null
  mainProductCategory: string | null
  mainProducts: string | null
  /** 이 mill이 해당 filler supplier와 이미 거래 중인지 여부 */
  hasExistingLinkage: boolean
  /** mill의 likely_filler_types — 영업 후보 추천 강도 */
  likelyFillerTypes: string[]
}

/**
 * 같은 국가의 paper mills 리스트 (잠재 고객).
 *
 * @param marketCode - filler supplier의 market_code
 * @param fillerSupplierId - 옵션: 이 supplier와 매핑 여부 확인
 */
export async function getCountryPaperMills(
  marketCode: string,
  fillerSupplierId?: number,
): Promise<CountryPaperMillRow[]> {
  const supabase = await createSupabaseServerClient()

  // 1) 해당 국가의 paper mills fetch
  const { data: millsRaw, error } = await supabase
    .schema('industry' as never)
    .from('paper_mills')
    .select(
      'id, mill_name, market_code, city, paper_company_id, main_product_category, main_products, likely_filler_types',
    )
    .eq('market_code', marketCode)
    .order('id', { ascending: true })

  if (error) {
    console.error(
      '[industry-link-extensions.getCountryPaperMills] mill fetch:',
      error,
    )
    return []
  }

  const mills = (millsRaw ?? []) as Array<{
    id: number
    mill_name: string
    market_code: string | null
    city: string | null
    paper_company_id: number | null
    main_product_category: string | null
    main_products: string | null
    likely_filler_types: string[] | null
  }>

  if (mills.length === 0) return []

  // 2) paper_company 이름 lookup
  const companyIds = Array.from(
    new Set(
      mills.map((m) => m.paper_company_id).filter((v): v is number => v != null),
    ),
  )

  const companyMap = new Map<number, string>()
  if (companyIds.length > 0) {
    const { data: companyRaw } = await supabase
      .schema('industry' as never)
      .from('paper_companies')
      .select('id, name')
      .in('id', companyIds)

    for (const c of (companyRaw ?? []) as Array<{ id: number; name: string }>) {
      companyMap.set(c.id, c.name)
    }
  }

  // 3) (옵션) 이 supplier와 이미 매핑된 mill id set
  let existingMillIds = new Set<number>()
  if (fillerSupplierId) {
    const { data: linkagesRaw } = await supabase
      .schema('industry' as never)
      .from('supplier_mill_linkages')
      .select('paper_mill_id')
      .eq('filler_supplier_id', fillerSupplierId)

    existingMillIds = new Set(
      ((linkagesRaw ?? []) as Array<{ paper_mill_id: number | null }>)
        .map((l) => l.paper_mill_id)
        .filter((v): v is number => v != null),
    )
  }

  return mills.map((m) => ({
    id: m.id,
    millName: m.mill_name,
    city: m.city,
    marketCode: m.market_code,
    paperCompanyId: m.paper_company_id,
    paperCompanyName:
      m.paper_company_id != null ? companyMap.get(m.paper_company_id) ?? null : null,
    mainProductCategory: m.main_product_category,
    mainProducts: m.main_products,
    hasExistingLinkage: existingMillIds.has(m.id),
    likelyFillerTypes: m.likely_filler_types ?? [],
  }))
}
