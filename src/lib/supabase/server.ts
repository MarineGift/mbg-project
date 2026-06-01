/**
 * lib/supabase/server.ts
 *
 * Supabase client used in Server Components, Server Actions, and Route Handlers.
 *
 * Key points:
 *   - read/refresh the JWT session via cookies()
 *   - a new instance per request (no long-lived caching)
 *   - the JWT's app_metadata.organization_id is applied to RLS automatically
 *     (injected by the custom_access_token_hook from the 013 migration)
 */

import { createServerClient, type CookieOptions } from '@supabase/ssr';
import type { SupabaseClient } from '@supabase/supabase-js';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';
import { env } from '@/lib/env';

/**
 * Parameter type of the setAll callback - matches the inline form in @supabase/ssr 0.5.
 */
type CookieToSet = { name: string; value: string; options?: CookieOptions };

/**
 * Stage 28-a: changed the factory's schema generic to 'app'.
 *
 * Background / Gotcha #45 (found in Session 11):
 *   createServerClient<Database, SchemaName, Schema> in @supabase/ssr 0.5.x has
 *   a misaligned generic position in its return type - the 2nd generic of SupabaseClient v2.x is
 *   SchemaNameOrClientOptions (string | {PostgrestVersion}); the 3rd is the actual SchemaName.
 *   if createServerClient returns SupabaseClient<Database, SchemaName, Schema>,
 *   the Schema object lands in the 3rd slot, and the class's internal Schema computation collapses to never.
 *   Result: the caller's .from("parties") has row type = never.
 *
 * Workaround: declare SbClient directly as SupabaseClient<Database, 'app'> (single generic).
 *   Inside the class, the SchemaName='app' default resolves to 'app', and Schema computes correctly
 *   to Database['app']. The factory return is cast via unknown (runtime behavior is identical).
 *
 * - app schema: parties / communications / email_* / contacts / org_members / ...
 * - public: RPC functions only
 * - to access another schema (ai / audit / urm), the caller specifies .schema('xxx')
 */
export type SbClient = SupabaseClient<Database, 'app'>;

/**
 * Used in Server Components. Read-only recommended (cookie set doesn't work outside layout/page).
 * In Server Actions / Route Handlers, set freely.
 */
export async function createSupabaseServerClient(): Promise<SbClient> {
  const cookieStore = await cookies();

  // one cast due to the ssr generic misalignment issue (see the comment above).
  // runtime still operates on the 'app' schema.
  const client = createServerClient<Database, 'app'>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options);
            });
          } catch {
            // set called in a Server Component context throws - ignore.
            // (middleware handles session refresh)
          }
        },
      },
    },
  );
  return client as unknown as SbClient;
}
