// src/app/api/parties/search/route.ts
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const q      = searchParams.get('q') ?? '';
  const module = searchParams.get('module') ?? 'paper_mill';
  const limit  = parseInt(searchParams.get('limit') ?? '10');

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.schema('app')
    .from('parties' as never)
    .select('id, name, party_type, country_code, tier')
    .eq('party_type' as never, module)
    .ilike('name' as never, `%${q}%`)
    .is('deleted_at' as never, null)
    .order('name')
    .limit(limit);

  if (error) return NextResponse.json([], { status: 500 });
  return NextResponse.json(data ?? []);
}
