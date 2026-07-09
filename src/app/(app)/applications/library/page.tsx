// src/app/(app)/applications/library/page.tsx
// Server component: loads the reusable answer library (RLS scopes to org).

import { createSupabaseServerClient } from '@/lib/supabase/server'
import LibraryClient, { type LibraryRow } from './library-client'

export const dynamic = 'force-dynamic'

export default async function AnswerLibraryPage() {
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('answer_library' as never)
    .select('id, answer_key, title, body_en, body_ko, disclosure_level, tags, updated_at')
    .order('answer_key', { ascending: true })

  if (error) console.error('[answer library] fetch failed:', error.message)

  const answers = (data ?? []) as unknown as LibraryRow[]
  return <LibraryClient initialAnswers={answers} />
}
