/**
 * components/parties/plant-profile-card.tsx
 *
 * Plant detail card for paper_mill and filler_supplier parties.
 * Reads the 1:1 profile row (app.paper_mill_profile / app.filler_supplier_profile)
 * and its extra_data.plant block:
 *   owner, products, grades[], machines, capacity{value,unit,year,source},
 *   capacity_split[{label,value_t}], filler[{supplier,type,status,basis}],
 *   fcc{royalty_usd_per_t, scenarios[{label,utilization,fcc_share,fcc_loading}], note},
 *   priority, pitch, approach, recent[{date,text,url}], to_collect[], sources[{label,url}],
 *   checked_at
 * Every block is optional - the card shows only what is filled.
 * FCC volume = capacity (metric t) x utilization x fcc_share x fcc_loading,
 * royalty = volume x royalty_usd_per_t. Scenario figures, not orders.
 */

import type { ReactNode } from 'react';
import { Factory, ExternalLink } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { createSupabaseServerClient } from '@/lib/supabase/server';

interface Props {
  partyId: string;
  partyType: 'paper_mill' | 'filler_supplier';
}

type Json = Record<string, unknown>;

interface Scenario { label?: string; utilization?: number; fcc_share?: number; fcc_loading?: number }
interface PlantBlock {
  owner?: string;
  products?: string;
  grades?: string[];
  machines?: number;
  capacity?: { value?: number; unit?: string; year?: string; source?: string };
  capacity_split?: { label?: string; value_t?: number }[];
  filler?: { supplier?: string; type?: string; status?: string; basis?: string }[];
  fcc?: { royalty_usd_per_t?: number; scenarios?: Scenario[]; note?: string };
  priority?: number;
  pitch?: string;
  approach?: string;
  recent?: { date?: string; text?: string; url?: string }[];
  to_collect?: string[];
  sources?: { label?: string; url?: string }[];
  checked_at?: string;
}

const SHORT_TO_METRIC = 0.90718474;
const nf = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
const usd = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
const pct = (v?: number) => (typeof v === 'number' ? `${Math.round(v * 100)}%` : '-');

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-[170px_1fr] gap-1 sm:gap-3 py-2 border-b border-border/40 last:border-0">
      <div className="text-xs font-medium text-muted-foreground pt-0.5">{label}</div>
      <div className="text-sm break-words min-w-0 leading-relaxed">{children}</div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="pt-4">
      <h3 className="text-sm font-semibold mb-2">{title}</h3>
      {children}
    </section>
  );
}

function capacityMetric(c?: PlantBlock['capacity']): number | null {
  if (!c || typeof c.value !== 'number') return null;
  const unit = (c.unit ?? '').toLowerCase();
  return unit.startsWith('short') ? c.value * SHORT_TO_METRIC : c.value;
}

function unitLabel(unit?: string) {
  const u = (unit ?? '').toLowerCase();
  if (u.startsWith('short')) return 'short tons/yr';
  if (u.startsWith('metric')) return 'metric t/yr';
  return unit ?? '';
}

export async function PlantProfileCard({ partyId, partyType }: Props) {
  const supabase = await createSupabaseServerClient();
  const table = partyType === 'paper_mill' ? 'paper_mill_profile' : 'filler_supplier_profile';
  const cols =
    partyType === 'paper_mill'
      ? 'main_product_category, main_products, headquarters, filler_use_intensity, evidence_level, extra_data'
      : 'supplier_type, market_role, supply_model, evidence_level, mineral_class, onsite_pcc_evidence, extra_data';

  const { data } = await supabase
    .schema('app')
    .from(table as never)
    .select(cols)
    .eq('party_id' as never, partyId)
    .is('deleted_at' as never, null)
    .maybeSingle();

  const prof = data as unknown as (Json & { extra_data?: Json }) | null;
  if (!prof) return null;

  const plant = ((prof.extra_data ?? {}) as Json).plant as PlantBlock | undefined;
  const str = (k: string) => (typeof prof[k] === 'string' && (prof[k] as string).trim() ? (prof[k] as string) : null);

  const baseRows: [string, string | null][] =
    partyType === 'paper_mill'
      ? [
          ['Category', str('main_product_category')],
          ['Products', str('main_products')],
          ['Headquarters', str('headquarters')],
          ['Filler use', str('filler_use_intensity')],
          ['Evidence level', str('evidence_level')],
        ]
      : [
          ['Supplier type', str('supplier_type')],
          ['Market role', str('market_role')],
          ['Supply model', str('supply_model')],
          ['Mineral', str('mineral_class')],
          ['On-site evidence', str('onsite_pcc_evidence')],
          ['Evidence level', str('evidence_level')],
        ];
  const shownBase = baseRows.filter(([, v]) => v);

  if (shownBase.length === 0 && !plant) return null;

  const capT = capacityMetric(plant?.capacity);
  const royalty = plant?.fcc?.royalty_usd_per_t ?? 15;
  const scenarios = (plant?.fcc?.scenarios ?? []).filter(
    (s) => typeof s.utilization === 'number' && typeof s.fcc_share === 'number' && typeof s.fcc_loading === 'number',
  );

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="flex items-center gap-2 text-base">
          <Factory className="h-4 w-4 text-slate-600" />
          {partyType === 'paper_mill' ? 'Mill profile' : 'Plant profile'}
          {typeof plant?.priority === 'number' && (
            <span className="ml-2 inline-flex px-2 py-0.5 text-xs font-medium rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300">
              Outreach priority {plant.priority}
            </span>
          )}
        </CardTitle>
        {plant?.checked_at && (
          <p className="text-xs text-muted-foreground">Checked {plant.checked_at}</p>
        )}
      </CardHeader>
      <CardContent className="pt-0">
        <dl>
          {plant?.owner && <Row label="Owner">{plant.owner}</Row>}
          {shownBase.map(([k, v]) => (
            <Row key={k} label={k}>{v}</Row>
          ))}
          {plant?.grades && plant.grades.length > 0 && (
            <Row label="Grades">
              <div className="flex flex-wrap gap-1.5">
                {plant.grades.map((g) => (
                  <span key={g} className="inline-flex px-2 py-0.5 text-xs rounded-full bg-muted">{g}</span>
                ))}
              </div>
            </Row>
          )}
          {typeof plant?.machines === 'number' && <Row label="Paper machines">{plant.machines}</Row>}
          {plant?.capacity && typeof plant.capacity.value === 'number' && (
            <Row label="Capacity">
              <span className="font-medium">{nf.format(plant.capacity.value)}</span> {unitLabel(plant.capacity.unit)}
              {capT !== null && (plant.capacity.unit ?? '').toLowerCase().startsWith('short') && (
                <span className="text-muted-foreground"> (about {nf.format(capT)} metric t)</span>
              )}
              {(plant.capacity.year || plant.capacity.source) && (
                <div className="text-xs text-muted-foreground">
                  {[plant.capacity.year, plant.capacity.source].filter(Boolean).join(', ')}
                </div>
              )}
            </Row>
          )}
          {plant?.capacity_split && plant.capacity_split.length > 0 && (
            <Row label="Capacity split">
              {plant.capacity_split.map((s) => (
                <div key={s.label}>
                  {s.label}: {typeof s.value_t === 'number' ? `${nf.format(s.value_t)} t` : '-'}
                </div>
              ))}
            </Row>
          )}
        </dl>

        {plant?.filler && plant.filler.length > 0 && (
          <Section title="Current filler supply">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-xs text-muted-foreground border-b">
                    <th className="py-1.5 pr-3 font-medium">Supplier</th>
                    <th className="py-1.5 pr-3 font-medium">Type</th>
                    <th className="py-1.5 pr-3 font-medium">Status</th>
                    <th className="py-1.5 font-medium">Basis</th>
                  </tr>
                </thead>
                <tbody>
                  {plant.filler.map((f, i) => (
                    <tr key={i} className="border-b border-border/40 last:border-0 align-top">
                      <td className="py-1.5 pr-3 font-medium">{f.supplier ?? '-'}</td>
                      <td className="py-1.5 pr-3">{f.type ?? '-'}</td>
                      <td className="py-1.5 pr-3">{f.status ?? '-'}</td>
                      <td className="py-1.5 text-muted-foreground">{f.basis ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Section>
        )}

        {capT !== null && scenarios.length > 0 && (
          <Section title={`FCC volume and royalty scenarios (${usd.format(royalty)}/t)`}>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-xs text-muted-foreground border-b">
                    <th className="py-1.5 pr-3 font-medium">Scenario</th>
                    <th className="py-1.5 pr-3 font-medium text-right">Utilization</th>
                    <th className="py-1.5 pr-3 font-medium text-right">Grades on FCC</th>
                    <th className="py-1.5 pr-3 font-medium text-right">FCC in sheet</th>
                    <th className="py-1.5 pr-3 font-medium text-right">FCC t/yr</th>
                    <th className="py-1.5 font-medium text-right">Royalty/yr</th>
                  </tr>
                </thead>
                <tbody>
                  {scenarios.map((s) => {
                    const t = capT * (s.utilization as number) * (s.fcc_share as number) * (s.fcc_loading as number);
                    return (
                      <tr key={s.label} className="border-b border-border/40 last:border-0">
                        <td className="py-1.5 pr-3">{s.label}</td>
                        <td className="py-1.5 pr-3 text-right">{pct(s.utilization)}</td>
                        <td className="py-1.5 pr-3 text-right">{pct(s.fcc_share)}</td>
                        <td className="py-1.5 pr-3 text-right">{pct(s.fcc_loading)}</td>
                        <td className="py-1.5 pr-3 text-right font-medium">{nf.format(t)}</td>
                        <td className="py-1.5 text-right font-medium">{usd.format(t * royalty)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <p className="text-xs text-muted-foreground mt-2">
              {plant?.fcc?.note ??
                'Planning scenarios on nameplate capacity, not orders. FCC in sheet is not the same as pulp replaced.'}
            </p>
          </Section>
        )}

        {(plant?.pitch || plant?.approach) && (
          <Section title="Approach">
            <dl>
              {plant?.pitch && <Row label="What to offer">{plant.pitch}</Row>}
              {plant?.approach && <Row label="How to approach">{plant.approach}</Row>}
            </dl>
          </Section>
        )}

        {plant?.recent && plant.recent.length > 0 && (
          <Section title="Recent events">
            <ul className="space-y-1.5 text-sm">
              {plant.recent.map((r, i) => (
                <li key={i}>
                  {r.date && <span className="text-muted-foreground mr-2">{r.date}</span>}
                  {r.text}
                  {r.url && (
                    <a href={r.url} target="_blank" rel="noopener noreferrer" className="ml-1 inline-flex align-middle text-primary">
                      <ExternalLink className="h-3.5 w-3.5" />
                    </a>
                  )}
                </li>
              ))}
            </ul>
          </Section>
        )}

        {plant?.to_collect && plant.to_collect.length > 0 && (
          <Section title="Ask in the first meeting">
            <ul className="list-disc pl-5 space-y-1 text-sm">
              {plant.to_collect.map((q) => (
                <li key={q}>{q}</li>
              ))}
            </ul>
          </Section>
        )}

        {plant?.sources && plant.sources.length > 0 && (
          <Section title="Sources">
            <ul className="space-y-1 text-xs">
              {plant.sources.map((s, i) => (
                <li key={i}>
                  {s.url ? (
                    <a href={s.url} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">
                      {s.label ?? s.url}
                    </a>
                  ) : (
                    s.label
                  )}
                </li>
              ))}
            </ul>
          </Section>
        )}
      </CardContent>
    </Card>
  );
}
