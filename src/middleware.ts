import { NextRequest, NextResponse } from 'next/server';

function isCrmHost(host: string): boolean {
  return host.startsWith('localhost') || host.startsWith('127.0.0.1') || host.includes('urm.');
}

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const host = req.headers.get('host') ?? '';

  // Framework paths
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/site') ||
    pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  // /admin -> CRM
  if (pathname.startsWith('/admin')) {
    const url = req.nextUrl.clone();
    const requestHeaders = new Headers(req.headers);
    requestHeaders.set('x-mbg-site', 'crm');
    return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
  }

  // localhost -> marinebiogroup site
  if (isCrmHost(host)) {
    const slug = req.nextUrl.searchParams.get('site') || 'marinebiogroup';
    const url = req.nextUrl.clone();
    url.pathname = /site$((pathname === '/' ? '' : pathname));
    const requestHeaders = new Headers(req.headers);
    requestHeaders.set('x-mbg-site', slug);
    return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
  }

  // public host -> site renderer
  const url = req.nextUrl.clone();
  url.pathname = /site$((pathname === '/' ? '' : pathname));
  const requestHeaders = new Headers(req.headers);
  requestHeaders.set('x-mbg-site', host.split(':')[0]);
  return NextResponse.rewrite(url, { request: { headers: requestHeaders } });
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|public).*)',
  ],
};