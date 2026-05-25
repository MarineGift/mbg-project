/**
 * types/ai.ts
 *
 * AI 시스템의 도메인 객체 타입.
 * ai 스키마(ai.agents·ai.runs·ai.drafts·ai.brand_voice·ai.knowledge_chunks·
 * ai.auto_send_rules)의 행을 camelCase로 매핑한다.
 *
 * DB row → 도메인 객체 변환은 lib/db/mappers.ts에서 수행.
 */

import type { ClassificationOutput, RiskFlag, StandardCategory } from './classification';

/* ============================================================
 * 1. 모델·역할 enum
 * ============================================================ */

/** AI 에이전트 역할 (ai.agents.role 컬럼). */
export type AgentRole =
  | 'classifier' // 메일 분류기 (Haiku)
  | 'reply_drafter' // 회신 초안 작성자 (Opus)
  | 'strategy_advisor' // 전략 어드바이저 (Opus)
  | 'summarizer' // 본문 요약기 (Haiku)
  | 'content_extractor'; // 스크래핑 결과 정규화 (Haiku)

/** 허용된 Claude 모델 ID. 다른 값이 들어오면 ClaudeInvalidModelError throw. */
export type ClaudeModel =
  | 'claude-opus-4-7'
  | 'claude-sonnet-4-6'
  | 'claude-haiku-4-5-20251001';

export type DraftStatus =
  | 'pending_review'
  | 'approved'
  | 'sent'
  | 'rejected'
  | 'expired'
  | 'auto_sent';

/**
 * 분류기의 10개 표준 카테고리 (마스터 §4.2). 절대 변경 금지.
 * SQL CHECK 제약 (ai.drafts.classification_category, ai.auto_send_rules)과 일치.
 */
export type ClassificationCategory =
  | 'information_request'
  | 'meeting_scheduling'
  | 'simple_acknowledgment'
  | 'price_negotiation'
  | 'contract_terms'
  | 'rejection'
  | 'complaint'
  | 'introduction'
  | 'follow_up'
  | 'other';

/**
 * 표준 카테고리 배열 — UI 드롭다운 등에 사용.
 */
export const CLASSIFICATION_CATEGORIES: readonly ClassificationCategory[] = [
  'information_request',
  'meeting_scheduling',
  'simple_acknowledgment',
  'price_negotiation',
  'contract_terms',
  'rejection',
  'complaint',
  'introduction',
  'follow_up',
  'other',
] as const;

/**
 * 도메인 수준 호출 상태(코드 vocabulary). recordRun()이 DB ai.run_status로 매핑한다.
 * - success         → ai.run_status='completed'
 * - failed          → ai.run_status='failed'
 * - timeout         → ai.run_status='timed_out'
 * - budget_exceeded → ai.run_status='failed' + metadata.error_class='ClaudeBudgetExceededError'
 */
export type RunStatus = 'success' | 'failed' | 'timeout' | 'budget_exceeded';

/** 모듈 ENUM (마스터 프롬프트 §3.1). */
/**
 * @deprecated Use PartyTypeCode from '@/types/party-type' instead.
 *
 * URM cutover (2026-05-25): ModuleType becomes an alias to PartyTypeCode.
 * Value set differs from legacy:
 *   - 'filler_supplier' -> 'filler_supplier' (rename)
 *   - 'crowdfunding', 'product_launch', 'sales' removed
 *   - 'buyer', 'government_grant' added
 *
 * 'filler_supplier' / 'crowdfunding' / 'product_launch' / 'sales' literals now fail
 * type-check. Migrate to PartyTypeCode in a cleanup sprint.
 */
// ModuleType alias removed during P2a-cleanup. Use PartyTypeCode (canonical).
import type { PartyTypeCode } from './party-type';
export type { PartyTypeCode };

export type Language = 'ko' | 'en' | 'ja';

/* ============================================================
 * 2. AgentRow — ai.agents 행
 * ============================================================ */
export interface AgentRow {
  id: string;
  organizationId: string;
  role: AgentRole;
  name: string;
  model: ClaudeModel;
  fallbackModel?: ClaudeModel;
  temperature: number;
  maxTokens: number;
  outputFormat: 'text' | 'structured';
  systemPrompt: string;
  applicableModules?: PartyTypeCode[];
  applicableLanguages?: Language[];
  requirePiiMasking?: boolean;
  knowledgeCollection?: string;
  isActive: boolean;
  version: number;
}

/* ============================================================
 * 3. BrandVoiceRow — ai.brand_voice 행
 * ============================================================ */
export interface BrandVoiceRow {
  id: string;
  organizationId: string;
  partyType: PartyTypeCode;
  language: Language;
  toneGuidelines: string;
  doSay: string[];
  dontSay: string[];
  glossary: Record<string, string>;
  fewShotExamples: Array<{
    input: string;
    output: string;
    notes?: string;
  }>;
  isActive: boolean;
  version: number;
}

/* ============================================================
 * 4. KnowledgeChunkRow (검색 결과)
 * ============================================================ */
export interface KnowledgeChunkSearchResult {
  id: string;
  collection: string;
  content: string;
  similarity: number;
  sourceType: string;
  sourceUri?: string;
  metadata?: Record<string, unknown>;
}

/* ============================================================
 * 5. AutoSendRuleRow — ai.auto_send_rules 행
 * ============================================================ */
export interface AutoSendRuleRow {
  id: string;
  organizationId: string;
  classificationCategory: StandardCategory;
  isBlocked: boolean;
  blockReason?: string;
  minConfidence: number;
  requiresHumanApproval: boolean;
  allowedModules: PartyTypeCode[];
  blockedKeywordsInBody: string[];
  dailyLimit: number;
  hourlyLimit: number;
  perPartyDailyLimit: number;
  requiresCalendarData: boolean;
  isActive: boolean;
}

/* ============================================================
 * 6. DraftRow — ai.drafts 행
 * ============================================================ */
export interface DraftRow {
  id: string;
  organizationId: string;
  communicationId: string;
  partyId?: string;
  engagementId?: string;
  classificationCategory: StandardCategory;
  confidenceScore: number;
  riskFlags: RiskFlag[];
  subject: string;
  bodyPlain: string;
  bodyHtml?: string;
  rationale?: string;
  requiresHumanApproval: boolean;
  autoSendEligible: boolean;
  autoSendBlockedReasons: string[];
  expiresAt: string;
  status: DraftStatus;
  classifierRunId?: string;
  drafterRunId?: string;
  reviewedBy?: string;
  reviewedAt?: string;
  approvedBy?: string;
  approvedAt?: string;
  sentAt?: string;
  language: Language;
  aiGenerated: boolean;
}

/* ============================================================
 * 7. ClaudeClient I/O
 * ============================================================ */

export interface ClaudeCompleteInput {
  agentRole: AgentRole;
  /** Party 컨텍스트(선택). prompt-renderer가 조회. */
  partyId?: string;
  /** Engagement 컨텍스트(선택). thread_history 조회 시 보조. */
  engagementId?: string;
  /** 모델에 전달할 메시지 본문. PII 마스킹은 maskPii 옵션으로 제어. */
  inboundMessage: string;
  /** 응답 언어 힌트(brand_voice 매칭에 사용). */
  language?: Language;
  /** PII 마스킹 강제 여부. 미지정 시 agent.requirePiiMasking 따름. */
  maskPii?: boolean;
  /** 'json' 시 응답을 JSON.parse → parsedJson에 채움. */
  outputFormat?: 'text' | 'json';
  /** 사용자 메시지에 추가할 컨텍스트(prompt-renderer 입력 보강용). */
  extraContext?: Record<string, unknown>;
  /** 호출자 식별용 트레이스 라벨(로깅에만 사용). */
  traceLabel?: string;
}

export interface ClaudeCompleteOutput {
  content: string;
  parsedJson?: object;
  runId: string;
  /** ai.runs.agent_id와 동일. ai.drafts.agent_id (NOT NULL)에 사용. */
  agentId: string;
  model: ClaudeModel;
  latencyMs: number;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
}

/* ============================================================
 * 8. ReplyDrafter 출력
 * ============================================================ */
export interface ReplyDrafterOutput {
  subject: string;
  bodyPlain: string;
  bodyHtml?: string;
  rationale: string;
  riskFlags: RiskFlag[];
  requiresHumanApproval: boolean;
  language: Language;
  /** 회신가가 사용한 brand_voice example의 인덱스(학습 루프용). */
  usedBrandVoiceExampleIndices?: number[];
  /** 사용된 knowledge_chunks의 ID(추적용). */
  citedKnowledgeChunkIds?: string[];
}

/**
 * Reply Drafter JSON 응답을 ReplyDrafterOutput으로 검증·변환.
 * 위반 시 [false, 사유] 반환 — processor가 requires_human_approval=true로 강제.
 */
export function validateReplyDrafterOutput(
  obj: unknown,
):
  | { ok: true; value: ReplyDrafterOutput }
  | { ok: false; reasons: string[] } {
  const reasons: string[] = [];
  if (!obj || typeof obj !== 'object') {
    return { ok: false, reasons: ['not_an_object'] };
  }
  const o = obj as Record<string, unknown>;

  if (typeof o.subject !== 'string' || o.subject.trim().length === 0) {
    reasons.push('subject_missing_or_empty');
  }
  if (typeof o.bodyPlain !== 'string' || o.bodyPlain.trim().length === 0) {
    reasons.push('body_plain_missing_or_empty');
  }
  if (typeof o.rationale !== 'string') {
    reasons.push('rationale_not_string');
  }
  if (!Array.isArray(o.riskFlags)) {
    reasons.push('risk_flags_not_array');
  }
  if (typeof o.requiresHumanApproval !== 'boolean') {
    reasons.push('requires_human_approval_not_boolean');
  }
  if (!['ko', 'en', 'ja'].includes(String(o.language))) {
    reasons.push(`invalid_language:${String(o.language)}`);
  }

  if (reasons.length > 0) return { ok: false, reasons };

  return {
    ok: true,
    value: {
      subject: (o.subject as string).trim(),
      bodyPlain: o.bodyPlain as string,
      bodyHtml: typeof o.bodyHtml === 'string' ? o.bodyHtml : undefined,
      rationale: o.rationale as string,
      riskFlags: (o.riskFlags as unknown[]).filter(
        (f): f is RiskFlag => typeof f === 'string',
      ) as RiskFlag[],
      requiresHumanApproval: o.requiresHumanApproval as boolean,
      language: o.language as Language,
      usedBrandVoiceExampleIndices: Array.isArray(o.usedBrandVoiceExampleIndices)
        ? (o.usedBrandVoiceExampleIndices as unknown[]).filter(
            (n): n is number => typeof n === 'number',
          )
        : undefined,
      citedKnowledgeChunkIds: Array.isArray(o.citedKnowledgeChunkIds)
        ? (o.citedKnowledgeChunkIds as unknown[]).filter(
            (s): s is string => typeof s === 'string',
          )
        : undefined,
    },
  };
}

/* ============================================================
 * 9. RecordRun 입력 (cost-tracker → ai.runs INSERT)
 * ============================================================ */
export interface RecordRunInput {
  agentId: string;
  status: RunStatus;
  model: string;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
  latencyMs: number;
  piiMasked: boolean;
  piiCategories: string[];
  retryCount: number;
  partyId?: string;
  engagementId?: string;
  brandVoiceId?: string;
  knowledgeChunkIds?: string[];
  errorMessage?: string;
  errorStatus?: number;
  /** trace 라벨(예: 'processor:classifier'). */
  traceLabel?: string;
}

/* ============================================================
 * 10. 분류 결과 + 회신 결과를 함께 다루는 합성 타입
 * ============================================================ */
export interface ProcessedInbound {
  communicationId: string;
  classification: ClassificationOutput;
  reply: ReplyDrafterOutput;
  classifierRunId: string;
  drafterRunId: string;
  draftId: string;
  autoSendAllowed: boolean;
  autoSendBlockedReasons: string[];
}
