/**
 * lib/supabase/client.ts
 *
 * Supabase client used in Client Components ('use client').
 *
 * Key points:
 *   - singleton (one per browser memory)
 *   - used for Realtime channel subscriptions, live toasts, etc.
 *   - prefer Server Actions for writes (prevents RLS-bypass risk)
 */

'use client';

import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database';

// Stage 28-a: changed the schema generic to 'app' (matches server.ts).
// Operational tables live in the app schema; public is for RPC functions only.
// The SupabaseClient generic has a different arity depending on the library version ->
// use createBrowserClient's return type as-is (single source of truth).
type SupabaseDb = ReturnType<typeof createBrowserClient<Database, 'app'>>;

/** Stage 28-a: exported so the caller can add a type annotation. */
export type SbBrowserClient = SupabaseDb;

let browserClient: SupabaseDb | null = null;

export function createSupabaseBrowserClient(): SupabaseDb {
  if (browserClient) return browserClient;

  // NEXT_PUBLIC_* variables are inlined into the client bundle, so access process.env directly.
  // (lib/env is for zod validation, but in the client bundle server-only variables would throw)
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY must be set in environment',
    );
  }

  browserClient = createBrowserClient<Database, 'app'>(url, anonKey);
  return browserClient;
}
