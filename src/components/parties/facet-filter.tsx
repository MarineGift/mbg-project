'use client';

/**
 * FacetFilter — 검색창용 통합 facet 필터
 *   partyType="paper_mill" → 종이종류 (paper_types, 카테고리 그룹)        → app.v_paper_mill_types
 *   partyType="filler"     → GCC / PCC / 둘다 / 미분류 (mineral_class)    → app.v_filler_classes
 *   partyType="investor"   → 투자단계 (investment_stages)                → app.v_investor_stages
 *
 * 칩 토글 선택 → 해당 항목만 필터링. 클라이언트는 app 스키마 락(SupabaseDb).
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { createSupabaseBrowserClient } from '@/lib/supabase/client';

type Locale = 'ko' | 'en' | 'ja';
export type PartyKind = 'paper_mill' | 'filler' | 'investor';

interface Facet {
  code: string;
  label: string;
  group?: string;
}
interface ResultRow {
  id: string;
  name: string;
  country: string | null;
  badge?: string | null;
}

const PAPER_CAT_ORDER = ['graphic', 'packaging', 'tissue', 'specialty', 'pulp'];
const FILLER_ORDER = ['both', 'gcc', 'pcc', 'unknown'];
const STAGE_ORDER = [
  'pre_seed', 'seed', 'series_a', 'series_b', 'series_c', 'series_d',
  'early', 'growth', 'late', 'buyout', 'public', 'unknown',
];

const T = {
  results: { ko: '대상', en: 'results', ja: '件' } as Record<Locale, string>,
  empty: {
    ko: '해당 조건의 대상이 없습니다.',
    en: 'No matches.',
    ja: '該当なし。',
  } as Record<Locale, string>,
  groups: {
    graphic: { ko: '인쇄용지', en: 'Graphic', ja: '印刷用紙' },
    packaging: { ko: '포장 / 판지', en: 'Packaging', ja: '包装 / 板紙' },
    tissue: { ko: '티슈 / 위생', en: 'Tissue', ja: 'ティシュ' },
    specialty: { ko: '특수지', en: 'Specialty', ja: '特殊紙' },
    pulp: { ko: '펄프', en: 'Pulp', ja: 'パルプ' },
  } as Record<string, Record<Locale, string>>,
  filler: {
    both: { ko: '둘 다', en: 'Both', ja: '両方' },
    gcc: { ko: 'GCC', en: 'GCC', ja: 'GCC' },
    pcc: { ko: 'PCC', en: 'PCC', ja: 'PCC' },
    unknown: { ko: '미분류', en: 'Unknown', ja: '未分類' },
  } as Record<string, Record<Locale, string>>,
};

const BADGE_STYLE: Record<string, string> = {
  high: 'bg-emerald-100 text-emerald-700',
  medium: 'bg-amber-100 text-amber-700',
  low: 'bg-slate-100 text-slate-500',
  none: 'bg-slate-100 text-slate-400',
};

export default function FacetFilter({
  partyType,
  locale = 'ko',
}: {
  partyType: PartyKind;
  locale?: Locale;
}) {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [facets, setFacets] = useState<Facet[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [rows, setRows] = useState<ResultRow[]>([]);
  const [loading, setLoading] = useState(false);

  const pick = useCallback(
    (m: Record<Locale, string> | undefined, fallback: string) => (m ? m[locale] : fallback),
    [locale],
  );

  // ---- load facets per party type ----
  useEffect(() => {
    setSelected(null);
    setRows([]);
    (async () => {
      if (partyType === 'filler') {
        setFacets(FILLER_ORDER.map((c) => ({ code: c, label: pick(T.filler[c], c) })));
        return;
      }
      if (partyType === 'paper_mill') {
        const { data } = await supabase
          .from('paper_types')
          .select('code,category,label_ko,label_en,label_ja,sort_order')
          .eq('is_active', true)
          .order('sort_order');
        setFacets(
          (data ?? []).map((t: any) => ({
            code: t.code,
            group: t.category,
            label: locale === 'en' ? t.label_en : locale === 'ja' ? t.label_ja : t.label_ko,
          })),
        );
        return;
      }
      // investor
      const { data } = await supabase
        .from('investment_stages')
        .select('code,label_ko,label_en,label_ja');
      setFacets(
        (data ?? [])
          .map((s: any) => ({
            code: s.code,
            label: locale === 'en' ? s.label_en : locale === 'ja' ? s.label_ja : s.label_ko,
          }))
          .sort(
            (a, b) =>
              (STAGE_ORDER.indexOf(a.code) + 1 || 99) - (STAGE_ORDER.indexOf(b.code) + 1 || 99),
          ),
      );
    })();
  }, [partyType, supabase, locale, pick]);

  // ---- load results for a selected facet ----
  const loadResults = useCallback(
    async (code: string) => {
      setLoading(true);
      let mapped: ResultRow[] = [];
      if (partyType === 'paper_mill') {
        const { data } = await supabase
          .from('v_paper_mill_types')
          .select('mill_id,party_name,country_code,filler_use_intensity')
          .eq('type_code', code)
          .order('party_name');
        mapped = (data ?? []).map((r: any) => ({
          id: r.mill_id,
          name: r.party_name,
          country: r.country_code,
          badge: r.filler_use_intensity ? `filler ${r.filler_use_intensity}` : null,
        }));
      } else if (partyType === 'filler') {
        const { data } = await supabase
          .from('v_filler_classes')
          .select('supplier_id,party_name,country_code,supply_model')
          .eq('mineral_class', code)
          .order('party_name');
        mapped = (data ?? []).map((r: any) => ({
          id: r.supplier_id,
          name: r.party_name,
          country: r.country_code,
          badge: r.supply_model ?? null,
        }));
      } else {
        const { data } = await supabase
          .from('v_investor_stages')
          .select('investor_id,party_name,country_code')
          .eq('stage_code', code)
          .order('party_name');
        mapped = (data ?? []).map((r: any) => ({
          id: r.investor_id,
          name: r.party_name,
          country: r.country_code,
          badge: null,
        }));
      }
      setRows(mapped);
      setLoading(false);
    },
    [partyType, supabase],
  );

  const onSelect = (code: string) => {
    const next = selected === code ? null : code;
    setSelected(next);
    if (next) loadResults(next);
    else setRows([]);
  };

  const grouped = useMemo(() => {
    if (partyType !== 'paper_mill') return null;
    const g: Record<string, Facet[]> = {};
    facets.forEach((f) => {
      (g[f.group ?? 'other'] ||= []).push(f);
    });
    return g;
  }, [facets, partyType]);

  const selectedLabel = facets.find((f) => f.code === selected)?.label ?? '';

  const Chips = ({ list }: { list: Facet[] }) => (
    <div className="flex flex-wrap gap-2">
      {list.map((f) => (
        <button
          key={f.code}
          type="button"
          onClick={() => onSelect(f.code)}
          className={[
            'rounded-full border px-3 py-1 text-sm transition',
            selected === f.code
              ? 'border-sky-500 bg-sky-500 text-white'
              : 'border-slate-200 bg-white text-slate-600 hover:border-sky-300',
          ].join(' ')}
        >
          {f.label}
        </button>
      ))}
    </div>
  );

  return (
    <div className="space-y-4">
      {grouped ? (
        <div className="space-y-3">
          {PAPER_CAT_ORDER.filter((c) => grouped[c]?.length).map((cat) => (
            <div key={cat}>
              <div className="mb-1 text-xs font-medium text-slate-400">{pick(T.groups[cat], cat)}</div>
              <Chips list={grouped[cat] ?? []} />
            </div>
          ))}
        </div>
      ) : (
        <Chips list={facets} />
      )}

      {selected && (
        <div className="rounded-lg border border-slate-200">
          <div className="flex items-center justify-between border-b border-slate-100 px-4 py-2 text-sm text-slate-500">
            <span>
              {selectedLabel} · {pick(T.results, 'results')}
            </span>
            <span className="tabular-nums">{loading ? '…' : rows.length}</span>
          </div>
          {loading ? (
            <div className="px-4 py-6 text-center text-sm text-slate-400">Loading…</div>
          ) : rows.length === 0 ? (
            <div className="px-4 py-6 text-center text-sm text-slate-400">{pick(T.empty, 'No matches.')}</div>
          ) : (
            <ul className="divide-y divide-slate-100">
              {rows.map((r) => (
                <li key={r.id} className="flex items-center justify-between px-4 py-2">
                  <div className="flex min-w-0 items-center gap-2">
                    <span className="truncate font-medium text-slate-700">{r.name}</span>
                    {r.country && <span className="shrink-0 text-xs text-slate-400">{r.country}</span>}
                  </div>
                  {r.badge && (
                    <span
                      className={`shrink-0 rounded px-2 py-0.5 text-xs ${
                        BADGE_STYLE[r.badge.replace('filler ', '')] ?? 'bg-slate-100 text-slate-500'
                      }`}
                    >
                      {r.badge}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
