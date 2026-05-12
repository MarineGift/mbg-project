/**
 * tests/url-parsers.test.ts
 *
 * URL searchParams → filter 객체로 변환하는 파서들의 단위 테스트.
 * 이들은 server-only 모듈에서 import — 'server-only' 폴리필 필요.
 */

import { describe, it, expect, vi } from 'vitest';

// server-only 폴리필 — Vitest 환경에서 import 가능하게
vi.mock('server-only', () => ({}));

// supabase server client mock — 파서는 client 사용 안 함
vi.mock('@/lib/supabase/server', () => ({
  createSupabaseServerClient: vi.fn(),
}));

import {
  parseInboxFilters,
  parseInboxPagination,
} from '@/lib/queries/inbox';
import {
  parseTaskFilters,
  parseTaskSort,
  parseTaskPagination,
} from '@/lib/queries/tasks';

describe('parseInboxFilters', () => {
  it('defaults all filters to "all" / empty / false', () => {
    const filters = parseInboxFilters({});
    expect(filters).toEqual({
      channel: 'all',
      direction: 'all',
      query: '',
      hasDraft: false,
      partyId: null,
    });
  });

  it('parses valid channel + direction', () => {
    const filters = parseInboxFilters({
      channel: 'email',
      direction: 'inbound',
    });
    expect(filters.channel).toBe('email');
    expect(filters.direction).toBe('inbound');
  });

  it('rejects unknown channel — falls back to "all"', () => {
    const filters = parseInboxFilters({ channel: 'pigeon' });
    expect(filters.channel).toBe('all');
  });

  it('parses hasDraft=1 as true', () => {
    expect(parseInboxFilters({ hasDraft: '1' }).hasDraft).toBe(true);
    expect(parseInboxFilters({ hasDraft: '0' }).hasDraft).toBe(false);
    expect(parseInboxFilters({}).hasDraft).toBe(false);
  });

  it('parses valid UUID party — rejects non-UUID', () => {
    const validUuid = '12345678-1234-1234-1234-123456789012';
    expect(parseInboxFilters({ party: validUuid }).partyId).toBe(validUuid);
    expect(parseInboxFilters({ party: 'not-a-uuid' }).partyId).toBeNull();
  });

  it('trims query string', () => {
    expect(parseInboxFilters({ q: '  hello  ' }).query).toBe('hello');
  });

  it('handles array searchParam (takes first)', () => {
    expect(parseInboxFilters({ channel: ['email', 'slack'] }).channel).toBe('email');
  });
});

describe('parseInboxPagination', () => {
  it('defaults to page=1, size=25', () => {
    expect(parseInboxPagination({})).toEqual({ page: 1, pageSize: 25 });
  });

  it('parses valid page', () => {
    expect(parseInboxPagination({ page: '3' }).page).toBe(3);
  });

  it('rejects negative/zero page', () => {
    expect(parseInboxPagination({ page: '0' }).page).toBe(1);
    expect(parseInboxPagination({ page: '-5' }).page).toBe(1);
  });

  it('rejects non-numeric page', () => {
    expect(parseInboxPagination({ page: 'abc' }).page).toBe(1);
  });

  it('accepts valid pageSize from allowed options', () => {
    expect(parseInboxPagination({ size: '50' }).pageSize).toBe(50);
    expect(parseInboxPagination({ size: '100' }).pageSize).toBe(100);
  });

  it('rejects invalid pageSize — falls to default 25', () => {
    expect(parseInboxPagination({ size: '37' }).pageSize).toBe(25);
    expect(parseInboxPagination({ size: '999' }).pageSize).toBe(25);
  });
});

describe('parseTaskFilters', () => {
  it('defaults status to "open"', () => {
    expect(parseTaskFilters({}).status).toBe('open');
  });

  it('accepts each valid TaskStatus', () => {
    for (const s of ['todo', 'in_progress', 'blocked', 'done', 'cancelled']) {
      expect(parseTaskFilters({ status: s }).status).toBe(s);
    }
    expect(parseTaskFilters({ status: 'all' }).status).toBe('all');
    expect(parseTaskFilters({ status: 'open' }).status).toBe('open');
  });

  it('overdueOnly=1 → true', () => {
    expect(parseTaskFilters({ overdue: '1' }).overdueOnly).toBe(true);
    expect(parseTaskFilters({ overdue: 'true' }).overdueOnly).toBe(false); // 정확히 '1'만
  });

  it('defaults sort to "due_soonest"', () => {
    expect(parseTaskSort({})).toBe('due_soonest');
  });

  it('accepts valid sort values', () => {
    expect(parseTaskSort({ sort: 'priority' })).toBe('priority');
    expect(parseTaskSort({ sort: 'newest' })).toBe('newest');
  });

  it('rejects unknown sort — falls to default', () => {
    expect(parseTaskSort({ sort: 'random' })).toBe('due_soonest');
  });

  it('parseTaskPagination behaves like inbox', () => {
    expect(parseTaskPagination({}).pageSize).toBe(25);
    expect(parseTaskPagination({ size: '50' }).pageSize).toBe(50);
  });
});
