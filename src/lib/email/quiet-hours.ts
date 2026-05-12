/**
 * lib/email/quiet-hours.ts
 *
 * 발송 시점이 mail_merge_jobs.quiet_hours 정책에 위반되는지 평가.
 *
 * 외부 라이브러리 없이 Intl.DateTimeFormat의 timeZone 옵션을 활용해
 * IANA 타임존 변환을 수행한다(Node 18+/모던 브라우저 모두 지원).
 *
 * 자정을 가로지르는 구간(예: 22:00 → 08:00) 처리:
 *   start > end 인 경우, [start, 24:00) ∪ [00:00, end)를 차단 시간으로 본다.
 *
 * 주말 차단:
 *   weekends_blocked=true이고 발송 시점이 토(6)·일(0)이면 즉시 차단.
 */

import type { QuietHours } from '../../types/email';

/* ============================================================
 * 1. 타임존 변환
 * ============================================================ */

interface ZonedParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  weekday: number; // 0=Sun..6=Sat
}

/**
 * 주어진 UTC 시각을 IANA 타임존의 시계 시각으로 분해.
 * Intl.DateTimeFormat의 formatToParts를 사용.
 *
 * 잘못된 timezone 문자열은 RangeError를 throw하므로 caller에서 try-catch.
 */
export function getZonedParts(date: Date, timezone: string): ZonedParts {
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    weekday: 'short',
    hourCycle: 'h23',
  });
  const parts = fmt.formatToParts(date);
  const get = (type: string): string =>
    parts.find((p) => p.type === type)?.value ?? '0';

  const weekdayMap: Record<string, number> = {
    Sun: 0,
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
  };
  const weekday = weekdayMap[get('weekday') as keyof typeof weekdayMap] ?? 0;

  return {
    year: Number(get('year')),
    month: Number(get('month')),
    day: Number(get('day')),
    hour: Number(get('hour')),
    minute: Number(get('minute')),
    weekday,
  };
}

/* ============================================================
 * 2. quiet hours 평가
 * ============================================================ */

/**
 * "HH:mm" → 0~1439 분 단위 정수로 변환.
 * 잘못된 형식은 -1 반환(호출자가 폴백 처리).
 */
export function parseHHMM(hhmm: string): number {
  const m = /^(\d{1,2}):(\d{2})$/.exec(hhmm);
  if (!m) return -1;
  const h = Number(m[1]);
  const mm = Number(m[2]);
  if (h < 0 || h > 23 || mm < 0 || mm > 59) return -1;
  return h * 60 + mm;
}

export interface QuietHoursVerdict {
  blocked: boolean;
  reason?:
    | 'weekend_blocked'
    | 'within_quiet_hours'
    | 'invalid_config'
    | 'invalid_timezone';
  /** 차단된 경우, 다음 발송 가능 시각의 UTC ISO 문자열. */
  nextAllowedAt?: string;
}

/**
 * 현재 시각이 quiet hours에 해당하는지 평가.
 *
 * 잘못된 timezone·HH:mm 형식이면 blocked=true, reason='invalid_*'.
 * 운영 안전성: 정책 파싱 실패 시 발송 차단(보수적).
 *
 * @param now 평가 기준 시각(UTC). 미지정 시 현재.
 * @param qh QuietHours 설정.
 */
export function evaluateQuietHours(
  qh: QuietHours,
  now: Date = new Date(),
): QuietHoursVerdict {
  // start/end 검증
  const startMin = parseHHMM(qh.start);
  const endMin = parseHHMM(qh.end);
  if (startMin < 0 || endMin < 0) {
    return { blocked: true, reason: 'invalid_config' };
  }

  // 타임존 변환 시도
  let zoned: ZonedParts;
  try {
    zoned = getZonedParts(now, qh.timezone);
  } catch {
    return { blocked: true, reason: 'invalid_timezone' };
  }

  // 주말 차단
  if (qh.weekends_blocked && (zoned.weekday === 0 || zoned.weekday === 6)) {
    return {
      blocked: true,
      reason: 'weekend_blocked',
      nextAllowedAt: computeNextAllowed(now, qh, zoned, true).toISOString(),
    };
  }

  // 시간 범위 차단
  const totalMin = zoned.hour * 60 + zoned.minute;
  let inRange: boolean;
  if (startMin === endMin) {
    // start==end는 차단 의미 없음 (24h 허용 또는 24h 차단의 모호함 → 허용으로 해석)
    inRange = false;
  } else if (startMin > endMin) {
    // 자정 횡단: [start, 24:00) ∪ [00:00, end)
    inRange = totalMin >= startMin || totalMin < endMin;
  } else {
    // 일반: [start, end)
    inRange = totalMin >= startMin && totalMin < endMin;
  }

  if (inRange) {
    return {
      blocked: true,
      reason: 'within_quiet_hours',
      nextAllowedAt: computeNextAllowed(now, qh, zoned, false).toISOString(),
    };
  }

  return { blocked: false };
}

/* ============================================================
 * 3. 다음 발송 가능 시각 계산
 * ============================================================ */

/**
 * 현재 시각에서 quiet hours가 풀리는 다음 시점을 UTC Date로 계산.
 *
 * 휴리스틱 (정확한 분 단위 반올림은 mail-merge-worker가 다시 평가):
 *   - 주말 차단이면 다음 월요일 start 시각으로 이동
 *   - 자정 횡단(start>end)이면 오늘 또는 내일 end 시각으로 이동
 *   - 일반(start<end)이면 오늘 end 시각으로 이동
 *
 * 본 함수는 보수적 추정 — 정확하지 않으면 워커가 다음 iteration에서 재평가.
 */
function computeNextAllowed(
  now: Date,
  qh: QuietHours,
  zoned: ZonedParts,
  isWeekendBlocked: boolean,
): Date {
  const endMin = parseHHMM(qh.end);
  const startMin = parseHHMM(qh.start);

  if (isWeekendBlocked) {
    // 다음 월요일까지 계산
    const daysUntilMonday = zoned.weekday === 0 ? 1 : 8 - zoned.weekday;
    const candidate = new Date(now);
    candidate.setUTCDate(candidate.getUTCDate() + daysUntilMonday);
    // 시각은 startMin 이후부터 가능 — 시작 직후로 이동
    candidate.setUTCHours(0, 0, 0, 0);
    candidate.setUTCMinutes(endMin);
    return candidate;
  }

  // 일반 quiet hours
  // start>end (자정 횡단): totalMin >= start면 다음 날 end로, totalMin < end면 오늘 end로
  // start<end: 오늘 end로 (단순)
  const totalMin = zoned.hour * 60 + zoned.minute;
  const candidate = new Date(now);

  if (startMin > endMin) {
    // 자정 횡단
    if (totalMin >= startMin) {
      // 오늘 밤 → 내일 오전 endMin
      candidate.setUTCDate(candidate.getUTCDate() + 1);
    }
    // totalMin < endMin이면 오늘 오전 endMin
  }
  // start<end는 오늘 endMin

  // endMin을 UTC 시각으로 정확히 변환하긴 어려우므로, 보수적으로 +30분
  return new Date(candidate.getTime() + 30 * 60 * 1000);
}
