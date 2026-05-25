/**
 * types/draft-queue.ts
 *
 * AI 초안 큐 목록 화면용 타입.
 *
 * DraftQueueRow는 ai.drafts + parties(name) + contacts(full_name) +
 * inbound communications(from_address, subject) 조인 결과를 평탄화한 형태.
 */

import type {
  ClassificationCategory,
  DraftStatus,
  Language,
  PartyTypeCode,
} from './ai';

/**
 * 큐 목록의 한 행. 큐 화면에서만 사용하는 좁은 SELECT 결과.
 */
export interface DraftQueueRow {
  id: string;
  status: DraftStatus;
  module: PartyTypeCode | null;
  classificationCategory: ClassificationCategory | null;
  confidenceScore: number | null;
  language: Language;
  subject: string | null;
  bodyPlainPreview: string;  // body_plain의 첫 120자
  riskFlags: string[];
  requiresHumanApproval: boolean;
  autoSendEligible: boolean;
  /** 사용자가 final_body_plain을 입력했는지 (편집 중 판단). 일괄 승인에서 제외. */
  hasEdits: boolean;
  expiresAt: string;  // ISO 8601
  createdAt: string;
  /** 거래처 정보 (null이면 미지정 — 첫 콜드 컨택 등) */
  partyId: string | null;
  partyName: string | null;
  /** 발신자 (party 없을 때 fallback) */
  fromAddress: string | null;
  /** 원본 inbound 메일 제목 */
  inboundSubject: string | null;
  /** 인게이지먼트 (있으면) */
  engagementId: string | null;
  engagementName: string | null;
}

/**
 * 큐 필터. URL query string으로 전달되어 Server Component에서 파싱.
 */
export interface DraftQueueFilters {
  /** 상태 — 기본 'pending_review'. 'all'은 모든 상태 */
  status: DraftStatus | 'all';
  module: PartyTypeCode | 'all';
  category: ClassificationCategory | 'all';
  /** 최소 신뢰도 (0~1). 0이면 필터 없음 */
  minConfidence: number;
  /** 위험 표시 있는 것만 */
  onlyRisky: boolean;
}

/**
 * 큐 정렬 옵션.
 */
export type DraftQueueSort =
  | 'urgent'           // confidence ASC, expires_at ASC (기본)
  | 'newest'           // created_at DESC
  | 'oldest'           // created_at ASC
  | 'confidence_high'  // confidence DESC
  | 'expiring_soon';   // expires_at ASC

/**
 * 페이지네이션.
 */
export interface DraftQueuePagination {
  page: number;        // 1-indexed
  pageSize: number;    // 20 / 50 / 100
}

/**
 * 큐 쿼리 결과 — 행 + 전체 카운트(페이지네이션 표시용).
 */
export interface DraftQueueResult {
  rows: DraftQueueRow[];
  totalCount: number;
  filters: DraftQueueFilters;
  sort: DraftQueueSort;
  pagination: DraftQueuePagination;
}

/* ============================================================
 * 기본값
 * ============================================================ */

export const DEFAULT_FILTERS: DraftQueueFilters = {
  status: 'pending_review',
  module: 'all',
  category: 'all',
  minConfidence: 0,
  onlyRisky: false,
};

export const DEFAULT_SORT: DraftQueueSort = 'urgent';

export const DEFAULT_PAGE_SIZE = 20;
export const PAGE_SIZE_OPTIONS: readonly number[] = [20, 50, 100] as const;
