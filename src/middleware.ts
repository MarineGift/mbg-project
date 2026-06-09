// src/middleware.ts
// Host-based routing. The CRM keeps its existing routes on the urm host.
// Every other (public) host is rewritten into the /site/* tenant renderer,
// so one deployment serves the CRM and all marketing sites.

import { NextResponse, type NextRequest } from 'next/server';

// Hosts that should keep using the existing CRM app as-is.
const CRM_HOSTS = new Set<string>([
  'urm.marinebiogroup.com',
]);

function isCrmHost(host: string): boolean {
  const h = host.toLowerCase().split(':')[0] ?? '';
  if (CRM_HOSTS.has(h)) return true;
  // local dev: treat localhost as CRM unless ?site= is used
  if (h === 'localhost' || h === '127.0.0.1') return true;
  return false;
}

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const host = req.headers.get('host') ?? '';

  // never touch framework/asset/api paths or the renderer itself
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/site') ||
    pathname.startsWith('/admin') ||
    pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  if (isCrmHost(host)) {
    // dev convenience: ?site=marinepad previews a tenant on localhost
    const slug = req.nextUrl.searchParams.get('site');
    if (slug) {
      const url = req.nextUrl.clone();
      url.pathname = `/site${pathname === '/' ? '' : pathname}`;
      const requestHeaders = new Headers(req.headers);
      requestHeaders.set('x-mbg-site', slug);
      return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
    }
    return NextResponse.next();
  }

  // public marketing host -> tenant renderer
  const url = req.nextUrl.clone();
  url.pathname = `/site${pathname === '/' ? '' : pathname}`;
  return NextResponse.rewrite(url);
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
