/**
 * types/party-detail.ts
 *
 * 거래처(parties) 상세 화면의 데이터 모델.
 * Phase 1은 read-only.
 *
 * 변경 이력:
 *   - 2026-05-11: DB 스키마와 정합 — 단일 industry/tags 필드 제거,
 *                 industryTags/interestTags 배열로 분리.
 *                 (DB 실제 컬럼: industry_tags ARRAY, interest_tags ARRAY)
 *   - 2026-05-14: Phase 6 — industryPaperCompanyId /
 *                 industryFillerSupplierId FK 필드 추가.
 */

import type { PartyTypeCode } from './ai';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
} from './inbox';

/** parties.tier CHECK 제약과 일치. */
export type PartyTier = 'tier_1' | 'tier_2' | 'tier_3' | 'cold';

/** parties.status CHECK 제약과 일치. */
export type PartyStatus = 'active' | 'paused' | 'closed_won' | 'closed_lost' | 'archived';

export interface PartyDetail {
  id: string;
  organizationId: string;
  name: string;
  module: PartyTypeCode;
  tier: PartyTier | null;
  status: PartyStatus;
  countryCode: string | null;
  website: string | null;
  /** 산업 분류 태그 (예: "Venture Capital", "Software", "Healthcare") */
  industryTags: string[];
  /** 관심/포커스 태그 (예: "Early Stage", "AI", "Growth") */
  interestTags: string[];
  notes: string | null;
  source: string | null;
  createdAt: string;
  updatedAt: string;

  /** ▼ Phase 6 — industry master DB 연동 FK */
  industryPaperCompanyId: number | null;
  industryFillerSupplierId: number | null;

  /** 통계 — RPC나 별도 COUNT 쿼리로 채움 */
  counts: {
    contacts: number;
    communications: number;
    pendingDrafts: number;
    openEngagements: number;
    openTasks: number;
  };
}

/** 활동 타임라인 한 항목 — communications + tasks 통합. */
export type TimelineItem =
  | TimelineCommunicationItem
  | TimelineTaskItem;

export interface TimelineCommunicationItem {
  kind: 'communication';
  id: string;
  occurredAt: string;
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  status: CommunicationStatus;
  subject: string | null;
  bodyPreview: string;
  fromAddress: string | null;
  aiGenerated: boolean;
}

export interface TimelineTaskItem {
  kind: 'task';
  id: string;
  occurredAt: string;     // created_at or completed_at
  event: 'created' | 'completed';
  title: string;
  status: string;
  priority: string | null;
  dueAt: string | null;
}

export interface PartyContact {
  id: string;
  fullName: string | null;
  email: string | null;
  jobTitle: string | null;
  phone: string | null;
  isPrimary: boolean;
}

export interface PartyEngagement {
  id: string;
  name: string;
  status: string;
  stage: string | null;
  valueAmount: number | null;
  valueCurrency: string;
  closeDate: string | null;
  updatedAt: string;
}

export interface PartyTask {
  id: string;
  title: string;
  status: string;
  priority: string | null;
  dueAt: string | null;
  createdAt: string;
}

export interface PartyDetailFull {
  party: PartyDetail;
  contacts: PartyContact[];
  engagements: PartyEngagement[];
  tasks: PartyTask[];
  timeline: TimelineItem[];
}
