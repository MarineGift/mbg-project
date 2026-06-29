// src/lib/queries/calendar.ts  (v3 - todo_v2: unified getCalendarFeed read-model)
//
// getCalendarFeed(start, end, opts?) is the single aggregation read-model for the
// calendar + Today cockpit. It merges up to 7 feed sources into one CalendarItem[]:
//   event              app.calendar_events  (google / microsoft / internal)
//   meeting            app.meetings
//   deal_task          app.tasks.due_at
//   communication      app.communications.occurred_at
//   todo               app.todo_items.due_date          (pure memo To-Do; no deal_id)
//   milestone_next_step app.deals.next_step_date
//   milestone_close    app.deals.expected_close_date
//
// fetchCalendarItems(start,end) is kept as a thin back-compat wrapper that returns
// ONLY the legacy 4 sources, so the existing /calendar page is byte-for-byte
// unchanged until it is explicitly repointed to getCalendarFeed.
//
// Conventions (mbg-project, Gotcha #45): the server client does NOT default to the
// app schema at runtime -> target it explicitly with .schema('app').from('T' as never).
// todo_items / deals embeds to parties are NOT used (FK not verified); party names are
// resolved via a single batched lookup against app.parties to avoid PostgREST
// relationship errors. All-day date-only items emit start_at='YYYY-MM-DDT00:00:00'
// (no Z) so the calendar-view local-date bucketing lands on the correct day in any tz.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'
import { z } from 'zod'
import { pushEventUpdate, pushEventDelete } from '@/lib/calendar/write-back'

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

// ---------------------------------------------------------------
// Types + constants moved to ./calendar-meta (client-safe, no server imports).
// Re-exported here for back-compat with all '@/lib/queries/calendar' importers.
// ---------------------------------------------------------------
export * from './calendar-meta'
import {
  CALENDAR_FEED_META,
  CALENDAR_FEED_SOURCES,
  LEGACY_SOURCES,
} from './calendar-meta'
import type {
  CalendarEventSource,
  CalendarFeedSource,
  CalendarAttendee,
  CalendarReminder,
  CalendarItem,
  GetCalendarFeedOptions,
} from './calendar-meta'
// ─────────────────────────────────────────────
// Recurrence expansion (3-3) — internal events only
//
// Lightweight RRULE expander. The stored rule has no 'RRULE:' prefix, e.g.
// 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;UNTIL=20261231' or 'FREQ=DAILY'.
// Supported: FREQ DAILY/WEEKLY/MONTHLY/YEARLY, INTERVAL, BYDAY (weekly multi-day),
// UNTIL (date), COUNT. NOT supported (v1): nth-weekday-of-month ordinals, EXDATE,
// BYMONTHDAY lists. Unknown/empty rules degrade to a single base occurrence.
// All math is done on local-free 'YYYY-MM-DD' strings in UTC so the date walk
// never drifts; the per-occurrence wall-clock time is the base event's own.
// ─────────────────────────────────────────────

const RRULE_DOW: Record<string, number> = {
  SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6,
}
const RRULE_ITER_CAP = 4000   // hard stop against pathological / unbounded rules
const RRULE_OCC_CAP  = 400    // max occurrences emitted per event within a range

interface ParsedRRule {
  freq?: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY'
  interval: number
  count?: number
  until?: string            // 'YYYY-MM-DD'
  byday?: number[]          // 0=Sun..6=Sat
}

function parseRRule(raw: string): ParsedRRule {
  const out: ParsedRRule = { interval: 1 }
  const body = (raw || '').trim().toUpperCase().replace(/^RRULE:/, '')
  for (const part of body.split(';')) {
    const [k, v] = part.split('=')
    if (!k || !v) continue
    if (k === 'FREQ' && (v === 'DAILY' || v === 'WEEKLY' || v === 'MONTHLY' || v === 'YEARLY')) {
      out.freq = v
    } else if (k === 'INTERVAL') {
      const n = parseInt(v, 10)
      if (Number.isFinite(n) && n > 0) out.interval = n
    } else if (k === 'COUNT') {
      const n = parseInt(v, 10)
      if (Number.isFinite(n) && n > 0) out.count = n
    } else if (k === 'UNTIL') {
      const digits = v.replace(/[^0-9]/g, '')
      if (digits.length >= 8) {
        out.until = `${digits.slice(0, 4)}-${digits.slice(4, 6)}-${digits.slice(6, 8)}`
      }
    } else if (k === 'BYDAY') {
      const days = v.split(',')
        .map((tok) => tok.replace(/^[+-]?\d+/, '').trim())   // drop ordinal prefix (v1)
        .map((code) => RRULE_DOW[code])
        .filter((n): n is number => n !== undefined)
      if (days.length) out.byday = Array.from(new Set(days)).sort((a, b) => a - b)
    }
  }
  return out
}

function ymdAddDays(ymd: string, n: number): string {
  const [y, mo, d] = ymd.split('-').map(Number) as [number, number, number]
  const dt = new Date(Date.UTC(y, mo - 1, d))
  dt.setUTCDate(dt.getUTCDate() + n)
  return dt.toISOString().slice(0, 10)
}

// same day-of-month n months later; null if that day doesn't exist (e.g. 31st)
function ymdAddMonths(ymd: string, n: number): string | null {
  const [y, mo, d] = ymd.split('-').map(Number) as [number, number, number]
  const anchor = new Date(Date.UTC(y, mo - 1, 1))
  anchor.setUTCMonth(anchor.getUTCMonth() + n)
  const ty = anchor.getUTCFullYear()
  const tm = anchor.getUTCMonth()
  const daysInMonth = new Date(Date.UTC(ty, tm + 1, 0)).getUTCDate()
  if (d > daysInMonth) return null
  return `${ty}-${String(tm + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`
}

// same month/day n years later; null for Feb 29 in a non-leap year
function ymdAddYears(ymd: string, n: number): string | null {
  const [y, mo, d] = ymd.split('-').map(Number) as [number, number, number]
  const ty = y + n
  const daysInMonth = new Date(Date.UTC(ty, mo, 0)).getUTCDate()
  if (d > daysInMonth) return null
  return `${ty}-${String(mo).padStart(2, '0')}-${String(d).padStart(2, '0')}`
}

function ymdDow(ymd: string): number {
  const [y, mo, d] = ymd.split('-').map(Number) as [number, number, number]
  return new Date(Date.UTC(y, mo - 1, d)).getUTCDay()
}

// Return the in-range occurrence dates ('YYYY-MM-DD') for a rule, inclusive.
function expandOccurrenceDates(
  baseYmd: string,
  rule: ParsedRRule,
  startYmd: string,
  endYmd: string,
): string[] {
  const { freq, interval, count, until, byday } = rule
  if (!freq) return baseYmd >= startYmd && baseYmd <= endYmd ? [baseYmd] : []

  const out: string[] = []
  let produced = 0   // counts every real occurrence from the series start (for COUNT)

  // returns false when the whole series should stop
  const consider = (ymd: string): boolean => {
    if (ymd < baseYmd) return true          // ignore dates before the series start
    if (until && ymd > until) return false
    produced++
    if (ymd >= startYmd && ymd <= endYmd && out.length < RRULE_OCC_CAP) out.push(ymd)
    if (count && produced >= count) return false
    return true
  }

  if (freq === 'WEEKLY') {
    const days = byday?.length ? byday : [ymdDow(baseYmd)]
    let weekStart = ymdAddDays(baseYmd, -ymdDow(baseYmd))   // Sunday of the base week
    let block = 0
    for (let i = 0; i < RRULE_ITER_CAP; i++) {
      if (block % interval === 0) {
        for (const dow of days) {
          if (!consider(ymdAddDays(weekStart, dow))) return out
        }
      }
      weekStart = ymdAddDays(weekStart, 7)
      block++
      if (weekStart > endYmd) break
    }
    return out
  }

  for (let k = 0; k < RRULE_ITER_CAP; k++) {
    let occ: string | null = null
    if (freq === 'DAILY')        occ = ymdAddDays(baseYmd, interval * k)
    else if (freq === 'MONTHLY') occ = ymdAddMonths(baseYmd, interval * k)
    else if (freq === 'YEARLY')  occ = ymdAddYears(baseYmd, interval * k)
    if (occ === null) continue                 // invalid day (31st / Feb 29) -> skip
    if (occ > endYmd) break                    // dates strictly increase
    if (!consider(occ)) break
  }
  return out
}

// Rebuild a single occurrence's start/end from the base event, shifting only the
// date and preserving the base's wall-clock time, zone format and duration.
function occurrenceTimes(
  e: { start_at: string; end_at?: string | null },
  ymd: string,
): { start_at: string; end_at: string } {
  const baseStart = String(e.start_at)
  const baseEnd   = String(e.end_at || e.start_at)
  const suffix    = baseStart.length > 10 ? baseStart.slice(10) : 'T00:00:00'
  const startAt   = `${ymd}${suffix}`
  let durMs = new Date(baseEnd).getTime() - new Date(baseStart).getTime()
  if (!Number.isFinite(durMs) || durMs < 0) durMs = 0
  const endAt = new Date(new Date(startAt).getTime() + durMs).toISOString()
  return { start_at: startAt, end_at: endAt }
}

export async function getCalendarFeed(
  rangeStart: string,
  rangeEnd:   string,
  opts?: GetCalendarFeedOptions,
): Promise<CalendarItem[]> {
  const supabase = await createSupabaseServerClient()

  const sources = opts?.sources ?? CALENDAR_FEED_SOURCES
  const want = (s: CalendarFeedSource) => sources.includes(s)

  // Date-typed columns (todo.due_date, deals.*_date) compare cleanly on the date part.
  const startDate = rangeStart.slice(0, 10)
  const endDate   = rangeEnd.slice(0, 10)
  const inRange = (d: string | null | undefined): d is string =>
    !!d && d >= startDate && d <= endDate

  const noRows = Promise.resolve({ data: [] as unknown[] } as { data: unknown[] })
  const wantDeals = want('milestone_next_step') || want('milestone_close')

  const [eventsRes, meetingsRes, tasksRes, commsRes, todosRes, dealsRes] =
    await Promise.all([
      // 1. calendar_events (google/ms/internal - those without a meeting_id)
      want('event')
        ? supabase.schema('app').from('calendar_events' as never).select(`
            id, title, description, location, meeting_url,
            start_at, end_at, is_all_day, status, source,
            visibility, attendees, external_id, connection_id, timezone,
            color, recurrence_rule, reminders, transparency,
            party_id, engagement_id, meeting_id,
            parties ( name:party_name )
          `)
          // Normal rows must start within the range. Internal recurring MASTERS
          // whose base start_at is BEFORE rangeStart must also be pulled so we can
          // expand their occurrences into the range (see expandOccurrenceDates).
          .lte('start_at', rangeEnd)
          .or(
            `and(source.eq.internal,recurrence_rule.not.is.null),` +
            `start_at.gte.${startDate}`,
          )
          .is('meeting_id', null)
          .neq('status', 'cancelled')
          .order('start_at')
        : noRows,

      // 2. meetings
      want('meeting')
        ? supabase.schema('app').from('meetings' as never).select(`
            id, title, meeting_type,
            scheduled_at, duration_min, status,
            location, meeting_url,
            party_id, engagement_id,
            parties ( name:party_name )
          `)
          .gte('scheduled_at', rangeStart)
          .lte('scheduled_at', rangeEnd)
          .neq('status', 'cancelled')
          .order('scheduled_at')
        : noRows,

      // 3. deal tasks with due_at
      want('deal_task')
        ? supabase.schema('app').from('tasks' as never).select(`
            id, title, due_at, deal_id
          `)
          .not('due_at', 'is', null)
          .gte('due_at', rangeStart)
          .lte('due_at', rangeEnd)
          .is('deleted_at', null)
          .order('due_at')
        : noRows,

      // 4. communications with occurred_at
      want('communication')
        ? supabase.schema('app').from('communications' as never).select(`
            id, subject, occurred_at,
            party_id,
            parties ( name:party_name )
          `)
          .not('occurred_at', 'is', null)
          .gte('occurred_at', rangeStart)
          .lte('occurred_at', rangeEnd)
          .is('deleted_at', null)
          .order('occurred_at')
        : noRows,

      // 5. To-Do items with due_date (pure memo; no parties embed - FK unverified)
      want('todo')
        ? supabase.schema('app').from('todo_items' as never).select(`
            id, title, due_date, status, priority, party_id, board_id
          `)
          .not('due_date', 'is', null)
          .gte('due_date', startDate)
          .lte('due_date', endDate)
          .is('archived_at', null)
          .order('due_date')
        : noRows,

      // 6. Deal milestones (open deals only); one row -> up to two items
      wantDeals
        ? supabase.schema('app').from('deals' as never).select(`
            id, deal_name, next_step, next_step_date, expected_close_date,
            status, party_id
          `)
          .eq('status', 'active')
          .is('deleted_at', null)
          .or(
            `and(next_step_date.gte.${startDate},next_step_date.lte.${endDate}),` +
            `and(expected_close_date.gte.${startDate},expected_close_date.lte.${endDate})`,
          )
        : noRows,
    ])

  const todoRows  = (todosRes.data ?? []) as any[]
  const dealRows  = (dealsRes.data ?? []) as any[]

  // Batched party-name lookup for the two embed-free sources (todo + milestones).
  const partyIds = Array.from(new Set(
    [...todoRows, ...dealRows]
      .map((r) => r.party_id as string | null)
      .filter((x): x is string => !!x),
  ))
  const nameMap = new Map<string, string>()
  if (partyIds.length) {
    const { data: pr } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, name')
      .in('id', partyIds)
    for (const p of (pr ?? []) as any[]) nameMap.set(p.id, p.name)
  }
  const nameOf = (id: string | null | undefined): string | null =>
    id ? nameMap.get(id) ?? null : null

  const items: CalendarItem[] = []

  // calendar_events (recurring internal events are expanded into occurrences)
  const buildEventItem = (e: any, over?: Partial<CalendarItem>): CalendarItem => ({
    id:            e.id,
    type:          'event',
    feed_source:   'event',
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
    color:           e.color ?? null,  // keep null so chip uses per-source color; only real Google colors override
    recurrence_rule: e.recurrence_rule ?? null,
    reminders:       (e.reminders as CalendarReminder[]) ?? [],
    transparency:    e.transparency ?? null,
    party_id:      e.party_id    ?? null,
    party_name:    (e.parties as any)?.name ?? null,
    engagement_id: e.engagement_id ?? null,
    source_event_id: null,
    ...over,
  })

  for (const e of (eventsRes.data ?? []) as any[]) {
    // Only internal events are expanded locally. Google/Microsoft recurring
    // events arrive already materialised by their own sync, so they pass through.
    const canExpand = e.source === 'internal' && !!e.recurrence_rule
    if (!canExpand) {
      items.push(buildEventItem(e))
      continue
    }

    const baseYmd = String(e.start_at).slice(0, 10)
    const occYmds = expandOccurrenceDates(
      baseYmd, parseRRule(String(e.recurrence_rule)), startDate, endDate,
    )
    // recurring but nothing in range -> emit nothing for this event
    for (const ymd of occYmds) {
      const { start_at, end_at } = occurrenceTimes(e, ymd)
      items.push(buildEventItem(e, {
        id:              `${e.id}__${ymd}`,   // unique React key per occurrence
        source_event_id: e.id,                // popup/edit/delete resolve the real row via this
        start_at,
        end_at,
      }))
    }
  }

  // meetings
  for (const m of (meetingsRes.data ?? []) as any[]) {
    const endAt = new Date(
      new Date(m.scheduled_at).getTime() + (m.duration_min ?? 30) * 60_000,
    ).toISOString()
    items.push({
      id:            m.id,
      type:          'meeting',
      feed_source:   'meeting',
      title:         m.title,
      start_at:      m.scheduled_at,
      end_at:        endAt,
      is_all_day:    false,
      status:        m.status,
      location:      m.location,
      meeting_url:   m.meeting_url,
      meeting_type:  m.meeting_type,
      color:         CALENDAR_FEED_META.meeting.color,
      party_id:      m.party_id      ?? null,
      party_name:    (m.parties as any)?.name ?? null,
      engagement_id: m.engagement_id ?? null,
    })
  }

  // deal tasks
  for (const t of (tasksRes.data ?? []) as any[]) {
    items.push({
      id:            t.id,
      type:          'task',
      feed_source:   'deal_task',
      title:         t.title,
      start_at:      t.due_at,
      end_at:        t.due_at,
      is_all_day:    true,
      color:         CALENDAR_FEED_META.deal_task.color,
      party_id:      null,
      party_name:    null,
      engagement_id: t.deal_id ?? null,
      deal_id:       t.deal_id ?? null,
    })
  }

  // communications
  for (const c of (commsRes.data ?? []) as any[]) {
    items.push({
      id:            c.id,
      type:          'communication',
      feed_source:   'communication',
      title:         c.subject ?? '(No subject)',
      start_at:      c.occurred_at,
      end_at:        c.occurred_at,
      is_all_day:    false,
      color:         CALENDAR_FEED_META.communication.color,
      party_id:      c.party_id ?? null,
      party_name:    (c.parties as any)?.name ?? null,
      engagement_id: null,
    })
  }

  // To-Do items (all-day; local-midnight format to avoid tz off-by-one)
  for (const t of todoRows) {
    const d = t.due_date as string  // 'YYYY-MM-DD'
    items.push({
      id:            t.id,
      type:          'todo',
      feed_source:   'todo',
      title:         t.title,
      start_at:      `${d}T00:00:00`,
      end_at:        `${d}T00:00:00`,
      is_all_day:    true,
      status:        t.status ?? undefined,
      color:         CALENDAR_FEED_META.todo.color,
      party_id:      t.party_id ?? null,
      party_name:    nameOf(t.party_id),
      engagement_id: null,
      board_id:      t.board_id ?? null,
      deal_id:       null,
    })
  }

  // Deal milestones - emit up to two items per open deal
  for (const dl of dealRows) {
    const dealName = dl.deal_name as string

    if (want('milestone_next_step') && inRange(dl.next_step_date)) {
      const d = dl.next_step_date as string
      items.push({
        id:             `${dl.id}:next_step`,
        type:           'milestone',
        feed_source:    'milestone_next_step',
        milestone_kind: 'next_step',
        title:          dl.next_step ? `${dealName} - ${dl.next_step}` : `${dealName} - next step`,
        start_at:       `${d}T00:00:00`,
        end_at:         `${d}T00:00:00`,
        is_all_day:     true,
        status:         dl.status ?? undefined,
        color:          CALENDAR_FEED_META.milestone_next_step.color,
        party_id:       dl.party_id ?? null,
        party_name:     nameOf(dl.party_id),
        engagement_id:  dl.id,
        deal_id:        dl.id,
      })
    }

    if (want('milestone_close') && inRange(dl.expected_close_date)) {
      const d = dl.expected_close_date as string
      items.push({
        id:             `${dl.id}:close`,
        type:           'milestone',
        feed_source:    'milestone_close',
        milestone_kind: 'close',
        title:          `${dealName} - expected close`,
        start_at:       `${d}T00:00:00`,
        end_at:         `${d}T00:00:00`,
        is_all_day:     true,
        status:         dl.status ?? undefined,
        color:          CALENDAR_FEED_META.milestone_close.color,
        party_id:       dl.party_id ?? null,
        party_name:     nameOf(dl.party_id),
        engagement_id:  dl.id,
        deal_id:        dl.id,
      })
    }
  }

  return items.sort((a, b) => a.start_at.localeCompare(b.start_at))
}

// ─────────────────────────────────────────────
// fetchCalendarItems - back-compat wrapper (legacy 4 sources only)
// ─────────────────────────────────────────────

export async function fetchCalendarItems(
  rangeStart: string,
  rangeEnd:   string,
): Promise<CalendarItem[]> {
  return getCalendarFeed(rangeStart, rangeEnd, { sources: LEGACY_SOURCES })
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
  recurrence_rule?: string | null
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

const reminderSchema = z.object({
  minutes: z.number().int().min(0).max(40320),
  method:  z.string().optional(),
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
  // Phase 2
  color:           z.string().nullable().optional(),
  recurrence_rule: z.string().nullable().optional(),
  reminders:       z.array(reminderSchema).optional(),
  transparency:    z.string().optional(),
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

  // Phase 5: best-effort write-back to the external calendar.
  const urow = data as Record<string, unknown>
  if (
    (urow.source === 'google' || urow.source === 'microsoft') &&
    urow.connection_id && urow.external_id
  ) {
    const wb = await pushEventUpdate({
      source:       urow.source as 'google' | 'microsoft',
      connectionId: urow.connection_id as string,
      externalId:   urow.external_id as string,
      fields: {
        title:       urow.title as string,
        description: (urow.description as string | null) ?? null,
        location:    (urow.location as string | null) ?? null,
        start_at:    urow.start_at as string,
        end_at:      urow.end_at as string,
        is_all_day:  urow.is_all_day as boolean,
        timezone:    (urow.timezone as string | null) ?? null,
      },
    })
    if (!wb.ok) console.error('[calendar write-back][update]', wb.error)
  }

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

  // google / microsoft: try to delete on the external calendar first (Phase 5),
  // then mirror locally. We need connection_id + external_id, so read the row.
  const { data: linkRaw } = await supabase
    .schema('app')
    .from('calendar_events' as never)
    .select('connection_id, external_id')
    .eq('id', id)
    .single()
  const link = (linkRaw ?? {}) as { connection_id?: string | null; external_id?: string | null }

  let wb: { ok: boolean; error?: string } = { ok: false, error: 'missing external linkage' }
  if (link.connection_id && link.external_id) {
    wb = await pushEventDelete({
      source:       source as 'google' | 'microsoft',
      connectionId: link.connection_id,
      externalId:   link.external_id,
    })
  }

  if (wb.ok) {
    // external delete succeeded -> remove locally too
    const { error: delErr } = await supabase
      .schema('app')
      .from('calendar_events' as never)
      .delete()
      .eq('id', id)
    if (delErr) throw delErr
    return { id, deleted: 'hard' as const, external: 'deleted' as const }
  }

  // external delete failed/absent -> fall back to local soft-cancel so the next
  // full-sync reconcile pass stays consistent.
  const { error } = await supabase
    .schema('app')
    .from('calendar_events' as never)
    .update({ status: 'cancelled', updated_at: new Date().toISOString() } as never)
    .eq('id', id)
  if (error) throw error
  console.error('[calendar write-back][delete]', wb.error)
  return { id, deleted: 'soft' as const, external: 'failed' as const, error: wb.error }
}
