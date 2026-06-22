// src/lib/queries/calendar-meta.ts
//
// Client-safe types + constants for the calendar / Today cockpit.
// queries/calendar.ts imports server-only modules (next/headers, server-only);
// any Client Component importing a *value* from it pulled that into the client
// bundle and broke `next build`. These declarations have zero server deps, so
// they live here and are re-exported from queries/calendar.ts for back-compat.

export type CalendarItemType =
  | 'meeting' | 'event' | 'task' | 'communication' | 'todo' | 'milestone'
export type CalendarEventSource = 'internal' | 'google' | 'microsoft'

export type CalendarFeedSource =
  | 'event'
  | 'meeting'
  | 'deal_task'
  | 'communication'
  | 'todo'
  | 'milestone_next_step'
  | 'milestone_close'

export interface CalendarFeedSourceMeta {
  label: string
  color: string
  defaultVisible: boolean
}

export const CALENDAR_FEED_META: Record<CalendarFeedSource, CalendarFeedSourceMeta> = {
  event:               { label: 'Calendar events', color: '#3b82f6', defaultVisible: true  },
  meeting:             { label: 'Meetings',        color: '#8b5cf6', defaultVisible: true  },
  deal_task:           { label: 'Deal tasks',      color: '#0ea5e9', defaultVisible: true  },
  communication:       { label: 'Communications',  color: '#64748b', defaultVisible: true  },
  todo:                { label: 'To-Do',           color: '#10b981', defaultVisible: true  },
  milestone_next_step: { label: 'Deal: next step', color: '#f59e0b', defaultVisible: true  },
  milestone_close:     { label: 'Deal: close',     color: '#ef4444', defaultVisible: false },
}

export const CALENDAR_FEED_SOURCES: CalendarFeedSource[] =
  Object.keys(CALENDAR_FEED_META) as CalendarFeedSource[]

export const LEGACY_SOURCES: CalendarFeedSource[] =
  ['event', 'meeting', 'deal_task', 'communication']

export interface CalendarAttendee {
  email: string
  name?: string
  [key: string]: unknown
}

export interface CalendarReminder {
  minutes: number
  method?: string
  [key: string]: unknown
}

export interface CalendarItem {
  id:            string
  type:          CalendarItemType
  title:         string
  start_at:      string
  end_at:        string
  is_all_day:    boolean
  party_id:      string | null
  party_name:    string | null
  engagement_id: string | null
  source?:       CalendarEventSource
  meeting_url?:  string | null
  status?:       string
  location?:     string | null
  meeting_type?: string
  description?:   string | null
  visibility?:    string | null
  attendees?:     CalendarAttendee[] | null
  external_id?:   string | null
  connection_id?: string | null
  timezone?:      string | null
  color?:           string | null
  recurrence_rule?: string | null
  reminders?:       CalendarReminder[] | null
  transparency?:    string | null
  feed_source?:    CalendarFeedSource
  milestone_kind?: 'next_step' | 'close'
  deal_id?:        string | null
  board_id?:       string | null
}

export interface GetCalendarFeedOptions {
  sources?: CalendarFeedSource[]
}