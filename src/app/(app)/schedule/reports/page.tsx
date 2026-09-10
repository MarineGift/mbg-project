// src/app/(app)/schedule/reports/page.tsx
// 일과표 리포트 — 매일 / 주간 / 월간 / 연간 / 카테고리별 달성률.

import Link from 'next/link';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ScheduleReports } from '@/components/schedule/schedule-reports';
import { todayISO, type RoutineBlock, type RoutineLog } from '@/components/schedule/constants';
import {
  buildOccurrences, aggregateDaily, aggregateWeekly,
  aggregateMonthly, aggregateYearly, aggregateCategory,
} from '@/components/schedule/aggregate';

export const dynamic = 'force-dynamic';

export default async function ScheduleReportsPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const today = todayISO();
  const windowDays = 400;
  const windowStart = (() => {
    const d = new Date(`${today}T12:00:00`);
    d.setDate(d.getDate() - (windowDays - 1));
    return new Intl.DateTimeFormat('en-CA').format(d);
  })();

  const [blocksRes, logsRes] = await Promise.all([
    supabase
      .schema('app')
      .from('routine_blocks' as never)
      .select('id, title, category, start_time, end_time, weekday_mask, sort_order, active, note')
      .eq('user_id' as never, auth.userId)
      .eq('active' as never, true),
    supabase
      .schema('app')
      .from('routine_logs' as never)
      .select('id, block_id, log_date, status, actual_minutes, note')
      .eq('user_id' as never, auth.userId)
      .gte('log_date' as never, windowStart),
  ]);

  const blocks = (blocksRes.data ?? []) as unknown as RoutineBlock[];
  const logs = (logsRes.data ?? []) as unknown as RoutineLog[];

  const occ = buildOccurrences(blocks, logs, today, windowDays);

  const daily = aggregateDaily(occ, today).slice(0, 30);      // 최근 30일
  const weekly = aggregateWeekly(occ, today).slice(0, 12);    // 최근 12주
  const monthly = aggregateMonthly(occ, today).slice(0, 12);  // 최근 12개월
  const yearly = aggregateYearly(occ, today);                 // 연도 전체
  const category = aggregateCategory(occ, today);

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">일과표 리포트</h1>
          <p className="text-sm text-muted-foreground">계획 대비 실제 달성률 · 기준일 {today}</p>
        </div>
        <Link href="/schedule" className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent">
          오늘로
        </Link>
      </div>

      {blocks.length === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center text-sm text-muted-foreground">
          아직 등록된 일과표가 없습니다. <Link href="/schedule" className="underline">오늘의 일과표</Link>에서 먼저 일정을 등록하세요.
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
