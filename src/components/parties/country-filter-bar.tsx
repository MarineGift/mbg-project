'use client';
import { Globe, X } from 'lucide-react';
import { CountrySelect } from '@/components/common/country-select';

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
      <CountrySelect
        value={current}
        onChange={navigate}
        names={countryNames}
        codes={sorted}
        emptyLabel="All countries"
        className="min-w-[180px]"
      />
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
