import pg from 'pg';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { ClaudeClient } from '@/lib/ai/claude-client';
import type { StrategyAdvisorOutput } from '@/types/ai';

// ───────────────────────────────────────────────────────────────────
// 페이로드
// ───────────────────────────────────────────────────────────────────

export interface ConsultationNotification {
  consultation_id: string;
  organization_id: string;
  module?: string;
  priority?: string;
  urgency?: string;
}

export class ConsultationWorkerError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'ConsultationWorkerError';
  }
}

// ───────────────────────────────────────────────────────────────────
// 핵심 비즈니스 로직
// ───────────────────────────────────────────────────────────────────

export async function processConsultation(
  supabase: SupabaseClient,
  notification: ConsultationNotification,
  claudeClientFactory: (orgId: string) => ClaudeClient = (orgId) =>
    new ClaudeClient(supabase, orgId),
): Promise<{ status: 'processed' | 'failed' | 'skipped'; reason?: string }> {
  const { consultation_id, organization_id } = notification;

  // [1] consultation 조회
  const { data: consultation, error: loadErr } = await supabase
    .schema('app')
    .from('consultations')
    .select('*')
    .eq('id', consultation_id)
    .eq('organization_id', organization_id)
    .maybeSingle();

  if (loadErr || !consultation) {
    return { status: 'skipped', reason: 'consultation_not_found' };
  }

  const c = consultation as Record<string, unknown>;
  const currentStatus = String(c.ai_processing_status ?? 'pending');
  if (currentStatus === 'processed') {
    return { status: 'skipped', reason: 'already_processed' };
  }

  // [2] processing 락
  await supabase
    .schema('app')
    .from('consultations')
    .update({
      ai_processing_status: 'processing',
      ai_processing_started_at: new Date().toISOString(),
    })
    .eq('id', consultation_id);

  // [3] Strategy Advisor 호출
  let advisorOutput: StrategyAdvisorOutput;
  try {
    const claudeClient = claudeClientFactory(organization_id);
    const result = await claudeClient.complete({
      agentRole: 'strategy_advisor',
      module: typeof c.module === 'string' ? c.module : undefined,
      partyId: typeof c.party_id === 'string' ? c.party_id : undefined,
      engagementId:
        typeof c.engagement_id === 'string' ? c.engagement_id : undefined,
      inboundMessage: buildAdvisorContext(c),
      outputFormat: 'json',
      caller: 'consultation-worker',
    });
    advisorOutput = parseAdvisorOutput(result.parsedJson);
  } catch (err) {
    await supabase
      .schema('app')
      .from('consultations')
      .update({
        ai_processing_status: 'failed',
        ai_processing_error: (err as Error).message,
      })
      .eq('id', consultation_id);
    // eslint-disable-next-line no-console
    console.error(
      `[consultation-worker] advisor failed for ${consultation_id}:`,
      (err as Error).message,
    );
    return { status: 'failed', reason: 'advisor_failed' };
  }

  // [4] response_strategies + strategy_actions INSERT
  try {
    await persistAdvisorOutput(
      supabase,
      organization_id,
      consultation_id,
      advisorOutput,
    );
  } catch (err) {
    await supabase
      .schema('app')
      .from('consultations')
      .update({
        ai_processing_status: 'failed',
        ai_processing_error: (err as Error).message,
      })
      .eq('id', consultation_id);
    return { status: 'failed', reason: 'persist_failed' };
  }

  // [5] processed
  await supabase
    .schema('app')
    .from('consultations')
    .update({
      ai_processing_status: 'processed',
      ai_processing_completed_at: new Date().toISOString(),
      ai_summary: advisorOutput.summary,
    })
    .eq('id', consultation_id);

  return { status: 'processed' };
}

function buildAdvisorContext(c: Record<string, unknown>): string {
  const lines: string[] = [];
  lines.push(`Consultation ID: ${String(c.id)}`);
  if (c.module) lines.push(`Module: ${String(c.module)}`);
  if (c.priority) lines.push(`Priority: ${String(c.priority)}`);
  if (c.urgency) lines.push(`Urgency: ${String(c.urgency)}`);
  if (c.title) lines.push(`Title: ${String(c.title)}`);
  if (c.description) {
    lines.push('');
    lines.push('Description:');
    lines.push(String(c.description));
  }
  if (c.context && typeof c.context === 'object') {
    lines.push('');
    lines.push('Additional Context:');
    lines.push(JSON.stringify(c.context, null, 2));
  }
  return lines.join('\n');
}

function parseAdvisorOutput(parsed: object | undefined): StrategyAdvisorOutput {
  if (!parsed || typeof parsed !== 'object') {
    throw new ConsultationWorkerError(
      'Strategy advisor returned non-JSON response',
    );
  }
  const r = parsed as Record<string, unknown>;
  const summary = typeof r.summary === 'string' ? r.summary : '';
  const strategiesRaw = Array.isArray(r.responseStrategies)
    ? r.responseStrategies
    : Array.isArray(r.response_strategies)
      ? r.response_strategies
      : [];

  const strategies: StrategyAdvisorOutput['responseStrategies'] = [];
  for (const s of strategiesRaw) {
    if (!s || typeof s !== 'object') continue;
    const sr = s as Record<string, unknown>;
    const actionsRaw = Array.isArray(sr.actions) ? sr.actions : [];
    const actions = actionsRaw
      .filter((a): a is Record<string, unknown> => !!a && typeof a === 'object')
      .map((a) => ({
        title: String(a.title ?? ''),
        description: String(a.description ?? ''),
        due_in_days:
          typeof a.due_in_days === 'number' ? a.due_in_days : undefined,
        assigned_role:
          typeof a.assigned_role === 'string' ? a.assigned_role : undefined,
        priority: pickPriority(a.priority),
      }))
      .filter((a) => a.title.length > 0);

    strategies.push({
      title: String(sr.title ?? ''),
      rationale: String(sr.rationale ?? ''),
      confidence: typeof sr.confidence === 'number' ? sr.confidence : 0.5,
      actions,
    });
  }

  const riskNotesRaw = Array.isArray(r.riskNotes)
    ? r.riskNotes
    : Array.isArray(r.risk_notes)
      ? r.risk_notes
      : [];
  const riskNotes = riskNotesRaw.filter((x): x is string => typeof x === 'string');

  return { summary, responseStrategies: strategies, riskNotes };
}

function pickPriority(
  v: unknown,
): 'low' | 'medium' | 'high' | 'urgent' | undefined {
  if (v === 'low' || v === 'medium' || v === 'high' || v === 'urgent') return v;
  return undefined;
}

async function persistAdvisorOutput(
  supabase: SupabaseClient,
  organizationId: string,
  consultationId: string,
  output: StrategyAdvisorOutput,
): Promise<void> {
  for (const strategy of output.responseStrategies) {
    const { data: stratRow, error: stratErr } = await supabase
      .schema('app')
      .from('response_strategies')
      .insert({
        organization_id: organizationId,
        consultation_id: consultationId,
        title: strategy.title,
        rationale: strategy.rationale,
        confidence: strategy.confidence,
        ai_generated: true,
      })
      .select('id')
      .single();

    if (stratErr || !stratRow) {
      throw new ConsultationWorkerError(
        `response_strategies INSERT failed: ${stratErr?.message ?? 'no data'}`,
      );
    }
    const strategyId = String((stratRow as { id: string }).id);

    if (strategy.actions.length === 0) continue;

    const actionRows = strategy.actions.map((a) => ({
      organization_id: organizationId,
      response_strategy_id: strategyId,
      title: a.title,
      description: a.description,
      due_in_days: a.due_in_days ?? null,
      assigned_role: a.assigned_role ?? null,
      priority: a.priority ?? 'medium',
      status: 'todo',
    }));

    const { error: actionsErr } = await supabase
      .schema('app')
      .from('strategy_actions')
      .insert(actionRows);

    if (actionsErr) {
      throw new ConsultationWorkerError(
        `strategy_actions INSERT failed: ${actionsErr.message}`,
      );
    }
  }
}

// ───────────────────────────────────────────────────────────────────
// LISTEN/NOTIFY 메인 루프
// ───────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
  );

  const pgClient = new pg.Client({ connectionString: env.SUPABASE_DB_URL });
  await pgClient.connect();
  await pgClient.query('LISTEN consultation_created');

  let isShuttingDown = false;
  const inflight = new Set<Promise<void>>();

  pgClient.on('notification', (msg) => {
    if (isShuttingDown) return;
    if (msg.channel !== 'consultation_created') return;
    if (!msg.payload) return;

    let notification: ConsultationNotification;
    try {
      notification = JSON.parse(msg.payload) as ConsultationNotification;
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[consultation-worker] payload parse failed:', err);
      return;
    }

    const promise = processConsultation(supabase, notification)
      .then((result) => {
        if (result.status === 'failed') {
          // eslint-disable-next-line no-console
          console.error(
            `[consultation-worker] processConsultation failed: ${notification.consultation_id} reason=${result.reason}`,
          );
        }
      })
      .catch((err) => {
        // eslint-disable-next-line no-console
        console.error(
          `[consultation-worker] unhandled error: ${notification.consultation_id}:`,
          err,
        );
      })
      .finally(() => {
        inflight.delete(promise);
      });
    inflight.add(promise);
  });

  pgClient.on('error', (err) => {
    // eslint-disable-next-line no-console
    console.error('[consultation-worker] pg error:', err.message);
  });

  const shutdown = async (signal: string): Promise<void> => {
    if (isShuttingDown) return;
    isShuttingDown = true;
    // eslint-disable-next-line no-console
    console.log(
      `[consultation-worker] received ${signal}, draining ${inflight.size} inflight tasks...`,
    );
    await Promise.allSettled(Array.from(inflight));
    try {
      await pgClient.end();
    } catch {
      // ignore
    }
    process.exit(0);
  };

  process.on('SIGTERM', () => {
    void shutdown('SIGTERM');
  });
  process.on('SIGINT', () => {
    void shutdown('SIGINT');
  });

  // eslint-disable-next-line no-console
  console.log('[consultation-worker] listening on consultation_created');
}

if (require.main === module) {
  main().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[consultation-worker] fatal:', err);
    process.exit(1);
  });
}
