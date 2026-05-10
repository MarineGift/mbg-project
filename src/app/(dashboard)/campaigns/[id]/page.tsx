import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getUserAndOrg } from '@/lib/supabase/server';
import StartButton from './StartButton';

export const dynamic = 'force-dynamic';

interface JobRow {
  id: string;
  name: string | null;
  status: string;
  tabs_campaign_id: string | null;
  progress: {
    totalRecipients?: number;
    totalSent?: number;
    totalDelivered?: number;
    totalOpened?: number;
    totalClicked?: number;
    totalBounced?: number;
    totalFailed?: number;
    upstreamStatus?: string;
    syncedAt?: string;
  } | null;
  payload: {
    subject_template?: string;
    body_template?: string;
    from_name?: string | null;
    from_address?: string;
    reply_to_address?: string | null;
    total_recipients?: number;
    invalid_email_count?: number;
    created_by?: string;
  } | null;
  created_at: string;
  completed_at: string | null;
}

export default async function CampaignDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { supabase, organizationId } = await getUserAndOrg();

  const { data, error } = await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', id)
    .maybeSingle();

  if (error || !data) notFound();
  const job = data as JobRow;

  // 큐된/발송됨/실패 communications 카운트 (실시간)
  const [queuedRes, sentRes, failedRes] = await Promise.all([
    supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('direction', 'outbound')
      .eq('status', 'queued')
      .filter('external_data->>campaign_id', 'eq', id),
    supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('direction', 'outbound')
      .eq('status', 'sent')
      .filter('external_data->>campaign_id', 'eq', id),
    supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('direction', 'outbound')
      .eq('status', 'failed')
      .filter('external_data->>campaign_id', 'eq', id),
  ]);

  const queuedCount = queuedRes.count ?? 0;
  const sentCount = sentRes.count ?? 0;
  const failedCount = failedRes.count ?? 0;
  const totalRecipients =
    job.payload?.total_recipients ?? job.progress?.totalRecipients ?? (queuedCount + sentCount + failedCount);

  const sentPct = totalRecipients > 0 ? Math.round((sentCount / totalRecipients) * 100) : 0;

  return (
    <div className="grid gap-6 max-w-5xl">
      <div>
        <Link href="/campaigns" className="text-base text-muted-foreground no-underline hover:text-zinc-700">
          ← Campaigns
        </Link>
        <h1 className="text-2xl font-bold mt-2 mb-1">{job.name ?? job.id}</h1>
        <div className="text-sm text-zinc-500">
          상태: <strong className={statusClass(job.status)}>{job.status}</strong>
          {' · '}생성: {new Date(job.created_at).toLocaleString('ko-KR')}
          {job.completed_at ? ` · 완료: ${new Date(job.completed_at).toLocaleString('ko-KR')}` : null}
        </div>
      </div>

      {/* 진행률 */}
      <section className="card">
        <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-4">진행률</h2>

        <div className="grid grid-cols-4 gap-4 mb-4">
          <Stat label="총 수신자" value={String(totalRecipients)} />
          <Stat label="발송됨" value={String(sentCount)} highlight="accent" />
          <Stat label="대기 중" value={String(queuedCount)} highlight="warning" />
          <Stat label="실패" value={String(failedCount)} highlight={failedCount > 0 ? 'destructive' : undefined} />
        </div>

        <div className="w-full h-2 bg-surface-muted rounded-sm overflow-hidden">
          <div
            className="h-full bg-accent transition-all"
            style={{ width: `${sentPct}%` }}
          />
        </div>
        <div className="text-xs text-muted-foreground mt-2 text-right">{sentPct}% 발송 완료</div>
      </section>

      <StartButton campaignId={job.id} initialStatus={job.status} />

      {/* 메타 정보 */}
      {job.payload ? (
        <section className="card">
          <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-4">메타 정보</h2>
          <dl className="grid grid-cols-[160px_1fr] gap-y-2 gap-x-4 text-base m-0">
            <dt className="text-muted-foreground">발신자</dt>
            <dd className="m-0">
              {job.payload.from_name ? `${job.payload.from_name} ` : ''}
              <span className="text-zinc-500">&lt;{job.payload.from_address ?? '-'}&gt;</span>
            </dd>
            {job.payload.reply_to_address ? (
              <>
                <dt className="text-muted-foreground">Reply-To</dt>
                <dd className="m-0">{job.payload.reply_to_address}</dd>
              </>
            ) : null}
            <dt className="text-muted-foreground">제목 템플릿</dt>
            <dd className="m-0 font-mono text-sm">{job.payload.subject_template ?? '-'}</dd>
            {job.payload.invalid_email_count !== undefined && job.payload.invalid_email_count > 0 ? (
              <>
                <dt className="text-muted-foreground">스킵된 잘못된 이메일</dt>
                <dd className="m-0 text-warning">{job.payload.invalid_email_count}건</dd>
              </>
            ) : null}
          </dl>
          {job.payload.body_template ? (
            <div className="mt-4">
              <div className="text-xs font-semibold text-zinc-500 uppercase tracking-wide mb-2">본문 템플릿</div>
              <pre className="pre-block max-h-72">{job.payload.body_template}</pre>
            </div>
          ) : null}
        </section>
      ) : null}
    </div>
  );
}

function Stat({
  label,
  value,
  highlight,
}: {
  label: string;
  value: string;
  highlight?: 'accent' | 'warning' | 'destructive';
}) {
  const colorClass =
    highlight === 'accent'
      ? 'text-accent-hover'
      : highlight === 'warning'
        ? 'text-warning-foreground'
        : highlight === 'destructive'
          ? 'text-destructive'
          : 'text-zinc-800';
  return (
    <div className="bg-surface-subtle border border-border-subtle rounded p-3">
      <div className="text-xs text-muted-foreground uppercase tracking-wide">{label}</div>
      <div className={`text-2xl font-bold mt-1 ${colorClass}`}>{value}</div>
    </div>
  );
}

function statusClass(status: string): string {
  if (status === 'draft') return 'text-zinc-700';
  if (status === 'queued') return 'text-warning-foreground';
  if (status === 'running') return 'text-info';
  if (status === 'completed') return 'text-accent-hover';
  if (status === 'failed') return 'text-destructive';
  return 'text-zinc-700';
}
