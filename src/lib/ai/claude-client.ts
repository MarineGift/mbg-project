/**
 * lib/ai/claude-client.ts
 *
 * Anthropic API의 단일 진입점.
 * 모든 AI 호출은 본 클래스를 거쳐야 ai.runs 기록·PII 마스킹·비용 추적이
 * 일관되게 적용된다.
 *
 * 외부에서 anthropic.messages.create() 직접 호출 금지.
 *
 * 주요 책임:
 *   1. 모델 ID 화이트리스트 검증
 *   2. 일일 예산 사전 체크
 *   3. PII 마스킹·복원
 *   4. prompt-renderer 호출 (brand_voice + RAG + thread)
 *   5. 재시도 (429/5xx exponential backoff, fallback 모델)
 *   6. 비용 계산 + ai.runs INSERT (성공/실패 모두)
 *   7. JSON 파싱 (output_format='json' 또는 agent.outputFormat='structured')
 */

import Anthropic from '@anthropic-ai/sdk';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import type {
  AgentRole,
  AgentRow,
  ClaudeCompleteInput,
  ClaudeCompleteOutput,
  ClaudeModel,
  Language,
  PartyTypeCode,
} from '../../types/ai';
import { maskPii, restorePii, type PiiTokenMap } from './pii-masker';
import { renderPrompt } from './prompt-renderer';
import {
  calculateCost,
  checkDailyBudget,
  checkMonthlyBudget,
  evaluateMonthlyCostThreshold,
  applyDowngrade,
  recordRun,
} from './cost-tracker';

/* ============================================================
 * 1. 에러 클래스
 * ============================================================ */

export class ClaudeApiError extends Error {
  public readonly status?: number;
  public readonly retryAfter?: number;
  public override readonly cause?: unknown;

  constructor(
    message: string,
    status?: number,
    retryAfter?: number,
    cause?: unknown,
  ) {
    super(message);
    this.name = 'ClaudeApiError';
    this.status = status;
    this.retryAfter = retryAfter;
    this.cause = cause;
  }
}

export class ClaudeBudgetExceededError extends Error {
  constructor(
    public readonly used: number,
    public readonly limit: number,
    public readonly period: 'daily' | 'monthly',
  ) {
    super(
      `Budget exceeded for ${period}: $${used.toFixed(2)} / $${limit.toFixed(2)}`,
    );
    this.name = 'ClaudeBudgetExceededError';
  }
}

export class ClaudeInvalidModelError extends Error {
  constructor(public readonly model: string) {
    super(`Unsupported Claude model: ${model}`);
    this.name = 'ClaudeInvalidModelError';
  }
}

export class ClaudeAgentNotFoundError extends Error {
  constructor(role: string, organizationId: string) {
    super(
      `Agent not found: role=${role} organization=${organizationId} (no active version)`,
    );
    this.name = 'ClaudeAgentNotFoundError';
  }
}

export class ClaudeTimeoutError extends ClaudeApiError {
  constructor(timeoutMs: number) {
    super(`Claude API timed out after ${timeoutMs}ms`, undefined, undefined);
    this.name = 'ClaudeTimeoutError';
  }
}

/* ============================================================
 * 2. 상수
 * ============================================================ */

const SUPPORTED_MODELS: ReadonlySet<ClaudeModel> = new Set<ClaudeModel>([
  'claude-opus-4-7',
  'claude-sonnet-4-6',
  'claude-haiku-4-5-20251001',
]);

const DEFAULT_MAX_TOKENS = 4096;
const DEFAULT_TEMPERATURE = 0.3;
const HARD_TIMEOUT_MS = 60_000;
const MAX_RETRY_ATTEMPTS = 3;

/* ============================================================
 * 3. 보조 함수
 * ============================================================ */

function isRetryableStatus(status: number | undefined): boolean {
  if (status === undefined) return false;
  return status === 429 || (status >= 500 && status < 600);
}

function backoffMs(attempt: number, retryAfter?: number): number {
  if (retryAfter !== undefined && retryAfter > 0) {
    return Math.min(retryAfter * 1000, 30_000);
  }
  // 1s, 2s, 4s
  return Math.pow(2, attempt) * 1000;
}

function dbRowToAgent(row: Record<string, unknown>): AgentRow {
  return {
    id: row.id as string,
    organizationId: row.organization_id as string,
    role: row.role as AgentRole,
    name: (row.name as string) ?? '',
    model: row.model as ClaudeModel,
    fallbackModel: (row.fallback_model as ClaudeModel | null) ?? undefined,
    temperature: Number(row.temperature ?? DEFAULT_TEMPERATURE),
    maxTokens: Number(row.max_tokens ?? DEFAULT_MAX_TOKENS),
    outputFormat: (row.output_format as 'text' | 'structured') ?? 'text',
    systemPrompt: (row.system_prompt as string) ?? '',
    applicableModules:
      (row.applicable_party_types as PartyTypeCode[] | null) ?? undefined,
    applicableLanguages:
      (row.applicable_languages as Language[] | null) ?? undefined,
    requirePiiMasking: (row.require_pii_masking as boolean | null) ?? true,
    knowledgeCollection:
      (row.knowledge_collection as string | null) ?? undefined,
    isActive: Boolean(row.is_active),
    version: Number(row.version ?? 1),
  };
}

function extractTextContent(message: Anthropic.Messages.Message): string {
  return message.content
    .filter((block): block is Anthropic.TextBlock => block.type === 'text')
    .map((block) => block.text)
    .join('\n');
}

function tryParseJson(content: string): object | undefined {
  // ```json fence 또는 일반 ``` fence 제거
  let cleaned = content.trim();
  cleaned = cleaned.replace(/^```(?:json)?\s*/i, '').replace(/\s*```\s*$/i, '');
  try {
    const parsed = JSON.parse(cleaned);
    if (parsed && typeof parsed === 'object') {
      return parsed as object;
    }
    return undefined;
  } catch {
    return undefined;
  }
}

/* ============================================================
 * 4. ClaudeClient 클래스
 * ============================================================ */

export interface ClaudeClientOptions {
  /** 단위 테스트에서 SDK를 주입할 때 사용. */
  anthropicClient?: Anthropic;
  /**
   * 월간 비용이 임계값을 초과한 경우 자동 다운그레이드 적용 여부.
   * 기본 true. 테스트에서 false로 설정해 결정론적 동작 확보.
   */
  enableMonthlyDowngrade?: boolean;
}

export class ClaudeClient {
  private readonly anthropic: Anthropic;
  private readonly enableMonthlyDowngrade: boolean;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
    options: ClaudeClientOptions = {},
  ) {
    this.anthropic =
      options.anthropicClient ??
      new Anthropic({
        apiKey: env.ANTHROPIC_API_KEY,
        maxRetries: 0, // SDK 재시도 비활성화 — 본 클래스에서 직접 제어
        timeout: HARD_TIMEOUT_MS,
      });
    this.enableMonthlyDowngrade = options.enableMonthlyDowngrade ?? true;
  }

  /**
   * 메인 호출 진입점.
   *
   * 단계:
   *   1. 일일 예산 체크
   *   2. 월간 예산 평가 → 다운그레이드 여부
   *   3. agent 조회
   *   4. 모델 ID 검증
   *   5. PII 마스킹
   *   6. prompt-renderer 호출
   *   7. API 호출 + 재시도
   *   8. PII 복원 + JSON 파싱
   *   9. 비용 계산 + ai.runs INSERT
   *  10. 출력 반환
   */
  async complete(input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> {
    // ── [1] 일일 예산 ─────────────────────────────────
    const dailyBudget = await checkDailyBudget(
      this.supabase,
      this.organizationId,
    );
    if (!dailyBudget.allowed) {
      throw new ClaudeBudgetExceededError(
        dailyBudget.used,
        dailyBudget.limit,
        'daily',
      );
    }

    // ── [2] 월간 예산 평가 → 다운그레이드 결정 ────────
    let costThreshold: 'normal' | 'alert_only' | 'force_downgrade' | 'block_auto_send' =
      'normal';
    if (this.enableMonthlyDowngrade) {
      const monthlyBudget = await checkMonthlyBudget(
        this.supabase,
        this.organizationId,
      );
      if (!monthlyBudget.allowed) {
        throw new ClaudeBudgetExceededError(
          monthlyBudget.used,
          monthlyBudget.limit,
          'monthly',
        );
      }
      costThreshold = evaluateMonthlyCostThreshold(monthlyBudget.used);
    }

    // ── [3] agent 조회 ─────────────────────────────────
    const agent = await this.loadAgent(input.agentRole);

    // ── [4] 모델 검증 ─────────────────────────────────
    if (!SUPPORTED_MODELS.has(agent.model)) {
      throw new ClaudeInvalidModelError(agent.model);
    }
    if (
      agent.fallbackModel &&
      !SUPPORTED_MODELS.has(agent.fallbackModel)
    ) {
      throw new ClaudeInvalidModelError(agent.fallbackModel);
    }

    // 다운그레이드 적용
    let modelUsed: ClaudeModel = applyDowngrade(agent.model, costThreshold);

    // ── [5] PII 마스킹 ─────────────────────────────────
    const maskPiiEnabled = input.maskPii ?? agent.requirePiiMasking ?? true;
    const maskResult = maskPiiEnabled
      ? maskPii(input.inboundMessage)
      : {
          masked: input.inboundMessage,
          tokens: new Map() as PiiTokenMap,
          categories: [] as string[],
          tokenCount: 0,
        };

    // ── [6] prompt 렌더 ───────────────────────────────
    const rendered = await renderPrompt({
      supabase: this.supabase,
      organizationId: this.organizationId,
      agent,
      partyId: input.partyId,
      engagementId: input.engagementId,
      inboundMessage: maskResult.masked,
      language: input.language,
      extraContext: input.extraContext,
    });

    // ── [7] API 호출 + 재시도 ─────────────────────────
    const startedAt = Date.now();
    let attempt = 0;
    let lastError: unknown;
    let response: Anthropic.Messages.Message | null = null;

    while (attempt < MAX_RETRY_ATTEMPTS && response === null) {
      try {
        response = await this.anthropic.messages.create({
          model: modelUsed,
          max_tokens: agent.maxTokens || DEFAULT_MAX_TOKENS,
          // Claude Opus 4.7+는 temperature 파라미터 미지원 (Anthropic 정책 변경)
          ...(modelUsed === 'claude-opus-4-7'
            ? {}
            : { temperature: agent.temperature ?? DEFAULT_TEMPERATURE }),
          system: rendered.system,
          messages: rendered.messages,
        });
      } catch (err) {
        lastError = err;
        const apiError = this.normalizeError(err);

        // 재시도 가능 여부
        if (!isRetryableStatus(apiError.status)) {
          break; // 즉시 실패
        }

        // 두 번째 재시도부터 fallback 모델
        if (
          attempt === 1 &&
          agent.fallbackModel &&
          SUPPORTED_MODELS.has(agent.fallbackModel) &&
          modelUsed !== agent.fallbackModel
        ) {
          modelUsed = agent.fallbackModel;
        }

        const delay = backoffMs(attempt, apiError.retryAfter);
        await new Promise((resolve) => setTimeout(resolve, delay));
        attempt += 1;
      }
    }

    const latencyMs = Date.now() - startedAt;

    // ── [8] 실패 경로: 기록 후 throw ─────────────────
    if (response === null) {
      const apiError = this.normalizeError(lastError);
      await recordRun(this.supabase, this.organizationId, {
        agentId: agent.id,
        status:
          apiError instanceof ClaudeTimeoutError ? 'timeout' : 'failed',
        model: modelUsed,
        tokensIn: 0,
        tokensOut: 0,
        costUsd: 0,
        latencyMs,
        piiMasked: maskPiiEnabled,
        piiCategories: maskResult.categories,
        retryCount: attempt,
        partyId: input.partyId,
        engagementId: input.engagementId,
        brandVoiceId: rendered.metadata.brandVoiceId,
        knowledgeChunkIds: rendered.metadata.knowledgeChunkIds,
        errorMessage: apiError.message,
        errorStatus: apiError.status,
        traceLabel: input.traceLabel,
      });
      throw apiError;
    }

    // ── [9] 성공 경로: 추출 + 복원 + 파싱 ────────────
    const rawContent = extractTextContent(response);
    const content = maskPiiEnabled
      ? restorePii(rawContent, maskResult.tokens)
      : rawContent;

    let parsedJson: object | undefined;
    if (input.outputFormat === 'json' || agent.outputFormat === 'structured') {
      parsedJson = tryParseJson(content);
      // JSON 파싱 실패는 throw하지 않음 — 호출자가 parsedJson 부재로 검증
    }

    // ── [10] 비용 계산 + ai.runs INSERT ──────────────
    const tokensIn = response.usage?.input_tokens ?? 0;
    const tokensOut = response.usage?.output_tokens ?? 0;
    let costUsd = 0;
    try {
      costUsd = calculateCost(modelUsed, tokensIn, tokensOut);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[claude-client] calculateCost failed:', err);
    }

    const runId = await recordRun(this.supabase, this.organizationId, {
      agentId: agent.id,
      status: 'success',
      model: modelUsed,
      tokensIn,
      tokensOut,
      costUsd,
      latencyMs,
      piiMasked: maskPiiEnabled,
      piiCategories: maskResult.categories,
      retryCount: attempt,
      partyId: input.partyId,
      engagementId: input.engagementId,
      brandVoiceId: rendered.metadata.brandVoiceId,
      knowledgeChunkIds: rendered.metadata.knowledgeChunkIds,
      traceLabel: input.traceLabel,
    });

    return {
      content,
      parsedJson,
      runId,
      agentId: agent.id,
      model: modelUsed,
      latencyMs,
      tokensIn,
      tokensOut,
      costUsd,
    };
  }

  /* --------------------------------------------------------
   * agent 조회 — role + organization_id + is_active=true,
   * 가장 높은 version 1건.
   * -------------------------------------------------------- */
  private async loadAgent(role: AgentRole): Promise<AgentRow> {
    const { data, error } = await this.supabase
      .schema('ai')
      .from('agents')
      .select(
        'id, organization_id, role, name, model, fallback_model, temperature, max_tokens, output_format, system_prompt, applicable_party_types, applicable_languages, require_pii_masking, knowledge_collection, is_active, version',
      )
      .eq('organization_id', this.organizationId)
      .eq('role', role)
      .eq('is_active', true)
      .order('version', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      throw new ClaudeApiError(
        `Agent lookup failed: role=${role}: ${error.message}`,
        undefined,
        undefined,
        error,
      );
    }
    if (!data) {
      throw new ClaudeAgentNotFoundError(role, this.organizationId);
    }
    return dbRowToAgent(data as Record<string, unknown>);
  }

  /* --------------------------------------------------------
   * Anthropic SDK 에러 → ClaudeApiError 정규화
   * -------------------------------------------------------- */
  private normalizeError(err: unknown): ClaudeApiError {
    if (err instanceof ClaudeApiError) return err;

    if (err instanceof Anthropic.APIError) {
      // retry-after 헤더 추출 (Headers 객체 또는 plain object 모두 지원)
      let retryAfter: number | undefined;
      const headers = (err as { headers?: unknown }).headers;
      if (headers) {
        let raw: string | null | undefined;
        if (typeof (headers as { get?: unknown }).get === 'function') {
          // Fetch Headers 객체
          const h = headers as Headers;
          raw = h.get('retry-after') ?? h.get('Retry-After') ?? h.get('x-retry-after');
        } else if (typeof headers === 'object') {
          // plain object
          const h = headers as Record<string, string | undefined>;
          raw = h['retry-after'] ?? h['Retry-After'] ?? h['x-retry-after'];
        }
        if (raw) {
          const n = Number(raw);
          if (!Number.isNaN(n)) retryAfter = n;
        }
      }
      return new ClaudeApiError(err.message, err.status, retryAfter, err);
    }

    // SDK가 timeout을 별도 클래스로 던지지 않는 환경 대응
    if (err instanceof Error) {
      if (
        /timeout|timed out|aborted/i.test(err.message) ||
        err.name === 'AbortError'
      ) {
        return new ClaudeTimeoutError(HARD_TIMEOUT_MS);
      }
      return new ClaudeApiError(err.message, undefined, undefined, err);
    }
    return new ClaudeApiError(String(err));
  }
}
