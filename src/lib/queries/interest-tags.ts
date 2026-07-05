/**
 * lib/queries/interest-tags.ts
 *
 * Canonical interest-tag options (app.interest_tags) for the Party form
 * TagMultiSelect. Global lookup, catalogue sort_order, mirrors
 * lib/queries/investor-types.ts.
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { TagOption } from '@/components/parties/tag-multi-select';

export async function fetchInterestTagOptions(): Promise<TagOption[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('interest_tags' as never)
    .select('code, label_en, label_ko, sort_order')
    .order('sort_order' as never, { ascending: true });

  if (error || !data) return [];

  return (
    data as Array<{ code: string; label_en: string | null; label_ko: string | null }>
  )
    .filter((r) => !!r.code)
    .map((r) => ({
      code: r.code,
      // English-only label (user request: no Korean in the picker)
      label: r.label_en ?? r.code,
    }));
}
