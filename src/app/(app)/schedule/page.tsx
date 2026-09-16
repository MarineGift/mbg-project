// src/app/(app)/schedule/page.tsx
// A specific date's schedule — show instances (if any) or the template projection,
// in time order, with execution check.

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

// validate "YYYY-MM-DD"
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

  // 1) instances for this date (if materialized)
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
    // 2) no instances → project the template onto this date (not saved yet)
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
        id: b.id,                       // template id for now (replaced on materialize)
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
            {isToday ? "Today's Schedule" : 'Schedule'}
          </h1>
          <p className="text-sm text-muted-foreground">Track plan vs. actual</p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href={`/schedule/edit?date=${date}`}
            className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent"
          >
            Edit
          </Link>
          <Link
            href="/schedule/reports"
            className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent"
          >
            Reports
          </Link>
        </div>
      </div>

      {!hasTemplate && !materialized ? (
        <div className="rounded-lg border border-dashed p-8 text-center">
          <p className="mb-1 text-sm font-medium">No schedule to show for this date.</p>
          <p className="mb-4 text-sm text-muted-foreground">
            Load the default 06:00-23:00 schedule, then customize per day.
          </p>
          <div className="flex justify-center gap-2">
            <LoadTemplateButton />
            <Link
              href={`/schedule/edit?date=${date}`}
              className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-accent"
            >
              Add manually
            </Link>
          </div>
        </div>
      ) : (
        <ScheduleToday key={`${date}:${materialized}`} date={date} blocks={view} materialized={materialized} />
      )}
    </div>
  );
}
