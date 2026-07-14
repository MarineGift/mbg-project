// src/app/(app)/mailing/outcomes/outcomes-client.tsx
'use client';

import { useMemo, useState, useTransition } from 'react';
import Link from 'next/link';
import {
  Activity, AlertCircle, CalendarClock, CheckCircle2, Loader2,
  MailWarning, Plus, X,
} from 'lucide-react';
import { addOutcomeEntry } from '@/lib/actions/email-outcomes';
import {
  NEXT_ACTIONS,
  OUTCOME_CODES,
  type NextAction,
  type OutcomeCode,
  type OutcomeRow,
} from '@/types/email-outcome';

/* ------------------------------------------------------------------ */
/* labels + badge colors                                               */
/* ------------------------------------------------------------------ */

const OUTCOME_LABEL: Record<OutcomeCode, string> = {
  bounce_hard: 'Bounce (hard)',
  bounce_soft: 'Bounce (soft)',
  send_failure: 'Send failure',
  rejected_sector: 'Rejected - sector',
  rejected_stage: 'Rejected - stage',
  rejected_other: 'Rejected - other',
  unsubscribe_request: 'Unsubscribe',
  auto_reply: 'Auto reply',
  reply_positive: 'Reply (positive)',
  reply_neutral: 'Reply (neutral)',
};

// spec: bounce=red, rejected=orange, reply_positive=green, auto=gray
function outcomeBadgeClass(o: OutcomeCode): string {
  if (o.startsWith('bounce') || o === 'send_failure' || o === 'unsubscribe_request')
    return 'bg-red-100 text-red-700';
  if (o.startsWith('rejected')) return 'bg-orange-100 text-orange-700';
  if (o === 'reply_positive') return 'bg-green-100 text-green-700';
  if (o === 'reply_neutral') return 'bg-blue-100 text-blue-700';
  return 'bg-gray-100 text-gray-600'; // auto_reply etc.
}

const ACTION_LABEL: Record<NextAction, string> = {
  suppress: 'Suppress',
  resend_later: 'Resend later',
  switch_deck: 'Switch deck',
  switch_contact: 'Switch contact',
  follow_up: 'Follow up',
  none: '-',
};

function actionBadgeClass(a: NextAction | null): string {
  switch (a) {
    case 'switch_contact': return 'bg-purple-100 text-purple-700';
    case 'switch_deck': return 'bg-indigo-100 text-indigo-700';
    case 'follow_up': return 'bg-amber-100 text-amber-700';
    case 'resend_later': return 'bg-blue-100 text-blue-700';
    case 'suppress': return 'bg-red-100 text-red-700';
    default: return 'bg-gray-100 text-gray-500';
  }
}

const ACTION_BOARD: NextAction[] = ['switch_contact', 'switch_deck', 'follow_up'];

/* ------------------------------------------------------------------ */
/* small helpers                                                       */
/* ------------------------------------------------------------------ */

function fmtDate(iso: string | null): string {
  if (!iso) return '-';
  return iso.slice(0, 10);
}

/** D-day label: D-7 (future), D-Day (today), D+3 (overdue = ready). */
function dDay(iso: string): { label: string; ready: boolean } {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const target = new Date(iso);
  target.setHours(0, 0, 0, 0);
  const diff = Math.round((target.getTime() - today.getTime()) / 86_400_000);
  if (diff > 0) return { label: `D-${diff}`, ready: false };
  if (diff === 0) return { label: 'D-Day', ready: true };
  return { label: `D+${-diff}`, ready: true };
}

function PartyCell({ row }: { row: OutcomeRow }) {
  if (row.party_id && row.party_name && row.party_type) {
    return (
      <Link
        href={`/${row.party_type}/parties/${row.party_id}`}
        className="font-medium text-blue-600 hover:underline"
      >
        {row.party_name}
      </Link>
    );
  }
  return <span className="text-muted-foreground">-</span>;
}

function OutcomeBadge({ o }: { o: OutcomeCode }) {
  return (
    <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${outcomeBadgeClass(o)}`}>
      {OUTCOME_LABEL[o] ?? o}
    </span>
  );
}

function ActionBadge({ a }: { a: NextAction | null }) {
  if (!a || a === 'none') return <span className="text-xs text-muted-foreground">-</span>;
  return (
    <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${actionBadgeClass(a)}`}>
      {ACTION_LABEL[a] ?? a}
    </span>
  );
}

/* ------------------------------------------------------------------ */
/* main client                                                         */
/* ------------------------------------------------------------------ */

export function OutcomesClient({ initialRows }: { initialRows: OutcomeRow[] }) {
  const [rows, setRows] = useState(initialRows);
  const [showAdd, setShowAdd] = useState(false);
  const [isPending, start] = useTransition();
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  // form state
  const [fEmail, setFEmail] = useState('');
  const [fOutcome, setFOutcome] = useState<OutcomeCode>('bounce_hard');
  const [fReason, setFReason] = useState('');
  const [fAction, setFAction] = useState<NextAction>('none');
  const [fResendDate, setFResendDate] = useState('');

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  };

  /* block 1 - summary counts (Q3) */
  const summary = useMemo(() => {
    const counts = new Map<OutcomeCode, number>();
    for (const r of rows) counts.set(r.outcome, (counts.get(r.outcome) ?? 0) + 1);
    return OUTCOME_CODES.filter((o) => (counts.get(o) ?? 0) > 0).map((o) => ({
      outcome: o,
      count: counts.get(o) ?? 0,
    }));
  }, [rows]);

  /* block 2 - action board (Q5) */
  const actionBoard = useMemo(
    () => rows.filter((r) => r.next_action && ACTION_BOARD.includes(r.next_action)),
    [rows],
  );

  /* block 3 - resend queue (Q4) */
  const resendQueue = useMemo(
    () =>
      rows
        .filter((r) => r.next_action === 'resend_later' && r.resend_not_before)
        .sort((a, b) => (a.resend_not_before! < b.resend_not_before! ? -1 : 1)),
    [rows],
  );

  const handleAdd = () => {
    const email = fEmail.trim().toLowerCase();
    if (!email) return;
    start(async () => {
      const res = await addOutcomeEntry({
        recipientEmail: email,
        outcome: fOutcome,
        reason: fReason || undefined,
        nextAction: fAction,
        resendNotBefore: fAction === 'resend_later' ? fResendDate : undefined,
      });
      if (!res.ok) {
        showToast(res.error ?? 'Failed to record outcome', false);
        return;
      }
      // optimistic prepend (party link resolves on next server render)
      setRows((prev) => [
        {
          id: `tmp-${Date.now()}`,
          recipient_email: email,
          outcome: fOutcome,
          reason: fReason || null,
          next_action: fAction,
          resend_not_before:
            fAction === 'resend_later' && fResendDate
              ? new Date(fResendDate).toISOString()
              : null,
          source: 'manual',
          evidence_ref: null,
          created_at: new Date().toISOString(),
          party_id: null,
          party_name: null,
          party_type: null,
        },
        ...prev,
      ]);
      setFEmail('');
      setFReason('');
      setFAction('none');
      setFResendDate('');
      setShowAdd(false);
      showToast('Outcome recorded');
    });
  };

  return (
    <div className="space-y-6">
      {/* header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="flex items-center gap-2 text-xl font-semibold">
            <MailWarning className="h-5 w-5 text-orange-600" /> Send Outcomes
          </h1>
          <p className="mt-1 text-sm text-muted-foreground">
            What happened after each send: bounces, rejections, replies. Auto rows
            come from the MailCarrier NDR parser; anything else is entered here.
            Hard bounces and suppressions feed the do-not-send view
            (app.v_email_do_not_send) used by every enrollment SQL.
          </p>
        </div>
        <button
          onClick={() => setShowAdd((v) => !v)}
          className="inline-flex shrink-0 items-center gap-1.5 rounded-md bg-orange-600 px-3 py-2 text-sm font-medium text-white hover:bg-orange-700"
        >
          <Plus className="h-4 w-4" /> Record outcome
        </button>
      </div>

      {/* manual entry form */}
      {showAdd && (
        <div className="rounded-lg border bg-card p-4">
          <div className="flex flex-wrap items-end gap-3">
            <div className="min-w-56 flex-1">
              <label className="mb-1 block text-xs font-medium text-muted-foreground">
                Recipient email
              </label>
              <input
                type="email"
                value={fEmail}
                onChange={(e) => setFEmail(e.target.value)}
                placeholder="someone@fund.com"
                className="w-full rounded-md border px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-muted-foreground">
                Outcome
              </label>
              <select
                value={fOutcome}
                onChange={(e) => setFOutcome(e.target.value as OutcomeCode)}
                className="rounded-md border px-3 py-2 text-sm"
              >
                {OUTCOME_CODES.map((o) => (
                  <option key={o} value={o}>
                    {OUTCOME_LABEL[o]}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-muted-foreground">
                Next action
              </label>
              <select
                value={fAction}
                onChange={(e) => setFAction(e.target.value as NextAction)}
                className="rounded-md border px-3 py-2 text-sm"
              >
                {NEXT_ACTIONS.map((a) => (
                  <option key={a} value={a}>
                    {a === 'none' ? 'None' : ACTION_LABEL[a]}
                  </option>
                ))}
              </select>
            </div>
            {fAction === 'resend_later' && (
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Resend not before
                </label>
                <input
                  type="date"
                  value={fResendDate}
                  onChange={(e) => setFResendDate(e.target.value)}
                  className="rounded-md border px-3 py-2 text-sm"
                />
              </div>
            )}
            <div className="min-w-56 flex-1">
              <label className="mb-1 block text-xs font-medium text-muted-foreground">
                Reason (optional)
              </label>
              <input
                type="text"
                value={fReason}
                onChange={(e) => setFReason(e.target.value)}
                placeholder="550 5.2.1 account disabled / polite pass, door open ..."
                className="w-full rounded-md border px-3 py-2 text-sm"
              />
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleAdd}
                disabled={isPending || !fEmail.trim()}
                className="inline-flex items-center gap-1.5 rounded-md bg-orange-600 px-3 py-2 text-sm font-medium text-white hover:bg-orange-700 disabled:opacity-50"
              >
                {isPending ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <CheckCircle2 className="h-4 w-4" />
                )}
                Save
              </button>
              <button
                onClick={() => setShowAdd(false)}
                className="rounded-md border px-3 py-2 text-sm hover:bg-gray-50"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* block 1 - summary cards */}
      <section>
        <h2 className="mb-2 flex items-center gap-1.5 text-sm font-semibold text-muted-foreground">
          <Activity className="h-4 w-4" /> Summary ({rows.length} recorded)
        </h2>
        {summary.length === 0 ? (
          <p className="text-sm text-muted-foreground">No outcomes recorded yet.</p>
        ) : (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
            {summary.map((s) => (
              <div key={s.outcome} className="rounded-lg border bg-card p-3">
                <div className="text-2xl font-semibold">{s.count}</div>
                <div className="mt-1">
                  <OutcomeBadge o={s.outcome} />
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* block 2 - action board */}
      <section>
        <h2 className="mb-2 flex items-center gap-1.5 text-sm font-semibold text-muted-foreground">
          <AlertCircle className="h-4 w-4" /> Action board - needs a move ({actionBoard.length})
        </h2>
        {actionBoard.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            Nothing waiting on switch_contact / switch_deck / follow_up.
          </p>
        ) : (
          <div className="overflow-x-auto rounded-lg border">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-left text-xs text-muted-foreground">
                <tr>
                  <th className="px-3 py-2">Party</th>
                  <th className="px-3 py-2">Email</th>
                  <th className="px-3 py-2">Outcome</th>
                  <th className="px-3 py-2">Next action</th>
                  <th className="px-3 py-2">Reason</th>
                  <th className="px-3 py-2">Recorded</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {actionBoard.map((r) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="px-3 py-2"><PartyCell row={r} /></td>
                    <td className="px-3 py-2 font-mono text-xs">{r.recipient_email}</td>
                    <td className="px-3 py-2"><OutcomeBadge o={r.outcome} /></td>
                    <td className="px-3 py-2"><ActionBadge a={r.next_action} /></td>
                    <td className="max-w-72 truncate px-3 py-2 text-xs text-muted-foreground" title={r.reason ?? ''}>
                      {r.reason ?? '-'}
                    </td>
                    <td className="px-3 py-2 text-xs text-muted-foreground">{fmtDate(r.created_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* block 3 - resend queue */}
      <section>
        <h2 className="mb-2 flex items-center gap-1.5 text-sm font-semibold text-muted-foreground">
          <CalendarClock className="h-4 w-4" /> Re-approach queue - resend_later ({resendQueue.length})
        </h2>
        {resendQueue.length === 0 ? (
          <p className="text-sm text-muted-foreground">No cooldowns scheduled.</p>
        ) : (
          <div className="overflow-x-auto rounded-lg border">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-left text-xs text-muted-foreground">
                <tr>
                  <th className="px-3 py-2">D-day</th>
                  <th className="px-3 py-2">Not before</th>
                  <th className="px-3 py-2">Party</th>
                  <th className="px-3 py-2">Email</th>
                  <th className="px-3 py-2">Outcome</th>
                  <th className="px-3 py-2">Reason</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {resendQueue.map((r) => {
                  const d = dDay(r.resend_not_before!);
                  return (
                    <tr key={r.id} className="hover:bg-gray-50">
                      <td className="px-3 py-2">
                        <span
                          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-semibold ${
                            d.ready ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'
                          }`}
                        >
                          {d.label}
                        </span>
                      </td>
                      <td className="px-3 py-2 text-xs">{fmtDate(r.resend_not_before)}</td>
                      <td className="px-3 py-2"><PartyCell row={r} /></td>
                      <td className="px-3 py-2 font-mono text-xs">{r.recipient_email}</td>
                      <td className="px-3 py-2"><OutcomeBadge o={r.outcome} /></td>
                      <td className="max-w-72 truncate px-3 py-2 text-xs text-muted-foreground" title={r.reason ?? ''}>
                        {r.reason ?? '-'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* block 4 - recent log */}
      <section>
        <h2 className="mb-2 text-sm font-semibold text-muted-foreground">
          Recent log ({rows.length}, newest first)
        </h2>
        {rows.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nothing yet.</p>
        ) : (
          <div className="overflow-x-auto rounded-lg border">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-left text-xs text-muted-foreground">
                <tr>
                  <th className="px-3 py-2">Recorded</th>
                  <th className="px-3 py-2">Party</th>
                  <th className="px-3 py-2">Email</th>
                  <th className="px-3 py-2">Outcome</th>
                  <th className="px-3 py-2">Next action</th>
                  <th className="px-3 py-2">Resend after</th>
                  <th className="px-3 py-2">Source</th>
                  <th className="px-3 py-2">Reason</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {rows.map((r) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="px-3 py-2 text-xs text-muted-foreground">{fmtDate(r.created_at)}</td>
                    <td className="px-3 py-2"><PartyCell row={r} /></td>
                    <td className="px-3 py-2 font-mono text-xs">{r.recipient_email}</td>
                    <td className="px-3 py-2"><OutcomeBadge o={r.outcome} /></td>
                    <td className="px-3 py-2"><ActionBadge a={r.next_action} /></td>
                    <td className="px-3 py-2 text-xs">{fmtDate(r.resend_not_before)}</td>
                    <td className="px-3 py-2 text-xs text-muted-foreground">{r.source ?? '-'}</td>
                    <td className="max-w-72 truncate px-3 py-2 text-xs text-muted-foreground" title={r.reason ?? ''}>
                      {r.reason ?? '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* toast */}
      {toast && (
        <div
          className={`fixed bottom-4 right-4 z-50 flex items-center gap-2 rounded-md px-4 py-2 text-sm text-white shadow-lg ${
            toast.ok ? 'bg-green-600' : 'bg-red-600'
          }`}
        >
          {toast.ok ? <CheckCircle2 className="h-4 w-4" /> : <AlertCircle className="h-4 w-4" />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}
