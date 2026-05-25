/**
 * lib/queries/saved-views.ts
 *
 * User-saved filter/view presets per entity type and module.
 */
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { PartyTypeCode } from '@/types/ai';

export interface SavedView {
  id: string;
  name: string;
  entity_type: string;
  module: PartyTypeCode;
  filters: Record<string, unknown>;
  is_default?: boolean;
  created_at?: string;
}

export async function fetchSavedViews(
  entityType: string,
  module: PartyTypeCode,
): Promise<SavedView[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('saved_views' as never)
    .select('*')
    .eq('entity_type' as never, entityType)
    .eq('module' as never, module)
    .order('name');

  if (error) {
    console.warn('[fetchSavedViews] error:', error.message);
    return [];
  }
  return ((data ?? []) as any[]) as SavedView[];
}