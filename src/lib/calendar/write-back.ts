// src/lib/calendar/write-back.ts
// Phase 5 - propagate local edits/deletes of google/microsoft events back to the
// external calendar. Server-only. Uses the service-role client to read the
// encrypted connection tokens (via token-crypto), refreshes if expired, then
// calls the provider API. All functions are best-effort and never throw to the
// caller: they return { ok, error? } so the local DB stays the source of truth.
import { createClient } from '@supabase/supabase-js'
import { decryptToken, updateAccessToken } from './token-crypto'
import {
  refreshGoogleToken,
  isTokenExpired,
  updateGoogleEvent,
  deleteGoogleEvent,
} from './google-client'
import {
  refreshMicrosoftToken,
  updateMicrosoftEvent,
  deleteMicrosoftEvent,
} from './microsoft-client'

type Provider = 'google' | 'microsoft'

interface Conn {
  id: string
  provider: Provider
  access_token: string
  refresh_token: string | null
  expires_at: string | null
}

function serviceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { db: { schema: 'app' } },
  )
}

async function getConnectionById(connId: string): Promise<Conn | null> {
  const sb = serviceClient()
  const { data, error } = await sb
    .from('calendar_connections')
    .select('id, provider, access_token, refresh_token, expires_at, is_active')
    .eq('id', connId)
    .maybeSingle()
  if (error || !data) return null
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const row = data as any
  if (!row.is_active) return null
  const [access, refresh] = await Promise.all([
    decryptToken(row.access_token),
    row.refresh_token ? decryptToken(row.refresh_token) : Promise.resolve(null),
  ])
  return {
    id:            row.id,
    provider:      row.provider,
    access_token:  access,
    refresh_token: refresh,
    expires_at:    row.expires_at,
  }
}

async function freshToken(conn: Conn): Promise<string> {
  if (!isTokenExpired(conn.expires_at)) return conn.access_token
  if (!conn.refresh_token) throw new Error('No refresh token available for write-back')
  if (conn.provider === 'google') {
    const r = await refreshGoogleToken(conn.refresh_token)
    await updateAccessToken(conn.id, r.access_token, new Date(Date.now() + r.expires_in * 1000))
    return r.access_token
  }
  const r = await refreshMicrosoftToken(conn.refresh_token)
  await updateAccessToken(conn.id, r.access_token, new Date(Date.now() + r.expires_in * 1000))
  return r.access_token
}

const ymd = (iso: string) => new Date(iso).toISOString().slice(0, 10)
const addDayYmd = (iso: string) => {
  const d = new Date(iso)
  d.setUTCDate(d.getUTCDate() + 1)
  return d.toISOString().slice(0, 10)
}

export interface ExternalEventFields {
  title:        string
  description?: string | null
  location?:    string | null
  start_at:     string
  end_at:       string
  is_all_day?:  boolean | null
  timezone?:    string | null
}

function googlePatch(f: ExternalEventFields): Record<string, unknown> {
  const tz = f.timezone || 'UTC'
  const start = f.is_all_day ? { date: ymd(f.start_at) } : { dateTime: f.start_at, timeZone: tz }
  const end   = f.is_all_day ? { date: addDayYmd(f.start_at) } : { dateTime: f.end_at, timeZone: tz }
  return {
    summary:     f.title,
    description: f.description ?? '',
    location:    f.location ?? '',
    start,
    end,
  }
}

function microsoftPatch(f: ExternalEventFields): Record<string, unknown> {
  const tz = f.timezone || 'UTC'
  const start = f.is_all_day
    ? { dateTime: `${ymd(f.start_at)}T00:00:00`, timeZone: tz }
    : { dateTime: f.start_at, timeZone: tz }
  const end = f.is_all_day
    ? { dateTime: `${addDayYmd(f.start_at)}T00:00:00`, timeZone: tz }
    : { dateTime: f.end_at, timeZone: tz }
  return {
    subject:  f.title,
    body:     { contentType: 'text', content: f.description ?? '' },
    location: { displayName: f.location ?? '' },
    start,
    end,
    isAllDay: !!f.is_all_day,
  }
}

export interface WriteBackResult {
  ok: boolean
  error?: string
}

export async function pushEventUpdate(args: {
  source:       Provider
  connectionId: string
  externalId:   string
  fields:       ExternalEventFields
}): Promise<WriteBackResult> {
  try {
    const conn = await getConnectionById(args.connectionId)
    if (!conn) return { ok: false, error: 'Calendar connection not found or inactive' }
    const token = await freshToken(conn)
    if (conn.provider === 'google') {
      await updateGoogleEvent(token, args.externalId, googlePatch(args.fields))
    } else {
      await updateMicrosoftEvent(token, args.externalId, microsoftPatch(args.fields))
    }
    return { ok: true }
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : 'write-back failed' }
  }
}

export async function pushEventDelete(args: {
  source:       Provider
  connectionId: string
  externalId:   string
}): Promise<WriteBackResult> {
  try {
    const conn = await getConnectionById(args.connectionId)
    if (!conn) return { ok: false, error: 'Calendar connection not found or inactive' }
    const token = await freshToken(conn)
    if (conn.provider === 'google') {
      await deleteGoogleEvent(token, args.externalId)
    } else {
      await deleteMicrosoftEvent(token, args.externalId)
    }
    return { ok: true }
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : 'write-back failed' }
  }
}
