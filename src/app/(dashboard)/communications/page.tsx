import Link from 'next/link';
import { getUserAndOrg } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

interface CommRow {
  id: string;
  direction: 'inbound' | 'outbound';
  channel: string;
  from_address: string | null;
  from_name: string | null;
  to_addresses: string[] | null;
  subject: string | null;
  status: string;
  occurred_at: string;
  language_detected: string | null;
  ai_processing_status: string | null;
  thread_id: string | null;
}

export default async function CommunicationsPage({
  searchParams,
}: {
  searchParams: Promise<{ direction?: string }>;
}) {
  const sp = await searchParams;
  const { supabase, organizationId } = await getUserAndOrg();

  let query = supabase
    .schema('app')
    .from('communications')
    .select(
      'id, direction, channel, from_address, from_name, to_addresses, subject, status, occurred_at, language_detected, ai_processing_status, thread_id',
    )
    .eq('organization_id', organizationId)
    .is('deleted_at', null)
    .order('occurred_at', { ascending: false })
    .limit(100);

  if (sp.direction === 'inbound' || sp.direction === 'outbound') {
    query = query.eq('direction', sp.direction);
  }

  const { data, error } = await query;
  const rows = (data ?? []) as CommRow[];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Communications</h1>

      <div className="flex gap-2 mb-4">
        <FilterLink label="전체" href="/communications" active={!sp.direction} />
        <FilterLink label="수신" href="/communications?direction=inbound" active={sp.direction === 'inbound'} />
        <FilterLink label="발송" href="/communications?direction=outbound" active={sp.direction === 'outbound'} />
      </div>

      {error ? (
        <div className="alert-error mb-4">
          <strong>조회 실패:</strong> {error.message}
        </div>
      ) : null}

      {rows.length === 0 && !error ? (
        <div className="text-center py-16 px-6 text-muted-foreground bg-surface border border-dashed border-border-strong rounded-md">
          표시할 메시지가 없습니다.
        </div>
      ) : (
        <div className="bg-surface border border-border rounded-md overflow-hidden">
          {rows.map((r) => (
            <Link
              key={r.id}
              href={`/communications/${r.id}`}
              className="flex items-center gap-3 px-4 py-3 border-b border-border-subtle last:border-b-0 no-underline text-zinc-800 text-base tr-hover"
            >
              <div className="w-14">
                <DirectionPill dir={r.direction} />
              </div>
              <div className="w-48 truncate">
                {r.direction === 'inbound'
                  ? r.from_name ?? r.from_address ?? '-'
                  : (r.to_addresses ?? [])[0] ?? '-'}
              </div>
              <div className="flex-1 truncate">
                {r.subject ?? '(제목 없음)'}
              </div>
              <div className="w-20 text-xs text-zinc-500">
                <StatusBadge status={r.status} />
              </div>
              <div className="w-32 text-xs text-zinc-500 text-right">
                {formatDate(r.occurred_at)}
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

function DirectionPill({ dir }: { dir: 'inbound' | 'outbound' }) {
  const isIn = dir === 'inbound';
  return (
    <span
      className={`inline-block px-1.5 py-0.5 text-xs font-bold uppercase rounded-sm ${
        isIn ? 'bg-info-subtle text-info' : 'bg-accent-subtle text-accent-hover'
      }`}
    >
      {isIn ? 'IN' : 'OUT'}
    </span>
  );
}

function StatusBadge({ status }: { status: string }) {
  const cls: Record<string, string> = {
    received: 'badge-neutral',
    sent: 'badge-accent',
    delivered: 'badge-accent',
    queued: 'badge-warning',
    failed: 'badge-destructive',
    bounced: 'badge-destructive',
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

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleString('ko-KR', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return iso;
  }
}
