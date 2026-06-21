'use server'
// src/app/actions/calendar.ts
// Server action wrappers for calendar queries (extracted for client component use).

import {
  fetchCalendarItems as _fetchCalendarItems,
  getCalendarFeed as _getCalendarFeed,
  createCalendarEvent as _createCalendarEvent,
  updateCalendarEvent as _updateCalendarEvent,
  deleteCalendarEvent as _deleteCalendarEvent,
  type CalendarItem,
} from '@/lib/queries/calendar'
import { sendOutboundManual } from '@/lib/actions/communications'

export async function fetchCalendarItemsAction(
  ...args: Parameters<typeof _fetchCalendarItems>
) {
  return _fetchCalendarItems(...args)
}

export async function getCalendarFeedAction(
  ...args: Parameters<typeof _getCalendarFeed>
) {
  return _getCalendarFeed(...args)
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

// Phase 3: email the attendees of an event. Reuses the verified manual-compose
// outbound path (whitelist + tracking + communications insert all in the core).
export async function sendEventEmailAction(input: {
  to: string
  subject: string
  bodyPlain: string
  cc?: string
  partyId?: string | null
}) {
  return sendOutboundManual({
    to:        input.to,
    subject:   input.subject,
    bodyPlain: input.bodyPlain,
    cc:        input.cc,
    partyId:   input.partyId ?? null,
  })
}
