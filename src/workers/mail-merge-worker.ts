import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { TabsMailerClient } from '@/lib/email/tabs-mailer';
import type {
  CampaignRecipient,
  CreateCampaignInput,
  QuietHours,
} from '@/types/email';

const POLL_INTERVAL_MS = 10_000;
const BATCH_SIZE = 5;
const MAX_RETRY_COUNT = 5;

export class MailMergeWorkerError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'MailMergeWorkerError';
  }
}

export async function pickAndProcessOnce(
  supabase: SupabaseClient,
  tabsClient: TabsMailerClient,
): Promise<{ processed: number; failed: number }> {
  const nowIso = new Date().toISOString();
  const { data: jobs, error } = await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .select('*')
    .eq('status', 'queued')
    .lte('scheduled_at', nowIso)
    .order('scheduled_at', { ascending: true })
    .limit(BATCH_SIZE);

  if (error) {
    throw new MailMergeWorkerError(
      `mail_merge_jobs query failed: ${error.message}`,
      error,
    );
  }

  if (!jobs || jobs.length === 0) {
    return { processed: 0, failed: 0 };
  }

  let processed = 0;
  let failed = 0;

  for (const jobRaw of jobs as Array<Record<string, unknown>>) {
    try {
      await processOneJob(supabase, tabsClient, jobRaw);
      processed += 1;
    } catch (err) {
      failed += 1;
      await markJobFailed(supabase, jobRaw, err as Error);
    }
  }

  return { processed, failed };
}

async function processOneJob(
  supabase: SupabaseClient,
  tabsClient: TabsMailerClient,
  job: Record<string, unknown>,
): Promise<void> {
  const jobId = String(job.id);
  const organizationId = String(job.organization_id);
  const retryCount = Number(job.retry_count ?? 0);

  // [1] running 락
  const { data: locked, error: lockErr } = await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .update({
      status: 'running',
      started_at: new Date().toISOString(),
    })
    .eq('id', jobId)
    .eq('status', 'queued')
    .select('id')
    .maybeSingle();

  if (lockErr || !locked) {
    return;
  }

  // [2] recipients 조회
  const { data: recipientRows, error: recipErr } = await supabase
    .schema('app')
    .from('mail_merge_recipients')
    .select(
      'id, communication_id, party_id, contact_id, to_email, to_name, variables',
    )
    .eq('mail_merge_job_id', jobId)
    .is('sent_at', null);

  if (recipErr) {
    throw new MailMergeWorkerError(
      `mail_merge_recipients query failed: ${recipErr.message}`,
    );
  }

  const recipients: CampaignRecipient[] = (recipientRows ?? []).map(
    (r: Record<string, unknown>) => ({
      partyId: optStr(r.party_id),
      contactId: optStr(r.contact_id),
      communicationId: String(r.communication_id),
      to: {
        address: String(r.to_email),
        name: optStr(r.to_name),
      },
      variables: (r.variables as Record<string, string | number>) ?? {},
    }),
  );

  if (recipients.length === 0) {
    await supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
      })
      .eq('id', jobId);
    return;
  }

  // [3] 캠페인 생성·발송
  const campaignInput: CreateCampaignInput = {
    name: String(job.name ?? `merge-${jobId}`),
    mergeJobId: jobId,
    fromAddress: String(job.from_address),
    fromName: optStr(job.from_name),
    replyToAddress: optStr(job.reply_to_address),
    subjectTemplate: String(job.subject_template ?? ''),
    bodyHtmlTemplate: optStr(job.body_html_template),
    bodyPlainTemplate: optStr(job.body_plain_template),
    recipients,
    scheduledAt: optStr(job.scheduled_at),
    rateLimitPerMinute: optNum(job.rate_limit_per_minute),
    rateLimitPerHour: optNum(job.rate_limit_per_hour),
    quietHours: parseQuietHours(job.quiet_hours),
    urmCampaignHeaders: {
      autoSend: false,
      engagementId: optStr(job.engagement_id),
      brandVoiceId: optStr(job.brand_voice_id),
    },
  };

  const result = await tabsClient.createCampaign(campaignInput);

  // [4] 캠페인 ID·진행 상태 갱신
  const allRejected = result.rejectedCount === recipients.length;
  await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .update({
      tabs_campaign_id: result.tabsCampaignId,
      status: allRejected ? 'failed' : 'completed',
      completed_at: new Date().toISOString(),
      retry_count: retryCount,
    })
    .eq('id', jobId);

  // [5] recipients sent_at
  await supabase
    .schema('app')
    .from('mail_merge_recipients')
    .update({ sent_at: new Date().toISOString() })
    .eq('mail_merge_job_id', jobId)
    .is('sent_at', null);

  try {
    await tabsClient.syncCampaignToMergeJob(jobId);
  } catch {
    // ignore
  }

  void organizationId;
}

async function markJobFailed(
  supabase: SupabaseClient,
  job: Record<string, unknown>,
  err: Error,
): Promise<void> {
  const jobId = String(job.id);
  const newRetryCount = Number(job.retry_count ?? 0) + 1;
  const finalFail = newRetryCount >= MAX_RETRY_COUNT;

  await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .update({
      status: finalFail ? 'failed' : 'queued',
      retry_count: newRetryCount,
      last_error_message: err.message,
      last_error_at: new Date().toISOString(),
      scheduled_at: finalFail
        ? null
        : new Date(Date.now() + 60_000 * newRetryCount).toISOString(),
    })
    .eq('id', jobId);

  // eslint-disable-next-line no-console
  console.error(
    `[mail-merge-worker] job ${jobId} failed (retry=${newRetryCount}): ${err.message}`,
  );
}

function optStr(v: unknown): string | undefined {
  if (v === null || v === undefined) return undefined;
  return String(v);
}

function optNum(v: unknown): number | undefined {
  if (v === null || v === undefined) return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
}

function parseQuietHours(v: unknown): QuietHours | undefined {
  if (!v || typeof v !== 'object') return undefined;
  const r = v as Record<string, unknown>;
  if (
    typeof r.timezone !== 'string'
    || typeof r.start !== 'string'
    || typeof r.end !== 'string'
  ) {
    return undefined;
  }
  return {
    timezone: r.timezone,
    start: r.start,
    end: r.end,
    daysOfWeek: Array.isArray(r.daysOfWeek)
      ? (r.daysOfWeek as number[])
      : Array.isArray(r.days_of_week)
        ? (r.days_of_week as number[])
        : undefined,
  };
}

async function main(): Promise<void> {
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
  );
  const tabsClient = new TabsMailerClient(supabase);

  let isShuttingDown = false;
  let currentCycle: Promise<unknown> | null = null;

  const runCycle = async (): Promise<void> => {
    try {
      await pickAndProcessOnce(supabase, tabsClient);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[mail-merge-worker] cycle error:', (err as Error).message);
    }
  };

  const shutdown = async (signal: string): Promise<void> => {
    if (isShuttingDown) return;
    isShuttingDown = true;
    // eslint-disable-next-line no-console
    console.log(`[mail-merge-worker] received ${signal}, draining...`);
    if (currentCycle) {
      await currentCycle.catch(() => {});
    }
    tabsClient.close();
    process.exit(0);
  };

  process.on('SIGTERM', () => {
    void shutdown('SIGTERM');
  });
  process.on('SIGINT', () => {
    void shutdown('SIGINT');
  });

  // eslint-disable-next-line no-console
  console.log('[mail-merge-worker] polling started');

  while (!isShuttingDown) {
    currentCycle = runCycle();
    await currentCycle;
    currentCycle = null;
    if (isShuttingDown) break;
    await sleep(POLL_INTERVAL_MS);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

if (require.main === module) {
  main().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[mail-merge-worker] fatal:', err);
    process.exit(1);
  });
}
