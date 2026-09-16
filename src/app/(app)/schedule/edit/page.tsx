// src/app/(app)/schedule/edit/page.tsx
// Schedule editing.
//   ?date=YYYY-MM-DD  → edit that date only (materialize the template into it on entry).
//   no date           → edit the default template (routine_blocks) → changes the default
//                       for every day not yet customized.

import Link from 'next/link';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ScheduleEditor, type EditorBlock } from '@/components/schedule/schedule-editor';
import {
  toMinutes, humanDate, todayISO,
  type RoutineBlock, type RoutineDayBlock,
} from '@/components/schedule/constants';

export const dynamic = 'force-dynamic';

function validDate(s: string | undefined): string | null {
  return s && /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : null;
}

type SB = Awaited<ReturnType<typeof createSupabaseServerClient>>;

// On edit entry: if the date has no instances, copy the template (silently, no revalidate).
async function materializeInline(supabase: SB, org: string, user: string, date: string) {
  const { count } = await supabase
    .schema('app')
    .from('routine_day_blocks' as never)
    .select('id' as never, { count: 'exact', head: true })
    .eq('user_id' as never, user)
    .eq('block_date' as never, date);
  if ((count ?? 0) > 0) return;

  const { data: tpl } = await supabase
    .schema('app')
    .from('routine_blocks' as never)
    .select('id, title, category, start_time, end_time, weekday_mask, sort_order')
    .eq('user_id' as never, user)
    .eq('active' as never, true);

  const dow = new Date(`${date}T12:00:00Z`).getUTCDay();
  const rows = ((tpl ?? []) as unknown as Array<{
    id: string; title: string; category: string;
    start_time: string; end_time: string; weekday_mask: number; sort_order: number;
  }>)
    .filter((b) => (b.weekday_mask & (1 << dow)) !== 0)
    .map((b) => ({
      organization_id: org,
      user_id: user,
      block_date: date,
      template_block_id: b.id,
      title: b.title,
      category: b.category,
      start_time: b.start_time,
      end_time: b.end_time,
      sort_order: b.sort_order,
      status: null,
    }));

  if (rows.length > 0) {
    await supabase
      .schema('app')
      .from('routine_day_blocks' as never)
      .upsert(rows as never, {
        onConflict: 'user_id,block_date,start_time,title',
        ignoreDuplicates: true,
      });
  }
}

export default async function ScheduleEditPage({
  searchParams,
}: {
  searchParams: Promise<{ date?: string }>;
}) {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const sp = await searchParams;
  const date = validDate(sp.date);

  let blocks: EditorBlock[];

  if (date) {
    // date edit mode — materialize on entry, then load instances
    await materializeInline(supabase, auth.organizationId, auth.userId, date);
    const res = await supabase
      .schema('app')
      .from('routine_day_blocks' as never)
      .select('id, title, category, start_time, end_time, sort_order')
      .eq('user_id' as never, auth.userId)
      .eq('block_date' as never, date);
    blocks = ((res.data ?? []) as unknown as RoutineDayBlock[])
      .map((b) => ({
        id: b.id, title: b.title, category: b.category,
        start_time: b.start_time, end_time: b.end_time,
      }))
      .sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time));
  } else {
    // template edit mode
    const res = await supabase
      .schema('app')
      .from('routine_blocks' as never)
      .select('id, title, category, start_time, end_time, weekday_mask, sort_order, active, note')
      .eq('user_id' as never, auth.userId);
    blocks = ((res.data ?? []) as unknown as RoutineBlock[])
      .map((b) => ({
        id: b.id, title: b.title, category: b.category,
        start_time: b.start_time, end_time: b.end_time,
        weekday_mask: b.weekday_mask, active: b.active,
      }))
      .sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time));
  }

  const backHref = date ? `/schedule?date=${date}` : '/schedule';

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">
            {date ? 'Edit Schedule' : 'Edit Default Template'}
          </h1>
          <p className="text-sm text-muted-foreground">
            {date
              ? `${humanDate(date)} - changes apply to this day only.`
              : 'Edit the daily default. Days you already customized are unaffected.'}
          </p>
        </div>
        <Link href={backHref} className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent">
          {date && date !== todayISO() ? 'Back to day' : 'Back'}
        </Link>
      </div>

      <ScheduleEditor blocks={blocks} date={date ?? undefined} />
    </div>
  );
}
