'use server'
// src/app/actions/mail-folders.ts
//
// 2026-09-15 - "mail folder per important party" (e.g. Greentown Labs).
//
// A folder is a saved view, not storage: nothing is moved or copied. Inbound
// mail already has party_id resolved at ingest time
// (src/lib/email/header-parser.ts -> matchSenderToContactAndParty: contact
// email, then party email, then sender domain), so a folder simply filters
// app.communications by that party, plus any extra sender domains the user
// pins to the folder (newsletters / no-reply@ that are not contacts).
//
// Table: app.mail_folders (sql/migration_20260915_mail_folders.sql)

import { requireAuth } from '@/lib/auth'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export interface MailFolder {
  id: string
  partyId: string
  /** label falls back to the party name */
  name: string
  label: string | null
  partyName: string
  color: string | null
  matchDomains: string[]
  sortOrder: number
}

export interface MailFolderWithCounts extends MailFolder {
  unread: number
  total: number
}

export interface PartyOption {
  id: string
  name: string
  typeCode: string | null
}

export type FolderResult<T = null> =
  | { ok: true; data: T }
  | { ok: false; error: string }

const COLS =
  'id, party_id, label, color, match_domains, sort_order, parties:party_id ( party_name )'

function toMessage(e: unknown): string {
  const err = e as { message?: string; details?: string; hint?: string; code?: string }
  return [err?.message, err?.details, err?.hint, err?.code ? `(${err.code})` : null]
    .filter(Boolean)
    .join(' \u00b7 ') || String(e)
}

interface RawFolder {
  id: string
  party_id: string
  label: string | null
  color: string | null
  match_domains: string[] | null
  sort_order: number
  parties: { party_name: string } | Array<{ party_name: string }> | null
}

function shape(raw: RawFolder): MailFolder {
  const party = Array.isArray(raw.parties) ? raw.parties[0] : raw.parties
  const partyName = party?.party_name ?? 'Unknown party'
  return {
    id: raw.id,
    partyId: raw.party_id,
    label: raw.label,
    partyName,
    name: raw.label?.trim() || partyName,
    color: raw.color,
    matchDomains: raw.match_domains ?? [],
    sortOrder: raw.sort_order ?? 0,
  }
}

// Domains are stored bare and lower-case: "greentownlabs.com".
// Accepts "@x.com", "https://x.com/", "Foo@X.com" and normalises them.
function normalizeDomains(input: string[] | string | null | undefined): string[] {
  const raw = Array.isArray(input)
    ? input
    : String(input ?? '').split(/[\s,;]+/)
  const out: string[] = []
  for (const item of raw) {
    let d = item.trim().toLowerCase()
    if (!d) continue
    d = d.replace(/^https?:\/\//, '').replace(/\/.*$/, '')
    const at = d.lastIndexOf('@')
    if (at >= 0) d = d.slice(at + 1)
    if (!/^[a-z0-9.-]+\.[a-z]{2,}$/.test(d)) continue
    if (!out.includes(d)) out.push(d)
  }
  return out
}

/* ------------------------------------------------------------------ read */

export async function listMailFoldersAction(): Promise<FolderResult<MailFolder[]>> {
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .select(COLS)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true })
      .order('created_at', { ascending: true })

    if (error) throw error
    return { ok: true, data: ((data ?? []) as unknown as RawFolder[]).map(shape) }
  } catch (e) {
    console.error('[mail-folders] list error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

// Sidebar payload: folders plus inbound counts. Counts are head-only requests
// (no rows transferred); with a handful of pinned folders this stays cheap.
export async function listMailFoldersWithCountsAction(): Promise<
  FolderResult<MailFolderWithCounts[]>
> {
  try {
    const base = await listMailFoldersAction()
    if (!base.ok) return base
    const supabase = await createSupabaseServerClient()

    const rows = await Promise.all(
      base.data.map(async (f) => {
        const buildCount = () =>
          supabase
            .schema('app')
            .from('communications' as never)
            .select('id', { count: 'exact', head: true })
            .is('deleted_at', null)
            .eq('direction', 'inbound')

        const orExpr = folderOrExpression(f.partyId, f.matchDomains)
        const [totalRes, unreadRes] = await Promise.all([
          buildCount().or(orExpr),
          buildCount().or(orExpr).is('read_at', null),
        ])

        return {
          ...f,
          total: totalRes.count ?? 0,
          unread: unreadRes.count ?? 0,
        }
      }),
    )
    return { ok: true, data: rows }
  } catch (e) {
    console.error('[mail-folders] counts error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function getMailFolderAction(id: string): Promise<FolderResult<MailFolder>> {
  if (!id) return { ok: false, error: 'Missing folder id' }
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .select(COLS)
      .eq('id', id)
      .is('deleted_at', null)
      .maybeSingle()
    if (error) throw error
    if (!data) return { ok: false, error: 'Folder not found' }
    return { ok: true, data: shape(data as unknown as RawFolder) }
  } catch (e) {
    console.error('[mail-folders] get error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

/* ----------------------------------------------------------------- write */

export async function createMailFolderAction(input: {
  partyId: string
  label?: string | null
  color?: string | null
  matchDomains?: string[] | string | null
}): Promise<FolderResult<MailFolder>> {
  if (!input?.partyId) return { ok: false, error: 'Pick a party first' }
  try {
    const auth = await requireAuth()
    const supabase = await createSupabaseServerClient()

    // Revive a previously removed folder for the same party instead of
    // tripping the partial unique index.
    const { data: existing } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .select('id, deleted_at')
      .eq('organization_id', auth.organizationId)
      .eq('party_id', input.partyId)
      .maybeSingle()

    const payload = {
      label: input.label?.trim() || null,
      color: input.color?.trim() || null,
      match_domains: normalizeDomains(input.matchDomains),
      deleted_at: null,
      updated_at: new Date().toISOString(),
    }

    if (existing) {
      const row = existing as { id: string; deleted_at: string | null }
      const { data, error } = await supabase
        .schema('app')
        .from('mail_folders' as never)
        .update(payload as never)
        .eq('id', row.id)
        .select(COLS)
        .maybeSingle()
      if (error) throw error
      revalidatePath('/inbox')
      return { ok: true, data: shape(data as unknown as RawFolder) }
    }

    const { count } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .select('id', { count: 'exact', head: true })
      .is('deleted_at', null)

    const { data, error } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .insert({
        organization_id: auth.organizationId,
        party_id: input.partyId,
        sort_order: count ?? 0,
        ...payload,
      } as never)
      .select(COLS)
      .maybeSingle()

    if (error) throw error
    if (!data) return { ok: false, error: 'Folder was not created (RLS?)' }
    revalidatePath('/inbox')
    return { ok: true, data: shape(data as unknown as RawFolder) }
  } catch (e) {
    console.error('[mail-folders] create error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function updateMailFolderAction(
  id: string,
  patch: {
    label?: string | null
    color?: string | null
    matchDomains?: string[] | string | null
    sortOrder?: number
  },
): Promise<FolderResult<MailFolder>> {
  if (!id) return { ok: false, error: 'Missing folder id' }
  try {
    const supabase = await createSupabaseServerClient()
    const row: Record<string, unknown> = { updated_at: new Date().toISOString() }
    if (patch.label !== undefined) row.label = patch.label?.trim() || null
    if (patch.color !== undefined) row.color = patch.color?.trim() || null
    if (patch.matchDomains !== undefined) row.match_domains = normalizeDomains(patch.matchDomains)
    if (patch.sortOrder !== undefined) row.sort_order = patch.sortOrder

    const { data, error } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .update(row as never)
      .eq('id', id)
      .is('deleted_at', null)
      .select(COLS)
      .maybeSingle()

    if (error) throw error
    if (!data) return { ok: false, error: 'No row updated (deleted, or RLS blocked the write)' }
    revalidatePath('/inbox')
    return { ok: true, data: shape(data as unknown as RawFolder) }
  } catch (e) {
    console.error('[mail-folders] update error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

// Soft delete. Mail is untouched - only the saved view goes away.
export async function deleteMailFolderAction(id: string): Promise<FolderResult<{ id: string }>> {
  if (!id) return { ok: false, error: 'Missing folder id' }
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('mail_folders' as never)
      .update({ deleted_at: new Date().toISOString() } as never)
      .eq('id', id)
      .select('id')
      .maybeSingle()
    if (error) throw error
    if (!data) return { ok: false, error: 'No row deleted (already gone, or RLS blocked it)' }
    revalidatePath('/inbox')
    return { ok: true, data: { id } }
  } catch (e) {
    console.error('[mail-folders] delete error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function reorderMailFoldersAction(
  orderedIds: string[],
): Promise<FolderResult<null>> {
  try {
    const supabase = await createSupabaseServerClient()
    await Promise.all(
      orderedIds.map((id, i) =>
        supabase
          .schema('app')
          .from('mail_folders' as never)
          .update({ sort_order: i, updated_at: new Date().toISOString() } as never)
          .eq('id', id),
      ),
    )
    revalidatePath('/inbox')
    return { ok: true, data: null }
  } catch (e) {
    console.error('[mail-folders] reorder error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

/* ---------------------------------------------------------- party picker */

export async function searchPartiesForFolderAction(
  q: string,
): Promise<FolderResult<PartyOption[]>> {
  try {
    const supabase = await createSupabaseServerClient()
    let query = supabase
      .schema('app')
      .from('parties' as never)
      .select('id, party_name, party_types(code)')
      .is('deleted_at', null)
      .order('party_name', { ascending: true })
      .limit(20)

    const term = q?.trim()
    if (term) query = query.ilike('party_name', `%${term.replace(/[%_]/g, '')}%`)

    const { data, error } = await query
    if (error) throw error

    const rows = (data ?? []) as unknown as Array<{
      id: string
      party_name: string
      party_types: { code: string } | Array<{ code: string }> | null
    }>
    return {
      ok: true,
      data: rows.map((r) => {
        const pt = Array.isArray(r.party_types) ? r.party_types[0] : r.party_types
        return { id: r.id, name: r.party_name, typeCode: pt?.code ?? null }
      }),
    }
  } catch (e) {
    console.error('[mail-folders] party search error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

/* --------------------------------------------------------------- helpers */

// PostgREST or() expression for "belongs to this folder".
// ilike inside or() uses '*' as the wildcard, not '%'.
export async function folderOrExpressionAction(
  partyId: string,
  matchDomains: string[],
): Promise<string> {
  return folderOrExpression(partyId, matchDomains)
}

function folderOrExpression(partyId: string, matchDomains: string[]): string {
  const parts = [`party_id.eq.${partyId}`]
  for (const d of normalizeDomains(matchDomains)) {
    parts.push(`from_address.ilike.*@${d}`)
  }
  return parts.join(',')
}
