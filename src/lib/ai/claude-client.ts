import Anthropic from '@anthropic-ai/sdk';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import {
  type AgentRow,
  type AgentRole,
  type ClaudeCompleteInput,
  type ClaudeCompleteOutput,
  type ClaudeModel,
  type RunStatus,
  isSupportedClaudeModel,
  toAgentRow,
} from '@/types/ai';
import { maskPii, restorePii, type PiiTokenMap } from './pii-masker';
import { renderPrompt } from './prompt-renderer';
import {
  calculateCost,
  checkDailyBudget,
  checkMonthlyBudget,
  recordRun,
} from './cost-tracker';

// ───────────────────────────────────────────────────────────────────
// 에러
// ───────────────────────────────────────────────────────────────────

export class ClaudeApiError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
    public readonly retryAfter?: number,
    public readonly cause?: unknown,
  ) {
    super(message);
    this.name = 'ClaudeApiError';
  }
}

export class ClaudeBudgetExceededError extends Error {
  constructor(
    public readonly used: number,
    public readonly limit: number,
    public readonly period: 'daily' | 'monthly',
  ) {
    super(
      `Budget exceeded for ${period}: ${used.toFixed(2)} / ${limit.toFixed(2)} USD`,
    );
    this.name = 'ClaudeBudgetExceededError';
  }
}

export class ClaudeInvalidModelError extends Error {
  constructor(public readonly model: string) {
    super(`Unsupported Claude model: ${model} (allowed: claude-opus-4-7 / claude-sonnet-4-6 / claude-haiku-4-5-20251001)`);
    this.name = 'ClaudeInvalidModelError';
  }
}

export class ClaudeAgentNotFoundError extends Error {
  constructor(public readonly role: AgentRole, public readonly organizationId: string) {
    super(`Agent not found: role=${role} organization=${organizationId}`);
    this.name = 'ClaudeAgentNotFoundError';
  }
}

// ───────────────────────────────────────────────────────────────────
// ClaudeClient
// ───────────────────────────────────────────────────────────────────

export class ClaudeClient {
  private readonly anthropic: Anthropic;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
    private readonly generateEmbedding?: (text: string) => Promise<number[]>,
    anthropicClient?: Anthropic,
  ) {
    this.anthropic =
      anthropicClient ??
      new Anthropic({
        apiKey: env.ANTHROPIC_API_KEY,
        maxRetries: 0,
        timeout: env.CLAUDE_HARD_TIMEOUT_MS,
      });
  }

  async complete(input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> {
    // 1. 예산 체크
    const daily = await checkDailyBudget(this.supabase, this.organizationId);
    if (!daily.allowed) {
      await this.recordPreflightBlock({
        agentId: null,
        status: 'budget_exceeded',
        model: 'unknown',
        errorMessage: `daily budget exceeded: ${daily.used.toFixed(2)} / ${daily.limit.toFixed(2)} USD`,
        caller: input.caller,
        partyId: input.partyId,
        engagementId: input.engagementId,
      });
      throw new ClaudeBudgetExceededError(daily.used, daily.limit, 'daily');
    }
    const monthly = await checkMonthlyBudget(this.supabase, this.organizationId);
    if (!monthly.allowed) {
      await this.recordPreflightBlock({
        agentId: null,
        status: 'budget_exceeded',
        model: 'unknown',
        errorMessage: `monthly budget exceeded: ${monthly.used.toFixed(2)} / ${monthly.limit.toFixed(2)} USD`,
        caller: input.caller,
        partyId: input.partyId,
        engagementId: input.engagementId,
      });
      throw new ClaudeBudgetExceededError(monthly.used, monthly.limit, 'monthly');
    }

    // 2. agent 조회
    let agent: AgentRow;
    try {
      agent = await this.loadAgent(input.agentRole, input.language, input.module);
    } catch (err) {
      // loadAgent는 두 가지 사유로 throw할 수 있음:
      //   (a) ClaudeAgentNotFoundError — DB에 row가 없음
      //   (b) toAgentRow의 일반 Error — DB에 row는 있으나 model 컬럼이 비표준 ID
      // 두 경우 모두 ai.runs(status=failed)에 best-effort로 기록한 뒤 re-throw.
      const errorMessage = err instanceof ClaudeAgentNotFoundError
        ? `agent_not_found: role=${input.agentRole}`
        : `agent_load_failed: ${(err as Error).message}`;
      await this.recordPreflightBlock({
        agentId: null,
        status: 'failed',
        model: 'unknown',
        errorMessage,
        caller: input.caller,
        partyId: input.partyId,
        engagementId: input.engagementId,
      });
      throw err;
    }
    if (!isSupportedClaudeModel(agent.model)) {
      await this.recordPreflightBlock({
        agentId: agent.id,
        status: 'failed',
        model: agent.model,
        errorMessage: `Unsupported model on agent: ${agent.model}`,
        caller: input.caller,
        partyId: input.partyId,
        engagementId: input.engagementId,
      });
      throw new ClaudeInvalidModelError(agent.model);
    }
    if (agent.fallbackModel && !isSupportedClaudeModel(agent.fallbackModel)) {
      await this.recordPreflightBlock({
        agentId: agent.id,
        status: 'failed',
        model: agent.fallbackModel,
        errorMessage: `Unsupported fallback_model on agent: ${agent.fallbackModel}`,
        caller: input.caller,
        partyId: input.partyId,
        engagementId: input.engagementId,
      });
      throw new ClaudeInvalidModelError(agent.fallbackModel);
    }

    // 3. PII 마스킹
    const maskPiiEnabled = input.maskPii ?? agent.requirePiiMasking ?? true;
    const maskResult = maskPiiEnabled
      ? maskPii(input.inboundMessage)
      : {
          masked: input.inboundMessage,
          tokens: new Map() as PiiTokenMap,
          categories: [] as string[],
        };

    // 4. 프롬프트 렌더
    const rendered = await renderPrompt({
      supabase: this.supabase,
      organizationId: this.organizationId,
      agent,
      partyId: input.partyId,
      engagementId: input.engagementId,
      inboundMessage: maskResult.masked,
      language: input.language,
      module: input.module,
      generateEmbedding: this.generateEmbedding,
    });

    // 5. API 호출
    const startedAt = Date.now();
    const callResult = await this.callWithRetries(agent, rendered);
    const latencyMs = Date.now() - startedAt;

    // 6. 실패 경로
    if (callResult.kind === 'failed') {
      await recordRun(this.supabase, this.organizationId, {
        agentId: agent.id,
        status: callResult.timedOut ? 'timeout' : 'failed',
        model: callResult.lastModelTried,
        tokensIn: 0,
        tokensOut: 0,
        costUsd: 0,
        latencyMs,
        piiMasked: maskPiiEnabled,
        piiCategories: maskResult.categories,
        retryCount: callResult.retryCount,
        partyId: input.partyId,
        engagementId: input.engagementId,
        brandVoiceId: rendered.metadata.brandVoiceId,
        knowledgeChunkIds: rendered.metadata.knowledgeChunkIds,
        errorMessage: callResult.error.message,
        errorStatus: callResult.error.status,
        caller: input.caller,
      });
      throw callResult.error;
    }

    // 7. 응답 추출 + PII 복원
    const rawContent = callResult.response.content
      .filter((block): block is Anthropic.TextBlock => block.type === 'text')
      .map((block) => block.text)
      .join('\n');
    const content = maskPiiEnabled ? restorePii(rawContent, maskResult.tokens) : rawContent;

    // 8. JSON 파싱
    let parsedJson: object | undefined;
    if (input.outputFormat === 'json' || agent.outputFormat === 'structured') {
      parsedJson = tryParseJson(content);
    }

    // 9. 비용 + ai.runs INSERT
    const tokensIn = callResult.response.usage.input_tokens;
    const tokensOut = callResult.response.usage.output_tokens;
    const costUsd = calculateCost(callResult.modelUsed, tokensIn, tokensOut);

    const runId = await recordRun(this.supabase, this.organizationId, {
      agentId: agent.id,
      status: 'success',
      model: callResult.modelUsed,
      tokensIn,
      tokensOut,
      costUsd,
      latencyMs,
      piiMasked: maskPiiEnabled,
      piiCategories: maskResult.categories,
      retryCount: callResult.retryCount,
      partyId: input.partyId,
      engagementId: input.engagementId,
      brandVoiceId: rendered.metadata.brandVoiceId,
      knowledgeChunkIds: rendered.metadata.knowledgeChunkIds,
      caller: input.caller,
      metadata: {
        thread_communication_ids: rendered.metadata.threadCommunicationIds,
        fallback_used: callResult.modelUsed !== agent.model,
      },
    });

    return {
      content,
      parsedJson,
      runId,
      model: callResult.modelUsed,
      latencyMs,
      tokensIn,
      tokensOut,
      costUsd,
      retryCount: callResult.retryCount,
    };
  }

  /**
   * 사전 차단 이벤트(예산 초과·invalid model·agent_not_found)를 ai.runs에 기록.
   * tokensIn/Out·costUsd·latencyMs는 모두 0 (실제 API 호출 없음).
   * recordRun 자체의 실패는 swallow되며 throw하지 않음 — 차단 이벤트의 추적성을
   * 위해 best-effort로만 기록한다.
   */
  private async recordPreflightBlock(args: {
    agentId: string | null;
    status: RunStatus;
    model: string;
    errorMessage: string;
    caller?: string;
    partyId?: string;
    engagementId?: string;
  }): Promise<void> {
    await recordRun(this.supabase, this.organizationId, {
      agentId: args.agentId,
      status: args.status,
      model: args.model,
      tokensIn: 0,
      tokensOut: 0,
      costUsd: 0,
      latencyMs: 0,
      piiMasked: false,
      piiCategories: [],
      retryCount: 0,
      partyId: args.partyId,
      engagementId: args.engagementId,
      errorMessage: args.errorMessage,
      caller: args.caller,
      metadata: { preflight_block: true },
    });
  }

  private async loadAgent(
    role: AgentRole,
    language: 'ko' | 'en' | 'ja' | undefined,
    module: string | undefined,
  ): Promise<AgentRow> {
    let query = this.supabase
      .schema('ai')
      .from('agents')
      .select('*')
      .eq('organization_id', this.organizationId)
      .eq('role', role)
      .eq('is_active', true)
      .order('version', { ascending: false })
      .limit(1);

    if (language) {
      query = query.or(
        `applicable_languages.cs.{${language}},applicable_languages.eq.{}`,
      );
    }
    if (module) {
      query = query.or(
        `applicable_modules.cs.{${module}},applicable_modules.eq.{}`,
      );
    }

    const { data, error } = await query.maybeSingle();
    if (error || !data) {
      throw new ClaudeAgentNotFoundError(role, this.organizationId);
    }
    return toAgentRow(data as Record<string, unknown>);
  }

  private async callWithRetries(
    agent: AgentRow,
    rendered: { system: string; messages: Anthropic.Messages.MessageParam[] },
  ): Promise<CallResult> {
    const maxRetries = env.CLAUDE_MAX_RETRIES;
    let modelUsed: ClaudeModel = agent.model;
    let attempt = 0;
    let lastError: ClaudeApiError | null = null;
    let fallbackTried = false;
    let timedOut = false;

    while (attempt < maxRetries) {
      try {
        const response = await this.anthropic.messages.create({
          model: modelUsed,
          max_tokens: agent.maxTokens,
          temperature: agent.temperature,
          system: rendered.system,
          messages: rendered.messages,
        });
        return {
          kind: 'success',
          response,
          modelUsed,
          retryCount: attempt,
        };
      } catch (err) {
        lastError = this.normalizeError(err);
        timedOut = isTimeoutError(err);

        const isRetryable =
          lastError.status === 429
          || (lastError.status !== undefined && lastError.status >= 500)
          || timedOut;

        if (!isRetryable) {
          if (!fallbackTried && agent.fallbackModel && agent.fallbackModel !== modelUsed) {
            fallbackTried = true;
            modelUsed = agent.fallbackModel;
            attempt += 1;
            continue;
          }
          break;
        }

        attempt += 1;
        if (attempt < maxRetries) {
          const delayMs = lastError.retryAfter
            ? Math.min(lastError.retryAfter * 1000, 30_000)
            : 1000 * Math.pow(2, attempt - 1);
          await sleep(delayMs);
        } else if (!fallbackTried && agent.fallbackModel && agent.fallbackModel !== modelUsed) {
          fallbackTried = true;
          modelUsed = agent.fallbackModel;
          attempt = 0;
          continue;
        }
      }
    }

    return {
      kind: 'failed',
      error: lastError ?? new ClaudeApiError('Unknown failure', undefined, undefined),
      lastModelTried: modelUsed,
      retryCount: attempt,
      timedOut,
    };
  }

  private normalizeError(err: unknown): ClaudeApiError {
    if (err instanceof ClaudeApiError) return err;

    if (typeof err === 'object' && err !== null) {
      const e = err as { status?: number; message?: string; headers?: Record<string, string> };
      const status = typeof e.status === 'number' ? e.status : undefined;
      const retryAfterRaw = e.headers?.['retry-after'];
      const retryAfter = retryAfterRaw ? parseInt(retryAfterRaw, 10) : undefined;
      return new ClaudeApiError(
        e.message ?? 'Anthropic API error',
        status,
        Number.isFinite(retryAfter) ? retryAfter : undefined,
        err,
      );
    }
    return new ClaudeApiError(String(err), undefined, undefined, err);
  }
}

// ───────────────────────────────────────────────────────────────────
// 헬퍼
// ───────────────────────────────────────────────────────────────────

type CallResult =
  | {
      kind: 'success';
      response: Anthropic.Messages.Message;
      modelUsed: ClaudeModel;
      retryCount: number;
    }
  | {
      kind: 'failed';
      error: ClaudeApiError;
      lastModelTried: ClaudeModel;
      retryCount: number;
      timedOut: boolean;
    };

function tryParseJson(text: string): object | undefined {
  const cleaned = text.replace(/```(?:json)?\s*([\s\S]*?)\s*```/g, '$1').trim();
  try {
    const parsed = JSON.parse(cleaned);
    return typeof parsed === 'object' && parsed !== null ? (parsed as object) : undefined;
  } catch {
    return undefined;
  }
}

function isTimeoutError(err: unknown): boolean {
  if (typeof err !== 'object' || err === null) return false;
  const e = err as { name?: string; message?: string; code?: string };
  return (
    e.code === 'ETIMEDOUT'
    || e.code === 'ESOCKETTIMEDOUT'
    || e.name === 'AbortError'
    || (typeof e.message === 'string' && /timeout/i.test(e.message))
  );
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
