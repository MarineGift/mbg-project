/**
 * lib/supabase/factories-urm.ts
 *
 * URM schema Supabase client factories (D5-3e2, Stage 29-c cutover).
 *
 * Three factories mirroring the existing app-schema client pattern in
 * admin.ts / client.ts / server.ts, but with schema generic locked to 'urm'.
 *
 * Use cases:
 *   - createUrmAdminClient()    : service_role, RLS bypass (workers, scripts)
 *   - createUrmBrowserClient()  : 'use client' components, singleton, Realtime
 *   - createUrmServerClient()   : Server Component / Server Action / Route Handler,
 *                                 cookies + JWT-based RLS
 *
 * URM tables (use any of these via the helpers below):
 *   parties, party_types, entity_types
 *   contacts, contact_types, contacts_history
 *   investor_profile, paper_mill_profile, filler_supplier_profile
 *   investor_portfolio_companies
 *   party_supply_links, plant_supply_links
 *   pipelines, stages, deals, deal_stage_history, deal_checklists, tasks
 *   engagements, engagement_types,
 *     engagement_email_details, engagement_meeting_details,
 *     engagement_attendees, engagement_documents
 *
 * Note on Stage 28-a generics gotcha (see server.ts comment for full detail):
 *   The 3rd generic Schema is computed from Database[SchemaName]. We rely on
 *   the default-positioned 2-generic form (<Database, 'urm'>) so it resolves
 *   to Database['urm'] correctly. The server factory casts via `unknown` to
 *   match the existing app-schema pattern.
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import {
  createBrowserClient,
  createServerClient,
  type CookieOptions,
} from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';
import { env } from '@/lib/env';

type CookieToSet = { name: string; value: string; options?: CookieOptions };

// ============================================================================
// Admin client (service_role) -- bypasses RLS
// ============================================================================

type SupabaseUrmAdminDb = ReturnType<typeof createClient<Database, 'urm'>>;

/** Type annotation helper for callers passing the admin client around. */
export type SbUrmAdminClient = SupabaseUrmAdminDb;

let urmAdminClient: SupabaseUrmAdminDb | null = null;

/**
 * URM admin client. Singleton. service_role bypasses RLS.
 *
 * Restrictions (same as the app-schema admin client):
 *   - Workers (consultation, draft-expiry, mail-merge) and auth callbacks only
 *   - Never use in general Server Actions (the RLS bypass is a privilege risk)
 *   - When calling, ALWAYS include organization_id in WHERE explicitly
 *   - Audit log: changed_by is NULL, so include a trace_label in metadata
 */
export function createUrmAdminClient(): SupabaseUrmAdminDb {
  if (urmAdminClient) return urmAdminClient;

  urmAdminClient = createClient<Database, 'urm'>(
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
  return urmAdminClient;
}

// ============================================================================
// Browser client ('use client' components)
// ============================================================================

type SupabaseUrmBrowserDb = ReturnType<
  typeof createBrowserClient<Database, 'urm'>
>;

/** Type annotation helper for callers passing the browser client around. */
export type SbUrmBrowserClient = SupabaseUrmBrowserDb;

let urmBrowserClient: SupabaseUrmBrowserDb | null = null;

/**
 * URM browser client. Singleton (one instance per browser tab).
 * Use for Realtime channels, optimistic updates, and any 'use client' read.
 *
 * Restrictions:
 *   - Do NOT use in Server Actions (RLS bypass risk on cross-context calls)
 */
export function createUrmBrowserClient(): SupabaseUrmBrowserDb {
  if (urmBrowserClient) return urmBrowserClient;

  // NEXT_PUBLIC_* are inlined into the client bundle; direct process.env
  // access is fine here (lib/env's zod validation is server-only).
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY must be set in environment',
    );
  }

  urmBrowserClient = createBrowserClient<Database, 'urm'>(url, anonKey);
  return urmBrowserClient;
}

// ============================================================================
// Server client (Server Component / Server Action / Route Handler)
// ============================================================================

/** Type annotation helper for callers passing the server client around. */
export type SbUrmServerClient = SupabaseClient<Database, 'urm'>;

/**
 * URM server client. New instance per request (no long-lived cache).
 * Reads JWT from cookies; RLS is applied automatically via the
 * custom_access_token_hook (migration 013) which puts organization_id
 * into app_metadata.
 *
 * Server Component usage: cookie SET calls are silently no-op'd; middleware
 * handles session refresh.
 */
export async function createUrmServerClient(): Promise<SbUrmServerClient> {
  const cookieStore = await cookies();

  // ssr's generic inference is incomplete (see server.ts comment); the
  // `as unknown as` cast paves over it. Runtime behavior is identical.
  const client = createServerClient<Database, 'urm'>(
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
            // Server Component context: set is a no-op; middleware refreshes
          }
        },
      },
    },
  );
  return client as unknown as SbUrmServerClient;
}
