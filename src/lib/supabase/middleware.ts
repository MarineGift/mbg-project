/**
 * lib/supabase/middleware.ts
 *
 * Helper that refreshes the Supabase session in Next.js middleware.
 *
 * Key points:
 *   - calls supabase.auth.getUser() on every request -> auto-refreshes the token just before expiry
 *   - sets the refreshed cookie directly on the response (Server Components can't write cookies)
 *   - redirects unauthenticated users from protected routes to /login
 */

import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import type { Database } from '@/types/database';

/**
 * Parameter type of the setAll callback.
 */
type CookieToSet = { name: string; value: string; options?: CookieOptions };

/**
 * Unprotected paths (no auth required).
 * All other paths require auth -> unauthenticated users are redirected to /login.
 */
const PUBLIC_PATHS: readonly string[] = [
  '/login',
  '/auth/callback',
  '/auth/error',
];

/**
 * Static assets / internal paths - the middleware does not touch them at all.
 * Primarily excluded by the matcher, but reinforced here.
 */
function isInternalPath(pathname: string): boolean {
  return (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/api/') ||
    pathname.startsWith('/favicon') ||
    pathname.includes('.') // files with an extension
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

  // internal paths pass through unchanged
  if (isInternalPath(pathname)) {
    return NextResponse.next({ request });
  }

  let response = NextResponse.next({ request });

  // use process.env instead of accessing env directly (middleware runs on the edge runtime,
  // lib/env's zod validation can fail on some server-only variables)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    // missing env vars can only happen in an unconfigured dev environment; block safely if it does
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
        // set the same on the response - refreshes the client cookie
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options),
        );
      },
    },
  });

  // getUser() is the key - it validates the token internally + refreshes if needed
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // an unauthenticated user accessing a protected path -> redirect to /login
  if (!user && !isPublicPath(pathname)) {
    const loginUrl = new URL('/login', request.url);
    // preserve the query so the user returns to their intended path after login
    loginUrl.searchParams.set('next', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // an authenticated user accessing /login etc. -> redirect to /
  if (user && pathname === '/login') {
    return NextResponse.redirect(new URL('/', request.url));
  }

  return response;
}
