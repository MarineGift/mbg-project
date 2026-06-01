/**
 * types/draft-detail.ts
 *
 * Data model for the AI draft detail/edit screen.
 * Much richer than the queue row (DraftQueueRow) - full body, AI run meta, gate evaluation, party, etc.
 */

import type {
  ClassificationCategory,
  DraftStatus,
  Language,
  PartyTypeCode,
} from './ai';

/** AI run meta (classifier and reply-drafter respectively). */
export interface DraftRunSummary {
  id: string;
  modelUsed: string;
  inputTokens: number | null;
  outputTokens: number | null;
  costUsd: number;
  latencyMs: number | null;
  status: string;
  startedAt: string;
  completedAt: string | null;
  /** trace_label, retry_count, etc. inside ai.runs.metadata */
  metadata: Record<string, unknown>;
}

/** Original inbound mail. */
export interface DraftInboundSummary {
  id: string;
  fromAddress: string | null;
  fromName: string | null;
  toAddresses: string[];
  ccAddresses: string[];
  subject: string | null;
  bodyPlain: string | null;
  bodyHtml: string | null;
  occurredAt: string;
  messageId: string | null;
  threadId: string | null;
  inReplyTo: string | null;
  channel: string;
}

/** Party summary. */
export interface DraftPartySummary {
  id: string;
  name: string;
  partyType: PartyTypeCode;
  tier: string | null;
  countryCode: string | null;
  website: string | null;
}

/** Engagement summary. */
export interface DraftEngagementSummary {
  id: string;
  name: string;
  partyType: PartyTypeCode;
  status: string;
  valueAmount: number | null;
  valueCurrency: string;
}

/** Auto-send rule + evaluation log. */
export interface DraftAutoSendInfo {
  eligible: boolean;
  blockedReasons: string[];
  ruleId: string | null;
  /** The category/confidence criteria the gate applied (for debugging) */
  evaluationLog: Record<string, unknown>;
  /** The rule's own active state, keywords, etc. */
  rule: {
    classificationCategory: string;
    minConfidence: number;
    requiresHumanApproval: boolean;
    isBlocked: boolean;
    blockReason: string | null;
    isActive: boolean;
  } | null;
}

/** One bundle of detail-screen data. */
export interface DraftDetail {
  id: string;
  organizationId: string;
  status: DraftStatus;
  partyType: PartyTypeCode | null;
  language: Language;

  // classification result
  classificationCategory: ClassificationCategory | null;
  confidenceScore: number | null;
  riskFlags: string[];
  requiresHumanApproval: boolean;
  rationale: string | null;

  // body (original vs edited)
  subject: string | null;
  bodyPlain: string;
  bodyHtml: string | null;
  finalSubject: string | null;
  finalBodyPlain: string | null;
  editDistance: number | null;

  // review info
  reviewedByUserId: string | null;
  reviewedAt: string | null;
  reviewNotes: string | null;

  // expiry
  expiresAt: string;
  expiredHandled: boolean;

  // send result (when status='sent')
  sentCommunicationId: string | null;

  aiGenerated: boolean;
  createdAt: string;
  updatedAt: string;

  // joined objects
  inbound: DraftInboundSummary | null;
  party: DraftPartySummary | null;
  engagement: DraftEngagementSummary | null;
  classifierRun: DraftRunSummary | null;
  drafterRun: DraftRunSummary | null;
  autoSend: DraftAutoSendInfo;
}

/** Rejection reason - 4 presets + 'other' (free text goes in the notes field). */
export type RejectReason =
  | 'outdated_request'
  | 'off_topic'
  | 'wrong_tone'
  | 'incorrect_info'
  | 'other';

export const REJECT_REASONS: readonly RejectReason[] = [
  'outdated_request',
  'off_topic',
  'wrong_tone',
  'incorrect_info',
  'other',
] as const;
