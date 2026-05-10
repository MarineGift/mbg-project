import { NextResponse, type NextRequest } from 'next/server';
import { getServerSupabase } from '@/lib/supabase/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * GET /auth/callback?code=...&next=...
 *
 * 매직 링크 또는 OAuth 콜백에서 사용. Supabase가 이메일에 포함시키는
 * `code` 파라미터를 세션 쿠키로 교환한다.
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  const { searchParams, origin } = request.nextUrl;
  const code = searchParams.get('code');
  const nextRaw = searchParams.get('next') ?? '/drafts';
  const next = nextRaw.startsWith('/') && !nextRaw.startsWith('//') ? nextRaw : '/drafts';

  if (!code) {
    return NextResponse.redirect(
      `${origin}/login?error=${encodeURIComponent('인증 코드가 없습니다')}`,
    );
  }

  const supabase = await getServerSupabase();
  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(
      `${origin}/login?error=${encodeURIComponent(error.message)}`,
    );
  }

  return NextResponse.redirect(`${origin}${next}`);
}
