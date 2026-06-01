/**
 * lib/supabase/admin.ts
 *
 * Supabase client using the service_role key (bypasses RLS).
 *
 * Usage restrictions:
 *   - STEP 3 workers (consultation-worker, draft-expiry-worker, mail-merge-worker)
 *   - auth callbacks (e.g. INSERT an app.users row right after user creation)
 *   - webhook handlers (external system -> our DB)
 *   - never use in a regular Server Action (risk of bypassing user permissions)
 *
 * Caller responsibilities:
 *   - do not trust external input; explicitly include organization_id in the WHERE
 *   - all changes written with this client are recorded in audit.change_log, but
 *     changed_by becomes NULL so tracing is hard -> supplement with trace_label, etc.
 */

import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';
import { env } from '@/lib/env';

// Stage 28-a: changed the schema generic to 'app' (matches server.ts/client.ts).
type SupabaseAdminDb = ReturnType<typeof createClient<Database, 'app'>>;

/** Stage 28-a: exported so the caller can add a type annotation. */
export type SbAdminClient = SupabaseAdminDb;

let adminClient: SupabaseAdminDb | null = null;

export function createSupabaseAdminClient(): SupabaseAdminDb {
  if (adminClient) return adminClient;

  adminClient = createClient<Database, 'app'>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false,
      },
    },
  );
  return adminClient;
}
