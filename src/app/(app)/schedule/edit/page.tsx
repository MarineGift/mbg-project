// src/app/(app)/schedule/edit/page.tsx
// 일과표 편집 — 시간블록 추가/수정/삭제, 요일 지정.

import Link from 'next/link';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ScheduleEditor } from '@/components/schedule/schedule-editor';
import { toMinutes, type RoutineBlock } from '@/components/schedule/constants';

export const dynamic = 'force-dynamic';

export default async function ScheduleEditPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const res = await supabase
    .schema('app')
    .from('routine_blocks' as never)
    .select('id, title, category, start_time, end_time, weekday_mask, sort_order, active, note')
    .eq('user_id' as never, auth.userId);

  const blocks = ((res.data ?? []) as unknown as RoutineBlock[])
    .sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time));

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">일과표 편집</h1>
          <p className="text-sm text-muted-foreground">시간블록을 추가·수정하고 요일을 지정하세요.</p>
        </div>
        <Link href="/schedule" className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent">
          오늘로
        </Link>
      </div>

      <ScheduleEditor blocks={blocks} />
    </div>
  );
}
