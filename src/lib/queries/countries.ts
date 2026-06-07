/**
 * src/lib/queries/countries.ts
 *
 * Single source of truth for ISO country code -> display name.
 * Data lives in the DB table `app.countries` (code text PK, name_en text),
 * so the UI is no longer driven by a hardcoded map. Seed a new country there
 * and every dropdown / label picks up the full name automatically.
 */
import { createSupabaseServerClient } from '@/lib/supabase/server';

/**
 * Returns a map of `country_code -> name_en` from app.countries.
 * Fails soft: on any error (e.g. table missing) returns {} so callers can
 * fall back to showing the raw code instead of crashing the page.
 */
export async function fetchCountryNames(): Promise<Record<string, string>> {
  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase
      .schema('app')
      .from('countries' as never)
      .select('code, name_en');
    if (error) return {};
    const map: Record<string, string> = {};
    for (const r of ((data ?? []) as any[])) {
      const code = r.code as string | null;
      if (code) map[code] = (r.name_en as string | null) ?? code;
    }
    return map;
  } catch {
    return {};
  }
}
