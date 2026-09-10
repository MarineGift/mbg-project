// src/app/(app)/schedule/reports/page.tsx
// 일과표 리포트 — 매일 / 주간 / 월간 / 연간 / 카테고리별 달성률 (연 날만 집계).

import Link from 'next/link';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ScheduleReports } from '@/components/schedule/schedule-reports';
import { todayISO, type RoutineDayBlock } from '@/components/schedule/constants';
import {
  aggregateDaily, aggregateWeekly,
  aggregateMonthly, aggregateYearly, aggregateCategory,
} from '@/components/schedule/aggregate';

export const dynamic = 'force-dynamic';

export default async function ScheduleReportsPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const today = todayISO();

  const res = await supabase
    .schema('app')
    .from('routine_day_blocks' as never)
    .select('id, block_date, template_block_id, title, category, start_time, end_time, sort_order, status, note')
    .eq('user_id' as never, auth.userId);

  const rows = (res.data ?? []) as unknown as RoutineDayBlock[];

  const daily = aggregateDaily(rows).slice(0, 30);      // 최근 30일
  const weekly = aggregateWeekly(rows).slice(0, 12);    // 최근 12주
  const monthly = aggregateMonthly(rows).slice(0, 12);  // 최근 12개월
  const yearly = aggregateYearly(rows);                 // 연도 전체
  const category = aggregateCategory(rows);

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">일과표 리포트</h1>
          <p className="text-sm text-muted-foreground">
            계획 대비 실제 달성률 · 체크·수정한 날만 집계 · 기준일 {today}
          </p>
        </div>
        <Link href="/schedule" className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent">
          오늘로
        </Link>
      </div>

      {rows.length === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center text-sm text-muted-foreground">
          아직 체크한 날이 없습니다. <Link href="/schedule" className="underline">오늘의 일과표</Link>에서 실행을 체크하면 여기에 달성률이 쌓입니다.
        </div>
      ) : (
        <ScheduleReports
          daily={daily}
          weekly={weekly}
          monthly={monthly}
          yearly={yearly}
          category={category}
        />
      )}
    </div>
  );
}
