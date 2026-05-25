/**
 * types/draft-detail.ts
 *
 * AI 초안 상세·편집 화면의 데이터 모델.
 * 큐 행(DraftQueueRow)보다 훨씬 풍부 — 본문 전체, AI 런 메타, 게이트 평가, 거래처 등.
 */

import type {
  ClassificationCategory,
  DraftStatus,
  Language,
  PartyTypeCode,
} from './ai';

/** AI 런 메타 (분류기·회신가 각각). */
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
  /** ai.runs.metadata 안의 trace_label, retry_count 등 */
  metadata: Record<string, unknown>;
}

/** 원본 인바운드 메일. */
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

/** 거래처 요약. */
export interface DraftPartySummary {
  id: string;
  name: string;
  module: PartyTypeCode;
  tier: string | null;
  countryCode: string | null;
  website: string | null;
}

/** 인게이지먼트 요약. */
export interface DraftEngagementSummary {
  id: string;
  name: string;
  module: PartyTypeCode;
  status: string;
  valueAmount: number | null;
  valueCurrency: string;
}

/** 자동발송 규칙 + 평가 로그. */
export interface DraftAutoSendInfo {
  eligible: boolean;
  blockedReasons: string[];
  ruleId: string | null;
  /** 게이트가 적용한 카테고리·신뢰도 기준 (디버깅용) */
  evaluationLog: Record<string, unknown>;
  /** 규칙 자체의 활성 여부·키워드 등 */
  rule: {
    classificationCategory: string;
    minConfidence: number;
    requiresHumanApproval: boolean;
    isBlocked: boolean;
    blockReason: string | null;
    isActive: boolean;
  } | null;
}

/** 상세 화면 데이터 한 묶음. */
export interface DraftDetail {
  id: string;
  organizationId: string;
  status: DraftStatus;
  module: PartyTypeCode | null;
  language: Language;

  // 분류 결과
  classificationCategory: ClassificationCategory | null;
  confidenceScore: number | null;
  riskFlags: string[];
  requiresHumanApproval: boolean;
  rationale: string | null;

  // 본문 (원본 vs 편집본)
  subject: string | null;
  bodyPlain: string;
  bodyHtml: string | null;
  finalSubject: string | null;
  finalBodyPlain: string | null;
  editDistance: number | null;

  // 검토 정보
  reviewedByUserId: string | null;
  reviewedAt: string | null;
  reviewNotes: string | null;

  // 만료
  expiresAt: string;
  expiredHandled: boolean;

  // 발송 결과 (status='sent'일 때)
  sentCommunicationId: string | null;

  aiGenerated: boolean;
  createdAt: string;
  updatedAt: string;

  // 조인된 객체
  inbound: DraftInboundSummary | null;
  party: DraftPartySummary | null;
  engagement: DraftEngagementSummary | null;
  classifierRun: DraftRunSummary | null;
  drafterRun: DraftRunSummary | null;
  autoSend: DraftAutoSendInfo;
}

/** 거부 사유 — 4 preset + 'other' (free text는 notes 필드에). */
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
