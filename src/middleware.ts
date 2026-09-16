import { NextRequest, NextResponse } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';

// Readdy-migrated marketing pages (served from src/app/(marketing)/...).
// These pass through on every host so they work on www/apex domains
// and remain reachable on the CRM host for testing.
const MARKETING_PATHS = ['/home', '/paper-filler', '/videos'];

function isCrmHost(host: string, req: NextRequest): boolean {
  const h = host.split(':')[0] ?? '';
  if (h.startsWith('urm.')) return true;
  if (h === 'localhost' || h === '127.0.0.1') {
    return !req.nextUrl.searchParams.get('site');
  }
  return false;
}

function siteSlugForHost(host: string, req: NextRequest): string {
  const h = host.split(':')[0] ?? '';
  if (h === 'localhost' || h === '127.0.0.1') {
    return req.nextUrl.searchParams.get('site') || 'marinebiogroup';
  }
  return h || 'marinebiogroup';
}

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const host = req.headers.get('host') ?? '';

  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/site') ||
    pathname.startsWith('/login') ||
    pathname.startsWith('/auth') ||
    pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  if (pathname === '/admin' || pathname.startsWith('/admin/')) {
    return NextResponse.next();
  }

  // Marketing (readdy) pages: always pass through, on any host.
  if (
    MARKETING_PATHS.some(
      (p) => pathname === p || pathname.startsWith(p + '/')
    )
  ) {
    return NextResponse.next();
  }

  if (isCrmHost(host, req)) {
    // 2026-09-16: refresh the Supabase session cookie here. The root middleware.ts
    // (which did this) is ignored because src/middleware.ts takes precedence, so
    // server-side queries ran as anon once the access token expired (42501 on parties).
    return updateSession(req);
  }

  // Non-CRM hosts (www.marinebiogroup.com, marinebiogroup.com, marinebio.kr):
  // root now serves the readdy homepage instead of the /site CMS.
  if (pathname === '/') {
    const url = req.nextUrl.clone();
    url.pathname = '/home';
    return NextResponse.rewrite(url);
  }

  // All other paths on marketing hosts keep the legacy /site CMS rewrite
  // (e.g. /shop, CMS pages) so nothing existing breaks.
  const slug = siteSlugForHost(host, req);
  const url = req.nextUrl.clone();
  url.pathname = `/site` + pathname;
  const requestHeaders = new Headers(req.headers);
  requestHeaders.set('x-mbg-site', slug);
  return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|public).*)',
  ],
};
