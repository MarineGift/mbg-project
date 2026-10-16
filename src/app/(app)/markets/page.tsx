// src/app/(app)/markets/page.tsx
//
// Country Markets index - one row per country, from app.country_markets plus
// every country that has paper mills or filler suppliers in URM. Lets a
// country be opened even when it has no mill / filler row (e.g. Timor-Leste).
// Counts are live from app.parties (paper_mill, filler_supplier).

import Link from 'next/link';
import { Globe } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { fetchCountryNames } from '@/lib/queries/countries';

export const dynamic = 'force-dynamic';

type Market = {
  country_code: string;
  country_name: string | null;
  priority: string | null;
  headline_ko: string | null;
  headline: string | null;
  fcc_potential_low_t: number | string | null;
  fcc_potential_high_t: number | string | null;
  chatgpt_url: string | null;
  claude_url: string | null;
  gemini_url: string | null;
  checked_at: string | null;
};

const PRIORITY: Record<string, { label: string; rank: number; cls: string }> = {
  high:    { label: '높음', rank: 1, cls: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300' },
  medium:  { label: '중간', rank: 2, cls: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' },
  low:     { label: '낮음', rank: 3, cls: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300' },
  on_hold: { label: '보류', rank: 4, cls: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300' },
  none:    { label: '대상 없음', rank: 5, cls: 'bg-muted text-muted-foreground' },
};

const nf = new Intl.NumberFormat('ko-KR', { maximumFractionDigits: 0 });
const toNum = (v: unknown): number | null => {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
};

export default async function MarketsPage({
  searchParams,
}: {
  searchParams: Promise<{ p?: string }>;
}) {
  const sp = await searchParams;
  const pFilter = (sp?.p ?? '').trim();
  const supabase = await createSupabaseServerClient();

  const [marketRes, typesRes, names] = await Promise.all([
    supabase
      .schema('app')
      .from('country_markets' as never)
      .select('country_code, country_name, priority, headline, headline_ko, fcc_potential_low_t, fcc_potential_high_t, chatgpt_url, claude_url, gemini_url, checked_at')
      .is('deleted_at' as never, null),
    supabase
      .schema('app')
      .from('party_types' as never)
      .select('id, code')
      .in('code' as never, ['paper_mill', 'filler_supplier'] as never),
    fetchCountryNames(),
  ]);

  const markets = ((marketRes.data ?? []) as unknown as Market[]);
  const types = ((typesRes.data ?? []) as unknown as { id: string | number; code: string }[]);
  const codeById = new Map(types.map((t) => [String(t.id), t.code]));

  // live mill / filler counts per country (paged - PostgREST caps at 1000 rows)
  const counts = new Map<string, { mills: number; fillers: number }>();
  if (types.length > 0) {
    for (let page = 0; page < 20; page++) {
      const { data, error } = await supabase
        .schema('app')
        .from('parties' as never)
        .select('country_code, party_type_id')
        .in('party_type_id' as never, types.map((t) => t.id) as never)
        .is('deleted_at' as never, null)
        .not('country_code' as never, 'is', null)
        .order('id' as never)
        .range(page * 1000, page * 1000 + 999);
      if (error) break;
      const rows = (data ?? []) as unknown as { country_code: string; party_type_id: string | number }[];
      for (const r of rows) {
        const c = (r.country_code ?? '').toUpperCase();
        if (!c) continue;
        const cur = counts.get(c) ?? { mills: 0, fillers: 0 };
        const kind = codeById.get(String(r.party_type_id));
        if (kind === 'paper_mill') cur.mills++;
        else if (kind === 'filler_supplier') cur.fillers++;
        counts.set(c, cur);
      }
      if (rows.length < 1000) break;
    }
  }

  const byCode = new Map(markets.map((m) => [m.country_code.toUpperCase(), m]));
  const allCodes = [...new Set([...byCode.keys(), ...counts.keys()])];

  type Row = { code: string; name: string; m: Market | null; mills: number; fillers: number; rank: number };
  let rows: Row[] = allCodes.map((code) => {
    const m = byCode.get(code) ?? null;
    const c = counts.get(code) ?? { mills: 0, fillers: 0 };
    return {
      code,
      name: m?.country_name || names[code] || code,
      m,
      mills: c.mills,
      fillers: c.fillers,
      rank: m ? (PRIORITY[m.priority ?? '']?.rank ?? 6) : 7,
    };
  });
  if (pFilter === 'none_row') rows = rows.filter((r) => !r.m);
  else if (pFilter) rows = rows.filter((r) => r.m?.priority === pFilter);
  rows.sort((a, b) => a.rank - b.rank || a.name.localeCompare(b.name));

  const withRow = allCodes.filter((c) => byCode.has(c)).length;
  const chips: Array<[string, string]> = [
    ['', '전체'], ['high', '높음'], ['medium', '중간'], ['low', '낮음'], ['on_hold', '보류'], ['none', '대상 없음'], ['none_row', '시장현황 미등록'],
  ];

  return (
    <div className="px-4 sm:px-6 py-4 sm:py-6 space-y-4">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl sm:text-2xl font-bold flex items-center gap-2">
          <Globe className="h-5 w-5" /> Country Markets
        </h1>
        <p className="text-sm text-muted-foreground">
          국가 {allCodes.length}개 · 시장현황 등록 {withRow}개 · 제지사·충전제사 수는 실시간
        </p>
        {marketRes.error && (
          <p className="text-sm text-amber-700">시장현황을 불러오지 못했습니다: {marketRes.error.message}</p>
        )}
      </div>

      <div className="flex flex-wrap gap-1.5">
        {chips.map(([v, label]) => (
          <Link
            key={v || 'all'}
            href={v ? `/markets?p=${v}` : '/markets'}
            className={`px-2.5 py-1 rounded-md text-xs border ${pFilter === v ? 'bg-primary text-primary-foreground border-primary' : 'hover:bg-muted'}`}
          >
            {label}
          </Link>
        ))}
      </div>

      <div className="overflow-x-auto rounded-md border">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-xs text-muted-foreground">
            <tr>
              <th className="px-3 py-2 text-left">국가</th>
              <th className="px-3 py-2 text-left">우선순위</th>
              <th className="px-3 py-2 text-left">요약</th>
              <th className="px-3 py-2 text-right">제지사</th>
              <th className="px-3 py-2 text-right">충전제사</th>
              <th className="px-3 py-2 text-right">FCC 예상 (t/년)</th>
              <th className="px-3 py-2 text-left">AI</th>
              <th className="px-3 py-2 text-left">확인일</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => {
              const p = r.m ? PRIORITY[r.m.priority ?? ''] : undefined;
              const lo = toNum(r.m?.fcc_potential_low_t);
              const hi = toNum(r.m?.fcc_potential_high_t);
              const fcc = lo === null && hi === null ? '-' : lo === hi || hi === null ? nf.format(lo ?? 0) : `${nf.format(lo ?? 0)} ~ ${nf.format(hi)}`;
              const ai = r.m ? [r.m.chatgpt_url && 'GPT', r.m.claude_url && 'Claude', r.m.gemini_url && 'Gemini'].filter(Boolean).join(' · ') : '';
              return (
                <tr key={r.code} className="border-t align-top hover:bg-muted/30">
                  <td className="px-3 py-2 whitespace-nowrap">
                    <Link href={`/markets/${r.code}`} className="font-medium text-primary hover:underline">
                      {r.name}
                    </Link>
                    <span className="ml-1.5 text-xs text-muted-foreground">{r.code}</span>
                  </td>
                  <td className="px-3 py-2 whitespace-nowrap">
                    {p ? (
                      <span className={`px-1.5 py-0.5 rounded text-xs ${p.cls}`}>{p.label}</span>
                    ) : (
                      <span className="text-xs text-muted-foreground">미등록</span>
                    )}
                  </td>
                  <td className="px-3 py-2 min-w-[260px]">{r.m?.headline_ko || r.m?.headline || '-'}</td>
                  <td className="px-3 py-2 text-right">
                    {r.mills > 0 ? (
                      <Link href={`/paper_mill/parties?country=${r.code}`} className="hover:underline">{nf.format(r.mills)}</Link>
                    ) : '0'}
                  </td>
                  <td className="px-3 py-2 text-right">
                    {r.fillers > 0 ? (
                      <Link href={`/filler_supplier/parties?country=${r.code}`} className="hover:underline">{nf.format(r.fillers)}</Link>
                    ) : '0'}
                  </td>
                  <td className="px-3 py-2 text-right whitespace-nowrap">{fcc}</td>
                  <td className="px-3 py-2 text-xs whitespace-nowrap">{ai || '-'}</td>
                  <td className="px-3 py-2 text-xs text-muted-foreground whitespace-nowrap">{r.m?.checked_at ?? '-'}</td>
                </tr>
              );
            })}
            {rows.length === 0 && (
              <tr><td colSpan={8} className="px-3 py-6 text-center text-muted-foreground">해당 국가 없음</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
