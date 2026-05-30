// src/app/api/parties/search/route.ts
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const q      = searchParams.get('q') ?? '';
  const module = searchParams.get('partyType') ?? 'paper_mill';
  const limit  = parseInt(searchParams.get('limit') ?? '10');

  const supabase = await createSupabaseServerClient();

  // resolve party_type code -> id (parties has party_type_id FK, not a text column)
  const { data: ptRow } = await supabase.schema('app')
    .from('party_types' as never)
    .select('id, code')
    .eq('code' as never, module)
    .maybeSingle();
  const partyTypeId = (ptRow as { id?: number } | null)?.id ?? null;
  if (partyTypeId == null) return NextResponse.json([]);

  const { data, error } = await supabase.schema('app')
    .from('parties' as never)
    .select('id, party_name, country_code, party_type_id')
    .eq('party_type_id' as never, partyTypeId as never)
    .ilike('party_name' as never, `%${q}%`)
    .is('deleted_at' as never, null)
    .order('party_name' as never)
    .limit(limit);

  if (error) return NextResponse.json([], { status: 500 });

  const result = ((data ?? []) as any[]).map(row => ({
    id:           row.id,
    name:         row.party_name ?? '',
    country_code: row.country_code ?? null,
    module:       module,
  }));
  return NextResponse.json(result);
}
