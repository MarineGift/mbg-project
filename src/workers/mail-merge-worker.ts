/**
 * workers/mail-merge-worker.ts
 *
 * Polls the mail_merge_jobs table and processes queued jobs:
 *   1. fetch N jobs whose status is queued and whose scheduled_at has arrived
 *   2. if there is no tabs_campaign_id, call TABS Mailer createCampaign
 *   3. update the job status to running
 *   4. sync statistics (syncCampaignToMergeJob) - a separate 5-minute cycle is recommended, but this worker does it too
 *   5. on failure, exponential backoff retry (status='failed' when max_retries is reached)
 *
 * Recipient-list resolution (recipient_filter jsonb -> SQL -> send) will be added after STEP 7 operational details are received.
 * In this STEP 3, focus on campaign registration and status sync.
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import {
  createTabsMailer,
  TabsMailerError,
  TabsMailerNotImplementedError,
  type ITabsMailerClient,
} from '../lib/email/tabs-mailer';
import { evaluateQuietHours } from '../lib/email/quiet-hours';
import {
  mapMailMergeJobRow,
  type MailMergeJobRow,
} from '../types/email';
import { createShutdownController, isMainEntry } from './runtime';

const POLL_INTERVAL_MS = 10_000;
const BATCH_SIZE = 5;
const STATS_SYNC_BATCH_SIZE = 10;

export interface ProcessJobOptions {
  /** Inject TabsMailer in unit tests. */
  mailer?: ITabsMailerClient;
  /** Freeze the clock. */
  nowProvider?: () => Date;
}

export interface ProcessJobResult {
  jobId: string;
  status: 'started' | 'rescheduled_quiet_hours' | 'failed' | 'skipped';
  tabsCampaignId?: string;
  errorMessage?: string;
  nextSendAt?: string;
}

/* ============================================================
 * 1. processOneJob - process a single job (test surface)
 * ============================================================ */

export async function processOneJob(
  supabase: SupabaseClient,
  job: MailMergeJobRow,
  options: ProcessJobOptions = {},
): Promise<ProcessJobResult> {
  const now = options.nowProvider ?? (() => new Date());

  // compliance: skip if legal approval is required but not granted
  if (job.requiresLegalApproval && !job.legalApprovedAt) {
    return {
      jobId: job.id,
      status: 'skipped',
      errorMessage: 'legal_approval_pending',
    };
  }

  // quiet hours pre-check - if blocked on entry, defer to next_send_at
  const quiet = evaluateQuietHours(job.quietHours, now());
  if (quiet.blocked) {
    await supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update({
        scheduled_at: quiet.nextAllowedAt ?? new Date(now().getTime() + 30 * 60_000).toISOString(),
        last_error_message: `quiet_hours_blocked:${quiet.reason ?? 'unknown'}`,
      })
      .eq('id', job.id)
      .eq('organization_id', job.organizationId);

    return {
      jobId: job.id,
      status: 'rescheduled_quiet_hours',
      nextSendAt: quiet.nextAllowedAt,
    };
  }

  const mailer = options.mailer ?? (await createTabsMailer());

  try {
    // register the campaign if not yet registered
    let tabsCampaignId = job.tabsCampaignId;
    if (!tabsCampaignId) {
      const created = await mailer.createCampaign({
        name: job.name,
        description: job.description,
        templateId: job.templateId,
        scheduledAt: job.scheduledAt ? new Date(job.scheduledAt) : undefined,
        recipientCount: job.estimatedRecipientCount ?? 0,
        fromAddress: job.fromAddress,
        fromName: job.fromName,
        replyToAddress: job.replyToAddress,
      });
      tabsCampaignId = created.tabsCampaignId;

      await supabase
        .schema('app')
        .from('mail_merge_jobs')
        .update({
          tabs_campaign_id: tabsCampaignId,
          tabs_campaign_status: 'created',
          status: 'running',
          started_at: now().toISOString(),
        })
        .eq('id', job.id)
        .eq('organization_id', job.organizationId);
    }

    return {
      jobId: job.id,
      status: 'started',
      tabsCampaignId,
    };
  } catch (err) {
    return await handleJobFailure(supabase, job, err, now());
  }
}

/* ============================================================
 * 2. failure handling - exponential backoff
 * ============================================================ */

async function handleJobFailure(
  supabase: SupabaseClient,
  job: MailMergeJobRow,
  err: unknown,
  now: Date,
): Promise<ProcessJobResult> {
  const errorMessage = err instanceof Error ? err.message : String(err);
  const newRetryCount = job.retryCount + 1;
  const isPermanent = err instanceof TabsMailerNotImplementedError;
  const maxRetriesReached = newRetryCount >= job.maxRetries;
  const shouldFail = isPermanent || maxRetriesReached;

  const backoffSec = Math.min(Math.pow(2, newRetryCount) * 60, 3600);
  const rescheduleAt = new Date(now.getTime() + backoffSec * 1000).toISOString();

  await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .update({
      status: shouldFail ? 'failed' : 'queued',
      retry_count: newRetryCount,
      error_message: errorMessage,
      last_error_at: now.toISOString(),
      scheduled_at: shouldFail ? job.scheduledAt : rescheduleAt,
    })
    .eq('id', job.id)
    .eq('organization_id', job.organizationId);

  return {
    jobId: job.id,
    status: 'failed',
    errorMessage,
    nextSendAt: shouldFail ? undefined : rescheduleAt,
  };
}

/* ============================================================
 * 3. processQueueBatch - process the queue in a batch
 * ============================================================ */

export async function processQueueBatch(
  supabase: SupabaseClient,
  options: ProcessJobOptions = {},
): Promise<ProcessJobResult[]> {
  const now = options.nowProvider ?? (() => new Date());

  const { data: jobsRaw, error } = await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .select('*')
    .eq('status', 'queued')
    .lte('scheduled_at', now().toISOString())
    .order('scheduled_at', { ascending: true })
    .limit(BATCH_SIZE);

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[mail-merge-worker] queue fetch failed:', error);
    return [];
  }

  if (!jobsRaw || jobsRaw.length === 0) return [];

  const results: ProcessJobResult[] = [];
  for (const raw of jobsRaw) {
    const job = mapMailMergeJobRow(raw as Record<string, unknown>);
    const r = await processOneJob(supabase, job, options);
    results.push(r);
  }
  return results;
}

/* ============================================================
 * 4. syncRunningCampaigns - sync statistics for running campaigns
 * ============================================================ */

export async function syncRunningCampaigns(
  supabase: SupabaseClient,
  organizationIds: string[],
  options: ProcessJobOptions = {},
): Promise<{ synced: number; failed: number }> {
  if (organizationIds.length === 0) return { synced: 0, failed: 0 };

  const { data: jobsRaw } = await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .select('id, organization_id, tabs_campaign_id')
    .eq('status', 'running')
    .in('organization_id', organizationIds)
    .not('tabs_campaign_id', 'is', null)
    .limit(STATS_SYNC_BATCH_SIZE);

  if (!jobsRaw || jobsRaw.length === 0) return { synced: 0, failed: 0 };

  const mailer = options.mailer ?? (await createTabsMailer());
  let synced = 0;
  let failed = 0;
  for (const j of jobsRaw) {
    try {
      await mailer.syncCampaignToMergeJob(
        supabase,
        j.organization_id as string,
        j.id as string,
      );
      synced += 1;
    } catch (err) {
      failed += 1;
      if (err instanceof TabsMailerNotImplementedError) {
        // operational details not received - stop trying
        // eslint-disable-next-line no-console
        console.warn(
          '[mail-merge-worker] sync skipped: TABS spec not implemented',
        );
        break;
      }
      if (err instanceof TabsMailerError) {
        // eslint-disable-next-line no-console
        console.error(
          `[mail-merge-worker] sync failed for job=${j.id}:`,
          err.message,
        );
      }
    }
  }
  return { synced, failed };
}

/* ============================================================
 * 5. main - polling loop + graceful shutdown
 * ============================================================ */

async function main(): Promise<void> {
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
  );
  const ctl = createShutdownController('mail-merge-worker');

  // eslint-disable-next-line no-console
  console.log(
    `[mail-merge-worker] starting (poll interval=${POLL_INTERVAL_MS}ms, batch=${BATCH_SIZE})`,
  );

  while (!ctl.isShuttingDown()) {
    try {
      const results = await ctl.track(processQueueBatch(supabase));
      if (results.length > 0) {
        // eslint-disable-next-line no-console
        console.log(
          `[mail-merge-worker] iteration: processed ${results.length} job(s)`,
        );
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[mail-merge-worker] iteration error:', err);
    }
    await ctl.sleep(POLL_INTERVAL_MS);
  }

  await ctl.waitForInflight(30_000);
  // eslint-disable-next-line no-console
  console.log('[mail-merge-worker] shutdown complete');
}

if (isMainEntry(import.meta.url)) {
  main().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[mail-merge-worker] fatal:', err);
    process.exit(1);
  });
}
