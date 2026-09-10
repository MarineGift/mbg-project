'use server';

/**
 * src/app/actions/schedule.ts
 * Routine schedule server actions — RLS client only (own org + user).
 *
 *  Model:
 *   - routine_blocks      = default schedule (template)
 *   - routine_day_blocks  = a specific date's actual schedule + status (main here)
 *
 *  "materialize" = when a date is first checked/edited, copy the template into
 *   routine_day_blocks so that date can be edited independently.
 */

import { revalidatePath } from 'next/cache';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

type RoutineStatus = 'done' | 'partial' | 'skipped';

export type ScheduleActionResult =
  | { success: true }
  | { success: false; error: string };

type SB = Awaited<ReturnType<typeof createSupabaseServerClient>>;

function revalidateSchedule() {
  revalidatePath('/schedule');
  revalidatePath('/schedule/reports');
  revalidatePath('/schedule/edit');
  revalidatePath('/calendar');
}

// "YYYY-MM-DD" → weekday (0=Sun..6=Sat). Noon+UTC to avoid boundary drift.
function dowOfDate(iso: string): number {
  return new Date(`${iso}T12:00:00Z`).getUTCDay();
}

// ---------------------------------------------------------------------------
// materialize: if the date has no instances, copy the template into it.
// No-op if it already exists (idempotent).
// ---------------------------------------------------------------------------
async function ensureDayMaterialized(
  supabase: SB,
  organizationId: string,
  userId: string,
  date: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const { count, error: cErr } = await supabase
    .schema('app')
    .from('routine_day_blocks' as never)
    .select('id' as never, { count: 'exact', head: true })
    .eq('user_id' as never, userId)
    .eq('block_date' as never, date);
  if (cErr) return { ok: false, error: cErr.message };
  if ((count ?? 0) > 0) return { ok: true }; // already materialized

  // copy template (active) blocks that fall on this weekday
  const { data: tpl, error: tErr } = await supabase
    .schema('app')
    .from('routine_blocks' as never)
    .select('id, title, category, start_time, end_time, weekday_mask, sort_order')
    .eq('user_id' as never, userId)
    .eq('active' as never, true);
  if (tErr) return { ok: false, error: tErr.message };

  const dow = dowOfDate(date);
  const rows = ((tpl ?? []) as unknown as Array<{
    id: string; title: string; category: string;
    start_time: string; end_time: string; weekday_mask: number; sort_order: number;
  }>)
    .filter((b) => (b.weekday_mask & (1 << dow)) !== 0)
    .map((b) => ({
      organization_id: organizationId,
      user_id: userId,
      block_date: date,
      template_block_id: b.id,
      title: b.title,
      category: b.category,
      start_time: b.start_time,
      end_time: b.end_time,
      sort_order: b.sort_order,
      status: null as RoutineStatus | null,
    }));

  if (rows.length === 0) return { ok: true }; // no template blocks on this weekday

  const { error: iErr } = await supabase
    .schema('app')
    .from('routine_day_blocks' as never)
    .upsert(rows as never, {
      onConflict: 'user_id,block_date,start_time,title',
      ignoreDuplicates: true,
    });
  if (iErr) return { ok: false, error: iErr.message };
  return { ok: true };
}

/** Materialize a specific date (can be called on edit/check entry) */
export async function materializeDay(date: string): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();
    const r = await ensureDayMaterialized(supabase, organizationId, userId, date);
    if (!r.ok) return { success: false, error: r.error };
    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

// Info to identify a block to check (dayBlockId may be absent before materialize)
export type DayStatusTarget = {
  dayBlockId?: string;
  start_time: string; // "HH:MM:SS" or "HH:MM"
  title: string;
};

/**
 * Set/change/clear a block's status on a date.
 * If the date isn't materialized yet, materialize first, then find the instance.
 */
export async function setDayStatus(
  date: string,
  target: DayStatusTarget,
  status: RoutineStatus | null,
): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    const m = await ensureDayMaterialized(supabase, organizationId, userId, date);
    if (!m.ok) return { success: false, error: m.error };

    // resolve the target instance id
    let dayBlockId = target.dayBlockId;
    if (!dayBlockId) {
      const startHm = target.start_time.slice(0, 5);
      const { data, error } = await supabase
        .schema('app')
        .from('routine_day_blocks' as never)
        .select('id, start_time, title')
        .eq('user_id' as never, userId)
        .eq('block_date' as never, date);
      if (error) return { success: false, error: error.message };
      const found = ((data ?? []) as unknown as Array<{ id: string; start_time: string; title: string }>)
        .find((r) => r.start_time.slice(0, 5) === startHm && r.title === target.title);
      if (!found) return { success: false, error: 'Could not find the block.' };
      dayBlockId = found.id;
    }

    const { error: uErr } = await supabase
      .schema('app')
      .from('routine_day_blocks' as never)
      .update({ status, updated_at: new Date().toISOString() } as never)
      .eq('id' as never, dayBlockId);
    if (uErr) return { success: false, error: uErr.message };

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

/** Mark the whole day as "done" (quick close) */
export async function completeDay(date: string): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    const m = await ensureDayMaterialized(supabase, organizationId, userId, date);
    if (!m.ok) return { success: false, error: m.error };

    const { error } = await supabase
      .schema('app')
      .from('routine_day_blocks' as never)
      .update({ status: 'done', updated_at: new Date().toISOString() } as never)
      .eq('user_id' as never, userId)
      .eq('block_date' as never, date);
    if (error) return { success: false, error: error.message };

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

/** Discard this day's edits → delete instances → show the template again */
export async function resetDayToTemplate(date: string): Promise<ScheduleActionResult> {
  try {
    const { userId } = await requireAuth();
    const supabase = await createSupabaseServerClient();
    const { error } = await supabase
      .schema('app')
      .from('routine_day_blocks' as never)
      .delete()
      .eq('user_id' as never, userId)
      .eq('block_date' as never, date);
    if (error) return { success: false, error: error.message };
    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

// ---------------------------------------------------------------------------
// Per-day block editing (used by the editor)
// ---------------------------------------------------------------------------
export type DayBlockInput = {
  id?: string;         // present = update, absent = add
  title: string;
  category: string;
  start_time: string;  // "HH:MM"
  end_time: string;    // "HH:MM"
};

/** Add/update a block on a specific date (materialize the day first) */
export async function upsertDayBlock(
  date: string,
  input: DayBlockInput,
): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    if (!input.title.trim()) return { success: false, error: 'Please enter a title.' };
    if (input.end_time <= input.start_time)
      return { success: false, error: 'End time must be after start time.' };

    const m = await ensureDayMaterialized(supabase, organizationId, userId, date);
    if (!m.ok) return { success: false, error: m.error };

    if (input.id) {
      const { error } = await supabase
        .schema('app')
        .from('routine_day_blocks' as never)
        .update({
          title: input.title.trim(),
          category: input.category || 'other',
          start_time: input.start_time,
          end_time: input.end_time,
          updated_at: new Date().toISOString(),
        } as never)
        .eq('id' as never, input.id);
      if (error) return { success: false, error: error.message };
    } else {
      const { error } = await supabase
        .schema('app')
        .from('routine_day_blocks' as never)
        .insert({
          organization_id: organizationId,
          user_id: userId,
          block_date: date,
          template_block_id: null,
          title: input.title.trim(),
          category: input.category || 'other',
          start_time: input.start_time,
          end_time: input.end_time,
          sort_order: 999,
          status: null,
        } as never);
      if (error) return { success: false, error: error.message };
    }

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

/** Delete a single block on a date */
export async function deleteDayBlock(id: string): Promise<ScheduleActionResult> {
  try {
    await requireAuth();
    const supabase = await createSupabaseServerClient();
    const { error } = await supabase
      .schema('app')
      .from('routine_day_blocks' as never)
      .delete()
      .eq('id' as never, id);
    if (error) return { success: false, error: error.message };
    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

// ===========================================================================
// Below: default template editing (routine_blocks). Used by /schedule/edit (no date).
// ===========================================================================

const DEFAULT_TEMPLATE: Array<{
  title: string; category: string; start_time: string; end_time: string; sort_order: number;
}> = [
  { title: 'Wake up, meal, shower, prep',            category: 'personal', start_time: '06:00', end_time: '06:30', sort_order: 1 },
  { title: 'Commute - English speaking (listen & repeat)', category: 'english', start_time: '06:30', end_time: '07:00', sort_order: 2 },
  { title: 'Meditation, to-do, gratitude',           category: 'personal', start_time: '07:00', end_time: '07:30', sort_order: 3 },
  { title: 'Work prep, email triage',                category: 'work',     start_time: '07:30', end_time: '08:00', sort_order: 4 },
  { title: 'Work 1 (deep work)',                     category: 'work',     start_time: '08:00', end_time: '09:00', sort_order: 5 },
  { title: 'Work 2',                                 category: 'work',     start_time: '09:00', end_time: '10:00', sort_order: 6 },
  { title: 'Break',                                  category: 'rest',     start_time: '10:00', end_time: '10:15', sort_order: 7 },
  { title: 'Work 3',                                 category: 'work',     start_time: '10:15', end_time: '11:30', sort_order: 8 },
  { title: 'English study (reading, vocab)',         category: 'english',  start_time: '11:30', end_time: '12:00', sort_order: 9 },
  { title: 'Lunch & break',                          category: 'meal',     start_time: '12:00', end_time: '13:00', sort_order: 10 },
  { title: 'Work 4',                                 category: 'work',     start_time: '13:00', end_time: '14:30', sort_order: 11 },
  { title: 'Break',                                  category: 'rest',     start_time: '14:30', end_time: '14:45', sort_order: 12 },
  { title: 'Work 5',                                 category: 'work',     start_time: '14:45', end_time: '16:00', sort_order: 13 },
  { title: 'Work 6, meeting',                        category: 'work',     start_time: '16:00', end_time: '17:00', sort_order: 14 },
  { title: 'Wrap-up, organize',                      category: 'work',     start_time: '17:00', end_time: '18:00', sort_order: 15 },
  { title: 'Dinner',                                 category: 'meal',     start_time: '18:00', end_time: '19:00', sort_order: 16 },
  { title: 'Exercise',                               category: 'exercise', start_time: '19:00', end_time: '20:00', sort_order: 17 },
  { title: 'Shower, rest',                           category: 'rest',     start_time: '20:00', end_time: '20:30', sort_order: 18 },
  { title: 'English study (speaking, shadowing)',    category: 'english',  start_time: '20:30', end_time: '21:30', sort_order: 19 },
  { title: 'Self-development, reading',              category: 'growth',   start_time: '21:30', end_time: '22:30', sort_order: 20 },
  { title: 'Daily review, gratitude journal, plan tomorrow', category: 'personal', start_time: '22:30', end_time: '23:00', sort_order: 21 },
];

export async function loadDefaultTemplate(): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    const rows = DEFAULT_TEMPLATE.map((b) => ({
      organization_id: organizationId,
      user_id: userId,
      title: b.title,
      category: b.category,
      start_time: b.start_time,
      end_time: b.end_time,
      weekday_mask: 127,
      sort_order: b.sort_order,
      active: true,
    }));

    const { error } = await supabase
      .schema('app')
      .from('routine_blocks' as never)
      .upsert(rows as never, { onConflict: 'user_id,title,start_time', ignoreDuplicates: true });
    if (error) return { success: false, error: error.message };

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

export type BlockInput = {
  id?: string;
  title: string;
  category: string;
  start_time: string;  // "HH:MM"
  end_time: string;    // "HH:MM"
  weekday_mask?: number;
  active?: boolean;
};

/** Add/update a template block */
export async function upsertBlock(input: BlockInput): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    if (!input.title.trim()) return { success: false, error: 'Please enter a title.' };
    if (input.end_time <= input.start_time)
      return { success: false, error: 'End time must be after start time.' };

    const payload = {
      organization_id: organizationId,
      user_id: userId,
      title: input.title.trim(),
      category: input.category || 'other',
      start_time: input.start_time,
      end_time: input.end_time,
      weekday_mask: input.weekday_mask ?? 127,
      active: input.active ?? true,
    };

    if (input.id) {
      const { error } = await supabase
        .schema('app')
        .from('routine_blocks' as never)
        .update(payload as never)
        .eq('id' as never, input.id);
      if (error) return { success: false, error: error.message };
    } else {
      const { error } = await supabase
        .schema('app')
        .from('routine_blocks' as never)
        .insert(payload as never);
      if (error) return { success: false, error: error.message };
    }

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

/** Delete a template block */
export async function deleteBlock(id: string): Promise<ScheduleActionResult> {
  try {
    await requireAuth();
    const supabase = await createSupabaseServerClient();
    const { error } = await supabase
      .schema('app')
      .from('routine_blocks' as never)
      .delete()
      .eq('id' as never, id);
    if (error) return { success: false, error: error.message };
    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}
