/**
 * lib/ai/cost-tracker.ts
 *
 * AI 호출 비용 계산 + ai.runs 기록 + 일일·월간 예산 강제.
 *
 * 모든 ClaudeClient.complete() 호출은 본 모듈을 거쳐
 * - 호출 직전: checkDailyBudget()
 * - 호출 직후: recordRun()
 * 으로 기록된다.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import type { ClaudeModel, RecordRunInput } from '../../types/ai';

/* ============================================================
 * 1. 단가 테이블 (USD per 1M tokens, 2026년 5월 기준)
 * ----------------------------------------------------------
 * 마스터 시스템 프롬프트 §2.4와 일치해야 한다.
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
 * 2. 비용 계산
 * ============================================================ */

/**
 * 입력·출력 토큰 수 → USD 비용.
 * MODEL_PRICING에 없는 모델은 throw.
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
  // 단가는 per 1M tokens
  return (tokensIn * pricing.input + tokensOut * pricing.output) / 1_000_000;
}

/* ============================================================
 * 3. ai.runs INSERT
 * ----------------------------------------------------------
 * 성공·실패·재시도 모든 경로에서 호출된다.
 * INSERT 실패 시에도 절대 caller로 예외를 propagate하지 않음
 * (관측 데이터 누락이 비즈니스 흐름을 막아서는 안 됨).
 *
 * 컬럼 매핑 (코드 도메인 → ai.runs SQL):
 *   - input.model         → model_used
 *   - input.tokensIn      → input_tokens (GENERATED tokens_in 미사용)
 *   - input.tokensOut     → output_tokens
 *   - input.partyId/engagementId → related_entity_type + related_entity_id
 *   - input.retryCount/brandVoiceId/knowledgeChunkIds/errorStatus/traceLabel
 *       → metadata jsonb 필드 안에 함께 저장
 *   - input.status        → mapRunStatusToDb()로 ai.run_status enum 매핑
 * ============================================================ */

/**
 * 도메인 RunStatus를 DB ai.run_status enum 값으로 매핑.
 * budget_exceeded는 ai.run_status에 없으므로 'failed'로 저장하되
 * metadata.error_class='ClaudeBudgetExceededError'로 식별 가능하게 보존.
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
    // metadata 누적: 도메인 필드를 jsonb 안에 보존
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
      // 도메인 budget_exceeded는 DB 'failed'로 저장되므로
      // 분석 시 구분할 수 있도록 error_class를 기록.
      metadata.error_class = 'ClaudeBudgetExceededError';
    }

    // related_entity: engagement_id 우선, 그 다음 party_id
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
 * 4. 일일·월간 예산 체크
 * ============================================================ */

export interface BudgetCheckResult {
  used: number;
  limit: number;
  allowed: boolean;
  period: 'daily' | 'monthly';
}

/**
 * 오늘(00:00 ~ 현재) 누적 비용을 ai.runs에서 집계.
 * env.MAX_DAILY_AI_COST_USD와 비교.
 *
 * 조회 실패 시 안전 정책: allowed=false (예산 보호 우선).
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
 * 이번 달(1일 00:00 ~ 현재) 누적 비용 집계.
 * 자동발송 자동 다운그레이드(월 $1,000 도달 시 Opus → Sonnet) 트리거에 사용.
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
 * 5. 비용 단계별 액션 결정
 * ----------------------------------------------------------
 * 마스터 §4.5 — 월 $500 알림, $1,000 다운그레이드, $2,000 자동발송 차단.
 * 본 함수는 정책 평가만 수행하고, 실제 액션(Slack alert, env 토글)은
 * 호출자가 처리한다.
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
 * threshold가 force_downgrade 이상이면 입력 모델을 더 저렴한 모델로 매핑.
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
  return model; // 이미 가장 저렴한 모델
}
