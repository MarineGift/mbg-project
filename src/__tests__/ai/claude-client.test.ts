import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('@/lib/env', () => ({
  env: {
    ANTHROPIC_API_KEY: 'sk-ant-test-1234567890',
    ANTHROPIC_MODEL_OPUS: 'claude-opus-4-7',
    ANTHROPIC_MODEL_HAIKU: 'claude-haiku-4-5-20251001',
    ANTHROPIC_MODEL_SONNET: 'claude-sonnet-4-6',
    MAX_DAILY_AI_COST_USD: 50,
    MAX_MONTHLY_AI_COST_USD: 1500,
    CLAUDE_HARD_TIMEOUT_MS: 60_000,
    CLAUDE_MAX_RETRIES: 3,
  },
}));

vi.mock('@/lib/ai/prompt-renderer', () => ({
  renderPrompt: vi.fn(async () => ({
    system: 'system prompt',
    messages: [{ role: 'user', content: 'test message' }],
    metadata: {
      brandVoiceId: 'bv-1',
      knowledgeChunkIds: ['kc-1'],
      threadCommunicationIds: [],
    },
  })),
  applyLiquidVariables: vi.fn((s: string) => s),
}));

import {
  ClaudeClient,
  ClaudeApiError,
  ClaudeBudgetExceededError,
  ClaudeAgentNotFoundError,
} from '@/lib/ai/claude-client';

interface ClaudeStubOptions {
  agentRow?: Record<string, unknown> | null;
  dailyCost?: number;
  monthlyCost?: number;
  runInsertResult?: { id: string };
}

function makeSupabaseStub(opts: ClaudeStubOptions) {
  const calls = {
    runInserts: [] as Array<Record<string, unknown>>,
  };

  const buildAgentChain = () => {
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn(() => chain);
    chain.or = vi.fn(() => chain);
    chain.order = vi.fn(() => chain);
    chain.limit = vi.fn(() => chain);
    chain.maybeSingle = vi.fn(async () => ({
      data: opts.agentRow ?? null,
      error: null,
    }));
    return chain;
  };

  // runs chain: select와 insert를 모두 노출. 호출자가 .select()로 시작하면
  // 예산 조회 경로(thenable로 종료), .insert()로 시작하면 INSERT 경로(.select().single() 종료).
  // 매 from('runs') 호출마다 새 chain을 발급해 카운터 의존성을 제거.
  const buildRunsChain = () => {
    let phase: 'daily' | 'monthly' = 'daily';
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn(() => chain);
    chain.gte = vi.fn((_col: string, ts: string) => {
      const days =
        (Date.now() - new Date(ts).getTime()) / (24 * 60 * 60 * 1000);
      phase = days > 1.5 ? 'monthly' : 'daily';
      return new Proxy(chain, {
        get(target, prop) {
          if (prop === 'then') {
            return (resolve: (v: unknown) => unknown) => {
              const cost =
                phase === 'daily'
                  ? (opts.dailyCost ?? 0)
                  : (opts.monthlyCost ?? 0);
              return resolve({
                data: cost > 0 ? [{ cost_usd: cost }] : [],
                error: null,
              });
            };
          }
          return (target as Record<string, unknown>)[String(prop)];
        },
      });
    });
    chain.insert = vi.fn((p: Record<string, unknown>) => ({
      select: vi.fn(() => ({
        single: vi.fn(async () => {
          calls.runInserts.push({ ...p });
          return {
            data: opts.runInsertResult ?? { id: 'run-1' },
            error: null,
          };
        }),
      })),
    }));
    return chain;
  };

  const aiSchema = {
    from: vi.fn((table: string) => {
      if (table === 'agents') return buildAgentChain();
      if (table === 'runs') return buildRunsChain();
      throw new Error(`unexpected ai.${table}`);
    }),
  };

  return {
    supa: { schema: vi.fn(() => aiSchema) },
    calls,
  };
}

function makeFakeAnthropic(opts: {
  successPayload?: { content: string; tokensIn?: number; tokensOut?: number };
  errors?: Array<{ status?: number; message: string; headers?: Record<string, string> }>;
}) {
  let callIdx = 0;
  return {
    messages: {
      create: vi.fn(async () => {
        const err = (opts.errors ?? [])[callIdx];
        callIdx += 1;
        if (err) {
          const e = new Error(err.message) as Error & {
            status?: number;
            headers?: Record<string, string>;
          };
          e.status = err.status;
          e.headers = err.headers;
          throw e;
        }
        const payload = opts.successPayload ?? { content: '{"ok":true}' };
        return {
          id: 'msg_test',
          type: 'message',
          role: 'assistant',
          content: [{ type: 'text', text: payload.content }],
          model: 'claude-haiku-4-5-20251001',
          stop_reason: 'end_turn',
          usage: {
            input_tokens: payload.tokensIn ?? 100,
            output_tokens: payload.tokensOut ?? 50,
          },
        };
      }),
    },
  } as never;
}

const VALID_AGENT = {
  id: 'agent-1',
  organization_id: 'org-1',
  role: 'classifier',
  name: 'Email Classifier',
  model: 'claude-haiku-4-5-20251001',
  fallback_model: 'claude-sonnet-4-6',
  temperature: 0.2,
  max_tokens: 1024,
  output_format: 'structured',
  system_prompt: 'Classify the email.',
  applicable_modules: [],
  applicable_languages: [],
  require_pii_masking: true,
  is_active: true,
  version: 1,
};

describe('ClaudeClient.complete - happy path', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('parses JSON, records ai.runs success, returns runId', async () => {
    const { supa, calls } = makeSupabaseStub({ agentRow: VALID_AGENT });
    const fakeAnthropic = makeFakeAnthropic({
      successPayload: { content: '{"category":"information_request","confidence":0.95}' },
    });
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);

    const r = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'Hello',
      outputFormat: 'json',
    });

    expect(r.parsedJson).toEqual({
      category: 'information_request',
      confidence: 0.95,
    });
    expect(r.model).toBe('claude-haiku-4-5-20251001');
    expect(r.tokensIn).toBe(100);
    expect(r.tokensOut).toBe(50);
    expect(r.costUsd).toBeCloseTo((100 * 0.8 + 50 * 4) / 1_000_000);
    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('success');
  });
});

describe('ClaudeClient.complete - agent and model validation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('throws ClaudeAgentNotFoundError when agent missing', async () => {
    const { supa, calls } = makeSupabaseStub({ agentRow: null });
    const fakeAnthropic = makeFakeAnthropic({});
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);

    await expect(
      client.complete({ agentRole: 'classifier', inboundMessage: 'x' }),
    ).rejects.toBeInstanceOf(ClaudeAgentNotFoundError);

    // Preflight block must record an ai.runs entry (selection B from validation #7)
    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('failed');
    expect(calls.runInserts[0]?.agent_id).toBeNull();
    expect(calls.runInserts[0]?.tokens_in).toBe(0);
    expect(calls.runInserts[0]?.tokens_out).toBe(0);
    expect(calls.runInserts[0]?.cost_usd).toBe(0);
    expect(String(calls.runInserts[0]?.error_message)).toContain('agent_not_found');
  });

  it('rejects legacy model id (claude-3-haiku) at toAgentRow', async () => {
    const { supa, calls } = makeSupabaseStub({
      agentRow: { ...VALID_AGENT, model: 'claude-3-haiku' },
    });
    const fakeAnthropic = makeFakeAnthropic({});
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);
    await expect(
      client.complete({ agentRole: 'classifier', inboundMessage: 'x' }),
    ).rejects.toBeInstanceOf(Error);
    // toAgentRow의 throw도 ai.runs에 기록됨 (instanceof 좁힘 해제 후)
    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('failed');
    expect(calls.runInserts[0]?.agent_id).toBeNull();
    expect(String(calls.runInserts[0]?.error_message)).toContain('agent_load_failed');
    expect(String(calls.runInserts[0]?.error_message)).toContain('claude-3-haiku');
  });
});

describe('ClaudeClient.complete - budget enforcement', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('throws ClaudeBudgetExceededError when daily cost reached', async () => {
    const { supa, calls } = makeSupabaseStub({
      agentRow: VALID_AGENT,
      dailyCost: 60,
    });
    const fakeAnthropic = makeFakeAnthropic({});
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);
    await expect(
      client.complete({ agentRole: 'classifier', inboundMessage: 'x' }),
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);

    // Preflight block must record an ai.runs entry with status=budget_exceeded
    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('budget_exceeded');
    expect(calls.runInserts[0]?.agent_id).toBeNull();
    expect(calls.runInserts[0]?.tokens_in).toBe(0);
    expect(calls.runInserts[0]?.cost_usd).toBe(0);
    expect(String(calls.runInserts[0]?.error_message)).toContain('daily budget exceeded');
  });

  it('throws ClaudeBudgetExceededError when monthly cost reached', async () => {
    const { supa, calls } = makeSupabaseStub({
      agentRow: VALID_AGENT,
      dailyCost: 0,
      monthlyCost: 2000,
    });
    const fakeAnthropic = makeFakeAnthropic({});
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);
    await expect(
      client.complete({ agentRole: 'classifier', inboundMessage: 'x' }),
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);

    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('budget_exceeded');
    expect(String(calls.runInserts[0]?.error_message)).toContain('monthly budget exceeded');
  });
});

describe('ClaudeClient.complete - retries and failures', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('records ai.runs(failed) and throws on non-retryable 400', async () => {
    const { supa, calls } = makeSupabaseStub({ agentRow: VALID_AGENT });
    const fakeAnthropic = makeFakeAnthropic({
      errors: [
        { status: 400, message: 'bad request' },
        { status: 400, message: 'bad request' },
      ],
    });
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);

    await expect(
      client.complete({ agentRole: 'classifier', inboundMessage: 'x' }),
    ).rejects.toBeInstanceOf(ClaudeApiError);

    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('failed');
    expect(calls.runInserts[0]?.error_status).toBe(400);
  });

  it('retries on 429 then succeeds', async () => {
    const { supa, calls } = makeSupabaseStub({ agentRow: VALID_AGENT });
    const fakeAnthropic = makeFakeAnthropic({
      errors: [{ status: 429, message: 'rate limited' }],
      successPayload: { content: '{"ok":true}' },
    });
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);

    vi.spyOn(globalThis, 'setTimeout').mockImplementation(((fn: () => void) => {
      fn();
      return 0 as unknown as NodeJS.Timeout;
    }) as never);

    const r = await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'x',
      outputFormat: 'json',
    });

    expect(r.parsedJson).toEqual({ ok: true });
    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.status).toBe('success');
    expect(calls.runInserts[0]?.retry_count).toBeGreaterThan(0);
  });
});

describe('ClaudeClient.complete - PII masking', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('records pii_masked=true and detects categories', async () => {
    const { supa, calls } = makeSupabaseStub({ agentRow: VALID_AGENT });
    const fakeAnthropic = makeFakeAnthropic({
      successPayload: { content: '{"ok":true}' },
    });
    const client = new ClaudeClient(supa as never, 'org-1', undefined, fakeAnthropic);

    await client.complete({
      agentRole: 'classifier',
      inboundMessage: 'My phone is 010-1234-5678 and email is test@example.com',
      outputFormat: 'json',
    });

    expect(calls.runInserts).toHaveLength(1);
    expect(calls.runInserts[0]?.pii_masked).toBe(true);
    const categories = calls.runInserts[0]?.pii_categories_detected as string[];
    expect(categories).toContain('phone_kr');
    expect(categories).toContain('email');
  });
});
