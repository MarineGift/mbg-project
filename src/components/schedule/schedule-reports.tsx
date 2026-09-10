'use client';

// src/components/schedule/schedule-reports.tsx
// 리포트 렌더링 — 탭(매일/주간/월간/연간) + 카테고리별 달성률.

import { useState } from 'react';
import { cn } from '@/lib/utils';
import { catMeta } from './constants';
import type { Bucket } from './aggregate';

type Tab = 'daily' | 'weekly' | 'monthly' | 'yearly';
const TABS: { key: Tab; label: string }[] = [
  { key: 'daily', label: '매일' },
  { key: 'weekly', label: '주간' },
  { key: 'monthly', label: '월간' },
  { key: 'yearly', label: '연간' },
];

export function ScheduleReports({
  daily, weekly, monthly, yearly, category,
}: {
  daily: Bucket[]; weekly: Bucket[]; monthly: Bucket[]; yearly: Bucket[]; category: Bucket[];
}) {
  const [tab, setTab] = useState<Tab>('daily');
  const data = tab === 'daily' ? daily : tab === 'weekly' ? weekly : tab === 'monthly' ? monthly : yearly;

  return (
    <div className="space-y-6">
      {/* 탭 */}
      <div className="inline-flex rounded-lg border p-0.5">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={cn(
              'rounded-md px-3 py-1.5 text-sm font-medium transition-colors',
              tab === t.key ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-accent',
            )}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* 기간별 달성률 */}
      <div className="rounded-lg border">
        <div className="border-b px-4 py-2 text-xs font-medium text-muted-foreground">
          기간별 달성률 (부분수행 0.5 가중, 분모 = 도래한 계획 수)
        </div>
        <ul className="divide-y">
          {data.length === 0 && (
            <li className="px-4 py-6 text-center text-sm text-muted-foreground">데이터 없음</li>
          )}
          {data.map((b) => (
            <li key={b.key} className="flex items-center gap-3 px-4 py-2.5">
              <div className="w-28 shrink-0 text-sm tabular-nums">{fmtKey(tab, b.key)}</div>
              <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
                <div className={cn('h-full rounded-full', barColor(b.adherence_pct))}
                     style={{ width: `${b.adherence_pct}%` }} />
              </div>
              <div className="w-12 shrink-0 text-right text-sm font-medium tabular-nums">
                {b.adherence_pct}%
              </div>
              <div className="hidden w-40 shrink-0 text-right text-xs text-muted-foreground tabular-nums sm:block">
                ✓{b.done} ◐{b.partial} ✗{b.skipped} ·{b.missed}
              </div>
            </li>
          ))}
        </ul>
      </div>

      {/* 카테고리별 */}
      <div className="rounded-lg border">
        <div className="border-b px-4 py-2 text-xs font-medium text-muted-foreground">
          카테고리별 달성률 (최근 {'\u2264'}400일)
        </div>
        <ul className="divide-y">
          {category.length === 0 && (
            <li className="px-4 py-6 text-center text-sm text-muted-foreground">데이터 없음</li>
          )}
          {category.map((c) => {
            const meta = catMeta(c.key);
            return (
              <li key={c.key} className="flex items-center gap-3 px-4 py-2.5">
                <div className="flex w-24 shrink-0 items-center gap-2 text-sm">
                  <span className={cn('h-2 w-2 rounded-full', meta.dot)} />
                  {meta.label}
                </div>
                <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
                  <div className={cn('h-full rounded-full', meta.bar)}
                       style={{ width: `${c.adherence_pct}%` }} />
                </div>
                <div className="w-12 shrink-0 text-right text-sm font-medium tabular-nums">
                  {c.adherence_pct}%
                </div>
              </li>
            );
          })}
        </ul>
      </div>
    </div>
  );
}

function barColor(pct: number): string {
  if (pct >= 80) return 'bg-emerald-500';
  if (pct >= 50) return 'bg-amber-500';
  return 'bg-rose-500';
}

function fmtKey(tab: Tab, key: string): string {
  if (tab === 'daily') return key.slice(5);        // MM-DD
  if (tab === 'weekly') return `${key.slice(5)} 주`; // MM-DD 주
  if (tab === 'monthly') return key;               // YYYY-MM
  return `${key}년`;                                // YYYY년
}
