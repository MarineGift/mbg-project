'use client';

// src/components/schedule/schedule-today.tsx
// 오늘 일과 체크 UI — 각 블록을 완료/부분/건너뜀 으로 표시.

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Check, Minus, X, Loader2, CheckCheck } from 'lucide-react';
import { cn } from '@/lib/utils';
import { setRoutineStatus, completeAllForDate } from '@/app/actions/schedule';
import {
  catMeta, hhmm, type RoutineBlock, type RoutineLog, type RoutineStatus,
} from './constants';

export function ScheduleToday({
  date,
  blocks,
  initialLogs,
}: {
  date: string;
  blocks: RoutineBlock[];
  initialLogs: RoutineLog[];
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [busyId, setBusyId] = useState<string | null>(null);

  // block_id → status
  const [statusMap, setStatusMap] = useState<Record<string, RoutineStatus | undefined>>(() => {
    const m: Record<string, RoutineStatus> = {};
    for (const l of initialLogs) m[l.block_id] = l.status;
    return m;
  });

  const total = blocks.length;
  const doneCount = blocks.filter((b) => statusMap[b.id] === 'done').length;
  const partialCount = blocks.filter((b) => statusMap[b.id] === 'partial').length;
  const recorded = blocks.filter((b) => statusMap[b.id]).length;
  const pct = total ? Math.round((100 * (doneCount + 0.5 * partialCount)) / total) : 0;

  function apply(blockId: string, next: RoutineStatus) {
    const current = statusMap[blockId];
    const target: RoutineStatus | null = current === next ? null : next; // 같은 걸 다시 누르면 해제
    setStatusMap((m) => ({ ...m, [blockId]: target ?? undefined }));
    setBusyId(blockId);
    startTransition(async () => {
      const res = await setRoutineStatus(blockId, date, target);
      setBusyId(null);
      if (!res.success) {
        // 실패 시 롤백
        setStatusMap((m) => ({ ...m, [blockId]: current }));
        alert(`저장 실패: ${res.error}`);
        return;
      }
      router.refresh();
    });
  }

  function completeAll() {
    const ids = blocks.map((b) => b.id);
    setStatusMap((m) => {
      const n = { ...m };
      for (const id of ids) n[id] = 'done';
      return n;
    });
    startTransition(async () => {
      const res = await completeAllForDate(ids, date);
      if (!res.success) alert(`저장 실패: ${res.error}`);
      router.refresh();
    });
  }

  return (
    <div>
      {/* 진행률 헤더 */}
      <div className="mb-4 rounded-lg border p-4">
        <div className="mb-2 flex items-center justify-between text-sm">
          <span className="font-medium">
            달성률 <span className="tabular-nums">{pct}%</span>
          </span>
          <span className="text-muted-foreground tabular-nums">
            완료 {doneCount} · 부분 {partialCount} · 기록 {recorded}/{total}
          </span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-emerald-500 transition-all"
            style={{ width: `${pct}%` }}
          />
        </div>
        <div className="mt-3 flex justify-end">
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
          const st = statusMap[b.id];
          const rowBusy = busyId === b.id && isPending;
          return (
            <li
              key={b.id}
              className={cn(
                'flex items-center gap-3 rounded-lg border p-3 transition-colors',
                st === 'done' && 'border-emerald-200 bg-emerald-50/40',
                st === 'partial' && 'border-amber-200 bg-amber-50/40',
                st === 'skipped' && 'border-zinc-200 bg-zinc-50/60 opacity-70',
              )}
            >
              <div className="w-[92px] shrink-0 text-sm tabular-nums text-muted-foreground">
                {hhmm(b.start_time)}–{hhmm(b.end_time)}
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
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              ) : (
                <div className="flex shrink-0 items-center gap-1">
                  <StatusBtn active={st === 'done'} onClick={() => apply(b.id, 'done')}
                    title="완료" activeClass="bg-emerald-500 text-white border-emerald-500">
                    <Check className="h-4 w-4" />
                  </StatusBtn>
                  <StatusBtn active={st === 'partial'} onClick={() => apply(b.id, 'partial')}
                    title="부분" activeClass="bg-amber-500 text-white border-amber-500">
                    <Minus className="h-4 w-4" />
                  </StatusBtn>
                  <StatusBtn active={st === 'skipped'} onClick={() => apply(b.id, 'skipped')}
                    title="건너뜀" activeClass="bg-zinc-500 text-white border-zinc-500">
                    <X className="h-4 w-4" />
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
        'inline-flex h-8 w-8 items-center justify-center rounded-md border text-muted-foreground transition-colors hover:bg-accent',
        active && activeClass,
      )}
    >
      {children}
    </button>
  );
}
