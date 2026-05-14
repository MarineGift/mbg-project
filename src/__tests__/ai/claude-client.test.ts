/**
 * __tests__/ai/claude-client.test.ts
 *
 * ClaudeClient.complete()의 핵심 보장:
 *   1. 일일 예산 초과 시 ClaudeBudgetExceededError throw
 *   2. agent.model이 SUPPORTED_MODELS에 없으면 ClaudeInvalidModelError throw
 *   3. 429/5xx에 exponential backoff, 두 번째 시도부터 fallback 모델 사용
 *   4. 4xx (재시도 불가)는 즉시 throw + ai.runs status='failed' 기록
 *   5. 성공 시 ai.runs status='success' 기록 + cost 계산 정확
 *   6. PII 마스킹 적용 후 응답에서 복원
 *   7. JSON output_format 시 parsedJson 채움
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import Anthropic from '@anthropic-ai/sdk';
import {
  ClaudeClient,
  ClaudeApiError,
  ClaudeBudgetExceededError,
  ClaudeInvalidModelError,
  ClaudeAgentNotFoundError,
} from '../../lib/ai/claude-client';
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';

// prompt-renderer는 OpenAI 호출이 있으므로 항상 mock
vi.mock('../../lib/ai/prompt-renderer', () => ({
  renderPrompt: vi.fn(async () => ({
    system: 'You are a classifier.',
    messages: [{ role: 'user', content: '{"inbound":"test"}' }],
    metadata: {
      brandVoiceId: 'bv-1',
      knowledgeChunkIds: ['kc-1', 'kc-2'],
      threadIds: [],
      embeddingTokens: 50,
    },
  })),
}));

interface FakeAnthropicOpts {
  responses?: Array<
    | { type: 'success'; content: string; tokensIn?: number; tokensOut?: number }
    | { type: 'error'; status: number; retryAfter?: number; message?: string }
  >;
}

function buildFakeAnthropic(opts: FakeAnthropicOpts): Anthropic {
  const responses = [...(opts.responses ?? [])];
  return {
    messages: {
      create: vi.fn(async () => {
        const r = responses.shift();
        if (!r) throw new Error('no more fake responses configured');
        if (r.type === 'error') {
          // 실제 Anthropic.APIError 인스턴스 — instanceof 검사 통과
          const headers = new Headers();
          if (r.retryAfter !== undefined) {
            headers.set('retry-after', String(r.retryAfter));
          }
          throw new Anthropic.APIError(
            r.status,
            undefined,
            r.message ?? `HTTP ${r.status}`,
            headers,
          );
        }
        return {
          id: 'msg_test',
          type: 'message',
          role: 'assistant',
          content: [{ type: 'text', text: r.content }],
          model: 'claude-haiku-4-5-20251001',
          stop_reason: 'end_turn',
          usage: {
            input_tokens: r.tokensIn ?? 100,
            output_tokens: r.tokensOut ?? 50,
          },
        };
      }),
    },
  } as unknown as Anthropic;
}

const orgId = 'org-1';

const haikuAgentRow = {
  id: 'agent-classifier-1',
  organization_id: orgId,
  role: 'classifier',
  name: 'Email Classifier',
  model: 'claude-haiku-4-5-20251001',
  fallback_model: 'claude-sonnet-4-6',
  temperature: 0.2,
  max_tokens: 1024,
  output_format: 'structured',
  system_prompt: 'You are a classifier.',
  applicable_modules: ['investor', 'paper_mill'],
  applicable_languages: ['ko', 'en', 'ja'],
  require_pii_masking: true,
  knowledge_collection: null,
  is_active: true,
  version: 1,
};

function buildSupabase(opts: {
  todayCost?: number;
  monthCost?: number;
  agentRow?: object | null;
  runInsertId?: string;
}): MockSupabase {
  // Daily cost = 호출 1: today rows, Monthly cost = 호출 2: month rows
  // 본 mock은 두 호출 모두 같은 결과 반환 (테스트에서 cost를 분리해야 할 때는
  // selectList를 동적으로 다른 응답 줘야 함)
  const todayRows = Array.from(
    { length: Math.min(opts.todayCost ?? 0, 100) > 0 ? 1 : 0 },
    () => ({ cost_usd: opts.todayCost ?? 0 }),
  );
  void opts.monthCost;
  return buildSupabaseMock({
    'ai.runs': {
      selectList: { data: todayRows },
      insertSingle: { data: { id: opts.runInsertId ?? 'run-1' } },
    },
    'ai.agents': {
      selectMaybeSingle: { data: opts.agentRow !== undefined ? opts.agentRow : haikuAgentRow },
    },
  });
}

describe('ClaudeClient — model validation', () => {
  it('throws ClaudeInvalidModelError when agent.model is unsupported', async () => {
    const supabase = buildSupabase({
      agentRow: { ...haikuAgentRow, model: 'claude-3-haiku' }, // 구버전!
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: buildFakeAnthropic({ responses: [] }),
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'test',
        outputFormat: 'json',
      }),
    ).rejects.toBeInstanceOf(ClaudeInvalidModelError);
  });

  it('throws ClaudeAgentNotFoundError when no active agent', async () => {
    const supabase = buildSupabase({ agentRow: null });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: buildFakeAnthropic({ responses: [] }),
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'test',
      }),
    ).rejects.toBeInstanceOf(ClaudeAgentNotFoundError);
  });
});

describe('ClaudeClient — budget enforcement', () => {
  it('throws ClaudeBudgetExceededError when daily limit exceeded', async () => {
    // setupFiles의 MAX_DAILY_AI_COST_USD=10. todayCost=15 → 초과
    const supabase = buildSupabase({ todayCost: 15 });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: buildFakeAnthropic({ responses: [] }),
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'test',
      }),
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);
  });
});

describe('ClaudeClient — successful call', () => {
  let supabase: MockSupabase;

  beforeEach(() => {
    supabase = buildSupabase({});
  });

  it('records ai.runs with success status and computes cost', async () => {
    const fake = buildFakeAnthropic({
      responses: [
        {
          type: 'success',
          content: '{"category":"information_request","confidence":0.95}',
          tokensIn: 1000,
          tokensOut: 500,
        },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: '안녕하세요, 가격이 궁금합니다.',
      outputFormat: 'json',
      language: 'ko',
    });

    expect(result.runId).toBe('run-1');
    expect(result.model).toBe('claude-haiku-4-5-20251001');
    expect(result.tokensIn).toBe(1000);
    expect(result.tokensOut).toBe(500);
    // Haiku: $0.8 in / $4 out per 1M
    // (1000 * 0.8 + 500 * 4) / 1_000_000 = 0.0008 + 0.002 = 0.0028
    expect(result.costUsd).toBeCloseTo(0.0028, 6);

    // parsedJson 채워짐
    expect(result.parsedJson).toEqual({
      category: 'information_request',
      confidence: 0.95,
    });

    // ai.runs INSERT — DB 컬럼명·매핑 검증
    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    expect(runInserts).toHaveLength(1);
    const payload = runInserts[0]?.payload as Record<string, unknown>;
    // RunStatus 'success' → DB 'completed'
    expect(payload.status).toBe('completed');
    expect(payload.model_used).toBe('claude-haiku-4-5-20251001');
    expect(payload.input_tokens).toBe(1000);
    expect(payload.output_tokens).toBe(500);
    expect(payload.pii_masked).toBe(true);
    // brand_voice_id·knowledge_chunk_ids는 metadata jsonb로 이동
    const meta = payload.metadata as Record<string, unknown>;
    expect(meta.brand_voice_id).toBe('bv-1');
    expect(meta.knowledge_chunk_ids).toEqual(['kc-1', 'kc-2']);
    // completed_at도 채워짐 (status !== 'running')
    expect(typeof payload.completed_at).toBe('string');
  });

  it('strips ```json fence from response', async () => {
    const fake = buildFakeAnthropic({
      responses: [
        {
          type: 'success',
          content: '```json\n{"category":"meeting_scheduling","confidence":0.9}\n```',
        },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });
    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'meeting?',
      outputFormat: 'json',
    });
    expect((result.parsedJson as Record<string, unknown>)?.category).toBe(
      'meeting_scheduling',
    );
  });

  it('restores PII tokens in response content', async () => {
    const fake = buildFakeAnthropic({
      responses: [
        {
          type: 'success',
          // AI가 마스킹된 토큰을 그대로 출력했다고 가정
          content: 'Phone {{PII_001}} verified.',
        },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: '연락처: 010-1234-5678 입니다',
      outputFormat: 'text',
    });
    // 토큰이 원문(010-1234-5678)으로 복원되어야 함
    expect(result.content).toContain('010-1234-5678');
    expect(result.content).not.toContain('{{PII_001}}');
  });
});

describe('ClaudeClient — retry logic', () => {
  let supabase: MockSupabase;

  beforeEach(() => {
    supabase = buildSupabase({});
  });

  it('retries on 429 then succeeds', async () => {
    const fake = buildFakeAnthropic({
      responses: [
        { type: 'error', status: 429, retryAfter: 0 },
        { type: 'success', content: '{"ok":true}' },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'hi',
      outputFormat: 'json',
    });
    expect(result.parsedJson).toEqual({ ok: true });
    expect((fake.messages.create as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(2);

    // ai.runs INSERT는 1회 (성공 시점만), retry_count=1
    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    expect(runInserts).toHaveLength(1);
    const payload = runInserts[0]?.payload as Record<string, unknown>;
    expect(payload.status).toBe('completed');
    const meta = payload.metadata as Record<string, unknown>;
    expect(meta.retry_count).toBe(1);
  });

  it('switches to fallback model on second retry attempt', async () => {
    const fake = buildFakeAnthropic({
      responses: [
        { type: 'error', status: 503 }, // attempt 0
        { type: 'error', status: 503 }, // attempt 1 → fallback 적용
        { type: 'success', content: 'ok' }, // attempt 2 — fallback model로 성공
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'hi',
    });
    // 두 번째 재시도부터 fallback 모델(sonnet) 사용
    expect(result.model).toBe('claude-sonnet-4-6');

    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    expect(runInserts).toHaveLength(1);
    expect((runInserts[0]?.payload as Record<string, unknown>).status).toBe('completed');
  });

  it('does NOT retry on 4xx and records failure', async () => {
    const fake = buildFakeAnthropic({
      responses: [{ type: 'error', status: 400, message: 'Bad Request' }],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'hi',
      }),
    ).rejects.toBeInstanceOf(ClaudeApiError);

    expect((fake.messages.create as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(1);

    // ai.runs INSERT — DB status='failed' (도메인 'failed' 그대로), error_status는 metadata
    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    expect(runInserts).toHaveLength(1);
    const payload = runInserts[0]?.payload as Record<string, unknown>;
    expect(payload.status).toBe('failed');
    const meta = payload.metadata as Record<string, unknown>;
    expect(meta.error_status).toBe(400);
  });

  it('gives up after 3 attempts on persistent 5xx', async () => {
    const fake = buildFakeAnthropic({
      responses: [
        { type: 'error', status: 500 },
        { type: 'error', status: 500 },
        { type: 'error', status: 500 },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      anthropicClient: fake,
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'hi',
      }),
    ).rejects.toBeInstanceOf(ClaudeApiError);

    expect((fake.messages.create as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(3);

    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    const payload = runInserts[0]?.payload as Record<string, unknown>;
    expect(payload.status).toBe('failed');
    const meta = payload.metadata as Record<string, unknown>;
    expect(meta.retry_count).toBe(3);
  });
}, 30_000);
