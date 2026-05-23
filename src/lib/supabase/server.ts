/**
 * lib/supabase/server.ts
 *
 * Server Component·Server Action·Route Handler에서 사용하는 Supabase 클라이언트.
 *
 * 핵심:
 *   - cookies()로 JWT 세션 읽기·갱신
 *   - 매 요청마다 새 인스턴스 (long-lived 캐싱 금지)
 *   - JWT의 app_metadata.organization_id가 자동으로 RLS에 적용됨
 *     (013 마이그레이션의 custom_access_token_hook이 주입)
 */

import { createServerClient, type CookieOptions } from '@supabase/ssr';
import type { SupabaseClient } from '@supabase/supabase-js';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';
import { env } from '@/lib/env';

/**
 * setAll 콜백의 매개변수 타입 — @supabase/ssr 0.5의 인라인 형태와 일치.
 */
type CookieToSet = { name: string; value: string; options?: CookieOptions };

/**
 * Stage 28-a: factory의 schema generic을 'app'으로 변경.
 *
 * 배경 / Gotcha #45 (Session 11에서 발견):
 *   @supabase/ssr 0.5.x 의 createServerClient<Database, SchemaName, Schema> 는
 *   반환 타입에서 generic 위치가 어긋남 — SupabaseClient v2.x 의 2번째 generic 은
 *   SchemaNameOrClientOptions (string | {PostgrestVersion}), 3번째가 실제 SchemaName.
 *   createServerClient 가 SupabaseClient<Database, SchemaName, Schema> 로 반환하면
 *   3번째 슬롯에 Schema 객체가 들어가버려, 클래스 내부에서 Schema 계산이 never 로 떨어짐.
 *   결과: caller 의 .from("parties") 가 row type = never.
 *
 * Workaround: SbClient 를 SupabaseClient<Database, 'app'> 로 직접 선언 (단일 generic).
 *   클래스 내부에서 SchemaName='app' default 가 'app' 으로 풀리고, Schema 가 Database['app']
 *   로 정상 계산. factory return 은 unknown 경유 cast (런타임 동작은 동일).
 *
 * - app schema: parties / communications / email_* / contacts / org_members / ...
 * - public: RPC functions only
 * - 다른 schema (ai / audit / urm) 접근은 caller 가 .schema('xxx') 명시
 */
export type SbClient = SupabaseClient<Database, 'app'>;

/**
 * Server Component에서 사용. 읽기 전용 권장(쿠키 set이 layout/page 외부에서는 동작 안 함).
 * Server Action·Route Handler에서는 자유롭게 set 가능.
 */
export async function createSupabaseServerClient(): Promise<SbClient> {
  const cookieStore = await cookies();

  // ssr 의 generic 어긋남 이슈 (위 주석 참조) 때문에 cast 1회.
  // 런타임은 동일하게 'app' schema 로 동작.
  const client = createServerClient<Database, 'app'>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options);
            });
          } catch {
            // Server Component context에서 set 호출 시 throw — 무시.
            // (middleware가 세션 갱신을 담당)
          }
        },
      },
    },
  );
  return client as unknown as SbClient;
}
