/**
 * lib/supabase/admin.ts
 *
 * service_role 키를 사용하는 Supabase 클라이언트 (RLS 우회).
 *
 * 사용 제한:
 *   - STEP 3 워커 (consultation-worker, draft-expiry-worker, mail-merge-worker)
 *   - 인증 콜백 (사용자 생성 직후 app.users 행 INSERT 등)
 *   - 웹훅 핸들러 (외부 시스템 → 우리 DB)
 *   - 절대 일반 Server Action에서 사용 금지 (사용자 권한 우회 위험)
 *
 * 호출자 책임:
 *   - 외부 입력을 신뢰하지 않고 명시적으로 organization_id를 WHERE에 포함
 *   - 본 클라이언트로 쓴 모든 변경은 audit.change_log에 기록되지만
 *     changed_by가 NULL이 되므로 트레이싱 어려움 → trace_label 등으로 보완
 */

import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';
import { env } from '@/lib/env';

type SupabaseAdminDb = ReturnType<typeof createClient<Database, 'public'>>;

let adminClient: SupabaseAdminDb | null = null;

export function createSupabaseAdminClient(): SupabaseAdminDb {
  if (adminClient) return adminClient;

  adminClient = createClient<Database, 'public'>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    },
  );
  return adminClient;
}
