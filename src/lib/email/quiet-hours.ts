/**
 * lib/email/quiet-hours.ts
 *
 * Evaluate whether the send time violates the mail_merge_jobs.quiet_hours policy.
 *
 * Without any external library, uses the timeZone option of Intl.DateTimeFormat to
 * perform IANA timezone conversion (supported on Node 18+ and modern browsers).
 *
 * Handling ranges that cross midnight (e.g. 22:00 -> 08:00):
 *   when start > end, treat [start, 24:00) U [00:00, end) as the blocked window.
 *
 * Weekend blocking:
 *   if weekends_blocked=true and the send time is Sat (6) or Sun (0), block immediately.
 */

import type { QuietHours } from '../../types/email';

/* ============================================================
 * 1. Timezone conversion
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
 * Decompose a given UTC time into wall-clock time in an IANA timezone.
 * Uses formatToParts of Intl.DateTimeFormat.
 *
 * Invalid timezone strings throw a RangeError, so the caller should try-catch.
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
 * 2. quiet hours evaluation
 * ============================================================ */

/**
 * "HH:mm" -> convert to an integer number of minutes (0-1439).
 * Invalid formats return -1 (the caller handles the fallback).
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
  /** When blocked, the UTC ISO string of the next allowed send time. */
  nextAllowedAt?: string;
}

/**
 * Evaluate whether the current time falls within quiet hours.
 *
 * On an invalid timezone or HH:mm format, blocked=true, reason='invalid_*'.
 * Operational safety: if policy parsing fails, block sending (conservative).
 *
 * @param now reference time for evaluation (UTC). Defaults to now if omitted.
 * @param qh QuietHours settings.
 */
export function evaluateQuietHours(
  qh: QuietHours,
  now: Date = new Date(),
): QuietHoursVerdict {
  // validate start/end
  const startMin = parseHHMM(qh.start);
  const endMin = parseHHMM(qh.end);
  if (startMin < 0 || endMin < 0) {
    return { blocked: true, reason: 'invalid_config' };
  }

  // attempt timezone conversion
  let zoned: ZonedParts;
  try {
    zoned = getZonedParts(now, qh.timezone);
  } catch {
    return { blocked: true, reason: 'invalid_timezone' };
  }

  // weekend blocking
  if (qh.weekends_blocked && (zoned.weekday === 0 || zoned.weekday === 6)) {
    return {
      blocked: true,
      reason: 'weekend_blocked',
      nextAllowedAt: computeNextAllowed(now, qh, zoned, true).toISOString(),
    };
  }

  // time-range blocking
  const totalMin = zoned.hour * 60 + zoned.minute;
  let inRange: boolean;
  if (startMin === endMin) {
    // start==end has no blocking meaning (ambiguous between allow-24h and block-24h -> interpreted as allow)
    inRange = false;
  } else if (startMin > endMin) {
    // crosses midnight: [start, 24:00) U [00:00, end)
    inRange = totalMin >= startMin || totalMin < endMin;
  } else {
    // normal: [start, end)
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
 * 3. Compute the next allowed send time
 * ============================================================ */

/**
 * Compute, as a UTC Date, the next moment quiet hours lift from the current time.
 *
 * Heuristic (exact minute-level rounding is re-evaluated by mail-merge-worker):
 *   - if weekend-blocked, move to next Monday's start time
 *   - if crossing midnight (start>end), move to today's or tomorrow's end time
 *   - if normal (start<end), move to today's end time
 *
 * This function is a conservative estimate - if imprecise, the worker re-evaluates on the next iteration.
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
    // compute days until next Monday
    const daysUntilMonday = zoned.weekday === 0 ? 1 : 8 - zoned.weekday;
    const candidate = new Date(now);
    candidate.setUTCDate(candidate.getUTCDate() + daysUntilMonday);
    // time is allowed from startMin onward - move to just after the start
    candidate.setUTCHours(0, 0, 0, 0);
    candidate.setUTCMinutes(endMin);
    return candidate;
  }

  // normal quiet hours
  // start>end (crosses midnight): if totalMin >= start go to next day's end, if totalMin < end go to today's end
  // start<end: go to today's end (simple)
  const totalMin = zoned.hour * 60 + zoned.minute;
  const candidate = new Date(now);

  if (startMin > endMin) {
    // crosses midnight
    if (totalMin >= startMin) {
      // tonight -> tomorrow morning's endMin
      candidate.setUTCDate(candidate.getUTCDate() + 1);
    }
    // if totalMin < endMin, today's morning endMin
  }
  // start<end is today's endMin

  // exactly converting endMin to a UTC time is hard, so conservatively add +30 min
  return new Date(candidate.getTime() + 30 * 60 * 1000);
}
