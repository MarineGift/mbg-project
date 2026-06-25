// src/components/settings/email-blocklist-client.tsx
'use client';
import { useState, useTransition } from 'react';
import {
  Ban, Globe, Mail, Regex, Plus, Trash2, ToggleLeft, ToggleRight,
  Loader2, CheckCircle2, AlertCircle, X, Search,
} from 'lucide-react';
import {
  addBlocklistEntry, toggleBlocklistEntry, deleteBlocklistEntry,
  type BlocklistEntry, type BlocklistKind,
} from '@/lib/actions/email-blocklist';

const KIND_META: Record<BlocklistKind, { label: string; icon: typeof Mail; hint: string }> = {
  address: { label: 'Address', icon: Mail, hint: 'someone@example.com' },
  domain: { label: 'Domain', icon: Globe, hint: 'example.com (no @)' },
  regex: { label: 'Regex', icon: Regex, hint: '.*@spam\\.example\\.com$' },
};

export function EmailBlocklistClient({ initialEntries }: { initialEntries: BlocklistEntry[] }) {
  const [entries, setEntries] = useState(initialEntries);
  const [showAdd, setShowAdd] = useState(false);
  const [kind, setKind] = useState<BlocklistKind>('address');
  const [pattern, setPattern] = useState('');
  const [reason, setReason] = useState('');
  const [filter, setFilter] = useState('');
  const [isPending, start] = useTransition();
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  };

  const handleAdd = () => {
    const p = pattern.trim();
    if (!p) return;
    start(async () => {
      const res = await addBlocklistEntry(p, kind, reason || undefined);
      if (!res.ok) {
        showToast(res.error ?? 'Failed to add', false);
        return;
      }
      // optimistic refresh: prepend a stub; created_at sort keeps it on top
      setEntries((prev) => [
        {
          id: `tmp-${Date.now()}`,
          pattern: p.toLowerCase(),
          kind,
          reason: reason || null,
          notes: null,
          is_active: true,
          created_at: new Date().toISOString(),
        },
        ...prev,
      ]);
      setPattern('');
      setReason('');
      setShowAdd(false);
      showToast('Added to do-not-send list');
    });
  };

  const handleToggle = (id: string, cur: boolean) =>
    start(async () => {
      const res = await toggleBlocklistEntry(id, !cur);
      if (!res.ok) return showToast(res.error ?? 'Failed', false);
      setEntries((prev) => prev.map((e) => (e.id === id ? { ...e, is_active: !cur } : e)));
    });

  const handleDelete = (id: string, pat: string) => {
    if (!confirm(`Delete "${pat}" from the do-not-send list?`)) return;
    start(async () => {
      const res = await deleteBlocklistEntry(id);
      if (!res.ok) return showToast(res.error ?? 'Failed', false);
      setEntries((prev) => prev.filter((e) => e.id !== id));
      showToast('Deleted');
    });
  };

  const visible = entries.filter(
    (e) =>
      !filter ||
      e.pattern.toLowerCase().includes(filter.toLowerCase()) ||
      (e.reason ?? '').toLowerCase().includes(filter.toLowerCase()),
  );
  const activeCount = entries.filter((e) => e.is_active).length;

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="flex items-center gap-2 text-xl font-semibold">
            <Ban className="h-5 w-5 text-red-600" /> Email Blocklist
          </h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Do-not-send list. Any matching recipient is blocked on every send path
            (bulk, sequence, compose, reply) and cannot be bypassed. Reuses the
            whitelist pattern format: exact address, domain, or regex.
          </p>
        </div>
        <button
          onClick={() => setShowAdd((v) => !v)}
          className="inline-flex shrink-0 items-center gap-1.5 rounded-md bg-red-600 px-3 py-2 text-sm font-medium text-white hover:bg-red-700"
        >
          <Plus className="h-4 w-4" /> Add
        </button>
      </div>

      {showAdd && (
        <div className="rounded-lg border bg-card p-4">
          <div className="flex flex-wrap items-end gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-muted-foreground">Type</label>
              <div className="flex rounded-md border p-0.5">
                {(Object.keys(KIND_META) as BlocklistKind[]).map((k) => {
                  const Icon = KIND_META[k].icon;
                  return (
                    <button
                      key={k}
                      onClick={() => setKind(k)}
                      className={`flex items-center gap-1 rounded px-2.5 py-1.5 text-sm ${
                        kind === k ? 'bg-accent font-medium' : 'text-muted-foreground'
                      }`}
                    >
                      <Icon className="h-3.5 w-3.5" /> {KIND_META[k].label}
                    </button>
                  );
                })}
              </div>
            </div>
            <div className="min-w-[220px] flex-1">
              <label className="mb-1 block text-xs font-medium text-muted-foreground">Pattern</label>
              <input
                value={pattern}
                onChange={(e) => setPattern(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
                placeholder={KIND_META[kind].hint}
                className="w-full rounded-md border px-3 py-2 text-sm"
              />
            </div>
            <div className="min-w-[160px]">
              <label className="mb-1 block text-xs font-medium text-muted-foreground">Reason (optional)</label>
              <input
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
                placeholder="unsubscribe / complaint"
                className="w-full rounded-md border px-3 py-2 text-sm"
              />
            </div>
            <button
              onClick={handleAdd}
              disabled={isPending || !pattern.trim()}
              className="inline-flex items-center gap-1.5 rounded-md bg-foreground px-3 py-2 text-sm font-medium text-background disabled:opacity-50"
            >
              {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />} Add
            </button>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between gap-3">
        <div className="relative max-w-xs flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <input
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            placeholder="Filter..."
            className="w-full rounded-md border py-2 pl-8 pr-3 text-sm"
          />
        </div>
        <span className="text-sm text-muted-foreground">
          {activeCount} active / {entries.length} total
        </span>
      </div>

      <div className="overflow-hidden rounded-lg border">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left text-xs text-muted-foreground">
            <tr>
              <th className="px-4 py-2 font-medium">Pattern</th>
              <th className="px-4 py-2 font-medium">Type</th>
              <th className="px-4 py-2 font-medium">Reason</th>
              <th className="px-4 py-2 font-medium">Active</th>
              <th className="w-10 px-4 py-2" />
            </tr>
          </thead>
          <tbody>
            {visible.length === 0 && (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                  {entries.length === 0 ? 'No entries yet. Add an address, domain, or regex to block.' : 'No matches.'}
                </td>
              </tr>
            )}
            {visible.map((e) => {
              const Icon = KIND_META[(e.kind as BlocklistKind)]?.icon ?? Mail;
              return (
                <tr key={e.id} className="border-t">
                  <td className="px-4 py-2 font-mono">{e.pattern}</td>
                  <td className="px-4 py-2">
                    <span className="inline-flex items-center gap-1 text-muted-foreground">
                      <Icon className="h-3.5 w-3.5" /> {KIND_META[(e.kind as BlocklistKind)]?.label ?? e.kind}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-muted-foreground">{e.reason ?? '-'}</td>
                  <td className="px-4 py-2">
                    <button onClick={() => handleToggle(e.id, e.is_active)} disabled={isPending}>
                      {e.is_active ? (
                        <ToggleRight className="h-5 w-5 text-red-600" />
                      ) : (
                        <ToggleLeft className="h-5 w-5 text-muted-foreground" />
                      )}
                    </button>
                  </td>
                  <td className="px-4 py-2">
                    <button
                      onClick={() => handleDelete(e.id, e.pattern)}
                      disabled={isPending}
                      className="text-muted-foreground hover:text-red-600"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {toast && (
        <div
          className={`fixed bottom-4 right-4 z-50 flex items-center gap-2 rounded-md px-4 py-2.5 text-sm text-white shadow-lg ${
            toast.ok ? 'bg-green-600' : 'bg-red-600'
          }`}
        >
          {toast.ok ? <CheckCircle2 className="h-4 w-4" /> : <AlertCircle className="h-4 w-4" />}
          {toast.msg}
          <button onClick={() => setToast(null)}>
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      )}
    </div>
  );
}
