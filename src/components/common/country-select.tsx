'use client';

// src/components/common/country-select.tsx
// The ONE country control used across URM. Every option and label comes from
// the DB table app.countries (code -> name_en); nothing is hardcoded.
//   CountrySelect       single value ('' = none / all)
//   CountryMultiSelect  several values (ISO-2 codes)
// Pass `names` when a server parent already loaded them (fetchCountryNames);
// otherwise the hook loads them once per page through listCountryNames().
// `codes` limits the options (e.g. filters that list only countries in use).

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { X, ChevronDown, Check } from 'lucide-react';
import { listCountryNames } from '@/lib/actions/countries';

type Names = Record<string, string>;

let namesPromise: Promise<Names> | null = null;

/** app.countries names; `given` wins when a server parent passed them. */
export function useCountryNames(given?: Names): Names {
  const hasGiven = !!given && Object.keys(given).length > 0;
  const [loaded, setLoaded] = useState<Names>({});
  useEffect(() => {
    if (hasGiven) return;
    let alive = true;
    if (!namesPromise) namesPromise = listCountryNames().catch(() => ({}));
    void namesPromise.then((n) => { if (alive) setLoaded(n); });
    return () => { alive = false; };
  }, [hasGiven]);
  return hasGiven ? (given as Names) : loaded;
}

export function countryLabel(code: string, names: Names): string {
  return names[code] ?? code;
}

function useOptions(names: Names, codes: string[] | undefined, extra: string[]) {
  return useMemo(() => {
    const pool = new Set<string>(codes && codes.length > 0 ? codes : Object.keys(names));
    for (const c of extra) if (c) pool.add(c);
    return Array.from(pool)
      .map((code) => ({ code, label: countryLabel(code, names) }))
      .sort((a, b) => a.label.localeCompare(b.label));
  }, [names, codes, extra]);
}

function useOutsideClose(open: boolean, close: () => void) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) close();
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [open, close]);
  return ref;
}

function OptionList({
  options, isOn, onPick, emptyLabel, onEmpty,
}: {
  options: Array<{ code: string; label: string }>;
  isOn: (code: string) => boolean;
  onPick: (code: string) => void;
  emptyLabel?: string;
  onEmpty?: () => void;
}) {
  return (
    <div className="max-h-64 overflow-auto">
      {emptyLabel !== undefined && onEmpty && (
        <button type="button" className="flex w-full px-3 py-1.5 text-left text-sm text-muted-foreground hover:bg-muted" onClick={onEmpty}>
          {emptyLabel}
        </button>
      )}
      {options.length === 0 && <div className="px-3 py-2 text-xs text-muted-foreground">No country matches.</div>}
      {options.map((o) => {
        const on = isOn(o.code);
        return (
          <button
            key={o.code}
            type="button"
            className={'flex w-full items-center justify-between px-3 py-1.5 text-left text-sm hover:bg-muted ' + (on ? 'font-medium' : '')}
            onClick={() => onPick(o.code)}
          >
            <span>{o.label} <span className="text-xs text-muted-foreground">{o.code}</span></span>
            {on && <Check className="h-4 w-4" />}
          </button>
        );
      })}
    </div>
  );
}

const filterBy = (options: Array<{ code: string; label: string }>, q: string) => {
  const t = q.trim().toLowerCase();
  return t ? options.filter((o) => o.label.toLowerCase().includes(t) || o.code.toLowerCase() === t) : options;
};

// ---------------------------------------------------------------------------

type SingleProps = {
  value: string;
  onChange: (code: string) => void;
  names?: Names;
  codes?: string[];
  /** label of the empty choice; '' is passed to onChange when picked. */
  emptyLabel?: string;
  id?: string;
  disabled?: boolean;
  className?: string;
};

export function CountrySelect({
  value, onChange, names: given, codes, emptyLabel = '(none)', id, disabled, className,
}: SingleProps) {
  const names = useCountryNames(given);
  const extra = useMemo(() => (value ? [value] : []), [value]);
  const options = useOptions(names, codes, extra);
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const close = useCallback(() => setOpen(false), []);
  const ref = useOutsideClose(open, close);
  const shown = filterBy(options, q);
  const pick = (code: string) => { onChange(code); setOpen(false); setQ(''); };

  return (
    <div ref={ref} className={'relative ' + (className ?? '')}>
      <button
        id={id}
        type="button"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        className="flex h-9 w-full min-w-[140px] items-center justify-between gap-2 rounded-md border border-input bg-background px-3 text-left text-sm disabled:opacity-50"
      >
        <span className={value ? '' : 'text-muted-foreground'}>
          {value ? `${countryLabel(value, names)} (${value})` : emptyLabel}
        </span>
        <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
      </button>
      {open && (
        <div className="absolute z-30 mt-1 w-full min-w-[14rem] rounded-md border bg-background shadow-md">
          <input
            autoFocus
            className="w-full border-b bg-background px-3 py-1.5 text-sm outline-none"
            placeholder="Type to search..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => {
              const first = shown[0];
              if (e.key === 'Enter' && first) { e.preventDefault(); pick(first.code); }
              if (e.key === 'Escape') setOpen(false);
            }}
          />
          <OptionList options={shown} isOn={(c) => c === value} onPick={pick} emptyLabel={emptyLabel} onEmpty={() => pick('')} />
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------

type MultiProps = {
  value: string[];
  onChange: (codes: string[]) => void;
  names?: Names;
  codes?: string[];
  placeholder?: string;
};

export function CountryMultiSelect({ value, onChange, names: given, codes, placeholder = 'All countries' }: MultiProps) {
  const names = useCountryNames(given);
  const options = useOptions(names, codes, value);
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const close = useCallback(() => setOpen(false), []);
  const ref = useOutsideClose(open, close);
  const shown = filterBy(options, q);
  const selected = new Set(value);
  const toggle = (code: string) => {
    const next = new Set(value);
    if (next.has(code)) next.delete(code); else next.add(code);
    onChange(Array.from(next));
  };

  return (
    <div ref={ref} className="relative">
      <div
        className="flex min-h-[38px] w-full cursor-text flex-wrap items-center gap-1 rounded-md border bg-background px-2 py-1 text-sm"
        onClick={() => setOpen(true)}
      >
        {value.map((code) => (
          <span key={code} className="inline-flex items-center gap-1 rounded-full border bg-muted px-2 py-0.5 text-xs">
            {countryLabel(code, names)}
            <button
              type="button"
              aria-label={`Remove ${countryLabel(code, names)}`}
              className="text-muted-foreground hover:text-foreground"
              onClick={(e) => { e.stopPropagation(); toggle(code); }}
            >
              <X className="h-3 w-3" />
            </button>
          </span>
        ))}
        <input
          className="min-w-[8rem] flex-1 bg-transparent py-1 outline-none"
          value={q}
          placeholder={value.length === 0 ? placeholder : 'Add country...'}
          onFocus={() => setOpen(true)}
          onChange={(e) => { setQ(e.target.value); setOpen(true); }}
          onKeyDown={(e) => {
            const first = shown[0];
            const last = value[value.length - 1];
            if (e.key === 'Enter' && first) { e.preventDefault(); toggle(first.code); setQ(''); }
            if (e.key === 'Escape') setOpen(false);
            if (e.key === 'Backspace' && q === '' && last) toggle(last);
          }}
        />
        {value.length > 0 && (
          <button type="button" className="text-xs text-muted-foreground hover:text-foreground"
            onClick={(e) => { e.stopPropagation(); onChange([]); }}>
            Clear
          </button>
        )}
        <ChevronDown className="h-4 w-4 text-muted-foreground" />
      </div>
      {open && (
        <div className="absolute z-30 mt-1 w-full min-w-[14rem] rounded-md border bg-background shadow-md">
          <OptionList options={shown} isOn={(c) => selected.has(c)} onPick={toggle} />
        </div>
      )}
    </div>
  );
}
