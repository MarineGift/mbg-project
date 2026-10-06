// src/app/(app)/pipelines/[code]/bulk-update-modal.tsx
//
// Bulk update (2026-10-05): paste investor feedback, one investor per line,
//   "InnoEnergy: passing, no sector expertise in pulp and paper."
// Each line is matched to the deals on this board (deal name or any company
// name), the target stage is guessed from the text ("passing", "not a fit",
// "outside their scope" -> Passed), and on Apply every row gets the stage move
// plus a note on the deal timeline. Rows can be corrected before applying.

'use client';

import { useMemo, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Check, AlertTriangle } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { bulkUpdateDeals } from './actions';

type Stage = { id: string; code: string; name: string; sort_order: number };
export type BulkDeal = {
  id: string;
  deal_name: string;
  current_stage_id: string;
  last_activity_at: string | null;
  deal_parties: Array<{ parties: { party_name: string } | null }> | null;
  round: { id: string; name: string } | null;
};

interface Props {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  pipelineCode: string;
  stages: Stage[];
  deals: BulkDeal[];
}

type Row = {
  key: string;
  name: string;
  note: string;
  matches: BulkDeal[];
  selected: Set<string>;
  stageId: string; // '' = keep current
};

export function normalize(s: string): string {
  return (s ?? '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/&/g, 'and')
    .replace(/[^a-z0-9\uac00-\ud7a3]+/g, ' ')
    .replace(/\b(inc|llc|ltd|co|corp|gmbh|ag|sa|the)\b/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function dealHaystack(d: BulkDeal): string[] {
  const out = [normalize(d.deal_name)];
  for (const p of d.deal_parties ?? []) {
    if (p.parties?.party_name) out.push(normalize(p.parties.party_name));
  }
  return out;
}

function findMatches(name: string, deals: BulkDeal[]): BulkDeal[] {
  const q = normalize(name);
  if (q.length < 2) return [];
  const hits = deals.filter((d) =>
    dealHaystack(d).some((h) => h.includes(q) || (h.length >= 4 && q.includes(h)))
  );
  // most recently active first (Seed 2026 deals before old Bridge deals)
  return hits.sort(
    (a, b) =>
      new Date(b.last_activity_at ?? 0).getTime() -
      new Date(a.last_activity_at ?? 0).getTime()
  );
}

function guessStageCode(note: string): string | null {
  const t = note.toLowerCase();
  if (
    /\bpass(ing|ed|es)?\b|not a (good )?fit|no fit|not fit|doesn.?t fit|outside (of )?(their|our|the)|out of scope|declin|not interested|no longer interested|won.?t (be )?(invest|proceed|move)/.test(
      t
    )
  )
    return 'passed';
  if (/\bon hold\b|\bhold\b|revisit|too early|circle back|come back (to|later)/.test(t)) return 'hold';
  if (/\bmeeting\b|call (is )?scheduled|set up a call/.test(t)) return 'meeting';
  return null;
}

function parseLines(text: string): Array<{ name: string; note: string }> {
  const out: Array<{ name: string; note: string }> = [];
  for (const raw of text.split(/\r?\n/)) {
    let line = raw.trim();
    if (!line) continue;
    line = line.replace(/^(\d+[.)]|[-*\u2022])\s*/, '');
    const m = line.match(/^(.{2,80}?)\s*(?::|\s[-\u2013\u2014]\s)\s*(.*)$/);
    if (m) out.push({ name: m[1]!.trim(), note: m[2]!.trim() });
    else if (out.length > 0 && !/^[A-Z][^:]{1,60}$/.test(line)) {
      // continuation of the previous investor's feedback
      out[out.length - 1]!.note += ' ' + line;
    } else out.push({ name: line, note: '' });
  }
  return out;
}

export function BulkUpdateModal({ open, onOpenChange, pipelineCode, stages, deals }: Props) {
  const router = useRouter();
  const [text, setText] = useState('');
  const [rows, setRows] = useState<Row[] | null>(null);
  const [pending, startTransition] = useTransition();
  const [result, setResult] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const stageByCode = useMemo(() => new Map(stages.map((s) => [s.code, s])), [stages]);
  const stageById = useMemo(() => new Map(stages.map((s) => [s.id, s])), [stages]);

  const reset = () => {
    setText('');
    setRows(null);
    setResult(null);
    setErrors({});
  };

  const analyze = () => {
    const parsed = parseLines(text);
    setRows(
      parsed.map((p, i) => {
        const matches = findMatches(p.name, deals);
        const code = guessStageCode(p.note);
        return {
          key: i + ':' + p.name,
          name: p.name,
          note: p.note,
          matches,
          selected: new Set(matches.slice(0, 1).map((d) => d.id)),
          stageId: code ? stageByCode.get(code)?.id ?? '' : '',
        };
      })
    );
    setResult(null);
    setErrors({});
  };

  const updateRow = (key: string, patch: Partial<Row>) =>
    setRows((prev) => (prev ?? []).map((r) => (r.key === key ? { ...r, ...patch } : r)));

  const toggleDeal = (key: string, dealId: string) =>
    setRows((prev) =>
      (prev ?? []).map((r) => {
        if (r.key !== key) return r;
        const sel = new Set(r.selected);
        if (sel.has(dealId)) sel.delete(dealId);
        else sel.add(dealId);
        return { ...r, selected: sel };
      })
    );

  const researchRow = (key: string, name: string) =>
    updateRow(key, (() => {
      const matches = findMatches(name, deals);
      return { name, matches, selected: new Set(matches.slice(0, 1).map((d) => d.id)) };
    })());

  const items = (rows ?? []).flatMap((r) =>
    Array.from(r.selected).map((dealId) => ({
      dealId,
      stageId: r.stageId || null,
      note: r.note,
    }))
  );

  const apply = () => {
    if (items.length === 0) return;
    startTransition(async () => {
      const res = await bulkUpdateDeals(pipelineCode, items);
      const errs: Record<string, string> = {};
      for (const r of res.results) if (!r.ok) errs[r.dealId] = r.error ?? 'failed';
      setErrors(errs);
      const okCount = res.results.filter((r) => r.ok).length;
      setResult(okCount + ' updated' + (Object.keys(errs).length ? ', ' + Object.keys(errs).length + ' failed' : ''));
      router.refresh();
    });
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!v) reset();
        onOpenChange(v);
      }}
    >
      <DialogContent className="max-h-[90vh] max-w-3xl overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Bulk update from feedback</DialogTitle>
        </DialogHeader>

        {rows === null ? (
          <div className="space-y-2">
            <p className="text-xs text-muted-foreground">
              One investor per line, as <code>Name: feedback</code>. Numbering is fine. The
              stage is guessed from the text (passing / not a fit / outside scope {'->'} Passed)
              and the feedback is saved as a note on the deal.
            </p>
            <textarea
              value={text}
              onChange={(e) => setText(e.target.value)}
              rows={10}
              placeholder={'1. InnoEnergy: passing, no sector expertise in pulp and paper.\n2. Evergreen Climate Innovations: outside their geographic scope.'}
              className="w-full rounded-md border bg-background p-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>
        ) : (
          <div className="space-y-3">
            {rows.length === 0 ? (
              <div className="text-sm text-muted-foreground">Nothing to parse.</div>
            ) : null}
            {rows.map((r) => (
              <div key={r.key} className="rounded-md border p-3 text-sm">
                <div className="flex flex-wrap items-center gap-2">
                  <input
                    defaultValue={r.name}
                    onBlur={(e) => {
                      if (e.target.value.trim() !== r.name) researchRow(r.key, e.target.value.trim());
                    }}
                    className="min-w-0 flex-1 rounded border bg-background px-2 py-1 font-medium"
                    title="Edit the name and leave the field to search again"
                  />
                  <select
                    value={r.stageId}
                    onChange={(e) => updateRow(r.key, { stageId: e.target.value })}
                    className="rounded border bg-background px-2 py-1 text-sm"
                  >
                    <option value="">(keep stage)</option>
                    {stages.map((s) => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>

                <div className="mt-2 space-y-1">
                  {r.matches.length === 0 ? (
                    <div className="flex items-center gap-1 text-xs text-amber-600">
                      <AlertTriangle className="h-3.5 w-3.5" />
                      No deal on this board matches. Edit the name (e.g. a shorter part) to search again.
                    </div>
                  ) : (
                    r.matches.slice(0, 6).map((d) => (
                      <label key={d.id} className="flex cursor-pointer items-center gap-2 text-xs">
                        <input
                          type="checkbox"
                          checked={r.selected.has(d.id)}
                          onChange={() => toggleDeal(r.key, d.id)}
                        />
                        <span className="font-medium text-foreground">{d.deal_name}</span>
                        <span className="text-muted-foreground">
                          {'\u00b7'} {stageById.get(d.current_stage_id)?.name ?? '?'}
                          {d.round ? ' \u00b7 ' + d.round.name : ''}
                        </span>
                        {errors[d.id] ? (
                          <span className="text-red-600">{errors[d.id]}</span>
                        ) : result && r.selected.has(d.id) ? (
                          <Check className="h-3.5 w-3.5 text-emerald-600" />
                        ) : null}
                      </label>
                    ))
                  )}
                </div>

                <textarea
                  value={r.note}
                  onChange={(e) => updateRow(r.key, { note: e.target.value })}
                  rows={2}
                  placeholder="Note (optional)"
                  className="mt-2 w-full rounded border bg-background p-2 text-xs"
                />
              </div>
            ))}
          </div>
        )}

        <DialogFooter className="items-center gap-2">
          {result ? <span className="mr-auto text-sm text-muted-foreground">{result}</span> : null}
          {rows === null ? (
            <Button size="sm" onClick={analyze} disabled={!text.trim()}>
              Match investors
            </Button>
          ) : (
            <>
              <Button size="sm" variant="outline" onClick={() => setRows(null)} disabled={pending}>
                Back
              </Button>
              {result ? (
                <Button size="sm" onClick={() => { reset(); onOpenChange(false); }}>
                  Done
                </Button>
              ) : (
                <Button size="sm" onClick={apply} disabled={pending || items.length === 0}>
                  {pending ? 'Saving...' : 'Apply to ' + items.length + ' deal' + (items.length === 1 ? '' : 's')}
                </Button>
              )}
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
