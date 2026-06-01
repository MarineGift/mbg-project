/**
 * lib/ai/claude-client.ts
 *
 * Single entry point for the Anthropic API.
 * All AI calls must go through this class so that ai.runs logging, PII masking, and cost tracking
 * are applied consistently.
 *
 * Do not call anthropic.messages.create() directly from outside.
 *
 * Main responsibilities:
 *   1. validate the model ID against a whitelist
 *   2. pre-check the daily budget
 *   3. PII masking/restoration
 *   4. call prompt-renderer (brand_voice + RAG + thread)
 *   5. retries (429/5xx exponential backoff, fallback model)
 *   6. cost calculation + ai.runs INSERT (both success and failure)
 *   7. JSON parsing (output_format='json' or agent.outputFormat='structured')
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
 * 1. Error classes
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
 * 2. Constants
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
 * 3. Helper functions
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
    applicablePartyTypes:
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
  // remove a ```json fence or a plain ``` fence
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
 * 4. ClaudeClient class
 * ============================================================ */

export interface ClaudeClientOptions {
  /** Used to inject the SDK in unit tests. */
  anthropicClient?: Anthropic;
  /**
   * Whether to auto-downgrade when the monthly cost exceeds the threshold.
   * Default true. Set to false in tests for deterministic behavior.
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
        maxRetries: 0, // disable SDK retries - controlled directly in this class
        timeout: HARD_TIMEOUT_MS,
      });
    this.enableMonthlyDowngrade = options.enableMonthlyDowngrade ?? true;
  }

  /**
   * Main call entry point.
   *
   * Stages:
   *   1. daily budget check
   *   2. evaluate monthly budget -> whether to downgrade
   *   3. look up the agent
   *   4. validate the model ID
   *   5. PII masking
   *   6. call prompt-renderer
   *   7. API call + retries
   *   8. PII restoration + JSON parsing
   *   9. cost calculation + ai.runs INSERT
   *  10. return the output
   */
  async complete(input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> {
    // ── [1] daily budget ──
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

    // ── [2] evaluate monthly budget -> downgrade decision ──
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

    // ── [3] look up the agent ──
    const agent = await this.loadAgent(input.agentRole);

    // ── [4] validate the model ──
    if (!SUPPORTED_MODELS.has(agent.model)) {
      throw new ClaudeInvalidModelError(agent.model);
    }
    if (
      agent.fallbackModel &&
      !SUPPORTED_MODELS.has(agent.fallbackModel)
    ) {
      throw new ClaudeInvalidModelError(agent.fallbackModel);
    }

    // apply downgrade
    let modelUsed: ClaudeModel = applyDowngrade(agent.model, costThreshold);

    // ── [5] PII masking ──
    const maskPiiEnabled = input.maskPii ?? agent.requirePiiMasking ?? true;
    const maskResult = maskPiiEnabled
      ? maskPii(input.inboundMessage)
      : {
          masked: input.inboundMessage,
          tokens: new Map() as PiiTokenMap,
          categories: [] as string[],
          tokenCount: 0,
        };

    // ── [6] prompt render ──
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

    // ── [7] API call + retries ──
    const startedAt = Date.now();
    let attempt = 0;
    let lastError: unknown;
    let response: Anthropic.Messages.Message | null = null;

    while (attempt < MAX_RETRY_ATTEMPTS && response === null) {
      try {
        response = await this.anthropic.messages.create({
          model: modelUsed,
          max_tokens: agent.maxTokens || DEFAULT_MAX_TOKENS,
          // Claude Opus 4.7+ does not support the temperature parameter (Anthropic policy change)
          ...(modelUsed === 'claude-opus-4-7'
            ? {}
            : { temperature: agent.temperature ?? DEFAULT_TEMPERATURE }),
          system: rendered.system,
          messages: rendered.messages,
        });
      } catch (err) {
        lastError = err;
        const apiError = this.normalizeError(err);

        // whether a retry is possible
        if (!isRetryableStatus(apiError.status)) {
          break; // fail immediately
        }

        // use the fallback model from the second retry onward
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

    // ── [8] failure path: record then throw ──
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

    // ── [9] success path: extract + restore + parse ──
    const rawContent = extractTextContent(response);
    const content = maskPiiEnabled
      ? restorePii(rawContent, maskResult.tokens)
      : rawContent;

    let parsedJson: object | undefined;
    if (input.outputFormat === 'json' || agent.outputFormat === 'structured') {
      parsedJson = tryParseJson(content);
      // JSON parse failure does not throw - the caller validates via the absence of parsedJson
    }

    // ── [10] cost calculation + ai.runs INSERT ──
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
   * look up the agent - role + organization_id + is_active=true,
   * the single highest version.
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
   * Normalize Anthropic SDK errors -> ClaudeApiError
   * -------------------------------------------------------- */
  private normalizeError(err: unknown): ClaudeApiError {
    if (err instanceof ClaudeApiError) return err;

    if (err instanceof Anthropic.APIError) {
      // extract the retry-after header (supports both a Headers object and a plain object)
      let retryAfter: number | undefined;
      const headers = (err as { headers?: unknown }).headers;
      if (headers) {
        let raw: string | null | undefined;
        if (typeof (headers as { get?: unknown }).get === 'function') {
          // Fetch Headers object
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

    // handle environments where the SDK doesn't throw timeouts as a separate class
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
