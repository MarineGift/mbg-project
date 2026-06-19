// src/lib/queries/calendar.ts  (v2 - includes meetings)
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export type CalendarItemType = 'meeting' | 'event' | 'task' | 'communication'
export type CalendarEventSource = 'internal' | 'google' | 'microsoft'

export interface CalendarItem {
  id:            string
  type:          CalendarItemType
  title:         string
  start_at:      string
  end_at:        string
  is_all_day:    boolean
  // context
  party_id:      string | null
  party_name:    string | null
  engagement_id: string | null
  // extras
  source?:       CalendarEventSource
  meeting_url?:  string | null
  status?:       string
  location?:     string | null
  // meeting-specific
  meeting_type?: string
}

// ─────────────────────────────────────────────
// fetchCalendarItems - unified query
// ─────────────────────────────────────────────

export async function fetchCalendarItems(
  rangeStart: string,
  rangeEnd:   string
): Promise<CalendarItem[]> {
  const supabase = await createSupabaseServerClient()

  const [eventsRes, meetingsRes, tasksRes, commsRes] = await Promise.all([

    // 1. calendar_events (Google/MS/internal - those without a meeting_id)
    supabase.schema('app').from('calendar_events' as never).select(`
      id, title, location, meeting_url,
      start_at, end_at, is_all_day, status, source,
      party_id, engagement_id, meeting_id,
      parties ( name:party_name )
    `)
    .gte('start_at', rangeStart)
    .lte('start_at', rangeEnd)
    .is('meeting_id', null)            // rows that have a meeting go through the meetings query
    .neq('status', 'cancelled')
    .order('start_at'),

    // 2. meetings (includes both with and without a calendar_event_id)
    supabase.schema('app').from('meetings' as never).select(`
      id, title, meeting_type,
      scheduled_at, duration_min, status,
      location, meeting_url,
      party_id, engagement_id,
      parties ( name:party_name )
    `)
    .gte('scheduled_at', rangeStart)
    .lte('scheduled_at', rangeEnd)
    .neq('status', 'cancelled')
    .order('scheduled_at'),

    // 3. tasks with due_at
    supabase.schema('app').from('tasks' as never).select(`
      id, title, due_at, deal_id
    `)
    .not('due_at', 'is', null)
    .gte('due_at', rangeStart)
    .lte('due_at', rangeEnd)
    .is('deleted_at', null)
    .order('due_at'),

    // 4. communications with occurred_at
    supabase.schema('app').from('communications' as never).select(`
      id, subject, occurred_at,
      party_id,
      parties ( name:party_name )
    `)
    .not('occurred_at', 'is', null)
    .gte('occurred_at', rangeStart)
    .lte('occurred_at', rangeEnd)
    .is('deleted_at', null)
    .order('occurred_at'),
  ])

  const items: CalendarItem[] = []

  // calendar_events
  for (const e of (eventsRes.data ?? []) as any[]) {
    items.push({
      id:            e.id,
      type:          'event',
      title:         e.title,
      start_at:      e.start_at,
      end_at:        e.end_at,
      is_all_day:    e.is_all_day,
      source:        e.source as CalendarEventSource,
      status:        e.status,
      location:      e.location,
      meeting_url:   e.meeting_url,
      party_id:      e.party_id    ?? null,
      party_name:    (e.parties as any)?.name ?? null,
      engagement_id: e.engagement_id ?? null,
    })
  }

  // meetings
  for (const m of (meetingsRes.data ?? []) as any[]) {
    const endAt = new Date(
      new Date(m.scheduled_at).getTime() + (m.duration_min ?? 30) * 60_000
    ).toISOString()
    items.push({
      id:            m.id,
      type:          'meeting',
      title:         m.title,
      start_at:      m.scheduled_at,
      end_at:        endAt,
      is_all_day:    false,
      status:        m.status,
      location:      m.location,
      meeting_url:   m.meeting_url,
      meeting_type:  m.meeting_type,
      party_id:      m.party_id      ?? null,
      party_name:    (m.parties as any)?.name ?? null,
      engagement_id: m.engagement_id ?? null,
    })
  }

  // tasks
  for (const t of (tasksRes.data ?? []) as any[]) {
    items.push({
      id:            t.id,
      type:          'task',
      title:         t.title,
      start_at:      t.due_at,
      end_at:        t.due_at,
      is_all_day:    true,
      party_id:      null,
      party_name:    null,
      engagement_id: t.deal_id ?? null,
    })
  }

  // communications
  for (const c of (commsRes.data ?? []) as any[]) {
    items.push({
      id:            c.id,
      type:          'communication',
      title:         c.subject ?? '(No subject)',
      start_at:      c.occurred_at,
      end_at:        c.occurred_at,
      is_all_day:    false,
      party_id:      c.party_id ?? null,
      party_name:    (c.parties as any)?.name ?? null,
      engagement_id: null,
    })
  }

  return items.sort((a, b) => a.start_at.localeCompare(b.start_at))
}

// ─────────────────────────────────────────────
// createCalendarEvent - create an internal event
// ─────────────────────────────────────────────

export interface CreateCalendarEventInput {
  title:         string
  description?:  string
  location?:     string
  meeting_url?:  string
  start_at:      string
  end_at:        string
  is_all_day?:   boolean
  party_id?:     string
  engagement_id?: string
}

export async function createCalendarEvent(input: CreateCalendarEventInput) {
  const auth = await requireAuth()
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('calendar_events' as never)
    .insert({
      ...input,
      source: 'internal',
      is_all_day: input.is_all_day ?? false,
      organization_id: auth.organizationId,
      user_id: auth.userId,
    } as never)
    .select()
    .single()
  if (error) throw error
  return data
}
