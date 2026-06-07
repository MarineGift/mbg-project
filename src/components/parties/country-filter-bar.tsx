'use client';
import { Globe, X } from 'lucide-react';

interface Props {
  countries: string[];
  /** code -> display name, sourced from app.countries (no hardcoding). */
  countryNames?: Record<string, string>;
  current: string;
}

export function CountryFilterBar({ countries, countryNames = {}, current }: Props) {
  const sorted = [...countries].sort((a, b) =>
    (countryNames[a] ?? a).localeCompare(countryNames[b] ?? b)
  );

  function navigate(code: string) {
    if (typeof window === 'undefined') return;
    const url = new URL(window.location.href);
    if (code) { url.searchParams.set('country', code); }
    else { url.searchParams.delete('country'); }
    url.searchParams.delete('page');
    window.location.href = url.toString();
  }

  return (
    <div className="flex items-center gap-2 flex-wrap mt-1">
      <Globe className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
      <select
        defaultValue={current}
        onChange={(e) => navigate(e.target.value)}
        className="h-8 pl-2 pr-6 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring cursor-pointer min-w-[140px]"
      >
        <option value="">All countries</option>
        {sorted.map((cc) => (
          <option key={cc} value={cc}>
            {countryNames[cc] ?? cc}
          </option>
        ))}
      </select>
      {current && (
        <button
          onClick={() => navigate('')}
          className="inline-flex items-center gap-1 px-2 py-1 h-7 text-xs rounded-md bg-primary/10 text-primary hover:bg-primary/20 transition-colors"
        >
          <span className="font-medium">{countryNames[current] ?? current}</span>
          <X className="h-3 w-3" />
        </button>
      )}
    </div>
  );
}
