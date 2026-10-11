'use server';

/**
 * lib/actions/countries.ts
 *
 * listCountryNames -- the app.countries map (code -> name_en) for client
 * components that have no server parent to pass it down (dialogs, settings).
 * Same source as fetchCountryNames, so every country control in URM shows the
 * same names.
 */

import { requireAuth } from '@/lib/auth';
import { fetchCountryNames } from '@/lib/queries/countries';

export async function listCountryNames(): Promise<Record<string, string>> {
  try {
    await requireAuth();
  } catch {
    return {};
  }
  return fetchCountryNames();
}
