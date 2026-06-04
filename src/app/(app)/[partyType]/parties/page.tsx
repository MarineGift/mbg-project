/**
 * app/(app)/[partyType]/parties/page.tsx
 * Phase 8 + responsive + Phase 20d (lead score) + pagination + Phase 20f (saved views)
 * Phase 23: supply links column (connected mills / fillers)
 */

import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Plus, ExternalLink, Building2, Factory, Layers3, AlertTriangle } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { requireAuthOrRedirect } from '@/lib/auth';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { LeadScoreBadge } from '@/components/common/lead-score-badge';
import { PaginationBar } from '@/components/common/pagination-bar';
import { SavedViewsDropdown } from '@/components/common/saved-views-dropdown';
import { fetchLeadScoresMany } from '@/lib/queries/lead-score';
import { fetchSavedViews } from '@/lib/queries/saved-views';
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
  'investor', 'paper_mill', 'partner', 'customer', 'filler_supplier', 'buyer', 'government_grant',
] as const;

const MODULE_LABELS: Record<PartyTypeCode, string> = {
  investor:       'Investors',
  paper_mill:     'Paper Mills',
  partner:        'Partners',
  customer:       'Customers',
  filler_supplier:         'Filler Suppliers',
  buyer:                   'Buyers',
  government_grant:        'Government Grants',
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

interface PartyRow {
  id: string; party_name: string; tier: PartyTier | null; status: PartyStatus;
  party_level: PartyLevel | null; parent_party_id: string | null;
  country_code: string | null; city: string | null;
  industry_tags: string[] | null; website: string | null; created_at: string;
}

interface PageProps {
  params: Promise<{ partyType: string }>;
  searchParams: Promise<{
    include_stubs?: string; sort?: string; page?: string; perPage?: string; q?: string;
  }>;
}

/** Fetch supply link names for a set of party IDs.
 *  Returns map: partyId → linked party names[] */
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

    if (error) return {}; // table may not exist yet → silent fallback

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

  const showStubs   = sp.include_stubs === '1';
  const sortParam   = sp.sort ?? 'name_asc';
  const sortByScore = sortParam === 'score' || sortParam === 'score_asc';
  const scoreAsc    = sortParam === 'score_asc';
  // DB-orderable sorts (everything except score, which is computed in JS).
  const DB_SORT: Record<string, { col: string; asc: boolean }> = {
    name_asc:      { col: 'party_name',   asc: true  },
    name_desc:     { col: 'party_name',   asc: false },
    country_asc:   { col: 'country_code', asc: true  },
    country_desc:  { col: 'country_code', asc: false },
    location_asc:  { col: 'city',         asc: true  },
    location_desc: { col: 'city',         asc: false },
  };
  const dbSort = DB_SORT[sortParam] ?? { col: 'party_name', asc: true };
  const page        = Math.max(1, Number(sp.page ?? 1));
  const pageSize    = (PAGE_SIZE_OPTIONS as readonly number[]).includes(Number(sp.perPage))
    ? Number(sp.perPage) : DEFAULT_PAGE_SIZE;
  const from = (page - 1) * pageSize;
  const to   = from + pageSize - 1;

  if (!(PHASE_1_MODULES as readonly string[]).includes(moduleParam)) notFound();
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

  let query = supabase
    .schema('app')
    .from('parties' as never)
    .select(
      'id, party_name, status, country_code, city, website, created_at',
      { count: 'exact' },
    )
    .eq('party_type_id' as never, partyTypeId)
    .is('deleted_at', null)
    .ilike('party_name' as never, searchQuery ? `%${searchQuery}%` : '%');

  if (countryFilter) {
    query = query.eq('country_code' as never, countryFilter);
  }

  if (!showStubs) {
    query = query.or('notes.is.null,notes.not.ilike.Auto-created%');
  }

  let parties: PartyRow[];
  let totalCount: number;

  if (sortByScore) {
    const { data: idData, count } = await query;
    totalCount = count ?? 0;
    const allParties = (idData ?? []) as unknown as PartyRow[];
    const scores = await fetchLeadScoresMany(allParties.map((p) => p.id));
    const sorted = [...allParties].sort((a, b) =>
      scoreAsc ? (scores[a.id] ?? 0) - (scores[b.id] ?? 0)
               : (scores[b.id] ?? 0) - (scores[a.id] ?? 0));
    parties = sorted.slice(from, to + 1);
  } else {
    const { data, error, count } = await query
      .order(dbSort.col as never, { ascending: dbSort.asc, nullsFirst: false })
      .range(from, to);
    if (error) throw error;
    totalCount = count ?? 0;
    parties = (data ?? []) as unknown as PartyRow[];
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

  

  const [scores, savedViews, supplyLinks] = await Promise.all([
    fetchLeadScoresMany(partyIds),
    fetchSavedViews('party', module),
    showLinks ? fetchSupplyLinks(supabase, partyIds, linkRole) : Promise.resolve({} as Record<string, string[]>),
  ]);

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
    if (value && value !== 'name_asc') qs.set('sort', value);
    const s = qs.toString();
    return `/${module}/parties${s ? `?${s}` : ''}`;
  }
  function sortHeader(primary: string, secondary: string) {
    const isPrimary = sortParam === primary;
    const isSecondary = sortParam === secondary;
    const next = isPrimary ? secondary : primary;
    const arrow = isPrimary ? '\u2191' : isSecondary ? '\u2193' : '';
    return { href: buildSortHref(next), arrow, active: isPrimary || isSecondary };
  }
  const hName     = sortHeader('name_asc', 'name_desc');
  const hScore    = sortHeader('score', 'score_asc');       // high first, then low
  const hCountry  = sortHeader('country_asc', 'country_desc');
  const hLocation = sortHeader('location_asc', 'location_desc');

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
                {unlinkedCount} unlinked — sales targets
              </span>
            )}
            {sortByScore && (
              <span className="text-xs text-muted-foreground/70">· Sorted by score</span>
            )}
          </p>
          <PartiesFilterBar
            countries={distinctCountries}
            country={countryFilter}
            q={searchQuery}
            sort={sortParam}
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
            <p className="text-muted-foreground mb-4">No parties registered.</p>
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
              <thead className="border-b bg-muted/30">
                <tr className="text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3 font-medium whitespace-nowrap">
                    <Link href={hName.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hName.active ? 'text-foreground' : ''}`}>
                      Name {hName.arrow && <span className="text-[10px]">{hName.arrow}</span>}
                    </Link>
                  </th>
                  <th className="px-3 py-3 font-medium whitespace-nowrap w-16 text-center">
                    <Link href={hScore.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hScore.active ? 'text-foreground' : ''}`}>
                      Score {hScore.arrow && <span className="text-[10px]">{hScore.arrow}</span>}
                    </Link>
                  </th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap">Level / Tier</th>
                  <th className="px-3 py-3 font-medium whitespace-nowrap hidden sm:table-cell w-16">
                    <Link href={hCountry.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hCountry.active ? 'text-foreground' : ''}`}>
                      Country {hCountry.arrow && <span className="text-[10px]">{hCountry.arrow}</span>}
                    </Link>
                  </th>
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                    <Link href={hLocation.href} className={`inline-flex items-center gap-1 hover:text-foreground ${hLocation.active ? 'text-foreground' : ''}`}>
                      Location {hLocation.arrow && <span className="text-[10px]">{hLocation.arrow}</span>}
                    </Link>
                  </th>
                  {showLinks && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell text-orange-600">
                      {linkLabel}
                    </th>
                  )}
                  {!showLinks && (
                    <th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell">Tags</th>
                  )}
                  <th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell w-16 text-center">Web</th>
                </tr>
              </thead>
              <tbody>
                {parties.map((p) => {
                  const location  = p.city ?? '';
                  const tags      = p.industry_tags ?? [];
                  const level     = p.party_level as PartyLevel | null;
                  const score     = scores[p.id] ?? 0;
                  const linked    = supplyLinks[p.id] ?? [];
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
                      </td>
                      <td className="px-3 py-3 text-center">
                        <LeadScoreBadge score={score} size="sm" />
                      </td>
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
                      <td className="px-3 py-3 text-sm hidden sm:table-cell whitespace-nowrap text-muted-foreground">
                        {p.country_code ?? '-'}
                      </td>
                      <td className="px-4 py-3 text-sm hidden sm:table-cell whitespace-nowrap">
                        {location || '-'}
                      </td>
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
                              {'\ubbf8\uc5f0\uacb0'}
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