import Link from 'next/link';
import { getUserAndOrg } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

interface CampaignRow {
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
    total_recipients?: number;
  } | null;
  created_at: string;
  completed_at: string | null;
}

export default async function CampaignsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; info?: string }>;
}) {
  const sp = await searchParams;
  const { supabase, organizationId } = await getUserAndOrg();

  let query = supabase
    .schema('app')
    .from('mail_merge_jobs')
    .select('id, name, status, tabs_campaign_id, progress, payload, created_at, completed_at')
    .eq('organization_id', organizationId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (sp.status && ['draft', 'queued', 'running', 'completed', 'failed'].includes(sp.status)) {
    query = query.eq('status', sp.status);
  }

  const { data, error } = await query;
  const rows = (data ?? []) as CampaignRow[];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Campaigns</h1>
        <Link href="/campaigns/new" className="btn-primary">
          + 신규 캠페인
        </Link>
      </div>

      {sp.info === 'created' ? (
        <div className="alert-info mb-4">캠페인이 생성됐습니다. 시작 버튼을 눌러 발송을 시작하세요.</div>
      ) : null}
      {sp.info === 'sent' ? (
        <div className="alert-info mb-4">캠페인이 발송 시작됐습니다. 진행률은 자동 업데이트됩니다.</div>
      ) : null}

      <div className="flex gap-2 mb-4">
        <FilterLink label="전체" href="/campaigns" active={!sp.status} />
        <FilterLink label="Draft" href="/campaigns?status=draft" active={sp.status === 'draft'} />
        <FilterLink label="Queued" href="/campaigns?status=queued" active={sp.status === 'queued'} />
        <FilterLink label="Running" href="/campaigns?status=running" active={sp.status === 'running'} />
        <FilterLink label="Completed" href="/campaigns?status=completed" active={sp.status === 'completed'} />
      </div>

      {error ? (
        <div className="alert-error mb-4">
          <strong>조회 실패:</strong> {error.message}
        </div>
      ) : null}

      {rows.length === 0 && !error ? (
        <div className="text-center py-16 px-6 text-muted-foreground bg-surface border border-dashed border-border-strong rounded-md">
          {sp.status ? `'${sp.status}' 상태의 캠페인이 없습니다.` : '등록된 캠페인이 없습니다.'}
        </div>
      ) : (
        <div className="table-shell">
          <table className="w-full border-collapse">
            <thead className="bg-surface-subtle border-b border-border">
              <tr>
                <th className="th">이름</th>
                <th className="th">상태</th>
                <th className="th">총 수신자</th>
                <th className="th">발송</th>
                <th className="th">전달</th>
                <th className="th">오픈</th>
                <th className="th">실패</th>
                <th className="th">생성</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((c) => {
                const p = c.progress ?? {};
                const total = p.totalRecipients ?? c.payload?.total_recipients ?? '-';
                return (
                  <tr key={c.id} className="border-b border-border-subtle tr-hover">
                    <td className="td">
                      <Link href={`/campaigns/${c.id}`} className="text-zinc-800 no-underline hover:underline">
                        {c.name ?? c.id}
                      </Link>
                    </td>
                    <td className="td">
                      <StatusBadge status={c.status} />
                    </td>
                    <td className="td">{total}</td>
                    <td className="td">{p.totalSent ?? 0}</td>
                    <td className="td">{p.totalDelivered ?? 0}</td>
                    <td className="td">{p.totalOpened ?? 0}</td>
                    <td className="td">{(p.totalBounced ?? 0) + (p.totalFailed ?? 0)}</td>
                    <td className="td text-xs text-zinc-500">
                      {new Date(c.created_at).toLocaleString('ko-KR', {
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const cls: Record<string, string> = {
    draft: 'badge-neutral',
    queued: 'badge-warning',
    running: 'badge-info',
    completed: 'badge-accent',
    failed: 'badge-destructive',
  };
  return <span className={`badge ${cls[status] ?? 'badge-neutral'}`}>{status}</span>;
}

function FilterLink({ label, href, active }: { label: string; href: string; active: boolean }) {
  return (
    <Link
      href={href}
      className={`px-3 py-1.5 text-sm rounded border no-underline transition-colors ${
        active
          ? 'bg-primary text-primary-foreground border-primary'
          : 'bg-surface text-zinc-700 border-border-strong hover:bg-surface-muted'
      }`}
    >
      {label}
    </Link>
  );
}
