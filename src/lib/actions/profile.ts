/**
 * lib/actions/profile.ts
 *
 * User profile Server Actions.
 *   - updateUserProfile: update full_name, display_name, sending_email
 *   - updateUserPreferredLanguage: update preferred_language + cookie sync on the client
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { locales } from '@/i18n/routing';
import type { Locale } from '@/i18n/routing';

export interface ProfileActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'database' | 'not_found';
  errorMessage?: string;
}

const profileSchema = z.object({
  fullName: z.string().min(1, 'Required').max(120),
  displayName: z.string().max(60).optional().nullable(),
  sendingEmail: z
    .string()
    .email()
    .max(255)
    .optional()
    .or(z.literal('').transform(() => undefined))
    .nullable(),
});

export async function updateUserProfile(input: {
  fullName: string;
  displayName?: string | null;
  sendingEmail?: string | null;
}): Promise<ProfileActionResult> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = profileSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const updates: Record<string, unknown> = {
    full_name: parsed.data.fullName,
    display_name: parsed.data.displayName?.trim() || null,
    sending_email: parsed.data.sendingEmail?.trim() || null,
  };

  const { error } = await supabase
    .schema('app')
    .from('users' as never)
    .update(updates as never)
    .eq('id', auth.userId);

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }

  revalidatePath('/', 'layout');
  return { ok: true };
}

const languageSchema = z.object({
  language: z.enum(['ko', 'en', 'ja']),
});

export async function updateUserPreferredLanguage(input: {
  language: Locale;
}): Promise<ProfileActionResult> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = languageSchema.safeParse(input);
  if (!parsed.success || !(locales as readonly string[]).includes(parsed.data.language)) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('users' as never)
    .update({ preferred_language: parsed.data.language } as never)
    .eq('id', auth.userId);

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }

  // the JWT reflects this automatically on the next token refresh (custom_access_token_hook)
  // the cookie is synced immediately on the client
  revalidatePath('/', 'layout');
  return { ok: true };
}
