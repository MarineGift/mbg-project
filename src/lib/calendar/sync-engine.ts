// src/lib/calendar/sync-engine.ts
// Google / Microsoft 이벤트 → calendar_events upsert

import { createClient } from '@supabase/supabase-js'
import {
  getActiveConnections,
  updateAccessToken,
  updateSyncState,
  DecryptedConnection,
} from './token-crypto'
import {
  fetchAllGoogleEvents,
  refreshGoogleToken,
  isTokenExpired,
  GoogleEvent,
} from './google-client'
import {
  fetchAllMicrosoftEvents,
  refreshMicrosoftToken,
  MicrosoftEvent,
} from './microsoft-client'

// ─────────────────────────────────────────────
// Supabase service client
// ─────────────────────────────────────────────

function serviceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { db: { schema: 'app' } }
  )
}

// ─────────────────────────────────────────────
// Normalise helpers
// ─────────────────────────────────────────────

function googleMeetingUrl(e: GoogleEvent): string | null {
  if (e.hangoutLink) return e.hangoutLink
  const ep = e.conferenceData?.entryPoints?.find(x => x.entryPointType === 'video')
  return ep?.uri ?? null
}

function googleAttendees(e: GoogleEvent) {
  return (e.attendees ?? []).map(a => ({
    email:    a.email,
    name:     a.displayName ?? null,
    response: a.responseStatus === 'needsAction' ? 'no_response'
             : a.responseStatus === 'accepted'   ? 'accepted'
             : a.responseStatus === 'declined'   ? 'declined'
             : 'tentative',
    role:     a.organizer ? 'organizer' : a.optional ? 'optional' : 'required',
  }))
}

function microsoftMeetingUrl(e: MicrosoftEvent): string | null {
  return e.onlineMeeting?.joinUrl ?? e.onlineMeetingUrl ?? null
}

function microsoftAttendees(e: MicrosoftEvent) {
  return (e.attendees ?? []).map(a => ({
    email:    a.emailAddress.address,
    name:     a.emailAddress.name ?? null,
    response: a.status.response === 'accepted'  ? 'accepted'
             : a.status.response === 'declined' ? 'declined'
             : a.status.response === 'tentative' ? 'tentative'
             : 'no_response',
    role:     a.type === 'required' ? 'required' : 'optional',
  }))
}

// ─────────────────────────────────────────────
// Google sync
// ─────────────────────────────────────────────

async function syncGoogle(conn: DecryptedConnection): Promise<number> {
  let token = conn.access_token

  // refresh if expired
  if (isTokenExpired(conn.expires_at)) {
    if (!conn.refresh_token) throw new Error('No refresh token available')
    const refreshed = await refreshGoogleToken(conn.refresh_token)
    token = refreshed.access_token
    await updateAccessToken(
      conn.id,
      refreshed.access_token,
      new Date(Date.now() + refreshed.expires_in * 1000)
    )
  }

  const isIncremental = !!conn.sync_token
  const { events, syncToken } = await fetchAllGoogleEvents({
    accessToken: token,
    syncToken:   conn.sync_token ?? undefined,
  })

  if (events.length === 0) {
    await updateSyncState(conn.id, { syncToken, status: 'success' })
    return 0
  }

  const sb = serviceClient()
  const upsertRows = events.map(e => {
    const isAllDay = !!e.start.date
    const startAt  = e.start.dateTime ?? `${e.start.date}T00:00:00Z`
    const endAt    = e.end.dateTime   ?? `${e.end.date}T23:59:59Z`
    const deleted  = e.status === 'cancelled'

    return {
      organization_id:      conn.organization_id,
      user_id:              conn.user_id,
      connection_id:        conn.id,
      source:               'google',
      external_id:          e.id,
      external_etag:        e.etag,
      title:                e.summary ?? '(No title)',
      description:          e.description ?? null,
      location:             e.location ?? null,
      meeting_url:          googleMeetingUrl(e),
      start_at:             startAt,
      end_at:               endAt,
      timezone:             e.start.timeZone ?? 'UTC',
      is_all_day:           isAllDay,
      recurrence_rule:      e.recurrence?.[0] ?? null,
      recurring_event_id:   e.recurringEventId ?? null,
      is_recurrence_instance: !!e.recurringEventId,
      attendees:            googleAttendees(e),
      organizer_email:      e.organizer?.email ?? null,
      organizer_name:       e.organizer?.displayName ?? null,
      status:               deleted ? 'cancelled' : e.status,
      external_created_at:  null,
      external_modified_at: null,
    }
  })

  const { error } = await sb
    .from('calendar_events')
    .upsert(upsertRows, {
      onConflict:        'connection_id,external_id',
      ignoreDuplicates:  false,
    })

  if (error) throw error

  await updateSyncState(conn.id, { syncToken, status: 'success' })
  return events.length
}

// ─────────────────────────────────────────────
// Microsoft sync
// ─────────────────────────────────────────────

async function syncMicrosoft(conn: DecryptedConnection): Promise<number> {
  let token = conn.access_token

  if (isTokenExpired(conn.expires_at)) {
    if (!conn.refresh_token) throw new Error('No refresh token available')
    const refreshed = await refreshMicrosoftToken(conn.refresh_token)
    token = refreshed.access_token
    await updateAccessToken(
      conn.id,
      refreshed.access_token,
      new Date(Date.now() + refreshed.expires_in * 1000)
    )
  }

  const { events, deltaLink } = await fetchAllMicrosoftEvents({
    accessToken: token,
    deltaLink:   conn.delta_link ?? undefined,
  })

  if (events.length === 0) {
    await updateSyncState(conn.id, { deltaLink, status: 'success' })
    return 0
  }

  const sb = serviceClient()
  const upsertRows = events.map(e => {
    const isDeleted = !!e['@removed'] || e.isCancelled
    const startAt   = e.start.dateTime
    const endAt     = e.end.dateTime

    return {
      organization_id:      conn.organization_id,
      user_id:              conn.user_id,
      connection_id:        conn.id,
      source:               'microsoft',
      external_id:          e.id,
      external_etag:        e['@odata.etag'],
      title:                e.subject ?? '(No title)',
      description:          e.bodyPreview ?? null,
      location:             e.location?.displayName ?? null,
      meeting_url:          microsoftMeetingUrl(e),
      start_at:             startAt,
      end_at:               endAt,
      timezone:             e.start.timeZone ?? 'UTC',
      is_all_day:           e.isAllDay,
      recurring_event_id:   e.seriesMasterId ?? null,
      is_recurrence_instance: !!e.seriesMasterId,
      attendees:            microsoftAttendees(e),
      organizer_email:      e.organizer?.emailAddress?.address ?? null,
      organizer_name:       e.organizer?.emailAddress?.name    ?? null,
      status:               isDeleted ? 'cancelled' : 'confirmed',
      external_created_at:  null,
      external_modified_at: null,
    }
  })

  const { error } = await sb
    .from('calendar_events')
    .upsert(upsertRows, {
      onConflict:        'connection_id,external_id',
      ignoreDuplicates:  false,
    })

  if (error) throw error

  await updateSyncState(conn.id, { deltaLink, status: 'success' })
  return events.length
}

// ─────────────────────────────────────────────
// Main sync runner
// ─────────────────────────────────────────────

export interface SyncResult {
  connectionId:  string
  provider:      string
  accountEmail:  string
  eventsSynced:  number
  error?:        string
}

export async function syncAllConnections(organizationId: string): Promise<SyncResult[]> {
  const connections = await getActiveConnections(organizationId)
  if (connections.length === 0) return []

  const results = await Promise.allSettled(
    connections.map(async conn => {
      await updateSyncState(conn.id, { status: 'syncing' })
      const count = conn.provider === 'google'
        ? await syncGoogle(conn)
        : await syncMicrosoft(conn)

      return {
        connectionId: conn.id,
        provider:     conn.provider,
        accountEmail: conn.account_email,
        eventsSynced: count,
      } satisfies SyncResult
    })
  )

  return results.map((r, i) => {
    const conn = connections[i]!
    if (r.status === 'fulfilled') return r.value
    // Update DB on failure
    updateSyncState(conn.id, {
      status:    'failed',
      lastError: r.reason?.message ?? 'Unknown error',
    }).catch(() => {})
    return {
      connectionId: conn.id,
      provider:     conn.provider,
      accountEmail: conn.account_email,
      eventsSynced: 0,
      error:        r.reason?.message ?? 'Unknown error',
    }
  })
}
