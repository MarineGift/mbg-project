'use server';

import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { getServerSupabase } from '@/lib/supabase/server';

/**
 * 이메일/비밀번호 로그인. 성공 시 `next` 경로로 리다이렉트, 실패 시 /login?error=...
 *
 * 본 골격에서는 회원가입(signUp)은 의도적으로 미노출 — 실제 운영 시
 * 조직 관리자가 Supabase Admin API로 invite하는 모델을 권장.
 */
export async function signInWithPassword(formData: FormData): Promise<void> {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');
  const next = sanitizeNext(formData.get('next'));

  if (!email || !password) {
    redirect(`/login?error=${encodeURIComponent('이메일과 비밀번호를 모두 입력하세요')}&next=${encodeURIComponent(next)}`);
  }

  const supabase = await getServerSupabase();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    redirect(`/login?error=${encodeURIComponent(error.message)}&next=${encodeURIComponent(next)}`);
  }

  revalidatePath('/', 'layout');
  redirect(next);
}

/**
 * 매직 링크 로그인 (선택). Supabase Project Settings > Auth > Email에서
 * email confirm template이 활성화되어 있어야 동작.
 */
export async function signInWithMagicLink(formData: FormData): Promise<void> {
  const email = String(formData.get('email') ?? '').trim();
  const next = sanitizeNext(formData.get('next'));

  if (!email) {
    redirect(`/login?error=${encodeURIComponent('이메일을 입력하세요')}&next=${encodeURIComponent(next)}`);
  }

  const supabase = await getServerSupabase();
  const origin = process.env.NEXT_PUBLIC_SITE_URL ?? '';
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: origin
        ? `${origin}/auth/callback?next=${encodeURIComponent(next)}`
        : undefined,
    },
  });

  if (error) {
    redirect(`/login?error=${encodeURIComponent(error.message)}&next=${encodeURIComponent(next)}`);
  }
  redirect(`/login?info=${encodeURIComponent('매직 링크를 이메일로 전송했습니다')}&next=${encodeURIComponent(next)}`);
}

export async function signOut(): Promise<void> {
  const supabase = await getServerSupabase();
  await supabase.auth.signOut();
  revalidatePath('/', 'layout');
  redirect('/login');
}

function sanitizeNext(raw: FormDataEntryValue | null): string {
  const candidate = typeof raw === 'string' ? raw : '/drafts';
  // open redirect 방지: 외부 URL 금지, 같은 origin 경로만 허용
  if (!candidate.startsWith('/') || candidate.startsWith('//')) return '/drafts';
  return candidate;
}
