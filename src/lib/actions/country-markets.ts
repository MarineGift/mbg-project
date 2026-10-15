'use server';

/**
 * lib/actions/country-markets.ts
 *
 * Report links on app.country_markets.report_links - jsonb array of
 * { label, url, added_at }. Used by the Market tab to open the source
 * analysis (e.g. a ChatGPT shared conversation) for the country.
 */

import { revalidatePath } from 'next/cache';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface ReportLink {
  label: string;
  url: string;
  added_at?: string;
}

export interface LinkActionResult {
  ok: boolean;
  error?: string;
  links?: ReportLink[];
}

function cleanCode(code: string) {
  return (code ?? '').trim().toUpperCase();
}

async function readLinks(code: string) {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('country_markets' as never)
    .select('id, report_links')
    .eq('country_code' as never, code)
    .is('deleted_at' as never, null)
    .maybeSingle();
  const row = data as unknown as { id: string; report_links: ReportLink[] | null } | null;
  return { supabase, row, error };
}

export async function addCountryMarketLink(
  countryCode: string,
  label: string,
  url: string,
  revalidate?: string,
): Promise<LinkActionResult> {
  try {
    await requireAuth();
  } catch {
    return { ok: false, error: 'Not signed in' };
  }
  const code = cleanCode(countryCode);
  const u = (url ?? '').trim();
  if (!/^https:\/\/\S+$/i.test(u)) return { ok: false, error: 'URL must start with https://' };
  const l = (label ?? '').trim() || 'ChatGPT analysis';

  const { supabase, row, error } = await readLinks(code);
  if (error) return { ok: false, error: error.message };
  if (!row) return { ok: false, error: `No country market row for ${code}` };

  const links = Array.isArray(row.report_links) ? row.report_links : [];
  if (links.some((x) => x.url === u)) return { ok: false, error: 'This link is already saved' };
  const next = [...links, { label: l.slice(0, 120), url: u, added_at: new Date().toISOString().slice(0, 10) }];

  const { error: upErr } = await supabase
    .schema('app')
    .from('country_markets' as never)
    .update({ report_links: next } as never)
    .eq('id' as never, row.id);
  if (upErr) return { ok: false, error: upErr.message };

  if (revalidate) revalidatePath(revalidate);
  return { ok: true, links: next };
}

export async function removeCountryMarketLink(
  countryCode: string,
  url: string,
  revalidate?: string,
): Promise<LinkActionResult> {
  try {
    await requireAuth();
  } catch {
    return { ok: false, error: 'Not signed in' };
  }
  const code = cleanCode(countryCode);
  const { supabase, row, error } = await readLinks(code);
  if (error) return { ok: false, error: error.message };
  if (!row) return { ok: false, error: `No country market row for ${code}` };

  const links = (Array.isArray(row.report_links) ? row.report_links : []).filter((x) => x.url !== url);
  const { error: upErr } = await supabase
    .schema('app')
    .from('country_markets' as never)
    .update({ report_links: links } as never)
    .eq('id' as never, row.id);
  if (upErr) return { ok: false, error: upErr.message };

  if (revalidate) revalidatePath(revalidate);
  return { ok: true, links };
}
