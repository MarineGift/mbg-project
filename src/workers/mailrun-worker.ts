/**
 * workers/mailrun-worker.ts
 *
 * Drains app.mail_runs / app.mail_run_recipients (the bulk mailing queue).
 * Background, persistent poll loop (matches the other workers). Removes the
 * synchronous action's 100-cap and timeout risk, paces by rate_per_minute,
 * tracks progress, and is resumable (a restart picks up where it left off).
 *
 * Sending reuses the proven core (sendOutboundEmail -> TabsMailer.sendOne), so
 * whitelist, template/signature render, communications insert (+ engagement
 * trigger), tracking and PII guard all behave exactly like a normal send.
 *
 * Run (persistent):  npx tsx --env-file=.env.local src/workers/mailrun-worker.ts
 * Run (drain once):  npx tsx --env-file=.env.local src/workers/mailrun-worker.ts --once
 *
 * Env: NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (service role bypasses RLS).
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import { sendOutboundEmail } from '../lib/email/send-outbound';
import type { SbClient } from '../lib/supabase/server';
import { createShutdownController, isMainEntry } from './runtime';

const POLL_INTERVAL_MS = 10_000;
const MAX_RUNS_PER_TICK = 3;

interface RunRow {
  id: string;
  organization_id: string;
  template_id: string;
  template_subject: string;
  mail_account_id: string;
  bypass_whitelist: boolean;
  rate_per_minute: number;
  concurrency: number;
  status: string;
}
interface RecipRow {
  id: string;
  party_id: string;
  contact_id: string | null;
  email: string;
}

/** per-tick send budget that approximates rate_per_minute over the poll cadence. */
function perTickBudget(ratePerMinute: number): number {
  return Math.max(1, Math.ceil((ratePerMinute * POLL_INTERVAL_MS) / 60_000));
}

/* ============================================================
 * processRunTick - claim + send one rate-limited batch for a run
 * ============================================================ */
export async function processRunTick(sb: SupabaseClient, run: RunRow): Promise<number> {
  const limit = perTickBudget(run.rate_per_minute);

  const { data: pendingRaw } = await sb
    .schema('app')
    .from('mail_run_recipients' as never)
    .select('id, party_id, contact_id, email')
    .eq('run_id', run.id)
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(limit);
  const batch = (pendingRaw ?? []) as unknown as RecipRow[];
  if (batch.length === 0) return 0;

  // claim the batch so an overlapping tick can't double-send
  await sb
    .schema('app')
    .from('mail_run_recipients' as never)
    .update({ status: 'sending' } as never)
    .in('id', batch.map((r) => r.id));

  const sbTyped = sb as unknown as SbClient;

  const sendOne = async (rec: RecipRow): Promise<void> => {
    let status: 'sent' | 'failed' | 'blocked' = 'failed';
    let communicationId: string | null = null;
    let error: string | null = null;
    try {
      const res = await sendOutboundEmail({
        supabase: sbTyped,
        organizationId: run.organization_id,
        to: rec.email,
        fromName: '',
        fromAddress: '',
        mailAccountId: run.mail_account_id,
        subject: run.template_subject,
        bodyHtml: '',
        merge: {
          partyId: rec.party_id,
          contactId: rec.contact_id ?? undefined,
          templateId: run.template_id,
        },
        partyId: rec.party_id,
        contactId: rec.contact_id,
        dealId: null,
        useSignature: true,
        skipWhitelist: run.bypass_whitelist,
        externalData: {
          source: 'bulk',
          mail_run_id: run.id,
          mail_run_recipient_id: rec.id,
          template_id: run.template_id,
        },
        traceLabel: `mailrun:${run.id}`,
      });
      status = res.status === 'sent' ? 'sent' : res.status === 'blocked' ? 'blocked' : 'failed';
      communicationId = res.communicationId ?? null;
      error = res.errorMessage ?? null;
    } catch (err) {
      status = 'failed';
      error = err instanceof Error ? err.message : 'send threw';
    }

    await sb
      .schema('app')
      .from('mail_run_recipients' as never)
      .update({
        status,
        communication_id: communicationId,
        error,
        attempts: 1,
        sent_at: status === 'sent' ? new Date().toISOString() : null,
      } as never)
      .eq('id', rec.id);
  };

  // bounded-concurrency pool
  let cursor = 0;
  const lanes = Math.min(run.concurrency, batch.length);
  const lane = async (): Promise<void> => {
    for (let i = cursor++; i < batch.length; i = cursor++) {
      const rec = batch[i];
      if (rec) await sendOne(rec);
    }
  };
  await Promise.all(Array.from({ length: Math.max(lanes, 0) }, () => lane()));

  return batch.length;
}

/* ============================================================
 * refreshRunStatus - recompute counters + mark completed
 * ============================================================ */
export async function refreshRunStatus(sb: SupabaseClient, runId: string): Promise<void> {
  const { data } = await sb
    .schema('app')
    .from('mail_run_recipients' as never)
    .select('status')
    .eq('run_id', runId);
  const rows = (data ?? []) as unknown as Array<{ status: string }>;

  let sent = 0;
  let failed = 0;
  let blocked = 0;
  let open = 0; // pending + sending
  for (const r of rows) {
    if (r.status === 'sent') sent += 1;
    else if (r.status === 'failed') failed += 1;
    else if (r.status === 'blocked') blocked += 1;
    else if (r.status === 'pending' || r.status === 'sending') open += 1;
  }

  const done = open === 0;
  await sb
    .schema('app')
    .from('mail_runs' as never)
    .update({
      sent_count: sent,
      failed_count: failed,
      blocked_count: blocked,
      status: done ? 'completed' : 'running',
      ...(done ? { completed_at: new Date().toISOString() } : {}),
    } as never)
    .eq('id', runId);
}

/* ============================================================
 * drainTick - one poll iteration across active runs
 * ============================================================ */
export async function drainTick(sb: SupabaseClient): Promise<number> {
  const { data: runsRaw } = await sb
    .schema('app')
    .from('mail_runs' as never)
    .select(
      'id, organization_id, template_id, template_subject, mail_account_id, bypass_whitelist, rate_per_minute, concurrency, status',
    )
    .in('status', ['queued', 'running'])
    // scheduled send: a queued run is held until its scheduled_at is due (null = asap);
    // running runs always continue regardless of scheduled_at.
    .or(`status.eq.running,scheduled_at.is.null,scheduled_at.lte.${new Date().toISOString()}`)
    .order('created_at', { ascending: true })
    .limit(MAX_RUNS_PER_TICK);
  const runs = (runsRaw ?? []) as unknown as RunRow[];

  let total = 0;
  for (const run of runs) {
    if (run.status === 'queued') {
      await sb
        .schema('app')
        .from('mail_runs' as never)
        .update({ status: 'running', started_at: new Date().toISOString() } as never)
        .eq('id', run.id);
    }
    total += await processRunTick(sb, run);
    await refreshRunStatus(sb, run.id);
  }
  return total;
}

/* ============================================================
 * main - persistent poll loop (or --once drain)
 * ============================================================ */
export async function runMailRunWorker(opts: { once?: boolean } = {}): Promise<void> {
  const once = opts.once ?? process.argv.includes('--once');
  const sb = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
  const ctl = createShutdownController('mailrun-worker');

  // eslint-disable-next-line no-console
  console.log(
    `[mailrun-worker] starting (once=${once}, poll=${POLL_INTERVAL_MS}ms, maxRuns/tick=${MAX_RUNS_PER_TICK})`,
  );

  if (once) {
    // drain until no work remains (bounded passes), then exit
    for (let i = 0; i < 1000; i += 1) {
      const n = await drainTick(sb);
      if (n === 0) break;
    }
    // eslint-disable-next-line no-console
    console.log('[mailrun-worker] --once drain complete');
    return;
  }

  while (!ctl.isShuttingDown()) {
    try {
      const n = await ctl.track(drainTick(sb));
      if (n > 0) {
        // eslint-disable-next-line no-console
        console.log(`[mailrun-worker] tick: sent ${n} recipient(s)`);
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[mailrun-worker] tick error:', err);
    }
    await ctl.sleep(POLL_INTERVAL_MS);
  }

  await ctl.waitForInflight(30_000);
  // eslint-disable-next-line no-console
  console.log('[mailrun-worker] shutdown complete');
}

if (isMainEntry(import.meta.url)) {
  runMailRunWorker().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[mailrun-worker] fatal:', err);
    process.exit(1);
  });
}
