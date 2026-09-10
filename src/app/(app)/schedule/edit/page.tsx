// src/app/(app)/schedule/edit/page.tsx
// 일과표 편집.
//   ?date=YYYY-MM-DD  → 그 날짜만 편집(진입 시 템플릿을 그날로 복사=materialize).
//   date 없음         → 기본 템플릿(routine_blocks) 편집 → 이후 모든 "안 연 날"의 기본이 바뀜.

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

// 편집 진입 시: 그날 인스턴스가 없으면 템플릿을 복사(revalidate 없이 조용히).
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
    // 날짜 편집 모드 — 진입 시 materialize 후 인스턴스 로드
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
    // 템플릿 편집 모드
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
            {date ? '일정 편집' : '기본 템플릿 편집'}
          </h1>
          <p className="text-sm text-muted-foreground">
            {date
              ? `${humanDate(date)} — 이 날짜만 수정됩니다.`
              : '매일의 기본값을 수정합니다. 이미 수정한 날짜에는 영향 없음.'}
          </p>
        </div>
        <Link href={backHref} className="rounded-md border px-3 py-1.5 text-sm font-medium hover:bg-accent">
          {date && date !== todayISO() ? '날짜로' : '돌아가기'}
        </Link>
      </div>

      <ScheduleEditor blocks={blocks} date={date ?? undefined} />
    </div>
  );
}
