/**
 * __tests__/setup/supabase-mock.ts
 *
 * Supabase 클라이언트 mock 빌더.
 *
 * 핵심 설계:
 *   - select / insert / update / delete 어느 것이든 builder 객체 반환
 *   - eq / order / limit 등 모든 chain 메서드도 builder 반환
 *   - 종단 평가는 다음 중 하나:
 *       * .single() / .maybeSingle() 호출 → 등록된 응답 반환
 *       * await builder (thenable) → 등록된 응답 반환 (Supabase의 PostgREST 동작)
 */

import { vi } from 'vitest';

export interface TableMockResponses {
  selectMaybeSingle?: { data: unknown; error?: unknown };
  selectCount?: { count: number; error?: unknown };
  selectList?: { data: unknown[]; error?: unknown };
  insertSingle?: { data: unknown; error?: unknown };
  updateResult?: { data?: unknown; error?: unknown };
  rpcResult?: { data: unknown; error?: unknown };
}

export interface SupabaseMockSpec {
  [schemaTable: string]: TableMockResponses;
}

export interface MockSupabaseCalls {
  insert: Array<{ schema: string; table: string; payload: unknown }>;
  update: Array<{ schema: string; table: string; payload: unknown }>;
  select: Array<{ schema: string; table: string; columns: string }>;
  rpc: Array<{ name: string; args: unknown }>;
}

export interface MockSupabase {
  schema: ReturnType<typeof vi.fn>;
  from: ReturnType<typeof vi.fn>;
  rpc: ReturnType<typeof vi.fn>;
  storage: {
    from: ReturnType<typeof vi.fn>;
  };
  __calls: MockSupabaseCalls;
}

export function buildSupabaseMock(spec: SupabaseMockSpec = {}): MockSupabase {
  const calls: MockSupabaseCalls = {
    insert: [],
    update: [],
    select: [],
    rpc: [],
  };

  const root: MockSupabase = {
    schema: vi.fn((schemaName: string) => ({
      from: (table: string) => makeQueryBuilder(schemaName, table),
    })),
    from: vi.fn((table: string) => makeQueryBuilder('public', table)),
    rpc: vi.fn((name: string, args: unknown) => {
      calls.rpc.push({ name, args });
      const r = spec[`rpc.${name}`];
      return Promise.resolve(r?.rpcResult ?? { data: null, error: null });
    }),
    storage: {
      from: vi.fn(() => ({
        upload: vi.fn(() => Promise.resolve({ data: null, error: null })),
        remove: vi.fn(() => Promise.resolve({ data: null, error: null })),
        download: vi.fn(() => Promise.resolve({ data: null, error: null })),
      })),
    },
    __calls: calls,
  };

  function makeQueryBuilder(schema: string, table: string) {
    const key = `${schema}.${table}`;
    const responses = spec[key] ?? {};

    let mode: 'select' | 'insert' | 'update' | 'delete' = 'select';
    let isCountHead = false;

    // 종단 응답 결정
    function resolveTerminal(forSingle: boolean): { data: unknown; error: unknown; count?: number } {
      if (mode === 'insert') {
        const r = responses.insertSingle ?? { data: null, error: null };
        return { data: r.data, error: r.error ?? null };
      }
      if (mode === 'update') {
        const r = responses.updateResult ?? { data: null, error: null };
        return { data: r.data ?? null, error: r.error ?? null };
      }
      if (mode === 'delete') {
        return { data: null, error: null };
      }
      // select
      if (isCountHead) {
        const r = responses.selectCount ?? { count: 0, error: null };
        return { data: null, error: r.error ?? null, count: r.count };
      }
      if (forSingle) {
        const r = responses.selectMaybeSingle ?? { data: null, error: null };
        return { data: r.data, error: r.error ?? null };
      }
      const r = responses.selectList ?? { data: [], error: null };
      return { data: r.data, error: r.error ?? null };
    }

    const builder: Record<string, unknown> = {};

    builder.select = vi.fn(
      (cols?: unknown, options?: { count?: string; head?: boolean }) => {
        // insert/update 후의 .select()는 PostgREST RETURNING — mode 유지
        if (mode !== 'insert' && mode !== 'update') {
          mode = 'select';
        }
        const colStr = typeof cols === 'string' ? cols : '*';
        if (options?.count === 'exact' && options?.head === true) {
          isCountHead = true;
        }
        calls.select.push({ schema, table, columns: colStr });
        return builder;
      },
    );
    builder.insert = vi.fn((payload: unknown) => {
      mode = 'insert';
      calls.insert.push({ schema, table, payload });
      return builder;
    });
    builder.update = vi.fn((payload: unknown) => {
      mode = 'update';
      calls.update.push({ schema, table, payload });
      return builder;
    });
    builder.delete = vi.fn(() => {
      mode = 'delete';
      return builder;
    });
    builder.upsert = vi.fn((payload: unknown) => {
      mode = 'insert';
      calls.insert.push({ schema, table, payload });
      return builder;
    });

    for (const m of [
      'eq', 'neq', 'gt', 'gte', 'lt', 'lte',
      'like', 'ilike', 'is', 'in', 'contains', 'containedBy',
      'rangeGt', 'rangeGte', 'rangeLt', 'rangeLte', 'rangeAdjacent',
      'overlaps', 'textSearch', 'match', 'not', 'or', 'filter',
      'order', 'limit', 'range', 'abortSignal', 'returns',
    ]) {
      builder[m] = vi.fn(() => builder);
    }

    builder.single = vi.fn(() => Promise.resolve(resolveTerminal(true)));
    builder.maybeSingle = vi.fn(() => Promise.resolve(resolveTerminal(true)));

    builder.then = (
      onFulfilled?: (v: unknown) => unknown,
      onRejected?: (v: unknown) => unknown,
    ): Promise<unknown> =>
      Promise.resolve(resolveTerminal(false)).then(onFulfilled, onRejected);

    builder.catch = (onRejected: (v: unknown) => unknown): Promise<unknown> =>
      Promise.resolve(resolveTerminal(false)).catch(onRejected);

    return builder;
  }

  return root;
}
