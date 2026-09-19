'use server'
// src/app/actions/add-email-to-calendar.ts
//
// 2026-09-19 - "Add to Calendar" from an email.
//
// An email was sent (or received) carrying a Google Meet link and a proposed
// time. This writes that into the URM calendar so it shows up on /calendar and
// /today like any other meeting.
//
// Two write paths, because app.meetings.party_id is NOT NULL:
//   party known   -> app.meetings   (createMeeting; feeds the 'meeting' source)
//   party unknown -> app.calendar_events (source 'internal'; party_id nullable)
// Both are already read by getCalendarFeed(), so the chip appears either way.
//
// No schema change: the source email is recorded in the agenda/description text
// rather than a new communication_id column.
//
// Returns a result object (never throws) so the real Postgres message reaches
// the modal - Next.js swallows thrown errors in production builds.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { createMeeting, type MeetingChannel } from '@/lib/queries/meetings'
import { createCalendarEvent } from '@/lib/queries/calendar'

export interface AddEmailToCalendarInput {
  /** Source email. Stored as a text reference in the agenda/description. */
  communicationId?: string | null
  partyId?: string | null
  title: string
  /** Absolute instant, ISO-8601. The modal computes this from wall clock + tz. */
  startIso: string
  durationMin: number
  meetingUrl?: string | null
  location?: string | null
  agenda?: string | null
  meetingType?: string
  channel?: MeetingChannel
  attendees?: Array<{ email: string; name?: string | null }>
  /** Set on the retry after a duplicate warning. */
  allowDuplicate?: boolean
}

export type AddEmailToCalendarResult =
  | { ok: true; kind: 'meeting' | 'event'; id: string }
  | { ok: false; error: string; duplicate?: boolean }

function toMessage(e: unknown): string {
  const err = e as { message?: string; details?: string; hint?: string; code?: string }
  const parts = [err?.message, err?.details, err?.hint, err?.code ? `(${err.code})` : null]
    .filter(Boolean)
  return parts.join(' \u00b7 ') || String(e)
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/** Same party + same start minute = already on the calendar. */
async function findDuplicate(
  partyId: string | null | undefined,
  startIso: string,
): Promise<string | null> {
  if (!partyId) return null
  try {
    const supabase = await createSupabaseServerClient()
    // +/- 1 minute so a second of drift does not defeat the check.
    const lo = new Date(new Date(startIso).getTime() - 60_000).toISOString()
    const hi = new Date(new Date(startIso).getTime() + 60_000).toISOString()
    const { data } = await supabase
      .schema('app')
      .from('meetings' as never)
      .select('id')
      .eq('party_id', partyId)
      .gte('scheduled_at', lo)
      .lte('scheduled_at', hi)
      .is('deleted_at', null)
      .neq('status', 'cancelled')
      .limit(1)
    const rows = (data ?? []) as Array<{ id: string }>
    return rows[0]?.id ?? null
  } catch {
    // A failed probe must not block the write.
    return null
  }
}

export async function addEmailToCalendarAction(
  input: AddEmailToCalendarInput,
): Promise<AddEmailToCalendarResult> {
  const title = (input.title ?? '').trim()
  if (!title) return { ok: false, error: 'Title is required' }

  const start = new Date(input.startIso)
  if (Number.isNaN(start.getTime())) {
    return { ok: false, error: 'Start time is not a valid date' }
  }
  const duration = Number.isFinite(input.durationMin) && input.durationMin > 0
    ? Math.min(Math.round(input.durationMin), 24 * 60)
    : 30

  try {
    if (!input.allowDuplicate) {
      const dupe = await findDuplicate(input.partyId, start.toISOString())
      if (dupe) {
        return {
          ok: false,
          duplicate: true,
          error: 'A meeting for this party already starts at that time.',
        }
      }
    }

    const notes = [
      input.agenda?.trim() || null,
      input.communicationId ? `Source email: ${input.communicationId}` : null,
    ].filter(Boolean).join('\n\n') || null

    // ── party known -> app.meetings ──────────────────────────
    if (input.partyId) {
      const attendees = (input.attendees ?? [])
        .filter((a) => a?.email && EMAIL_RE.test(a.email.trim()))
        .map((a) => ({
          email: a.email.trim().toLowerCase(),
          name: a.name?.trim() || undefined,
        }))
      // De-dupe: meeting_attendees has no unique constraint to lean on.
      const seen = new Set<string>()
      const uniqueAttendees = attendees.filter((a) => {
        if (seen.has(a.email)) return false
        seen.add(a.email)
        return true
      })

      const row = await createMeeting({
        party_id: input.partyId,
        title,
        meeting_type: input.meetingType || 'discovery',
        channel: input.channel ?? (input.meetingUrl ? 'video_call' : 'other'),
        scheduled_at: start.toISOString(),
        duration_min: duration,
        agenda: notes ?? undefined,
        location: input.location?.trim() || undefined,
        meeting_url: input.meetingUrl?.trim() || undefined,
        attendees: uniqueAttendees.length > 0 ? uniqueAttendees : undefined,
      })

      revalidatePath('/calendar')
      revalidatePath('/today')
      revalidatePath(`/meetings/${row.id}`)
      return { ok: true, kind: 'meeting', id: row.id }
    }

    // ── no party -> app.calendar_events ──────────────────────
    const end = new Date(start.getTime() + duration * 60_000)
    const event = await createCalendarEvent({
      title,
      description: notes ?? undefined,
      location: input.location?.trim() || undefined,
      meeting_url: input.meetingUrl?.trim() || undefined,
      start_at: start.toISOString(),
      end_at: end.toISOString(),
    })

    revalidatePath('/calendar')
    revalidatePath('/today')
    const id = (event as { id?: string } | null)?.id ?? ''
    return { ok: true, kind: 'event', id }
  } catch (e) {
    console.error('[add-email-to-calendar] error:', e)
    return { ok: false, error: toMessage(e) }
  }
}
