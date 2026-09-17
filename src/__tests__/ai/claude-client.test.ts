/**
 * __tests__/ai/claude-client.test.ts  (provider: OpenAI)
 *
 * Core guarantees of ClaudeClient.complete():
 *   1. throws ClaudeBudgetExceededError when the daily budget is exceeded
 *   2. throws ClaudeInvalidModelError if agent.model is not in SUPPORTED_MODELS
 *   3. exponential backoff on 429/5xx, using the fallback model from the second attempt
 *   4. 4xx (non-retryable) throws immediately + records ai.runs status='failed'
 *   5. on success, records ai.runs status='success' + computes cost accurately
 *   6. applies PII masking then restores it in the response
 *   7. fills parsedJson when JSON output_format is used
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import OpenAI from 'openai';
import {
  ClaudeClient,
  ClaudeApiError,
  ClaudeBudgetExceededError,
  ClaudeInvalidModelError,
  ClaudeAgentNotFoundError,
} from '../../lib/ai/claude-client';
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';

// always mock prompt-renderer since it makes OpenAI calls
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

interface FakeOpenAiOpts {
  responses?: Array<
    | { type: 'success'; content: string; tokensIn?: number; tokensOut?: number }
    | { type: 'error'; status: number; retryAfter?: number; message?: string }
  >;
}

type FakeOpenAi = OpenAI & {
  chat: { completions: { create: ReturnType<typeof vi.fn> } };
};

function buildFakeOpenAi(opts: FakeOpenAiOpts): FakeOpenAi {
  const responses = [...(opts.responses ?? [])];
  return {
    chat: {
      completions: {
        create: vi.fn(async (params: { model: string }) => {
          const r = responses.shift();
          if (!r) throw new Error('no more fake responses configured');
          if (r.type === 'error') {
            // a real OpenAI.APIError instance - passes the instanceof check
            const headers: Record<string, string> = {};
            if (r.retryAfter !== undefined) {
              headers['retry-after'] = String(r.retryAfter);
            }
            throw new OpenAI.APIError(
              r.status,
              undefined,
              r.message ?? `HTTP ${r.status}`,
              headers,
            );
          }
          return {
            id: 'chatcmpl_test',
            object: 'chat.completion',
            created: 0,
            model: params.model,
            choices: [
              {
                index: 0,
                finish_reason: 'stop',
                message: { role: 'assistant', content: r.content },
              },
            ],
            usage: {
              prompt_tokens: r.tokensIn ?? 100,
              completion_tokens: r.tokensOut ?? 50,
              total_tokens: (r.tokensIn ?? 100) + (r.tokensOut ?? 50),
            },
          };
        }),
      },
    },
  } as unknown as FakeOpenAi;
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
  // Daily cost = call 1: today rows, Monthly cost = call 2: month rows
  // this mock returns the same result for both calls (when a test needs to separate cost,
  // selectList must dynamically return different responses)
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
      agentRow: { ...haikuAgentRow, model: 'claude-3-haiku' }, // old version!
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: buildFakeOpenAi({ responses: [] }),
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
      openaiClient: buildFakeOpenAi({ responses: [] }),
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
    // MAX_DAILY_AI_COST_USD=10 from setupFiles. todayCost=15 -> exceeded
    const supabase = buildSupabase({ todayCost: 15 });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: buildFakeOpenAi({ responses: [] }),
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
    const fake = buildFakeOpenAi({
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
      openaiClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: '안녕하세요, 가격이 궁금합니다.',
      outputFormat: 'json',
      language: 'ko',
    });

    expect(result.runId).toBe('run-1');
    // tier id is kept; the provider model is the mapped OpenAI model
    expect(result.model).toBe('claude-haiku-4-5-20251001');
    expect(result.providerModel).toBe('gpt-5-nano');
    expect(result.tokensIn).toBe(1000);
    expect(result.tokensOut).toBe(500);
    // gpt-5-nano: $0.05 in / $0.40 out per 1M
    // (1000 * 0.05 + 500 * 0.4) / 1_000_000 = 0.00005 + 0.0002 = 0.00025
    expect(result.costUsd).toBeCloseTo(0.00025, 8);

    // request body is valid for a reasoning model
    const req = (fake.chat.completions.create.mock.calls[0]?.[0] ?? {}) as Record<string, unknown>;
    expect(req.model).toBe('gpt-5-nano');
    expect(req.temperature).toBeUndefined();
    expect(req.max_completion_tokens).toBe(1024);
    expect(req.reasoning_effort).toBe('minimal');
    expect((req.messages as Array<{ role: string }>)[0]?.role).toBe('system');

    // parsedJson is filled
    expect(result.parsedJson).toEqual({
      category: 'information_request',
      confidence: 0.95,
    });

    // ai.runs INSERT - verify DB column names/mapping
    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    expect(runInserts).toHaveLength(1);
    const payload = runInserts[0]?.payload as Record<string, unknown>;
    // RunStatus 'success' → DB 'completed'
    expect(payload.status).toBe('completed');
    expect(payload.model_used).toBe('gpt-5-nano');
    expect(payload.input_tokens).toBe(1000);
    expect(payload.output_tokens).toBe(500);
    expect(payload.pii_masked).toBe(true);
    // brand_voice_id / knowledge_chunk_ids moved into the metadata jsonb
    const meta = payload.metadata as Record<string, unknown>;
    expect(meta.brand_voice_id).toBe('bv-1');
    expect(meta.knowledge_chunk_ids).toEqual(['kc-1', 'kc-2']);
    // completed_at is also filled (status !== 'running')
    expect(typeof payload.completed_at).toBe('string');
  });

  it('strips ```json fence from response', async () => {
    const fake = buildFakeOpenAi({
      responses: [
        {
          type: 'success',
          content: '```json\n{"category":"meeting_scheduling","confidence":0.9}\n```',
        },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: fake,
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
    const fake = buildFakeOpenAi({
      responses: [
        {
          type: 'success',
          // assume the AI output the masked token as-is
          content: 'Phone {{PII_001}} verified.',
        },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: '연락처: 010-1234-5678 입니다',
      outputFormat: 'text',
    });
    // the token must be restored to the original (010-1234-5678)
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
    const fake = buildFakeOpenAi({
      responses: [
        { type: 'error', status: 429, retryAfter: 0 },
        { type: 'success', content: '{"ok":true}' },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'hi',
      outputFormat: 'json',
    });
    expect(result.parsedJson).toEqual({ ok: true });
    expect(fake.chat.completions.create.mock.calls).toHaveLength(2);

    // ai.runs INSERT once (only at success), retry_count=1
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
    const fake = buildFakeOpenAi({
      responses: [
        { type: 'error', status: 503 }, // attempt 0
        { type: 'error', status: 503 }, // attempt 1 -> fallback applied
        { type: 'success', content: 'ok' }, // attempt 2 - success with the fallback model
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: fake,
      enableMonthlyDowngrade: false,
    });

    const result = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'hi',
    });
    // use the fallback model (sonnet tier -> gpt-5-mini) from the second retry
    expect(result.model).toBe('claude-sonnet-4-6');
    expect(result.providerModel).toBe('gpt-5-mini');

    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    expect(runInserts).toHaveLength(1);
    expect((runInserts[0]?.payload as Record<string, unknown>).status).toBe('completed');
  });

  it('does NOT retry on 4xx and records failure', async () => {
    const fake = buildFakeOpenAi({
      responses: [{ type: 'error', status: 400, message: 'Bad Request' }],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: fake,
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'hi',
      }),
    ).rejects.toBeInstanceOf(ClaudeApiError);

    expect(fake.chat.completions.create.mock.calls).toHaveLength(1);

    // ai.runs INSERT - DB status='failed' (domain 'failed' as-is), error_status in metadata
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
    const fake = buildFakeOpenAi({
      responses: [
        { type: 'error', status: 500 },
        { type: 'error', status: 500 },
        { type: 'error', status: 500 },
      ],
    });
    const client = new ClaudeClient(supabase as never, orgId, {
      openaiClient: fake,
      enableMonthlyDowngrade: false,
    });

    await expect(
      client.complete({
        agentRole: 'classifier',
        inboundMessage: 'hi',
      }),
    ).rejects.toBeInstanceOf(ClaudeApiError);

    expect(fake.chat.completions.create.mock.calls).toHaveLength(3);

    const runInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'runs',
    );
    const payload = runInserts[0]?.payload as Record<string, unknown>;
    expect(payload.status).toBe('failed');
    const meta = payload.metadata as Record<string, unknown>;
    expect(meta.retry_count).toBe(3);
  });
}, 30_000);
