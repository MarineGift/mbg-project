/**
 * __tests__/email/quiet-hours.test.ts
 *
 * Unit tests for the quiet-hours evaluation function.
 * All times are created directly as UTC Date objects, and IANA timezone conversion is
 * delegated to Intl.DateTimeFormat - Node 22's default ICU data is sufficient.
 */

import { describe, it, expect } from 'vitest';
import {
  evaluateQuietHours,
  getZonedParts,
  parseHHMM,
} from '../../lib/email/quiet-hours';

describe('parseHHMM', () => {
  it('parses valid HH:mm', () => {
    expect(parseHHMM('00:00')).toBe(0);
    expect(parseHHMM('09:30')).toBe(570);
    expect(parseHHMM('23:59')).toBe(23 * 60 + 59);
  });
  it('returns -1 on invalid format', () => {
    expect(parseHHMM('25:00')).toBe(-1);
    expect(parseHHMM('09:60')).toBe(-1);
    expect(parseHHMM('abc')).toBe(-1);
    expect(parseHHMM('')).toBe(-1);
  });
});

describe('getZonedParts', () => {
  it('converts UTC to Asia/Seoul (+9)', () => {
    // UTC 2026-03-15 00:00 → Seoul 2026-03-15 09:00
    const utc = new Date('2026-03-15T00:00:00Z');
    const parts = getZonedParts(utc, 'Asia/Seoul');
    expect(parts.year).toBe(2026);
    expect(parts.month).toBe(3);
    expect(parts.day).toBe(15);
    expect(parts.hour).toBe(9);
    expect(parts.minute).toBe(0);
  });

  it('throws RangeError on invalid timezone', () => {
    expect(() => getZonedParts(new Date(), 'Not/A_TZ')).toThrow();
  });
});

describe('evaluateQuietHours — basic time range', () => {
  const qh = {
    timezone: 'UTC',
    start: '22:00',
    end: '08:00',
    weekends_blocked: false,
  };

  it('blocks at 23:00 UTC (within 22:00-08:00)', () => {
    // weekday (Wednesday) 23:00
    const v = evaluateQuietHours(qh, new Date('2026-03-04T23:00:00Z'));
    expect(v.blocked).toBe(true);
    expect(v.reason).toBe('within_quiet_hours');
  });

  it('blocks at 03:00 UTC (within 22:00-08:00 spanning midnight)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T03:00:00Z'));
    expect(v.blocked).toBe(true);
  });

  it('allows at 12:00 UTC (outside quiet hours)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T12:00:00Z'));
    expect(v.blocked).toBe(false);
  });

  it('allows exactly at end time (08:00 → 08:00 is allowed)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T08:00:00Z'));
    expect(v.blocked).toBe(false);
  });
});

describe('evaluateQuietHours — non-spanning range', () => {
  const qh = {
    timezone: 'UTC',
    start: '12:00',
    end: '13:00',
    weekends_blocked: false,
  };

  it('blocks at 12:30 (within 12:00-13:00)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T12:30:00Z'));
    expect(v.blocked).toBe(true);
  });

  it('allows at 13:00 (end is exclusive)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T13:00:00Z'));
    expect(v.blocked).toBe(false);
  });
});

describe('evaluateQuietHours — weekend blocking', () => {
  const qh = {
    timezone: 'UTC',
    start: '22:00',
    end: '08:00',
    weekends_blocked: true,
  };

  it('blocks on Saturday at noon', () => {
    // 2026-03-07 is Saturday
    const v = evaluateQuietHours(qh, new Date('2026-03-07T12:00:00Z'));
    expect(v.blocked).toBe(true);
    expect(v.reason).toBe('weekend_blocked');
    expect(v.nextAllowedAt).toBeDefined();
  });

  it('blocks on Sunday at noon', () => {
    // 2026-03-08 is Sunday
    const v = evaluateQuietHours(qh, new Date('2026-03-08T12:00:00Z'));
    expect(v.blocked).toBe(true);
    expect(v.reason).toBe('weekend_blocked');
  });
});

describe('evaluateQuietHours — Asia/Seoul timezone', () => {
  const qh = {
    timezone: 'Asia/Seoul',
    start: '22:00',
    end: '08:00',
    weekends_blocked: false,
  };

  it('blocks at UTC 13:00 (= Seoul 22:00)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T13:00:00Z'));
    expect(v.blocked).toBe(true);
  });

  it('allows at UTC 03:00 (= Seoul 12:00)', () => {
    const v = evaluateQuietHours(qh, new Date('2026-03-04T03:00:00Z'));
    expect(v.blocked).toBe(false);
  });
});

describe('evaluateQuietHours — invalid config', () => {
  it('blocks with invalid_config when start is malformed', () => {
    const v = evaluateQuietHours({
      timezone: 'UTC',
      start: '25:00',
      end: '08:00',
      weekends_blocked: false,
    });
    expect(v.blocked).toBe(true);
    expect(v.reason).toBe('invalid_config');
  });

  it('blocks with invalid_timezone when timezone is unknown', () => {
    const v = evaluateQuietHours({
      timezone: 'Not/A_Real_TZ',
      start: '22:00',
      end: '08:00',
      weekends_blocked: false,
    });
    expect(v.blocked).toBe(true);
    expect(v.reason).toBe('invalid_timezone');
  });
});
