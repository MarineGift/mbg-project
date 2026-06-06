// src/app/api/supply-links/candidates/route.ts
// Link candidates for the supply-links picker.
//   scope=country (default): same country_code as the party
//   scope=all: worldwide (any country)
// For a paper_mill party -> filler_supplier candidates; for a filler -> mills.
// Already-linked parties and self are excluded.
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const partyId = searchParams.get('partyId');
  const role    = searchParams.get('role');
  const scope   = searchParams.get('scope') === 'all' ? 'all' : 'country';
  if (!partyId) return NextResponse.json({ country: null, scope, candidates: [] }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const isFillerRole = role === 'filler_supplier';
  const linkedCode = isFillerRole ? 'paper_mill' : 'filler_supplier';
  const selfCol  = isFillerRole ? 'filler_party_id' : 'mill_party_id';
  const otherCol = isFillerRole ? 'mill_party_id'   : 'filler_party_id';

  const { data: selfRow } = await supabase.schema('app')
    .from('parties' as never)
    .select('country_code')
    .eq('id' as never, partyId)
    .maybeSingle();
  const country = (selfRow as { country_code?: string | null } | null)?.country_code ?? null;
  if (scope === 'country' && !country) return NextResponse.json({ country: null, scope, candidates: [] });

  const { data: ptRows } = await supabase.schema('app')
    .from('party_types' as never)
    .select('id, code');
  const linkedTypeId = ((ptRows ?? []) as { id: number; code: string }[])
    .find(r => r.code === linkedCode)?.id;
  if (linkedTypeId === undefined) return NextResponse.json({ country, scope, candidates: [] });

  const { data: linkRows } = await supabase.schema('app')
    .from('party_supply_links' as never)
    .select(`${otherCol}`)
    .eq(selfCol as never, partyId)
    .is('deleted_at' as never, null);
  const linkedSet = new Set(((linkRows ?? []) as any[]).map(r => r[otherCol] as string));

  let q = supabase.schema('app')
    .from('parties' as never)
    .select('id, party_name, country_code')
    .eq('party_type_id' as never, linkedTypeId)
    .is('deleted_at' as never, null);
  if (scope === 'country') q = q.eq('country_code' as never, country as never);
  const { data: candRows, error } = await q
    .order('party_name' as never, { ascending: true })
    .limit(1000);
  if (error) return NextResponse.json({ country, scope, candidates: [] }, { status: 500 });

  const candidates = ((candRows ?? []) as any[])
    .filter(r => r.id !== partyId && !linkedSet.has(r.id))
    .map(r => ({ id: r.id as string, name: r.party_name as string, country_code: r.country_code as string | null }));

  return NextResponse.json({ country, scope, candidates });
}
