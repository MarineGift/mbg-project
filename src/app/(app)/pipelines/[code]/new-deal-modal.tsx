// src/app/(app)/pipelines/[code]/new-deal-modal.tsx
//
// Quick-create modal for a new deal.
//   - Deal name
//   - Companies: one or more rows (company search + role + commitment amount).
//     A deal is many-to-many with parties (app.deal_parties); each row becomes
//     one deal_parties row. Deal total = sum of commitments.
//   - Round (Investor pipeline only): optional selector + inline "+ New".
//
// The company-section label adapts to the pipeline (Investors / Paper mills /
// Filler suppliers / Companies).
//
// Hooks order: all React hooks declared at the top of each component, BEFORE
// any conditional return.

'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Plus, X } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { createDeal, searchParties } from './actions';
import { createRound } from '@/lib/actions/rounds';

type Stage = { id: string; code: string; name: string; sort_order: number };
type RoundOption = { id: string; name: string };

interface PartyResult {
  id: string;
  party_name: string;
  country_code: string | null;
}

interface CompanyRow {
  key: string;
  partyId: string;
  partyDisplay: string;
  role: string;
  amount: string;
}

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  pipelineCode: string;
  pipelineName: string;
  stages: Stage[];
  /** Investor pipeline only; [] elsewhere. */
  rounds: RoundOption[];
}

let _rowSeq = 0;
function blankRow(role: string): CompanyRow {
  _rowSeq += 1;
  return { key: 'r' + _rowSeq, partyId: '', partyDisplay: '', role, amount: '0' };
}

export function NewDealModal({
  open,
  onOpenChange,
  pipelineCode,
  pipelineName,
  stages,
  rounds,
}: Props) {
  const router = useRouter();
  const isInvestor = pipelineCode === 'investor';
  const firstStage = stages[0];

  const firstRole = isInvestor ? 'lead' : 'primary';
  const addRole = isInvestor ? 'co_investor' : 'participant';

  const roleOptions: Array<[string, string]> = isInvestor
    ? [
        ['lead', 'Lead'],
        ['co_investor', 'Co-investor'],
        ['participant', 'Participant'],
        ['advisor', 'Advisor'],
      ]
    : [
        ['primary', 'Primary'],
        ['participant', 'Participant'],
        ['advisor', 'Advisor'],
      ];

  const companyLabel =
    pipelineCode === 'investor'
      ? 'Investors'
      : pipelineCode === 'paper_mill'
        ? 'Paper mills'
        : pipelineCode === 'filler_supplier'
          ? 'Filler suppliers'
          : 'Companies';

  const [dealName, setDealName] = useState('');
  const [rows, setRows] = useState<CompanyRow[]>(() => [blankRow(firstRole)]);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  // Round (investor only)
  const [roundId, setRoundId] = useState('');
  const [newRoundMode, setNewRoundMode] = useState(false);
  const [newRoundName, setNewRoundName] = useState('');
  const [creatingRound, startRoundTransition] = useTransition();

  useEffect(() => {
    if (!open) {
      setDealName('');
      setRows([blankRow(firstRole)]);
      setError(null);
      setRoundId('');
      setNewRoundMode(false);
      setNewRoundName('');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const updateRow = (key: string, patch: Partial<CompanyRow>) =>
    setRows((prev) => prev.map((r) => (r.key === key ? { ...r, ...patch } : r)));
  const addRow = () => setRows((prev) => [...prev, blankRow(addRole)]);
  const removeRow = (key: string) =>
    setRows((prev) => (prev.length > 1 ? prev.filter((r) => r.key !== key) : prev));

  // Live total of entered commitments (single currency assumed: USD).
  const total = rows.reduce((sum, r) => {
    const n = Number(r.amount);
    return sum + (r.amount.trim() && Number.isFinite(n) && n >= 0 ? n : 0);
  }, 0);

  const handleCreateRound = () => {
    const name = newRoundName.trim();
    if (!name) return;
    setError(null);
    startRoundTransition(async () => {
      const res = await createRound({ name });
      if (res.ok && res.roundId) {
        setRoundId(res.roundId);
        setNewRoundMode(false);
        setNewRoundName('');
        router.refresh();
      } else {
        setError(res.errorMessage ?? 'Failed to create round');
      }
    });
  };

  const handleSubmit = () => {
    setError(null);
    const trimmedName = dealName.trim();
    if (!trimmedName) { setError('Deal name is required'); return; }
    if (!firstStage) { setError('No stages configured for this pipeline'); return; }

    const filled = rows.filter((r) => r.partyId);
    if (filled.length === 0) { setError('Add at least one company'); return; }

    const seen = new Set<string>();
    const parties: Array<{
      partyId: string;
      role: 'lead' | 'co_investor' | 'participant' | 'advisor' | 'primary';
      commitmentAmount: number | null;
      currency: string;
    }> = [];
    for (const r of filled) {
      if (seen.has(r.partyId)) { setError('The same company is listed twice'); return; }
      seen.add(r.partyId);
      let amount: number | null = null;
      if (r.amount.trim()) {
        const n = Number(r.amount);
        if (!Number.isFinite(n) || n < 0) {
          setError('Each amount must be a non-negative number');
          return;
        }
        amount = n;
      }
      parties.push({
        partyId: r.partyId,
        role: r.role as 'lead' | 'co_investor' | 'participant' | 'advisor' | 'primary',
        commitmentAmount: amount,
        currency: 'USD',
      });
    }

    startTransition(async () => {
      const result = await createDeal({
        pipelineCode,
        deal_name: trimmedName,
        current_stage_id: firstStage.id,
        parties,
        round_id: isInvestor ? (roundId || null) : null,
      });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      onOpenChange(false);
      router.push('/pipelines/' + pipelineCode + '/deals/' + result.dealId);
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-xl">
        <DialogHeader>
          <DialogTitle>New {pipelineName} deal</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Deal name */}
          <div>
            <label
              htmlFor="deal-name"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Deal name <span className="text-rose-600">*</span>
            </label>
            <input
              id="deal-name"
              type="text"
              value={dealName}
              onChange={(e) => setDealName(e.target.value)}
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              autoFocus
              maxLength={200}
              disabled={isPending}
            />
          </div>

          {/* Companies (M:N) */}
          <div>
            <label className="mb-1 block text-sm font-medium text-foreground">
              {companyLabel} <span className="text-rose-600">*</span>
            </label>

            <div className="space-y-2">
              {rows.map((row) => (
                <div key={row.key} className="flex items-start gap-2">
                  <div className="min-w-0 flex-1">
                    <PartySearchInput
                      partyId={row.partyId}
                      partyDisplay={row.partyDisplay}
                      onSelect={(p) =>
                        updateRow(row.key, { partyId: p.id, partyDisplay: p.party_name })
                      }
                      onClear={() =>
                        updateRow(row.key, { partyId: '', partyDisplay: '' })
                      }
                      disabled={isPending}
                    />
                  </div>
                  <select
                    value={row.role}
                    onChange={(e) => updateRow(row.key, { role: e.target.value })}
                    disabled={isPending}
                    className="h-[38px] w-32 shrink-0 rounded-md border bg-background px-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
                  >
                    {roleOptions.map(([v, l]) => (
                      <option key={v} value={v}>{l}</option>
                    ))}
                  </select>
                  <input
                    type="number"
                    min="0"
                    step="any"
                    value={row.amount}
                    onChange={(e) => updateRow(row.key, { amount: e.target.value })}
                    placeholder="Amount"
                    disabled={isPending}
                    className="h-[38px] w-28 shrink-0 rounded-md border bg-background px-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
                  />
                  <button
                    type="button"
                    onClick={() => removeRow(row.key)}
                    disabled={isPending || rows.length <= 1}
                    aria-label="Remove company"
                    className="mt-1 shrink-0 text-muted-foreground hover:text-foreground disabled:opacity-30"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>

            <div className="mt-2 flex items-center justify-between">
              <button
                type="button"
                onClick={addRow}
                disabled={isPending}
                className="inline-flex items-center gap-1 text-xs font-medium text-muted-foreground hover:text-foreground disabled:opacity-50"
              >
                <Plus className="h-3.5 w-3.5" />
                Add company
              </button>
              {total > 0 ? (
                <span className="text-xs text-muted-foreground">
                  Total:{' '}
                  <span className="font-medium tabular-nums text-foreground">
                    US${total.toLocaleString()}
                  </span>
                </span>
              ) : null}
            </div>
          </div>

          {/* Round (Investor pipeline only) */}
          {isInvestor && (
            <div>
              <label className="mb-1 block text-sm font-medium text-foreground">
                Round
                <span className="ml-1 text-xs font-normal text-muted-foreground">
                  optional
                </span>
              </label>

              {!newRoundMode ? (
                <div className="flex gap-2">
                  <select
                    value={roundId}
                    onChange={(e) => setRoundId(e.target.value)}
                    disabled={isPending}
                    className="flex-1 rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
                  >
                    <option value="">No round</option>
                    {rounds.map((r) => (
                      <option key={r.id} value={r.id}>
                        {r.name}
                      </option>
                    ))}
                  </select>
                  <button
                    type="button"
                    onClick={() => setNewRoundMode(true)}
                    disabled={isPending}
                    className="shrink-0 rounded-md border px-3 py-2 text-sm text-muted-foreground hover:text-foreground disabled:opacity-50"
                  >
                    + New
                  </button>
                </div>
              ) : (
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={newRoundName}
                    onChange={(e) => setNewRoundName(e.target.value)}
                    placeholder="e.g. Series A"
                    maxLength={120}
                    disabled={creatingRound}
                    className="flex-1 rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
                  />
                  <button
                    type="button"
                    onClick={handleCreateRound}
                    disabled={creatingRound || !newRoundName.trim()}
                    className="shrink-0 rounded-md border px-3 py-2 text-sm font-medium text-foreground hover:bg-muted disabled:opacity-50"
                  >
                    {creatingRound ? '...' : 'Create'}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setNewRoundMode(false);
                      setNewRoundName('');
                    }}
                    disabled={creatingRound}
                    className="shrink-0 rounded-md px-2 py-2 text-sm text-muted-foreground hover:text-foreground disabled:opacity-50"
                  >
                    Cancel
                  </button>
                </div>
              )}
            </div>
          )}

          {firstStage && (
            <div className="text-xs text-muted-foreground">
              Will be added to{' '}
              <span className="font-medium text-foreground">{firstStage.name}</span>
              . You can drag it to a different stage afterward.
            </div>
          )}

          {error && (
            <div className="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700 ring-1 ring-inset ring-rose-200">
              {error}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isPending}
          >
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={isPending}>
            {isPending ? 'Creating...' : 'Create deal'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================
// Counterparty search (debounced, server-side) - one per company row
// ============================================================

function PartySearchInput({
  partyId,
  partyDisplay,
  onSelect,
  onClear,
  disabled,
}: {
  partyId: string;
  partyDisplay: string;
  onSelect: (p: PartyResult) => void;
  onClear: () => void;
  disabled?: boolean;
}) {
  // === ALL HOOKS FIRST -- before any conditional return ===
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<PartyResult[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  // === Now it's safe to branch on selected vs unselected ===
  if (partyId) {
    return (
      <div className="flex h-[38px] items-center gap-2 rounded-md border bg-muted/30 px-3 text-sm">
        <span className="flex-1 truncate font-medium text-foreground">
          {partyDisplay}
        </span>
        <button
          type="button"
          onClick={onClear}
          disabled={disabled}
          className="text-xs text-muted-foreground hover:text-foreground disabled:opacity-50"
        >
          Change
        </button>
      </div>
    );
  }

  const runSearch = (q: string) => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(async () => {
      setLoading(true);
      try {
        const r = await searchParties(q);
        setResults(r);
        setOpen(true);
      } finally {
        setLoading(false);
      }
    }, 250);
  };

  return (
    <div ref={containerRef} className="relative">
      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <input
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            runSearch(e.target.value);
          }}
          onFocus={() => runSearch(query)}
          placeholder="Search company name..."
          disabled={disabled}
          className="h-[38px] w-full rounded-md border bg-background pl-9 pr-3 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
        />
      </div>

      {open && (
        <div className="absolute z-50 mt-1 w-full overflow-hidden rounded-md border bg-popover shadow-md">
          {loading ? (
            <div className="px-3 py-2 text-xs text-muted-foreground">
              Searching...
            </div>
          ) : results.length === 0 ? (
            <div className="px-3 py-3 text-xs text-muted-foreground">
              No companies found
            </div>
          ) : (
            <ul className="max-h-60 overflow-y-auto py-1">
              {results.map((p) => (
                <li key={p.id}>
                  <button
                    type="button"
                    onClick={() => {
                      onSelect(p);
                      setOpen(false);
                      setQuery('');
                    }}
                    className="block w-full px-3 py-1.5 text-left text-sm hover:bg-muted"
                  >
                    <span className="font-medium text-foreground">
                      {p.party_name}
                    </span>
                    {p.country_code && (
                      <span className="ml-2 text-xs text-muted-foreground">
                        {p.country_code}
                      </span>
                    )}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
