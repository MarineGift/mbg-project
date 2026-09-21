// src/app/(app)/ipo/snapshot-panel.tsx
//
// The only numeric input point: app.ipo_metric_snapshots. Same date = overwrite.

'use client';

import { useState } from 'react';
import { addMetricSnapshot, recordDecisionReview } from './actions';

export type MetricOpt = { id: string; code: string; label: string; unit: string; requires_verification: boolean };

export function SnapshotForm({ metrics }: { metrics: MetricOpt[] }) {
  const [metricId, setMetricId] = useState(metrics[0]?.id ?? '');
  const [asOf, setAsOf] = useState(new Date().toISOString().slice(0, 10));
  const [value, setValue] = useState('');
  const [verified, setVerified] = useState(false);
  const [note, setNote] = useState('');
  const [msg, setMsg] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const start = (fn: () => Promise<void>) => { setPending(true); void fn().finally(() => setPending(false)); };
  const m = metrics.find((x) => x.id === metricId);
  return (
    <form className="flex flex-col gap-2 rounded-md border p-3 text-sm" onSubmit={(e) => {
      e.preventDefault();
      start(async () => {
        const r = await addMetricSnapshot({ metricId, asOf, value: Number(value), verified, sourceNote: note });
        setMsg(r.ok ? 'Saved' : r.error);
        if (r.ok) setValue('');
      });
    }}>
      <div className="grid gap-2 sm:grid-cols-[1fr_140px_160px]">
        <select value={metricId} onChange={(e) => setMetricId(e.target.value)} className="h-9 rounded border bg-background px-2">
          {metrics.map((x) => <option key={x.id} value={x.id}>{x.label} ({x.unit})</option>)}
        </select>
        <input type="date" value={asOf} onChange={(e) => setAsOf(e.target.value)} className="h-9 rounded border bg-background px-2" />
        <input type="number" step="any" required value={value} onChange={(e) => setValue(e.target.value)} placeholder="Value" className="h-9 rounded border bg-background px-2" />
      </div>
      <div className="grid gap-2 sm:grid-cols-[1fr_auto]">
        <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="Source (e.g. FY2027 audit report, cap table v12)" className="h-9 rounded border bg-background px-2" />
        <label className="inline-flex items-center gap-2 text-xs">
          <input type="checkbox" checked={verified} onChange={(e) => setVerified(e.target.checked)} /> Verified
          {m?.requires_verification && <span className="text-amber-700">(not used for criteria until verified)</span>}
        </label>
      </div>
      <div className="flex items-center gap-3">
        <button type="submit" disabled={pending || !metricId} className="rounded bg-foreground px-3 py-1.5 text-xs text-background disabled:opacity-50">Save snapshot</button>
        {msg && <span className="text-xs text-muted-foreground">{msg}</span>}
      </div>
    </form>
  );
}

export function DecisionForm({ programId }: { programId: string }) {
  const [stage, setStage] = useState('quarterly');
  const [decision, setDecision] = useState('undecided');
  const [rationale, setRationale] = useState('');
  const [msg, setMsg] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const start = (fn: () => Promise<void>) => { setPending(true); void fn().finally(() => setPending(false)); };
  return (
    <form className="flex flex-col gap-2 rounded-md border p-3 text-sm" onSubmit={(e) => {
      e.preventDefault();
      start(async () => {
        const r = await recordDecisionReview({ programId, stage, decision, rationale });
        setMsg(r.ok ? 'Recorded' : r.error);
      });
    }}>
      <div className="grid gap-2 sm:grid-cols-2">
        <select value={stage} onChange={(e) => setStage(e.target.value)} className="h-9 rounded border bg-background px-2">
          <option value="quarterly">Quarterly review</option><option value="gate1">Gate 1 — Preliminary</option>
          <option value="gate2">Gate 2 — Final Internal</option><option value="gate3">Gate 3 — Underwriter</option>
        </select>
        <select value={decision} onChange={(e) => setDecision(e.target.value)} className="h-9 rounded border bg-background px-2">
          <option value="undecided">Undecided</option><option value="accelerated_2029q4">Accelerate — 2029 Q4</option>
          <option value="base_2030q2">Base — 2030 Q2</option><option value="defer">Defer</option>
        </select>
      </div>
      <textarea value={rationale} onChange={(e) => setRationale(e.target.value)} rows={2} placeholder="Rationale" className="rounded border bg-background p-2" />
      <div className="flex items-center gap-3">
        <button type="submit" disabled={pending} className="rounded bg-foreground px-3 py-1.5 text-xs text-background disabled:opacity-50">Record decision</button>
        {msg && <span className="text-xs text-muted-foreground">{msg}</span>}
      </div>
    </form>
  );
}
