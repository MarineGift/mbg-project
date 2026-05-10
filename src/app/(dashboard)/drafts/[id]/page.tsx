import Link from 'next/link';
import { getUserAndOrg } from '@/lib/supabase/server';
import { approveDraftAction, rejectDraftAction } from './actions';
import { notFound } from 'next/navigation';

export const dynamic = 'force-dynamic';

interface DraftRow {
  id: string;
  status: string;
  subject: string | null;
  body_plain: string | null;
  body_html: string | null;
  rationale: string | null;
  classification_category: string | null;
  language: string | null;
  risk_flags: string[] | null;
  requires_human_approval: boolean;
  auto_send_eligible: boolean;
  auto_send_blocked_reasons: string[] | null;
  created_at: string;
  expires_at: string | null;
  communication_id: string;
}

interface InboundRow {
  id: string;
  from_address: string | null;
  from_name: string | null;
  subject: string | null;
  body_plain: string | null;
  occurred_at: string;
  language_detected: string | null;
  ai_classification: Record<string, unknown> | null;
}

export default async function DraftDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { id } = await params;
  const sp = await searchParams;
  const { supabase, organizationId } = await getUserAndOrg();

  const { data: draftRaw, error: draftErr } = await supabase
    .schema('ai')
    .from('drafts')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', id)
    .maybeSingle();

  if (draftErr || !draftRaw) notFound();
  const draft = draftRaw as DraftRow;

  const { data: inboundRaw } = await supabase
    .schema('app')
    .from('communications')
    .select('id, from_address, from_name, subject, body_plain, occurred_at, language_detected, ai_classification')
    .eq('organization_id', organizationId)
    .eq('id', draft.communication_id)
    .maybeSingle();

  const inbound = (inboundRaw ?? null) as InboundRow | null;

  const isPending = draft.status === 'pending';

  return (
    <div className="grid gap-6 max-w-4xl">
      <div>
        <Link href="/drafts" className="text-base text-muted-foreground no-underline hover:text-zinc-700">
          ← Drafts 목록
        </Link>
        <h1 className="text-2xl font-bold mt-2 mb-1">
          {draft.subject ?? '(제목 없음)'}
        </h1>
        <div className="text-sm text-zinc-500">
          상태: <strong className={statusClass(draft.status)}>{draft.status}</strong>
          {' · '}분류: {draft.classification_category ?? 'unknown'}
          {' · '}언어: {draft.language ?? '-'}
        </div>
      </div>

      {sp.error ? (
        <div className="alert-error">
          <strong>오류:</strong> {sp.error}
        </div>
      ) : null}

      {inbound ? (
        <Section title="원본 메일 (수신)">
          <div className="flex justify-between text-base">
            <div>
              <strong>{inbound.from_name ?? inbound.from_address}</strong>{' '}
              <span className="text-zinc-400">&lt;{inbound.from_address}&gt;</span>
            </div>
            <div className="text-zinc-400 text-sm">
              {new Date(inbound.occurred_at).toLocaleString('ko-KR')}
            </div>
          </div>
          <div className="text-md font-semibold mt-3 mb-2">
            {inbound.subject ?? '(제목 없음)'}
          </div>
          <pre className="pre-block">{inbound.body_plain ?? '(본문 없음)'}</pre>
        </Section>
      ) : null}

      {(draft.risk_flags ?? []).length > 0 ? (
        <Section title="위험 신호 (Risk Flags)">
          <div className="flex flex-wrap gap-1.5">
            {(draft.risk_flags ?? []).map((rf) => (
              <span key={rf} className="badge badge-warning">
                {rf}
              </span>
            ))}
          </div>
        </Section>
      ) : null}

      {(draft.auto_send_blocked_reasons ?? []).length > 0 ? (
        <Section title="자동발송 차단 사유">
          <ul className="m-0 pl-5 text-base text-muted-foreground list-disc">
            {(draft.auto_send_blocked_reasons ?? []).map((r) => (
              <li key={r}>{r}</li>
            ))}
          </ul>
        </Section>
      ) : null}

      {draft.rationale ? (
        <Section title="AI 작성 근거">
          <pre className="pre-block">{draft.rationale}</pre>
        </Section>
      ) : null}

      <Section title="답장 드래프트 (편집 가능)">
        {isPending ? (
          <form action={approveDraftAction} className="grid gap-3">
            <input type="hidden" name="id" value={draft.id} />
            <label className="label">
              제목 (Override)
              <input
                type="text"
                name="subject"
                defaultValue={draft.subject ?? ''}
                className="input"
              />
            </label>
            <label className="label">
              본문 (Plain Text)
              <textarea
                name="body_plain"
                defaultValue={draft.body_plain ?? ''}
                rows={16}
                className="input font-mono resize-y"
              />
            </label>
            <div className="flex gap-2 justify-end">
              <button type="submit" className="btn-accent">
                승인하고 발송
              </button>
            </div>
          </form>
        ) : (
          <pre className="pre-block">{draft.body_plain ?? ''}</pre>
        )}
      </Section>

      {isPending ? (
        <Section title="거절">
          <form action={rejectDraftAction} className="grid gap-3">
            <input type="hidden" name="id" value={draft.id} />
            <label className="label">
              거절 사유 (선택)
              <textarea name="reason" rows={2} className="input" />
            </label>
            <div className="flex justify-end">
              <button type="submit" className="btn-destructive">
                거절
              </button>
            </div>
          </form>
        </Section>
      ) : null}
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="card">
      <h2 className="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-3">
        {title}
      </h2>
      {children}
    </section>
  );
}

function statusClass(status: string): string {
  if (status === 'pending') return 'text-info';
  if (status === 'sent') return 'text-accent-hover';
  if (status === 'rejected') return 'text-destructive';
  if (status === 'expired') return 'text-zinc-500';
  return 'text-zinc-700';
}
