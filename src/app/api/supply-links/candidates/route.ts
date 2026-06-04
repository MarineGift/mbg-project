// src/app/api/supply-links/candidates/route.ts
// Returns same-country link candidates for the supply-links picker.
// For a paper_mill party -> filler_supplier parties in the same country.
// For a filler_supplier party -> paper_mill parties in the same country.
// Already-linked parties are excluded.
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const partyId = searchParams.get('partyId');
  const role    = searchParams.get('role'); // self role
  if (!partyId) return NextResponse.json({ country: null, candidates: [] }, { status: 400 });

  const supabase = await createSupabaseServerClient();
  const isFillerRole = role === 'filler_supplier';
  const linkedCode = isFillerRole ? 'paper_mill' : 'filler_supplier';
  const selfCol  = isFillerRole ? 'filler_party_id' : 'mill_party_id';
  const otherCol = isFillerRole ? 'mill_party_id'   : 'filler_party_id';

  // self party country
  const { data: selfRow } = await supabase.schema('app')
    .from('parties' as never)
    .select('country_code')
    .eq('id' as never, partyId)
    .maybeSingle();
  const country = (selfRow as { country_code?: string | null } | null)?.country_code ?? null;
  if (!country) return NextResponse.json({ country: null, candidates: [] });

  // linked party_type_id
  const { data: ptRows } = await supabase.schema('app')
    .from('party_types' as never)
    .select('id, code');
  const linkedTypeId = ((ptRows ?? []) as { id: number; code: string }[])
    .find(r => r.code === linkedCode)?.id;
  if (linkedTypeId === undefined) return NextResponse.json({ country, candidates: [] });

  // already-linked ids to exclude
  const { data: linkRows } = await supabase.schema('app')
    .from('party_supply_links' as never)
    .select(`${otherCol}`)
    .eq(selfCol as never, partyId)
    .is('deleted_at' as never, null);
  const linkedSet = new Set(((linkRows ?? []) as any[]).map(r => r[otherCol] as string));

  // same-country candidates of the linked type
  const { data: candRows, error } = await supabase.schema('app')
    .from('parties' as never)
    .select('id, party_name, country_code')
    .eq('party_type_id' as never, linkedTypeId)
    .eq('country_code' as never, country)
    .is('deleted_at' as never, null)
    .order('party_name' as never, { ascending: true })
    .limit(500);
  if (error) return NextResponse.json({ country, candidates: [] }, { status: 500 });

  const candidates = ((candRows ?? []) as any[])
    .filter(r => r.id !== partyId && !linkedSet.has(r.id))
    .map(r => ({ id: r.id as string, name: r.party_name as string, country_code: r.country_code as string | null }));

  return NextResponse.json({ country, candidates });
}
