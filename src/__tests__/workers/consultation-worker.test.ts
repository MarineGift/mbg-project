import { describe, it, expect, vi, beforeEach } from 'vitest';
import { processConsultation } from '@/workers/consultation-worker';

vi.mock('@/lib/env', () => ({
  env: {
    NEXT_PUBLIC_SUPABASE_URL: 'https://example.supabase.co',
    SUPABASE_SERVICE_ROLE_KEY: 'test-service-role-key-1234567890',
    SUPABASE_DB_URL: 'postgres://x',
    ANTHROPIC_API_KEY: 'sk-ant-test-1234567890',
    AI_AUTO_SEND_ENABLED: false,
    DRAFT_EXPIRY_DAYS: 7,
    CLAUDE_MAX_RETRIES: 3,
    CLAUDE_HARD_TIMEOUT_MS: 60_000,
    MAX_DAILY_AI_COST_USD: 50,
    MAX_MONTHLY_AI_COST_USD: 1500,
  },
}));

interface ConsultationStubOptions {
  consultation?: Record<string, unknown> | null;
  strategyInsertResults?: Array<{ id: string }>;
  strategyInsertError?: { message: string } | null;
  actionsInsertError?: { message: string } | null;
}

function makeSupabaseStub(opts: ConsultationStubOptions) {
  const calls = {
    consultationUpdates: [] as Array<Record<string, unknown>>,
    strategyInserts: [] as Array<Record<string, unknown>>,
    actionInserts: [] as Array<Array<Record<string, unknown>>>,
  };

  let strategyIdx = 0;

  const buildConsultationsChain = () => {
    const chain: Record<string, unknown> = {};
    let updatePayload: Record<string, unknown> | null = null;
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn(() => chain);
    chain.maybeSingle = vi.fn(async () => ({
      data: opts.consultation ?? null,
      error: null,
    }));
    chain.update = vi.fn((p: Record<string, unknown>) => {
      updatePayload = p;
      return {
        eq: vi.fn(async () => {
          if (updatePayload) calls.consultationUpdates.push({ ...updatePayload });
          return { data: null, error: null };
        }),
      };
    });
    return chain;
  };

  const buildStrategiesChain = () => {
    return {
      insert: vi.fn((p: Record<string, unknown>) => ({
        select: vi.fn(() => ({
          single: vi.fn(async () => {
            calls.strategyInserts.push({ ...p });
            if (opts.strategyInsertError) {
              return { data: null, error: opts.strategyInsertError };
            }
            const result = (opts.strategyInsertResults ?? [])[strategyIdx];
            strategyIdx += 1;
            return { data: result ?? { id: `strat-${strategyIdx}` }, error: null };
          }),
        })),
      })),
    };
  };

  const buildActionsChain = () => {
    return {
      insert: vi.fn(async (rows: Array<Record<string, unknown>>) => {
        calls.actionInserts.push([...rows]);
        if (opts.actionsInsertError) {
          return { data: null, error: opts.actionsInsertError };
        }
        return { data: rows, error: null };
      }),
    };
  };

  const supa = {
    schema: vi.fn(() => ({
      from: vi.fn((table: string) => {
        if (table === 'consultations') return buildConsultationsChain();
        if (table === 'response_strategies') return buildStrategiesChain();
        if (table === 'strategy_actions') return buildActionsChain();
        throw new Error(`unexpected table: ${table}`);
      }),
    })),
  };

  return { supa, calls };
}

function makeClaudeFactory(response: { parsedJson?: object; throws?: Error }) {
  return () =>
    ({
      complete: vi.fn(async () => {
        if (response.throws) throw response.throws;
        return {
          content: JSON.stringify(response.parsedJson ?? {}),
          parsedJson: response.parsedJson,
          runId: 'run-advisor-1',
          model: 'claude-opus-4-7' as const,
          latencyMs: 200,
          tokensIn: 500,
          tokensOut: 300,
          costUsd: 0.03,
          retryCount: 0,
        };
      }),
    }) as never;
}

const VALID_CONSULTATION = {
  id: 'cons-1',
  organization_id: 'org-1',
  module: 'investor',
  priority: 'high',
  title: 'LP responded asking about Q1 metrics',
  description: 'Need a strategic response for Greylock LP',
  ai_processing_status: 'pending',
};

const VALID_ADVISOR_OUTPUT = {
  summary: 'LP wants Q1 metrics. Recommend factual response with framing.',
  responseStrategies: [
    {
      title: 'Direct response with metrics deck',
      rationale: 'LP needs quick visibility',
      confidence: 0.9,
      actions: [
        {
          title: 'Compile Q1 metrics one-pager',
          description: 'Use existing dashboard data',
          due_in_days: 2,
          priority: 'high',
        },
        {
          title: 'Schedule 30min call',
          description: 'Walk through metrics',
          due_in_days: 5,
          priority: 'medium',
        },
      ],
    },
  ],
  riskNotes: ['Avoid forward-looking statements'],
};

describe('processConsultation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns skipped when consultation not found', async () => {
    const { supa } = makeSupabaseStub({ consultation: null });
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'missing', organization_id: 'org-1' },
      makeClaudeFactory({ parsedJson: VALID_ADVISOR_OUTPUT }),
    );
    expect(r.status).toBe('skipped');
    expect(r.reason).toBe('consultation_not_found');
  });

  it('returns skipped when already processed', async () => {
    const { supa } = makeSupabaseStub({
      consultation: { ...VALID_CONSULTATION, ai_processing_status: 'processed' },
    });
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'cons-1', organization_id: 'org-1' },
      makeClaudeFactory({ parsedJson: VALID_ADVISOR_OUTPUT }),
    );
    expect(r.status).toBe('skipped');
    expect(r.reason).toBe('already_processed');
  });

  it('happy path: persists strategies and actions, marks processed', async () => {
    const { supa, calls } = makeSupabaseStub({
      consultation: VALID_CONSULTATION,
      strategyInsertResults: [{ id: 'strat-77' }],
    });
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'cons-1', organization_id: 'org-1' },
      makeClaudeFactory({ parsedJson: VALID_ADVISOR_OUTPUT }),
    );
    expect(r.status).toBe('processed');

    expect(calls.strategyInserts).toHaveLength(1);
    expect(calls.strategyInserts[0]?.title).toBe(
      'Direct response with metrics deck',
    );
    expect(calls.actionInserts).toHaveLength(1);
    expect(calls.actionInserts[0]).toHaveLength(2);
    expect(calls.actionInserts[0]?.[0]?.response_strategy_id).toBe('strat-77');

    const lastUpdate =
      calls.consultationUpdates[calls.consultationUpdates.length - 1];
    expect(lastUpdate?.ai_processing_status).toBe('processed');
    expect(lastUpdate?.ai_summary).toBe(VALID_ADVISOR_OUTPUT.summary);
  });

  it('returns failed and marks consultation failed on advisor error', async () => {
    const { supa, calls } = makeSupabaseStub({
      consultation: VALID_CONSULTATION,
    });
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'cons-1', organization_id: 'org-1' },
      makeClaudeFactory({ throws: new Error('budget exceeded') }),
    );
    expect(r.status).toBe('failed');
    expect(r.reason).toBe('advisor_failed');

    const lastUpdate =
      calls.consultationUpdates[calls.consultationUpdates.length - 1];
    expect(lastUpdate?.ai_processing_status).toBe('failed');
    expect(lastUpdate?.ai_processing_error).toBe('budget exceeded');
  });

  it('returns failed when advisor returns non-JSON', async () => {
    const { supa, calls } = makeSupabaseStub({
      consultation: VALID_CONSULTATION,
    });
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'cons-1', organization_id: 'org-1' },
      makeClaudeFactory({ parsedJson: undefined }),
    );
    expect(r.status).toBe('failed');
    expect(r.reason).toBe('advisor_failed');
    expect(calls.strategyInserts).toHaveLength(0);
  });

  it('returns failed when persisting strategies fails', async () => {
    const { supa } = makeSupabaseStub({
      consultation: VALID_CONSULTATION,
      strategyInsertError: { message: 'FK violation' },
    });
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'cons-1', organization_id: 'org-1' },
      makeClaudeFactory({ parsedJson: VALID_ADVISOR_OUTPUT }),
    );
    expect(r.status).toBe('failed');
    expect(r.reason).toBe('persist_failed');
  });

  it('skips empty actions array gracefully', async () => {
    const { supa, calls } = makeSupabaseStub({
      consultation: VALID_CONSULTATION,
      strategyInsertResults: [{ id: 'strat-x' }],
    });
    const advisorWithoutActions = {
      ...VALID_ADVISOR_OUTPUT,
      responseStrategies: [
        { ...VALID_ADVISOR_OUTPUT.responseStrategies[0], actions: [] },
      ],
    };
    const r = await processConsultation(
      supa as never,
      { consultation_id: 'cons-1', organization_id: 'org-1' },
      makeClaudeFactory({ parsedJson: advisorWithoutActions }),
    );
    expect(r.status).toBe('processed');
    expect(calls.strategyInserts).toHaveLength(1);
    expect(calls.actionInserts).toHaveLength(0);
  });
});
