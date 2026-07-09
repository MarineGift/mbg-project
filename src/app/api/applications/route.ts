// src/app/api/applications/route.ts
// GET: list all application forms with per-field status rows.
// RLS scopes to the session org; the API trusts the session only.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('v_application_field_status' as never)
    .select('*')
    .order('deadline', { ascending: true, nullsFirst: false })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data ?? [])
}
