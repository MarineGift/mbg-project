/**
 * lib/supabase/middleware.ts
 *
 * Next.js middleware에서 Supabase 세션을 갱신하는 헬퍼.
 *
 * 핵심:
 *   - 매 요청마다 supabase.auth.getUser() 호출 → 만료 직전 토큰 자동 갱신
 *   - 갱신된 cookie를 응답에 직접 설정 (Server Component는 cookie 쓰기 불가)
 *   - 인증되지 않은 사용자를 보호 라우트에서 /login으로 리다이렉트
 */

import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import type { Database } from '@/types/database';

/**
 * setAll 콜백 매개변수 타입.
 */
type CookieToSet = { name: string; value: string; options?: CookieOptions };

/**
 * 보호되지 않는 경로 (인증 불필요).
 * 그 외 모든 경로는 인증 필요 → 미인증 시 /login으로 리다이렉트.
 */
const PUBLIC_PATHS: readonly string[] = [
  '/login',
  '/auth/callback',
  '/auth/error',
];

/**
 * 정적 자산·내부 경로 — middleware가 일체 관여하지 않음.
 * matcher에서 1차 제외하지만 보강.
 */
function isInternalPath(pathname: string): boolean {
  return (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/api/') ||
    pathname.startsWith('/favicon') ||
    pathname.includes('.') // 확장자 있는 파일
  );
}

function isPublicPath(pathname: string): boolean {
  return PUBLIC_PATHS.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`),
  );
}

export async function updateSession(
  request: NextRequest,
): Promise<NextResponse> {
  const pathname = request.nextUrl.pathname;

  // 내부 경로는 그대로 통과
  if (isInternalPath(pathname)) {
    return NextResponse.next({ request });
  }

  let response = NextResponse.next({ request });

  // env에 직접 접근하지 않고 process.env 사용 (middleware는 edge runtime,
  // lib/env의 zod 검증은 일부 server-only 변수에서 실패할 수 있음)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    // 환경변수 누락은 dev 환경 미설정 이외 발생할 수 없으나, 발생 시 안전 차단
    return NextResponse.redirect(new URL('/auth/error?reason=config', request.url));
  }

  const supabase = createServerClient<Database, 'public'>(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet: CookieToSet[]) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value),
        );
        // 응답에도 동일하게 set — 클라이언트 cookie 갱신
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options),
        );
      },
    },
  });

  // getUser()가 핵심 — 내부적으로 토큰 검증 + 필요 시 refresh
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // 인증되지 않은 사용자가 보호 경로에 접근 → /login 리다이렉트
  if (!user && !isPublicPath(pathname)) {
    const loginUrl = new URL('/login', request.url);
    // 로그인 후 원래 가려던 경로로 복귀하도록 query 보존
    loginUrl.searchParams.set('next', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // 인증된 사용자가 /login 등 접근 → /로 리다이렉트
  if (user && pathname === '/login') {
    return NextResponse.redirect(new URL('/', request.url));
  }

  return response;
}
