'use server'
// src/app/actions/meetings.ts
//
// 2026-09-14 — "calendar items cannot be edited or deleted" fix.
//
// Calendar chips of type 'meeting' come from app.meetings, but the only
// edit/delete UI that existed was EditEventModal, which targets
// app.calendar_events (type === 'event'). Meetings were therefore read-only
// everywhere (calendar popup + /meetings/[id]). These actions give the client
// components a write path.
//
// Why not reuse lib/queries/meetings.ts fetchMeetingDetail(): its DETAIL_SELECT
// embeds `parties ( id, name )` and `pipeline_stages:stage_id`, neither of which
// matches the live schema (app.parties uses party_name; deal stages live in
// app.stages). A flat column read avoids the PostgREST 42703 / relationship
// errors — the edit form needs no joins anyway.
//
// Delete is a SOFT delete (app.meetings.deleted_at), matching fetchMeetings()
// and the /meetings/[id] page, which already filter `.is('deleted_at', null)`.
// Readers that did not filter it (calendar feed, today cockpit, party detail)
// are patched in the same change set.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

// Flat, join-free projection of the editable columns.
const EDIT_COLS = [
  'id', 'title', 'status', 'meeting_type', 'channel',
  'scheduled_at', 'occurred_at', 'duration_min',
  'location', 'meeting_url', 'agenda', 'notes',
  'party_id', 'engagement_id', 'calendar_event_id',
].join(', ')

export interface MeetingEditable {
  id: string
  title: string
  status: string
  meeting_type: string | null
  channel: string | null
  scheduled_at: string | null
  occurred_at: string | null
  duration_min: number | null
  location: string | null
  meeting_url: string | null
  agenda: string | null
  notes: string | null
  party_id: string | null
  engagement_id: string | null
  calendar_event_id: string | null
}

export interface MeetingPatchInput {
  title?: string
  status?: string
  meeting_type?: string | null
  channel?: string | null
  scheduled_at?: string | null
  duration_min?: number | null
  location?: string | null
  meeting_url?: string | null
  agenda?: string | null
  notes?: string | null
}

export type MeetingActionResult<T = null> =
  | { ok: true; data: T }
  | { ok: false; error: string }

// Next.js swallows thrown errors in production builds, so every action returns
// a result object and the real Postgres message reaches the modal.
function toMessage(e: unknown): string {
  const err = e as { message?: string; details?: string; hint?: string; code?: string }
  const parts = [err?.message, err?.details, err?.hint, err?.code ? `(${err.code})` : null]
    .filter(Boolean)
  return parts.join(' \u00b7 ') || String(e)
}

function revalidateMeeting(id: string) {
  try {
    revalidatePath('/calendar')
    revalidatePath('/today')
    revalidatePath(`/meetings/${id}`)
  } catch {
    // revalidatePath throws outside a request scope in some runtimes; ignore.
  }
}

export async function getMeetingForEditAction(
  id: string,
): Promise<MeetingActionResult<MeetingEditable>> {
  if (!id) return { ok: false, error: 'Missing meeting id' }
  try {
    const supabase = await createSupabaseServerClient()
    const { data, error } = await supabase
      .schema('app')
      .from('meetings' as never)
      .select(EDIT_COLS)
      .eq('id', id)
      .is('deleted_at', null)
      .maybeSingle()

    if (error) throw error
    if (!data) return { ok: false, error: 'Meeting not found (or already deleted)' }
    return { ok: true, data: data as unknown as MeetingEditable }
  } catch (e) {
    console.error('[meetings] load-for-edit error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

export async function updateMeetingAction(
  id: string,
  patch: MeetingPatchInput,
): Promise<MeetingActionResult<MeetingEditable>> {
  if (!id) return { ok: false, error: 'Missing meeting id' }
  try {
    const supabase = await createSupabaseServerClient()

    // Only send keys the caller actually set — undefined would null out columns.
    const row: Record<string, unknown> = { updated_at: new Date().toISOString() }
    for (const [k, v] of Object.entries(patch)) {
      if (v !== undefined) row[k] = v
    }
    // occurred_at is NOT NULL and is what most list queries sort on; keep it in
    // step with a rescheduled meeting.
    if (patch.scheduled_at) row.occurred_at = patch.scheduled_at

    const { data, error } = await supabase
      .schema('app')
      .from('meetings' as never)
      .update(row as never)
      .eq('id', id)
      .is('deleted_at', null)
      .select(EDIT_COLS)
      .maybeSingle()

    if (error) throw error
    if (!data) {
      return {
        ok: false,
        error: 'No row was updated — the meeting may be deleted, or RLS blocked the write.',
      }
    }
    revalidateMeeting(id)
    return { ok: true, data: data as unknown as MeetingEditable }
  } catch (e) {
    console.error('[meetings] update error:', e)
    return { ok: false, error: toMessage(e) }
  }
}

// Soft delete. Also drops the linked calendar_events mirror row when one exists
// (URM-created meetings may carry calendar_event_id), so the chip disappears
// from every feed instead of lingering as an orphan event.
export async function deleteMeetingAction(
  id: string,
): Promise<MeetingActionResult<{ id: string }>> {
  if (!id) return { ok: false, error: 'Missing meeting id' }
  try {
    const supabase = await createSupabaseServerClient()

    const { data: current } = await supabase
      .schema('app')
      .from('meetings' as never)
      .select('id, calendar_event_id')
      .eq('id', id)
      .maybeSingle()

    const { data, error } = await supabase
      .schema('app')
      .from('meetings' as never)
      .update({
        deleted_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as never)
      .eq('id', id)
      .select('id')
      .maybeSingle()

    if (error) throw error
    if (!data) {
      return {
        ok: false,
        error: 'No row was deleted — the meeting may already be gone, or RLS blocked the write.',
      }
    }

    const mirrorId = (current as { calendar_event_id?: string | null } | null)?.calendar_event_id
    if (mirrorId) {
      const { error: mirrorErr } = await supabase
        .schema('app')
        .from('calendar_events' as never)
        .delete()
        .eq('id', mirrorId)
      // Non-fatal: the meeting is already deleted; log and continue.
      if (mirrorErr) console.error('[meetings] mirror event delete error:', mirrorErr)
    }

    revalidateMeeting(id)
    return { ok: true, data: { id } }
  } catch (e) {
    console.error('[meetings] delete error:', e)
    return { ok: false, error: toMessage(e) }
  }
}
