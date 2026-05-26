'use client';
// src/components/settings/email-history-client.tsx

import { useState } from 'react';
import type { EmailHistoryRow } from '@/lib/queries/email-history';

interface Props {
  rows:       EmailHistoryRow[];
  totalCount: number;
}

const STATUS_COLOR: Record<string, string> = {
  sent:    'bg-emerald-100 text-emerald-700',
  skipped: 'bg-gray-100 text-gray-500',
  failed:  'bg-red-100 text-red-700',
};

function formatDate(iso: string | null) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

export function EmailHistoryClient({ rows, totalCount }: Props) {
  const [filter, setFilter] = useState<'all' | 'opened' | 'unopened' | 'errors'>('all');

  const filtered = rows.filter(r => {
    if (filter === 'opened')   return r.open_count > 0;
    if (filter === 'unopened') return r.send_status === 'sent' && r.open_count === 0;
    if (filter === 'errors')   return r.send_status === 'failed' || r.send_status === 'skipped';
    return true;
  });

  const stats = {
    total:    rows.length,
    sent:     rows.filter(r => r.send_status === 'sent').length,
    opened:   rows.filter(r => r.open_count > 0).length,
    skipped:  rows.filter(r => r.send_status === 'skipped').length,
    failed:   rows.filter(r => r.send_status === 'failed').length,
  };
  const openRate = stats.sent > 0 ? Math.round((stats.opened / stats.sent) * 100) : 0;

  return (
    <>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-xl font-semibold text-gray-900">Email History</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            All sequence emails sent — most recent {rows.length} of {totalCount}
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-3 mb-5">
        <div className="bg-white border border-gray-200 rounded-lg p-3">
          <div className="text-xs text-gray-500">Total Sent</div>
          <div className="text-2xl font-semibold text-gray-900">{stats.sent}</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-3">
          <div className="text-xs text-gray-500">Opened</div>
          <div className="text-2xl font-semibold text-emerald-600">{stats.opened}</div>
          <div className="text-xs text-gray-400 mt-0.5">{openRate}% open rate</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-3">
          <div className="text-xs text-gray-500">Skipped</div>
          <div className="text-2xl font-semibold text-amber-600">{stats.skipped}</div>
        </div>
        <div className="bg-white border border-gray-200 rounded-lg p-3">
          <div className="text-xs text-gray-500">Failed</div>
          <div className="text-2xl font-semibold text-red-600">{stats.failed}</div>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1 mb-4 border-b border-gray-200">
        {[
          { key: 'all',      label: 'All' },
          { key: 'opened',   label: 'Opened' },
          { key: 'unopened', label: 'Unopened' },
          { key: 'errors',   label: 'Errors' },
        ].map(t => (
          <button
            key={t.key}
            onClick={() => setFilter(t.key as typeof filter)}
            className={
              `px-4 py-2 text-sm font-medium border-b-2 transition-colors ` +
              (filter === t.key
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700')
            }
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <div className="text-center py-16 text-gray-400">
          <div className="text-4xl mb-3">📭</div>
          <p>No emails to show</p>
        </div>
      ) : (
        <div className="rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-xs text-gray-500 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 text-left font-medium">Sent</th>
                <th className="px-4 py-3 text-left font-medium">Recipient</th>
                <th className="px-4 py-3 text-left font-medium">Party</th>
                <th className="px-4 py-3 text-left font-medium">Sequence</th>
                <th className="px-4 py-3 text-center font-medium">Status</th>
                <th className="px-4 py-3 text-right font-medium">Opens</th>
                <th className="px-4 py-3 text-right font-medium">Clicks</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.map(r => (
                <tr key={r.send_id} className="hover:bg-gray-50">
                  <td className="px-4 py-2.5 text-gray-600 whitespace-nowrap">
                    {formatDate(r.sent_at)}
                  </td>
                  <td className="px-4 py-2.5">
                    <div className="text-gray-900 truncate max-w-xs">
                      {r.contact_full_name ?? '—'}
                    </div>
                    {r.contact_email && (
                      <div className="text-xs text-gray-400 truncate max-w-xs">{r.contact_email}</div>
                    )}
                  </td>
                  <td className="px-4 py-2.5">
                    <span className="text-gray-700 truncate block max-w-[180px]">
                      {r.party_name ?? '—'}
                    </span>
                  </td>
                  <td className="px-4 py-2.5">
                    <span className="text-gray-700 truncate block max-w-[200px]">
                      {r.sequence_name}
                    </span>
                    <span className="text-xs text-gray-400">step {r.step_order + 1}</span>
                  </td>
                  <td className="px-4 py-2.5 text-center">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${STATUS_COLOR[r.send_status] ?? 'bg-gray-100 text-gray-600'}`}>
                      {r.send_status}
                    </span>
                  </td>
                  <td className="px-4 py-2.5 text-right">
                    {r.open_count > 0 ? (
                      <span className="text-emerald-600 font-medium">👁 {r.open_count}</span>
                    ) : (
                      <span className="text-gray-300">—</span>
                    )}
                  </td>
                  <td className="px-4 py-2.5 text-right">
                    {r.click_count > 0 ? (
                      <span className="text-blue-600 font-medium">🖱 {r.click_count}</span>
                    ) : (
                      <span className="text-gray-300">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
