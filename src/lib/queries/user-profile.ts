/**
 * lib/queries/user-profile.ts
 *
 * 현재 로그인 사용자의 프로필 조회.
 * app.users 행 + organization 정보.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { requireAuth } from '@/lib/auth';
import type { Locale } from '@/i18n/routing';

export interface UserProfile {
  id: string;
  email: string;
  fullName: string;
  displayName: string | null;
  sendingEmail: string | null;
  preferredLanguage: Locale;
  isOwner: boolean;
  organizationId: string;
  organizationName: string;
  createdAt: string;
}

export async function fetchCurrentUserProfile(): Promise<UserProfile | null> {
  const auth = await requireAuth();
  const supabase = await createSupabaseServerClient();

  const [userRes, orgRes] = await Promise.all([
    supabase
      .schema('app')
      .from('users' as never)
      .select(
        'id, email, full_name, display_name, sending_email, preferred_language, created_at',
      )
      .eq('id', auth.userId)
      .maybeSingle(),

    supabase
      .schema('app')
      .from('organizations' as never)
      .select('id, name')
      .eq('id', auth.organizationId)
      .maybeSingle(),
  ]);

  if (userRes.error || !userRes.data) return null;
  const u = userRes.data as {
    id: string;
    email: string;
    full_name: string;
    display_name: string | null;
    sending_email: string | null;
    preferred_language: string | null;
    created_at: string;
  };

  const org = orgRes.data as { id: string; name: string } | null;

  const lang: Locale =
    u.preferred_language === 'ko' ||
    u.preferred_language === 'en' ||
    u.preferred_language === 'ja'
      ? (u.preferred_language as Locale)
      : 'ko';

  return {
    id: u.id,
    email: u.email,
    fullName: u.full_name,
    displayName: u.display_name,
    sendingEmail: u.sending_email,
    preferredLanguage: lang,
    isOwner: auth.isOwner,
    organizationId: auth.organizationId,
    organizationName: org?.name ?? '(unknown)',
    createdAt: u.created_at,
  };
}
