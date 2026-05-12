/**
 * lib/actions/auth.ts
 *
 * 인증 관련 Server Actions.
 *
 * 중요: organization_id 검증은 session.access_token (JWT)을 직접 디코드한다.
 *       data.user.app_metadata는 DB의 raw_app_meta_data를 반환하므로
 *       hook이 주입한 organization_id를 못 본다.
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
 * JWT의 payload를 base64url 디코드.
 */
function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
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

  // JWT를 직접 디코드 — hook이 주입한 app_metadata가 여기 있음
  // data.user.app_metadata는 DB의 raw_app_meta_data라서 hook 결과 안 보임
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