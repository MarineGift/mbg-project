// src/app/(app)/ipo/milestone-status-select.tsx
'use client';

import { useState } from 'react';
import { setMilestoneStatus } from './actions';

const OPTIONS: Array<[string, string]> = [
  ['not_started', 'Not started'], ['in_progress', 'In progress'], ['blocked', 'Blocked'], ['done', 'Done'], ['waived', 'Waived'],
];

export function MilestoneStatusSelect({ id, status, compact }: { id: string; status: string; compact?: boolean }) {
  const [val, setVal] = useState(status);
  const [pending, setPending] = useState(false);
  const start = (fn: () => Promise<void>) => { setPending(true); void fn().finally(() => setPending(false)); };
  const [err, setErr] = useState<string | null>(null);
  return (
    <span className="inline-flex items-center gap-1">
      <select
        value={val}
        disabled={pending}
        onChange={(e) => {
          const next = e.target.value;
          setVal(next);
          start(async () => {
            const r = await setMilestoneStatus({ milestoneId: id, status: next });
            if (!r.ok) { setErr(r.error); setVal(status); } else setErr(null);
          });
        }}
        className={'rounded border bg-background ' + (compact ? 'h-6 px-1 text-[11px]' : 'h-8 px-2 text-sm')}
        aria-label="Milestone status"
      >
        {OPTIONS.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
      </select>
      {err && <span className="text-[11px] text-red-600">{err}</span>}
    </span>
  );
}
