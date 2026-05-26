// src/lib/queries/email-sequences.ts
// Email sequence queries (server-only).
// RPCs live in 'public' schema (no .schema('app') needed).

import 'server-only'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export async function listSequences(organizationId: string) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await (supabase as any)
    .rpc('list_sequences', { p_organization_id: organizationId })
  if (error) throw error
  return data ?? []
}

export async function getSequenceWithSteps(sequenceId: string) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await (supabase as any)
    .rpc('get_sequence_with_steps', { p_sequence_id: sequenceId })
  if (error) throw error
  return data ?? null
}

export async function getPartyEnrollments(partyId: string) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await (supabase as any)
    .rpc('get_party_enrollments', { p_party_id: partyId })
  if (error) throw error
  return data ?? []
}

export const fetchSequences = listSequences
export const fetchPartyEnrollments = getPartyEnrollments