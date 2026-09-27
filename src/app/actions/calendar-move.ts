'use server'
// src/app/actions/calendar-move.ts
//
// 2026-09-27 - drag & drop rescheduling on /calendar.
// One action moves any calendar chip to another day and writes the new date to
// the row that owns it:
//   event (google / microsoft / internal)  app.calendar_events.start_at/end_at
//        -> updateCalendarEvent, which also writes back to Google / Microsoft
//   meeting             app.meetings.scheduled_at (+ occurred_at), and any
//                       linked calendar_events mirror (-> Google write-back)
//   deal_task           app.tasks.due_at
//   todo                app.todo_items.due_date
//   milestone_next_step app.deals.next_step_date      (Pipeline)
//   milestone_close     app.deals.expected_close_date (Pipeline)
// Communications are history and cannot be moved. A single occurrence of a
// recurring event cannot be moved (it would move the whole series).
//
// Timed items: the client computes the new start (same local wall-clock time on
// the target day, DST-safe) and sends it as newStartIso; the duration is kept.
// All-day / date items: shifted by whole days / set to toYmd.

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { updateCalendarEvent } from '@/lib/queries/calendar'
import type { CalendarFeedSource } from '@/lib/queries/calendar-meta'

export interface MoveCalendarItemInput {
  feed_source:      CalendarFeedSource
  id:               string
  source_event_id?: string | null
  deal_id?:         string | null
  /** target day, 'YYYY-MM-DD' (browser local date) */
  toYmd:            string
  /** whole days between the old and the new local day */
  dayDelta:         number
  /** timed items: new start instant, same wall-clock time on toYmd */
  newStartIso?:     string | null
}

export interface MoveCalendarItemResult {
  ok:     boolean
  error?: string
}

const YMD = /^\d{4}-\d{2}-\d{2}$/

function shiftIsoDays(iso: string, days: number): string {
  const d = new Date(iso)
  d.setUTCDate(d.getUTCDate() + days)
  return d.toISOString()
}

function keepDuration(oldStart: string, oldEnd: string | null, newStart: string): string {
  const dur = oldEnd ? new Date(oldEnd).getTime() - new Date(oldStart).getTime() : 0
  return new Date(new Date(newStart).getTime() + Math.max(dur, 0)).toISOString()
}

function msg(e: unknown): string {
  if (e instanceof Error) return e.message
  if (e && typeof e === 'object' && 'message' in e) return String((e as { message: unknown }).message)
  return 'move failed'
}

type Sb = Awaited<ReturnType<typeof createSupabaseServerClient>>

/** move one calendar_events row (write-back to Google/Microsoft inside updateCalendarEvent) */
async function moveEventRow(
  supabase: Sb,
  id: string,
  dayDelta: number,
  newStartIso: string | null | undefined,
): Promise<void> {
  const { data, error } = await supabase
    .schema('app')
    .from('calendar_events' as never)
    .select('id, start_at, end_at, is_all_day, recurrence_rule')
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  const row = data as {
    start_at: string; end_at: string | null; is_all_day: boolean | null; recurrence_rule: string | null
  } | null
  if (!row) throw new Error('Event not found')
  if (row.recurrence_rule) throw new Error('Recurring events cannot be moved by drag - edit the event instead')

  let start: string
  let end: string
  if (row.is_all_day || !newStartIso) {
    start = shiftIsoDays(row.start_at, dayDelta)
    end = row.end_at ? shiftIsoDays(row.end_at, dayDelta) : start
  } else {
    start = new Date(newStartIso).toISOString()
    end = keepDuration(row.start_at, row.end_at, start)
  }
  await updateCalendarEvent(id, { start_at: start, end_at: end })
}

export async function moveCalendarItemAction(
  input: MoveCalendarItemInput,
): Promise<MoveCalendarItemResult> {
  try {
    const { feed_source, id, toYmd } = input
    const dayDelta = Math.trunc(Number(input.dayDelta) || 0)
    if (!id) return { ok: false, error: 'Missing item id' }
    if (!YMD.test(toYmd)) return { ok: false, error: 'Bad target date' }
    if (dayDelta === 0) return { ok: true }

    const supabase = await createSupabaseServerClient()

    switch (feed_source) {
      case 'event': {
        if (input.source_event_id) {
          return { ok: false, error: 'Recurring events cannot be moved by drag - edit the event instead' }
        }
        await moveEventRow(supabase, id, dayDelta, input.newStartIso)
        break
      }

      case 'meeting': {
        const { data, error } = await supabase
          .schema('app')
          .from('meetings' as never)
          .select('id, scheduled_at')
          .eq('id', id)
          .is('deleted_at', null)
          .maybeSingle()
        if (error) throw error
        const m = data as { scheduled_at: string | null } | null
        if (!m?.scheduled_at) return { ok: false, error: 'Meeting not found' }
        const start = input.newStartIso
          ? new Date(input.newStartIso).toISOString()
          : shiftIsoDays(m.scheduled_at, dayDelta)
        const { error: upErr } = await supabase
          .schema('app')
          .from('meetings' as never)
          .update({ scheduled_at: start, occurred_at: start, updated_at: new Date().toISOString() } as never)
          .eq('id', id)
        if (upErr) throw upErr

        // calendar_events mirrors of this meeting (Google-synced invites etc.)
        const { data: mirrors } = await supabase
          .schema('app')
          .from('calendar_events' as never)
          .select('id')
          .eq('meeting_id', id)
          .neq('status', 'cancelled')
        for (const r of (mirrors ?? []) as Array<{ id: string }>) {
          try {
            await moveEventRow(supabase, r.id, dayDelta, start)
          } catch (e) {
            console.error('[calendar-move] meeting mirror', r.id, msg(e))
          }
        }
        break
      }

      case 'deal_task': {
        const { data, error } = await supabase
          .schema('app')
          .from('tasks' as never)
          .select('id, due_at')
          .eq('id', id)
          .maybeSingle()
        if (error) throw error
        const t = data as { due_at: string | null } | null
        if (!t?.due_at) return { ok: false, error: 'Task not found' }
        const { error: upErr } = await supabase
          .schema('app')
          .from('tasks' as never)
          .update({ due_at: shiftIsoDays(t.due_at, dayDelta), updated_at: new Date().toISOString() } as never)
          .eq('id', id)
        if (upErr) throw upErr
        break
      }

      case 'todo': {
        const { error } = await supabase
          .schema('app')
          .from('todo_items' as never)
          .update({ due_date: toYmd, updated_at: new Date().toISOString() } as never)
          .eq('id', id)
        if (error) throw error
        break
      }

      case 'milestone_next_step':
      case 'milestone_close': {
        const dealId = input.deal_id ?? id.split(':')[0]
        if (!dealId) return { ok: false, error: 'Missing deal id' }
        const col = feed_source === 'milestone_next_step' ? 'next_step_date' : 'expected_close_date'
        const { error } = await supabase
          .schema('app')
          .from('deals' as never)
          .update({ [col]: toYmd } as never)
          .eq('id', dealId)
        if (error) throw error
        revalidatePath('/pipelines', 'layout')
        break
      }

      case 'communication':
        return { ok: false, error: 'Communications are history and cannot be moved' }

      default:
        return { ok: false, error: `Unsupported item: ${String(feed_source)}` }
    }

    revalidatePath('/calendar')
    revalidatePath('/today')
    return { ok: true }
  } catch (e) {
    console.error('[calendar-move]', e)
    return { ok: false, error: msg(e) }
  }
}
