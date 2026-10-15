/**
 * components/parties/country-market-tab.tsx
 *
 * "Market" tab for paper_mill and filler_supplier parties (Korean UI).
 * Shows the party's country market from app.country_markets (Korean columns
 * headline_ko / summary_ko / sections_ko / fcc_potential_*), linked to the URM
 * databases by app.parties.country_code:
 *   - live counts of the country's paper mills and filler suppliers
 *   - mill table with outreach priority, products, capacity and the Base FCC
 *     scenario computed from each mill's extra_data.plant block
 *   - filler supplier table
 * Scenario figures are planning numbers, not orders.
 */

import type { ReactNode } from 'react';
import Link from 'next/link';
import { Globe } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { createSupabaseServerClient } from '@/lib/supabase/server';

interface Props {
  partyId: string;
  country: string | null;
}

type Json = Record<string, unknown>;

interface Sections {
  fillers?: string;
  mills?: string;
  strategy?: string;
  risks?: string;
  next_steps?: string[];
  key_numbers?: { label?: string; value?: string }[];
  files?: string[];
}

interface MarketRow {
  country_code: string;
  country_name: string;
  priority: string;
  headline: string | null;
  summary: string | null;
  sections: Sections | null;
  headline_ko: string | null;
  summary_ko: string | null;
  sections_ko: Sections | null;
  fcc_potential_low_t: number | string | null;
  fcc_potential_high_t: number | string | null;
  fcc_potential_basis_ko: string | null;
  checked_at: string | null;
}

interface Scenario { label?: string; utilization?: number; fcc_share?: number; fcc_loading?: number }

const ROYALTY = 15;
const SHORT_TO_METRIC = 0.90718474;
const nf = new Intl.NumberFormat('ko-KR', { maximumFractionDigits: 0 });
const usd = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

const PRIORITY: Record<string, { label: string; cls: string }> = {
  high:    { label: '우선순위 높음', cls: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300' },
  medium:  { label: '우선순위 중간', cls: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' },
  low:     { label: '우선순위 낮음', cls: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300' },
  on_hold: { label: '보류 (제재)',   cls: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300' },
  none:    { label: '대상 없음',     cls: 'bg-muted text-muted-foreground' },
};

const toNum = (v: unknown): number | null => {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string' && v.trim() !== '' && Number.isFinite(Number(v))) return Number(v);
  return null;
};

function capacityOf(plant: Json | undefined): number | null {
  if (!plant) return null;
  const cap = plant.capacity as { value?: unknown; unit?: string } | undefined;
  const v = toNum(cap?.value);
  if (v !== null) return (cap?.unit ?? '').toLowerCase().startsWith('short') ? v * SHORT_TO_METRIC : v;
  const split = plant.capacity_split as { value_t?: unknown }[] | undefined;
  const first = split?.map((s) => toNum(s.value_t)).find((x) => x !== null);
  return first ?? null;
}

function baseScenarioT(plant: Json | undefined): number | null {
  if (!plant) return null;
  const cap = plant.capacity as { value?: unknown; unit?: string } | undefined;
  const v = toNum(cap?.value);
  if (v === null) return null;
  const capT = (cap?.unit ?? '').toLowerCase().startsWith('short') ? v * SHORT_TO_METRIC : v;
  const sc = ((plant.fcc as { scenarios?: Scenario[] } | undefined)?.scenarios ?? []).filter(
    (s) => typeof s.utilization === 'number' && typeof s.fcc_share === 'number' && typeof s.fcc_loading === 'number',
  );
  if (sc.length === 0) return null;
  const base = sc.find((s) => (s.label ?? '').toLowerCase() === 'base') ?? sc[Math.floor(sc.length / 2)];
  return capT * (base.utilization as number) * (base.fcc_share as number) * (base.fcc_loading as number);
}

function Block({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="pt-4">
      <h3 className="mb-1 text-sm font-semibold">{title}</h3>
      <div className="text-sm leading-relaxed">{children}</div>
    </section>
  );
}

function MetricRow({ label, value, note }: { label: string; value: ReactNode; note?: ReactNode }) {
  return (
    <tr className="border-b border-border/40 last:border-0 align-top">
      <td className="py-2 pr-4 text-muted-foreground whitespace-nowrap">{label}</td>
      <td className="py-2 pr-4 font-medium">{value}</td>
      <td className="py-2 text-xs text-muted-foreground">{note}</td>
    </tr>
  );
}

export async function CountryMarketTab({ partyId, country }: Props) {
  if (!country) {
    return <p className="text-sm text-muted-foreground">국가 정보가 없어 시장현황을 표시할 수 없습니다.</p>;
  }
  const code = country.trim().toUpperCase();
  const supabase = await createSupabaseServerClient();

  const [marketRes, typesRes] = await Promise.all([
    supabase
      .schema('app')
      .from('country_markets' as never)
      .select(
        'country_code, country_name, priority, headline, summary, sections, headline_ko, summary_ko, sections_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at',
      )
      .eq('country_code' as never, code)
      .is('deleted_at' as never, null)
      .maybeSingle(),
    supabase
      .schema('app')
      .from('party_types' as never)
      .select('id, code')
      .in('code' as never, ['paper_mill', 'filler_supplier'] as never),
  ]);

  if (marketRes.error) {
    return (
      <div className="rounded-md border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-800 dark:bg-amber-950/30 dark:text-amber-300">
        {code} 시장현황을 불러오지 못했습니다: {marketRes.error.message}
      </div>
    );
  }
  const m = marketRes.data as unknown as MarketRow | null;
  if (!m) {
    return <p className="text-sm text-muted-foreground">{code} 국가의 시장현황이 아직 등록되지 않았습니다.</p>;
  }

  // ---- linked mills and fillers (same country_code) ----
  const types = ((typesRes.data ?? []) as unknown as { id: string | number; code: string }[]);
  const codeById = new Map(types.map((t) => [String(t.id), t.code]));

  type PartyRow = { id: string; party_name: string; party_type_id: string | number; city: string | null; region: string | null };
  let rows: PartyRow[] = [];
  if (types.length > 0) {
    const { data } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, party_name, party_type_id, city, region')
      .eq('country_code' as never, code)
      .in('party_type_id' as never, types.map((t) => t.id) as never)
      .is('deleted_at' as never, null)
      .order('party_name' as never)
      .limit(500);
    rows = ((data ?? []) as unknown as PartyRow[]);
  }
  const millRows = rows.filter((r) => codeById.get(String(r.party_type_id)) === 'paper_mill');
  const fillerRows = rows.filter((r) => codeById.get(String(r.party_type_id)) === 'filler_supplier');

  const [millProf, fillerProf] = await Promise.all([
    millRows.length
      ? supabase.schema('app').from('paper_mill_profile' as never)
          .select('party_id, main_products, extra_data')
          .in('party_id' as never, millRows.map((r) => r.id) as never)
      : Promise.resolve({ data: [] }),
    fillerRows.length
      ? supabase.schema('app').from('filler_supplier_profile' as never)
          .select('party_id, supplier_type, mineral_class, market_role, extra_data')
          .in('party_id' as never, fillerRows.map((r) => r.id) as never)
      : Promise.resolve({ data: [] }),
  ]);

  const mp = new Map(((millProf.data ?? []) as unknown as { party_id: string; main_products: string | null; extra_data: Json | null }[])
    .map((p) => [p.party_id, p]));
  const fp = new Map(((fillerProf.data ?? []) as unknown as { party_id: string; supplier_type: string | null; mineral_class: string | null; market_role: string | null; extra_data: Json | null }[])
    .map((p) => [p.party_id, p]));

  const mills = millRows.map((r) => {
    const prof = mp.get(r.id);
    const plant = (prof?.extra_data ?? {}).plant as Json | undefined;
    const fcc = baseScenarioT(plant);
    return {
      ...r,
      priority: toNum(plant?.priority),
      products: (plant?.products as string | undefined) ?? prof?.main_products ?? null,
      capacity: capacityOf(plant),
      fcc,
    };
  }).sort((a, b) => (a.priority ?? 999) - (b.priority ?? 999) || a.party_name.localeCompare(b.party_name));

  const fillers = fillerRows.map((r) => ({ ...r, prof: fp.get(r.id) ?? null }));

  const prioritized = mills.filter((x) => x.priority !== null).length;
  const withCap = mills.filter((x) => x.capacity !== null);
  const capSum = withCap.reduce((s, x) => s + (x.capacity ?? 0), 0);
  const withFcc = mills.filter((x) => x.fcc !== null);
  const fccSum = withFcc.reduce((s, x) => s + (x.fcc ?? 0), 0);
  const lo = toNum(m.fcc_potential_low_t);
  const hi = toNum(m.fcc_potential_high_t);

  const sec: Sections = (m.sections_ko && Object.keys(m.sections_ko).length > 0 ? m.sections_ko : m.sections) ?? {};
  const files = m.sections?.files ?? [];
  const pr = PRIORITY[m.priority] ?? PRIORITY.low;
  const numbers = (sec.key_numbers ?? []).filter((n) => n.label && n.value);

  const range =
    lo !== null || hi !== null
      ? lo !== null && hi !== null && lo !== hi
        ? `${nf.format(lo)} ~ ${nf.format(hi)} t/년`
        : `${nf.format((hi ?? lo) as number)} t/년`
      : null;
  const royaltyRange =
    lo !== null || hi !== null
      ? lo !== null && hi !== null && lo !== hi
        ? `${usd.format(lo * ROYALTY)} ~ ${usd.format(hi * ROYALTY)}/년`
        : `${usd.format(((hi ?? lo) as number) * ROYALTY)}/년`
      : null;

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="flex flex-wrap items-center gap-2 text-base">
            <Globe className="h-4 w-4 text-slate-600" />
            국가 시장현황 — {m.country_name} ({m.country_code})
            <span className={`ml-1 inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${pr.cls}`}>{pr.label}</span>
          </CardTitle>
          {(m.headline_ko ?? m.headline) && (
            <p className="text-sm text-muted-foreground">{m.headline_ko ?? m.headline}</p>
          )}
        </CardHeader>
        <CardContent className="pt-0">
          <h3 className="mb-1 pt-2 text-sm font-semibold">핵심 지표</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <tbody>
                <MetricRow label="제지사 수 (URM)" value={`${nf.format(mills.length)}곳`} note={`우선순위 지정 ${prioritized}곳`} />
                <MetricRow label="충전제 제조사 수 (URM)" value={`${nf.format(fillers.length)}곳`} note="PCC·GCC·석회 원료사 포함" />
                <MetricRow
                  label="확인된 제지 생산능력 합계"
                  value={withCap.length ? `${nf.format(capSum)} t/년` : '-'}
                  note={`생산능력이 입력된 ${withCap.length}개 밀 기준 (명목능력, 지종 혼합)`}
                />
                <MetricRow
                  label="FCC 예상 물량 (밀 시나리오 합계)"
                  value={withFcc.length ? `${nf.format(fccSum)} t/년 · 로열티 ${usd.format(fccSum * ROYALTY)}/년` : '-'}
                  note={`Base 시나리오(가동 85%·적용 25%·FCC 20%)가 있는 ${withFcc.length}개 밀`}
                />
                <MetricRow
                  label="FCC 예상 공급 물량 (보고서)"
                  value={range ? `${range} · 로열티 ${royaltyRange}` : '-'}
                  note={m.fcc_potential_basis_ko ?? undefined}
                />
                {numbers.map((n, i) => (
                  <MetricRow key={i} label={n.label as string} value={n.value} />
                ))}
              </tbody>
            </table>
          </div>

          {(m.summary_ko ?? m.summary) && <Block title="시장 요약">{m.summary_ko ?? m.summary}</Block>}
          {sec.fillers && <Block title="충전제 제조사 현황 (PCC·GCC)">{sec.fillers}</Block>}
          {sec.mills && <Block title="제지사 현황">{sec.mills}</Block>}
          {sec.strategy && <Block title="접근 전략">{sec.strategy}</Block>}
          {sec.risks && <Block title="리스크">{sec.risks}</Block>}
          {(sec.next_steps ?? []).length > 0 && (
            <Block title="다음 단계">
              <ul className="list-disc pl-5">
                {(sec.next_steps ?? []).map((t, i) => <li key={i}>{t}</li>)}
              </ul>
            </Block>
          )}
          <p className="pt-4 text-xs text-muted-foreground">
            확인일 {m.checked_at ?? '-'}
            {files.length > 0 && <> · 근거 파일: {files.join(', ')}</>}
            {' '}· 물량·로열티는 계획 시나리오이며 주문이 아닙니다 (로열티 {usd.format(ROYALTY)}/t 가정).
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">제지사 ({mills.length})</CardTitle>
        </CardHeader>
        <CardContent className="pt-0">
          {mills.length === 0 ? (
            <p className="text-sm text-muted-foreground">URM 에 등록된 제지사가 없습니다.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-xs text-muted-foreground">
                    <th className="py-1.5 pr-3 font-medium">우선순위</th>
                    <th className="py-1.5 pr-3 font-medium">회사</th>
                    <th className="py-1.5 pr-3 font-medium">지역</th>
                    <th className="py-1.5 pr-3 font-medium">지종·제품</th>
                    <th className="py-1.5 pr-3 text-right font-medium">생산능력 (t/년)</th>
                    <th className="py-1.5 pr-3 text-right font-medium">FCC 기준 (t/년)</th>
                    <th className="py-1.5 text-right font-medium">로열티 ($/년)</th>
                  </tr>
                </thead>
                <tbody>
                  {mills.map((x) => (
                    <tr key={x.id} className={`border-b border-border/40 align-top last:border-0 ${x.id === partyId ? 'bg-indigo-50 dark:bg-indigo-950/30' : ''}`}>
                      <td className="py-1.5 pr-3">{x.priority ?? '-'}</td>
                      <td className="py-1.5 pr-3">
                        <Link href={`/paper_mill/parties/${x.id}?tab=market`} className="text-primary hover:underline">{x.party_name}</Link>
                      </td>
                      <td className="py-1.5 pr-3 text-muted-foreground">{x.city ?? x.region ?? '-'}</td>
                      <td className="py-1.5 pr-3 text-muted-foreground">{x.products ?? '-'}</td>
                      <td className="py-1.5 pr-3 text-right">{x.capacity !== null ? nf.format(x.capacity) : '-'}</td>
                      <td className="py-1.5 pr-3 text-right">{x.fcc !== null ? nf.format(x.fcc) : '-'}</td>
                      <td className="py-1.5 text-right">{x.fcc !== null ? usd.format(x.fcc * ROYALTY) : '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">충전제 제조사 ({fillers.length})</CardTitle>
        </CardHeader>
        <CardContent className="pt-0">
          {fillers.length === 0 ? (
            <p className="text-sm text-muted-foreground">URM 에 등록된 충전제 제조사가 없습니다.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-xs text-muted-foreground">
                    <th className="py-1.5 pr-3 font-medium">회사</th>
                    <th className="py-1.5 pr-3 font-medium">지역</th>
                    <th className="py-1.5 pr-3 font-medium">유형</th>
                    <th className="py-1.5 pr-3 font-medium">광물</th>
                    <th className="py-1.5 font-medium">시장 역할</th>
                  </tr>
                </thead>
                <tbody>
                  {fillers.map((x) => (
                    <tr key={x.id} className={`border-b border-border/40 align-top last:border-0 ${x.id === partyId ? 'bg-indigo-50 dark:bg-indigo-950/30' : ''}`}>
                      <td className="py-1.5 pr-3">
                        <Link href={`/filler_supplier/parties/${x.id}?tab=market`} className="text-primary hover:underline">{x.party_name}</Link>
                      </td>
                      <td className="py-1.5 pr-3 text-muted-foreground">{x.city ?? x.region ?? '-'}</td>
                      <td className="py-1.5 pr-3">{x.prof?.supplier_type ?? '-'}</td>
                      <td className="py-1.5 pr-3">{x.prof?.mineral_class ?? '-'}</td>
                      <td className="py-1.5 text-muted-foreground">{x.prof?.market_role ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
