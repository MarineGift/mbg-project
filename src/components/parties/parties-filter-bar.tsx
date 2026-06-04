'use client';

// Common filter/search bar for every parties list (investor / paper_mill /
// filler_supplier / partner / ...). All controls drive URL params, so the
// server component re-queries:
//   ?country=  exact country_code filter
//   ?q=        party_name ilike search (used when no country is chosen, or
//              combined with a country)
//   ?sort=     name_asc (default) | name_desc | score
//   ?type=     investor_category filter (investor list only; see `types`)
// Resetting any of these always clears ?page so results start at page 1.

import { useState } from 'react';
import { Globe, Search, X } from 'lucide-react';

const COUNTRY_NAMES: Record<string, string> = {
  AR:'Argentina', AT:'Austria', AU:'Australia', BD:'Bangladesh',
  BE:'Belgium',   BR:'Brazil',  CA:'Canada',   CH:'Switzerland',
  CL:'Chile',     CN:'China',   CO:'Colombia', DE:'Germany',
  DZ:'Algeria',   EG:'Egypt',   ES:'Spain',    FI:'Finland',
  FR:'France',    GB:'UK',      ID:'Indonesia', IN:'India',
  IR:'Iran',      IT:'Italy',   JP:'Japan',    KR:'Korea',
  LK:'Sri Lanka', MA:'Morocco', MX:'Mexico',   MY:'Malaysia',
  NG:'Nigeria',   NO:'Norway',  PH:'Philippines', PK:'Pakistan',
  PL:'Poland',    PT:'Portugal', RU:'Russia',  SA:'Saudi Arabia',
  SE:'Sweden',    SK:'Slovakia', TH:'Thailand', TN:'Tunisia',
  TR:'Turkey',    US:'USA',     UY:'Uruguay',  VN:'Vietnam',
  ZA:'South Africa',
};

const SORT_OPTIONS: { value: string; label: string }[] = [
  { value: 'name_asc',  label: 'Name (A \u2192 Z)' },
  { value: 'name_desc', label: 'Name (Z \u2192 A)' },
  { value: 'score',     label: 'Score (high \u2192 low)' },
];

/** Investor type facet (category + count) for the type-filter chips. */
export type InvestorFacet = { category: string; count: number };

interface Props {
  countries: string[];
  /** Current ?country= value (uppercase code or ''). */
  country: string;
  /** Current ?q= value. */
  q: string;
  /** Current ?sort= value (name_asc | name_desc | score). */
  sort: string;
  /** Investor type facets. When provided (investor list), render type chips. */
  types?: InvestorFacet[];
  /** Current ?type= value (investor_category, or ''). */
  type?: string;
}

export function PartiesFilterBar({ countries, country, q, sort, types, type = '' }: Props) {
  const [term, setTerm] = useState(q);

  const sortedCountries = [...countries].sort((a, b) =>
    (COUNTRY_NAMES[a] ?? a).localeCompare(COUNTRY_NAMES[b] ?? b)
  );

  function applyParams(mutate: (sp: URLSearchParams) => void) {
    if (typeof window === 'undefined') return;
    const url = new URL(window.location.href);
    mutate(url.searchParams);
    url.searchParams.delete('page'); // any filter/sort change resets paging
    window.location.href = url.toString();
  }

  function runSearch() {
    applyParams((sp) => {
      const t = term.trim();
      if (t) sp.set('q', t);
      else sp.delete('q');
    });
  }

  function setCountry(code: string) {
    applyParams((sp) => {
      if (code) sp.set('country', code);
      else sp.delete('country');
    });
  }

  function setSort(value: string) {
    applyParams((sp) => {
      if (value && value !== 'name_asc') sp.set('sort', value);
      else sp.delete('sort');
    });
  }

  function setType(value: string) {
    applyParams((sp) => {
      if (value) sp.set('type', value);
      else sp.delete('type');
    });
  }

  function clearSearch() {
    setTerm('');
    applyParams((sp) => sp.delete('q'));
  }

  const totalTypes = (types ?? []).reduce((s, t) => s + t.count, 0);

  return (
    <div className="space-y-2">
      <div className="mt-1 flex flex-wrap items-center gap-2">
        {/* Country */}
        <div className="flex items-center gap-1.5">
          <Globe className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
          <select
            value={country}
            onChange={(e) => setCountry(e.target.value)}
            className="h-9 min-w-[140px] cursor-pointer rounded-md border border-input bg-background pl-2 pr-6 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value="">All countries</option>
            {sortedCountries.map((cc) => (
              <option key={cc} value={cc}>
                {cc} &mdash; {COUNTRY_NAMES[cc] ?? cc}
              </option>
            ))}
          </select>
        </div>

        {/* Search box + button */}
        <div className="flex items-center gap-1.5">
          <div className="relative">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              value={term}
              onChange={(e) => setTerm(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') runSearch(); }}
              placeholder="Search by name..."
              className="h-9 w-56 rounded-md border border-input bg-background pl-8 pr-7 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
            />
            {term && (
              <button
                type="button"
                onClick={clearSearch}
                aria-label="Clear search"
                className="absolute right-1.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>
          <button
            type="button"
            onClick={runSearch}
            className="inline-flex h-9 items-center gap-1.5 rounded-md bg-foreground px-3 text-sm font-medium text-background hover:bg-foreground/90"
          >
            <Search className="h-3.5 w-3.5" />
            Search
          </button>
        </div>

        {/* Sort */}
        <div className="flex items-center gap-1.5">
          <span className="text-xs text-muted-foreground">Sort</span>
          <select
            value={SORT_OPTIONS.some((o) => o.value === sort) ? sort : 'name_asc'}
            onChange={(e) => setSort(e.target.value)}
            className="h-9 cursor-pointer rounded-md border border-input bg-background pl-2 pr-6 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
          >
            {SORT_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>

        {/* Active country pill (quick clear) */}
        {country && (
          <button
            type="button"
            onClick={() => setCountry('')}
            className="inline-flex h-7 items-center gap-1 rounded-md bg-primary/10 px-2 py-1 text-xs text-primary transition-colors hover:bg-primary/20"
          >
            <span className="font-medium">{COUNTRY_NAMES[country] ?? country}</span>
            <X className="h-3 w-3" />
          </button>
        )}
      </div>

      {/* Investor type chips (only on the investor list, when facets passed) */}
      {types && types.length > 0 && (
        <div className="flex flex-wrap items-center gap-1.5">
          <button
            type="button"
            onClick={() => setType('')}
            aria-pressed={!type}
            className={[
              'inline-flex h-7 items-center gap-1 rounded-full border px-2.5 text-xs transition-colors',
              !type
                ? 'border-foreground bg-foreground text-background'
                : 'border-input bg-background text-muted-foreground hover:bg-muted',
            ].join(' ')}
          >
            All <span className="opacity-60">{totalTypes}</span>
          </button>
          {types.map((t) => {
            const active = type === t.category;
            return (
              <button
                key={t.category}
                type="button"
                onClick={() => setType(t.category)}
                aria-pressed={active}
                className={[
                  'inline-flex h-7 items-center gap-1 rounded-full border px-2.5 text-xs transition-colors',
                  active
                    ? 'border-foreground bg-foreground text-background'
                    : 'border-input bg-background text-muted-foreground hover:bg-muted',
                ].join(' ')}
              >
                {t.category} <span className="opacity-60">{t.count}</span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
