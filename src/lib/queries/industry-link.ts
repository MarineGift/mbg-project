/**
 * lib/queries/industry-link.ts
 *
 * Phase 6 — Industry master DB와 연결된 거래처의 상세 인텔리전스 fetch.
 *
 *   - getPaperCompanyIntel(id):
 *       paper company 메타 + 보유 mill 리스트 (likely_* fallback 포함)
 *       + 각 mill의 supplier 매트릭스 + supplier 단위 aggregation
 *
 *   - getFillerSupplierIntel(id):
 *       filler supplier 메타 + 공급 중인 mill 리스트 (Mill-Specific)
 *       + 지역만 확인된 footprint 리스트 (Supplier Footprint) 분리
 *
 * 설계 메모:
 *   - industry 스키마는 jsonb 없이 모두 flat columns. supplier_mill_linkages에
 *     paper_company_id, paper_mill_id가 nullable로 같이 있어 양방향 조회 가능.
 *   - Cross-schema FK 캐시 이슈 (queries/drafts.ts 참조)를 피하기 위해 nested
 *     join 대신 별도 쿼리 + JS merge 패턴. industry 내부 단일 스키마라 사실 nested
 *     join도 가능하지만, 일관성과 디버깅 용이성을 위해 동일 패턴 채택.
 *   - paper_mills의 likely_filler_types / likely_supplier_note 컬럼은 47% 매칭
 *     안 된 mill의 영업 fallback intel. 확정 supplier가 없어도 mill 행으로 표시.
 *
 * RLS: industry 스키마는 organization-agnostic 마스터 데이터이므로 RLS 검증 없음.
 *      호출자가 app.parties.industry_xxx_id를 통해 간접 검증.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type {
  AssessmentScope,
  ConfidenceGrade,
  EvidenceLevel,
  FillerLinkageRow,
  FillerSupplierIntel,
  IndustryFillerSupplierSummary,
  IndustryMillRow,
  IndustryPaperCompanySummary,
  PaperCompanyIntel,
  PaperCompanySupplierSummaryRow,
} from '@/types/industry-link';

/* ============================================================
 * Paper Company → Mills + Supplier Matrix
 * ============================================================ */

interface RawPaperCompanyRow {
  id: number;
  name: string;
  market_code: string | null;
  headquarters: string | null;
  europe_mills_footprint: string | null;
  main_product_category: string | null;
  main_products: string | null;
  filler_use_intensity: string | null;
  known_filler_types: string[] | null;
  supply_structure_note: string | null;
  evidence_level: string | null;
  source_url: string | null;
  notes: string | null;
}

interface RawPaperMillRow {
  id: number;
  paper_company_id: number;
  market_code: string | null;
  mill_name: string;
  city: string | null;
  region: string | null;
  main_product_category: string | null;
  main_products: string | null;
  filler_probability: string | null;
  likely_filler_types: string[] | null;
  likely_supply_structure: string | null;
  likely_supplier_note: string | null;
}

interface RawLinkageForPaperRow {
  id: number | string;
  paper_mill_id: number | null;
  filler_supplier_id: number | null;
  filler_type: string | null;
  supply_structure: string | null;
  relationship_type: string | null;
  confidence_grade: string | null;
  assessment_scope: string | null;
}

interface RawFillerSupplierLookupRow {
  id: number;
  name: string;
}

export async function getPaperCompanyIntel(
  paperCompanyId: number,
): Promise<PaperCompanyIntel | null> {
  const supabase = await createSupabaseServerClient();

  // ── [1] paper company 본체 ────────────────────────────────
  const { data: companyRaw, error: companyErr } = await supabase
    .schema('industry' as never)
    .from('paper_companies' as never)
    .select(
      'id, name, market_code, headquarters, europe_mills_footprint, main_product_category, main_products, filler_use_intensity, known_filler_types, supply_structure_note, evidence_level, source_url, notes',
    )
    .eq('id', paperCompanyId)
    .maybeSingle();

  if (companyErr || !companyRaw) {
    if (companyErr) {
      // eslint-disable-next-line no-console
      console.error('[industry-link.getPaperCompanyIntel] company fetch:', companyErr);
    }
    return null;
  }

  const company = mapPaperCompany(companyRaw as unknown as RawPaperCompanyRow);

  // ── [2] mills ─────────────────────────────────────────────
  const { data: millsRawData, error: millsErr } = await supabase
    .schema('industry' as never)
    .from('paper_mills' as never)
    .select(
      'id, paper_company_id, market_code, mill_name, city, region, main_product_category, main_products, filler_probability, likely_filler_types, likely_supply_structure, likely_supplier_note',
    )
    .eq('paper_company_id', paperCompanyId)
    .order('mill_name', { ascending: true });

  if (millsErr) {
    // eslint-disable-next-line no-console
    console.error('[industry-link.getPaperCompanyIntel] mills fetch:', millsErr);
  }

  const mills = (millsRawData ?? []) as unknown as RawPaperMillRow[];
  const millIds = mills.map((m) => m.id);

  // ── [3] Mill-Specific linkages (paper_mill_id IN [mills]) ─
  let linkages: RawLinkageForPaperRow[] = [];
  if (millIds.length > 0) {
    const { data: linkRaw, error: linkErr } = await supabase
      .schema('industry' as never)
      .from('supplier_mill_linkages' as never)
      .select(
        'id, paper_mill_id, filler_supplier_id, filler_type, supply_structure, relationship_type, confidence_grade, assessment_scope',
      )
      .in('paper_mill_id', millIds);

    if (linkErr) {
      // eslint-disable-next-line no-console
      console.error('[industry-link.getPaperCompanyIntel] linkages fetch:', linkErr);
    }
    linkages = (linkRaw ?? []) as unknown as RawLinkageForPaperRow[];
  }

  // ── [4] supplier 이름 lookup ──────────────────────────────
  const supplierIds = Array.from(
    new Set(
      linkages
        .map((l) => l.filler_supplier_id)
        .filter((v): v is number => v != null),
    ),
  );
  const supplierMap = new Map<number, string>();
  if (supplierIds.length > 0) {
    const { data: supplierRaw, error: supplierErr } = await supabase
      .schema('industry' as never)
      .from('filler_suppliers' as never)
      .select('id, name')
      .in('id', supplierIds);

    if (supplierErr) {
      // eslint-disable-next-line no-console
      console.error('[industry-link.getPaperCompanyIntel] supplier lookup:', supplierErr);
    }
    for (const s of (supplierRaw ?? []) as unknown as RawFillerSupplierLookupRow[]) {
      supplierMap.set(s.id, s.name);
    }
  }

  // ── [5] mill_id → linkages 매핑 ──────────────────────────
  const linkagesByMillId = new Map<number, RawLinkageForPaperRow[]>();
  for (const l of linkages) {
    if (l.paper_mill_id == null) continue;
    const arr = linkagesByMillId.get(l.paper_mill_id) ?? [];
    arr.push(l);
    linkagesByMillId.set(l.paper_mill_id, arr);
  }

  // ── [6] IndustryMillRow 매핑 ─────────────────────────────
  const millRows: IndustryMillRow[] = mills.map((m) => {
    const ls = linkagesByMillId.get(m.id) ?? [];
    return {
      id: m.id,
      millName: m.mill_name,
      city: m.city,
      region: m.region,
      marketCode: m.market_code,
      mainProductCategory: m.main_product_category,
      mainProducts: m.main_products,
      fillerProbability: m.filler_probability,
      likelyFillerTypes: m.likely_filler_types ?? [],
      likelySupplyStructure: m.likely_supply_structure,
      likelySupplierNote: m.likely_supplier_note,
      suppliers: ls.map((l) => ({
        fillerSupplierId: l.filler_supplier_id,
        supplierName:
          l.filler_supplier_id != null
            ? supplierMap.get(l.filler_supplier_id) ?? '(unknown supplier)'
            : '(unmatched)',
        fillerType: l.filler_type,
        supplyStructure: l.supply_structure,
        relationshipType: l.relationship_type,
        confidenceGrade: toConfidenceGrade(l.confidence_grade),
      })),
    };
  });

  // ── [7] supplier aggregation ─────────────────────────────
  // 같은 mill 내 동일 supplier 중복(예: GCC + PCC 라인)은 1회만 카운트
  const supplierAgg = new Map<
    number,
    { name: string; millCount: number; grades: ConfidenceGrade[] }
  >();
  for (const m of millRows) {
    const seenInThisMill = new Set<number>();
    for (const s of m.suppliers) {
      if (s.fillerSupplierId == null) continue;
      if (seenInThisMill.has(s.fillerSupplierId)) continue;
      seenInThisMill.add(s.fillerSupplierId);

      const existing = supplierAgg.get(s.fillerSupplierId);
      if (existing) {
        existing.millCount += 1;
        if (s.confidenceGrade) existing.grades.push(s.confidenceGrade);
      } else {
        supplierAgg.set(s.fillerSupplierId, {
          name: s.supplierName,
          millCount: 1,
          grades: s.confidenceGrade ? [s.confidenceGrade] : [],
        });
      }
    }
  }

  const supplierSummary: PaperCompanySupplierSummaryRow[] = Array.from(
    supplierAgg.entries(),
  )
    .map(([id, v]) => ({
      fillerSupplierId: id,
      supplierName: v.name,
      millCount: v.millCount,
      topConfidence: pickTopConfidence(v.grades),
    }))
    .sort(
      (a, b) =>
        b.millCount - a.millCount ||
        a.supplierName.localeCompare(b.supplierName),
    );

  // ── [8] stats ────────────────────────────────────────────
  const millsWithSuppliers = millRows.filter((m) => m.suppliers.length > 0).length;
  const millsWithLikelyOnly = millRows.filter(
    (m) => m.suppliers.length === 0 && m.likelyFillerTypes.length > 0,
  ).length;

  return {
    company,
    mills: millRows,
    supplierSummary,
    stats: {
      totalMills: millRows.length,
      millsWithSuppliers,
      totalSupplierCount: supplierAgg.size,
      millsWithLikelyOnly,
    },
  };
}

/* ============================================================
 * Filler Supplier → Mill linkages + Footprint
 * ============================================================ */

interface RawFillerSupplierRow {
  id: number;
  name: string;
  market_code: string | null;
  supplier_type: string | null;
  market_role: string | null;
  relevant_filler_types: string[] | null;
  supply_model: string | null;
  europe_paper_evidence: string | null;
  onsite_pcc_evidence: string | null;
  evidence_level: string | null;
  source_url: string | null;
  notes: string | null;
}

interface RawLinkageForFillerRow {
  id: number | string;
  paper_company_id: number | null;
  paper_company_name_raw: string | null;
  paper_mill_id: number | null;
  mill_site_raw: string | null;
  market_code: string | null;
  country_region: string | null;
  filler_type: string | null;
  supply_structure: string | null;
  relationship_type: string | null;
  confidence_grade: string | null;
  assessment_scope: string | null;
  confirmation_status: string | null;
}

interface RawPaperCompanyLookupRow {
  id: number;
  name: string;
}

interface RawPaperMillLookupRow {
  id: number;
  mill_name: string;
}

export async function getFillerSupplierIntel(
  fillerSupplierId: number,
): Promise<FillerSupplierIntel | null> {
  const supabase = await createSupabaseServerClient();

  // ── [1] filler supplier 본체 ──────────────────────────────
  const { data: supplierRaw, error: supplierErr } = await supabase
    .schema('industry' as never)
    .from('filler_suppliers' as never)
    .select(
      'id, name, market_code, supplier_type, market_role, relevant_filler_types, supply_model, europe_paper_evidence, onsite_pcc_evidence, evidence_level, source_url, notes',
    )
    .eq('id', fillerSupplierId)
    .maybeSingle();

  if (supplierErr || !supplierRaw) {
    if (supplierErr) {
      // eslint-disable-next-line no-console
      console.error(
        '[industry-link.getFillerSupplierIntel] supplier fetch:',
        supplierErr,
      );
    }
    return null;
  }

  const supplier = mapFillerSupplier(supplierRaw as unknown as RawFillerSupplierRow);

  // ── [2] 이 supplier의 모든 linkage ────────────────────────
  const { data: linkagesRaw, error: linkagesErr } = await supabase
    .schema('industry' as never)
    .from('supplier_mill_linkages' as never)
    .select(
      'id, paper_company_id, paper_company_name_raw, paper_mill_id, mill_site_raw, market_code, country_region, filler_type, supply_structure, relationship_type, confidence_grade, assessment_scope, confirmation_status',
    )
    .eq('filler_supplier_id', fillerSupplierId);

  if (linkagesErr) {
    // eslint-disable-next-line no-console
    console.error(
      '[industry-link.getFillerSupplierIntel] linkages fetch:',
      linkagesErr,
    );
  }

  const linkages = (linkagesRaw ?? []) as unknown as RawLinkageForFillerRow[];

  // ── [3] paper_company / paper_mill lookup (병렬) ─────────
  const paperCompanyIds = Array.from(
    new Set(
      linkages
        .map((l) => l.paper_company_id)
        .filter((v): v is number => v != null),
    ),
  );
  const paperMillIds = Array.from(
    new Set(
      linkages.map((l) => l.paper_mill_id).filter((v): v is number => v != null),
    ),
  );

  const [paperCompaniesRes, paperMillsRes] = await Promise.all([
    paperCompanyIds.length > 0
      ? supabase
          .schema('industry' as never)
          .from('paper_companies' as never)
          .select('id, name')
          .in('id', paperCompanyIds)
      : Promise.resolve({ data: [], error: null }),
    paperMillIds.length > 0
      ? supabase
          .schema('industry' as never)
          .from('paper_mills' as never)
          .select('id, mill_name')
          .in('id', paperMillIds)
      : Promise.resolve({ data: [], error: null }),
  ]);

  if (paperCompaniesRes.error) {
    // eslint-disable-next-line no-console
    console.error(
      '[industry-link.getFillerSupplierIntel] paper_companies lookup:',
      paperCompaniesRes.error,
    );
  }
  if (paperMillsRes.error) {
    // eslint-disable-next-line no-console
    console.error(
      '[industry-link.getFillerSupplierIntel] paper_mills lookup:',
      paperMillsRes.error,
    );
  }

  const companyMap = new Map<number, string>();
  for (const c of (paperCompaniesRes.data ?? []) as unknown as RawPaperCompanyLookupRow[]) {
    companyMap.set(c.id, c.name);
  }
  const millMap = new Map<number, string>();
  for (const m of (paperMillsRes.data ?? []) as unknown as RawPaperMillLookupRow[]) {
    millMap.set(m.id, m.mill_name);
  }

  // ── [4] scope별 분류 + FillerLinkageRow 매핑 ──────────────
  const millSpecific: FillerLinkageRow[] = [];
  const footprint: FillerLinkageRow[] = [];
  const seenPaperCompanies = new Set<string>();
  const seenMills = new Set<number>();

  for (const l of linkages) {
    const paperCompanyName =
      (l.paper_company_id != null ? companyMap.get(l.paper_company_id) : null) ??
      l.paper_company_name_raw ??
      '(unknown company)';

    const millName =
      (l.paper_mill_id != null ? millMap.get(l.paper_mill_id) : null) ??
      l.mill_site_raw ??
      null;

    const scope = toAssessmentScope(l.assessment_scope);

    const row: FillerLinkageRow = {
      id: String(l.id),
      paperCompanyId: l.paper_company_id,
      paperCompanyName,
      paperMillId: l.paper_mill_id,
      millName,
      marketCode: l.market_code,
      countryRegion: l.country_region,
      fillerType: l.filler_type,
      supplyStructure: l.supply_structure,
      relationshipType: l.relationship_type,
      confidenceGrade: toConfidenceGrade(l.confidence_grade),
      assessmentScope: scope,
      confirmationStatus: l.confirmation_status,
    };

    if (scope === 'Mill-Specific') {
      millSpecific.push(row);
    } else {
      footprint.push(row);
    }

    seenPaperCompanies.add(paperCompanyName.toLowerCase());
    if (l.paper_mill_id != null) seenMills.add(l.paper_mill_id);
  }

  // 정렬: mill-specific은 company → mill, footprint는 market → company
  millSpecific.sort((a, b) => {
    const c = a.paperCompanyName.localeCompare(b.paperCompanyName);
    if (c !== 0) return c;
    return (a.millName ?? '').localeCompare(b.millName ?? '');
  });
  footprint.sort((a, b) => {
    const c = (a.marketCode ?? '').localeCompare(b.marketCode ?? '');
    if (c !== 0) return c;
    return a.paperCompanyName.localeCompare(b.paperCompanyName);
  });

  return {
    supplier,
    millSpecificLinks: millSpecific,
    footprintLinks: footprint,
    stats: {
      totalLinks: linkages.length,
      millSpecificCount: millSpecific.length,
      footprintCount: footprint.length,
      uniquePaperCompanies: seenPaperCompanies.size,
      uniqueMills: seenMills.size,
    },
  };
}

/* ============================================================
 * 매퍼 / 유틸
 * ============================================================ */

function mapPaperCompany(r: RawPaperCompanyRow): IndustryPaperCompanySummary {
  return {
    id: r.id,
    name: r.name,
    marketCode: r.market_code,
    sourceUrl: r.source_url,
    evidenceLevel: toEvidenceLevel(r.evidence_level),
    fillerUseIntensity: r.filler_use_intensity,
    knownFillerTypes: r.known_filler_types ?? [],
    mainProductCategory: r.main_product_category,
    mainProducts: r.main_products,
    headquarters: r.headquarters,
    europeMillsFootprint: r.europe_mills_footprint,
    supplyStructureNote: r.supply_structure_note,
    notes: r.notes,
  };
}

function mapFillerSupplier(
  r: RawFillerSupplierRow,
): IndustryFillerSupplierSummary {
  return {
    id: r.id,
    name: r.name,
    marketCode: r.market_code,
    sourceUrl: r.source_url,
    evidenceLevel: toEvidenceLevel(r.evidence_level),
    supplierType: r.supplier_type,
    marketRole: r.market_role,
    supplyModel: r.supply_model,
    relevantFillerTypes: r.relevant_filler_types ?? [],
    europePaperEvidence: r.europe_paper_evidence,
    onsitePccEvidence: r.onsite_pcc_evidence,
    notes: r.notes,
  };
}

function toEvidenceLevel(v: string | null): EvidenceLevel | null {
  if (v === 'A' || v === 'B' || v === 'C') return v;
  return null;
}

function toConfidenceGrade(v: string | null): ConfidenceGrade | null {
  if (v === 'A' || v === 'B' || v === 'C') return v;
  return null;
}

function toAssessmentScope(v: string | null): AssessmentScope {
  // V11.4 enum. 알 수 없는 값은 Footprint로 안전 fallback
  return v === 'Mill-Specific' ? 'Mill-Specific' : 'Supplier Footprint';
}

/**
 * confidence 등급 배열에서 가장 높은 등급 반환 (A > B > C). 빈 배열은 null.
 */
function pickTopConfidence(grades: ConfidenceGrade[]): ConfidenceGrade | null {
  if (grades.length === 0) return null;
  if (grades.includes('A')) return 'A';
  if (grades.includes('B')) return 'B';
  return 'C';
}
