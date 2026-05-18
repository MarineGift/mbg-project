'use client';
import { Globe, X } from 'lucide-react';

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

interface Props {
  countries: string[];
  current: string;
}

export function CountryFilterBar({ countries, current }: Props) {
  const sorted = [...countries].sort((a, b) =>
    (COUNTRY_NAMES[a] ?? a).localeCompare(COUNTRY_NAMES[b] ?? b)
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
        <option value="">전체 국가</option>
        {sorted.map((cc) => (
          <option key={cc} value={cc}>
            {cc} — {COUNTRY_NAMES[cc] ?? cc}
          </option>
        ))}
      </select>
      {current && (
        <button
          onClick={() => navigate('')}
          className="inline-flex items-center gap-1 px-2 py-1 h-7 text-xs rounded-md bg-primary/10 text-primary hover:bg-primary/20 transition-colors"
        >
          <span className="font-medium">{COUNTRY_NAMES[current] ?? current}</span>
          <X className="h-3 w-3" />
        </button>
      )}
    </div>
  );
}
