/**
 * app/auth/callback/route.ts
 *
 * Supabase Auth callback — magic link, OAuth provider 응답 처리.
 * Phase 1은 이메일/비밀번호만 사용하지만 향후 확장 대비 endpoint 준비.
 *
 * 흐름:
 *   1. Supabase 로그인 화면 또는 OAuth provider → /auth/callback?code=...
 *   2. 본 핸들러가 code → session 교환
 *   3. 성공 시 next param의 경로(또는 /)로 redirect
 */

import { NextResponse, type NextRequest } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code');
  const next = sanitizeNextPath(searchParams.get('next'));

  if (!code) {
    return NextResponse.redirect(new URL('/auth/error?reason=missing_code', request.url));
  }

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(
      new URL(`/auth/error?reason=exchange_failed&message=${encodeURIComponent(error.message)}`, request.url),
    );
  }

  return NextResponse.redirect(new URL(next, request.url));
}

function sanitizeNextPath(next: string | null): string {
  if (!next) return '/';
  if (
    next.startsWith('http://') ||
    next.startsWith('https://') ||
    next.startsWith('//') ||
    next.includes('\\')
  ) {
    return '/';
  }
  if (!next.startsWith('/')) return '/';
  return next;
}
