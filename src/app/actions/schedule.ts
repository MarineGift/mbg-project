'use server';

/**
 * src/app/actions/schedule.ts
 * 일과표(Routine) 서버 액션 — RLS 클라이언트(본인 org+user)만 사용.
 * calendar.ts / delete-task.ts 와 동일한 패턴.
 */

import { revalidatePath } from 'next/cache';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

type RoutineStatus = 'done' | 'partial' | 'skipped';

export type ScheduleActionResult =
  | { success: true }
  | { success: false; error: string };

function revalidateSchedule() {
  revalidatePath('/schedule');
  revalidatePath('/schedule/reports');
  revalidatePath('/schedule/edit');
}

/**
 * 특정 날짜의 블록 실행 상태를 저장/변경/해제.
 * status === null 이면 로그 삭제(미기록으로 되돌림).
 */
export async function setRoutineStatus(
  blockId: string,
  logDate: string, // "YYYY-MM-DD"
  status: RoutineStatus | null,
): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();

    if (status === null) {
      const { error } = await supabase
        .schema('app')
        .from('routine_logs' as never)
        .delete()
        .eq('block_id' as never, blockId)
        .eq('log_date' as never, logDate);
      if (error) return { success: false, error: error.message };
      revalidateSchedule();
      return { success: true };
    }

    const { error } = await supabase
      .schema('app')
      .from('routine_logs' as never)
      .upsert(
        {
          organization_id: organizationId,
          user_id: userId,
          block_id: blockId,
          log_date: logDate,
          status,
          completed_at: new Date().toISOString(),
        } as never,
        { onConflict: 'block_id,log_date' },
      );
    if (error) return { success: false, error: error.message };

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

/** 하루 전체를 한 번에 "완료" 처리(빠른 마감용) */
export async function completeAllForDate(
  blockIds: string[],
  logDate: string,
): Promise<ScheduleActionResult> {
  try {
    const { userId, organizationId } = await requireAuth();
    const supabase = await createSupabaseServerClient();
    if (blockIds.length === 0) return { success: true };

    const rows = blockIds.map((block_id) => ({
      organization_id: organizationId,
      user_id: userId,
      block_id,
      log_date: logDate,
      status: 'done' as const,
      completed_at: new Date().toISOString(),
    }));

    const { error } = await supabase
      .schema('app')
      .from('routine_logs' as never)
      .upsert(rows as never, { onConflict: 'block_id,log_date' });
    if (error) return { success: false, error: error.message };

    revalidateSchedule();
    return { success: true };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : 'unknown error' };
  }
}

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

/**
 * 기본 06:00~23:00 일과표를 현재 사용자에게 주입.
 * 이미 존재하는(user_id,title,start_time) 블록은 건너뜀(중복 방지).
 */
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

/** 블록 추가/수정 */
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

/** 블록 삭제(로그도 FK CASCADE로 함께 삭제) */
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
