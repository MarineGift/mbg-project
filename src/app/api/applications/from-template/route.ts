// src/app/api/applications/from-template/route.ts
// POST: create an application form (or fill an existing empty one) with a
// standard canonical_key field set, auto-binding the best answer_library
// variant per field (target_length vs max_length).
//
// Body (create new form):
//   { party_id, form_type, form_url, submission_method?, login_required?, deadline? }
// Body (generate fields into an existing empty form):
//   { form_id }
//
// SaaS rules: application_form_fields / application_field_answers are
// child/link tables -> no created_by. application_forms is an entity ->
// created_by defaults to auth.uid() in the DB. RLS scopes everything;
// organization_id comes off the session JWT for insert paths.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'
import {
  CANONICAL_TEMPLATES,
  pickVariant,
  type LibraryRowLite,
  type TemplateFormType,
} from '@/lib/applications/canonical-templates'

export const dynamic = 'force-dynamic'

type Body = {
  form_id?: string
  party_id?: string
  form_type?: string
  form_url?: string
  submission_method?: 'email' | 'web_form' | 'portal' | 'email_then_form'
  login_required?: boolean
  deadline?: string | null
}

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient()
  let orgId: string
  try {
    const auth = await requireAuth()
    orgId = auth.organizationId
  } catch {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  const body = (await req.json()) as Body

  // ── resolve or create the form ─────────────────────────────
  let formId = body.form_id ?? null
  let formType = body.form_type ?? 'application'

  if (formId) {
    const { data: existing, error } = await supabase
      .schema('app')
      .from('application_forms' as never)
      .select('id, form_type')
      .eq('id', formId)
      .maybeSingle()
    if (error || !existing) {
      return NextResponse.json({ error: 'form not found' }, { status: 404 })
    }
    formType = (existing as { form_type: string }).form_type

    const { count } = await supabase
      .schema('app')
      .from('application_form_fields' as never)
      .select('id', { count: 'exact', head: true })
      .eq('form_id', formId)
    if ((count ?? 0) > 0) {
      return NextResponse.json(
        { error: 'form already has fields; template generation is for empty forms only' },
        { status: 409 },
      )
    }
  } else {
    if (!body.party_id || !body.form_url) {
      return NextResponse.json(
        { error: 'party_id and form_url are required to create a form' },
        { status: 400 },
      )
    }
    const insertForm: Record<string, unknown> = {
      organization_id: orgId,
      party_id: body.party_id,
      form_url: body.form_url,
      form_type: formType,
      submission_method: body.submission_method ?? 'web_form',
      login_required: body.login_required ?? body.submission_method === 'portal',
      status: 'drafting',
    }
    if (body.deadline) insertForm.deadline = body.deadline

    const { data: created, error: createErr } = await supabase
      .schema('app')
      .from('application_forms' as never)
      .insert(insertForm as never)
      .select('id')
      .single()
    if (createErr || !created) {
      return NextResponse.json(
        { error: createErr?.message ?? 'form insert failed' },
        { status: 500 },
      )
    }
    formId = (created as { id: string }).id
  }

  const template = CANONICAL_TEMPLATES[formType as TemplateFormType]
  if (!template) {
    return NextResponse.json(
      { error: `no template for form_type ${formType}`, form_id: formId },
      { status: 422 },
    )
  }

  // ── load library candidates for every key in one query ─────
  const keys = Array.from(new Set(template.map((t) => t.canonicalKey)))
  const { data: libData, error: libErr } = await supabase
    .schema('app')
    .from('answer_library' as never)
    .select('id, answer_key, variant, target_length, body_en, disclosure_level')
    .in('answer_key', keys)
  if (libErr) {
    return NextResponse.json({ error: libErr.message }, { status: 500 })
  }
  const library = (libData ?? []) as unknown as LibraryRowLite[]
  const byKey = new Map<string, LibraryRowLite[]>()
  for (const row of library) {
    const arr = byKey.get(row.answer_key) ?? []
    arr.push(row)
    byKey.set(row.answer_key, arr)
  }

  // ── insert fields ──────────────────────────────────────────
  const fieldRows = template.map((t, i) => ({
    organization_id: orgId,
    form_id: formId,
    seq: (i + 1) * 10,
    label: t.label,
    field_type: 'textarea',
    max_length: t.maxLength,
    is_required: t.isRequired,
    canonical_key: t.canonicalKey,
  }))
  const { data: fieldData, error: fieldErr } = await supabase
    .schema('app')
    .from('application_form_fields' as never)
    .insert(fieldRows as never)
    .select('id, seq, canonical_key, max_length')
  if (fieldErr || !fieldData) {
    return NextResponse.json(
      { error: fieldErr?.message ?? 'field insert failed', form_id: formId },
      { status: 500 },
    )
  }

  // ── auto-bind best variant per field ───────────────────────
  const answerRows: Record<string, unknown>[] = []
  let bound = 0
  for (const f of fieldData as unknown as {
    id: string
    canonical_key: string | null
    max_length: number | null
  }[]) {
    const candidates = f.canonical_key ? (byKey.get(f.canonical_key) ?? []) : []
    const pick = pickVariant(candidates, f.max_length)
    if (!pick) continue
    answerRows.push({
      organization_id: orgId,
      field_id: f.id,
      answer_id: pick.id,
      final_text: pick.body_en ?? '',
    })
    bound += 1
  }
  if (answerRows.length > 0) {
    const { error: ansErr } = await supabase
      .schema('app')
      .from('application_field_answers' as never)
      .upsert(answerRows as never, { onConflict: 'field_id' })
    if (ansErr) {
      return NextResponse.json(
        { error: ansErr.message, form_id: formId, fields: fieldRows.length },
        { status: 500 },
      )
    }
  }

  return NextResponse.json({
    form_id: formId,
    fields: fieldRows.length,
    bound,
    unbound_keys: template
      .map((t) => t.canonicalKey)
      .filter((k) => !byKey.has(k)),
  })
}
