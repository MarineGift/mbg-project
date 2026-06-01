/**
 * lib/actions/auth.ts
 *
 * Authentication-related Server Actions.
 *
 * Important: organization_id validation decodes session.access_token (JWT) directly.
 *       data.user.app_metadata returns the DB's raw_app_meta_data, so it
 *       does not see the organization_id injected by the hook.
 */

'use server';

import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface SignInResult {
  ok: boolean;
  errorCode?:
    | 'invalid_credentials'
    | 'no_organization'
    | 'rate_limited'
    | 'unknown';
  errorMessage?: string;
}

const signInSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  next: z.string().optional(),
});

/**
 * base64url-decode the JWT payload.
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
    return JSON.parse(Buffer.from(padded, 'base64').toString('utf-8'));
  } catch {
    return null;
  }
}

export async function signInWithPassword(input: {
  email: string;
  password: string;
  next?: string;
}): Promise<SignInResult> {
  const parsed = signInSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'invalid_credentials',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  const { data, error } = await supabase.auth.signInWithPassword({
    email: parsed.data.email,
    password: parsed.data.password,
  });

  if (error) {
    const isCredError =
      error.message.includes('Invalid login credentials') ||
      error.message.includes('Email not confirmed');
    return {
      ok: false,
      errorCode: isCredError ? 'invalid_credentials' : 'unknown',
      errorMessage: error.message,
    };
  }

  // decode the JWT directly - the hook-injected app_metadata is here
  // data.user.app_metadata is the DB's raw_app_meta_data, so the hook result is not visible
  const accessToken = data.session?.access_token;
  let orgId: string | undefined;
  if (accessToken) {
    const payload = decodeJwtPayload(accessToken);
    const meta = payload?.app_metadata as Record<string, unknown> | undefined;
    if (typeof meta?.organization_id === 'string') {
      orgId = meta.organization_id;
    }
  }

  if (!orgId) {
    return {
      ok: false,
      errorCode: 'no_organization',
      errorMessage:
        'Account is not assigned to an organization. Contact your administrator.',
    };
  }

  const safeNext = sanitizeNextPath(parsed.data.next);
  revalidatePath('/', 'layout');
  redirect(safeNext);
}

export async function signOut(): Promise<void> {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();
  revalidatePath('/', 'layout');
  redirect('/login');
}

function sanitizeNextPath(next: string | undefined): string {
  if (!next) return '/';
  if (
    next.startsWith('http://') ||
    next.startsWith('https://') ||
    next.startsWith('//') ||
    next.includes('\\')
  ) {
    return '/';
  }
  if (!next.startsWith('/')) {
    return '/';
  }
  return next;
}