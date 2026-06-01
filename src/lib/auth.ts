/**
 * lib/auth.ts
 *
 * Auth helper used in Server Components, Server Actions, and Route Handlers.
 *
 * Important: app_metadata is used by decoding what the hook injected into the JWT directly.
 *       supabase.auth.getUser() returns the DB's raw_app_meta_data, so it
 *       does not see the organization_id injected by the hook.
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
 * Decode the payload part of the JWT. JWT format: header.payload.signature
 */
function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    if (!parts[1]) {
      throw new Error('Invalid JWT format: missing payload section');
    }
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