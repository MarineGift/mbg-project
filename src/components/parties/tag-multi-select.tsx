'use client';

/**
 * components/parties/tag-multi-select.tsx
 *
 * Multi-select tag input with suggestions from the normalized tag catalogue.
 *  - shows existing tags as filterable suggestions (code + label)
 *  - Enter or click adds a tag chip; Backspace removes the last chip
 *  - unknown queries get an explicit `Add "<slug>"` action (free vocabulary,
 *    normalized later by the interest-tags alias/merge pipeline)
 *  - emits the same comma-separated string the form previously stored, so
 *    server actions / zod schema stay untouched.
 */

import { useMemo, useRef, useState } from 'react';
import { X, Plus, Check } from 'lucide-react';

export interface TagOption {
  code: string;
  label: string;
}

interface Props {
  inputId?: string;
  /** comma-separated tag codes (react-hook-form field value) */
  value: string;
  onChange: (next: string) => void;
  suggestions?: TagOption[];
  placeholder?: string;
  disabled?: boolean;
}

function slugify(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

export function TagMultiSelect({
  inputId,
  value,
  onChange,
  suggestions = [],
  placeholder,
  disabled,
}: Props) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const boxRef = useRef<HTMLDivElement>(null);

  const selected = useMemo(
    () => value.split(',').map((s) => s.trim()).filter(Boolean),
    [value],
  );
  const selectedSet = useMemo(
    () => new Set(selected.map((s) => s.toLowerCase())),
    [selected],
  );

  const q = query.trim().toLowerCase();
  // checkbox mode: selected tags STAY in the list (checked) so multiple
  // selections toggle in place.
  const matches = useMemo(() => {
    if (!q) return suggestions.slice(0, 12);
    return suggestions
      .filter(
        (s) =>
          s.code.toLowerCase().includes(q) || s.label.toLowerCase().includes(q),
      )
      .slice(0, 12);
  }, [suggestions, q]);

  const slug = slugify(q);
  const exactExists =
    q !== '' &&
    (selectedSet.has(slug) ||
      suggestions.some((s) => s.code.toLowerCase() === slug));

  const add = (code: string) => {
    const c = code.trim();
    if (!c || selectedSet.has(c.toLowerCase())) return;
    onChange([...selected, c].join(', '));
    setQuery('');
  };
  const remove = (code: string) => {
    onChange(selected.filter((s) => s !== code).join(', '));
  };
  const toggle = (code: string) => {
    const found = selected.find((s) => s.toLowerCase() === code.toLowerCase());
    if (found) remove(found);
    else add(code);
  };

  return (
    <div ref={boxRef} className="relative">
      <div
        className={`flex min-h-9 w-full flex-wrap items-center gap-1 rounded-md border bg-background px-2 py-1 text-sm ${disabled ? 'opacity-50' : ''}`}
      >
        {selected.map((tag) => (
          <span
            key={tag}
            className="inline-flex items-center gap-1 rounded bg-muted px-1.5 py-0.5 text-xs"
          >
            {tag}
            {!disabled && (
              <button
                type="button"
                className="text-muted-foreground hover:text-foreground"
                onClick={() => remove(tag)}
                aria-label={'remove ' + tag}
              >
                <X className="h-3 w-3" />
              </button>
            )}
          </span>
        ))}
        <input
          id={inputId}
          className="min-w-[120px] flex-1 bg-transparent py-0.5 outline-none placeholder:text-muted-foreground"
          value={query}
          placeholder={selected.length === 0 ? placeholder : undefined}
          disabled={disabled}
          autoComplete="off"
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => window.setTimeout(() => setOpen(false), 150)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              if (q !== '' && matches.length > 0) add(matches[0]!.code);
              else if (q !== '' && slug) add(slug);
            } else if (e.key === 'Backspace' && q === '' && selected.length > 0) {
              remove(selected[selected.length - 1]!);
            }
          }}
        />
      </div>
      {open && !disabled && (q !== '' || matches.length > 0) && (
        <div className="absolute z-30 mt-1 max-h-64 w-full overflow-y-auto rounded-md border bg-popover p-1 shadow-md">
          {matches.map((s) => {
            const checked = selectedSet.has(s.code.toLowerCase());
            return (
              <button
                key={s.code}
                type="button"
                className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-muted"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => toggle(s.code)}
              >
                <span
                  className={`flex h-4 w-4 shrink-0 items-center justify-center rounded border ${checked ? 'border-primary bg-primary text-primary-foreground' : 'border-input'}`}
                >
                  {checked && <Check className="h-3 w-3" />}
                </span>
                <span className="flex-1 truncate">{s.code}</span>
                {s.label !== s.code && (
                  <span className="ml-2 truncate text-xs text-muted-foreground">
                    {s.label}
                  </span>
                )}
              </button>
            );
          })}
          {q !== '' && slug !== '' && !exactExists && (
            <button
              type="button"
              className="mt-0.5 flex w-full items-center gap-1 rounded px-2 py-1.5 text-left text-sm text-primary hover:bg-muted"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => add(slug)}
            >
              <Plus className="h-3.5 w-3.5" />
              {'Add "' + slug + '"'}
            </button>
          )}
          {matches.length === 0 && q === '' && (
            <div className="px-2 py-1.5 text-xs text-muted-foreground">
              Type to search tags
            </div>
          )}
        </div>
      )}
    </div>
  );
}
