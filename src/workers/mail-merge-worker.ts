/**
 * workers/mail-merge-worker.ts
 *
 * mail_merge_jobs 테이블을 폴링해 큐에 들어온 잡을 처리:
 *   1. 잡 상태가 queued이고 scheduled_at이 도달한 잡 N건 fetch
 *   2. tabs_campaign_id가 없으면 TABS Mailer createCampaign 호출
 *   3. 잡 상태를 running으로 갱신
 *   4. 통계 동기화 (syncCampaignToMergeJob) — 별도 5분 주기 권장이나 본 워커가 함께 수행
 *   5. 실패 시 exponential backoff retry (max_retries 도달 시 status='failed')
 *
 * 수신자 명단 해석(recipient_filter jsonb → SQL → 발송)은 STEP 7 운영 정보 수령 후
 * 추가. 본 STEP 3에서는 캠페인 등록·상태 동기화에 집중.
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
  /** 단위 테스트에서 TabsMailer를 주입. */
  mailer?: ITabsMailerClient;
  /** 시각 고정. */
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
 * 1. processOneJob — 단일 잡 처리 (테스트 표면)
 * ============================================================ */

export async function processOneJob(
  supabase: SupabaseClient,
  job: MailMergeJobRow,
  options: ProcessJobOptions = {},
): Promise<ProcessJobResult> {
  const now = options.nowProvider ?? (() => new Date());

  // 컴플라이언스: legal 승인이 필요한데 미승인이면 skip
  if (job.requiresLegalApproval && !job.legalApprovedAt) {
    return {
      jobId: job.id,
      status: 'skipped',
      errorMessage: 'legal_approval_pending',
    };
  }

  // Quiet hours 사전 검증 — 진입 시 차단되면 next_send_at으로 미루기
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
    // 캠페인 미등록이면 등록
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
 * 2. 실패 처리 — exponential backoff
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
 * 3. processQueueBatch — 큐 일괄 처리
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
 * 4. syncRunningCampaigns — 진행 중인 캠페인 통계 동기화
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
        // 운영 정보 미수령 — 더 이상 시도 안 함
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
 * 5. main — 폴링 루프 + graceful shutdown
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
