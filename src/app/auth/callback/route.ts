/**
 * app/auth/callback/route.ts
 *
 * Supabase Auth callback - handles magic link and OAuth provider responses.
 * Phase 1 uses only email/password, but this endpoint is prepared for future expansion.
 *
 * Flow:
 *   1. Supabase login screen or OAuth provider -> /auth/callback?code=...
 *   2. this handler exchanges code -> session
 *   3. on success, redirect to the next param's path (or /)
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
