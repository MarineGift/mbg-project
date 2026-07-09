// src/app/api/applications/[formId]/submit/route.ts
// POST: mark a form as submitted (status + submitted_at).
// The actual submission is always done by a human in the browser.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

export async function POST(
  _req: Request,
  { params }: { params: { formId: string } },
) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('application_forms' as never)
    .update({
      status: 'submitted',
      submitted_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    } as never)
    .eq('id', params.formId)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}
