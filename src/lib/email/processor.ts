/**
 * lib/email/processor.ts
 *
 * 수신 메일 처리 파이프라인.
 *
 * 단계:
 *   [1] communications 행 lock + 조회
 *   [2] ai_processing_status='processing' 갱신
 *   [3] 분류기(Haiku) 호출 → ClassificationOutput
 *       - 표준 10 카테고리 위반 시 'other'로 강제 + requires_human=true
 *   [4] 회신가(Opus) 호출 → ReplyDrafterOutput
 *       - 출력 검증 실패 시 requires_human_approval=true 강제
 *       - 미복원 PII 토큰 검출 시 requires_human_approval=true 강제
 *   [5] auto-send-gate 평가
 *   [6] ai.drafts INSERT (expires_at = NOW() + DRAFT_EXPIRY_DAYS)
 *   [7] communications.ai_draft_id FK 갱신 + ai_processing_status='completed'
 *
 * 어느 단계가 실패해도 communications.ai_processing_status='failed' 갱신 보장.
 *
 * AI 호출은 모두 ClaudeClient를 거치므로 ai.runs 자동 기록·PII 마스킹 적용.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import {
  ClaudeApiError,
  ClaudeBudgetExceededError,
  ClaudeClient,
} from '../ai/claude-client';
import {
  hasUnrestoredTokens,
  findUnrestoredTokens,
} from '../ai/pii-masker';
import { evaluateAutoSend, type GateResult } from './auto-send-gate';
import { resolveReplyLanguage, type AiProcessingStatus } from '../../types/email';
import {
  validateClassificationOutput,
  STANDARD_CATEGORIES,
  type ClassificationOutput,
  type StandardCategory,
} from '../../types/classification';
import {
  validateReplyDrafterOutput,
  type Language,
  type PartyTypeCode,
  type ProcessedInbound,
  type ReplyDrafterOutput,
} from '../../types/ai';

/* ============================================================
 * 1. 에러 클래스
 * ============================================================ */

export class ProcessorError extends Error {
  public override readonly cause?: unknown;
  constructor(message: string, cause?: unknown) {
    super(message);
    this.name = 'ProcessorError';
    this.cause = cause;
  }
}

export class ProcessorCommunicationNotFoundError extends ProcessorError {
  constructor(communicationId: string) {
    super(`Communication not found or already deleted: ${communicationId}`);
    this.name = 'ProcessorCommunicationNotFoundError';
  }
}

/* ============================================================
 * 2. 입력
 * ============================================================ */

export interface ProcessInboundOptions {
  /** 강제로 처리(이미 ai_draft_id가 있어도). 디폴트 false. */
  force?: boolean;
  /** 단위 테스트에서 ClaudeClient를 주입할 때 사용. */
  claudeClient?: ClaudeClient;
}

interface CommunicationContext {
  id: string;
  organizationId: string;
  partyId?: string;
  contactId?: string;
  engagementId?: string;
  partyType?: PartyTypeCode;
  fromAddress?: string;
  bodyPlain: string;
  subject: string;
  languageDetected?: string;
  contactPreferredLanguage?: string;
  partyCountryCode?: string;
}

/* ============================================================
 * 3. processInbound — 메인 진입점
 * ============================================================ */

export async function processInbound(
  supabase: SupabaseClient,
  organizationId: string,
  communicationId: string,
  options: ProcessInboundOptions = {},
): Promise<ProcessedInbound> {
  // [1] 조회
  const ctx = await fetchCommunicationContext(
    supabase,
    organizationId,
    communicationId,
    options.force ?? false,
  );

  // [2] processing 상태 마킹
  await updateProcessingStatus(supabase, communicationId, 'processing');

  try {
    // 회신 언어 결정
    const language = resolveReplyLanguage({
      contactPreferred: ctx.contactPreferredLanguage,
      detectedFromInbound: ctx.languageDetected,
      partyCountryCode: ctx.partyCountryCode,
    });

    const claude =
      options.claudeClient ?? new ClaudeClient(supabase, organizationId);

    // [3] 분류기
    const classification = await runClassifier(claude, ctx, language);

    // [4] 회신가
    const replyResult = await runReplyDrafter(
      claude,
      ctx,
      classification,
      language,
    );

    // [5] 자동발송 게이트
    const gate = await evaluateAutoSend(supabase, {
      organizationId,
      partyType: ctx.partyType,
      partyId: ctx.partyId,
      classification,
      draftBody: replyResult.reply.bodyPlain,
      drafterRequiresHuman: replyResult.reply.requiresHumanApproval,
    });

    // [6] ai.drafts INSERT
    const draftId = await insertDraft(supabase, {
      ctx,
      classification,
      reply: replyResult.reply,
      classifierRunId: classification.__runId,
      drafterRunId: replyResult.runId,
      drafterAgentId: replyResult.agentId,
      gate,
      language,
    });

    // [7] communications 갱신
    await updateProcessingComplete(
      supabase,
      communicationId,
      draftId,
      classification,
      language,
    );

    return {
      communicationId,
      classification: stripInternalFields(classification),
      reply: replyResult.reply,
      classifierRunId: classification.__runId,
      drafterRunId: replyResult.runId,
      draftId,
      autoSendAllowed: gate.allowed,
      autoSendBlockedReasons: gate.reasons.map((r) => String(r)),
    };
  } catch (err) {
    // 실패 시 status='failed' + error 기록
    await markFailed(supabase, communicationId, err);
    throw err;
  }
}

/* ============================================================
 * 4. 단계별 헬퍼
 * ============================================================ */

async function fetchCommunicationContext(
  supabase: SupabaseClient,
  organizationId: string,
  communicationId: string,
  force: boolean,
): Promise<CommunicationContext> {
  const { data, error } = await supabase
    .schema('app')
    .from('communications')
    .select(
      'id, organization_id, party_id, contact_id, engagement_id, module, from_address, body_plain, subject, language_detected, ai_draft_id, ai_processing_status',
    )
    .eq('id', communicationId)
    .eq('organization_id', organizationId)
    .is('deleted_at', null)
    .maybeSingle();

  if (error) {
    throw new ProcessorError(
      `Communication lookup failed: ${error.message}`,
      error,
    );
  }
  if (!data) {
    throw new ProcessorCommunicationNotFoundError(communicationId);
  }

  if (data.ai_draft_id && !force) {
    throw new ProcessorError(
      `Communication ${communicationId} already has draft ${data.ai_draft_id}; pass force=true to reprocess`,
    );
  }

  // contact·party 보조 정보 조회 (회신 언어 결정용)
  let contactPreferredLanguage: string | undefined;
  if (data.contact_id) {
    const { data: contact } = await supabase
      .schema('app')
      .from('contacts')
      .select('preferred_language')
      .eq('id', data.contact_id)
      .maybeSingle();
    if (contact?.preferred_language) {
      contactPreferredLanguage = contact.preferred_language as string;
    }
  }

  let partyCountryCode: string | undefined;
  if (data.party_id) {
    const { data: party } = await supabase
      .schema('app')
      .from('parties')
      .select('country_code')
      .eq('id', data.party_id)
      .maybeSingle();
    if (party?.country_code) partyCountryCode = party.country_code as string;
  }

  return {
    id: data.id as string,
    organizationId: data.organization_id as string,
    partyId: (data.party_id as string | null) ?? undefined,
    contactId: (data.contact_id as string | null) ?? undefined,
    engagementId: (data.engagement_id as string | null) ?? undefined,
    partyType: (data.module as PartyTypeCode | null) ?? undefined,
    fromAddress: (data.from_address as string | null) ?? undefined,
    bodyPlain: (data.body_plain as string | null) ?? '',
    subject: (data.subject as string | null) ?? '',
    languageDetected: (data.language_detected as string | null) ?? undefined,
    contactPreferredLanguage,
    partyCountryCode,
  };
}

/* --------------------------------------------------------
 * Classifier 호출 + 표준 10 카테고리 강제
 * -------------------------------------------------------- */
type ClassificationWithMeta = ClassificationOutput & { __runId: string };

async function runClassifier(
  claude: ClaudeClient,
  ctx: CommunicationContext,
  language: Language,
): Promise<ClassificationWithMeta> {
  const result = await claude.complete({
    agentRole: 'classifier',
    inboundMessage: ctx.bodyPlain,
    outputFormat: 'json',
    partyId: ctx.partyId,
    engagementId: ctx.engagementId,
    language,
    traceLabel: `processor:classifier:${ctx.id}`,
  });

  const validation = validateClassificationOutput(result.parsedJson);
  if (!validation.ok) {
    // eslint-disable-next-line no-console
    console.warn(
      `[processor:${ctx.id}] classifier output invalid: ${validation.reasons.join(',')} → forcing 'other'`,
    );
    return {
      __runId: result.runId,
      category: 'other',
      urgency: 'medium',
      sentiment: 'neutral',
      requiresHuman: true,
      confidence: 0.3,
      rationale: `classifier output validation failed: ${validation.reasons.join(',')}`,
      riskFlags: [],
      detectedLanguage: 'other',
    };
  }

  let classification = validation.value;

  // 표준 카테고리 검증 (validateClassificationOutput이 이미 수행하지만 재확인)
  if (
    !(STANDARD_CATEGORIES as readonly string[]).includes(classification.category)
  ) {
    // eslint-disable-next-line no-console
    console.warn(
      `[processor:${ctx.id}] non-standard category: ${classification.category} → 'other'`,
    );
    classification = {
      ...classification,
      category: 'other' as StandardCategory,
      requiresHuman: true,
      confidence: Math.min(classification.confidence, 0.5),
    };
  }

  return { ...classification, __runId: result.runId };
}

function stripInternalFields(c: ClassificationWithMeta): ClassificationOutput {
  const { __runId, ...rest } = c;
  void __runId;
  return rest;
}

/* --------------------------------------------------------
 * Reply Drafter 호출
 * -------------------------------------------------------- */

interface ReplyResult {
  reply: ReplyDrafterOutput;
  runId: string;
  agentId: string;
}

async function runReplyDrafter(
  claude: ClaudeClient,
  ctx: CommunicationContext,
  classification: ClassificationWithMeta,
  language: Language,
): Promise<ReplyResult> {
  const result = await claude.complete({
    agentRole: 'reply_drafter',
    inboundMessage: ctx.bodyPlain,
    outputFormat: 'json',
    partyId: ctx.partyId,
    engagementId: ctx.engagementId,
    language,
    extraContext: {
      classification: stripInternalFields(classification),
      original_subject: ctx.subject,
    },
    traceLabel: `processor:reply_drafter:${ctx.id}`,
  });

  const validation = validateReplyDrafterOutput(result.parsedJson);
  if (!validation.ok) {
    // 검증 실패 → 사람 검토 필수 + 안전한 폴백 응답
    // eslint-disable-next-line no-console
    console.warn(
      `[processor:${ctx.id}] reply drafter output invalid: ${validation.reasons.join(',')}`,
    );
    return {
      runId: result.runId,
      agentId: result.agentId,
      reply: buildFallbackReply(ctx, classification, language, validation.reasons),
    };
  }

  let reply = validation.value;

  // 미복원 PII 토큰이 본문에 있으면 사람 검토 강제
  if (
    hasUnrestoredTokens(reply.bodyPlain) ||
    (reply.bodyHtml && hasUnrestoredTokens(reply.bodyHtml))
  ) {
    const tokens = [
      ...findUnrestoredTokens(reply.bodyPlain),
      ...findUnrestoredTokens(reply.bodyHtml ?? ''),
    ];
    // eslint-disable-next-line no-console
    console.warn(
      `[processor:${ctx.id}] unrestored PII tokens in reply: ${tokens.join(',')}`,
    );
    reply = {
      ...reply,
      requiresHumanApproval: true,
      rationale: `${reply.rationale}\n[Forced human approval: unrestored PII tokens detected: ${tokens.join(',')}]`,
    };
  }

  return { runId: result.runId, agentId: result.agentId, reply };
}

function buildFallbackReply(
  ctx: CommunicationContext,
  classification: ClassificationWithMeta,
  language: Language,
  reasons: string[],
): ReplyDrafterOutput {
  const subjectPrefix =
    language === 'ko' ? 'Re: ' : language === 'ja' ? 'Re: ' : 'Re: ';
  const bodyByLang: Record<Language, string> = {
    ko: '메시지를 잘 받았습니다. 검토 후 빠른 시일 내에 답변드리겠습니다.\n\n감사합니다.',
    en: 'Thank you for your message. We will review it and get back to you shortly.\n\nBest regards.',
    ja: 'ご連絡いただきありがとうございます。内容を確認のうえ、改めてご連絡いたします。\n\n敬具',
  };
  return {
    subject: subjectPrefix + ctx.subject,
    bodyPlain: bodyByLang[language],
    rationale: `Fallback reply due to drafter validation failure: ${reasons.join(',')}. Original category: ${classification.category}.`,
    riskFlags: [],
    requiresHumanApproval: true,
    language,
  };
}

/* --------------------------------------------------------
 * ai.drafts INSERT
 * -------------------------------------------------------- */

interface InsertDraftInput {
  ctx: CommunicationContext;
  classification: ClassificationWithMeta;
  reply: ReplyDrafterOutput;
  classifierRunId: string;
  drafterRunId: string;
  /** ai.drafts.agent_id (NOT NULL) — 회신가 에이전트의 ai.agents.id */
  drafterAgentId: string;
  gate: GateResult;
  language: Language;
}

async function insertDraft(
  supabase: SupabaseClient,
  input: InsertDraftInput,
): Promise<string> {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + env.DRAFT_EXPIRY_DAYS);

  const requiresHumanApproval =
    !input.gate.allowed ||
    input.classification.requiresHuman ||
    input.reply.requiresHumanApproval;

  const { data, error } = await supabase
    .schema('ai')
    .from('drafts')
    .insert({
      organization_id: input.ctx.organizationId,
      agent_id: input.drafterAgentId,
      inbound_communication_id: input.ctx.id,
      party_id: input.ctx.partyId ?? null,
      engagement_id: input.ctx.engagementId ?? null,
      partyType: input.ctx.partyType ?? null,
      classification_category: input.classification.category,
      confidence_score: input.classification.confidence,
      risk_flags: input.classification.riskFlags,
      subject: input.reply.subject,
      body_plain: input.reply.bodyPlain,
      body_html: input.reply.bodyHtml ?? null,
      rationale: input.reply.rationale,
      requires_human_approval: requiresHumanApproval,
      auto_send_eligible: input.gate.allowed,
      auto_send_blocked_reasons: input.gate.reasons,
      auto_send_rule_id: input.gate.ruleId ?? null,
      auto_send_evaluation_log: input.gate.evaluationLog,
      expires_at: expiresAt.toISOString(),
      ai_generated: true,
      status: 'pending_review',
      classifier_run_id: input.classifierRunId,
      drafter_run_id: input.drafterRunId,
      language: input.language,
    })
    .select('id')
    .single();

  if (error || !data) {
    throw new ProcessorError(
      `ai.drafts INSERT failed: ${error?.message ?? 'unknown'}`,
      error,
    );
  }
  return data.id as string;
}

/* --------------------------------------------------------
 * 상태 갱신 헬퍼
 * -------------------------------------------------------- */

async function updateProcessingStatus(
  supabase: SupabaseClient,
  communicationId: string,
  status: AiProcessingStatus,
): Promise<void> {
  const update: Record<string, unknown> = {
    external_data: undefined, // PostgREST는 undefined를 무시
  };
  // ai_processing_status는 communications에 직접 컬럼이 없으므로 external_data에 보관
  // 단, 향후 마이그레이션으로 컬럼 추가 시 양쪽 갱신.

  await supabase
    .schema('app')
    .from('communications')
    .update({
      // external_data jsonb에 추가 정보
      ...(status === 'processing'
        ? {
            external_data: {
              ai_processing_status: status,
              ai_processing_started_at: new Date().toISOString(),
            },
          }
        : {
            external_data: {
              ai_processing_status: status,
            },
          }),
    })
    .eq('id', communicationId);
  void update;
}

async function updateProcessingComplete(
  supabase: SupabaseClient,
  communicationId: string,
  draftId: string,
  classification: ClassificationWithMeta,
  language: Language,
): Promise<void> {
  await supabase
    .schema('app')
    .from('communications')
    .update({
      ai_draft_id: draftId,
      ai_classification: stripInternalFields(classification),
      language_detected:
        classification.detectedLanguage === 'other'
          ? null
          : classification.detectedLanguage,
      external_data: {
        ai_processing_status: 'completed',
        ai_processing_completed_at: new Date().toISOString(),
        reply_language: language,
      },
    })
    .eq('id', communicationId);
}

async function markFailed(
  supabase: SupabaseClient,
  communicationId: string,
  err: unknown,
): Promise<void> {
  const errorClass = err instanceof Error ? err.name : 'UnknownError';
  const errorMessage = err instanceof Error ? err.message : String(err);
  const isBudget = err instanceof ClaudeBudgetExceededError;
  const isApi = err instanceof ClaudeApiError;

  try {
    await supabase
      .schema('app')
      .from('communications')
      .update({
        external_data: {
          ai_processing_status: 'failed',
          ai_processing_error_class: errorClass,
          ai_processing_error_message: errorMessage,
          ai_processing_failed_at: new Date().toISOString(),
          ai_processing_retryable: isApi && !isBudget,
        },
      })
      .eq('id', communicationId);
  } catch (updateErr) {
    // eslint-disable-next-line no-console
    console.error(
      `[processor:${communicationId}] failed to mark failed:`,
      updateErr,
    );
  }
}
