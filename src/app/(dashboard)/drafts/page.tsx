import Link from 'next/link';
import { getUserAndOrg } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

interface DraftListRow {
  id: string;
  status: string;
  classification_category: string | null;
  subject: string | null;
  language: string | null;
  requires_human_approval: boolean;
  auto_send_eligible: boolean;
  created_at: string;
  expires_at: string | null;
  communication_id: string;
}

export default async function DraftsPage() {
  const { supabase, organizationId } = await getUserAndOrg();

  const { data, error } = await supabase
    .schema('ai')
    .from('drafts')
    .select(
      'id, status, classification_category, subject, language, requires_human_approval, auto_send_eligible, created_at, expires_at, communication_id',
    )
    .eq('organization_id', organizationId)
    .eq('status', 'pending')
    .order('created_at', { ascending: false })
    .limit(50);

  const rows = (data ?? []) as DraftListRow[];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Pending Drafts</h1>

      {error ? (
        <div className="alert-error mb-4">
          <strong>조회 실패:</strong> {error.message}
        </div>
      ) : null}

      {rows.length === 0 && !error ? (
        <EmptyState />
      ) : (
        <div className="table-shell">
          <table className="w-full border-collapse">
            <thead className="bg-surface-subtle border-b border-border">
              <tr>
                <th className="th">제목</th>
                <th className="th">분류</th>
                <th className="th">언어</th>
                <th className="th">승인 필요</th>
                <th className="th">생성 시각</th>
                <th className="th">만료</th>
                <th className="th"></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((d) => (
                <tr key={d.id} className="border-b border-border-subtle tr-hover">
                  <td className="td">{d.subject ?? '(제목 없음)'}</td>
                  <td className="td">
                    <span className="badge badge-neutral">
                      {d.classification_category ?? 'unknown'}
                    </span>
                  </td>
                  <td className="td">{d.language ?? '-'}</td>
                  <td className="td">
                    {d.requires_human_approval ? (
                      <span className="text-destructive font-medium">필수</span>
                    ) : d.auto_send_eligible ? (
                      <span className="text-accent-hover">자동발송 가능</span>
                    ) : (
                      <span className="text-muted">차단됨</span>
                    )}
                  </td>
                  <td className="td">{formatDate(d.created_at)}</td>
                  <td className="td">{d.expires_at ? formatDate(d.expires_at) : '-'}</td>
                  <td className="td text-right">
                    <Link
                      href={`/drafts/${d.id}`}
                      className="btn-secondary btn-sm"
                    >
                      검토 →
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function EmptyState() {
  return (
    <div className="text-center py-16 px-6 text-muted-foreground bg-surface border border-dashed border-border-strong rounded-md">
      현재 검토 대기 중인 드래프트가 없습니다.
    </div>
  );
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleString('ko-KR', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return iso;
  }
}
