// src/app/api/applications/[formId]/fields/[fieldId]/route.ts
// PATCH: upsert the answer bound to one field.
// Body: { final_text?, answer_id?, is_copied? }
// application_field_answers has UNIQUE(field_id), so upsert on field_id.
// Child/link table: NO created_by (SaaS rule). RLS enforces org scoping;
// organization_id is taken from the session JWT for the insert path.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

export async function PATCH(
  req: Request,
  { params }: { params: { fieldId: string } },
) {
  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const orgId =
    (user.app_metadata?.organization_id as string | undefined) ?? null
  if (!orgId) return NextResponse.json({ error: 'no org in session' }, { status: 403 })

  const body = (await req.json()) as {
    final_text?: string | null
    answer_id?: string | null
    is_copied?: boolean
  }

  const row: Record<string, unknown> = {
    organization_id: orgId,
    field_id: params.fieldId,
    updated_at: new Date().toISOString(),
  }
  if ('final_text' in body) row.final_text = body.final_text
  if ('answer_id' in body) row.answer_id = body.answer_id
  if ('is_copied' in body) row.is_copied = body.is_copied

  const { data, error } = await supabase
    .schema('app')
    .from('application_field_answers' as never)
    .upsert(row as never, { onConflict: 'field_id' })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}
