import { NextResponse, type NextRequest } from 'next/server';
import { getAdminSupabase } from '@/lib/supabase/admin';
import { verifyCronAuth } from '@/lib/cron-auth';
import { TabsMailerClient } from '@/lib/email/tabs-mailer';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const BATCH_SIZE = 5;
const PER_INVOCATION_BUDGET_MS = 50_000;

/**
 * Vercel Cron (2분 주기) — mail_merge_jobs.status='queued'인 작업의 통계를 동기화하거나
 * 신규 작업의 발송을 트리거.
 *
 * 본 라우트는 "이미 발송이 시작된 캠페인"의 통계 동기화에 집중한다.
 * 신규 캠페인의 createCampaign 자체는 (a) 사용자 UI에서 직접 호출하거나
 * (b) src/workers/mail-merge-worker.ts를 별도 호스트에서 가동하는 게 권장.
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  const authError = verifyCronAuth(request);
  if (authError) {
    return NextResponse.json({ error: authError }, { status: 401 });
  }

  const supa = getAdminSupabase();
  const startedAt = Date.now();
  const summary = {
    picked: 0,
    synced: 0,
    failed: 0,
    skipped: 0,
    errors: [] as Array<{ job_id: string; message: string }>,
  };

  const { data: jobs, error } = await supa
    .schema('app')
    .from('mail_merge_jobs')
    .select('id, organization_id, tabs_campaign_id, status')
    .in('status', ['running', 'queued'])
    .not('tabs_campaign_id', 'is', null)
    .order('created_at', { ascending: true })
    .limit(BATCH_SIZE);

  if (error) {
    return NextResponse.json(
      { error: 'pick_failed', detail: error.message },
      { status: 500 },
    );
  }

  const rows = (jobs ?? []) as Array<{
    id: string;
    organization_id: string;
    tabs_campaign_id: string | null;
    status: string;
  }>;
  summary.picked = rows.length;

  const mailer = new TabsMailerClient(supa);

  try {
    for (const job of rows) {
      if (Date.now() - startedAt > PER_INVOCATION_BUDGET_MS) {
        summary.skipped += rows.length - summary.synced - summary.failed;
        break;
      }
      try {
        await mailer.syncCampaignToMergeJob(job.id);
        summary.synced += 1;
      } catch (err) {
        summary.failed += 1;
        summary.errors.push({
          job_id: job.id,
          message: (err as Error).message,
        });
      }
    }
  } finally {
    mailer.close();
  }

  return NextResponse.json({
    ok: true,
    elapsed_ms: Date.now() - startedAt,
    ...summary,
  });
}
