'use client';

/**
 * MentorFilterPanel - multi-criteria search for the mentor directory.
 * Drives URL params only (server page filters in memory):
 *   ?mq=        keyword, every word must appear (name, title, company, bio,
 *               why-mentor, location, all tag lists)
 *   ?m_gender= ?m_exp= ?m_sec= ?m_prod= ?m_tech= ?m_stage= ?m_avail= ?m_eng= ?m_loc= ?m_tier=
 *               repeatable. OR inside one category, AND across categories.
 * Any change resets ?page.
 */

import { useEffect, useMemo, useRef, useState, useTransition } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { ChevronDown, Loader2, Search, SlidersHorizontal, X } from 'lucide-react';

export type MentorFacetOption = { value: string; count: number };
export type MentorFacet = { key: string; label: string; options: MentorFacetOption[] };

interface Props {
  facets: MentorFacet[];
  keyword: string;
  selected: Record<string, string[]>;
  resultCount: number;
}

export const MENTOR_FILTER_KEYS = [
  'm_gender', 'm_exp', 'm_sec', 'm_prod', 'm_tech', 'm_stage', 'm_avail', 'm_eng', 'm_loc', 'm_tier',
] as const;

function FacetDropdown({
  facet, values, onToggle, onClear,
}: {
  facet: MentorFacet;
  values: string[];
  onToggle: (v: string) => void;
  onClear: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [find, setFind] = useState('');
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const h = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false); };
    const k = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', h);
    document.addEventListener('keydown', k);
    return () => { document.removeEventListener('mousedown', h); document.removeEventListener('keydown', k); };
  }, [open]);

  const shown = useMemo(() => {
    const f = find.trim().toLowerCase();
    return f ? facet.options.filter((o) => o.value.toLowerCase().includes(f)) : facet.options;
  }, [facet.options, find]);

  const active = values.length > 0;
  return (
    <div className="relative" ref={ref}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={`inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-medium transition whitespace-nowrap ${
          active ? 'border-indigo-500 bg-indigo-50 text-indigo-700 dark:bg-indigo-950/40 dark:text-indigo-300'
                 : 'border-input bg-background hover:bg-muted text-foreground'
        }`}
      >
        {facet.label}
        {active && <span className="rounded-full bg-indigo-600 text-white px-1.5 text-[10px] tabular-nums">{values.length}</span>}
        <ChevronDown className="h-3.5 w-3.5 opacity-60" />
      </button>
      {open && (
        <div className="absolute z-30 mt-1 w-72 max-w-[90vw] rounded-md border bg-popover shadow-lg">
          {facet.options.length > 8 && (
            <div className="p-2 border-b">
              <input
                autoFocus
                value={find}
                onChange={(e) => setFind(e.target.value)}
                placeholder="Find option..."
                className="w-full rounded border border-input bg-background px-2 py-1 text-xs"
              />
            </div>
          )}
          <div className="max-h-72 overflow-y-auto py-1">
            {shown.length === 0 && <div className="px-3 py-2 text-xs text-muted-foreground">No options</div>}
            {shown.map((o) => {
              const on = values.includes(o.value);
              return (
                <label key={o.value} className="flex items-start gap-2 px-3 py-1.5 text-xs cursor-pointer hover:bg-muted">
                  <input type="checkbox" checked={on} onChange={() => onToggle(o.value)} className="mt-0.5 shrink-0" />
                  <span className="flex-1 leading-snug">{o.value}</span>
                  <span className="text-muted-foreground tabular-nums">{o.count}</span>
                </label>
              );
            })}
          </div>
          {active && (
            <div className="border-t p-1.5 flex justify-end">
              <button type="button" onClick={onClear} className="text-xs text-muted-foreground hover:text-foreground px-2 py-0.5">
                Clear {facet.label}
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export function MentorFilterPanel({ facets, keyword, selected, resultCount }: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const sp = useSearchParams();
  const [pending, startTransition] = useTransition();
  const [kw, setKw] = useState(keyword);

  useEffect(() => { setKw(keyword); }, [keyword]);

  const push = (mutate: (qs: URLSearchParams) => void) => {
    const qs = new URLSearchParams(sp.toString());
    mutate(qs);
    qs.delete('page');
    const s = qs.toString();
    startTransition(() => router.push(`${pathname}${s ? `?${s}` : ''}`, { scroll: false }));
  };

  const toggle = (key: string, value: string) =>
    push((qs) => {
      const cur = qs.getAll(key);
      qs.delete(key);
      const next = cur.includes(value) ? cur.filter((v) => v !== value) : [...cur, value];
      for (const v of next) qs.append(key, v);
    });

  const clearKey = (key: string) => push((qs) => qs.delete(key));

  const applyKeyword = () =>
    push((qs) => {
      const v = kw.trim();
      if (v) qs.set('mq', v); else qs.delete('mq');
    });

  const clearAll = () =>
    push((qs) => {
      qs.delete('mq');
      for (const k of MENTOR_FILTER_KEYS) qs.delete(k);
    });

  const labelOf = (key: string) => facets.find((f) => f.key === key)?.label ?? key;
  const activeChips = Object.entries(selected).flatMap(([k, vs]) => vs.map((v) => ({ k, v })));
  const anyActive = activeChips.length > 0 || keyword !== '';

  return (
    <div className="rounded-lg border bg-muted/20 p-3 space-y-2.5">
      <div className="flex items-center gap-2 flex-wrap">
        <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-muted-foreground mr-1">
          <SlidersHorizontal className="h-3.5 w-3.5" /> Mentor search
        </span>
        <div className="flex items-center gap-1">
          <div className="relative">
            <Search className="h-3.5 w-3.5 absolute left-2 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input
              value={kw}
              onChange={(e) => setKw(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') applyKeyword(); }}
              placeholder="Keyword in bio, company, expertise... (e.g. paper, materials)"
              className="w-80 max-w-[70vw] rounded-md border border-input bg-background pl-7 pr-2 py-1.5 text-xs"
            />
          </div>
          <button type="button" onClick={applyKeyword}
            className="rounded-md bg-foreground text-background px-2.5 py-1.5 text-xs font-medium">
            Go
          </button>
        </div>
        {pending && <Loader2 className="h-3.5 w-3.5 animate-spin text-muted-foreground" />}
        <span className="text-xs text-muted-foreground ml-auto tabular-nums">{resultCount} mentors match</span>
      </div>

      <div className="flex items-center gap-1.5 flex-wrap">
        {facets.map((f) => (
          <FacetDropdown
            key={f.key}
            facet={f}
            values={selected[f.key] ?? []}
            onToggle={(v) => toggle(f.key, v)}
            onClear={() => clearKey(f.key)}
          />
        ))}
        {anyActive && (
          <button type="button" onClick={clearAll}
            className="text-xs text-muted-foreground hover:text-foreground underline underline-offset-2 ml-1">
            Clear all
          </button>
        )}
      </div>

      {anyActive && (
        <div className="flex items-center gap-1.5 flex-wrap">
          {keyword && (
            <span className="inline-flex items-center gap-1 rounded-full bg-foreground/10 px-2 py-0.5 text-[11px]">
              Keyword: {keyword}
              <button type="button" onClick={() => push((qs) => qs.delete('mq'))} aria-label="Remove keyword">
                <X className="h-3 w-3" />
              </button>
            </span>
          )}
          {activeChips.map(({ k, v }) => (
            <span key={`${k}:${v}`} className="inline-flex items-center gap-1 rounded-full bg-indigo-100 text-indigo-800 dark:bg-indigo-900/40 dark:text-indigo-200 px-2 py-0.5 text-[11px] max-w-[360px]">
              <span className="opacity-70">{labelOf(k)}:</span>
              <span className="truncate">{v}</span>
              <button type="button" onClick={() => toggle(k, v)} aria-label="Remove filter">
                <X className="h-3 w-3" />
              </button>
            </span>
          ))}
          <span className="text-[11px] text-muted-foreground">OR within a category, AND across categories</span>
        </div>
      )}
    </div>
  );
}
