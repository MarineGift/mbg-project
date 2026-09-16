// src/components/schedule/aggregate.ts
// Pure module computing daily/weekly/monthly/yearly/category adherence from
// routine_day_blocks (opened days only). Each instance row = one planned item
// for that day; partial = 0.5 weight.
//   done/partial/skipped = checked values, missed = not checked (pending).

import { dowOf, type RoutineDayBlock } from './constants';

export type Bucket = {
  key: string;         // display label (date/week/month/year/category)
  planned_due: number; // planned count for the bucket (= number of instances)
  done: number;
  partial: number;
  skipped: number;
  missed: number;      // not checked (pending)
  adherence_pct: number;
};

function isoAddDays(iso: string, delta: number): string {
  const d = new Date(`${iso}T12:00:00`);
  d.setDate(d.getDate() + delta);
  return new Intl.DateTimeFormat('en-CA', {
    year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(d);
}

// Start date of the (Monday-first) week
function weekStart(iso: string): string {
  const dow = dowOf(iso);            // 0=Sun..6=Sat
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
    else bk.missed += 1; // null = not checked
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
