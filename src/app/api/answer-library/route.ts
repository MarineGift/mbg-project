// src/app/api/answer-library/route.ts
// GET: list. POST: create. PATCH: update (id in body).
// answer_library is an ENTITY table: created_by defaults to auth.uid()
// on insert (session client, so auth.uid() is real). RLS scopes org.

import { NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function GET() {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('answer_library' as never)
    .select('*')
    .order('answer_key', { ascending: true })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data ?? [])
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

  const body = (await req.json()) as {
    answer_key: string
    title: string
    body_en?: string | null
    body_ko?: string | null
    disclosure_level?: 'public' | 'nda_only'
    tags?: string[]
  }
  if (!body.answer_key?.trim() || !body.title?.trim()) {
    return NextResponse.json({ error: 'answer_key and title required' }, { status: 400 })
  }

  const { data, error } = await supabase
    .schema('app')
    .from('answer_library' as never)
    .insert({
      organization_id: orgId,
      answer_key: body.answer_key.trim(),
      title: body.title.trim(),
      body_en: body.body_en ?? null,
      body_ko: body.body_ko ?? null,
      disclosure_level: body.disclosure_level ?? 'public',
      tags: body.tags ?? [],
    } as never)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function PATCH(req: Request) {
  const supabase = await createSupabaseServerClient()
  const body = (await req.json()) as {
    id: string
    title?: string
    body_en?: string | null
    body_ko?: string | null
    disclosure_level?: 'public' | 'nda_only'
    tags?: string[]
  }
  if (!body.id) return NextResponse.json({ error: 'id required' }, { status: 400 })

  const patch: Record<string, unknown> = { updated_at: new Date().toISOString() }
  if ('title' in body) patch.title = body.title
  if ('body_en' in body) patch.body_en = body.body_en
  if ('body_ko' in body) patch.body_ko = body.body_ko
  if ('disclosure_level' in body) patch.disclosure_level = body.disclosure_level
  if ('tags' in body) patch.tags = body.tags

  const { data, error } = await supabase
    .schema('app')
    .from('answer_library' as never)
    .update(patch as never)
    .eq('id', body.id)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}
