'use server'
// src/app/actions/calendar.ts
// Server action wrappers for calendar queries (extracted for client component use).

import {
  fetchCalendarItems as _fetchCalendarItems,
  createCalendarEvent as _createCalendarEvent,
  type CalendarItem,
} from '@/lib/queries/calendar'

export async function fetchCalendarItemsAction(
  ...args: Parameters<typeof _fetchCalendarItems>
) {
  return _fetchCalendarItems(...args)
}

export async function createCalendarEventAction(
  ...args: Parameters<typeof _createCalendarEvent>
) {
  return _createCalendarEvent(...args)
}