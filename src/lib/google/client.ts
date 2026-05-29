// src/lib/google/client.ts
// Server-only helper around googleapis. Requires: npm install googleapis
import { google } from 'googleapis'
import { createSupabaseServerClient } from '@/lib/supabase/server'

// calendar.events = read + write events. email/openid = to show which Google account connected.
const SCOPES = [
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/calendar.events',
]

export function getOAuthClient() {
  return new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI,
  )
}

// URL that sends the user to Google's consent screen.
export function getAuthUrl() {
  return getOAuthClient().generateAuthUrl({
    access_type: 'offline', // needed to receive a refresh_token
    prompt: 'consent', // force Google to (re)send refresh_token
    scope: SCOPES,
  })
}

// Returns an authed Calendar client for the given user, or null if not connected.
export async function getCalendarForUser(userId: string) {
  const supabase = await createSupabaseServerClient()
  const { data } = await supabase
    .schema('app')
    .from('google_calendar_tokens' as never)
    .select('refresh_token, access_token, expiry, calendar_id')
    .eq('user_id', userId)
    .maybeSingle()

  const token = data as any
  if (!token?.refresh_token) return null

  const auth = getOAuthClient()
  auth.setCredentials({
    refresh_token: token.refresh_token,
    access_token: token.access_token ?? undefined,
    expiry_date: token.expiry ? new Date(token.expiry).getTime() : undefined,
  })

  // When googleapis silently refreshes the access token, persist it back.
  auth.on('tokens', (t) => {
    if (!t.access_token) return
    void supabase
      .schema('app')
      .from('google_calendar_tokens' as never)
      .update({
        access_token: t.access_token,
        expiry: t.expiry_date ? new Date(t.expiry_date).toISOString() : null,
        updated_at: new Date().toISOString(),
      } as never)
      .eq('user_id', userId)
  })

  const calendar = google.calendar({ version: 'v3', auth })
  return { calendar, auth, calendarId: (token.calendar_id as string) || 'primary' }
}
