// src/lib/calendar/google-client.ts
// Google Calendar API v3 wrapper (no googleapis package needed)

const GOOGLE_TOKEN_URL   = 'https://oauth2.googleapis.com/token'
const GOOGLE_CALENDAR_BASE = 'https://www.googleapis.com/calendar/v3'
const GOOGLE_AUTH_BASE   = 'https://accounts.google.com/o/oauth2/v2/auth'

export const GOOGLE_SCOPES = [
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/calendar.events',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
  // Drive: per-file access for URM attachment upload/download.
  // Re-consent required after adding (Settings -> Calendar -> reconnect Google).
  'https://www.googleapis.com/auth/drive.file',
].join(' ')

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export interface GoogleTokenResponse {
  access_token: string
  refresh_token?: string
  expires_in: number       // seconds
  scope: string
  token_type: string
}

export interface GoogleUserInfo {
  email: string
  name: string
}

export interface GoogleEvent {
  id: string
  etag: string
  summary?: string
  description?: string
  location?: string
  hangoutLink?: string
  start: { dateTime?: string; date?: string; timeZone?: string }
  end:   { dateTime?: string; date?: string; timeZone?: string }
  status: 'confirmed' | 'tentative' | 'cancelled'
  recurrence?: string[]
  recurringEventId?: string
  organizer?: { email: string; displayName?: string }
  attendees?: Array<{
    email: string
    displayName?: string
    responseStatus: 'needsAction' | 'accepted' | 'declined' | 'tentative'
    organizer?: boolean
    optional?: boolean
  }>
  conferenceData?: {
    entryPoints?: Array<{ uri: string; entryPointType: string }>
  }
}

export interface GoogleEventListResponse {
  items: GoogleEvent[]
  nextSyncToken?: string
  nextPageToken?: string
}

// ─────────────────────────────────────────────
// OAuth helpers
// ─────────────────────────────────────────────

export function buildGoogleAuthUrl(state: string): string {
  const params = new URLSearchParams({
    client_id:     process.env.GOOGLE_CALENDAR_CLIENT_ID!,
    redirect_uri:  process.env.GOOGLE_CALENDAR_REDIRECT_URI!,
    response_type: 'code',
    scope:         GOOGLE_SCOPES,
    access_type:   'offline',
    prompt:        'consent',
    state,
  })
  return `${GOOGLE_AUTH_BASE}?${params}`
}

export async function exchangeGoogleCode(code: string): Promise<GoogleTokenResponse> {
  const res = await fetch(GOOGLE_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id:     process.env.GOOGLE_CALENDAR_CLIENT_ID!,
      client_secret: process.env.GOOGLE_CALENDAR_CLIENT_SECRET!,
      redirect_uri:  process.env.GOOGLE_CALENDAR_REDIRECT_URI!,
      grant_type:    'authorization_code',
    }),
  })
  if (!res.ok) throw new Error(`Google token exchange failed: ${await res.text()}`)
  return res.json()
}

export async function refreshGoogleToken(refreshToken: string): Promise<GoogleTokenResponse> {
  const res = await fetch(GOOGLE_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      refresh_token: refreshToken,
      client_id:     process.env.GOOGLE_CALENDAR_CLIENT_ID!,
      client_secret: process.env.GOOGLE_CALENDAR_CLIENT_SECRET!,
      grant_type:    'refresh_token',
    }),
  })
  if (!res.ok) throw new Error(`Google token refresh failed: ${await res.text()}`)
  return res.json()
}

export async function getGoogleUserInfo(accessToken: string): Promise<GoogleUserInfo> {
  const res = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) throw new Error('Failed to fetch Google user info')
  const data = await res.json()
  return { email: data.email, name: data.name }
}

// ─────────────────────────────────────────────
// Token freshness — refresh if <5 min to expiry
// ─────────────────────────────────────────────

export function isTokenExpired(expiresAt: string | null): boolean {
  if (!expiresAt) return true
  const margin = 5 * 60 * 1000   // 5 minutes
  return new Date(expiresAt).getTime() - margin < Date.now()
}

// ─────────────────────────────────────────────
// Events API
// ─────────────────────────────────────────────

interface FetchEventsOptions {
  accessToken:  string
  calendarId?:  string        // default: 'primary'
  syncToken?:   string        // incremental sync
  timeMin?:     string        // ISO (full sync)
  pageToken?:   string
}

export async function fetchGoogleEvents(
  opts: FetchEventsOptions
): Promise<GoogleEventListResponse> {
  const calId = encodeURIComponent(opts.calendarId ?? 'primary')
  const params = new URLSearchParams({
    maxResults:  '2500',
    singleEvents: 'true',
  })

  if (opts.syncToken) {
    params.set('syncToken', opts.syncToken)
  } else {
    // Full sync: last 1 year + next 1 year
    const timeMin = opts.timeMin ?? new Date(
      Date.now() - 365 * 24 * 60 * 60 * 1000
    ).toISOString()
    params.set('timeMin', timeMin)
    params.set('orderBy', 'startTime')
  }

  if (opts.pageToken) params.set('pageToken', opts.pageToken)

  const res = await fetch(
    `${GOOGLE_CALENDAR_BASE}/calendars/${calId}/events?${params}`,
    { headers: { Authorization: `Bearer ${opts.accessToken}` } }
  )

  // 410 Gone = syncToken expired → full sync required
  if (res.status === 410) {
    return fetchGoogleEvents({ ...opts, syncToken: undefined })
  }

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Google Calendar API error ${res.status}: ${err}`)
  }

  return res.json()
}

/** collect all pages */
export async function fetchAllGoogleEvents(
  opts: Omit<FetchEventsOptions, 'pageToken'>
): Promise<{ events: GoogleEvent[]; syncToken: string }> {
  const allEvents: GoogleEvent[] = []
  let pageToken: string | undefined
  let finalSyncToken = ''

  do {
    const page = await fetchGoogleEvents({ ...opts, pageToken })
    allEvents.push(...(page.items ?? []))
    finalSyncToken = page.nextSyncToken ?? finalSyncToken
    pageToken = page.nextPageToken
  } while (pageToken)

  return { events: allEvents, syncToken: finalSyncToken }
}

// ─────────────────────────────────────────────
// Write-back: update / delete an event (Phase 5)
// ─────────────────────────────────────────────

export async function updateGoogleEvent(
  accessToken: string,
  eventId: string,
  patch: Record<string, unknown>,
  calendarId = 'primary',
): Promise<void> {
  const calId = encodeURIComponent(calendarId)
  const res = await fetch(
    `${GOOGLE_CALENDAR_BASE}/calendars/${calId}/events/${encodeURIComponent(eventId)}`,
    {
      method: 'PATCH',
      headers: {
        Authorization:  `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(patch),
    },
  )
  if (!res.ok) {
    throw new Error(`Google event update failed ${res.status}: ${await res.text()}`)
  }
}

export async function deleteGoogleEvent(
  accessToken: string,
  eventId: string,
  calendarId = 'primary',
): Promise<void> {
  const calId = encodeURIComponent(calendarId)
  const res = await fetch(
    `${GOOGLE_CALENDAR_BASE}/calendars/${calId}/events/${encodeURIComponent(eventId)}`,
    { method: 'DELETE', headers: { Authorization: `Bearer ${accessToken}` } },
  )
  // 404/410 = already gone -> treat as success
  if (!res.ok && res.status !== 404 && res.status !== 410) {
    throw new Error(`Google event delete failed ${res.status}: ${await res.text()}`)
  }
}
