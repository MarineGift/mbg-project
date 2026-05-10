import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import type { ClaudeModel, RunStatus } from '@/types/ai';

/**
 * 2026년 5월 기준 Anthropic 단가 (USD per 1M tokens). 마스터 §2.4와 일치.
 */
export const MODEL_PRICING: Readonly<Record<ClaudeModel, { input: number; output: number }>> = {
  'claude-opus-4-7': { input: 15.0, output: 75.0 },
  'claude-sonnet-4-6': { input: 3.0, output: 15.0 },
  'claude-haiku-4-5-20251001': { input: 0.8, output: 4.0 },
};

export function calculateCost(
  model: ClaudeModel,
  tokensIn: number,
  tokensOut: number,
): number {
  const pricing = MODEL_PRICING[model];
  if (!pricing) {
    throw new Error(`No pricing defined for model: ${model}`);
  }
  if (tokensIn < 0 || tokensOut < 0) {
    throw new Error(`Negative token count: in=${tokensIn} out=${tokensOut}`);
  }
  return (tokensIn * pricing.input + tokensOut * pricing.output) / 1_000_000;
}

export async function checkDailyBudget(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<{ used: number; limit: number; allowed: boolean }> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const { data, error } = await supabase
    .schema('ai')
    .from('runs')
    .select('cost_usd')
    .eq('organization_id', organizationId)
    .gte('created_at', today.toISOString());

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[checkDailyBudget] query failed → blocking:', error.message);
    return { used: 0, limit: env.MAX_DAILY_AI_COST_USD, allowed: false };
  }

  const used = (data ?? []).reduce(
    (sum, row) => sum + Number((row as { cost_usd?: number | string | null }).cost_usd ?? 0),
    0,
  );
  const limit = env.MAX_DAILY_AI_COST_USD;
  return { used, limit, allowed: used < limit };
}

export async function checkMonthlyBudget(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<{ used: number; limit: number; allowed: boolean }> {
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const { data, error } = await supabase
    .schema('ai')
    .from('runs')
    .select('cost_usd')
    .eq('organization_id', organizationId)
    .gte('created_at', startOfMonth.toISOString());

  if (error) {
    return { used: 0, limit: env.MAX_MONTHLY_AI_COST_USD, allowed: false };
  }

  const used = (data ?? []).reduce(
    (sum, row) => sum + Number((row as { cost_usd?: number | string | null }).cost_usd ?? 0),
    0,
  );
  const limit = env.MAX_MONTHLY_AI_COST_USD;
  return { used, limit, allowed: used < limit };
}

export interface RecordRunInput {
  /**
   * Agent UUID. ClaudeClient.complete가 agent를 로드하기 전에 사전 차단하는 경우
   * (예산 초과, agent_not_found)에는 null. 그 외 정상/실패 경로에는 항상 string.
   */
  agentId: string | null;
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
  caller?: string;
  metadata?: Record<string, unknown>;
}

export async function recordRun(
  supabase: SupabaseClient,
  organizationId: string,
  input: RecordRunInput,
): Promise<string> {
  try {
    const { data, error } = await supabase
      .schema('ai')
      .from('runs')
      .insert({
        organization_id: organizationId,
        agent_id: input.agentId,
        status: input.status,
        model: input.model,
        tokens_in: input.tokensIn,
        tokens_out: input.tokensOut,
        cost_usd: input.costUsd,
        latency_ms: input.latencyMs,
        pii_masked: input.piiMasked,
        pii_categories_detected: input.piiCategories,
        retry_count: input.retryCount,
        party_id: input.partyId ?? null,
        engagement_id: input.engagementId ?? null,
        brand_voice_id: input.brandVoiceId ?? null,
        knowledge_chunk_ids: input.knowledgeChunkIds ?? [],
        error_message: input.errorMessage ?? null,
        error_status: input.errorStatus ?? null,
        metadata: {
          caller: input.caller ?? null,
          ...(input.metadata ?? {}),
        },
      })
      .select('id')
      .single();

    if (error || !data) {
      // eslint-disable-next-line no-console
      console.error('[recordRun] failed to insert ai.runs:', error?.message);
      return '';
    }
    return String((data as { id: string }).id);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[recordRun] threw unexpectedly:', (e as Error).message);
    return '';
  }
}
