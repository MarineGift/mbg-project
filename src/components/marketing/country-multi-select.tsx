'use client';

// src/components/marketing/country-multi-select.tsx
// Multi-select of countries by NAME (stores ISO-2 codes). Names come from
// app.countries (fetchCountryNames) and fall back to Intl.DisplayNames, then
// to the raw code. Type to filter by name or code; click to toggle.

import { useEffect, useMemo, useRef, useState } from 'react';
import { X, ChevronDown, Check } from 'lucide-react';

type Props = {
  value: string[];
  onChange: (codes: string[]) => void;
  names: Record<string, string>;
  placeholder?: string;
};

let intlNames: Intl.DisplayNames | null = null;
function intlName(code: string): string | null {
  try {
    if (!intlNames) intlNames = new Intl.DisplayNames(['en'], { type: 'region' });
    const n = intlNames.of(code);
    return n && n !== code ? n : null;
  } catch {
    return null;
  }
}

export function countryLabel(code: string, names: Record<string, string>): string {
  return names[code] ?? intlName(code) ?? code;
}

export function CountryMultiSelect({ value, onChange, names, placeholder = 'All countries' }: Props) {
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const boxRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [open]);

  const options = useMemo(() => {
    const codes = new Set<string>([...Object.keys(names), ...value]);
    return Array.from(codes)
      .map((code) => ({ code, label: countryLabel(code, names) }))
      .sort((a, b) => a.label.localeCompare(b.label));
  }, [names, value]);

  const term = q.trim().toLowerCase();
  const shown = term
    ? options.filter((o) => o.label.toLowerCase().includes(term) || o.code.toLowerCase() === term)
    : options;

  const selected = new Set(value);
  const toggle = (code: string) => {
    const next = new Set(value);
    if (next.has(code)) next.delete(code); else next.add(code);
    onChange(Array.from(next));
  };

  return (
    <div ref={boxRef} className="relative">
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
          <button
            type="button"
            className="text-xs text-muted-foreground hover:text-foreground"
            onClick={(e) => { e.stopPropagation(); onChange([]); }}
          >
            Clear
          </button>
        )}
        <ChevronDown className="h-4 w-4 text-muted-foreground" />
      </div>
      {open && (
        <div className="absolute z-20 mt-1 max-h-64 w-full overflow-auto rounded-md border bg-background shadow-md">
          {shown.length === 0 && <div className="px-3 py-2 text-xs text-muted-foreground">No country matches.</div>}
          {shown.map((o) => {
            const on = selected.has(o.code);
            return (
              <button
                key={o.code}
                type="button"
                className={'flex w-full items-center justify-between px-3 py-1.5 text-left text-sm hover:bg-muted ' + (on ? 'font-medium' : '')}
                onClick={() => toggle(o.code)}
              >
                <span>{o.label} <span className="text-xs text-muted-foreground">{o.code}</span></span>
                {on && <Check className="h-4 w-4" />}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
