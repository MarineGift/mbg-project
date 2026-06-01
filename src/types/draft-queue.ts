/**
 * types/draft-queue.ts
 *
 * Type for the AI draft queue list screen.
 *
 * DraftQueueRow is a flattened result of joining ai.drafts + parties(name) + contacts(full_name) +
 * inbound communications(from_address, subject).
 */

import type {
  ClassificationCategory,
  DraftStatus,
  Language,
  PartyTypeCode,
} from './ai';

/**
 * One row of the queue list. A narrow SELECT result used only on the queue screen.
 */
export interface DraftQueueRow {
  id: string;
  status: DraftStatus;
  partyType: PartyTypeCode | null;
  classificationCategory: ClassificationCategory | null;
  confidenceScore: number | null;
  language: Language;
  subject: string | null;
  bodyPlainPreview: string;  // first 120 chars of body_plain
  riskFlags: string[];
  requiresHumanApproval: boolean;
  autoSendEligible: boolean;
  /** Whether the user entered final_body_plain (to detect editing). Excluded from bulk approve. */
  hasEdits: boolean;
  expiresAt: string;  // ISO 8601
  createdAt: string;
  /** Party info (null means unassigned - e.g. a first cold contact) */
  partyId: string | null;
  partyName: string | null;
  /** Sender (fallback when there is no party) */
  fromAddress: string | null;
  /** Original inbound mail subject */
  inboundSubject: string | null;
  /** Engagement (if any) */
  engagementId: string | null;
  engagementName: string | null;
}

/**
 * Queue filter. Passed via the URL query string and parsed in a Server Component.
 */
export interface DraftQueueFilters {
  /** status - default 'pending_review'. 'all' means every status */
  status: DraftStatus | 'all';
  partyType: PartyTypeCode | 'all';
  category: ClassificationCategory | 'all';
  /** minimum confidence (0-1). 0 means no filter */
  minConfidence: number;
  /** only those flagged as risky */
  onlyRisky: boolean;
}

/**
 * Queue sort options.
 */
export type DraftQueueSort =
  | 'urgent'           // confidence ASC, expires_at ASC (default)
  | 'newest'           // created_at DESC
  | 'oldest'           // created_at ASC
  | 'confidence_high'  // confidence DESC
  | 'expiring_soon';   // expires_at ASC

/**
 * Pagination.
 */
export interface DraftQueuePagination {
  page: number;        // 1-indexed
  pageSize: number;    // 20 / 50 / 100
}

/**
 * Queue query result - rows + total count (for pagination display).
 */
export interface DraftQueueResult {
  rows: DraftQueueRow[];
  totalCount: number;
  filters: DraftQueueFilters;
  sort: DraftQueueSort;
  pagination: DraftQueuePagination;
}

/* ============================================================
 * default values
 * ============================================================ */

export const DEFAULT_FILTERS: DraftQueueFilters = {
  status: 'pending_review',
  partyType: 'all',
  category: 'all',
  minConfidence: 0,
  onlyRisky: false,
};

export const DEFAULT_SORT: DraftQueueSort = 'urgent';

export const DEFAULT_PAGE_SIZE = 20;
export const PAGE_SIZE_OPTIONS: readonly number[] = [20, 50, 100] as const;
