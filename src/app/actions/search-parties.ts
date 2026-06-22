'use server'
// src/app/actions/search-parties.ts
// Lightweight party name search for the meeting-create modal (returns UUIDs).

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'

export interface PartySearchResult {
  id: string
  party_name: string
}

export async function searchPartiesForMeeting(
  query: string,
): Promise<PartySearchResult[]> {
  const q = query.trim()
  if (q.length < 2) return []

  const auth = await requireAuth()
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name')
    .eq('organization_id', auth.organizationId)
    .ilike('party_name', `%${q}%`)
    .order('party_name', { ascending: true })
    .limit(10)

  if (error) {
    console.error('[searchPartiesForMeeting]', error)
    return []
  }
  return (data ?? []) as unknown as PartySearchResult[]
}
