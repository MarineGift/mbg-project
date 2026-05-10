import { NextResponse, type NextRequest } from 'next/server';
import { createServerClient, type CookieOptions } from '@supabase/ssr';

/**
 * 미들웨어는 모든 요청에서 Supabase 세션 쿠키를 새로고침한다.
 * - /api/webhooks/* : 인증 미사용 (서명 헤더로 별도 검증)
 * - /api/cron/*     : 인증 미사용 (CRON_SECRET 헤더로 별도 검증)
 * - 그 외          : Supabase 세션 필수 → 미인증 시 /login으로 리다이렉트 (login 페이지는 별도 구현 시)
 */
export async function middleware(request: NextRequest) {
  const response = NextResponse.next({
    request: { headers: request.headers },
  });

  // 인증 우회 경로
  const path = request.nextUrl.pathname;
  if (
    path.startsWith('/api/webhooks/')
    || path.startsWith('/api/cron/')
    || path.startsWith('/api/health')
    || path.startsWith('/_next/')
    || path === '/favicon.ico'
    || path === '/login'
    || path === '/'
  ) {
    return response;
  }

  // env에서 직접 읽음 — middleware는 Edge runtime이라 서버 모듈 import 제약 있음
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseAnonKey) {
    // 환경변수 미설정 시 미들웨어를 통과시키되 경고. (env.ts가 production에서 차단할 것)
    return response;
  }

  const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet: Array<{ name: string; value: string; options: CookieOptions }>) {
        cookiesToSet.forEach(({ name, value }) => {
          request.cookies.set(name, value);
        });
        cookiesToSet.forEach(({ name, value, options }) => {
          response.cookies.set(name, value, options);
        });
      },
    },
  });

  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    if (path.startsWith('/api/')) {
      return new NextResponse(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    const loginUrl = request.nextUrl.clone();
    loginUrl.pathname = '/login';
    loginUrl.searchParams.set('next', path);
    return NextResponse.redirect(loginUrl);
  }

  return response;
}

export const config = {
  // 정적 자산은 미들웨어 통과 안 함 (성능)
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
