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
  /** group rows have no party; they aggregate their children */
  isGroup: boolean
  parentId: string | null
  partyId: string | null
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
  'id, party_id, parent_id, is_group, label, color, match_domains, sort_order, parties:party_id ( party_name )'

function toMessage(e: unknown): string {
  const err = e as { message?: string; details?: string; hint?: string; code?: string }
  return [err?.message, err?.details, err?.hint, err?.code ? `(${err.code})` : null]
    .filter(Boolean)
    .join(' \u00b7 ') || String(e)
}

interface RawFolder {
  id: string
  party_id: string | null
  parent_id: string | null
  is_group: boolean
  label: string | null
  color: string | null
  match_domains: string[] | null
  sort_order: number
  parties: { party_name: string } | Array<{ party_name: string }> | null
}

function shape(raw: RawFolder): MailFolder {
  const party = Array.isArray(raw.parties) ? raw.parties[0] : raw.parties
  const partyName = party?.party_name ?? (raw.is_group ? '' : 'Unknown party')
  return {
    id: raw.id,
    isGroup: !!raw.is_group,
    parentId: raw.parent_id ?? null,
    partyId: raw.party_id ?? null,
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

    // One round trip. app.mail_folder_counts() walks each folder's subtree and
    // counts DISTINCT messages, so a group never double-counts a message that
    // two of its children both match (shared sender domain).
    // `as never` on the rpc name: the generated Database types are regenerated
    // separately and do not know this function yet.
    const { data, error } = await supabase
      .schema('app')
      .rpc('mail_folder_counts' as never)
    if (error) throw error

    const counts = (data ?? []) as unknown as Array<{
      folder_id: string
      inbound: number | string
      unread: number | string
    }>
    const byId = new Map(counts.map((r) => [r.folder_id, r]))

    return {
      ok: true,
      data: base.data.map((f) => {
        const c = byId.get(f.id)
        return { ...f, total: Number(c?.inbound ?? 0), unread: Number(c?.unread ?? 0) }
      }),
    }
  } catch (e) {
    console.error('[mail-folders] counts error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export interface FolderScope {
  id: string
  name: string
  color: string | null
  isGroup: boolean
  /** every party whose mail belongs to this folder (a group folds in its children) */
  partyIds: string[]
  domains: string[]
}

// What the inbox needs to filter on when you open ?folder=<id>.
export async function resolveFolderScopeAction(
  id: string,
): Promise<FolderResult<FolderScope>> {
  if (!id) return { ok: false, error: 'Missing folder id' }
  try {
    const all = await listMailFoldersAction()
    if (!all.ok) return all
    const self = all.data.find((f) => f.id === id)
    if (!self) return { ok: false, error: 'Folder not found' }

    // Groups nest (Business > Omya > Omya (Korea)), so collect the whole
    // subtree, not just direct children. A group can carry domains itself.
    const members: MailFolder[] = []
    const seen = new Set<string>()
    const walk = (node: MailFolder) => {
      if (seen.has(node.id)) return
      seen.add(node.id)
      members.push(node)
      for (const child of all.data) {
        if (child.parentId === node.id) walk(child)
      }
    }
    walk(self)

    const partyIds: string[] = []
    const domains: string[] = []
    for (const m of members) {
      if (m.partyId && !partyIds.includes(m.partyId)) partyIds.push(m.partyId)
      for (const d of m.matchDomains) if (!domains.includes(d)) domains.push(d)
    }

    return {
      ok: true,
      data: {
        id: self.id,
        name: self.name,
        color: self.color,
        isGroup: self.isGroup,
        partyIds,
        domains,
      },
    }
  } catch (e) {
    console.error('[mail-folders] scope error:', e)
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
  partyId?: string | null
  /** true => a group header (Partners / Investors / Business) */
  isGroup?: boolean
  parentId?: string | null
  label?: string | null
  color?: string | null
  matchDomains?: string[] | string | null
}): Promise<FolderResult<MailFolder>> {
  if (input?.isGroup) {
    if (!input.label?.trim()) return { ok: false, error: 'Name the group first' }
  } else if (!input?.partyId) {
    return { ok: false, error: 'Pick a party first' }
  }
  try {
    const auth = await requireAuth()
    const supabase = await createSupabaseServerClient()

    // Revive a previously removed folder for the same party instead of
    // tripping the partial unique index. Groups have no party, so skip.
    const { data: existing } = input.partyId
      ? await supabase
          .schema('app')
          .from('mail_folders' as never)
          .select('id, deleted_at')
          .eq('organization_id', auth.organizationId)
          .eq('party_id', input.partyId)
          .maybeSingle()
      : { data: null }

    const payload = {
      label: input.label?.trim() || null,
      color: input.color?.trim() || null,
      match_domains: normalizeDomains(input.matchDomains),
      parent_id: input.parentId || null,
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
        party_id: input.isGroup ? null : input.partyId,
        is_group: !!input.isGroup,
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
    /** null moves the folder back out to the top level */
    parentId?: string | null
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
    if (patch.parentId !== undefined) row.parent_id = patch.parentId || null

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
  partyIds: string[],
  matchDomains: string[],
): Promise<string> {
  return folderOrExpression(partyIds, matchDomains)
}

function folderOrExpression(partyIds: string[], matchDomains: string[]): string {
  const parts: string[] = []
  if (partyIds.length === 1) parts.push(`party_id.eq.${partyIds[0]}`)
  else if (partyIds.length > 1) parts.push(`party_id.in.(${partyIds.join(',')})`)
  for (const d of normalizeDomains(matchDomains)) {
    parts.push(`from_address.ilike.*@${d}`)
  }
  return parts.join(',')
}
