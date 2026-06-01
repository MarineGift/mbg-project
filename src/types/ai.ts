/**
 * types/ai.ts
 *
 * Domain object types for the AI system.
 * Maps rows of the ai schema (ai.agents, ai.runs, ai.drafts, ai.brand_voice, ai.knowledge_chunks,
 * ai.auto_send_rules) to camelCase.
 *
 * DB row -> domain object conversion is done in lib/db/mappers.ts.
 */

import type { ClassificationOutput, RiskFlag, StandardCategory } from './classification';

/* ============================================================
 * 1. Model/role enums
 * ============================================================ */

/** AI agent role (ai.agents.role column). */
export type AgentRole =
  | 'classifier' // mail classifier (Haiku)
  | 'reply_drafter' // reply-draft writer (Opus)
  | 'strategy_advisor' // strategy advisor (Opus)
  | 'summarizer' // body summarizer (Haiku)
  | 'content_extractor'; // scraping-result normalizer (Haiku)

/** Allowed Claude model IDs. Any other value throws ClaudeInvalidModelError. */
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
 * The classifier's 10 standard categories (master §4.2). Never change.
 * Matches the SQL CHECK constraints (ai.drafts.classification_category, ai.auto_send_rules).
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
 * Standard category array - used for UI dropdowns, etc.
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
 * Domain-level call status (code vocabulary). recordRun() maps it to the DB ai.run_status.
 * - success         → ai.run_status='completed'
 * - failed          → ai.run_status='failed'
 * - timeout         → ai.run_status='timed_out'
 * - budget_exceeded → ai.run_status='failed' + metadata.error_class='ClaudeBudgetExceededError'
 */
export type RunStatus = 'success' | 'failed' | 'timeout' | 'budget_exceeded';

/** Module ENUM (master prompt §3.1). */
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
 * 2. AgentRow - ai.agents row
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
  applicablePartyTypes?: PartyTypeCode[];
  applicableLanguages?: Language[];
  requirePiiMasking?: boolean;
  knowledgeCollection?: string;
  isActive: boolean;
  version: number;
}

/* ============================================================
 * 3. BrandVoiceRow - ai.brand_voice row
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
 * 4. KnowledgeChunkRow (search result)
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
 * 5. AutoSendRuleRow - ai.auto_send_rules row
 * ============================================================ */
export interface AutoSendRuleRow {
  id: string;
  organizationId: string;
  classificationCategory: StandardCategory;
  isBlocked: boolean;
  blockReason?: string;
  minConfidence: number;
  requiresHumanApproval: boolean;
  allowedPartyTypes: PartyTypeCode[];
  blockedKeywordsInBody: string[];
  dailyLimit: number;
  hourlyLimit: number;
  perPartyDailyLimit: number;
  requiresCalendarData: boolean;
  isActive: boolean;
}

/* ============================================================
 * 6. DraftRow - ai.drafts row
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
  /** Party context (optional). Looked up by prompt-renderer. */
  partyId?: string;
  /** Engagement context (optional). Aids thread_history lookup. */
  engagementId?: string;
  /** Message body to pass to the model. PII masking is controlled by the maskPii option. */
  inboundMessage: string;
  /** Response language hint (used for brand_voice matching). */
  language?: Language;
  /** Whether to force PII masking. If unset, follows agent.requirePiiMasking. */
  maskPii?: boolean;
  /** When 'json', the response is JSON.parse'd -> filled into parsedJson. */
  outputFormat?: 'text' | 'json';
  /** Context to add to the user message (to enrich prompt-renderer input). */
  extraContext?: Record<string, unknown>;
  /** Trace label for identifying the caller (logging only). */
  traceLabel?: string;
}

export interface ClaudeCompleteOutput {
  content: string;
  parsedJson?: object;
  runId: string;
  /** Same as ai.runs.agent_id. Used for ai.drafts.agent_id (NOT NULL). */
  agentId: string;
  model: ClaudeModel;
  latencyMs: number;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
}

/* ============================================================
 * 8. ReplyDrafter output
 * ============================================================ */
export interface ReplyDrafterOutput {
  subject: string;
  bodyPlain: string;
  bodyHtml?: string;
  rationale: string;
  riskFlags: RiskFlag[];
  requiresHumanApproval: boolean;
  language: Language;
  /** Index of the brand_voice example the drafter used (for the learning loop). */
  usedBrandVoiceExampleIndices?: number[];
  /** IDs of the knowledge_chunks used (for tracing). */
  citedKnowledgeChunkIds?: string[];
}

/**
 * Validate/convert the Reply Drafter JSON response into ReplyDrafterOutput.
 * On violation, returns [false, reason] - the processor forces requires_human_approval=true.
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
 * 9. RecordRun input (cost-tracker -> ai.runs INSERT)
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
  /** trace label (e.g. 'processor:classifier'). */
  traceLabel?: string;
}

/* ============================================================
 * 10. Composite type holding both classification and reply results
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
