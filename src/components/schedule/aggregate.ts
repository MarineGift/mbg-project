// src/components/schedule/aggregate.ts
// routine_day_blocks(연 날의 인스턴스)로 일/주/월/년/카테고리 달성률을 계산하는 순수 모듈.
// "연 날"만 집계 → 각 인스턴스 행이 곧 그날의 계획 1건. partial=0.5 가중.
//   done/partial/skipped = 체크값,  missed = 미체크(pending)로 표기(컴포넌트 호환).

import { dowOf, type RoutineDayBlock } from './constants';

export type Bucket = {
  key: string;         // 표시용 라벨 (날짜/주/월/년/카테고리)
  planned_due: number; // 그 버킷의 계획 수(= 인스턴스 수)
  done: number;
  partial: number;
  skipped: number;
  missed: number;      // 미체크(pending)
  adherence_pct: number;
};

function isoAddDays(iso: string, delta: number): string {
  const d = new Date(`${iso}T12:00:00`);
  d.setDate(d.getDate() + delta);
  return new Intl.DateTimeFormat('en-CA', {
    year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(d);
}

// 월요일 시작 주(週)의 시작 날짜
function weekStart(iso: string): string {
  const dow = dowOf(iso);            // 0=일..6=토
  const back = dow === 0 ? 6 : dow - 1;
  return isoAddDays(iso, -back);
}

function emptyBucket(key: string): Bucket {
  return { key, planned_due: 0, done: 0, partial: 0, skipped: 0, missed: 0, adherence_pct: 0 };
}

function finalize(b: Bucket): Bucket {
  b.adherence_pct = b.planned_due
    ? Math.round((1000 * (b.done + 0.5 * b.partial)) / b.planned_due) / 10
    : 0;
  return b;
}

type KeyFn = (r: RoutineDayBlock) => string;

function groupBy(rows: RoutineDayBlock[], keyFn: KeyFn): Bucket[] {
  const map = new Map<string, Bucket>();
  for (const r of rows) {
    const key = keyFn(r);
    let bk = map.get(key);
    if (!bk) { bk = emptyBucket(key); map.set(key, bk); }
    bk.planned_due += 1;
    if (r.status === 'done') bk.done += 1;
    else if (r.status === 'partial') bk.partial += 1;
    else if (r.status === 'skipped') bk.skipped += 1;
    else bk.missed += 1; // null = 미체크
  }
  return Array.from(map.values()).map(finalize).sort((a, b) => (a.key < b.key ? 1 : -1));
}

export function aggregateDaily(rows: RoutineDayBlock[]): Bucket[] {
  return groupBy(rows, (r) => r.block_date);
}
export function aggregateWeekly(rows: RoutineDayBlock[]): Bucket[] {
  return groupBy(rows, (r) => weekStart(r.block_date));
}
export function aggregateMonthly(rows: RoutineDayBlock[]): Bucket[] {
  return groupBy(rows, (r) => r.block_date.slice(0, 7)); // YYYY-MM
}
export function aggregateYearly(rows: RoutineDayBlock[]): Bucket[] {
  return groupBy(rows, (r) => r.block_date.slice(0, 4)); // YYYY
}
export function aggregateCategory(rows: RoutineDayBlock[]): Bucket[] {
  return groupBy(rows, (r) => r.category)
    .sort((a, b) => b.adherence_pct - a.adherence_pct);
}
