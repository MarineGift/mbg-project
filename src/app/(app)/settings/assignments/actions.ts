// src/app/(app)/settings/assignments/actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export type PartyRow = {
  id: string
  party_name: string
  owner_user_id: string | null
}

// ownerFilter: 'all' | 'unassigned' | <userId>
export async function searchAssignableParties(
  query: string,
  ownerFilter: string,
): Promise<PartyRow[]> {
  const supabase = await createSupabaseServerClient()

  let q = supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name, owner_user_id')
    .order('party_name')
    .limit(100)

  const term = query.trim()
  if (term) q = q.ilike('party_name', `%${term}%`)

  if (ownerFilter === 'unassigned') q = q.is('owner_user_id', null)
  else if (ownerFilter && ownerFilter !== 'all') q = q.eq('owner_user_id', ownerFilter)

  const { data, error } = await q
  if (error) {
    console.error('[assignments] search failed:', error.message)
    return []
  }
  return ((data as any) ?? []) as PartyRow[]
}

// ownerUserId = null  -> unassign
export async function assignParties(
  partyIds: string[],
  ownerUserId: string | null,
): Promise<{ ok: boolean; error?: string; count?: number }> {
  if (!partyIds.length) return { ok: false, error: 'No parties selected.' }

  const supabase = await createSupabaseServerClient()
  const { error, count } = await supabase
    .schema('app')
    .from('parties' as never)
    .update({ owner_user_id: ownerUserId } as any, { count: 'exact' })
    .in('id', partyIds)

  if (error) return { ok: false, error: error.message }

  revalidatePath('/settings/assignments')
  return { ok: true, count: count ?? partyIds.length }
}
