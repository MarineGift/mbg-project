// src/lib/queries/calendar.ts  (v2 - includes meetings)
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'
import { z } from 'zod'

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export type CalendarItemType = 'meeting' | 'event' | 'task' | 'communication'
export type CalendarEventSource = 'internal' | 'google' | 'microsoft'

export interface CalendarAttendee {
  email: string
  name?: string
  [key: string]: unknown
}

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
  // event edit fields (Phase 1)
  description?:   string | null
  visibility?:    string | null
  attendees?:     CalendarAttendee[] | null
  external_id?:   string | null
  connection_id?: string | null
  timezone?:      string | null
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
      id, title, description, location, meeting_url,
      start_at, end_at, is_all_day, status, source,
      visibility, attendees, external_id, connection_id, timezone,
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
      description:   e.description ?? null,
      visibility:    e.visibility ?? null,
      attendees:     (e.attendees as CalendarAttendee[]) ?? [],
      external_id:   e.external_id ?? null,
      connection_id: e.connection_id ?? null,
      timezone:      e.timezone ?? null,
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


// --------------------------------------------------
// updateCalendarEvent / deleteCalendarEvent (Phase 1)
// --------------------------------------------------

const attendeeSchema = z.object({
  email: z.string().email(),
  name:  z.string().optional(),
})

const updateCalendarEventSchema = z.object({
  title:       z.string().min(1).optional(),
  description: z.string().nullable().optional(),
  location:    z.string().nullable().optional(),
  start_at:    z.string().optional(),
  end_at:      z.string().optional(),
  is_all_day:  z.boolean().optional(),
  visibility:  z.string().optional(),
  attendees:   z.array(attendeeSchema).optional(),
})

export type UpdateCalendarEventInput = z.infer<typeof updateCalendarEventSchema>

export async function updateCalendarEvent(
  id: string,
  fields: UpdateCalendarEventInput,
) {
  const parsed = updateCalendarEventSchema.parse(fields)

  // Only update keys that were actually provided.
  const patch: Record<string, unknown> = {}
  for (const [k, v] of Object.entries(parsed)) {
    if (v !== undefined) patch[k] = v
  }
  patch.updated_at = new Date().toISOString()

  // user-session client -> RLS (pol_calendar_events_modify) enforces
  // organization_id / user_id match. org/user are never touched here.
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('calendar_events' as never)
    .update(patch as never)
    .eq('id', id)
    .select()
    .single()
  if (error) throw error
  return data
}

export async function deleteCalendarEvent(
  id: string,
  source: CalendarEventSource = 'internal',
) {
  const supabase = await createSupabaseServerClient()

  if (source === 'internal') {
    // internal events: hard delete
    const { error } = await supabase
      .schema('app')
      .from('calendar_events' as never)
      .delete()
      .eq('id', id)
    if (error) throw error
    return { id, deleted: 'hard' as const }
  }

  // google / microsoft: soft delete (status = 'cancelled') so the next
  // full-sync reconcile pass stays consistent.
  const { error } = await supabase
    .schema('app')
    .from('calendar_events' as never)
    .update({ status: 'cancelled', updated_at: new Date().toISOString() } as never)
    .eq('id', id)
  if (error) throw error
  return { id, deleted: 'soft' as const }
}
