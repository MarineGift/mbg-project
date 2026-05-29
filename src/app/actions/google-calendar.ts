// src/app/actions/google-calendar.ts
'use server'

import type { CalendarItem } from '@/lib/queries/calendar'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { getCalendarForUser } from '@/lib/google/client'

export async function isGoogleConnected(): Promise<boolean> {
  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return false

  const { data } = await supabase
    .schema('app')
    .from('google_calendar_tokens' as never)
    .select('user_id')
    .eq('user_id', user.id)
    .maybeSingle()

  return !!data
}

export async function disconnectGoogle(): Promise<{ ok: boolean }> {
  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { ok: false }

  await supabase
    .schema('app')
    .from('google_calendar_tokens' as never)
    .delete()
    .eq('user_id', user.id)

  return { ok: true }
}

export async function fetchGoogleCalendarItems(
  startISO: string,
  endISO: string,
): Promise<CalendarItem[]> {
  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return []

  const conn = await getCalendarForUser(user.id)
  if (!conn) return [] // not connected -> nothing to merge

  try {
    const res = await conn.calendar.events.list({
      calendarId: conn.calendarId,
      timeMin: startISO,
      timeMax: endISO,
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 500,
    })
    const events = res.data.items ?? []
    return events.map(mapEvent).filter((x): x is CalendarItem => x !== null)
  } catch (e) {
    console.error('[google-calendar] list failed:', (e as Error).message)
    return []
  }
}

// Map a Google event to the app's CalendarItem shape.
// NOTE: cast through unknown so this compiles even if your CalendarItem type
// has extra fields. If tsc complains about a missing required field, add it here.
function mapEvent(ev: any): CalendarItem | null {
  const start = ev.start?.dateTime ?? ev.start?.date
  if (!start) return null
  const end = ev.end?.dateTime ?? ev.end?.date ?? start
  const isAllDay = !ev.start?.dateTime

  return {
    id: `google:${ev.id}`,
    type: 'event',
    title: ev.summary || '(No title)',
    start_at: new Date(start).toISOString(),
    end_at: new Date(end).toISOString(),
    is_all_day: isAllDay,
    source: 'google',
    location: ev.location ?? null,
    meeting_url:
      ev.hangoutLink ?? ev.conferenceData?.entryPoints?.[0]?.uri ?? null,
    party_name: null,
  } as unknown as CalendarItem
}
