'use server';

/**
 * lib/actions/country-markets.ts
 *
 * AI analysis links on app.country_markets - one field per provider:
 *   chatgpt_url, claude_url, gemini_url
 * Saved per country, so every mill and filler supplier of that country shows
 * the same links on its Market tab.
 */

import { revalidatePath } from 'next/cache';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export type AiProvider = 'chatgpt' | 'claude' | 'gemini';

const COLUMN: Record<AiProvider, string> = {
  chatgpt: 'chatgpt_url',
  claude: 'claude_url',
  gemini: 'gemini_url',
};

export interface AiLinkResult {
  ok: boolean;
  error?: string;
  url?: string | null;
}

export async function setCountryMarketAiLink(
  countryCode: string,
  provider: AiProvider,
  url: string | null,
  revalidate?: string,
): Promise<AiLinkResult> {
  try {
    await requireAuth();
  } catch {
    return { ok: false, error: 'Not signed in' };
  }
  const col = COLUMN[provider];
  if (!col) return { ok: false, error: 'Unknown provider' };

  const code = (countryCode ?? '').trim().toUpperCase();
  const value = url && url.trim() ? url.trim() : null;
  if (value && !/^https:\/\/\S+$/i.test(value)) return { ok: false, error: 'URL must start with https://' };

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('country_markets' as never)
    .update({ [col]: value } as never)
    .eq('country_code' as never, code)
    .is('deleted_at' as never, null)
    .select('country_code');
  if (error) return { ok: false, error: error.message };
  if (!data || (data as unknown[]).length === 0) return { ok: false, error: `No country market row for ${code}` };

  if (revalidate) revalidatePath(revalidate);
  return { ok: true, url: value };
}
