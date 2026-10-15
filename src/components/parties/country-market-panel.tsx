/**
 * components/parties/country-market-panel.tsx
 *
 * Country market overview for paper_mill and filler_supplier parties.
 * - Reads app.country_markets (one row per country_code, organization-scoped).
 * - Links to the URM databases through app.parties.country_code: lists the
 *   country's paper mills and filler suppliers, with the outreach priority
 *   from each profile's extra_data.plant.priority.
 * The client part renders a "Country market" button that expands the overview.
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import {
  CountryMarketPanelClient,
  type CountryMarket,
  type MarketParty,
} from './country-market-panel-client';

interface Props {
  partyId: string;
  country: string | null;
}

type Json = Record<string, unknown>;

const MODULES = ['paper_mill', 'filler_supplier'] as const;

export async function CountryMarketPanel({ partyId, country }: Props) {
  if (!country) return null;
  const code = country.trim().toUpperCase();
  const supabase = await createSupabaseServerClient();

  const [marketRes, typesRes] = await Promise.all([
    supabase
      .schema('app')
      .from('country_markets' as never)
      .select('country_code, country_name, priority, headline, summary, sections, checked_at, updated_at')
      .eq('country_code' as never, code)
      .is('deleted_at' as never, null)
      .maybeSingle(),
    supabase
      .schema('app')
      .from('party_types' as never)
      .select('id, code')
      .in('code' as never, MODULES as unknown as string[]),
  ]);

  const market = marketRes.data as unknown as CountryMarket | null;
  if (!market) return null;

  const types = ((typesRes.data ?? []) as unknown as { id: string | number; code: string }[]);
  const codeById = new Map(types.map((t) => [String(t.id), t.code]));

  let mills: MarketParty[] = [];
  let fillers: MarketParty[] = [];

  if (types.length > 0) {
    const { data: partyRows } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, party_name, party_type_id, city')
      .eq('country_code' as never, code)
      .in('party_type_id' as never, types.map((t) => t.id) as never)
      .is('deleted_at' as never, null)
      .order('party_name' as never)
      .limit(400);

    const rows = ((partyRows ?? []) as unknown as {
      id: string; party_name: string; party_type_id: string | number; city: string | null;
    }[]);

    const millIds = rows.filter((r) => codeById.get(String(r.party_type_id)) === 'paper_mill').map((r) => r.id);
    const fillerIds = rows.filter((r) => codeById.get(String(r.party_type_id)) === 'filler_supplier').map((r) => r.id);

    const priorityOf = new Map<string, number>();
    const readPriorities = async (table: string, ids: string[]) => {
      if (ids.length === 0) return;
      const { data } = await supabase
        .schema('app')
        .from(table as never)
        .select('party_id, extra_data')
        .in('party_id' as never, ids as never);
      for (const r of ((data ?? []) as unknown as { party_id: string; extra_data: Json | null }[])) {
        const plant = (r.extra_data ?? {}).plant as Json | undefined;
        const p = plant?.priority;
        if (typeof p === 'number') priorityOf.set(r.party_id, p);
      }
    };
    await Promise.all([
      readPriorities('paper_mill_profile', millIds),
      readPriorities('filler_supplier_profile', fillerIds),
    ]);

    const toItem = (r: (typeof rows)[number]): MarketParty => ({
      id: r.id,
      name: r.party_name,
      city: r.city,
      module: codeById.get(String(r.party_type_id)) ?? 'paper_mill',
      priority: priorityOf.get(r.id) ?? null,
    });
    const byPriority = (a: MarketParty, b: MarketParty) =>
      (a.priority ?? 999) - (b.priority ?? 999) || a.name.localeCompare(b.name);

    mills = rows.filter((r) => millIds.includes(r.id)).map(toItem).sort(byPriority);
    fillers = rows.filter((r) => fillerIds.includes(r.id)).map(toItem).sort(byPriority);
  }

  return (
    <CountryMarketPanelClient
      partyId={partyId}
      market={market}
      mills={mills}
      fillers={fillers}
    />
  );
}
