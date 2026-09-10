// src/app/(app)/schedule/page.tsx
// 오늘의 일과표 — 계획된 시간블록을 시간순으로 보여주고 실행 여부를 체크.

import Link from 'next/link';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ScheduleToday } from '@/components/schedule/schedule-today';
import { LoadTemplateButton } from '@/components/schedule/load-template-button';
import {
  todayISO, dowOf, blockActiveOn, toMinutes,
  type RoutineBlock, type RoutineLog,
} from '@/components/schedule/constants';

export const dynamic = 'force-dynamic';

export default async function SchedulePage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const today = todayISO();
  const dow = dowOf(today);

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
      .eq('log_date' as never, today),
  ]);

  const allBlocks = ((blocksRes.data ?? []) as unknown as RoutineBlock[])
    .filter((b) => blockActiveOn(b.weekday_mask, dow))
    .sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time));

  const logs = (logsRes.data ?? []) as unknown as RoutineLog[];

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">오늘의 일과표</h1>
          <p className="text-sm text-muted-foreground">{today} · 계획 대비 실행 체크</p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href="/schedule/edit"
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

      {allBlocks.length === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center">
          <p className="mb-1 text-sm font-medium">아직 등록된 일과표가 없습니다.</p>
          <p className="mb-4 text-sm text-muted-foreground">
            06:00~23:00 기본 일과표를 불러온 뒤 자유롭게 수정하세요.
          </p>
          <div className="flex justify-center gap-2">
            <LoadTemplateButton />
            <Link
              href="/schedule/edit"
              className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-accent"
            >
              직접 추가하기
            </Link>
          </div>
        </div>
      ) : (
        <ScheduleToday date={today} blocks={allBlocks} initialLogs={logs} />
      )}
    </div>
  );
}
