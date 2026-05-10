import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getUserAndOrg } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

interface CommDetailRow {
  id: string;
  direction: 'inbound' | 'outbound';
  channel: string;
  from_address: string | null;
  from_name: string | null;
  to_addresses: string[] | null;
  cc_addresses: string[] | null;
  subject: string | null;
  body_plain: string | null;
  body_html: string | null;
  status: string;
  occurred_at: string;
  language_detected: string | null;
  thread_id: string | null;
  message_id: string | null;
  in_reply_to: string | null;
  ai_processing_status: string | null;
  ai_classification: Record<string, unknown> | null;
  pii_masked: boolean | null;
  pii_categories_detected: string[] | null;
}

export default async function CommunicationDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const { supabase, organizationId } = await getUserAndOrg();

  const { data: row, error } = await supabase
    .schema('app')
    .from('communications')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', id)
    .maybeSingle();

  if (error || !row) notFound();
  const comm = row as CommDetailRow;

  let threadMessages: CommDetailRow[] = [];
  if (comm.thread_id) {
    const { data: threadRows } = await supabase
      .schema('app')
      .from('communications')
      .select('id, direction, from_address, from_name, to_addresses, subject, occurred_at, status')
      .eq('organization_id', organizationId)
      .eq('thread_id', comm.thread_id)
      .neq('id', comm.id)
      .order('occurred_at', { ascending: true });
    threadMessages = (threadRows ?? []) as CommDetailRow[];
  }

  return (
    <div className="grid gap-6 max-w-4xl">
      <div>
        <Link href="/communications" className="text-base text-muted-foreground no-underline hover:text-zinc-700">
          ← Communications
        </Link>
      </div>

      <section className="card">
        <div className="flex justify-between items-start gap-4">
          <div>
            <h1 className="text-lg font-bold mb-2">
              {comm.subject ?? '(제목 없음)'}
            </h1>
            <div className="text-sm text-zinc-600 leading-7">
              <div>
                <strong>{comm.direction === 'inbound' ? '발신자' : '수신자'}:</strong>{' '}
                {comm.direction === 'inbound'
                  ? `${comm.from_name ?? ''} <${comm.from_address ?? ''}>`
                  : (comm.to_addresses ?? []).join(', ')}
              </div>
              {(comm.cc_addresses ?? []).length > 0 ? (
                <div>
                  <strong>CC:</strong> {(comm.cc_addresses ?? []).join(', ')}
                </div>
              ) : null}
              <div>
                <strong>일시:</strong> {new Date(comm.occurred_at).toLocaleString('ko-KR')}
              </div>
              <div>
                <strong>언어:</strong> {comm.language_detected ?? '-'}
                {' · '}
                <strong>상태:</strong> {comm.status}
              </div>
              <div className="text-zinc-400 text-xs mt-1">
                Message-ID: {comm.message_id ?? '-'}
              </div>
            </div>
          </div>
          <div className="flex flex-col gap-1.5 items-end">
            <DirectionPill dir={comm.direction} />
            {comm.ai_processing_status ? (
              <span className="text-xs text-zinc-400">
                AI: {comm.ai_processing_status}
              </span>
            ) : null}
            {comm.pii_masked ? (
              <span className="text-xs text-warning">
                PII 마스킹됨
                {(comm.pii_categories_detected ?? []).length > 0
                  ? ` (${(comm.pii_categories_detected ?? []).join(', ')})`
                  : ''}
              </span>
            ) : null}
          </div>
        </div>
      </section>

      <section className="card">
        <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-3">
          본문
        </h2>
        <pre className="pre-block">{comm.body_plain ?? '(본문 없음)'}</pre>
      </section>

      {comm.ai_classification ? (
        <section className="card">
          <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-3">
            AI 분류 결과
          </h2>
          <pre className="pre-block text-sm">
            {JSON.stringify(comm.ai_classification, null, 2)}
          </pre>
        </section>
      ) : null}

      {threadMessages.length > 0 ? (
        <section className="card">
          <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-3">
            같은 스레드 ({threadMessages.length})
          </h2>
          <div className="grid gap-2">
            {threadMessages.map((m) => (
              <Link
                key={m.id}
                href={`/communications/${m.id}`}
                className="flex items-center gap-3 px-3 py-2 rounded bg-surface-subtle no-underline text-zinc-800 hover:bg-surface-muted transition-colors"
              >
                <DirectionPill dir={m.direction} />
                <span className="text-sm text-zinc-600 w-36 truncate">
                  {m.direction === 'inbound'
                    ? m.from_address ?? '-'
                    : (m.to_addresses ?? [])[0] ?? '-'}
                </span>
                <span className="flex-1 text-base truncate">
                  {m.subject ?? '(제목 없음)'}
                </span>
                <span className="text-xs text-zinc-500">
                  {new Date(m.occurred_at).toLocaleString('ko-KR', {
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </span>
              </Link>
            ))}
          </div>
        </section>
      ) : null}
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
