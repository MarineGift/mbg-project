'use server';

/**
 * src/app/actions/schedule.ts
 * 일과표(Routine) 서버 액션 — RLS 클라이언트(본인 org+user)만 사용.
 *
 *  모델:
 *   - routine_blocks      = 기본 일정(템플릿)
 *   - routine_day_blocks  = 특정 날짜의 실제 일정 + 상태 (이 파일이 주로 다룸)
 *
 *  "materialize" = 어떤 날짜를 처음 체크/수정할 때, 그날 템플릿을
 *   routine_day_blocks 로 복사해 그 날짜를 독립 편집 가능하게 만드는 것.
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

// "YYYY-MM-DD" → 요일(0=일..6=토). 정오+UTC로 경계 흔들림 방지.
function dowOfDate(iso: string): number {
  return new Date(`${iso}T12:00:00Z`).getUTCDay();
}

// ---------------------------------------------------------------------------
// materialize: 해당 날짜에 인스턴스가 없으면 템플릿을 복사해 넣는다.
// 이미 있으면 아무 것도 하지 않음(멱등).
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
  if ((count ?? 0) > 0) return { ok: true }; // 이미 materialize됨

  // 템플릿(활성)에서 이 요일에 해당하는 블록만 복사
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

  if (rows.length === 0) return { ok: true }; // 이 요일엔 템플릿 블록이 없음 → 빈 날

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

/** 특정 날짜의 블록을 materialize (편집/체크 진입 시 버튼 없이도 호출 가능) */
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

// 체크할 블록을 식별하기 위한 정보 (materialize 전이면 dayBlockId가 없을 수 있음)
export type DayStatusTarget = {
  dayBlockId?: string;
  start_time: string; // "HH:MM:SS" 또는 "HH:MM"
  title: string;
};

/**
 * 특정 날짜·블록의 실행 상태 저장/변경/해제.
 * 아직 materialize 안 된 날이면 먼저 materialize한 뒤, 해당 인스턴스를 찾아 상태 지정.
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

    // 대상 인스턴스 id 확정
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
      if (!found) return { success: false, error: '해당 블록을 찾지 못했습니다.' };
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

/** 그날 전체를 "완료"로 (빠른 마감) */
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

/** 그날 수정 취소 → 인스턴스 삭제 → 다시 템플릿(기본)으로 표시 */
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
// 날짜별 블록 편집 (에디터에서 사용)
// ---------------------------------------------------------------------------
export type DayBlockInput = {
  id?: string;         // 있으면 수정, 없으면 추가
  title: string;
  category: string;
  start_time: string;  // "HH:MM"
  end_time: string;    // "HH:MM"
};

/** 특정 날짜의 블록 추가/수정 (수정 진입 시 그날을 먼저 materialize) */
export async function upsertDayBlock(
  date: string,
  input: DayBlockInput,
): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    if (!input.title.trim()) return { success: false, error: '제목을 입력하세요.' };
    if (input.end_time <= input.start_time)
      return { success: false, error: '종료 시각은 시작 시각보다 뒤여야 합니다.' };

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

/** 특정 날짜의 블록 1개 삭제 */
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
// 아래는 "기본 템플릿" 편집용 액션 (routine_blocks). /schedule/edit (날짜 없음)에서 사용.
// ===========================================================================

const DEFAULT_TEMPLATE: Array<{
  title: string; category: string; start_time: string; end_time: string; sort_order: number;
}> = [
  { title: '기상 및 식사, 샤워, 출근준비',       category: 'personal', start_time: '06:00', end_time: '06:30', sort_order: 1 },
  { title: '출근 – 영어 스피킹 (들으면서 말하기)', category: 'english',  start_time: '06:30', end_time: '07:00', sort_order: 2 },
  { title: '명상 · 오늘의 할일 · 감사기도',        category: 'personal', start_time: '07:00', end_time: '07:30', sort_order: 3 },
  { title: '업무 준비 · 이메일 정리',              category: 'work',     start_time: '07:30', end_time: '08:00', sort_order: 4 },
  { title: '업무 1 (집중 딥워크)',                 category: 'work',     start_time: '08:00', end_time: '09:00', sort_order: 5 },
  { title: '업무 2',                               category: 'work',     start_time: '09:00', end_time: '10:00', sort_order: 6 },
  { title: '휴식',                                 category: 'rest',     start_time: '10:00', end_time: '10:15', sort_order: 7 },
  { title: '업무 3',                               category: 'work',     start_time: '10:15', end_time: '11:30', sort_order: 8 },
  { title: '영어 공부 (리딩 · 어휘)',              category: 'english',  start_time: '11:30', end_time: '12:00', sort_order: 9 },
  { title: '점심 및 휴식',                         category: 'meal',     start_time: '12:00', end_time: '13:00', sort_order: 10 },
  { title: '업무 4',                               category: 'work',     start_time: '13:00', end_time: '14:30', sort_order: 11 },
  { title: '휴식',                                 category: 'rest',     start_time: '14:30', end_time: '14:45', sort_order: 12 },
  { title: '업무 5',                               category: 'work',     start_time: '14:45', end_time: '16:00', sort_order: 13 },
  { title: '업무 6 · 미팅',                        category: 'work',     start_time: '16:00', end_time: '17:00', sort_order: 14 },
  { title: '업무 마무리 · 정리',                   category: 'work',     start_time: '17:00', end_time: '18:00', sort_order: 15 },
  { title: '저녁 식사',                            category: 'meal',     start_time: '18:00', end_time: '19:00', sort_order: 16 },
  { title: '운동',                                 category: 'exercise', start_time: '19:00', end_time: '20:00', sort_order: 17 },
  { title: '샤워 · 휴식',                          category: 'rest',     start_time: '20:00', end_time: '20:30', sort_order: 18 },
  { title: '영어 공부 (스피킹 · 섀도잉)',          category: 'english',  start_time: '20:30', end_time: '21:30', sort_order: 19 },
  { title: '자기계발 · 독서',                      category: 'growth',   start_time: '21:30', end_time: '22:30', sort_order: 20 },
  { title: '하루 리뷰 · 감사일기 · 내일 계획',     category: 'personal', start_time: '22:30', end_time: '23:00', sort_order: 21 },
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

/** 템플릿 블록 추가/수정 */
export async function upsertBlock(input: BlockInput): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    if (!input.title.trim()) return { success: false, error: '제목을 입력하세요.' };
    if (input.end_time <= input.start_time)
      return { success: false, error: '종료 시각은 시작 시각보다 뒤여야 합니다.' };

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

/** 템플릿 블록 삭제 */
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
