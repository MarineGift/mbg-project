// src/app/(app)/schedule/page.tsx
// 특정 날짜의 일과표 — 인스턴스(있으면) 또는 템플릿(없으면)을 시간순으로 보여주고 실행 체크.

import Link from 'next/link';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ScheduleToday } from '@/components/schedule/schedule-today';
import { LoadTemplateButton } from '@/components/schedule/load-template-button';
import {
  todayISO, dowOf, blockActiveOn, toMinutes,
  type RoutineBlock, type RoutineDayBlock, type DayBlockView,
} from '@/components/schedule/constants';

export const dynamic = 'force-dynamic';

// "YYYY-MM-DD" 형식 검증
function validDate(s: string | undefined): string | null {
  return s && /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : null;
}

export default async function SchedulePage({
  searchParams,
}: {
  searchParams: Promise<{ date?: string }>;
}) {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const sp = await searchParams;
  const date = validDate(sp.date) ?? todayISO();
  const dow = dowOf(date);

  // 1) 이 날짜의 인스턴스(materialize된 경우)
  const dayRes = await supabase
    .schema('app')
    .from('routine_day_blocks' as never)
    .select('id, block_date, template_block_id, title, category, start_time, end_time, sort_order, status, note')
    .eq('user_id' as never, auth.userId)
    .eq('block_date' as never, date);

  const dayBlocks = (dayRes.data ?? []) as unknown as RoutineDayBlock[];
  const materialized = dayBlocks.length > 0;

  let view: DayBlockView[];

  if (materialized) {
    view = dayBlocks
      .map((d) => ({
        id: d.id,
        template_block_id: d.template_block_id,
        title: d.title,
        category: d.category,
        start_time: d.start_time,
        end_time: d.end_time,
        sort_order: d.sort_order,
        status: d.status,
      }))
      .sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time));
  } else {
    // 2) 인스턴스가 없으면 템플릿을 이 날짜에 투영(아직 저장 아님)
    const tplRes = await supabase
      .schema('app')
      .from('routine_blocks' as never)
      .select('id, title, category, start_time, end_time, weekday_mask, sort_order, active, note')
      .eq('user_id' as never, auth.userId)
      .eq('active' as never, true);

    view = ((tplRes.data ?? []) as unknown as RoutineBlock[])
      .filter((b) => blockActiveOn(b.weekday_mask, dow))
      .sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time))
      .map((b) => ({
        id: b.id,                       // 아직 템플릿 id (체크 시 materialize되어 교체됨)
        template_block_id: b.id,
        title: b.title,
        category: b.category,
        start_time: b.start_time,
        end_time: b.end_time,
        sort_order: b.sort_order,
        status: null,
      }));
  }

  const isToday = date === todayISO();
  const hasTemplate = view.length > 0;

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">
            {isToday ? '오늘의 일과표' : '일과표'}
          </h1>
          <p className="text-sm text-muted-foreground">계획 대비 실행 체크</p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href={`/schedule/edit?date=${date}`}
            className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent"
          >
            일정 편집
          </Link>
          <Link
            href="/schedule/reports"
            className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent"
          >
            리포트
          </Link>
        </div>
      </div>

      {!hasTemplate && !materialized ? (
        <div className="rounded-lg border border-dashed p-8 text-center">
          <p className="mb-1 text-sm font-medium">이 날짜에 표시할 일과가 없습니다.</p>
          <p className="mb-4 text-sm text-muted-foreground">
            06:00~23:00 기본 일과표를 불러온 뒤 날짜별로 수정하세요.
          </p>
          <div className="flex justify-center gap-2">
            <LoadTemplateButton />
            <Link
              href={`/schedule/edit?date=${date}`}
              className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-accent"
            >
              직접 추가하기
            </Link>
          </div>
        </div>
      ) : (
        <ScheduleToday key={`${date}:${materialized}`} date={date} blocks={view} materialized={materialized} />
      )}
    </div>
  );
}
