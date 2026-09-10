'use client';

// src/components/schedule/schedule-today.tsx
// 특정 날짜 일과 체크 UI — 날짜 이동 + 각 블록을 완료/부분/건너뜀 으로 표시.
// materialize 전/후로 블록 id가 바뀌어도 체크가 유지되도록 (시작시각|제목) 안정키로 상태 관리.

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  Check, Minus, X, Loader2, CheckCheck, ChevronLeft, ChevronRight, RotateCcw,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { setDayStatus, completeDay, resetDayToTemplate } from '@/app/actions/schedule';
import {
  catMeta, hhmm, humanDate, isoAddDays, todayISO,
  type DayBlockView, type RoutineStatus,
} from './constants';

function keyOf(b: { start_time: string; title: string }): string {
  return `${hhmm(b.start_time)}|${b.title}`;
}

export function ScheduleToday({
  date,
  blocks,
  materialized,
}: {
  date: string;
  blocks: DayBlockView[];
  materialized: boolean;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [busyKey, setBusyKey] = useState<string | null>(null);

  // 안정키 → status
  const [statusMap, setStatusMap] = useState<Record<string, RoutineStatus | undefined>>(() => {
    const m: Record<string, RoutineStatus> = {};
    for (const b of blocks) if (b.status) m[keyOf(b)] = b.status;
    return m;
  });

  const total = blocks.length;
  const doneCount = blocks.filter((b) => statusMap[keyOf(b)] === 'done').length;
  const partialCount = blocks.filter((b) => statusMap[keyOf(b)] === 'partial').length;
  const recorded = blocks.filter((b) => statusMap[keyOf(b)]).length;
  const pct = total ? Math.round((100 * (doneCount + 0.5 * partialCount)) / total) : 0;

  const today = todayISO();
  const prevDate = isoAddDays(date, -1);
  const nextDate = isoAddDays(date, 1);

  function apply(b: DayBlockView, next: RoutineStatus) {
    const k = keyOf(b);
    const current = statusMap[k];
    const target: RoutineStatus | null = current === next ? null : next; // 같은 걸 다시 누르면 해제
    setStatusMap((m) => ({ ...m, [k]: target ?? undefined }));
    setBusyKey(k);
    startTransition(async () => {
      const res = await setDayStatus(
        date,
        { dayBlockId: materialized ? b.id : undefined, start_time: b.start_time, title: b.title },
        target,
      );
      setBusyKey(null);
      if (!res.success) {
        setStatusMap((m) => ({ ...m, [k]: current })); // 롤백
        alert(`저장 실패: ${res.error}`);
        return;
      }
      router.refresh();
    });
  }

  function completeAll() {
    setStatusMap((m) => {
      const n = { ...m };
      for (const b of blocks) n[keyOf(b)] = 'done';
      return n;
    });
    startTransition(async () => {
      const res = await completeDay(date);
      if (!res.success) alert(`저장 실패: ${res.error}`);
      router.refresh();
    });
  }

  function resetDay() {
    if (!confirm('이 날짜의 수정 내용을 지우고 기본 일정으로 되돌릴까요?')) return;
    startTransition(async () => {
      const res = await resetDayToTemplate(date);
      if (!res.success) { alert(`초기화 실패: ${res.error}`); return; }
      router.refresh();
    });
  }

  return (
    <div>
      {/* 날짜 이동 바 */}
      <div className="mb-3 flex items-center justify-between gap-2">
        <Link
          href={`/schedule?date=${prevDate}`}
          className="inline-flex h-9 w-9 items-center justify-center rounded-md border hover:bg-accent"
          aria-label="이전 날"
        >
          <ChevronLeft className="h-4 w-4" />
        </Link>

        <div className="flex flex-1 items-center justify-center gap-2">
          <span className="text-sm font-semibold tabular-nums">{humanDate(date)}</span>
          <span
            className={cn(
              'rounded px-1.5 py-0.5 text-[11px] font-medium ring-1 ring-inset',
              materialized
                ? 'bg-blue-50 text-blue-700 ring-blue-600/20'
                : 'bg-zinc-100 text-zinc-600 ring-zinc-500/20',
            )}
          >
            {materialized ? '수정됨' : '기본'}
          </span>
          {date !== today && (
            <Link
              href={`/schedule?date=${today}`}
              className="rounded-md border px-2 py-0.5 text-xs font-medium hover:bg-accent"
            >
              오늘
            </Link>
          )}
        </div>

        <Link
          href={`/schedule?date=${nextDate}`}
          className="inline-flex h-9 w-9 items-center justify-center rounded-md border hover:bg-accent"
          aria-label="다음 날"
        >
          <ChevronRight className="h-4 w-4" />
        </Link>
      </div>

      {/* 진행률 헤더 */}
      <div className="mb-4 rounded-lg border p-4">
        <div className="mb-2 flex items-center justify-between gap-2 text-sm">
          <span className="whitespace-nowrap font-medium">
            달성률 <span className="tabular-nums">{pct}%</span>
          </span>
          <span className="text-right text-xs tabular-nums text-muted-foreground sm:text-sm">
            완료 {doneCount} · 부분 {partialCount} · 기록 {recorded}/{total}
          </span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-emerald-500 transition-all"
            style={{ width: `${pct}%` }}
          />
        </div>
        <div className="mt-3 flex justify-end gap-2">
          {materialized && (
            <button
              onClick={resetDay}
              disabled={isPending}
              className="inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs font-medium text-muted-foreground hover:bg-accent disabled:opacity-50"
            >
              <RotateCcw className="h-3.5 w-3.5" /> 기본으로 되돌리기
            </button>
          )}
          <button
            onClick={completeAll}
            disabled={isPending}
            className="inline-flex items-center gap-1.5 rounded-md border px-2.5 py-1 text-xs font-medium hover:bg-accent disabled:opacity-50"
          >
            <CheckCheck className="h-3.5 w-3.5" /> 전체 완료
          </button>
        </div>
      </div>

      {/* 블록 목록 */}
      <ul className="space-y-2">
        {blocks.map((b) => {
          const meta = catMeta(b.category);
          const k = keyOf(b);
          const st = statusMap[k];
          const rowBusy = busyKey === k && isPending;
          return (
            <li
              key={b.id}
              className={cn(
                'flex items-center gap-2 rounded-lg border p-2.5 transition-colors sm:gap-3 sm:p-3',
                st === 'done' && 'border-emerald-200 bg-emerald-50/40',
                st === 'partial' && 'border-amber-200 bg-amber-50/40',
                st === 'skipped' && 'border-zinc-200 bg-zinc-50/60 opacity-70',
              )}
            >
              {/* 시간: 세로로 쌓아 좁게 (시작 위 / 종료 아래) */}
              <div className="w-10 shrink-0 text-center text-[11px] leading-tight tabular-nums text-muted-foreground sm:w-11 sm:text-xs">
                <div>{hhmm(b.start_time)}</div>
                <div className="opacity-60">{hhmm(b.end_time)}</div>
              </div>

              <span className={cn('h-2 w-2 shrink-0 rounded-full', meta.dot)} aria-hidden />

              <div className="min-w-0 flex-1">
                <div
                  className={cn(
                    'truncate text-sm font-medium',
                    st === 'skipped' && 'line-through',
                  )}
                >
                  {b.title}
                </div>
                <span
                  className={cn(
                    'mt-0.5 inline-block rounded px-1.5 py-0.5 text-[11px] font-medium ring-1 ring-inset',
                    meta.chip,
                  )}
                >
                  {meta.label}
                </span>
              </div>

              {rowBusy ? (
                <Loader2 className="h-4 w-4 shrink-0 animate-spin text-muted-foreground" />
              ) : (
                <div className="flex shrink-0 items-center gap-0.5">
                  <StatusBtn active={st === 'done'} onClick={() => apply(b, 'done')}
                    title="완료" activeClass="bg-emerald-500 text-white border-emerald-500">
                    <Check className="h-3.5 w-3.5" />
                  </StatusBtn>
                  <StatusBtn active={st === 'partial'} onClick={() => apply(b, 'partial')}
                    title="부분" activeClass="bg-amber-500 text-white border-amber-500">
                    <Minus className="h-3.5 w-3.5" />
                  </StatusBtn>
                  <StatusBtn active={st === 'skipped'} onClick={() => apply(b, 'skipped')}
                    title="건너뜀" activeClass="bg-zinc-500 text-white border-zinc-500">
                    <X className="h-3.5 w-3.5" />
                  </StatusBtn>
                </div>
              )}
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function StatusBtn({
  active, onClick, title, activeClass, children,
}: {
  active: boolean;
  onClick: () => void;
  title: string;
  activeClass: string;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      title={title}
      aria-pressed={active}
      className={cn(
        'inline-flex h-7 w-7 items-center justify-center rounded-md border text-muted-foreground transition-colors hover:bg-accent',
        active && activeClass,
      )}
    >
      {children}
    </button>
  );
}
