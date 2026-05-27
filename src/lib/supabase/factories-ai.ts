/**
 * lib/supabase/factories-ai.ts
 *
 * AI schema Supabase client factories (D5-3e2, Stage 29-c cutover).
 *
 * Three factories mirroring the existing app-schema client pattern in
 * admin.ts / client.ts / server.ts, but with schema generic locked to 'ai'.
 *
 * Use cases:
 *   - createAiAdminClient()    : service_role, RLS bypass (AI workers, scripts)
 *   - createAiBrowserClient()  : 'use client' components, singleton
 *   - createAiServerClient()   : Server Component / Server Action / Route Handler,
 *                                cookies + JWT-based RLS
 *
 * AI tables (use any of these via the helpers below):
 *   drafts          -- AI-generated email drafts
 *   agents          -- AI agent configurations
 *   brand_voice     -- per-organization brand voice settings
 *   knowledge_chunks -- vector store (pgvector)
 *   runs            -- AI run history (prompt + completion + metadata)
 *   auto_send_rules -- automation rules for outbound email
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

type SupabaseAiAdminDb = ReturnType<typeof createClient<Database, 'ai'>>;

/** Type annotation helper for callers passing the admin client around. */
export type SbAiAdminClient = SupabaseAiAdminDb;

let aiAdminClient: SupabaseAiAdminDb | null = null;

/**
 * AI admin client. Singleton. service_role bypasses RLS.
 *
 * Restrictions (same as the app-schema admin client):
 *   - Workers and AI orchestration only (not general Server Actions)
 *   - When calling, ALWAYS include organization_id in WHERE explicitly
 */
export function createAiAdminClient(): SupabaseAiAdminDb {
  if (aiAdminClient) return aiAdminClient;

  aiAdminClient = createClient<Database, 'ai'>(
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
  return aiAdminClient;
}

// ============================================================================
// Browser client ('use client' components)
// ============================================================================

type SupabaseAiBrowserDb = ReturnType<
  typeof createBrowserClient<Database, 'ai'>
>;

/** Type annotation helper for callers passing the browser client around. */
export type SbAiBrowserClient = SupabaseAiBrowserDb;

let aiBrowserClient: SupabaseAiBrowserDb | null = null;

/**
 * AI browser client. Singleton (one instance per browser tab).
 *
 * Restrictions:
 *   - Do NOT use in Server Actions
 */
export function createAiBrowserClient(): SupabaseAiBrowserDb {
  if (aiBrowserClient) return aiBrowserClient;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY must be set in environment',
    );
  }

  aiBrowserClient = createBrowserClient<Database, 'ai'>(url, anonKey);
  return aiBrowserClient;
}

// ============================================================================
// Server client (Server Component / Server Action / Route Handler)
// ============================================================================

/** Type annotation helper for callers passing the server client around. */
export type SbAiServerClient = SupabaseClient<Database, 'ai'>;

/**
 * AI server client. New instance per request (no long-lived cache).
 * Reads JWT from cookies; RLS applied via custom_access_token_hook.
 */
export async function createAiServerClient(): Promise<SbAiServerClient> {
  const cookieStore = await cookies();

  const client = createServerClient<Database, 'ai'>(
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
  return client as unknown as SbAiServerClient;
}
