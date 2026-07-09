// src/app/api/applications/route.ts
// GET: list application forms with per-field status rows.
//   ?party_id=<uuid>  optional filter (powers the party detail panel)
// RLS scopes to the session org; the API trusts the session only.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

export async function GET(req: Request) {
  const supabase = await createSupabaseServerClient()
  const { searchParams } = new URL(req.url)
  const partyId = searchParams.get('party_id')

  let q = supabase
    .schema('app')
    .from('v_application_field_status' as never)
    .select('*')
    .order('deadline', { ascending: true, nullsFirst: false })

  if (partyId) q = q.eq('party_id', partyId)

  const { data, error } = await q
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data ?? [])
}
