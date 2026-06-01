/**
 * workers/consultation-worker.ts
 *
 * Subscribes to the Postgres LISTEN consultation_created channel and, for each new consultation,
 * calls the strategy_advisor agent and generates:
 *   - 1 response_strategies row
 *   - N strategy_actions rows (immediate / short_term / long_term)
 *   - immediate actions auto-create tasks + a linked_task_id back-link
 *
 * Structure:
 *   - processConsultation(): unit-testable core logic
 *   - main(): pg LISTEN loop + graceful shutdown
 *
 * Why pg.Client is used directly:
 *   Supabase JS does not support LISTEN/NOTIFY. Connect directly via SUPABASE_DB_URL.
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import pg from 'pg';
import { env } from '../lib/env';
import {
  ClaudeClient,
  ClaudeApiError,
  ClaudeBudgetExceededError,
} from '../lib/ai/claude-client';
import { createShutdownController, isMainEntry } from './runtime';

/* ============================================================
 * 1. Types
 * ============================================================ */

export interface ConsultationNotification {
  consultation_id: string;
  organization_id: string;
  priority?: string;
  urgency?: string;
  party_type?: string | null;
}

export interface ProcessConsultationResult {
  consultationId: string;
  strategyId?: string;
  actionsCreated: number;
  tasksCreated: number;
  status: 'completed' | 'failed';
  errorMessage?: string;
}

export interface ProcessConsultationOptions {
  /** Inject ClaudeClient in unit tests. */
  claudeClient?: ClaudeClient;
  /** Freeze the clock in unit tests. */
  nowProvider?: () => Date;
}

interface StrategyData {
  situation_analysis: string;
  key_signals?: string[];
  recommended_approach: string;
  key_messages?: string[];
  risks_to_avoid?: string[];
  questions_to_ask_internally?: string[];
  confidence_score: number;
  requires_human_review?: boolean;
  requires_legal_review?: boolean;
  requires_finance_review?: boolean;
  actions?: Array<{
    title: string;
    description: string;
    action_type: 'immediate' | 'short_term' | 'long_term';
    priority?: string;
    suggested_due_in_hours?: number;
    suggested_due_in_days?: number;
    rationale?: string;
    sort_order?: number;
  }>;
}

/* ============================================================
 * 2. processConsultation - core logic (test surface)
 * ============================================================ */

export async function processConsultation(
  supabase: SupabaseClient,
  notification: ConsultationNotification,
  options: ProcessConsultationOptions = {},
): Promise<ProcessConsultationResult> {
  const { consultation_id: consultationId, organization_id: orgId } = notification;
  const now = options.nowProvider ?? (() => new Date());

  // [1] look up the consultation
  const { data: consultation, error: consultError } = await supabase
    .schema('app')
    .from('consultations')
    .select(
      'id, organization_id, party_id, engagement_id, party_type, content_raw, content_processed, language, priority, urgency, ai_processing_status',
    )
    .eq('id', consultationId)
    .eq('organization_id', orgId)
    .maybeSingle();

  if (consultError || !consultation) {
    return {
      consultationId,
      actionsCreated: 0,
      tasksCreated: 0,
      status: 'failed',
      errorMessage: consultError?.message ?? 'consultation not found',
    };
  }

  // idempotency: skip if already processed
  if (consultation.ai_processing_status === 'completed') {
    return {
      consultationId,
      actionsCreated: 0,
      tasksCreated: 0,
      status: 'completed',
      errorMessage: 'already_completed',
    };
  }

  // [2] mark processing
  await supabase
    .schema('app')
    .from('consultations')
    .update({
      ai_processing_status: 'processing',
      ai_processing_started_at: now().toISOString(),
    })
    .eq('id', consultationId)
    .eq('organization_id', orgId);

  try {
    // [3] call strategy_advisor
    const claude = options.claudeClient ?? new ClaudeClient(supabase, orgId);
    const inboundMessage =
      (consultation.content_processed as string | null) ??
      (consultation.content_raw as string | null) ??
      '';
    const language = ((consultation.language as string | null) ?? 'ko') as 'ko' | 'en' | 'ja';

    const result = await claude.complete({
      agentRole: 'strategy_advisor',
      inboundMessage,
      partyId: (consultation.party_id as string | null) ?? undefined,
      engagementId: (consultation.engagement_id as string | null) ?? undefined,
      language,
      outputFormat: 'json',
      traceLabel: `consultation:${consultationId}`,
    });

    const strategyData = result.parsedJson as StrategyData | undefined;
    if (!strategyData || typeof strategyData.recommended_approach !== 'string') {
      throw new Error('strategy_advisor returned invalid JSON structure');
    }

    // [4] response_strategies INSERT
    const { data: strategyRow, error: strategyError } = await supabase
      .schema('app')
      .from('response_strategies')
      .insert({
        organization_id: orgId,
        consultation_id: consultationId,
        engagement_id: consultation.engagement_id ?? null,
        party_id: consultation.party_id ?? null,
        party_type: consultation.party_type ?? null,
        run_id: result.runId,
        ai_generated: true,
        situation_analysis: strategyData.situation_analysis,
        key_signals: strategyData.key_signals ?? [],
        recommended_approach: strategyData.recommended_approach,
        key_messages: strategyData.key_messages ?? [],
        risks_to_avoid: strategyData.risks_to_avoid ?? [],
        questions_to_ask_internally:
          strategyData.questions_to_ask_internally ?? [],
        confidence_score: strategyData.confidence_score,
        requires_human_review: strategyData.requires_human_review ?? true,
        requires_legal_review: strategyData.requires_legal_review ?? false,
        requires_finance_review: strategyData.requires_finance_review ?? false,
        raw_ai_output: strategyData,
        status: 'draft',
      })
      .select('id')
      .single();

    if (strategyError || !strategyRow) {
      throw new Error(
        `response_strategies INSERT failed: ${strategyError?.message ?? 'unknown'}`,
      );
    }

    const strategyId = strategyRow.id as string;

    // [5] strategy_actions + tasks (immediate)
    let actionsCreated = 0;
    let tasksCreated = 0;
    for (const action of strategyData.actions ?? []) {
      const { data: actionRow, error: actionError } = await supabase
        .schema('app')
        .from('strategy_actions')
        .insert({
          organization_id: orgId,
          strategy_id: strategyId,
          title: action.title,
          description: action.description,
          action_type: action.action_type,
          priority: action.priority ?? 'medium',
          suggested_due_in_hours: action.suggested_due_in_hours ?? null,
          suggested_due_in_days: action.suggested_due_in_days ?? null,
          rationale: action.rationale ?? null,
          sort_order: action.sort_order ?? 0,
        })
        .select('id')
        .single();

      if (actionError || !actionRow) {
        // a single action failure does not affect the next action
        // eslint-disable-next-line no-console
        console.error(
          `[consultation-worker] strategy_action INSERT failed:`,
          actionError,
        );
        continue;
      }
      actionsCreated += 1;

      if (action.action_type === 'immediate') {
        const dueAt =
          action.suggested_due_in_hours !== undefined &&
          action.suggested_due_in_hours !== null
            ? new Date(
                now().getTime() + action.suggested_due_in_hours * 3_600_000,
              ).toISOString()
            : null;

        // app.tasks is deal-scoped: deal_id is NOT NULL, and consultation.engagement_id
        // IS the deal id. There is no party_id / engagement_id / party_type /
        // linked_strategy_action_id column on app.tasks. Skip task creation when the
        // consultation has no deal; keep the action link in extra_data for traceability
        // (the reverse strategy_actions.linked_task_id back-link is set below).
        const dealId = (consultation.engagement_id as string | null) ?? null;
        const taskRow = dealId
          ? (
              await supabase
                .schema('app')
                .from('tasks')
                .insert({
                  organization_id: orgId,
                  deal_id: dealId,
                  title: action.title,
                  description: action.description,
                  priority: action.priority ?? 'high',
                  status: 'todo',
                  due_at: dueAt,
                  extra_data: { linked_strategy_action_id: actionRow.id },
                })
                .select('id')
                .single()
            ).data
          : null;

        if (taskRow) {
          tasksCreated += 1;
          await supabase
            .schema('app')
            .from('strategy_actions')
            .update({ linked_task_id: taskRow.id })
            .eq('id', actionRow.id);
        }
      }
    }

    // [6] mark the consultation complete
    await supabase
      .schema('app')
      .from('consultations')
      .update({
        ai_processing_status: 'completed',
        ai_processing_completed_at: now().toISOString(),
      })
      .eq('id', consultationId)
      .eq('organization_id', orgId);

    return {
      consultationId,
      strategyId,
      actionsCreated,
      tasksCreated,
      status: 'completed',
    };
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    const isBudget = err instanceof ClaudeBudgetExceededError;
    const isApiTransient =
      err instanceof ClaudeApiError &&
      (err.status === undefined || err.status >= 500 || err.status === 429);

    await supabase
      .schema('app')
      .from('consultations')
      .update({
        ai_processing_status: 'failed',
        ai_processing_error_message: errorMessage,
        ai_processing_failed_at: now().toISOString(),
        ai_processing_retryable: isApiTransient && !isBudget,
      })
      .eq('id', consultationId)
      .eq('organization_id', orgId);

    return {
      consultationId,
      actionsCreated: 0,
      tasksCreated: 0,
      status: 'failed',
      errorMessage,
    };
  }
}

/* ============================================================
 * 3. main - pg LISTEN loop + graceful shutdown
 * ============================================================ */

async function main(): Promise<void> {
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
  );

  const pgClient = new pg.Client({ connectionString: env.SUPABASE_DB_URL });
  await pgClient.connect();
  await pgClient.query('LISTEN consultation_created');

  const ctl = createShutdownController('consultation-worker');

  pgClient.on('notification', (msg) => {
    if (ctl.isShuttingDown()) return;
    if (msg.channel !== 'consultation_created' || !msg.payload) return;
    let parsed: ConsultationNotification;
    try {
      parsed = JSON.parse(msg.payload) as ConsultationNotification;
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[consultation-worker] payload parse failed:', err);
      return;
    }
    if (!parsed.consultation_id || !parsed.organization_id) return;

    void ctl.track(
      processConsultation(supabase, parsed)
        .then((result) => {
          // eslint-disable-next-line no-console
          console.log(
            `[consultation-worker] processed consultation=${result.consultationId} status=${result.status} actions=${result.actionsCreated} tasks=${result.tasksCreated}`,
          );
        })
        .catch((err) => {
          // eslint-disable-next-line no-console
          console.error(
            `[consultation-worker] processConsultation threw:`,
            err,
          );
        }),
    );
  });

  // eslint-disable-next-line no-console
  console.log('[consultation-worker] listening on consultation_created');

  // wait until the shutdown signal arrives - repeated short waits instead of sleep(Infinity)
  while (!ctl.isShuttingDown()) {
    await ctl.sleep(60_000);
  }

  // graceful shutdown
  await ctl.waitForInflight(30_000);
  try {
    await pgClient.query('UNLISTEN consultation_created');
    await pgClient.end();
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn('[consultation-worker] pg client cleanup error:', err);
  }
  // eslint-disable-next-line no-console
  console.log('[consultation-worker] shutdown complete');
}

if (isMainEntry(import.meta.url)) {
  main().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[consultation-worker] fatal:', err);
    process.exit(1);
  });
}
