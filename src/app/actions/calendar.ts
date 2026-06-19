'use server'
// src/app/actions/calendar.ts
// Server action wrappers for calendar queries (extracted for client component use).

import {
  fetchCalendarItems as _fetchCalendarItems,
  createCalendarEvent as _createCalendarEvent,
  updateCalendarEvent as _updateCalendarEvent,
  deleteCalendarEvent as _deleteCalendarEvent,
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


export async function updateCalendarEventAction(
  ...args: Parameters<typeof _updateCalendarEvent>
) {
  return _updateCalendarEvent(...args)
}

export async function deleteCalendarEventAction(
  ...args: Parameters<typeof _deleteCalendarEvent>
) {
  return _deleteCalendarEvent(...args)
}
