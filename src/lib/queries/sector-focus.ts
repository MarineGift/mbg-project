/**
 * lib/queries/sector-focus.ts
 *
 * Canonical sector options (app.sectors) for the Party form Sector focus
 * TagMultiSelect. Global lookup, catalogue sort_order. Mirrors
 * lib/queries/interest-tags.ts so the Sector focus picker behaves exactly like
 * the Interest Tags picker (checkbox multi-select + Add-new).
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { TagOption } from '@/components/parties/tag-multi-select';

export async function fetchSectorOptions(): Promise<TagOption[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('sectors' as never)
    .select('code, label_en, sort_order')
    .order('sort_order' as never, { ascending: true });

  if (error || !data) return [];

  return (data as Array<{ code: string; label_en: string | null }>)
    .filter((r) => !!r.code)
    .map((r) => ({ code: r.code, label: r.label_en ?? r.code }));
}
