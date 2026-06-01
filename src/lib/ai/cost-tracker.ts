/**
 * lib/ai/cost-tracker.ts
 *
 * AI call cost calculation + ai.runs logging + daily/monthly budget enforcement.
 *
 * Every ClaudeClient.complete() call is recorded through this module via
 * - just before the call: checkDailyBudget()
 * - just after the call: recordRun()
 * as shown above.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import type { ClaudeModel, RecordRunInput } from '../../types/ai';

/* ============================================================
 * 1. Unit-price table (USD per 1M tokens, as of May 2026)
 * ----------------------------------------------------------
 * Must match the master system prompt §2.4.
 * ============================================================ */
export const MODEL_PRICING: Readonly<
  Record<ClaudeModel, { input: number; output: number }>
> = Object.freeze({
  'claude-opus-4-7': { input: 15.0, output: 75.0 },
  'claude-sonnet-4-6': { input: 3.0, output: 15.0 },
  'claude-haiku-4-5-20251001': { input: 0.8, output: 4.0 },
});

export class UnknownModelPricingError extends Error {
  constructor(public readonly model: string) {
    super(`No pricing defined for model: ${model}`);
    this.name = 'UnknownModelPricingError';
  }
}

/* ============================================================
 * 2. Cost calculation
 * ============================================================ */

/**
 * input/output token counts -> USD cost.
 * Models not in MODEL_PRICING throw.
 */
export function calculateCost(
  model: ClaudeModel | string,
  tokensIn: number,
  tokensOut: number,
): number {
  const pricing = MODEL_PRICING[model as ClaudeModel];
  if (!pricing) {
    throw new UnknownModelPricingError(model);
  }
  // unit price is per 1M tokens
  return (tokensIn * pricing.input + tokensOut * pricing.output) / 1_000_000;
}

/* ============================================================
 * 3. ai.runs INSERT
 * ----------------------------------------------------------
 * Called on all paths: success, failure, and retry.
 * Never propagates an exception to the caller even when the INSERT fails
 * (missing observability data must not block the business flow).
 *
 * Column mapping (code domain -> ai.runs SQL):
 *   - input.model         → model_used
 *   - input.tokensIn      -> input_tokens (the GENERATED tokens_in is unused)
 *   - input.tokensOut     → output_tokens
 *   - input.partyId/engagementId → related_entity_type + related_entity_id
 *   - input.retryCount/brandVoiceId/knowledgeChunkIds/errorStatus/traceLabel
 *       -> stored together inside the metadata jsonb field
 *   - input.status        -> mapped to the ai.run_status enum via mapRunStatusToDb()
 * ============================================================ */

/**
 * Map the domain RunStatus to a DB ai.run_status enum value.
 * budget_exceeded is not in ai.run_status, so it is stored as 'failed' but
 * preserved identifiably via metadata.error_class='ClaudeBudgetExceededError'.
 */
export function mapRunStatusToDb(status: import('../../types/ai').RunStatus): string {
  switch (status) {
    case 'success':
      return 'completed';
    case 'timeout':
      return 'timed_out';
    case 'budget_exceeded':
    case 'failed':
      return 'failed';
  }
}

export async function recordRun(
  supabase: SupabaseClient,
  organizationId: string,
  input: RecordRunInput,
): Promise<string> {
  try {
    // accumulate metadata: preserve domain fields inside the jsonb
    const metadata: Record<string, unknown> = {};
    if (input.retryCount !== undefined && input.retryCount > 0) {
      metadata.retry_count = input.retryCount;
    }
    if (input.brandVoiceId) {
      metadata.brand_voice_id = input.brandVoiceId;
    }
    if (input.knowledgeChunkIds && input.knowledgeChunkIds.length > 0) {
      metadata.knowledge_chunk_ids = input.knowledgeChunkIds;
    }
    if (input.errorStatus !== undefined && input.errorStatus !== null) {
      metadata.error_status = input.errorStatus;
    }
    if (input.traceLabel) {
      metadata.trace_label = input.traceLabel;
    }
    if (input.status === 'budget_exceeded') {
      // the domain budget_exceeded is stored as DB 'failed', so
      // record error_class so it can be distinguished during analysis.
      metadata.error_class = 'ClaudeBudgetExceededError';
    }

    // related_entity: engagement_id first, then party_id
    let relatedEntityType: string | null = null;
    let relatedEntityId: string | null = null;
    if (input.engagementId) {
      relatedEntityType = 'engagement';
      relatedEntityId = input.engagementId;
    } else if (input.partyId) {
      relatedEntityType = 'party';
      relatedEntityId = input.partyId;
    }

    const dbStatus = mapRunStatusToDb(input.status);

    const { data, error } = await supabase
      .schema('ai')
      .from('runs')
      .insert({
        organization_id: organizationId,
        agent_id: input.agentId,
        status: dbStatus,
        model_used: input.model,
        input_tokens: input.tokensIn,
        output_tokens: input.tokensOut,
        cost_usd: input.costUsd,
        latency_ms: input.latencyMs,
        pii_masked: input.piiMasked,
        pii_categories_detected: input.piiCategories,
        related_entity_type: relatedEntityType,
        related_entity_id: relatedEntityId,
        error_message: input.errorMessage ?? null,
        completed_at: dbStatus === 'running' ? null : new Date().toISOString(),
        metadata,
      })
      .select('id')
      .single();

    if (error || !data) {
      // eslint-disable-next-line no-console
      console.error('[cost-tracker.recordRun] ai.runs INSERT failed:', error);
      return '';
    }
    return data.id as string;
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[cost-tracker.recordRun] unexpected error:', err);
    return '';
  }
}

/* ============================================================
 * 4. Daily/monthly budget checks
 * ============================================================ */

export interface BudgetCheckResult {
  used: number;
  limit: number;
  allowed: boolean;
  period: 'daily' | 'monthly';
}

/**
 * Aggregate today's (00:00 - now) accumulated cost from ai.runs.
 * Compare against env.MAX_DAILY_AI_COST_USD.
 *
 * Safe policy on lookup failure: allowed=false (budget protection first).
 */
export async function checkDailyBudget(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<BudgetCheckResult> {
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  try {
    const { data, error } = await supabase
      .schema('ai')
      .from('runs')
      .select('cost_usd')
      .eq('organization_id', organizationId)
      .gte('created_at', startOfToday.toISOString());

    if (error) {
      // eslint-disable-next-line no-console
      console.error('[cost-tracker.checkDailyBudget] query failed:', error);
      return {
        used: 0,
        limit: env.MAX_DAILY_AI_COST_USD,
        allowed: false,
        period: 'daily',
      };
    }

    const used = (data ?? []).reduce(
      (sum, row) => sum + Number(row.cost_usd ?? 0),
      0,
    );

    return {
      used,
      limit: env.MAX_DAILY_AI_COST_USD,
      allowed: used < env.MAX_DAILY_AI_COST_USD,
      period: 'daily',
    };
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[cost-tracker.checkDailyBudget] unexpected error:', err);
    return {
      used: 0,
      limit: env.MAX_DAILY_AI_COST_USD,
      allowed: false,
      period: 'daily',
    };
  }
}

/**
 * Aggregate this month's (00:00 on the 1st - now) accumulated cost.
 * Used to trigger auto-downgrade for auto-send (Opus -> Sonnet when monthly $1,000 is reached).
 */
export async function checkMonthlyBudget(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<BudgetCheckResult> {
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  try {
    const { data, error } = await supabase
      .schema('ai')
      .from('runs')
      .select('cost_usd')
      .eq('organization_id', organizationId)
      .gte('created_at', startOfMonth.toISOString());

    if (error) {
      // eslint-disable-next-line no-console
      console.error(
        '[cost-tracker.checkMonthlyBudget] query failed:',
        error,
      );
      return {
        used: 0,
        limit: env.MAX_MONTHLY_AI_COST_USD,
        allowed: false,
        period: 'monthly',
      };
    }

    const used = (data ?? []).reduce(
      (sum, row) => sum + Number(row.cost_usd ?? 0),
      0,
    );

    return {
      used,
      limit: env.MAX_MONTHLY_AI_COST_USD,
      allowed: used < env.MAX_MONTHLY_AI_COST_USD,
      period: 'monthly',
    };
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[cost-tracker.checkMonthlyBudget] unexpected error:', err);
    return {
      used: 0,
      limit: env.MAX_MONTHLY_AI_COST_USD,
      allowed: false,
      period: 'monthly',
    };
  }
}

/* ============================================================
 * 5. Decide actions per cost tier
 * ----------------------------------------------------------
 * Master §4.5 - monthly $500 alert, $1,000 downgrade, $2,000 auto-send block.
 * This function only evaluates the policy; the actual actions (Slack alert, env toggle) are
 * handled by the caller.
 * ============================================================ */
export type CostThreshold =
  | 'normal'
  | 'alert_only'
  | 'force_downgrade'
  | 'block_auto_send';

export function evaluateMonthlyCostThreshold(monthlyUsed: number): CostThreshold {
  if (monthlyUsed >= 2000) return 'block_auto_send';
  if (monthlyUsed >= 1000) return 'force_downgrade';
  if (monthlyUsed >= 500) return 'alert_only';
  return 'normal';
}

/**
 * If the threshold is at or above force_downgrade, map the input model to a cheaper model.
 * Opus → Sonnet, Sonnet → Haiku.
 */
export function applyDowngrade(
  model: ClaudeModel,
  threshold: CostThreshold,
): ClaudeModel {
  if (threshold !== 'force_downgrade' && threshold !== 'block_auto_send') {
    return model;
  }
  if (model === 'claude-opus-4-7') return 'claude-sonnet-4-6';
  if (model === 'claude-sonnet-4-6') return 'claude-haiku-4-5-20251001';
  return model; // already the cheapest model
}
