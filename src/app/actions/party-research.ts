'use server'
// src/app/actions/party-research.ts
//
// 2026-09-15 - backs the "투자사 분석" tab on a party page.
//
//   app.party_research    one free-text row per party: what we found out about
//                         the firm.
//   app.party_cold_mails  outreach sent OUTSIDE URM (Greentown's investor
//                         platform, LinkedIn, a warm intro), pasted in by hand.
//
// Deliberately NOT written into app.communications: those rows come from the
// mail pipeline with message ids, threads, tracking and read state. A pasted
// copy has none of that, and mixing them would skew reply/open reporting.

import { requireAuth } from '@/lib/auth'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export interface PartyResearch {
  id: string
  partyId: string
  researchNotes: string
  updatedAt: string | null
}

export interface ColdMail {
  id: string
  partyId: string
  source: string
  subject: string | null
  body: string | null
  recipient: string | null
  sentAt: string | null
  outcome: string | null
  createdAt: string
}

export type ResearchResult<T = null> =
  | { ok: true; data: T }
  | { ok: false; error: string }

const COLD_COLS =
  'id, party_id, source, subject, body, recipient, sent_at, outcome, created_at'

function toMessage(e: unknown): string {
  const err = e as { message?: string; details?: string; hint?: string; code?: string }
  return [err?.message, err?.details, err?.hint, err?.code ? `(${err.code})` : null]
    .filter(Boolean)
    .join(' \u00b7 ') || String(e)
}

/* --------------------------------------------------------------- research */

export async function getPartyResearchAction(
  partyId: string,
): Promise<ResearchResult<PartyResearch | null>> {
  if (!partyId) return { ok: false, error: 'Missing party id' }
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('party_research' as never)
      .select('id, party_id, research_notes, updated_at')
      .eq('party_id', partyId)
      .maybeSingle()
    if (error) throw error
    if (!data) return { ok: true, data: null }
    const r = data as unknown as {
      id: string
      party_id: string
      research_notes: string | null
      updated_at: string | null
    }
    return {
      ok: true,
      data: {
        id: r.id,
        partyId: r.party_id,
        researchNotes: r.research_notes ?? '',
        updatedAt: r.updated_at,
      },
    }
  } catch (e) {
    console.error('[party-research] load error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

// Upsert on (organization_id, party_id) - one research row per party.
export async function savePartyResearchAction(
  partyId: string,
  notes: string,
): Promise<ResearchResult<PartyResearch>> {
  if (!partyId) return { ok: false, error: 'Missing party id' }
  try {
    const auth = await requireAuth()
    const supabase = await createSupabaseServerClient()
    const now = new Date().toISOString()

    const { data, error } = await supabase
      .schema('app')
      .from('party_research' as never)
      .upsert(
        {
          organization_id: auth.organizationId,
          party_id: partyId,
          research_notes: notes,
          updated_at: now,
          updated_by: auth.userId,
        } as never,
        { onConflict: 'organization_id,party_id' },
      )
      .select('id, party_id, research_notes, updated_at')
      .maybeSingle()

    if (error) throw error
    if (!data) return { ok: false, error: 'Nothing was saved (RLS?)' }
    const r = data as unknown as {
      id: string
      party_id: string
      research_notes: string | null
      updated_at: string | null
    }
    revalidatePath(`/investor/parties/${partyId}`)
    return {
      ok: true,
      data: {
        id: r.id,
        partyId: r.party_id,
        researchNotes: r.research_notes ?? '',
        updatedAt: r.updated_at,
      },
    }
  } catch (e) {
    console.error('[party-research] save error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

/* -------------------------------------------------------------- cold mail */

function shapeCold(raw: Record<string, unknown>): ColdMail {
  return {
    id: String(raw.id),
    partyId: String(raw.party_id),
    source: (raw.source as string) ?? 'other',
    subject: (raw.subject as string) ?? null,
    body: (raw.body as string) ?? null,
    recipient: (raw.recipient as string) ?? null,
    sentAt: (raw.sent_at as string) ?? null,
    outcome: (raw.outcome as string) ?? null,
    createdAt: String(raw.created_at),
  }
}

export async function listColdMailsAction(
  partyId: string,
): Promise<ResearchResult<ColdMail[]>> {
  if (!partyId) return { ok: false, error: 'Missing party id' }
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('party_cold_mails' as never)
      .select(COLD_COLS)
      .eq('party_id', partyId)
      .is('deleted_at', null)
      .order('sent_at', { ascending: false, nullsFirst: false })
      .order('created_at', { ascending: false })
    if (error) throw error
    return {
      ok: true,
      data: ((data ?? []) as unknown as Array<Record<string, unknown>>).map(shapeCold),
    }
  } catch (e) {
    console.error('[party-research] cold mail list error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function createColdMailAction(input: {
  partyId: string
  source?: string
  subject?: string | null
  body?: string | null
  recipient?: string | null
  sentAt?: string | null
  outcome?: string | null
}): Promise<ResearchResult<ColdMail>> {
  if (!input?.partyId) return { ok: false, error: 'Missing party id' }
  if (!input.subject?.trim() && !input.body?.trim()) {
    return { ok: false, error: 'Add a subject or the message body' }
  }
  try {
    const auth = await requireAuth()
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('party_cold_mails' as never)
      .insert({
        organization_id: auth.organizationId,
        party_id: input.partyId,
        source: input.source?.trim() || 'greentown',
        subject: input.subject?.trim() || null,
        body: input.body?.trim() || null,
        recipient: input.recipient?.trim() || null,
        sent_at: input.sentAt || null,
        outcome: input.outcome?.trim() || null,
      } as never)
      .select(COLD_COLS)
      .maybeSingle()
    if (error) throw error
    if (!data) return { ok: false, error: 'Nothing was saved (RLS?)' }
    revalidatePath(`/investor/parties/${input.partyId}`)
    return { ok: true, data: shapeCold(data as unknown as Record<string, unknown>) }
  } catch (e) {
    console.error('[party-research] cold mail create error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function updateColdMailAction(
  id: string,
  patch: { outcome?: string | null; subject?: string | null; body?: string | null },
): Promise<ResearchResult<ColdMail>> {
  if (!id) return { ok: false, error: 'Missing id' }
  try {
    const supabase = await createSupabaseServerClient()
    const row: Record<string, unknown> = { updated_at: new Date().toISOString() }
    if (patch.outcome !== undefined) row.outcome = patch.outcome?.trim() || null
    if (patch.subject !== undefined) row.subject = patch.subject?.trim() || null
    if (patch.body !== undefined) row.body = patch.body?.trim() || null

    const { data, error } = await supabase
      .schema('app')
      .from('party_cold_mails' as never)
      .update(row as never)
      .eq('id', id)
      .is('deleted_at', null)
      .select(COLD_COLS)
      .maybeSingle()
    if (error) throw error
    if (!data) return { ok: false, error: 'No row updated (deleted, or RLS blocked it)' }
    return { ok: true, data: shapeCold(data as unknown as Record<string, unknown>) }
  } catch (e) {
    console.error('[party-research] cold mail update error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function deleteColdMailAction(
  id: string,
): Promise<ResearchResult<{ id: string }>> {
  if (!id) return { ok: false, error: 'Missing id' }
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('party_cold_mails' as never)
      .update({ deleted_at: new Date().toISOString() } as never)
      .eq('id', id)
      .select('id')
      .maybeSingle()
    if (error) throw error
    if (!data) return { ok: false, error: 'No row deleted (already gone, or RLS blocked it)' }
    return { ok: true, data: { id } }
  } catch (e) {
    console.error('[party-research] cold mail delete error:', e)
    return { ok: false, error: toMessage(e) }
  }
}
