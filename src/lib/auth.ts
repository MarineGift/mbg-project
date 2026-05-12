/**
 * lib/auth.ts
 *
 * Server Component·Server Action·Route Handler에서 사용하는 인증 헬퍼.
 *
 * 중요: app_metadata는 JWT에 hook이 주입한 것을 직접 디코드해서 사용한다.
 *       supabase.auth.getUser()는 DB의 raw_app_meta_data를 반환하므로
 *       hook이 주입한 organization_id를 못 본다.
 */

import 'server-only';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { normalizeLocale, type Locale } from '@/i18n/routing';

export interface AuthContext {
  userId: string;
  organizationId: string;
  isOwner: boolean;
  preferredLanguage: Locale;
  email: string;
}

export class AuthError extends Error {
  constructor(
    message: string,
    public readonly code: 'no_session' | 'no_organization' | 'invalid_jwt',
  ) {
    super(message);
    this.name = 'AuthError';
  }
}

/**
 * JWT의 payload 부분을 디코드. JWT 형식: header.payload.signature
 */
function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
    const decoded = Buffer.from(padded, 'base64').toString('utf-8');
    return JSON.parse(decoded) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export async function getCurrentAuth(): Promise<AuthContext | null> {
  const supabase = await createSupabaseServerClient();

  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session?.access_token) return null;

  const payload = decodeJwtPayload(session.access_token);
  if (!payload) return null;

  const userId = typeof payload.sub === 'string' ? payload.sub : null;
  const email = typeof payload.email === 'string' ? payload.email : '';
  if (!userId) return null;

  const appMetadata = (payload.app_metadata ?? {}) as Record<string, unknown>;
  const organizationId =
    typeof appMetadata.organization_id === 'string'
      ? appMetadata.organization_id
      : null;

  if (!organizationId) return null;

  const isOwner =
    typeof appMetadata.is_owner === 'boolean' ? appMetadata.is_owner : false;
  const preferredLanguage = normalizeLocale(
    typeof appMetadata.preferred_language === 'string'
      ? appMetadata.preferred_language
      : null,
  );

  return {
    userId,
    organizationId,
    isOwner,
    preferredLanguage,
    email,
  };
}

export async function requireAuth(): Promise<AuthContext> {
  const ctx = await getCurrentAuth();
  if (!ctx) {
    throw new AuthError('Authentication required', 'no_session');
  }
  return ctx;
}

export async function requireAuthOrRedirect(
  redirectPath = '/login',
): Promise<AuthContext> {
  const ctx = await getCurrentAuth();
  if (!ctx) {
    redirect(redirectPath);
  }
  return ctx;
}