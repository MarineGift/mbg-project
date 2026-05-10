import { describe, it, expect, vi, beforeEach } from 'vitest';
import { processInbound } from '@/lib/email/processor';

vi.mock('@/lib/env', () => ({
  env: {
    AI_AUTO_SEND_ENABLED: false,
    DRAFT_EXPIRY_DAYS: 7,
    MAX_DAILY_AI_COST_USD: 50,
    MAX_MONTHLY_AI_COST_USD: 1500,
    CLAUDE_MAX_RETRIES: 3,
    CLAUDE_HARD_TIMEOUT_MS: 60_000,
    ANTHROPIC_API_KEY: 'sk-ant-test-key-123456789',
    ANTHROPIC_MODEL_OPUS: 'claude-opus-4-7',
    ANTHROPIC_MODEL_HAIKU: 'claude-haiku-4-5-20251001',
    ANTHROPIC_MODEL_SONNET: 'claude-sonnet-4-6',
  },
}));

interface MockClaudeResponse {
  parsedJson?: object;
  content?: string;
  runId: string;
}

const claudeResponses: MockClaudeResponse[] = [];

vi.mock('@/lib/ai/claude-client', () => {
  return {
    ClaudeClient: vi.fn().mockImplementation(() => {
      return {
        complete: vi.fn(async () => {
          const next = claudeResponses.shift();
          if (!next) {
            throw new Error('No mock claude response queued');
          }
          return {
            content: next.content ?? JSON.stringify(next.parsedJson ?? {}),
            parsedJson: next.parsedJson,
            runId: next.runId,
            model: 'claude-haiku-4-5-20251001',
            latencyMs: 100,
            tokensIn: 50,
            tokensOut: 30,
            costUsd: 0.001,
            retryCount: 0,
          };
        }),
      };
    }),
  };
});

vi.mock('@/lib/email/auto-send-gate', () => ({
  evaluateAutoSend: vi.fn(async () => ({
    allowed: false,
    reasons: ['global_disabled'],
    blockedRules: [],
    evaluationLog: { step: 'global_flag' },
  })),
}));

interface SupabaseProcessorStubOptions {
  communication?: Record<string, unknown> | null;
  draftInsertResult?: { id: string };
  draftInsertError?: { message: string };
}

function makeSupabaseStub(opts: SupabaseProcessorStubOptions) {
  const calls = {
    statusUpdates: [] as Array<Record<string, unknown>>,
    draftInserts: [] as Array<Record<string, unknown>>,
    commsUpdates: [] as Array<Record<string, unknown>>,
  };

  const buildCommSelectChain = () => {
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn(() => chain);
    chain.is = vi.fn(() => chain);
    chain.maybeSingle = vi.fn(async () => ({
      data: opts.communication ?? null,
      error: null,
    }));
    return chain;
  };

  const buildCommUpdateChain = (kind: 'status' | 'final') => {
    let payload: Record<string, unknown> = {};
    return {
      update: vi.fn((p: Record<string, unknown>) => {
        payload = p;
        return {
          eq: vi.fn(async () => {
            if (kind === 'status') {
              calls.statusUpdates.push({ ...payload });
            } else {
              calls.commsUpdates.push({ ...payload });
            }
            return { data: null, error: null };
          }),
        };
      }),
    };
  };

  const buildDraftInsertChain = () => {
    let payload: Record<string, unknown> = {};
    return {
      insert: vi.fn((p: Record<string, unknown>) => {
        payload = p;
        return {
          select: vi.fn(() => ({
            single: vi.fn(async () => {
              calls.draftInserts.push({ ...payload });
              if (opts.draftInsertError) {
                return { data: null, error: opts.draftInsertError };
              }
              return {
                data: opts.draftInsertResult ?? { id: 'draft-1' },
                error: null,
              };
            }),
          })),
        };
      }),
    };
  };

  let commActionCount = 0;
  const appSchema = {
    from: vi.fn((table: string) => {
      if (table === 'communications') {
        commActionCount += 1;
        if (commActionCount === 1) {
          return buildCommSelectChain();
        }
        return buildCommUpdateChain(commActionCount === 2 ? 'status' : 'final');
      }
      throw new Error(`unexpected app.${table}`);
    }),
  };

  const aiSchema = {
    from: vi.fn((table: string) => {
      if (table === 'drafts') return buildDraftInsertChain();
      throw new Error(`unexpected ai.${table}`);
    }),
  };

  return {
    supa: {
      schema: vi.fn((s: string) => (s === 'app' ? appSchema : aiSchema)),
    },
    calls,
  };
}

const VALID_COMM = {
  id: 'comm-1',
  organization_id: 'org-1',
  party_id: 'p-1',
  contact_id: null,
  engagement_id: 'eng-1',
  module: 'investor',
  channel: 'email',
  direction: 'inbound',
  message_id: '<m@x>',
  thread_id: 't-1',
  in_reply_to: null,
  from_address: 'lp@fund.example.com',
  from_name: 'LP Partner',
  to_addresses: ['us@us.com'],
  cc_addresses: [],
  bcc_addresses: [],
  subject: 'Quick question',
  body_plain: 'Could you share Q1 metrics?',
  body_html: null,
  language_detected: 'en',
  status: 'received',
  occurred_at: '2026-05-09T00:00:00Z',
  template_variables: {},
  external_data: {},
  ai_processing_status: 'pending',
  ai_generated: false,
  is_starred: false,
  is_important: false,
  created_at: '2026-05-09T00:00:00Z',
  updated_at: '2026-05-09T00:00:00Z',
};

describe('processInbound', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    claudeResponses.length = 0;
  });

  it('returns skipped when communication not found', async () => {
    const { supa } = makeSupabaseStub({ communication: null });
    const r = await processInbound(supa as never, 'org-1', 'missing');
    expect(r.status).toBe('skipped');
    expect(r.reason).toBe('communication_not_found');
  });

  it('returns skipped when not inbound', async () => {
    const { supa } = makeSupabaseStub({
      communication: { ...VALID_COMM, direction: 'outbound' },
    });
    const r = await processInbound(supa as never, 'org-1', 'comm-1');
    expect(r.status).toBe('skipped');
    expect(r.reason).toBe('not_inbound');
  });

  it('returns skipped when already processed (no force)', async () => {
    const { supa } = makeSupabaseStub({
      communication: { ...VALID_COMM, ai_processing_status: 'processed' },
    });
    const r = await processInbound(supa as never, 'org-1', 'comm-1');
    expect(r.status).toBe('skipped');
    expect(r.reason).toBe('already_processed');
  });

  it('full happy path: classifier → reply → gate → ai.drafts INSERT', async () => {
    claudeResponses.push(
      {
        runId: 'run-classifier-1',
        parsedJson: {
          category: 'information_request',
          urgency: 'medium',
          sentiment: 'positive',
          requiresHuman: false,
          confidence: 0.97,
          rationale: 'standard info request',
          riskFlags: [],
          detectedLanguage: 'en',
        },
      },
      {
        runId: 'run-drafter-1',
        parsedJson: {
          subject: 'Re: Quick question',
          bodyPlain: 'Hi, here are the Q1 metrics...',
          rationale: 'matches information_request pattern',
          riskFlags: [],
          requiresHumanApproval: false,
          language: 'en',
          classificationCategory: 'information_request',
        },
      },
    );

    const { supa, calls } = makeSupabaseStub({
      communication: VALID_COMM,
      draftInsertResult: { id: 'draft-77' },
    });

    const r = await processInbound(supa as never, 'org-1', 'comm-1');
    expect(r.status).toBe('processed');
    expect(r.draftId).toBe('draft-77');
    expect(r.classifierRunId).toBe('run-classifier-1');
    expect(r.replyDrafterRunId).toBe('run-drafter-1');
    expect(r.autoSendAllowed).toBe(false);

    expect(calls.draftInserts).toHaveLength(1);
    const draftInsert = calls.draftInserts[0]!;
    expect(draftInsert.classification_category).toBe('information_request');
    expect(draftInsert.classifier_run_id).toBe('run-classifier-1');
    expect(draftInsert.reply_drafter_run_id).toBe('run-drafter-1');
    expect(draftInsert.requires_human_approval).toBe(true);
    expect(draftInsert.auto_send_eligible).toBe(false);
    expect(draftInsert.expires_at).toBeTruthy();

    expect(calls.commsUpdates).toHaveLength(1);
    const commUpdate = calls.commsUpdates[0]!;
    expect(commUpdate.ai_draft_id).toBe('draft-77');
    expect(commUpdate.ai_processing_status).toBe('processed');
  });

  it('forces requires_human=true on non-standard category from classifier', async () => {
    claudeResponses.push(
      {
        runId: 'run-classifier-bad',
        parsedJson: {
          category: 'meeting_request',
          urgency: 'medium',
          sentiment: 'neutral',
          requiresHuman: false,
          confidence: 0.99,
          rationale: 'mistake',
          riskFlags: [],
          detectedLanguage: 'en',
        },
      },
      {
        runId: 'run-drafter-bad',
        parsedJson: {
          subject: 'Re: meeting',
          bodyPlain: 'sure, let me suggest times',
          rationale: 'meeting flow',
          riskFlags: [],
          requiresHumanApproval: false,
          language: 'en',
          classificationCategory: 'other',
        },
      },
    );

    const { supa, calls } = makeSupabaseStub({
      communication: VALID_COMM,
      draftInsertResult: { id: 'draft-fallback' },
    });

    const r = await processInbound(supa as never, 'org-1', 'comm-1');
    expect(r.status).toBe('processed');

    const draftInsert = calls.draftInserts[0]!;
    expect(draftInsert.classification_category).toBe('other');
    expect(draftInsert.requires_human_approval).toBe(true);
  });

  it('returns failed when classifier throws', async () => {
    const { supa, calls } = makeSupabaseStub({ communication: VALID_COMM });
    const r = await processInbound(supa as never, 'org-1', 'comm-1');
    expect(r.status).toBe('failed');
    expect(r.reason).toBe('classifier_failed');
    expect(calls.draftInserts).toHaveLength(0);
  });

  it('returns failed when reply drafter returns invalid JSON', async () => {
    claudeResponses.push(
      {
        runId: 'run-c',
        parsedJson: {
          category: 'information_request',
          urgency: 'low',
          sentiment: 'neutral',
          requiresHuman: false,
          confidence: 0.95,
          rationale: 'ok',
          riskFlags: [],
          detectedLanguage: 'en',
        },
      },
      { runId: 'run-d', content: 'not-json' },
    );
    const { supa, calls } = makeSupabaseStub({ communication: VALID_COMM });
    const r = await processInbound(supa as never, 'org-1', 'comm-1');
    expect(r.status).toBe('failed');
    expect(r.reason).toBe('reply_drafter_failed');
    expect(calls.draftInserts).toHaveLength(0);
  });
});
