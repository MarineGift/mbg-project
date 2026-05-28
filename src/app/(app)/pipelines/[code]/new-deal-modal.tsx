// src/app/(app)/pipelines/[code]/new-deal-modal.tsx
//
// Quick-create modal for a new deal. Three fields (name / counterparty / value).
// Counterparty uses server-side debounced search via the searchParties action.
//
// Hooks order: all React hooks declared at the top of each component, BEFORE
// any conditional return -- avoids the "Rendered fewer hooks than expected"
// runtime error when the selected-state branch is taken.

'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Search } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { createDeal, searchParties } from './actions';

type Stage = { id: string; code: string; name: string; sort_order: number };

interface PartyResult {
  id: string;
  party_name: string;
  country_code: string | null;
}

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  pipelineCode: string;
  pipelineName: string;
  stages: Stage[];
}

export function NewDealModal({
  open,
  onOpenChange,
  pipelineCode,
  pipelineName,
  stages,
}: Props) {
  const router = useRouter();

  const [dealName, setDealName] = useState('');
  const [partyId, setPartyId] = useState('');
  const [partyDisplay, setPartyDisplay] = useState('');
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const firstStage = stages[0];

  useEffect(() => {
    if (!open) {
      setDealName('');
      setPartyId('');
      setPartyDisplay('');
      setValue('');
      setError(null);
    }
  }, [open]);

  const handleSubmit = () => {
    setError(null);
    const trimmedName = dealName.trim();
    if (!trimmedName) { setError('Deal name is required'); return; }
    if (!partyId) { setError('Please select a counterparty'); return; }
    if (!firstStage) { setError('No stages configured for this pipeline'); return; }

    let amount: number | null = null;
    if (value.trim()) {
      const n = Number(value);
      if (!Number.isFinite(n) || n < 0) {
        setError('Value must be a positive number');
        return;
      }
      amount = n;
    }

    startTransition(async () => {
      const result = await createDeal({
        pipelineCode,
        deal_name: trimmedName,
        party_id: partyId,
        current_stage_id: firstStage.id,
        value_amount: amount,
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
      <DialogContent className="max-w-md">
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

          {/* Counterparty */}
          <div>
            <label className="mb-1 block text-sm font-medium text-foreground">
              Counterparty <span className="text-rose-600">*</span>
            </label>
            <PartySearchInput
              partyId={partyId}
              partyDisplay={partyDisplay}
              onSelect={(p) => {
                setPartyId(p.id);
                setPartyDisplay(p.party_name);
              }}
              onClear={() => {
                setPartyId('');
                setPartyDisplay('');
              }}
              disabled={isPending}
            />
          </div>

          {/* Value */}
          <div>
            <label
              htmlFor="deal-value"
              className="mb-1 block text-sm font-medium text-foreground"
            >
              Value (USD)
              <span className="ml-1 text-xs font-normal text-muted-foreground">
                optional
              </span>
            </label>
            <input
              id="deal-value"
              type="number"
              min="0"
              step="any"
              value={value}
              onChange={(e) => setValue(e.target.value)}
              placeholder="50000"
              className="w-full rounded-md border bg-background px-3 py-2 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
              disabled={isPending}
            />
          </div>

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
// Counterparty search (debounced, server-side)
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

  // Click outside to close dropdown. Declared BEFORE the early return so
  // React always counts the same number of hooks per render.
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
      <div className="flex items-center gap-2 rounded-md border bg-muted/30 px-3 py-2 text-sm">
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

  // Regular helper -- not a hook, can live below the conditional return
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
          className="w-full rounded-md border bg-background py-2 pl-9 pr-3 text-sm focus:border-foreground/30 focus:outline-none focus:ring-2 focus:ring-foreground/5"
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
