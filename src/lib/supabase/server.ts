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
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';
import { env } from '@/lib/env';

/**
 * setAll 콜백의 매개변수 타입 — @supabase/ssr 0.5의 인라인 형태와 일치.
 */
type CookieToSet = { name: string; value: string; options?: CookieOptions };

/**
 * Server Component에서 사용. 읽기 전용 권장(쿠키 set이 layout/page 외부에서는 동작 안 함).
 * Server Action·Route Handler에서는 자유롭게 set 가능.
 */
export async function createSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient<Database, 'public'>(
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
}
