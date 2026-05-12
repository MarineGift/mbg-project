/**
 * middleware.ts
 *
 * 모든 요청을 가로채 Supabase 세션을 갱신하고 보호 경로 인증을 확인.
 *
 * 본 파일은 src/ 바깥 (프로젝트 루트)에 위치해야 Next.js가 인식.
 */

import type { NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';

export async function middleware(request: NextRequest) {
  return updateSession(request);
}

export const config = {
  matcher: [
    /*
     * 다음을 제외한 모든 요청에 적용:
     *   - _next/static (정적 파일)
     *   - _next/image (이미지 최적화)
     *   - favicon.ico, robots.txt, sitemap.xml
     *   - 확장자가 있는 파일 (이미지, 폰트 등)
     * 단, /api/는 포함 → API route도 인증 검증
     */
    '/((?!_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml|.*\\..*).*)',
  ],
};
