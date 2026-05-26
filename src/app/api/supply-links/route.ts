// src/app/api/supply-links/route.ts
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const partyId = searchParams.get('partyId');
  const role    = searchParams.get('role'); // 'filler_supplier' | 'paper_mill'
  if (!partyId) return NextResponse.json([], { status: 400 });

  const supabase = await createSupabaseServerClient();
  const isFillerRole = role === 'filler_supplier';
  const selfCol   = isFillerRole ? 'filler_party_id' : 'mill_party_id';
  const linkedCol = isFillerRole ? 'mill_party_id'   : 'filler_party_id';

  const { data, error } = await supabase.schema('app')
    .from('party_supply_links' as never)
    .select(`id, link_type, product_grade, volume_estimate, notes,
      linked_filler:filler_party_id(id,name,module,country_code,tier),
      linked_mill:mill_party_id(id,name,module,country_code,tier)`)
    .eq(selfCol as never, partyId);

  if (error) return NextResponse.json([], { status: 500 });

  const result = ((data ?? []) as any[]).map(row => {
    const linked = isFillerRole ? row.linked_mill : row.linked_filler;
    return {
      id:             row.id,
      linked_id:      linked?.id ?? '',
      linked_name:    linked?.name ?? '',
      linked_module:  linked?.module ?? '',
      linked_country: linked?.country_code ?? null,
      linked_tier:    linked?.tier ?? null,
      link_type:    row.link_type,
      product_grade:  row.product_grade,
      volume_estimate:     row.volume_estimate,
      notes:          row.notes,
    };
  });
  return NextResponse.json(result);
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.schema('app')
    .from('party_supply_links' as never)
    .insert([body] as never)
    .select()
    .single();
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(data, { status: 201 });
}
