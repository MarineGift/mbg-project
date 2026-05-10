import 'server-only';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';

/**
 * Service-role Supabase 클라이언트. RLS를 우회하므로 다음 경로에서만 사용:
 *  - 인증된 사용자가 아닌 시스템 작업 (cron, webhook receiver, worker)
 *  - 멀티테넌트 경계를 코드 레벨에서 명시적으로 강제하는 곳 (organization_id 항상 명시)
 *
 * 절대 클라이언트 컴포넌트나 미들웨어에서 import하지 말 것.
 */
let cached: SupabaseClient | null = null;

export function getAdminSupabase(): SupabaseClient {
  if (cached) return cached;
  cached = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    global: {
      headers: {
        'X-Client-Info': 'urm-platform-admin',
      },
    },
  });
  return cached;
}
