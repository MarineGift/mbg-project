/**
 * app/(app)/[partyType]/parties/page.tsx
 * Phase 8 + responsive + Phase 20d (lead score) + pagination + Phase 20f (saved views)
 * Phase 23: supply links column (connected mills / fillers)
 * Feature A: account scoring -> directory now reads app.v_account_scores
 *            (A/B/C tier + 0..100 score), with score sort + grade filter.
 */

import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Plus, ExternalLink, Building2, Factory, Layers3, AlertTriangle } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { requireAuthOrRedirect } from '@/lib/auth';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { AccountScoreBadge } from '@/components/common/account-score-badge';
import { PaginationBar } from '@/components/common/pagination-bar';
import { SavedViewsDropdown } from '@/components/common/saved-views-dropdown';
import { fetchAccountScoresMany, type AccountScore, type AccountTier } from '@/lib/queries/account-score';
import { fetchSavedViews } from '@/lib/queries/saved-views';
import { fetchCountryNames } from '@/lib/queries/countries';
import type { PartyTypeCode } from '@/types/ai';
import type { PartyTier, PartyStatus } from '@/types/party-detail';
import dynamic from 'next/dynamic';
const PartiesFilterBar = dynamic(
  () => import('@/components/parties/parties-filter-bar').then(m => ({ default: m.PartiesFilterBar })),
  { ssr: false, loading: () => null }
);

const DEFAULT_PAGE_SIZE = 50;
const PAGE_SIZE_OPTIONS = [25, 50, 100, 200] as const;

const PHASE_1_MODULES: readonly PartyTypeCode[] = [
  'investor', 'paper_mill', 'partner', 'customer', 'filler_supplier', 'buyer', 'government_grant', 'self',
] as const;

const MODULE_LABELS: Record<PartyTypeCode, string> = {
  investor:       'Investors',
  paper_mill:     'Paper Mills',
  partner:        'Partners',
  customer:       'Customers',
  filler_supplier:         'Filler Suppliers',
  buyer:                   'Buyers',
  government_grant:        'Government Grants',
  consultant:              'Consultants',
  crowdfunding_platform:   'Crowdfunding Platforms',
  self:                    'MarineBio Group',
};

const TIER_LABELS: Record<PartyTier, string> = {
  tier_1: 'Tier 1', tier_2: 'Tier 2', tier_3: 'Tier 3', cold: 'Cold',
};
const TIER_COLORS: Record<PartyTier, string> = {
  tier_1: 'bg-emerald-100 text-emerald-700',
  tier_2: 'bg-blue-100 text-blue-700',
  tier_3: 'bg-slate-100 text-slate-700',
  cold:   'bg-gray-100 text-gray-500',
};

type PartyLevel = 'group_hq' | 'country_entity' | 'plant';
const PARTY_LEVEL_LABELS: Record<PartyLevel, string> = {
  group_hq: 'HQ', country_entity: 'Entity', plant: 'Plant',
};
const PARTY_LEVEL_COLORS: Record<PartyLevel, string> = {
  group_hq:       'bg-violet-100 text-violet-700',
  country_entity: 'bg-sky-100 text-sky-700',
  plant:          'bg-teal-100 text-teal-700',
};

const US_STATES: Record<string, string> = { AL:'Alabama', AK:'Alaska', AZ:'Arizona', AR:'Arkansas', CA:'California', CO:'Colorado', CT:'Connecticut', DE:'Delaware', FL:'Florida', GA:'Georgia', HI:'Hawaii', ID:'Idaho', IL:'Illinois', IN:'Indiana', IA:'Iowa', KS:'Kansas', KY:'Kentucky', LA:'Louisiana', ME:'Maine', MD:'Maryland', MA:'Massachusetts', MI:'Michigan', MN:'Minnesota', MS:'Mississippi', MO:'Missouri', MT:'Montana', NE:'Nebraska', NV:'Nevada', NH:'New Hampshire', NJ:'New Jersey', NM:'New Mexico', NY:'New York', NC:'North Carolina', ND:'North Dakota', OH:'Ohio', OK:'Oklahoma', OR:'Oregon', PA:'Pennsylvania', RI:'Rhode Island', SC:'South Carolina', SD:'South Dakota', TN:'Tennessee', TX:'Texas', UT:'Utah', VT:'Vermont', VA:'Virginia', WA:'Washington', WV:'West Virginia', WI:'Wisconsin', WY:'Wyoming', DC:'District of Columbia', BC:'British Columbia', ON:'Ontario', QC:'Quebec' };

interface PartyRow {
  id: string; party_name: string; tier: PartyTier | null; status: PartyStatus;
  party_level: PartyLevel | null; parent_party_id: string | null;
  country_code: string | null; city: string | null; region: string | null;
  interest_tags: string[] | null; website: string | null; created_at: string;
  entity_type_id: number | null;
}

interface PageProps {
  params: Promise<{ partyType: string }>;
  searchParams: Promise<{
    include_stubs?: string; sort?: string; page?: string; perPage?: string; q?: string;
    country?: string; type?: string; grade?: string; priority?: string;
  }>;
}

/** Fetch supply link names for a set of party IDs.
 *  Returns map: partyId ??linked party names[] */
async function fetchSupplyLinks(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  partyIds: string[],
  role: 'filler_supplier' | 'paper_mill',
): Promise<Record<string, string[]>> {
  if (partyIds.length === 0) return {};
  try {
    const selfCol   = role === 'filler_supplier' ? 'filler_party_id' : 'mill_party_id';
    const linkedCol = role === 'filler_supplier' ? 'mill_party_id'   : 'filler_party_id';

    const { data, error } = await supabase
      .schema('app')
      .from('party_supply_links' as never)
      .select(`${selfCol}, linked:${linkedCol}(party_name)`)
      .in(selfCol as never, partyIds);

    if (error) return {}; // table may not exist yet ??silent fallback

    const map: Record<string, string[]> = {};
    for (const row of (data ?? []) as any[]) {
      const selfId = row[selfCol] as string;
      const name   = row.linked?.party_name as string | undefined;
      if (!selfId || !name) continue;
      if (!map[selfId]) map[selfId] = [];
      map[selfId].push(name);
    }
    return map;
  } catch {
    return {}; // graceful fallback if table doesn't exist
  }
}

export default async function PartiesListPage({ params, searchParams }: PageProps) {
  const { partyType: moduleParam } = await params;
  const sp = await searchParams;
  const searchQuery  = (sp.q ?? '').trim();
  const countryFilter = ((sp as any).country ?? '').trim().toUpperCase();
  const typeFilter = ((sp as any).type ?? '').trim();
  const isInvestor = moduleParam === 'investor';
  const isPaperMill = moduleParam === 'paper_mill';
  const isFiller = moduleParam === 'filler_supplier';

  // Account-score grade filter (A/B/C). Named `grade` to avoid colliding with
  // the party `tier` concept (tier_1/2/3/cold) shown in the Level/Tier column.
  const gradeRaw = (((sp as any).grade ?? '') as string).trim().toUpperCase();
  const gradeFilter: '' | AccountTier =
    gradeRaw === 'A' || gradeRaw === 'B' || gradeRaw === 'C' ? (gradeRaw as AccountTier) : '';

  // Investment-stage (round) filter for the investor list: ?stage=<code>
  // (e.g. 'series_a'), matched against the investor's investor_stage_focus set.
  const stageFilter = (((sp as any).stage ?? '') as string).trim();
  // Sector focus filter for the investor list: ?sector=<code> (e.g. 'advanced_materials'),
  // matched against the investor's investor_sector_focus set.
  const sectorFilter = (((sp as any).sector ?? '') as string).trim();
  // Manual investor Priority filter (relevance / who to contact now): ?priority=high|medium|low
  const priorityFilter = (((sp as any).priority ?? '') as string).trim().toLowerCase();

  const showStubs   = sp.include_stubs === '1';
  const sortParam   = sp.sort ?? 'name_asc';
  const sortByScore = sortParam === 'score' || sortParam === 'score_asc';
  const scoreAsc    = sortParam === 'score_asc';
  const sortByType  = isInvestor && (sortParam === 'type_asc' || sortParam === 'type_desc');
  const typeAsc     = sortParam === 'type_asc';
  const sortByPriority = isInvestor && (sortParam === 'priority' || sortParam === 'priority_asc');
  const priorityAsc    = sortParam === 'priority_asc';
  // DB-orderable sorts (everything except score, which is computed in JS).
  const DB_SORT: Record<string, { col: string; asc: boolean }> = {
    name_asc:      { col: 'party_name',   asc: true  },
    name_desc:     { col: 'party_name',   asc: false },
    country_asc:   { col: 'country_code', asc: true  },
    country_desc:  { col: 'country_code', asc: false },
    location_asc:  { col: 'city',         asc: true  },
    location_desc: { col: 'city',         asc: false },
    state_asc:     { col: 'region',       asc: true  },
    state_desc:    { col: 'region',       asc: false },
    etype_asc:     { col: 'entity_type_id', asc: true  },
    etype_desc:    { col: 'entity_type_id', asc: false },
  };
  const dbSort = DB_SORT[sortParam] ?? { col: 'party_name', asc: true };
  const page        = Math.max(1, Number(sp.page ?? 1));
  const pageSize    = (PAGE_SIZE_OPTIONS as readonly number[]).includes(Number(sp.perPage))
    ? Number(sp.perPage) : DEFAULT_PAGE_SIZE;
  const from = (page - 1) * pageSize;
  const to   = from + pageSize - 1;

  // Allow every party-type code that has a directory label (incl. self,
  // consultant, crowdfunding_platform) -- not just the Phase-1 modules.
  if (!Object.keys(MODULE_LABELS).includes(moduleParam)) notFound();
  const module = moduleParam as PartyTypeCode;

  await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  // D6-5e: resolve party_type code -> party_type_id (app.party_types lookup)
  const { data: ptRow } = await supabase
    .schema('app')
    .from('party_types' as never)
    .select('id')
    .eq('code' as never, module)
    .maybeSingle();
  if (!ptRow) notFound();
  const partyTypeId = (ptRow as { id: string }).id;

  // Show supply links column only for filler and paper_mill
  const showLinks = module === 'filler_supplier' || module === 'paper_mill';
  const linkRole  = module === 'filler_supplier' ? 'filler_supplier' : 'paper_mill';
  const linkLabel = module === 'filler_supplier' ? 'Linked Paper Mill' : 'Linked Filler';
  // Partner-style directories get an org "Type" (entity_type) column; suppliers keep
  // their linked column and investors keep their investor-type column.
  const showEntityType = !isInvestor && !showLinks;

  // Investor type lookup (all investors): one fetch powers facets, badges,
  // the type filter, and type sorting.
  const investorCatAll: Record<string, { type_name: string | null; category: string }> = {};
  let investorFacets: { category: string; count: number }[] = [];
  if (isInvestor) {
    const { data: vitRows } = await supabase
      .schema('app')
      .from('v_investor_types' as never)
      .select('party_id, type_name, investor_category');
    const counts = new Map<string, number>();
    for (const r of ((vitRows ?? []) as any[])) {
      investorCatAll[r.party_id] = { type_name: r.type_name ?? null, category: r.investor_category };
      counts.set(r.investor_category, (counts.get(r.investor_category) ?? 0) + 1);
    }
    investorFacets = [...counts.entries()]
      .map(([category, count]) => ({ category, count }))
      .sort((a, b) => b.count - a.count);
  }
  // Investor INVESTMENT STAGES (the rounds they invest in): party -> stages, via
  // parties -> investor_profile -> investor_stage_focus -> investment_stages.
  // Powers the Stage filter chips + per-row stage badges so you can pull e.g.
  // every Series A investor fast. Mirrors the investor-type lookup above.
  const investorStageAll: Record<string, Array<{ code: string; label: string; sort: number }>> = {};
  let stageFacets: { code: string; label: string; count: number }[] = [];
  if (isInvestor) {
    const [{ data: profRows }, { data: stageRows }, { data: focusRows }] = await Promise.all([
      supabase.schema('app').from('investor_profile' as never).select('id, party_id'),
      supabase.schema('app').from('investment_stages' as never).select('id, code, label_en, sort_order'),
      supabase.schema('app').from('investor_stage_focus' as never).select('investor_profile_id, stage_id'),
    ]);
    const profileToParty = new Map<string, string>();
    for (const r of ((profRows ?? []) as any[])) if (r.party_id) profileToParty.set(r.id, r.party_id);
    const stageById = new Map<number, { code: string; label: string; sort: number }>();
    for (const r of ((stageRows ?? []) as any[])) {
      stageById.set(r.id, { code: r.code, label: r.label_en ?? r.code, sort: r.sort_order ?? 9999 });
    }
    const facet = new Map<string, { label: string; sort: number; parties: Set<string> }>();
    for (const r of ((focusRows ?? []) as any[])) {
      const pid = profileToParty.get(r.investor_profile_id);
      const st = stageById.get(r.stage_id);
      if (!pid || !st) continue;
      const arr = investorStageAll[pid] ?? [];
      if (!arr.some((s) => s.code === st.code)) arr.push({ code: st.code, label: st.label, sort: st.sort });
      investorStageAll[pid] = arr;
      const f = facet.get(st.code) ?? { label: st.label, sort: st.sort, parties: new Set<string>() };
      f.parties.add(pid);
      facet.set(st.code, f);
    }
    for (const k of Object.keys(investorStageAll)) investorStageAll[k]!.sort((a, b) => a.sort - b.sort);
    stageFacets = [...facet.entries()]
      .map(([code, v]) => ({ code, label: v.label, count: v.parties.size, sort: v.sort }))
      .sort((a, b) => a.sort - b.sort)
      .map(({ code, label, count }) => ({ code, label, count }));
  }
  // Investor SECTOR FOCUS (what they invest in): party -> sectors, via
  // parties -> investor_profile -> investor_sector_focus -> sectors.
  // Powers the Sector filter chips so you can pull e.g. every advanced-materials
  // investor fast. Controlled vocabulary (app.sectors), mirrors the stage plumbing.
  const investorSectorAll: Record<string, Array<{ code: string; label: string; sort: number }>> = {};
  let sectorFacets: { code: string; label: string; count: number }[] = [];
  if (isInvestor) {
    const [{ data: profRows2 }, { data: sectorRows }, { data: secFocusRows }] = await Promise.all([
      supabase.schema('app').from('investor_profile' as never).select('id, party_id'),
      supabase.schema('app').from('sectors' as never).select('id, code, label_en, sort_order'),
      supabase.schema('app').from('investor_sector_focus' as never).select('investor_profile_id, sector_id'),
    ]);
    const profileToParty2 = new Map<string, string>();
    for (const r of ((profRows2 ?? []) as any[])) if (r.party_id) profileToParty2.set(r.id, r.party_id);
    const sectorById = new Map<number, { code: string; label: string; sort: number }>();
    for (const r of ((sectorRows ?? []) as any[])) {
      sectorById.set(r.id, { code: r.code, label: r.label_en ?? r.code, sort: r.sort_order ?? 9999 });
    }
    const sFacet = new Map<string, { label: string; sort: number; parties: Set<string> }>();
    for (const r of ((secFocusRows ?? []) as any[])) {
      const pid = profileToParty2.get(r.investor_profile_id);
      const sc = sectorById.get(r.sector_id);
      if (!pid || !sc) continue;
      const arr = investorSectorAll[pid] ?? [];
      if (!arr.some((s) => s.code === sc.code)) arr.push({ code: sc.code, label: sc.label, sort: sc.sort });
      investorSectorAll[pid] = arr;
      const f = sFacet.get(sc.code) ?? { label: sc.label, sort: sc.sort, parties: new Set<string>() };
      f.parties.add(pid);
      sFacet.set(sc.code, f);
    }
    for (const k of Object.keys(investorSectorAll)) investorSectorAll[k]!.sort((a, b) => a.sort - b.sort);
    sectorFacets = [...sFacet.entries()]
      .map(([code, v]) => ({ code, label: v.label, count: v.parties.size, sort: v.sort }))
      .sort((a, b) => a.sort - b.sort)
      .map(({ code, label, count }) => ({ code, label, count }));
  }

  // Investor manual Priority (high/medium/low) per party, from investor_profile.
  // Powers the Priority column, the Priority sort, and the Priority filter.
  const investorPriorityAll: Record<string, 'high' | 'medium' | 'low'> = {};
  if (isInvestor) {
    const { data: prRows } = await supabase
      .schema('app')
      .from('investor_profile' as never)
      .select('party_id, priority');
    for (const r of ((prRows ?? []) as any[])) {
      if (r.party_id && (r.priority === 'high' || r.priority === 'medium' || r.priority === 'low')) {
        investorPriorityAll[r.party_id] = r.priority;
      }
    }
  }

  // Paper-mill paper-type facets.
  // The active facet SET + display order + parent come from app.paper_types
  // (so deactivated types like market_pulp / specialty(other) never leak in,
  // and 2-level sub-grades sit right after their parent). Mill counts come
  // from app.v_paper_mill_types.
  let paperTypeFacets: { category: string; label: string; count: number; parent?: string | null }[] = [];
  if (isPaperMill) {
    const [{ data: typeRows }, { data: linkRows }] = await Promise.all([
      supabase
        .schema('app')
        .from('paper_types' as never)
        .select('id, code, label_en, sort_order, parent_id')
        .eq('is_active' as never, true)
        .order('sort_order' as never),
      supabase
        .schema('app')
        .from('v_paper_mill_types' as never)
        .select('mill_id, type_code'),
    ]);
    const idToCode = new Map<string, string>();
    for (const t of ((typeRows ?? []) as any[])) idToCode.set(t.id, t.code);
    const millsByCode = new Map<string, Set<string>>();
    for (const r of ((linkRows ?? []) as any[])) {
      const s = millsByCode.get(r.type_code) ?? new Set<string>();
      s.add(r.mill_id);
      millsByCode.set(r.type_code, s);
    }
    paperTypeFacets = ((typeRows ?? []) as any[]).map((t) => ({
      category: t.code,
      label: t.label_en ?? t.code,
      count: millsByCode.get(t.code)?.size ?? 0,
      parent: t.parent_id ? (idToCode.get(t.parent_id) ?? null) : null,
    }));
  }

  // Filler mineral-class facets (via app.v_filler_classes).
  const MINERAL_LABEL: Record<string, string> = {
    gcc: 'GCC', pcc: 'PCC', both: 'Both', kaolin: 'Kaolin',
    talc: 'Talc', lime: 'Lime', unknown: 'Unknown',
  };
  let mineralFacets: { category: string; label: string; count: number }[] = [];
  if (isFiller) {
    const { data } = await supabase
      .schema('app')
      .from('v_filler_classes' as never)
      .select('supplier_id, mineral_class');
    const counts = new Map<string, number>();
    for (const r of ((data ?? []) as any[])) {
      const k = (r.mineral_class ?? 'unknown') as string;
      counts.set(k, (counts.get(k) ?? 0) + 1);
    }
    mineralFacets = [...counts.entries()]
      .map(([code, count]) => ({ category: code, label: MINERAL_LABEL[code] ?? code, count }))
      .sort((a, b) => b.count - a.count);
  }

  let typeFilterIds: string[] | null = null;
  if (typeFilter) {
    if (isInvestor) {
      typeFilterIds = Object.keys(investorCatAll).filter((id) => investorCatAll[id]?.category === typeFilter);
    } else if (isPaperMill) {
      const { data } = await supabase
        .schema('app')
        .from('v_paper_mill_types' as never)
        .select('mill_id')
        .eq('type_code' as never, typeFilter);
      typeFilterIds = [...new Set(((data ?? []) as any[]).map((r) => r.mill_id as string))];
    } else if (isFiller) {
      const { data } = await supabase
        .schema('app')
        .from('v_filler_classes' as never)
        .select('supplier_id')
        .eq('mineral_class' as never, typeFilter);
      typeFilterIds = [...new Set(((data ?? []) as any[]).map((r) => r.supplier_id as string))];
    }
    if (typeFilterIds && typeFilterIds.length === 0) typeFilterIds = ['00000000-0000-0000-0000-000000000000'];
  }

  // Build the filtered base query fresh on each call so the DB-ordered path can
  // safely retry with a different .order() (sort fallback) without mutating an
  // already-spent query builder.
  const buildBaseQuery = () => {
    let q = supabase
      .schema('app')
      .from('parties' as never)
      .select(
        'id, party_name, status, country_code, city, region, website, interest_tags, created_at, entity_type_id',
        { count: 'exact' },
      )
      .eq('party_type_id' as never, partyTypeId)
      .is('deleted_at', null)
      .ilike('party_name' as never, searchQuery ? `%${searchQuery}%` : '%');
    if (countryFilter) q = q.eq('country_code' as never, countryFilter);
    if (typeFilterIds) q = q.in('id' as never, typeFilterIds);
    if (!showStubs)    q = q.or('notes.is.null,notes.not.ilike.Auto-created%');
    return q;
  };
  const query = buildBaseQuery();

  // We must process in memory (fetch the full candidate set, then slice) when
  // ordering or filtering by something the DB query can't do directly:
  //   - score sort   (score lives in app.account_scores, not app.parties)
  //   - investor type sort
  //   - grade filter (A/B/C, derived from the account score)
  // `isInvestor` forces the in-memory path so the always-on exclusion of
  // purely Fintech/SaaS investors (irrelevant to mbg) can be applied below.
  const needMemory = isInvestor || sortByScore || sortByType || gradeFilter !== '' || stageFilter !== '' || sectorFilter !== '' || priorityFilter !== '' || sortByPriority;

  let parties: PartyRow[];
  let totalCount: number;
  let scores: Record<string, AccountScore> = {};

  if (needMemory) {
    const { data: idData, count } = await query;
    const allParties = (idData ?? []) as unknown as PartyRow[];
    // scores for the full candidate set (needed to filter/sort by score)
    scores = await fetchAccountScoresMany(allParties.map((p) => p.id));

    let working = allParties;
    if (gradeFilter) {
      working = working.filter((p) => (scores[p.id]?.tier ?? 'C') === gradeFilter);
    }
    if (stageFilter) {
      working = working.filter((p) => (investorStageAll[p.id] ?? []).some((s) => s.code === stageFilter));
    }
    if (sectorFilter) {
      working = working.filter((p) => (investorSectorAll[p.id] ?? []).some((s) => s.code === sectorFilter));
    }
    if (priorityFilter) {
      working = working.filter((p) => (investorPriorityAll[p.id] ?? '') === priorityFilter);
    }
    // Always hide investors whose focus is purely Fintech/SaaS (no relevance to
    // mbg). An investor that also focuses on a relevant sector stays visible, and
    // investors with no tagged sector are kept (unknown focus). Skipped when the
    // user explicitly filters by one of these sectors, so that view still works.
    // Matches by sector code and by label, to be robust to code naming.
    const isFintechOrSaas = (s: { code: string; label: string }) => {
      const c = (s.code ?? '').toLowerCase();
      const l = (s.label ?? '').toLowerCase();
      return c === 'fintech' || c === 'software' || c === 'saas'
        || l.includes('fintech') || l.includes('saas');
    };
    const irrelevantSectorFilter =
      ['fintech', 'software', 'saas'].includes(sectorFilter.toLowerCase());
    if (isInvestor && !irrelevantSectorFilter) {
      working = working.filter((p) => {
        const secs = investorSectorAll[p.id] ?? [];
        if (secs.length === 0) return true;
        return !secs.every(isFintechOrSaas);
      });
    }

    // Null/locale-safe comparison key. localeCompare() on a null value throws,
    // which only surfaces when the primary key ties often (e.g. sorting
    // investors by city, where many rows share an empty city) so the party_name
    // tiebreaker runs constantly and hits any row with a null name. Coerce
    // everything through String(... ?? '') so the sort can never 500 the page.
    const nameKey = (p: PartyRow) => String(p.party_name ?? '');

    if (sortByScore) {
      working = [...working].sort((a, b) =>
        scoreAsc ? (scores[a.id]?.score ?? 0) - (scores[b.id]?.score ?? 0)
                 : (scores[b.id]?.score ?? 0) - (scores[a.id]?.score ?? 0));
    } else if (sortByType) {
      working = [...working].sort((a, b) => {
        const ca = investorCatAll[a.id]?.category ?? '';
        const cb = investorCatAll[b.id]?.category ?? '';
        const cmp = ca.localeCompare(cb);
        return (typeAsc ? cmp : -cmp) || nameKey(a).localeCompare(nameKey(b));
      });
    } else if (sortByPriority) {
      const rank: Record<string, number> = { high: 3, medium: 2, low: 1 };
      working = [...working].sort((a, b) => {
        const ra = rank[investorPriorityAll[a.id] ?? ''] ?? 0;
        const rb = rank[investorPriorityAll[b.id] ?? ''] ?? 0;
        const cmp = rb - ra; // high first by default
        return (priorityAsc ? -cmp : cmp) || nameKey(a).localeCompare(nameKey(b));
      });
    } else {
      // Honor the column sort (name/country/location/state) in memory too, so
      // Location/State/Country sorting still works while a sector/stage/grade
      // filter has forced the in-memory path. dbSort.col is one of:
      //   party_name | country_code | city | region  (all present on PartyRow)
      const col = dbSort.col as 'party_name' | 'country_code' | 'city' | 'region';
      working = [...working].sort((a, b) => {
        const av = String(a[col] ?? '').toLowerCase();
        const bv = String(b[col] ?? '').toLowerCase();
        const cmp = av.localeCompare(bv);
        return (dbSort.asc ? cmp : -cmp) || nameKey(a).localeCompare(nameKey(b));
      });
    }

    totalCount = (isInvestor || gradeFilter || stageFilter || sectorFilter || priorityFilter) ? working.length : (count ?? 0);
    parties = working.slice(from, to + 1);
  } else {
    // DB-ordered path. A sort column the DB cannot order by must never 500 the
    // whole directory -- degrade gracefully to name ordering, then to an
    // unordered fetch, instead of throwing.
    let res = await buildBaseQuery()
      .order(dbSort.col as never, { ascending: dbSort.asc, nullsFirst: false })
      .range(from, to);
    if (res.error && dbSort.col !== 'party_name') {
      res = await buildBaseQuery()
        .order('party_name' as never, { ascending: true, nullsFirst: false })
        .range(from, to);
    }
    if (res.error) {
      res = await buildBaseQuery().range(from, to);
    }
    totalCount = res.count ?? 0;
    parties = (res.data ?? []) as unknown as PartyRow[];
  }

  const partyIds = parties.map((p) => p.id);

  // Fetch distinct countries for filter bar
  const { data: countryData } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('country_code')
    .eq('party_type_id' as never, partyTypeId)
    .is('deleted_at' as never, null)
    .not('country_code' as never, 'is', null);
  const distinctCountries: string[] = [...new Set(
    ((countryData ?? []) as any[]).map((r) => r.country_code as string).filter(Boolean)
  )].sort();

  const [savedViews, supplyLinks, pageScores, countryNames] = await Promise.all([
    fetchSavedViews('party', module),
    showLinks ? fetchSupplyLinks(supabase, partyIds, linkRole) : Promise.resolve({} as Record<string, string[]>),
    // In memory mode `scores` already covers the page; in DB mode fetch just
    // the visible page's scores.
    needMemory ? Promise.resolve(scores) : fetchAccountScoresMany(partyIds),
    fetchCountryNames(),
  ]);
  scores = pageScores;

  // Org kind (entity_type) per visible party -> Type column + mobile sub-info.
  const entityTypeAll: Record<string, { en: string; ko: string }> = {};
  if (partyIds.length > 0) {
    const { data: etRows } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, entity_types(display_name_en, display_name_ko)')
      .in('id' as never, partyIds);
    for (const r of ((etRows ?? []) as any[])) {
      const et = Array.isArray(r.entity_types) ? r.entity_types[0] : r.entity_types;
      if (et) entityTypeAll[r.id] = { en: et.display_name_en, ko: et.display_name_ko };
    }
  }

  // Stats for link coverage (only filler/paper_mill)
  const linkedCount   = showLinks ? partyIds.filter(id => (supplyLinks[id]?.length ?? 0) > 0).length : 0;
  const unlinkedCount = showLinks ? partyIds.length - linkedCount : 0;

  // Header sort: build an href that preserves the current filters and toggles
  // the direction for the given column. `primary` is the value applied on first
  // click; clicking again (when already primary) flips to `secondary`.
  function buildSortHref(value: string): string {
    const qs = new URLSearchParams();
    if (countryFilter) qs.set('country', countryFilter);
    if (searchQuery) qs.set('q', searchQuery);
    if (pageSize !== DEFAULT_PAGE_SIZE) qs.set('perPage', String(pageSize));
    if (typeFilter) qs.set('type', typeFilter);
    if (gradeFilter) qs.set('grade', gradeFilter);
    if (stageFilter) qs.set('stage', stageFilter);
    if (sectorFilter) qs.set('sector', sectorFilter);
    if (priorityFilter) qs.set('priority', priorityFilter);
    if (value && value !== 'name_asc') qs.set('sort', value);
    const s = qs.toString();
    return `/${module}/parties${s ? `?${s}` : ''}`;
  }
  function sortHeader(primary: string, secondary: string) {
    const isPrimary = sortParam === primary;
    const isSecondary = sortParam === secondary;
    const next = isPrimary ? secondary : primary;
    // up when active-primary, down when active-secondary, up-down (dim) when
    // sortable but inactive -> the arrow always signals "this column sorts".
    const arrow = isPrimary ? '\u2191' : isSecondary ? '\u2193' : '\u2195';
    return { href: buildSortHref(next), arrow, active: isPrimary || isSecondary };
  }
  const hName     = sortHeader('name_asc', 'name_desc');
  const hScore    = sortHeader('score', 'score_asc');       // high first, then low
  const hCountry  = sortHeader('country_asc', 'country_desc');
  const hLocation = sortHeader('location_asc', 'location_desc');
  const hState    = sortHeader('state_asc', 'state_desc');
  const hType     = sortHeader('type_asc', 'type_desc');
  const hEntityType = sortHeader('etype_asc', 'etype_desc');
  const hPriority = sortHeader('priority', 'priority_asc');

  return (
    <div className="px-4 sm:px-6 py-4 sm:py-6 space-y-4 sm:space-y-6 h-full flex flex-col">

      {/* Header */}
      <div className="flex flex-col gap-2 sm:gap-0 sm:flex-row sm:items-start sm:justify-between">
        <div className="flex flex-col gap-1.5">
          <h1 className="text-xl sm:text-2xl font-bold">{MODULE_LABELS[module]}</h1>
          <p className="text-sm text-muted-foreground flex items-center gap-3">
            <span>{totalCount} parties</span>
            {showLinks && unlinkedCount > 0 && (
              <span className="inline-flex items-center gap-1 text-amber-600 font-medium text-xs">
                <AlertTriangle className="h-3.5 w-3.5" />
                {unlinkedCount} unlinked ??sales targets
              </span>
            )}
            {gradeFilter && (
              <span className="text-xs text-muted-foreground/70">??Tier {gradeFilter} only</span>
            )}
            {sortByScore && (
              <span className="text-xs text-muted-foreground/70">??Sorted by score</span>
            )}
          </p>
          <PartiesFilterBar
            countries={distinctCountries}
            countryNames={countryNames}
            country={countryFilter}
            q={searchQuery}
            sort={sortParam}
            grade={gradeFilter}
            priority={priorityFilter}
            showPriority={isInvestor}
            types={isInvestor ? investorFacets : isPaperMill ? paperTypeFacets : isFiller ? mineralFacets : undefined}
            type={typeFilter}
            typeLabel={isPaperMill ? 'Paper' : isFiller ? 'Mineral' : undefined}
            stages={isInvestor ? stageFacets : undefined}
            stage={stageFilter}
            sectors={isInvestor ? sectorFacets : undefined}
            sector={sectorFilter}
          />
        </div>
        <div className="flex items-center gap-2 flex-wrap justify-end">
          <SavedViewsDropdown views={savedViews} entityType="party" partyType={module} />
          <Button asChild size="sm">
            <Link href={`/${module}/parties/new`}>
              <Plus className="h-4 w-4" />
              <span className="hidden sm:inline">New Party</span>
              <span className="sm:hidden">Add</span>
            </Link>
          </Button>
        </div>
      </div>

      {/* Table + Pagination */}
      {totalCount === 0 ? (
        <Card className="flex-1">
          <CardContent className="py-16 text-center">
            <p className="text-muted-foreground mb-4">
              {gradeFilter ? `No Tier ${gradeFilter} parties.` : 'No parties registered.'}
            </p>
            <Button asChild>
              <Link href={`/${module}/parties/new`}>
                <Plus className="h-4 w-4" />Add first party
              </Link>
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Card className="flex-1 flex flex-col">
          <div className="overflow-x-auto flex-1">
            <table className="w-full min-w-[520px]">
              <thead className="border-b bg-indigo-50/80 dark:bg-indigo-950/30">
                <tr className="text-left text-xs uppercase tracking-wide font-semibold text-indigo-700/80 dark:text-indigo-300">
                  <th className="px-4 py-3 font-medium whitespace-nowrap">
                    <Link href={hName.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hName.active ? 'text-foreground' : ''}`}>
                      Name <span className={`text-[10px] ${hName.active ? '' : 'opacity-40'}`}>{hName.arrow}</span>
                    </Link>
                  </th>
                  {showEntityType && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                      <Link href={hEntityType.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hEntityType.active ? 'text-foreground' : ''}`}>
                        Type <span className={`text-[10px] ${hEntityType.active ? '' : 'opacity-40'}`}>{hEntityType.arrow}</span>
                      </Link>
                    </th>
                  )}
                  {showLinks ? (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell text-orange-600">
                      {linkLabel}
                    </th>
                  ) : (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell">Tags</th>
                  )}
                  {isInvestor && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap">
                      <Link href={hPriority.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hPriority.active ? 'text-foreground' : ''}`}>
                        Priority <span className={`text-[10px] ${hPriority.active ? '' : 'opacity-40'}`}>{hPriority.arrow}</span>
                      </Link>
                    </th>
                  )}
                  <th className="px-3 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                    <Link href={hCountry.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hCountry.active ? 'text-foreground' : ''}`}>
                      Country <span className={`text-[10px] ${hCountry.active ? '' : 'opacity-40'}`}>{hCountry.arrow}</span>
                    </Link>
                  </th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                    <Link href={hLocation.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hLocation.active ? 'text-foreground' : ''}`}>
                      Location <span className={`text-[10px] ${hLocation.active ? '' : 'opacity-40'}`}>{hLocation.arrow}</span>
                    </Link>
                  </th>
                  {(isInvestor || showEntityType) && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell">
                      <Link href={hState.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hState.active ? 'text-foreground' : ''}`}>
                        State <span className={`text-[10px] ${hState.active ? '' : 'opacity-40'}`}>{hState.arrow}</span>
                      </Link>
                    </th>
                  )}
                  {isInvestor && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">
                      <Link href={hType.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hType.active ? 'text-foreground' : ''}`}>
                        Type <span className={`text-[10px] ${hType.active ? '' : 'opacity-40'}`}>{hType.arrow}</span>
                      </Link>
                    </th>
                  )}
                  {isInvestor && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Stage</th>
                  )}
                  {!isInvestor && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap">Level / Tier</th>
                  )}
                  <th className="px-3 py-3 font-medium whitespace-nowrap w-20 text-center">
                    <Link href={hScore.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hScore.active ? 'text-foreground' : ''}`}>
                      Score <span className={`text-[10px] ${hScore.active ? '' : 'opacity-40'}`}>{hScore.arrow}</span>
                    </Link>
                  </th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell w-16 text-center">Web</th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Status</th>
                </tr>
              </thead>
              <tbody>
                {parties.map((p) => {
                  const location  = p.city ?? '';
                  // interest_tags can arrive as a non-array (jsonb object/scalar)
                  // for some rows; coerce so .slice()/.map() can't 500 the page.
                  const tags      = Array.isArray(p.interest_tags) ? p.interest_tags : [];
                  const level     = p.party_level as PartyLevel | null;
                  const acc       = scores[p.id];
                  const linked    = Array.isArray(supplyLinks[p.id]) ? supplyLinks[p.id]! : [];
                  const hasLinks  = linked.length > 0;
                  const LevelIcon = level === 'group_hq' ? Building2
                    : level === 'country_entity' ? Layers3
                    : level === 'plant' ? Factory : null;

                  return (
                    <tr
                      key={p.id}
                      className={`border-b hover:bg-muted/20 transition ${showLinks && !hasLinks ? 'bg-amber-50/30 dark:bg-amber-950/10' : ''}`}
                    >
                      <td className="px-4 py-3">
                        <Link href={`/${module}/parties/${p.id}`} className="font-medium hover:underline line-clamp-1">
                          {p.party_name}
                        </Link>
                        {showEntityType && (
                          <div className="mt-1 flex flex-col gap-0.5 text-xs text-muted-foreground sm:hidden">
                            {entityTypeAll[p.id] && (
                              <span className="font-medium text-slate-700 dark:text-slate-200">{entityTypeAll[p.id]!.ko}</span>
                            )}
                            <span>
                              {[
                                p.country_code ? (countryNames[p.country_code] ?? p.country_code) : null,
                                location || null,
                                p.region ? (US_STATES[p.region] ?? p.region) : null,
                              ].filter(Boolean).join(' · ') || '-'}
                            </span>
                          </div>
                        )}
                        {showLinks && (
                          <div className="mt-1 flex flex-col gap-1 md:hidden">
                            <div className="flex flex-wrap items-center gap-1">
                              <span className="text-[10px] font-medium uppercase tracking-wide text-orange-600">
                                {linkLabel}
                              </span>
                              {hasLinks ? (
                                <>
                                  {linked.slice(0, 2).map((name) => (
                                    <span key={name} className="inline-flex px-1.5 py-0.5 text-xs bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 rounded max-w-[180px] truncate">
                                      {name}
                                    </span>
                                  ))}
                                  {linked.length > 2 && (
                                    <span className="text-xs text-emerald-600 font-medium whitespace-nowrap">
                                      +{linked.length - 2}
                                    </span>
                                  )}
                                </>
                              ) : (
                                <span className="inline-flex items-center gap-1 px-1.5 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 rounded-full whitespace-nowrap">
                                  <AlertTriangle className="h-3 w-3" />
                                  Unlinked
                                </span>
                              )}
                            </div>
                            <div className="sm:hidden text-xs text-muted-foreground">
                              {p.country_code ? (countryNames[p.country_code] ?? p.country_code) : '-'}
                            </div>
                          </div>
                        )}
                      </td>
                      {showEntityType && (
                        <td className="px-4 py-3 text-sm hidden sm:table-cell whitespace-nowrap text-muted-foreground">
                          {entityTypeAll[p.id]?.ko ?? '-'}
                        </td>
                      )}
                      {showLinks && (
                        <td className="px-4 py-3 hidden md:table-cell max-w-[260px]">
                          {hasLinks ? (
                            <div className="flex flex-wrap gap-1">
                              {linked.slice(0, 2).map((name) => (
                                <span key={name} className="inline-flex px-1.5 py-0.5 text-xs bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 rounded whitespace-nowrap max-w-[120px] truncate">
                                  {name}
                                </span>
                              ))}
                              {linked.length > 2 && (
                                <span className="inline-flex px-1.5 py-0.5 text-xs text-emerald-600 font-medium whitespace-nowrap">
                                  +{linked.length - 2}
                                </span>
                              )}
                            </div>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 rounded-full whitespace-nowrap">
                              <AlertTriangle className="h-3 w-3" />
                              {'Unlinked'}
                            </span>
                          )}
                        </td>
                      )}
                      {!showLinks && (
                        <td className="px-4 py-3 hidden md:table-cell">
                          <div className="flex flex-wrap gap-1 max-w-[280px]">
                            {tags.slice(0, 2).map((tag) => (
                              <span key={tag} className="inline-flex px-1.5 py-0.5 text-xs bg-muted rounded whitespace-nowrap">
                                {tag}
                              </span>
                            ))}
                            {tags.length > 2 && (
                              <span className="inline-flex px-1 py-0.5 text-xs text-muted-foreground whitespace-nowrap">
                                +{tags.length - 2}
                              </span>
                            )}
                          </div>
                        </td>
                      )}
                      {isInvestor && (
                        <td className="px-4 py-3">
                          {(() => {
                            const pr = investorPriorityAll[p.id];
                            if (!pr) return <span className="text-sm text-muted-foreground">-</span>;
                            const cls = pr === 'high'
                              ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300'
                              : pr === 'medium'
                                ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'
                                : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300';
                            const label = pr === 'high' ? 'High' : pr === 'medium' ? 'Medium' : 'Low';
                            return (
                              <span className={`inline-flex px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap ${cls}`}>
                                {label}
                              </span>
                            );
                          })()}
                        </td>
                      )}
                      <td className="px-3 py-3 text-sm hidden sm:table-cell whitespace-nowrap text-muted-foreground">
                        {p.country_code ? (countryNames[p.country_code] ?? p.country_code) : '-'}
                      </td>
                      <td className="px-4 py-3 text-sm hidden sm:table-cell whitespace-nowrap">
                        {location || '-'}
                      </td>
                      {(isInvestor || showEntityType) && (
                        <td className="px-4 py-3 text-sm hidden md:table-cell whitespace-nowrap">
                          {p.region ? (US_STATES[p.region] ?? p.region) : '-'}
                        </td>
                      )}
                      {isInvestor && (
                        <td className="px-4 py-3 hidden lg:table-cell">
                          {investorCatAll[p.id]?.type_name ? (
                            <span className="inline-flex px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300">
                              {investorCatAll[p.id]!.type_name}
                            </span>
                          ) : (
                            <span className="text-sm text-muted-foreground">-</span>
                          )}
                        </td>
                      )}
                      {isInvestor && (
                        <td className="px-4 py-3 hidden lg:table-cell">
                          {(investorStageAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1">
                              {(investorStageAll[p.id] ?? []).map((s) => (
                                <span key={s.code} className="inline-flex px-1.5 py-0.5 text-[10px] font-medium rounded whitespace-nowrap bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300">
                                  {s.label}
                                </span>
                              ))}
                            </div>
                          ) : (
                            <span className="text-sm text-muted-foreground">-</span>
                          )}
                        </td>
                      )}
                      {!isInvestor && (
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-1 flex-wrap">
                            {level && LevelIcon && (
                              <span className={`inline-flex items-center gap-1 px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap ${PARTY_LEVEL_COLORS[level]}`}>
                                <LevelIcon className="h-3 w-3" />
                                {PARTY_LEVEL_LABELS[level]}
                              </span>
                            )}
                            {p.tier ? (
                              <span className={`inline-flex px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap ${TIER_COLORS[p.tier]}`}>
                                {TIER_LABELS[p.tier]}
                              </span>
                            ) : (!level && <span className="text-sm text-muted-foreground">-</span>)}
                          </div>
                        </td>
                      )}
                      <td className="px-3 py-3 text-center">
                        <AccountScoreBadge score={acc?.score ?? null} tier={acc?.tier ?? null} size="sm" />
                      </td>
                      <td className="px-4 py-3 hidden lg:table-cell text-center">
                        {p.website ? (
                          <a href={p.website} target="_blank" rel="noopener noreferrer"
                            className="text-primary hover:text-primary/70 inline-flex items-center justify-center"
                            title={p.website}>
                            <ExternalLink className="h-4 w-4" />
                          </a>
                        ) : (
                          <span className="text-muted-foreground text-sm">-</span>
                        )}
                      </td>
                      <td className="px-4 py-3 hidden lg:table-cell">
                        {p.status ? (
                          <span className="inline-flex px-1.5 py-0.5 text-xs font-medium rounded-full whitespace-nowrap bg-muted text-muted-foreground capitalize">
                            {String(p.status).replace(/_/g, ' ')}
                          </span>
                        ) : (
                          <span className="text-sm text-muted-foreground">-</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <PaginationBar
            totalCount={totalCount}
            pageSize={pageSize}
            currentPage={page}
            pageSizeOptions={[...PAGE_SIZE_OPTIONS]}
          />
        </Card>
      )}
    </div>
  );
}
