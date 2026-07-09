// src/app/api/applications/[formId]/route.ts
// GET: one form's field-status rows from the view.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

export async function GET(
  _req: Request,
  { params }: { params: { formId: string } },
) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('v_application_field_status' as never)
    .select('*')
    .eq('form_id', params.formId)
    .order('seq', { ascending: true })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data ?? [])
}
