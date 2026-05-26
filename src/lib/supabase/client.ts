/**
 * lib/supabase/client.ts
 *
 * Client Component('use client')에서 사용하는 Supabase 클라이언트.
 *
 * 핵심:
 *   - 싱글톤 (브라우저 메모리에 1개)
 *   - Realtime 채널 구독, 실시간 토스트 등에 사용
 *   - 쓰기는 Server Action 사용 권장 (RLS 우회 위험 차단)
 */

'use client';

import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database';

// Stage 28-a: schema generic을 'app'으로 변경 (server.ts와 일치).
// 운영 테이블은 app schema 거주, public은 RPC functions 전용.
// SupabaseClient 제네릭은 라이브러리 버전에 따라 인자 수가 다름 →
// createBrowserClient의 반환 타입을 그대로 사용 (single source of truth).
type SupabaseDb = ReturnType<typeof createBrowserClient<Database, 'app'>>;

/** Stage 28-a: caller가 type annotation 가능하도록 export. */
export type SbBrowserClient = SupabaseDb;

let browserClient: SupabaseDb | null = null;

export function createSupabaseBrowserClient(): SupabaseDb {
  if (browserClient) return browserClient;

  // NEXT_PUBLIC_* 변수는 client bundle에 인라인되므로 process.env 직접 접근.
  // (lib/env는 zod 검증을 위한 것이지만 client bundle에선 server-only 변수가 throw)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY must be set in environment',
    );
  }

  browserClient = createBrowserClient<Database, 'app'>(url, anonKey);
  return browserClient;
}
