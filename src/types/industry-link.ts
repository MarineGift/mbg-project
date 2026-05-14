/**
 * types/industry-link.ts
 *
 * Phase 6 — Industry master DB와 연결된 거래처 detail 섹션 도메인 타입.
 *
 * industry 스키마의 정규화된 raw row를 UI 표시용 camelCase로 변환한 결과.
 * V11.4 평가 체계(Mill-Specific vs Supplier Footprint)와 mill 단위 likely_* 메타
 * (unmatched mill의 fallback intel)를 1급 시민으로 노출.
 *
 * 참고: industry 스키마는 flat columns만 사용 (jsonb module_data 없음).
 */

export type EvidenceLevel = 'A' | 'B' | 'C';
export type ConfidenceGrade = 'A' | 'B' | 'C';
export type AssessmentScope = 'Mill-Specific' | 'Supplier Footprint';

/* ============================================================
 * Paper Company 측 (buyer module)
 * ============================================================ */

export interface IndustryPaperCompanySummary {
  id: number;
  name: string;
  marketCode: string | null;
  sourceUrl: string | null;
  evidenceLevel: EvidenceLevel | null;
  /** 'High' | 'Medium' | 'Low' 등 자유 텍스트 */
  fillerUseIntensity: string | null;
  knownFillerTypes: string[];
  /** 회사 차원의 paper grade */
  mainProductCategory: string | null;
  mainProducts: string | null;
  headquarters: string | null;
  /** 유럽 mill 분포 텍스트 — V11.4 footprint hint */
  europeMillsFootprint: string | null;
  /** "supply structure" 메모 (Tolling/Onsite/Toll-manufacturer 등) */
  supplyStructureNote: string | null;
  notes: string | null;
}

export interface IndustryMillRow {
  id: number;
  millName: string;
  city: string | null;
  region: string | null;
  marketCode: string | null;
  mainProductCategory: string | null;
  mainProducts: string | null;
  /** confidence 같은 게 아닌, "이 mill이 filler를 쓸 확률" 메모 */
  fillerProbability: string | null;
  /** likely supplier 추측 (linkage 매칭 안 된 mill의 fallback) */
  likelyFillerTypes: string[];
  likelySupplyStructure: string | null;
  likelySupplierNote: string | null;
  /** 확정된 supplier 매트릭스 (supplier_mill_linkages 기반) */
  suppliers: Array<{
    fillerSupplierId: number | null;
    supplierName: string;
    fillerType: string | null;
    supplyStructure: string | null;
    relationshipType: string | null;
    confidenceGrade: ConfidenceGrade | null;
  }>;
}

/** Supplier 단위 aggregation — "이 회사에 가장 많이 들어가는 공급사 순" */
export interface PaperCompanySupplierSummaryRow {
  fillerSupplierId: number | null;
  supplierName: string;
  millCount: number;
  /** 같은 supplier의 mill별 confidence 중 최고 등급 (A > B > C) */
  topConfidence: ConfidenceGrade | null;
}

export interface PaperCompanyIntel {
  company: IndustryPaperCompanySummary;
  mills: IndustryMillRow[];
  supplierSummary: PaperCompanySupplierSummaryRow[];
  stats: {
    totalMills: number;
    /** 1개 이상의 확정 supplier가 매핑된 mill 수 */
    millsWithSuppliers: number;
    /** unique 공급사 수 (mill 횟수 무관) */
    totalSupplierCount: number;
    /** likely_filler_types만 있고 확정 supplier가 없는 mill 수 — 영업 우선순위 */
    millsWithLikelyOnly: number;
  };
}

/* ============================================================
 * Filler Supplier 측 (filler module)
 * ============================================================ */

export interface IndustryFillerSupplierSummary {
  id: number;
  name: string;
  marketCode: string | null;
  sourceUrl: string | null;
  evidenceLevel: EvidenceLevel | null;
  /** 'GCC' | 'PCC' | 'Kaolin' | 'Multi-mineral' 등 */
  supplierType: string | null;
  /** 'Global major' | 'Regional' | 'Niche' 등 */
  marketRole: string | null;
  /** 'Tolling' | 'Direct' 등 (자유 텍스트) */
  supplyModel: string | null;
  /** 공급 가능한 filler 종류 (V11.4) */
  relevantFillerTypes: string[];
  europePaperEvidence: string | null;
  onsitePccEvidence: string | null;
  notes: string | null;
}

export interface FillerLinkageRow {
  /** supplier_mill_linkages.id를 string으로 정규화 */
  id: string;
  paperCompanyId: number | null;
  /** FK 매핑 우선, 없으면 raw name fallback */
  paperCompanyName: string;
  paperMillId: number | null;
  /** FK 매핑 우선 → mill_site_raw → null */
  millName: string | null;
  marketCode: string | null;
  countryRegion: string | null;
  fillerType: string | null;
  supplyStructure: string | null;
  relationshipType: string | null;
  confidenceGrade: ConfidenceGrade | null;
  /** V11.4 평가 범위 */
  assessmentScope: AssessmentScope;
  /** 'Confirmed' | 'Probable' | 'Unconfirmed' 등 */
  confirmationStatus: string | null;
}

export interface FillerSupplierIntel {
  supplier: IndustryFillerSupplierSummary;
  /** assessment_scope = 'Mill-Specific' — plant 단위 확정 거래 */
  millSpecificLinks: FillerLinkageRow[];
  /** assessment_scope = 'Supplier Footprint' — 지역 단위만 확인 */
  footprintLinks: FillerLinkageRow[];
  stats: {
    totalLinks: number;
    millSpecificCount: number;
    footprintCount: number;
    /** 거래 중인 unique paper company 수 (raw name 포함) */
    uniquePaperCompanies: number;
    /** Mill-Specific 한정 unique mill 수 */
    uniqueMills: number;
  };
}
