/**
 * types/engagement.ts
 *
 * Data model for the Engagement (deals) screen.
 *
 * Kanban structure (normalized schema):
 *   pipeline_definitions (active pipeline per module)
 *     └─ pipeline_stages   (stage columns)
 *         └─ engagements   (cards belonging to each stage)
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

/** pipeline_stage_type - common mapping for LEAN analysis. */
export type PipelineStageType =
  | 'lead'
  | 'qualified'
  | 'proposal'
  | 'negotiation'
  | 'closed_won'
  | 'closed_lost'
  | 'other';

/** One Kanban column = one pipeline_stage. */
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

/** Kanban card = one engagement (flattened for listing). */
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

/** Kanban board - one module's default pipeline + stages + cards. */
export interface KanbanBoard {
  partyType: PartyTypeCode;
  /** null when the module has no default pipeline - show guidance to the user */
  pipelineDefinitionId: string | null;
  pipelineName: string | null;
  stages: KanbanStage[];
  /** stage_id -> cards group mapping */
  cardsByStage: Record<string, KanbanCard[]>;
  /** cards with no stage or unmapped - the 'Uncategorized' column */
  uncategorizedCards: KanbanCard[];
  /** count (for the UI header display) */
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
  /** available stages for this engagement (dropdown options) */
  availableStages: KanbanStage[];
  stageHistory: EngagementStageHistoryItem[];
}
