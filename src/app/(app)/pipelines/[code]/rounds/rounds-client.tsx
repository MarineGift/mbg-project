// src/app/(app)/pipelines/[code]/rounds/rounds-client.tsx
//
// Client UI for the Round management screen.
//   - Table of rounds with rollups (committed / target progress / deals).
//   - Expandable per-stage breakdown.
//   - Create / edit via a Dialog form; delete via inline confirm.
//
// Mirrors the kanban/new-deal-modal conventions: shadcn Dialog + Button,
// theme tokens, USD single-currency assumption.

'use client';

import { Fragment, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Plus,
  Pencil,
  Trash2,
  ChevronRight,
  ChevronDown,
  ArrowLeft,
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import {
  createRound,
  updateRound,
  deleteRound,
} from '@/lib/actions/rounds';
import {
  ROUND_STATUSES,
  ROUND_STATUS_LABEL,
  type RoundStatus,
  type RoundWithRollup,
} from '@/types/round';

interface Props {
  pipelineName: string;
  rounds: RoundWithRollup[];
}

const STATUS_BADGE: Record<RoundStatus, string> = {
  planned: 'bg-zinc-100 text-zinc-700 ring-zinc-200',
  open: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  closed: 'bg-blue-50 text-blue-700 ring-blue-200',
  cancelled: 'bg-rose-50 text-rose-700 ring-rose-200',
};

function fmtMoney(n: number, currency = 'USD'): string {
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(n);
  } catch {
    return n.toLocaleString() + ' ' + currency;
  }
}

function fmtDate(iso: string | null): string {
  if (!iso) return '\u2014';
  // PG date 'YYYY-MM-DD' -> short display
  const d = new Date(iso + 'T00:00:00');
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

// ------------------------------------------------------------------
// Edit/create form state
// ------------------------------------------------------------------

interface FormState {
  name: string;
  roundType: string;
  status: RoundStatus;
  targetAmount: string;
  preMoneyValuation: string;
  openedAt: string;
  closedAt: string;
  notes: string;
}

function blankForm(): FormState {
  return {
    name: '',
    roundType: '',
    status: 'open',
    targetAmount: '',
    preMoneyValuation: '',
    openedAt: '',
    closedAt: '',
    notes: '',
  };
}

function formFromRound(r: RoundWithRollup): FormState {
  return {
    name: r.name,
    roundType: r.roundType ?? '',
    status: r.status,
    targetAmount: r.targetAmount ?? '',
    preMoneyValuation: r.preMoneyValuation ?? '',
    openedAt: r.openedAt ?? '',
    closedAt: r.closedAt ?? '',
    notes: r.notes ?? '',
  };
}

const INPUT_CLS =
  'w-full rounded-md border bg-background px-3 py-2 text-sm ' +
  'focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5';

export function RoundsClient({ pipelineName, rounds }: Props) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null); // null = create
  const [form, setForm] = useState<FormState>(blankForm);
  const [error, setError] = useState<string | null>(null);

  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);

  const openCreate = () => {
    setEditingId(null);
    setForm(blankForm());
    setError(null);
    setDialogOpen(true);
  };

  const openEdit = (r: RoundWithRollup) => {
    setEditingId(r.id);
    setForm(formFromRound(r));
    setError(null);
    setDialogOpen(true);
  };

  const patch = (p: Partial<FormState>) => setForm((f) => ({ ...f, ...p }));

  // string -> number|null, with validation. Returns { value } or { err }.
  const parseAmount = (
    s: string,
    label: string,
  ): { value: number | null } | { err: string } => {
    const t = s.trim();
    if (!t) return { value: null };
    const n = Number(t);
    if (!Number.isFinite(n) || n < 0) {
      return { err: label + ' must be a non-negative number' };
    }
    return { value: n };
  };

  const handleSubmit = () => {
    setError(null);
    const name = form.name.trim();
    if (!name) {
      setError('Round name is required');
      return;
    }
    const target = parseAmount(form.targetAmount, 'Target amount');
    if ('err' in target) {
      setError(target.err);
      return;
    }
    const valuation = parseAmount(form.preMoneyValuation, 'Valuation');
    if ('err' in valuation) {
      setError(valuation.err);
      return;
    }

    const common = {
      name,
      roundType: form.roundType.trim() || null,
      targetAmount: target.value,
      preMoneyValuation: valuation.value,
      status: form.status,
      openedAt: form.openedAt || null,
      closedAt: form.closedAt || null,
      notes: form.notes.trim() || null,
    };

    startTransition(async () => {
      const res = editingId
        ? await updateRound({ roundId: editingId, ...common })
        : await createRound({ currency: 'USD', ...common });
      if (res.ok) {
        setDialogOpen(false);
        router.refresh();
      } else {
        setError(res.errorMessage ?? 'Save failed');
      }
    });
  };

  const handleDelete = (roundId: string) => {
    setError(null);
    startTransition(async () => {
      const res = await deleteRound({ roundId });
      if (res.ok) {
        setConfirmDeleteId(null);
        router.refresh();
      } else {
        setError(res.errorMessage ?? 'Delete failed');
      }
    });
  };

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="flex items-center justify-between gap-4 border-b bg-background px-6 py-4">
        <div className="min-w-0">
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <Link
              href="/pipelines/investor"
              className="inline-flex items-center gap-1 hover:text-foreground"
            >
              <ArrowLeft className="h-3.5 w-3.5" />
              {pipelineName}
            </Link>
          </div>
          <h1 className="mt-0.5 truncate text-xl font-semibold text-foreground">
            Rounds
          </h1>
        </div>
        <Button size="sm" onClick={openCreate} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          New round
        </Button>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-auto px-6 py-4">
        {rounds.length === 0 ? (
          <div className="rounded-lg border border-dashed py-16 text-center text-sm text-muted-foreground">
            No rounds yet. Create one to group your investor deals.
          </div>
        ) : (
          <div className="overflow-hidden rounded-lg border">
            <table className="w-full border-collapse text-sm">
              <thead>
                <tr className="border-b bg-muted/40 text-left text-xs uppercase tracking-wider text-muted-foreground">
                  <th className="w-8 px-2 py-2" />
                  <th className="px-3 py-2 font-medium">Round</th>
                  <th className="px-3 py-2 font-medium">Status</th>
                  <th className="px-3 py-2 font-medium">Committed / Target</th>
                  <th className="px-3 py-2 font-medium">Valuation</th>
                  <th className="px-3 py-2 font-medium">Window</th>
                  <th className="px-3 py-2 text-right font-medium">Deals</th>
                  <th className="w-24 px-3 py-2 text-right font-medium">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody>
                {rounds.map((r) => {
                  const expanded = expandedId === r.id;
                  const currency = r.currency || 'USD';
                  const target =
                    r.targetAmount != null ? parseFloat(r.targetAmount) : null;
                  const valuation =
                    r.preMoneyValuation != null
                      ? parseFloat(r.preMoneyValuation)
                      : null;
                  const pct = r.progressPct;
                  const barPct =
                    pct == null ? 0 : Math.max(0, Math.min(100, pct));
                  const hasBreakdown = r.stageBreakdown.length > 0;
                  const confirming = confirmDeleteId === r.id;

                  return (
                    <Fragment key={r.id}>
                      <tr className="border-b last:border-0 align-top hover:bg-muted/20">
                        {/* expand toggle */}
                        <td className="px-2 py-3">
                          {hasBreakdown ? (
                            <button
                              type="button"
                              onClick={() =>
                                setExpandedId(expanded ? null : r.id)
                              }
                              className="text-muted-foreground hover:text-foreground"
                              aria-label={expanded ? 'Collapse' : 'Expand'}
                            >
                              {expanded ? (
                                <ChevronDown className="h-4 w-4" />
                              ) : (
                                <ChevronRight className="h-4 w-4" />
                              )}
                            </button>
                          ) : null}
                        </td>

                        {/* name + type */}
                        <td className="px-3 py-3">
                          <div className="font-medium text-foreground">
                            {r.name}
                          </div>
                          {r.roundType ? (
                            <div className="text-xs text-muted-foreground">
                              {r.roundType}
                            </div>
                          ) : null}
                        </td>

                        {/* status */}
                        <td className="px-3 py-3">
                          <span
                            className={
                              'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset ' +
                              STATUS_BADGE[r.status]
                            }
                          >
                            {ROUND_STATUS_LABEL[r.status]}
                          </span>
                        </td>

                        {/* committed / target + bar */}
                        <td className="px-3 py-3">
                          <div className="text-foreground">
                            {fmtMoney(r.committedTotal, currency)}
                            <span className="text-muted-foreground">
                              {' '}
                              /{' '}
                              {target != null
                                ? fmtMoney(target, currency)
                                : '\u2014'}
                            </span>
                          </div>
                          {target != null ? (
                            <div className="mt-1 flex items-center gap-2">
                              <div className="h-1.5 w-28 overflow-hidden rounded-full bg-muted">
                                <div
                                  className={
                                    'h-full rounded-full ' +
                                    (pct != null && pct >= 100
                                      ? 'bg-emerald-500'
                                      : 'bg-foreground/60')
                                  }
                                  style={{ width: barPct + '%' }}
                                />
                              </div>
                              <span className="text-xs text-muted-foreground tabular-nums">
                                {pct != null ? pct + '%' : '\u2014'}
                              </span>
                            </div>
                          ) : null}
                        </td>

                        {/* valuation */}
                        <td className="px-3 py-3 text-foreground">
                          {valuation != null
                            ? fmtMoney(valuation, currency)
                            : '\u2014'}
                        </td>

                        {/* window */}
                        <td className="px-3 py-3 text-xs text-muted-foreground">
                          {fmtDate(r.openedAt)}
                          <span className="px-1">{'\u2192'}</span>
                          {fmtDate(r.closedAt)}
                        </td>

                        {/* deal count */}
                        <td className="px-3 py-3 text-right tabular-nums text-foreground">
                          {r.dealCount}
                        </td>

                        {/* actions */}
                        <td className="px-3 py-3">
                          {confirming ? (
                            <div className="flex items-center justify-end gap-1">
                              <button
                                type="button"
                                disabled={pending}
                                onClick={() => handleDelete(r.id)}
                                className="rounded-md px-2 py-1 text-xs font-medium text-rose-700 hover:bg-rose-50 disabled:opacity-50"
                              >
                                Delete
                              </button>
                              <button
                                type="button"
                                disabled={pending}
                                onClick={() => setConfirmDeleteId(null)}
                                className="rounded-md px-2 py-1 text-xs text-muted-foreground hover:text-foreground"
                              >
                                Cancel
                              </button>
                            </div>
                          ) : (
                            <div className="flex items-center justify-end gap-1">
                              <button
                                type="button"
                                onClick={() => openEdit(r)}
                                className="rounded-md p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
                                aria-label="Edit round"
                              >
                                <Pencil className="h-3.5 w-3.5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => setConfirmDeleteId(r.id)}
                                className="rounded-md p-1.5 text-muted-foreground hover:bg-rose-50 hover:text-rose-700"
                                aria-label="Delete round"
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>

                      {/* stage breakdown */}
                      {expanded && hasBreakdown ? (
                        <tr
                          key={r.id + ':breakdown'}
                          className="border-b last:border-0 bg-muted/10"
                        >
                          <td />
                          <td colSpan={7} className="px-3 py-2">
                            <div className="space-y-1">
                              <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                                By stage
                              </div>
                              <div className="grid gap-1">
                                {r.stageBreakdown.map((s) => (
                                  <div
                                    key={s.stageId}
                                    className="flex items-center justify-between gap-4 text-xs"
                                  >
                                    <span className="text-foreground">
                                      {s.stageName}
                                    </span>
                                    <span className="text-muted-foreground tabular-nums">
                                      {s.dealCount}{' '}
                                      {s.dealCount === 1 ? 'deal' : 'deals'}
                                      {' \u00b7 '}
                                      {fmtMoney(s.committed, currency)}
                                    </span>
                                  </div>
                                ))}
                              </div>
                            </div>
                          </td>
                        </tr>
                      ) : null}
                    </Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {error && !dialogOpen ? (
          <div className="mt-3 rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700 ring-1 ring-inset ring-rose-200">
            {error}
          </div>
        ) : null}
      </div>

      {/* Create / edit dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingId ? 'Edit round' : 'New round'}</DialogTitle>
          </DialogHeader>

          <div className="space-y-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-muted-foreground">
                Name
              </label>
              <input
                className={INPUT_CLS}
                value={form.name}
                onChange={(e) => patch({ name: e.target.value })}
                placeholder="Series A"
                autoFocus
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Round type
                </label>
                <input
                  className={INPUT_CLS}
                  value={form.roundType}
                  onChange={(e) => patch({ roundType: e.target.value })}
                  placeholder="Equity / SAFE ..."
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Status
                </label>
                <select
                  className={INPUT_CLS}
                  value={form.status}
                  onChange={(e) =>
                    patch({ status: e.target.value as RoundStatus })
                  }
                >
                  {ROUND_STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {ROUND_STATUS_LABEL[s]}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Target amount (USD)
                </label>
                <input
                  className={INPUT_CLS}
                  inputMode="decimal"
                  value={form.targetAmount}
                  onChange={(e) => patch({ targetAmount: e.target.value })}
                  placeholder="10000000"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Pre-money valuation (USD)
                </label>
                <input
                  className={INPUT_CLS}
                  inputMode="decimal"
                  value={form.preMoneyValuation}
                  onChange={(e) =>
                    patch({ preMoneyValuation: e.target.value })
                  }
                  placeholder="50000000"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Opened
                </label>
                <input
                  type="date"
                  className={INPUT_CLS}
                  value={form.openedAt}
                  onChange={(e) => patch({ openedAt: e.target.value })}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-muted-foreground">
                  Closed
                </label>
                <input
                  type="date"
                  className={INPUT_CLS}
                  value={form.closedAt}
                  onChange={(e) => patch({ closedAt: e.target.value })}
                />
              </div>
            </div>

            <div>
              <label className="mb-1 block text-xs font-medium text-muted-foreground">
                Notes
              </label>
              <textarea
                className={INPUT_CLS + ' min-h-[64px] resize-y'}
                value={form.notes}
                onChange={(e) => patch({ notes: e.target.value })}
                placeholder="Optional"
              />
            </div>

            {error && dialogOpen ? (
              <div className="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700 ring-1 ring-inset ring-rose-200">
                {error}
              </div>
            ) : null}
          </div>

          <DialogFooter>
            <Button
              variant="ghost"
              onClick={() => setDialogOpen(false)}
              disabled={pending}
            >
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={pending}>
              {pending
                ? 'Saving\u2026'
                : editingId
                  ? 'Save changes'
                  : 'Create round'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
