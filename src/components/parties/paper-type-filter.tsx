'use client';

/**
 * PaperTypeFilter
 * 종이종류(paper_types) 칩을 눌러 해당 종류를 생산하는 paper mill만 필터링.
 * 데이터: app.paper_types (드롭다운) + app.v_paper_mill_types (결과, security_invoker 뷰).
 *
 * ⚠️ 조정 필요: supabase 브라우저 클라이언트 import 경로를 프로젝트 실제 경로로 바꾸세요.
 *    (예: '@/lib/supabase/client' | '@/utils/supabase/client' | '@/lib/supabaseClient')
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { createAppBrowserClient } from '@/lib/supabase/client';

type Locale = 'ko' | 'en' | 'ja';

interface PaperType {
  id: string;
  code: string;
  category: string;
  label_ko: string;
  label_en: string;
  label_ja: string;
  filler_relevance: string | null;
  sort_order: number;
}

interface MillRow {
  mill_id: string;
  party_name: string;
  country_code: string | null;
  city: string | null;
  filler_use_intensity: string | null;
  type_code: string;
  label_ko: string;
  label_en: string;
  label_ja: string;
  is_primary: boolean;
}

const CATEGORY_LABEL: Record<string, Record<Locale, string>> = {
  graphic: { ko: '인쇄용지', en: 'Graphic', ja: '印刷用紙' },
  packaging: { ko: '포장 / 판지', en: 'Packaging', ja: '包装 / 板紙' },
  tissue: { ko: '티슈 / 위생', en: 'Tissue', ja: 'ティシュ' },
  specialty: { ko: '특수지', en: 'Specialty', ja: '特殊紙' },
  pulp: { ko: '펄프', en: 'Pulp', ja: 'パルプ' },
};
const CATEGORY_ORDER = ['graphic', 'packaging', 'tissue', 'specialty', 'pulp'];

const INTENSITY_STYLE: Record<string, string> = {
  high: 'bg-emerald-100 text-emerald-700',
  medium: 'bg-amber-100 text-amber-700',
  low: 'bg-slate-100 text-slate-500',
  none: 'bg-slate-100 text-slate-400',
};

export default function PaperTypeFilter({ locale = 'ko' }: { locale?: Locale }) {
  const supabase = useMemo(() => createAppBrowserClient(), []);
  const [types, setTypes] = useState<PaperType[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [mills, setMills] = useState<MillRow[]>([]);
  const [loading, setLoading] = useState(false);

  const lab = useCallback(
    (r: { label_ko: string; label_en: string; label_ja: string }) =>
      locale === 'en' ? r.label_en : locale === 'ja' ? r.label_ja : r.label_ko,
    [locale],
  );

  useEffect(() => {
    (async () => {
      const { data, error } = await supabase
        .from('paper_types')
        .select('id,code,category,label_ko,label_en,label_ja,filler_relevance,sort_order')
        .eq('is_active', true)
        .order('sort_order');
      if (!error && data) setTypes(data as PaperType[]);
    })();
  }, [supabase]);

  const loadMills = useCallback(
    async (code: string) => {
      setLoading(true);
      const { data, error } = await supabase
        .from('v_paper_mill_types')
        .select(
          'mill_id,party_name,country_code,city,filler_use_intensity,type_code,label_ko,label_en,label_ja,is_primary',
        )
        .eq('type_code', code)
        .order('party_name');
      setMills(!error && data ? (data as MillRow[]) : []);
      setLoading(false);
    },
    [supabase],
  );

  const onSelect = (code: string) => {
    const next = selected === code ? null : code;
    setSelected(next);
    if (next) loadMills(next);
    else setMills([]);
  };

  const grouped = useMemo(
    () =>
      types.reduce<Record<string, PaperType[]>>((acc, t) => {
        (acc[t.category] ||= []).push(t);
        return acc;
      }, {}),
    [types],
  );

  const selectedType = types.find((t) => t.code === selected) ?? null;

  return (
    <div className="space-y-4">
      <div className="space-y-3">
        {CATEGORY_ORDER.filter((c) => grouped[c]?.length).map((cat) => (
          <div key={cat}>
            <div className="mb-1 text-xs font-medium text-slate-400">
              {CATEGORY_LABEL[cat]?.[locale] ?? cat}
            </div>
            <div className="flex flex-wrap gap-2">
              {(grouped[cat] ?? []).map((t) => (
                <button
                  key={t.code}
                  type="button"
                  onClick={() => onSelect(t.code)}
                  className={[
                    'rounded-full border px-3 py-1 text-sm transition',
                    selected === t.code
                      ? 'border-sky-500 bg-sky-500 text-white'
                      : 'border-slate-200 bg-white text-slate-600 hover:border-sky-300',
                  ].join(' ')}
                >
                  {lab(t)}
                </button>
              ))}
            </div>
          </div>
        ))}
      </div>

      {selected && selectedType && (
        <div className="rounded-lg border border-slate-200">
          <div className="flex items-center justify-between border-b border-slate-100 px-4 py-2 text-sm text-slate-500">
            <span>
              {lab(selectedType)} {locale === 'ko' ? '생산업체' : locale === 'ja' ? 'メーカー' : 'mills'}
            </span>
            <span className="tabular-nums">{loading ? '…' : mills.length}</span>
          </div>

          {loading ? (
            <div className="px-4 py-6 text-center text-sm text-slate-400">Loading…</div>
          ) : mills.length === 0 ? (
            <div className="px-4 py-6 text-center text-sm text-slate-400">
              {locale === 'ko'
                ? '해당 종이종류 생산업체가 없습니다.'
                : locale === 'ja'
                  ? '該当するメーカーがありません。'
                  : 'No mills for this paper type.'}
            </div>
          ) : (
            <ul className="divide-y divide-slate-100">
              {mills.map((m) => (
                <li key={m.mill_id} className="flex items-center justify-between px-4 py-2">
                  <div className="flex min-w-0 items-center gap-2">
                    <span className="truncate font-medium text-slate-700">{m.party_name}</span>
                    {m.country_code && (
                      <span className="shrink-0 text-xs text-slate-400">{m.country_code}</span>
                    )}
                    {m.is_primary && (
                      <span className="shrink-0 rounded bg-sky-50 px-1.5 py-0.5 text-[10px] text-sky-600">
                        primary
                      </span>
                    )}
                  </div>
                  {m.filler_use_intensity && (
                    <span
                      className={`shrink-0 rounded px-2 py-0.5 text-xs ${
                        INTENSITY_STYLE[m.filler_use_intensity] ?? 'bg-slate-100 text-slate-500'
                      }`}
                    >
                      filler {m.filler_use_intensity}
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
