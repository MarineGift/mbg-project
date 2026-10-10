'use client';

// src/components/mailing/mail-run-detail-dialog.tsx
// Detail view for one bulk mail run: summary + per-recipient status table
// (filterable by status, searchable), links to the party and the sent mail.
// Refreshes every 5 s while the run is still queued/running.

import { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { Download, RefreshCw } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { getMailRunDetail, type MailRunDetail } from '@/lib/actions/mail-run-detail';

const TERMINAL = ['completed', 'failed', 'canceled'];
const FILTERS = ['all', 'sent', 'failed', 'blocked', 'pending'] as const;
type Filter = (typeof FILTERS)[number];

const fmt = (s: string | null) => (s ? new Date(s).toLocaleString() : '-');

const statusCls = (s: string) =>
  s === 'sent' ? 'text-emerald-700'
  : s === 'failed' ? 'text-red-700'
  : s === 'blocked' ? 'text-amber-700'
  : 'text-muted-foreground';

export function MailRunDetailDialog({
  runId, onOpenChange,
}: { runId: string | null; onOpenChange: (open: boolean) => void }) {
  const [detail, setDetail] = useState<MailRunDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState<Filter>('all');
  const [q, setQ] = useState('');

  const load = useCallback(async (id: string) => {
    setLoading(true);
    const res = await getMailRunDetail(id);
    setLoading(false);
    if (!res.ok || !res.detail) { setError(res.errorMessage ?? 'Load failed'); return; }
    setError(null);
    setDetail(res.detail);
  }, []);

  useEffect(() => {
    setDetail(null); setFilter('all'); setQ(''); setError(null);
    if (runId) void load(runId);
  }, [runId, load]);

  useEffect(() => {
    if (!runId || !detail || TERMINAL.includes(detail.status)) return;
    const t = setInterval(() => { void load(runId); }, 5000);
    return () => clearInterval(t);
  }, [runId, detail, load]);

  const counts = useMemo(() => {
    const c: Record<string, number> = {};
    for (const r of detail?.recipients ?? []) {
      const k = r.status === 'sending' ? 'pending' : r.status;
      c[k] = (c[k] ?? 0) + 1;
    }
    return c;
  }, [detail]);

  const rows = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return (detail?.recipients ?? []).filter((r) => {
      const st = r.status === 'sending' ? 'pending' : r.status;
      if (filter !== 'all' && st !== filter) return false;
      if (!needle) return true;
      return `${r.partyName} ${r.email} ${r.error ?? ''}`.toLowerCase().includes(needle);
    });
  }, [detail, filter, q]);

  const exportCsv = () => {
    if (!detail) return;
    const esc = (v: string) => `"${v.replace(/"/g, '""')}"`;
    const lines = [
      ['company', 'email', 'status', 'sent_at', 'error'].join(','),
      ...rows.map((r) => [r.partyName, r.email, r.status, r.sentAt ?? '', r.error ?? ''].map(esc).join(',')),
    ];
    const blob = new Blob(['\ufeff' + lines.join('\n')], { type: 'text/csv;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `mail_run_${detail.id.slice(0, 8)}_${filter}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  return (
    <Dialog open={!!runId} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-5xl max-h-[90vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>Run detail</DialogTitle>
        </DialogHeader>

        {error && <p className="text-sm text-red-700">{error}</p>}
        {!detail && !error && <p className="text-sm text-muted-foreground">Loading…</p>}

        {detail && (
          <div className="flex min-h-0 flex-col gap-4">
            <div className="grid gap-x-6 gap-y-1 text-sm sm:grid-cols-2">
              <div><span className="text-muted-foreground">Template: </span>{detail.templateName ?? '-'}</div>
              <div><span className="text-muted-foreground">Status: </span><span className="font-medium capitalize">{detail.status}</span></div>
              <div className="sm:col-span-2"><span className="text-muted-foreground">Subject: </span>{detail.subject || '-'}</div>
              <div><span className="text-muted-foreground">From: </span>{detail.fromAddress ?? '-'}</div>
              <div>
                <span className="text-muted-foreground">Options: </span>
                {detail.recipientMode === 'all_contacts' ? 'all contacts' : 'primary contact'}
                {detail.ratePerMinute ? ` · ${detail.ratePerMinute}/min` : ''}
                {detail.bypassWhitelist ? ' · whitelist bypassed' : ''}
              </div>
              <div><span className="text-muted-foreground">Created: </span>{fmt(detail.createdAt)}</div>
              <div><span className="text-muted-foreground">Scheduled: </span>{fmt(detail.scheduledAt)}</div>
              <div><span className="text-muted-foreground">Started: </span>{fmt(detail.startedAt)}</div>
              <div><span className="text-muted-foreground">Completed: </span>{fmt(detail.completedAt)}</div>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              {FILTERS.map((f) => {
                const n = f === 'all' ? detail.recipients.length : (counts[f] ?? 0);
                return (
                  <button key={f} type="button" onClick={() => setFilter(f)}
                    className={'rounded-full border px-3 py-1 text-xs capitalize ' + (filter === f ? 'border-blue-600 bg-blue-50 text-blue-700' : 'hover:bg-muted')}>
                    {f} {n}
                  </button>
                );
              })}
              <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search company / e-mail / error"
                className="ml-auto w-64 rounded-md border bg-background px-3 py-1.5 text-sm" />
              <Button type="button" variant="outline" size="sm" onClick={() => runId && load(runId)} disabled={loading} title="Refresh">
                <RefreshCw className={'h-4 w-4 ' + (loading ? 'animate-spin' : '')} />
              </Button>
              <Button type="button" variant="outline" size="sm" onClick={exportCsv} title="Export CSV">
                <Download className="h-4 w-4" />
              </Button>
            </div>

            <div className="min-h-0 flex-1 overflow-auto rounded-md border">
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-muted/80 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-3 py-2">Company</th>
                    <th className="px-3 py-2">E-mail</th>
                    <th className="px-3 py-2">Status</th>
                    <th className="px-3 py-2">Sent at</th>
                    <th className="px-3 py-2">Error</th>
                    <th className="px-3 py-2"></th>
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 && (
                    <tr><td colSpan={6} className="px-3 py-6 text-center text-muted-foreground">No recipients</td></tr>
                  )}
                  {rows.map((r) => (
                    <tr key={r.id} className="border-t align-top">
                      <td className="px-3 py-2">
                        {r.partyId && r.partyTypeCode ? (
                          <Link href={`/${r.partyTypeCode}/parties/${r.partyId}`} className="hover:underline" target="_blank">
                            {r.partyName || '(unnamed)'}
                          </Link>
                        ) : (r.partyName || '-')}
                      </td>
                      <td className="px-3 py-2">{r.email}</td>
                      <td className={'px-3 py-2 capitalize ' + statusCls(r.status)}>{r.status}</td>
                      <td className="px-3 py-2 whitespace-nowrap text-xs">{fmt(r.sentAt)}</td>
                      <td className="px-3 py-2 text-xs text-red-700 max-w-[260px] break-words">{r.error ?? ''}</td>
                      <td className="px-3 py-2 text-xs">
                        {r.communicationId && (
                          <Link href={`/inbox/${r.communicationId}`} className="text-blue-600 hover:underline" target="_blank">Mail</Link>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="flex gap-2 text-xs text-muted-foreground">
              <Badge variant="outline">Total {detail.total}</Badge>
              <Badge variant="outline">Sent {detail.sent}</Badge>
              <Badge variant="outline">Failed {detail.failed}</Badge>
              <Badge variant="outline">Blocked {detail.blocked}</Badge>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
