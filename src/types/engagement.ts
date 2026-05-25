/**
 * types/engagement.ts
 *
 * Engagement(인게이지먼트, deals) 화면의 데이터 모델.
 *
 * Kanban 구조 (스키마 정규화):
 *   pipeline_definitions (모듈별 활성 파이프라인)
 *     └─ pipeline_stages   (stage 컬럼들)
 *         └─ engagements   (각 stage에 속한 카드들)
 */

import type { PartyTypeCode } from './ai';

/** app.engagement_status enum. */
export type EngagementStatus =
  | 'open'
  | 'in_progress'
  | 'on_hold'
  | 'won'
  | 'lost'
  | 'archived';

/** pipeline_stage_type — LEAN 분석용 공통 매핑. */
export type PipelineStageType =
  | 'lead'
  | 'qualified'
  | 'proposal'
  | 'negotiation'
  | 'closed_won'
  | 'closed_lost'
  | 'other';

/** Kanban 한 컬럼 = 한 pipeline_stage. */
export interface KanbanStage {
  id: string;
  pipelineDefinitionId: string;
  code: string;
  name: string;
  stageType: PipelineStageType;
  sortOrder: number;
  defaultProbabilityPct: number;
  isTerminal: boolean;
  isWon: boolean;
  isLost: boolean;
  colorHex: string | null;
}

/** Kanban 카드 = 한 engagement (목록용 평탄화). */
export interface KanbanCard {
  id: string;
  name: string;
  partyType: PartyTypeCode;
  status: EngagementStatus;
  currentStageId: string | null;
  pipelineDefinitionId: string | null;
  partyId: string;
  partyName: string;
  valueAmount: number | null;
  valueCurrency: string;
  probabilityPct: number;
  weightedAmount: number | null;
  expectedCloseDate: string | null;
  ownerUserId: string | null;
  updatedAt: string;
}

/** Kanban 보드 — 한 모듈의 default pipeline + stages + cards. */
export interface KanbanBoard {
  partyType: PartyTypeCode;
  /** module에 default pipeline이 없을 경우 null — 사용자에게 안내 표시 */
  pipelineDefinitionId: string | null;
  pipelineName: string | null;
  stages: KanbanStage[];
  /** stage_id → cards 그룹 매핑 */
  cardsByStage: Record<string, KanbanCard[]>;
  /** stage가 없거나 매핑 안 된 카드 — '미분류' 컬럼 */
  uncategorizedCards: KanbanCard[];
  /** 카운트 (UI 헤더 표시용) */
  totalCount: number;
}

/* ============================================================
 * Engagement Detail
 * ============================================================ */

export interface EngagementStageHistoryItem {
  id: string;
  fromStageId: string | null;
  fromStageName: string | null;
  toStageId: string | null;
  toStageName: string;
  movedAt: string;
  movedByUserId: string | null;
  durationSeconds: number | null;
  reason: string | null;
}

export interface EngagementDetail {
  id: string;
  organizationId: string;
  partyId: string;
  partyName: string;
  primaryContactId: string | null;
  primaryContactName: string | null;
  partyType: PartyTypeCode;
  name: string;
  description: string | null;
  pipelineDefinitionId: string | null;
  pipelineName: string | null;
  currentStageId: string | null;
  currentStageName: string | null;
  currentStageColor: string | null;
  status: EngagementStatus;
  valueAmount: number | null;
  valueCurrency: string;
  probabilityPct: number;
  weightedAmount: number | null;
  expectedCloseDate: string | null;
  actualCloseDate: string | null;
  ownerUserId: string | null;
  wonLostReason: string | null;
  source: string | null;
  createdAt: string;
  updatedAt: string;
  /** 이 인게이지먼트의 사용 가능 stages (드롭다운 옵션) */
  availableStages: KanbanStage[];
  stageHistory: EngagementStageHistoryItem[];
}
