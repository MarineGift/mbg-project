import type { StandardCategory, RiskFlag } from './classification';

/**
 * Anthropic 모델 ID. 마스터 시스템 프롬프트 §2.4에 의해 정확히 이 3개만 허용.
 * 구버전 명명(claude-3-opus, claude-opus-4-5 등)은 ClaudeInvalidModelError로 차단.
 */
export type ClaudeModel =
  | 'claude-opus-4-7'
  | 'claude-sonnet-4-6'
  | 'claude-haiku-4-5-20251001';

export const SUPPORTED_CLAUDE_MODELS: ReadonlySet<ClaudeModel> = new Set([
  'claude-opus-4-7',
  'claude-sonnet-4-6',
  'claude-haiku-4-5-20251001',
]);

export function isSupportedClaudeModel(value: unknown): value is ClaudeModel {
  return typeof value === 'string' && SUPPORTED_CLAUDE_MODELS.has(value as ClaudeModel);
}

/**
 * ai.agents.role — STEP 2의 시드 데이터와 일치해야 한다.
 */
export type AgentRole =
  | 'classifier'
  | 'reply_drafter'
  | 'strategy_advisor'
  | 'summarizer'
  | 'translator'
  | 'risk_reviewer';

export type AgentOutputFormat = 'text' | 'structured';

export type RunStatus = 'success' | 'failed' | 'timeout' | 'budget_exceeded';

/**
 * ai.agents 행의 도메인 표현 (camelCase).
 */
export interface AgentRow {
  id: string;
  organizationId: string;
  role: AgentRole;
  name: string;
  model: ClaudeModel;
  fallbackModel?: ClaudeModel;
  temperature: number;
  maxTokens: number;
  outputFormat: AgentOutputFormat;
  systemPrompt: string;
  /** 모듈 매칭 ('investor' 등) — 빈 배열은 전 모듈 적용 */
  applicableModules?: string[];
  /** 'ko' | 'en' | 'ja' — 빈 배열은 전 언어 적용 */
  applicableLanguages?: string[];
  requirePiiMasking?: boolean;
  /** ai.knowledge_chunks 조회 시 사용할 collection 식별자 */
  knowledgeCollection?: string;
  isActive: boolean;
  version: number;
}

/**
 * Supabase row(snake_case) → AgentRow(camelCase) 매퍼. 호출처에서 type assertion 대신
 * 본 함수를 사용해 컬럼 변경 시 컴파일 타임에 검출되도록 한다.
 */
export function toAgentRow(dbRow: Record<string, unknown>): AgentRow {
  const model = dbRow.model;
  if (!isSupportedClaudeModel(model)) {
    throw new Error(
      `Invalid agent.model in DB: ${String(model)} (id=${String(dbRow.id)})`,
    );
  }
  const fallbackModelRaw = dbRow.fallback_model;
  const fallbackModel = isSupportedClaudeModel(fallbackModelRaw)
    ? fallbackModelRaw
    : undefined;

  return {
    id: String(dbRow.id),
    organizationId: String(dbRow.organization_id),
    role: dbRow.role as AgentRole,
    name: String(dbRow.name ?? ''),
    model,
    fallbackModel,
    temperature: Number(dbRow.temperature ?? 0.3),
    maxTokens: Number(dbRow.max_tokens ?? 4096),
    outputFormat: (dbRow.output_format as AgentOutputFormat) ?? 'text',
    systemPrompt: String(dbRow.system_prompt ?? ''),
    applicableModules: Array.isArray(dbRow.applicable_modules)
      ? (dbRow.applicable_modules as string[])
      : undefined,
    applicableLanguages: Array.isArray(dbRow.applicable_languages)
      ? (dbRow.applicable_languages as string[])
      : undefined,
    requirePiiMasking: dbRow.require_pii_masking === true,
    knowledgeCollection:
      typeof dbRow.knowledge_collection === 'string'
        ? dbRow.knowledge_collection
        : undefined,
    isActive: dbRow.is_active === true,
    version: Number(dbRow.version ?? 1),
  };
}

/**
 * ai.brand_voice 도메인 표현.
 */
export interface BrandVoiceRow {
  id: string;
  organizationId: string;
  module: string;
  language: 'ko' | 'en' | 'ja';
  toneDescription: string;
  signatureBlock?: string;
  fewShotExamples: Array<{ inbound: string; outbound: string; note?: string }>;
  isDefault: boolean;
}

export function toBrandVoiceRow(dbRow: Record<string, unknown>): BrandVoiceRow {
  return {
    id: String(dbRow.id),
    organizationId: String(dbRow.organization_id),
    module: String(dbRow.module),
    language: dbRow.language as BrandVoiceRow['language'],
    toneDescription: String(dbRow.tone_description ?? ''),
    signatureBlock:
      typeof dbRow.signature_block === 'string' ? dbRow.signature_block : undefined,
    fewShotExamples: Array.isArray(dbRow.few_shot_examples)
      ? (dbRow.few_shot_examples as BrandVoiceRow['fewShotExamples'])
      : [],
    isDefault: dbRow.is_default === true,
  };
}

/**
 * ai.knowledge_chunks 도메인 표현 (벡터 검색 결과).
 */
export interface KnowledgeChunkRow {
  id: string;
  organizationId: string;
  collection?: string;
  title?: string;
  content: string;
  /** cosine 유사도 (0~1, 1에 가까울수록 유사) */
  similarity: number;
  metadata?: Record<string, unknown>;
}

/**
 * ClaudeClient.complete 입력.
 */
export interface ClaudeCompleteInput {
  agentRole: AgentRole;
  partyId?: string;
  engagementId?: string;
  inboundMessage: string;
  language?: 'ko' | 'en' | 'ja';
  module?: string;
  maskPii?: boolean;
  outputFormat?: 'text' | 'json';
  caller?: string;
}

/**
 * ClaudeClient.complete 출력.
 */
export interface ClaudeCompleteOutput {
  content: string;
  parsedJson?: object;
  runId: string;
  model: ClaudeModel;
  latencyMs: number;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
  retryCount: number;
}

/**
 * Reply Drafter (Opus) 의 정형 출력.
 */
export interface ReplyDrafterOutput {
  subject: string;
  bodyPlain: string;
  bodyHtml?: string;
  rationale: string;
  riskFlags: RiskFlag[];
  requiresHumanApproval: boolean;
  language: 'ko' | 'en' | 'ja';
  classificationCategory: StandardCategory;
}

/**
 * ai.drafts INSERT용 페이로드.
 */
export interface DraftInsertPayload {
  organizationId: string;
  communicationId: string;
  partyId?: string;
  engagementId?: string;
  module?: string;
  language: 'ko' | 'en' | 'ja';
  classificationCategory: StandardCategory;
  subject: string;
  bodyPlain: string;
  bodyHtml?: string;
  rationale: string;
  riskFlags: RiskFlag[];
  requiresHumanApproval: boolean;
  autoSendEligible: boolean;
  autoSendBlockedReasons: string[];
  classifierRunId: string;
  replyDrafterRunId: string;
  expiresAt: string;
}

/**
 * Strategy Advisor (consultation-worker) 의 출력.
 */
export interface StrategyAdvisorOutput {
  summary: string;
  responseStrategies: Array<{
    title: string;
    rationale: string;
    confidence: number;
    actions: Array<{
      title: string;
      description: string;
      due_in_days?: number;
      assigned_role?: string;
      priority?: 'low' | 'medium' | 'high' | 'urgent';
    }>;
  }>;
  riskNotes: string[];
}
