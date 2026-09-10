// src/components/schedule/aggregate.ts
// 계획(blocks) + 실제(logs)로 일/주/월/년/카테고리 달성률을 계산하는 순수 모듈.
// 서버 컴포넌트에서 호출 (DB 뷰와 동일한 규칙: partial=0.5 가중, 분모=도래한 계획 수).

import {
  blockActiveOn, dowOf, type RoutineBlock, type RoutineLog, type RoutineStatus,
} from './constants';

export type Bucket = {
  key: string;         // 표시용 라벨 (날짜/주/월/년/카테고리)
  planned_due: number; // 오늘까지 도래한 계획 수
  done: number;
  partial: number;
  skipped: number;
  missed: number;
  adherence_pct: number;
};

export type Occurrence = {
  date: string;
  block: RoutineBlock;
  status: RoutineStatus | 'missed' | 'pending' | 'upcoming';
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

/** 윈도우 내 모든 계획 발생(occurrence)을 생성하고 로그와 결합해 상태를 부여 */
export function buildOccurrences(
  blocks: RoutineBlock[],
  logs: RoutineLog[],
  today: string,
  windowDays = 400,
): Occurrence[] {
  const logMap = new Map<string, RoutineStatus>();
  for (const l of logs) logMap.set(`${l.block_id}|${l.log_date}`, l.status);

  const out: Occurrence[] = [];
  const start = isoAddDays(today, -(windowDays - 1));
  for (let cur = start; cur <= today; cur = isoAddDays(cur, 1)) {
    const dow = dowOf(cur);
    for (const b of blocks) {
      if (!b.active || !blockActiveOn(b.weekday_mask, dow)) continue;
      const st = logMap.get(`${b.id}|${cur}`);
      out.push({
        date: cur,
        block: b,
        status: st ?? (cur < today ? 'missed' : cur === today ? 'pending' : 'upcoming'),
      });
    }
  }
  return out;
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

type KeyFn = (o: Occurrence) => string;

function groupBy(occ: Occurrence[], today: string, keyFn: KeyFn): Bucket[] {
  const map = new Map<string, Bucket>();
  for (const o of occ) {
    const key = keyFn(o);
    let bk = map.get(key);
    if (!bk) { bk = emptyBucket(key); map.set(key, bk); }
    if (o.date <= today) bk.planned_due += 1;
    if (o.status === 'done') bk.done += 1;
    else if (o.status === 'partial') bk.partial += 1;
    else if (o.status === 'skipped') bk.skipped += 1;
    else if (o.status === 'missed') bk.missed += 1;
  }
  return Array.from(map.values()).map(finalize).sort((a, b) => (a.key < b.key ? 1 : -1));
}

export function aggregateDaily(occ: Occurrence[], today: string): Bucket[] {
  return groupBy(occ, today, (o) => o.date);
}
export function aggregateWeekly(occ: Occurrence[], today: string): Bucket[] {
  return groupBy(occ, today, (o) => weekStart(o.date));
}
export function aggregateMonthly(occ: Occurrence[], today: string): Bucket[] {
  return groupBy(occ, today, (o) => o.date.slice(0, 7)); // YYYY-MM
}
export function aggregateYearly(occ: Occurrence[], today: string): Bucket[] {
  return groupBy(occ, today, (o) => o.date.slice(0, 4)); // YYYY
}
export function aggregateCategory(occ: Occurrence[], today: string): Bucket[] {
  return groupBy(occ, today, (o) => o.block.category)
    .sort((a, b) => b.adherence_pct - a.adherence_pct);
}
