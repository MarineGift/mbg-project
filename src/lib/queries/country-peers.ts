import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface CountryPeer {
  id: string;
  name: string;
  module: string;
  country: string | null;   // from country_code column
  status: string | null;
  tier: string | null;
  tags: string[] | null;
  description: string | null;
}

export async function getCountryPeers(
  countryCode: string,
  module: 'paper_mill' | 'filler_supplier',
  excludeId: string,
  limit = 50
): Promise<CountryPeer[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('id, name, party_type, country_code, status, tier, industry_tags, notes')
    .eq('party_type' as never, module)
    .eq('country_code' as never, countryCode)
    .neq('id' as never, excludeId)
    .is('deleted_at' as never, null)
    .order('name')
    .limit(limit);

  if (error) {
    console.error('[getCountryPeers]', error.message, { countryCode, module });
    return [];
  }

  return ((data ?? []) as any[]).map((row) => ({
    id: row.id,
    name: row.name,
    module: row.party_type,
    country: row.country_code ?? null,
    status: row.status ?? null,
    tier: row.tier ?? null,
    tags: row.industry_tags ?? null,
    description: row.notes ?? null,
  }));
}