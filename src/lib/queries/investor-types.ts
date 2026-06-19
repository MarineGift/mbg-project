/**
 * lib/queries/investor-types.ts
 *
 * Lookup options for the investor "type" (app.investor_types) used by the
 * Party edit/create form. Global lookup table (no org scoping), mirroring how
 * party-detail.ts resolves investor_type_id -> (code, display_name).
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface InvestorTypeOption {
  code: string;
  name: string;
}

export async function fetchInvestorTypeOptions(): Promise<InvestorTypeOption[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('investor_types' as never)
    .select('code, display_name')
    .order('display_name' as never, { ascending: true });

  if (error || !data) return [];

  return (data as Array<{ code: string; display_name: string | null }>)
    .filter((r) => !!r.code)
    .map((r) => ({ code: r.code, name: r.display_name ?? r.code }));
}
