'use client';

/**
 * components/parties/country-market-panel-client.tsx
 *
 * Collapsible "Country market" card. Closed by default - the button opens the
 * country overview (headline, summary, key numbers, fillers, mills, strategy,
 * risks, next steps) and the country's mills and filler suppliers in URM.
 */

import { useState, type ReactNode } from 'react';
import Link from 'next/link';
import { Globe, ChevronDown, ChevronRight } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';

export interface CountryMarket {
  country_code: string;
  country_name: string;
  priority: 'high' | 'medium' | 'low' | 'on_hold' | 'none' | string;
  headline: string | null;
  summary: string | null;
  sections: {
    fillers?: string;
    mills?: string;
    strategy?: string;
    risks?: string;
    next_steps?: string[];
    key_numbers?: { label?: string; value?: string }[];
    files?: string[];
  } | null;
  checked_at: string | null;
  updated_at: string | null;
}

export interface MarketParty {
  id: string;
  name: string;
  city: string | null;
  module: string;
  priority: number | null;
}

interface Props {
  partyId: string;
  market: CountryMarket;
  mills: MarketParty[];
  fillers: MarketParty[];
}

const PRIORITY: Record<string, { label: string; cls: string }> = {
  high:    { label: 'High priority',   cls: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300' },
  medium:  { label: 'Medium priority', cls: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' },
  low:     { label: 'Low priority',    cls: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300' },
  on_hold: { label: 'On hold',         cls: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300' },
  none:    { label: 'No target',       cls: 'bg-muted text-muted-foreground' },
};

function Block({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="pt-3">
      <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">{title}</h3>
      <div className="text-sm leading-relaxed">{children}</div>
    </section>
  );
}

function PartyList({ items, currentId }: { items: MarketParty[]; currentId: string }) {
  if (items.length === 0) return <p className="text-sm text-muted-foreground">None in URM yet.</p>;
  return (
    <ul className="divide-y divide-border/40 rounded-md border border-border/60">
      {items.map((p) => (
        <li key={p.id}>
          <Link
            href={`/${p.module}/parties/${p.id}`}
            className={cn(
              'flex items-center gap-2 px-3 py-1.5 text-sm hover:bg-muted/60',
              p.id === currentId && 'bg-indigo-50 dark:bg-indigo-950/30 font-medium',
            )}
          >
            {typeof p.priority === 'number' ? (
              <span className="inline-flex min-w-[1.5rem] justify-center rounded-full bg-indigo-100 px-1.5 text-xs font-medium text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300">
                {p.priority}
              </span>
            ) : (
              <span className="inline-flex min-w-[1.5rem] justify-center text-xs text-muted-foreground">-</span>
            )}
            <span className="truncate">{p.name}</span>
            {p.city && <span className="ml-auto shrink-0 text-xs text-muted-foreground">{p.city}</span>}
          </Link>
        </li>
      ))}
    </ul>
  );
}

export function CountryMarketPanelClient({ partyId, market, mills, fillers }: Props) {
  const [open, setOpen] = useState(false);
  const s = market.sections ?? {};
  const pr = PRIORITY[market.priority] ?? PRIORITY.low;
  const numbers = (s.key_numbers ?? []).filter((n) => n.label && n.value);

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-base">
          <button
            type="button"
            onClick={() => setOpen((v) => !v)}
            aria-expanded={open}
            className="flex w-full items-center gap-2 text-left"
          >
            {open ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
            <Globe className="h-4 w-4 text-slate-600" />
            <span>Country market: {market.country_name}</span>
            <span className={cn('ml-2 inline-flex rounded-full px-2 py-0.5 text-xs font-medium', pr.cls)}>{pr.label}</span>
            <span className="ml-auto text-xs font-normal text-muted-foreground">
              {mills.length} mills · {fillers.length} fillers in URM
            </span>
          </button>
        </CardTitle>
        {market.headline && <p className="pl-12 text-sm text-muted-foreground">{market.headline}</p>}
      </CardHeader>

      {open && (
        <CardContent className="pt-0">
          {market.summary && <Block title="Summary">{market.summary}</Block>}

          {numbers.length > 0 && (
            <Block title="Key numbers">
              <dl className="grid grid-cols-1 gap-x-4 gap-y-1 sm:grid-cols-[200px_1fr]">
                {numbers.map((n, i) => (
                  <div key={i} className="contents">
                    <dt className="text-muted-foreground">{n.label}</dt>
                    <dd>{n.value}</dd>
                  </div>
                ))}
              </dl>
            </Block>
          )}

          {s.fillers && <Block title="Filler makers (PCC / GCC)">{s.fillers}</Block>}
          {s.mills && <Block title="Paper mills">{s.mills}</Block>}
          {s.strategy && <Block title="Approach">{s.strategy}</Block>}
          {s.risks && <Block title="Risks">{s.risks}</Block>}
          {(s.next_steps ?? []).length > 0 && (
            <Block title="Next steps">
              <ul className="list-disc pl-5">
                {(s.next_steps ?? []).map((t, i) => <li key={i}>{t}</li>)}
              </ul>
            </Block>
          )}

          <div className="grid gap-4 pt-4 md:grid-cols-2">
            <div>
              <h3 className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                Paper mills in URM ({mills.length})
              </h3>
              <PartyList items={mills} currentId={partyId} />
            </div>
            <div>
              <h3 className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                Filler suppliers in URM ({fillers.length})
              </h3>
              <PartyList items={fillers} currentId={partyId} />
            </div>
          </div>

          <p className="pt-3 text-xs text-muted-foreground">
            Checked {market.checked_at ?? '-'}
            {(s.files ?? []).length > 0 && <> · source files: {(s.files ?? []).join(', ')}</>}
          </p>
        </CardContent>
      )}
    </Card>
  );
}
