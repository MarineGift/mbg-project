// src/app/(app)/schedule/reports/page.tsx
// Schedule report — daily / weekly / monthly / yearly / by-category adherence
// (only days you opened are counted).

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

  const daily = aggregateDaily(rows).slice(0, 30);      // last 30 days
  const weekly = aggregateWeekly(rows).slice(0, 12);    // last 12 weeks
  const monthly = aggregateMonthly(rows).slice(0, 12);  // last 12 months
  const yearly = aggregateYearly(rows);                 // all years
  const category = aggregateCategory(rows);

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Schedule Report</h1>
          <p className="text-sm text-muted-foreground">
            Adherence, plan vs. actual · counts only days you opened · as of {today}
          </p>
        </div>
        <Link href="/schedule" className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent">
          Today
        </Link>
      </div>

      {rows.length === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center text-sm text-muted-foreground">
          No days checked yet. Check off items on the <Link href="/schedule" className="underline">schedule</Link> and adherence will build up here.
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
