// src/lib/calendar/microsoft-client.ts
// Microsoft Graph API wrapper - OAuth2 + calendarView (full range)

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
// Events — calendarView (full range, no delta)
//
// We use the plain /me/calendarView endpoint instead of
// /me/calendarView/delta. The delta endpoint silently returns only a
// very narrow default window when the time range is supplied via query
// string, which caused most Outlook events to be missed. Plain
// calendarView accepts startDateTime / endDateTime as query params and
// expands recurring events into instances. We always fetch the full
// +/- 1 year window; the event volume is small enough that a full
// fetch on every sync is fine.
// ─────────────────────────────────────────────

interface FetchMsEventsOptions {
  accessToken: string
  deltaLink?:  string     // kept for signature compatibility; unused now
  timeMin?:    string     // ISO
  timeMax?:    string     // ISO
}

const MS_EVENT_SELECT = [
  'id','subject','bodyPreview','location','start','end',
  'isAllDay','isCancelled','recurrence','seriesMasterId',
  'organizer','attendees','onlineMeeting','onlineMeetingUrl',
].join(',')

export async function fetchMicrosoftEvents(
  opts: FetchMsEventsOptions
): Promise<MicrosoftEventListResponse> {
  const timeMin = opts.timeMin ?? new Date(
    Date.now() - 365 * 24 * 60 * 60 * 1000
  ).toISOString()
  const timeMax = opts.timeMax ?? new Date(
    Date.now() + 365 * 24 * 60 * 60 * 1000
  ).toISOString()

  const params = new URLSearchParams({
    startDateTime: timeMin,
    endDateTime:   timeMax,
    $select:       MS_EVENT_SELECT,
    $orderby:      'start/dateTime',
    $top:          '999',
  })
  const url = `${MS_GRAPH_BASE}/me/calendarView?${params}`

  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${opts.accessToken}`,
      Prefer: 'outlook.timezone="UTC", odata.maxpagesize=999',
    },
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Microsoft Graph API error ${res.status}: ${err}`)
  }

  return res.json()
}

/** Follow an absolute @odata.nextLink page URL. */
async function fetchMicrosoftPage(
  accessToken: string,
  pageUrl: string
): Promise<MicrosoftEventListResponse> {
  const res = await fetch(pageUrl, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Prefer: 'outlook.timezone="UTC", odata.maxpagesize=999',
    },
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Microsoft Graph API error ${res.status}: ${err}`)
  }
  return res.json()
}

/** collect all pages */
export async function fetchAllMicrosoftEvents(
  opts: Omit<FetchMsEventsOptions, 'nextLink'>
): Promise<{ events: MicrosoftEvent[]; deltaLink: string }> {
  const allEvents: MicrosoftEvent[] = []

  // First page (full range)
  let page = await fetchMicrosoftEvents(opts)
  allEvents.push(...(page.value ?? []))

  // Follow nextLink pages (absolute URLs that already encode the range)
  while (page['@odata.nextLink']) {
    page = await fetchMicrosoftPage(opts.accessToken, page['@odata.nextLink'])
    allEvents.push(...(page.value ?? []))
  }

  // No delta token in this mode: return empty so the engine always
  // performs a full fetch next time.
  return { events: allEvents, deltaLink: '' }
}

// ─────────────────────────────────────────────
// Write-back: update / delete an event (Phase 5)
// ─────────────────────────────────────────────

export async function updateMicrosoftEvent(
  accessToken: string,
  eventId: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const res = await fetch(`${MS_GRAPH_BASE}/me/events/${encodeURIComponent(eventId)}`, {
    method: 'PATCH',
    headers: {
      Authorization:  `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(patch),
  })
  if (!res.ok) {
    throw new Error(`Microsoft event update failed ${res.status}: ${await res.text()}`)
  }
}

export async function deleteMicrosoftEvent(
  accessToken: string,
  eventId: string,
): Promise<void> {
  const res = await fetch(`${MS_GRAPH_BASE}/me/events/${encodeURIComponent(eventId)}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  // 404/410 = already gone -> treat as success
  if (!res.ok && res.status !== 404 && res.status !== 410) {
    throw new Error(`Microsoft event delete failed ${res.status}: ${await res.text()}`)
  }
}
