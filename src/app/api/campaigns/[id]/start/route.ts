import { NextResponse, type NextRequest } from 'next/server';
import { getUserAndOrg } from '@/lib/supabase/server';
import { TabsMailerClient, TabsMailerError } from '@/lib/email/tabs-mailer';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const maxDuration = 60;

const MAX_PER_INVOCATION = 100;       // Vercel 60s 안에 안전하게 처리 가능한 양
const PER_INVOCATION_BUDGET_MS = 50_000;

/**
 * POST /api/campaigns/[id]/start
 *
 * 캠페인의 status='queued'인 communications 행을 가져와 TABS Mailer로 순차 발송.
 *
 * Vercel 함수 timeout 60초 내에 ~100건 처리 가능. 그 이상은:
 *   - 본 라우트를 여러 번 호출 (UI에서 polling)
 *   - 또는 별도 worker에서 처리 (Railway/Fly.io)
 *
 * 응답:
 *   200 { ok, campaign_id, processed, sent, failed, remaining }
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  const { id: campaignId } = await params;

  let auth;
  try {
    auth = await getUserAndOrg();
  } catch (err) {
    return NextResponse.json(
      { error: 'unauthorized', detail: (err as Error).message },
      { status: 401 },
    );
  }

  // 1. 캠페인 존재 + 조직 확인
  const { data: campaign, error: campaignErr } = await auth.supabase
    .schema('app')
    .from('mail_merge_jobs')
    .select('id, status, name, progress, payload')
    .eq('organization_id', auth.organizationId)
    .eq('id', campaignId)
    .maybeSingle();

  if (campaignErr || !campaign) {
    return NextResponse.json(
      { error: 'campaign_not_found', detail: campaignErr?.message },
      { status: 404 },
    );
  }
  const job = campaign as {
    id: string;
    status: string;
    name: string | null;
    progress: Record<string, unknown> | null;
    payload: Record<string, unknown> | null;
  };

  if (job.status === 'completed') {
    return NextResponse.json(
      { error: 'already_completed', campaign_id: campaignId },
      { status: 409 },
    );
  }

  // 2. 캠페인을 running으로 표시
  if (job.status === 'queued') {
    await auth.supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update({ status: 'running' })
      .eq('id', campaignId);
  }

  // 3. 큐된 수신자 조회 (배치)
  const { data: queuedRows, error: queryErr } = await auth.supabase
    .schema('app')
    .from('communications')
    .select('id, to_addresses, subject, body_plain, message_id, reply_to_address, from_address, from_name')
    .eq('organization_id', auth.organizationId)
    .eq('direction', 'outbound')
    .eq('status', 'queued')
    .filter('external_data->>campaign_id', 'eq', campaignId)
    .order('created_at', { ascending: true })
    .limit(MAX_PER_INVOCATION);

  if (queryErr) {
    return NextResponse.json(
      { error: 'query_failed', detail: queryErr.message },
      { status: 500 },
    );
  }

  type QueuedRow = {
    id: string;
    to_addresses: string[] | null;
    subject: string | null;
    body_plain: string | null;
    message_id: string | null;
    reply_to_address: string | null;
    from_address: string | null;
    from_name: string | null;
  };
  const queued: QueuedRow[] = (queuedRows ?? []) as QueuedRow[];

  if (queued.length === 0) {
    // 남은 수신자 없음 → 캠페인 완료 처리
    await auth.supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
      })
      .eq('id', campaignId);

    return NextResponse.json({
      ok: true,
      campaign_id: campaignId,
      processed: 0,
      sent: 0,
      failed: 0,
      remaining: 0,
      campaign_status: 'completed',
    });
  }

  // 4. 순차 발송
  const startedAt = Date.now();
  let sent = 0;
  let failed = 0;
  let processed = 0;

  const mailer = new TabsMailerClient(auth.supabase);

  try {
    for (const row of queued) {
      if (Date.now() - startedAt > PER_INVOCATION_BUDGET_MS) break;

      const recipient = (row.to_addresses ?? [])[0];
      if (!recipient) {
        await markFailed(auth.supabase, row.id, 'no recipient');
        failed += 1;
        processed += 1;
        continue;
      }

      try {
        await mailer.sendOne({
          to: { address: recipient },
          from: row.from_address
            ? { name: row.from_name ?? undefined, address: row.from_address }
            : undefined,
          replyTo: row.reply_to_address ? { address: row.reply_to_address } : undefined,
          subject: row.subject ?? '',
          text: row.body_plain ?? '',
          messageId: row.message_id ?? undefined,
          urmHeaders: {
            communicationId: row.id,
            autoSend: false,
          },
        });

        await auth.supabase
          .schema('app')
          .from('communications')
          .update({
            status: 'sent',
            sent_at: new Date().toISOString(),
          })
          .eq('id', row.id);

        sent += 1;
      } catch (err) {
        const errMsg = err instanceof TabsMailerError ? err.message : (err as Error).message;
        await markFailed(auth.supabase, row.id, errMsg);
        failed += 1;
      }
      processed += 1;
    }
  } finally {
    mailer.close();
  }

  // 5. 진행률 업데이트
  const remaining = await countRemaining(auth.supabase, auth.organizationId, campaignId);

  const newProgress = {
    ...((job.progress as Record<string, unknown> | null) ?? {}),
    totalSent: ((job.progress?.totalSent as number) ?? 0) + sent,
    totalFailed: ((job.progress?.totalFailed as number) ?? 0) + failed,
    upstreamStatus: remaining === 0 ? 'completed' : 'running',
    syncedAt: new Date().toISOString(),
  };

  const newStatus = remaining === 0 ? 'completed' : 'running';
  const updatePayload: Record<string, unknown> = {
    progress: newProgress,
    status: newStatus,
  };
  if (remaining === 0) {
    updatePayload.completed_at = new Date().toISOString();
  }

  await auth.supabase
    .schema('app')
    .from('mail_merge_jobs')
    .update(updatePayload)
    .eq('id', campaignId);

  return NextResponse.json({
    ok: true,
    campaign_id: campaignId,
    processed,
    sent,
    failed,
    remaining,
    elapsed_ms: Date.now() - startedAt,
    campaign_status: newStatus,
  });
}

async function markFailed(
  supabase: Awaited<ReturnType<typeof getUserAndOrg>>['supabase'],
  communicationId: string,
  reason: string,
): Promise<void> {
  await supabase
    .schema('app')
    .from('communications')
    .update({
      status: 'failed',
      bounce_reason: reason,
    })
    .eq('id', communicationId);
}

async function countRemaining(
  supabase: Awaited<ReturnType<typeof getUserAndOrg>>['supabase'],
  organizationId: string,
  campaignId: string,
): Promise<number> {
  const { count } = await supabase
    .schema('app')
    .from('communications')
    .select('id', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .eq('direction', 'outbound')
    .eq('status', 'queued')
    .filter('external_data->>campaign_id', 'eq', campaignId);
  return count ?? 0;
}
