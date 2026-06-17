'use client';
// src/components/settings/sequence-opens-dialog.tsx
// Popup showing who opened a sequence's emails (read receipts via tracking pixel).

import { useEffect, useState, useTransition } from 'react';
import { getSequenceOpenReport, type SequenceOpenReport } from '@/lib/actions/sequence-opens';

interface Props {
  open:         boolean;
  onClose:      () => void;
  sequenceId:   string;
  sequenceName: string;
}

function fmt(ts: string | null): string {
  if (!ts) return '—';
  const d = new Date(ts);
  return d.toLocaleString();
}

export function SequenceOpensDialog({ open, onClose, sequenceId, sequenceName }: Props) {
  const [report,  setReport]  = useState<SequenceOpenReport | null>(null);
  const [error,   setError]   = useState<string | null>(null);
  const [pending, start]      = useTransition();

  function load() {
    setError(null);
    start(async () => {
      const res = await getSequenceOpenReport(sequenceId);
      if ('error' in res) setError(res.error);
      else setReport(res);
    });
  }

  useEffect(() => {
    if (open) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, sequenceId]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-2xl max-h-[85vh] overflow-hidden flex flex-col rounded-xl bg-white shadow-xl">
        {/* header */}
        <div className="flex items-start justify-between border-b border-gray-200 px-5 py-4">
          <div>
            <h2 className="text-base font-semibold text-gray-900">Read Receipts</h2>
            <p className="text-xs text-gray-500 mt-0.5 truncate max-w-md">{sequenceName}</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={load}
              disabled={pending}
              className="text-xs text-blue-600 hover:text-blue-800 font-medium disabled:opacity-50"
            >
              {pending ? 'Refreshing…' : '↻ Refresh'}
            </button>
            <button onClick={onClose} className="text-gray-400 hover:text-gray-600">✕</button>
          </div>
        </div>

        {/* summary */}
        {report && (
          <div className="grid grid-cols-4 gap-2 px-5 py-4 border-b border-gray-100">
            {[
              { label: 'Sent',      value: report.sent },
              { label: 'Opened',    value: report.opened },
              { label: 'Open rate', value: `${report.openRate}%` },
              { label: 'Clicked',   value: report.clicked },
            ].map((s) => (
              <div key={s.label} className="rounded-lg bg-gray-50 px-3 py-2 text-center">
                <div className="text-lg font-semibold text-gray-900">{s.value}</div>
                <div className="text-[11px] uppercase tracking-wide text-gray-400">{s.label}</div>
              </div>
            ))}
          </div>
        )}

        {/* body */}
        <div className="overflow-y-auto px-5 py-3">
          {error && (
            <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">Error: {error}</div>
          )}
          {!error && pending && !report && (
            <div className="py-10 text-center text-sm text-gray-400">Loading…</div>
          )}
          {!error && report && report.rows.length === 0 && (
            <div className="py-10 text-center text-sm text-gray-400">
              No sends tracked for this sequence yet.
            </div>
          )}
          {!error && report && report.rows.length > 0 && (
            <table className="w-full text-sm">
              <thead className="text-xs text-gray-500 uppercase tracking-wider">
                <tr>
                  <th className="py-2 text-left font-medium">Recipient</th>
                  <th className="py-2 text-right font-medium">Opens</th>
                  <th className="py-2 text-right font-medium">First opened</th>
                  <th className="py-2 text-right font-medium">Clicks</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {report.rows.map((r, i) => (
                  <tr key={i} className={r.openCount > 0 ? '' : 'opacity-50'}>
                    <td className="py-2">
                      <div className="text-gray-900">{r.recipient}</div>
                      {r.partyName && <div className="text-xs text-gray-400">{r.partyName}</div>}
                    </td>
                    <td className="py-2 text-right">
                      {r.openCount > 0 ? (
                        <span className="font-medium text-emerald-600">{r.openCount}</span>
                      ) : (
                        <span className="text-gray-400">—</span>
                      )}
                    </td>
                    <td className="py-2 text-right text-xs text-gray-500">{fmt(r.firstOpenedAt)}</td>
                    <td className="py-2 text-right text-gray-600">{r.clickCount || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* footnote */}
        <div className="border-t border-gray-100 px-5 py-2.5 text-[11px] text-gray-400">
          Opens are counted via a tracking pixel and may under-count (image-blocking clients) but never over-count.
        </div>
      </div>
    </div>
  );
}
