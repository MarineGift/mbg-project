/**
 * components/parties/investor-priority-editor.tsx
 *
 * Inline, editable Priority (Tier) control for the Investor Profile card.
 *   high = Tier A, medium = Tier B, low = Tier C, null = unset.
 * Click a level to set it; click the active level again to clear.
 * Saves via the updateInvestorPriority server action (upserts investor_profile).
 */

'use client';

import { useState, useTransition } from 'react';
import { updateInvestorPriority } from '@/lib/actions/parties';
import { cn } from '@/lib/utils';
import type { InvestorPriority } from '@/types/party-detail';

interface Props {
  partyId: string;
  partyType: string;
  value: InvestorPriority | null;
}

const OPTIONS: { value: InvestorPriority; label: string; active: string }[] = [
  { value: 'high', label: 'High (Tier A)', active: 'bg-red-100 text-red-700 ring-red-300' },
  { value: 'medium', label: 'Medium (Tier B)', active: 'bg-amber-100 text-amber-700 ring-amber-300' },
  { value: 'low', label: 'Low (Tier C)', active: 'bg-slate-100 text-slate-600 ring-slate-300' },
];

export function InvestorPriorityEditor({ partyId, partyType, value }: Props) {
  const [current, setCurrent] = useState<InvestorPriority | null>(value);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function choose(next: InvestorPriority | null) {
    const prev = current;
    setCurrent(next);
    setError(null);
    startTransition(async () => {
      const res = await updateInvestorPriority({ partyId, partyType, priority: next });
      if (!res.ok) {
        setCurrent(prev);
        setError(res.errorMessage ?? 'Failed to save');
      }
    });
  }

  return (
    <div className="flex flex-wrap items-center gap-1.5">
      {OPTIONS.map((o) => {
        const isActive = current === o.value;
        return (
          <button
            key={o.value}
            type="button"
            disabled={pending}
            aria-pressed={isActive}
            onClick={() => choose(isActive ? null : o.value)}
            className={cn(
              'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 transition',
              isActive
                ? o.active
                : 'bg-transparent text-muted-foreground ring-border hover:bg-muted',
              pending && 'opacity-60 cursor-wait',
            )}
          >
            {o.label}
          </button>
        );
      })}
      {pending && <span className="text-xs text-muted-foreground">Saving...</span>}
      {error && <span className="text-xs text-red-600">{error}</span>}
    </div>
  );
}
