import 'server-only';
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';

/**
 * Next.js 서버 컴포넌트, 라우트 핸들러, 미들웨어에서 사용하는 user-scoped 클라이언트.
 * 쿠키에서 Supabase 세션을 읽어 RLS를 적용한다.
 *
 * Server Action / Route Handler에서는 cookies()가 readonly가 아니라 set 가능.
 * 단, Server Component에서는 set이 작동하지 않으므로 try/catch로 안전 처리.
 */
export async function getServerSupabase(): Promise<SupabaseClient> {
  const cookieStore = await cookies();

  return createServerClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet: Array<{ name: string; value: string; options: CookieOptions }>) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // Server Component에서 호출되면 set이 막힘 — 무시 (미들웨어가 새로고침 처리)
        }
      },
    },
  });
}

/**
 * 현재 인증된 사용자와 organization_id를 동시에 반환.
 * 인증 실패 시 throw — 호출자는 try/catch로 401 응답을 반환한다.
 */
export async function getUserAndOrg(): Promise<{
  userId: string;
  organizationId: string;
  email: string;
  supabase: SupabaseClient;
}> {
  const supabase = await getServerSupabase();
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    throw new Error('Unauthorized: no Supabase session');
  }

  // user_organizations 또는 직접 user.app_metadata.organization_id 등 — 운영 스키마에 맞게 조정.
  // 본 골격은 user_organizations 테이블을 가정하되, 누락 시 user.app_metadata.organization_id로 fallback.
  const { data: memberRow } = await supabase
    .schema('app')
    .from('user_organizations')
    .select('organization_id')
    .eq('user_id', userData.user.id)
    .eq('is_active', true)
    .maybeSingle();

  const fromMembership = (memberRow as { organization_id?: string } | null)?.organization_id;
  const fromMetadata = (userData.user.app_metadata as { organization_id?: string } | undefined)
    ?.organization_id;
  const organizationId = fromMembership ?? fromMetadata;
  if (!organizationId) {
    throw new Error('Forbidden: no organization membership found for user');
  }

  return {
    userId: userData.user.id,
    organizationId,
    email: userData.user.email ?? '',
    supabase,
  };
}
