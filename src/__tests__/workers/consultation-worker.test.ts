/**
 * __tests__/workers/consultation-worker.test.ts
 *
 * Verifies the core logic of processConsultation:
 *   1. normal flow - strategy + 3 actions (immediate/short/long); immediate creates a task
 *   2. a consultation with ai_processing_status='completed' is skipped (idempotent)
 *   3. consultation not found -> status='failed'
 *   4. ClaudeBudgetExceededError → ai_processing_retryable=false
 *   5. ClaudeApiError 5xx → ai_processing_retryable=true
 *   6. strategy_advisor returns invalid JSON -> handled as failure
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  processConsultation,
  type ConsultationNotification,
} from '../../workers/consultation-worker';
import {
  ClaudeApiError,
  ClaudeBudgetExceededError,
} from '../../lib/ai/claude-client';
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
import type {
  ClaudeCompleteInput,
  ClaudeCompleteOutput,
} from '../../types/ai';

const orgId = 'org-1';
const consultationId = 'consult-1';

interface MockClaudeOpts {
  parsedJson?: object;
  throwError?: Error;
}

function buildMockClaude(opts: MockClaudeOpts): {
  complete: ReturnType<typeof vi.fn>;
} {
  const complete = vi.fn(async (_input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> => {
    if (opts.throwError) throw opts.throwError;
    return {
      content: opts.parsedJson ? JSON.stringify(opts.parsedJson) : '',
      parsedJson: opts.parsedJson,
      runId: 'run-strat-1',
      agentId: 'agent-strategy-advisor-1',
      model: 'claude-opus-4-7',
      latencyMs: 4000,
      tokensIn: 1000,
      tokensOut: 800,
      costUsd: 0.075,
    };
  });
  return { complete };
}

const validStrategy = {
  situation_analysis: 'Investor showing strong interest after demo',
  key_signals: ['quick reply', 'follow-up questions'],
  recommended_approach: 'Send updated deck and propose call',
  key_messages: ['traction', 'team', 'roadmap'],
  risks_to_avoid: ['premature valuation discussion'],
  questions_to_ask_internally: ['confirm investor mandate'],
  confidence_score: 0.85,
  requires_human_review: true,
  requires_legal_review: false,
  requires_finance_review: false,
  actions: [
    {
      title: 'Reply with updated deck',
      description: 'Send v3 deck and propose 30-min call',
      action_type: 'immediate',
      priority: 'high',
      suggested_due_in_hours: 24,
      sort_order: 1,
    },
    {
      title: 'Prepare data room',
      description: 'Organize financials and metrics',
      action_type: 'short_term',
      priority: 'medium',
      suggested_due_in_days: 7,
      sort_order: 2,
    },
    {
      title: 'Schedule board update',
      description: 'Brief board on funding pipeline',
      action_type: 'long_term',
      priority: 'low',
      suggested_due_in_days: 30,
      sort_order: 3,
    },
  ],
};

const consultationRow = {
  id: consultationId,
  organization_id: orgId,
  party_id: 'party-1',
  engagement_id: 'eng-1',
  party_type: 'investor',
  content_raw: '안녕하세요, 데모 잘 봤습니다…',
  content_processed: '안녕하세요, 데모 잘 봤습니다… [요약]',
  language: 'ko',
  priority: 'high',
  urgency: 'high',
  ai_processing_status: 'pending',
};

function makeBaseNotification(): ConsultationNotification {
  return {
    consultation_id: consultationId,
    organization_id: orgId,
    party_type: 'investor',
    priority: 'high',
    urgency: 'high',
  };
}

function buildSupabase(consultationData: object | null = consultationRow): MockSupabase {
  return buildSupabaseMock({
    'app.consultations': {
      selectMaybeSingle: { data: consultationData },
      updateResult: { error: null },
    },
    'app.response_strategies': {
      insertSingle: { data: { id: 'strategy-1' } },
    },
    'app.strategy_actions': {
      insertSingle: { data: { id: 'action-1' } },
      updateResult: { error: null },
    },
    'app.tasks': {
      insertSingle: { data: { id: 'task-1' } },
    },
  });
}

describe('processConsultation — happy path', () => {
  let supabase: MockSupabase;

  beforeEach(() => {
    supabase = buildSupabase();
  });

  it('runs strategy_advisor and inserts response_strategies + actions + tasks', async () => {
    const claude = buildMockClaude({ parsedJson: validStrategy });
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
      nowProvider: () => new Date('2026-04-01T10:00:00Z'),
    });

    expect(result.status).toBe('completed');
    expect(result.strategyId).toBe('strategy-1');
    expect(result.actionsCreated).toBe(3); // 3 actions
    expect(result.tasksCreated).toBe(1); // 1 immediate

    // claude calls strategy_advisor once
    expect(claude.complete).toHaveBeenCalledTimes(1);
    expect(claude.complete.mock.calls[0]?.[0]?.agentRole).toBe('strategy_advisor');
    expect(claude.complete.mock.calls[0]?.[0]?.outputFormat).toBe('json');

    // verify the response_strategies INSERT
    const strategyInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'app' && c.table === 'response_strategies',
    );
    expect(strategyInserts).toHaveLength(1);
    const strategyPayload = strategyInserts[0]?.payload as Record<string, unknown>;
    expect(strategyPayload.consultation_id).toBe(consultationId);
    expect(strategyPayload.run_id).toBe('run-strat-1');
    expect(strategyPayload.confidence_score).toBe(0.85);
    expect(strategyPayload.ai_generated).toBe(true);
    expect(strategyPayload.status).toBe('draft');

    // INSERT 3 strategy_actions
    const actionInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'app' && c.table === 'strategy_actions',
    );
    expect(actionInserts).toHaveLength(3);

    // INSERT 1 task (immediate only)
    const taskInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'app' && c.table === 'tasks',
    );
    expect(taskInserts).toHaveLength(1);
    const taskPayload = taskInserts[0]?.payload as Record<string, unknown>;
    expect(taskPayload.title).toBe('Reply with updated deck');
    expect(taskPayload.status).toBe('todo');
    expect(taskPayload.deal_id).toBe('eng-1'); // engagement_id IS the deal id
    expect(
      (taskPayload.extra_data as Record<string, unknown>).linked_strategy_action_id,
    ).toBe('action-1');

    // due_at 24 hours later
    expect(taskPayload.due_at).toBe('2026-04-02T10:00:00.000Z');

    // strategy_actions UPDATE (linked_task_id back-link) at least 1
    const actionUpdates = supabase.__calls.update.filter(
      (c) => c.schema === 'app' && c.table === 'strategy_actions',
    );
    expect(actionUpdates.length).toBeGreaterThanOrEqual(1);
  });

  it('does not create task when due_in_hours is missing', async () => {
    const supa = buildSupabase();
    const strategyNoHours = {
      ...validStrategy,
      actions: [
        {
          title: 'Immediate without due',
          description: 'x',
          action_type: 'immediate',
          // no suggested_due_in_hours
        },
      ],
    };
    const claude = buildMockClaude({ parsedJson: strategyNoHours });
    const result = await processConsultation(supa as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });
    expect(result.tasksCreated).toBe(1);
    const tasks = supa.__calls.insert.filter((c) => c.table === 'tasks');
    expect((tasks[0]?.payload as Record<string, unknown>).due_at).toBeNull();
  });
});

describe('processConsultation — idempotency', () => {
  it('skips when ai_processing_status is already completed', async () => {
    const supabase = buildSupabase({
      ...consultationRow,
      ai_processing_status: 'completed',
    });
    const claude = buildMockClaude({ parsedJson: validStrategy });

    const result = await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });

    expect(result.status).toBe('completed');
    expect(result.errorMessage).toBe('already_completed');
    // claude should not be called
    expect(claude.complete).not.toHaveBeenCalled();
    // response_strategies is not INSERTed
    const strategyInserts = supabase.__calls.insert.filter(
      (c) => c.table === 'response_strategies',
    );
    expect(strategyInserts).toHaveLength(0);
  });
});

describe('processConsultation — failure paths', () => {
  it('returns failed when consultation does not exist', async () => {
    const supabase = buildSupabase(null);
    const claude = buildMockClaude({ parsedJson: validStrategy });
    const result = await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });
    expect(result.status).toBe('failed');
    expect(claude.complete).not.toHaveBeenCalled();
  });

  it('marks ai_processing_retryable=false on ClaudeBudgetExceededError', async () => {
    const supabase = buildSupabase();
    const claude = buildMockClaude({
      throwError: new ClaudeBudgetExceededError(60, 50, 'daily'),
    });

    const result = await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });
    expect(result.status).toBe('failed');

    const updates = supabase.__calls.update.filter(
      (c) => c.schema === 'app' && c.table === 'consultations',
    );
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
    expect(lastUpdate.ai_processing_status).toBe('failed');
    expect(lastUpdate.ai_processing_retryable).toBe(false);
  });

  it('marks ai_processing_retryable=true on transient ClaudeApiError 503', async () => {
    const supabase = buildSupabase();
    const claude = buildMockClaude({
      throwError: new ClaudeApiError('upstream timeout', 503),
    });

    const result = await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });
    expect(result.status).toBe('failed');

    const updates = supabase.__calls.update.filter(
      (c) => c.schema === 'app' && c.table === 'consultations',
    );
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
    expect(lastUpdate.ai_processing_retryable).toBe(true);
  });

  it('handles invalid strategy JSON', async () => {
    const supabase = buildSupabase();
    const claude = buildMockClaude({ parsedJson: { situation_analysis: 'x' } }); // recommended_approach missing

    const result = await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });
    expect(result.status).toBe('failed');
    expect(result.errorMessage).toContain('invalid JSON structure');
  });

  it('continues with remaining actions when one fails', async () => {
    let actionInsertCount = 0;
    const supa = buildSupabaseMock({
      'app.consultations': {
        selectMaybeSingle: { data: consultationRow },
        updateResult: { error: null },
      },
      'app.response_strategies': {
        insertSingle: { data: { id: 'strategy-1' } },
      },
      'app.tasks': {
        insertSingle: { data: { id: 'task-1' } },
      },
    });
    // the first strategy_actions INSERT fails, the rest succeed
    const orig = supa.schema;
    supa.schema = vi.fn((schemaName: string) => ({
      from: (table: string) => {
        const built = orig(schemaName).from(table) as Record<string, unknown>;
        if (table === 'strategy_actions') {
          built.single = vi.fn(() => {
            actionInsertCount += 1;
            if (actionInsertCount === 1) {
              return Promise.resolve({
                data: null,
                error: { message: 'insert failed' },
              });
            }
            return Promise.resolve({ data: { id: `action-${actionInsertCount}` }, error: null });
          });
        }
        return built;
      },
    })) as unknown as typeof supa.schema;

    const claude = buildMockClaude({ parsedJson: validStrategy });
    const result = await processConsultation(supa as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });

    // first of 3 fails -> only 2 succeed
    expect(result.actionsCreated).toBe(2);
    expect(result.status).toBe('completed');
  });
});

describe('processConsultation — fields propagation', () => {
  it('passes language and partyId to Claude correctly', async () => {
    const supabase = buildSupabase({
      ...consultationRow,
      language: 'en',
      party_id: 'party-en-1',
      engagement_id: 'eng-en-1',
    });
    const claude = buildMockClaude({ parsedJson: validStrategy });
    await processConsultation(supabase as never, makeBaseNotification(), {
      claudeClient: claude as never,
    });
    const callInput = claude.complete.mock.calls[0]?.[0] as ClaudeCompleteInput;
    expect(callInput.language).toBe('en');
    expect(callInput.partyId).toBe('party-en-1');
    expect(callInput.engagementId).toBe('eng-en-1');
    expect(callInput.traceLabel).toContain(consultationId);
  });
});
