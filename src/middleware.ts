import { NextRequest, NextResponse } from 'next/server';

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

export function middleware(req: NextRequest) {
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

  if (isCrmHost(host, req)) {
    return NextResponse.next();
  }

  const slug = siteSlugForHost(host, req);
  const url = req.nextUrl.clone();
  url.pathname = `/site` + (pathname === '/' ? '' : pathname);
  const requestHeaders = new Headers(req.headers);
  requestHeaders.set('x-mbg-site', slug);
  return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|public).*)',
  ],
};