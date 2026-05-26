// src/lib/calendar/microsoft-client.ts
// Microsoft Graph API 래퍼 — OAuth2 + calendarView delta

const MS_AUTH_BASE    = 'https://login.microsoftonline.com/common/oauth2/v2.0'
const MS_GRAPH_BASE   = 'https://graph.microsoft.com/v1.0'

export const MICROSOFT_SCOPES = [
  'offline_access',
  'User.Read',
  'Calendars.ReadWrite',
].join(' ')

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export interface MicrosoftTokenResponse {
  access_token:  string
  refresh_token: string
  expires_in:    number
  scope:         string
  token_type:    string
}

export interface MicrosoftUserInfo {
  email: string
  name:  string
}

export interface MicrosoftEvent {
  id:                   string
  '@odata.etag':        string
  subject?:             string
  bodyPreview?:         string
  location?:            { displayName?: string }
  onlineMeeting?:       { joinUrl?: string }
  onlineMeetingUrl?:    string
  start:                { dateTime: string; timeZone: string }
  end:                  { dateTime: string; timeZone: string }
  isAllDay:             boolean
  isCancelled:          boolean
  recurrence?:          any
  seriesMasterId?:      string
  organizer?:           { emailAddress: { address: string; name?: string } }
  attendees?:           Array<{
    emailAddress: { address: string; name?: string }
    status:       { response: string }
    type:         string
  }>
  '@removed'?:          { reason: string }   // deleted events in delta
}

export interface MicrosoftEventListResponse {
  value:              MicrosoftEvent[]
  '@odata.nextLink'?: string
  '@odata.deltaLink'?: string
}

// ─────────────────────────────────────────────
// OAuth helpers
// ─────────────────────────────────────────────

export function buildMicrosoftAuthUrl(state: string): string {
  const params = new URLSearchParams({
    client_id:     process.env.MICROSOFT_CALENDAR_CLIENT_ID!,
    redirect_uri:  process.env.MICROSOFT_CALENDAR_REDIRECT_URI!,
    response_type: 'code',
    scope:         MICROSOFT_SCOPES,
    response_mode: 'query',
    state,
  })
  return `${MS_AUTH_BASE}/authorize?${params}`
}

export async function exchangeMicrosoftCode(code: string): Promise<MicrosoftTokenResponse> {
  const res = await fetch(`${MS_AUTH_BASE}/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id:     process.env.MICROSOFT_CALENDAR_CLIENT_ID!,
      client_secret: process.env.MICROSOFT_CALENDAR_CLIENT_SECRET!,
      redirect_uri:  process.env.MICROSOFT_CALENDAR_REDIRECT_URI!,
      grant_type:    'authorization_code',
    }),
  })
  if (!res.ok) throw new Error(`Microsoft token exchange failed: ${await res.text()}`)
  return res.json()
}

export async function refreshMicrosoftToken(refreshToken: string): Promise<MicrosoftTokenResponse> {
  const res = await fetch(`${MS_AUTH_BASE}/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      refresh_token: refreshToken,
      client_id:     process.env.MICROSOFT_CALENDAR_CLIENT_ID!,
      client_secret: process.env.MICROSOFT_CALENDAR_CLIENT_SECRET!,
      grant_type:    'refresh_token',
    }),
  })
  if (!res.ok) throw new Error(`Microsoft token refresh failed: ${await res.text()}`)
  return res.json()
}

export async function getMicrosoftUserInfo(accessToken: string): Promise<MicrosoftUserInfo> {
  const res = await fetch(`${MS_GRAPH_BASE}/me`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) throw new Error('Failed to fetch Microsoft user info')
  const data = await res.json()
  return {
    email: data.mail ?? data.userPrincipalName,
    name:  data.displayName,
  }
}

// ─────────────────────────────────────────────
// Events — calendarView delta
// ─────────────────────────────────────────────

interface FetchMsEventsOptions {
  accessToken: string
  deltaLink?:  string     // incremental sync
  timeMin?:    string     // ISO (full sync)
  timeMax?:    string     // ISO (full sync)
}

export async function fetchMicrosoftEvents(
  opts: FetchMsEventsOptions
): Promise<MicrosoftEventListResponse> {
  let url: string

  if (opts.deltaLink) {
    url = opts.deltaLink
  } else {
    const timeMin = opts.timeMin ?? new Date(
      Date.now() - 365 * 24 * 60 * 60 * 1000
    ).toISOString()
    const timeMax = opts.timeMax ?? new Date(
      Date.now() + 365 * 24 * 60 * 60 * 1000
    ).toISOString()

    const params = new URLSearchParams({
      startDateTime: timeMin,
      endDateTime:   timeMax,
      $top:          '999',
      $select:       [
        'id','subject','bodyPreview','location','start','end',
        'isAllDay','isCancelled','recurrence','seriesMasterId',
        'organizer','attendees','onlineMeeting','onlineMeetingUrl',
      ].join(','),
    })
    url = `${MS_GRAPH_BASE}/me/calendarView/delta?${params}`
  }

  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${opts.accessToken}`,
      Prefer: 'odata.maxpagesize=999',
    },
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Microsoft Graph API error ${res.status}: ${err}`)
  }

  return res.json()
}

/** 모든 페이지 수집 */
export async function fetchAllMicrosoftEvents(
  opts: Omit<FetchMsEventsOptions, 'nextLink'>
): Promise<{ events: MicrosoftEvent[]; deltaLink: string }> {
  const allEvents: MicrosoftEvent[] = []
  let finalDeltaLink = ''
  let currentUrl: string | undefined

  // First fetch
  let page = await fetchMicrosoftEvents(opts)
  allEvents.push(...(page.value ?? []))

  while (page['@odata.nextLink']) {
    page = await fetchMicrosoftEvents({
      accessToken: opts.accessToken,
      deltaLink:   page['@odata.nextLink'],
    })
    allEvents.push(...(page.value ?? []))
  }

  finalDeltaLink = page['@odata.deltaLink'] ?? ''
  return { events: allEvents, deltaLink: finalDeltaLink }
}
