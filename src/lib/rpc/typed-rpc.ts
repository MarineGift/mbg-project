// src/lib/rpc/typed-rpc.ts
//
// Stage 27 — typed RPC wrapper (v2).
//
// v2 changes (relative to v1):
//   - cast fix: `(client.rpc as never)(...)` → `(client.rpc as any)(...)`.
//     Reason: `as never` removes callable signature too (TS2349). `as any`
//     keeps callability while still isolating the unsafe op to one line.
//   - FnArgs / FnReturns simplified from conditional `infer` form to direct
//     lookup. Conditional types in generic context can defer evaluation;
//     direct lookup forces immediate resolution and gives caller proper
//     narrowing (avoids TS18048 cascade).
//
// URM's single source for all supabase.rpc(...) calls.
// On the caller side: no casts, with fn-name + args autocomplete + result-type inference.
//
// Augmentation: Supabase CLI gen types cannot handle PostgreSQL function overloads,
// so 3 function types are missing (the DB has both short + long versions). The long signature
// is adopted (includes industry_tag + name_contains). short is a subset of long, so it is compatible.

import type { SupabaseClient, PostgrestError } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

// ---------------------------------------------------------------
// Augmentation - compensates for the CLI's lack of overload support (3 functions)
// ---------------------------------------------------------------

type Augmentation = {
  bulk_enroll_filtered: {
    Args: {
      p_organization_id: string;
      p_sequence_id: string;
      p_module?: string | null;
      p_tiers?: string[] | null;
      p_status?: string | null;
      p_country_code?: string | null;
      p_enrolled_by?: string | null;
      p_dry_run?: boolean | null;
      p_industry_tag?: string | null;
      p_name_contains?: string | null;
      p_priority?: string[] | null;
    };
    Returns: {
      total_matching: number | null;
      enrolled_count: number | null;
      skipped_already_enrolled: number | null;
      skipped_no_email: number | null;
      sample_names: string[] | null;
    }[];
  };


};

// ---------------------------------------------------------------
// Combined function map — 8 generated + 3 augmented = 11
// v2: direct lookup (no conditional `infer`) for reliable narrowing
// ---------------------------------------------------------------

type Fns = Database['public']['Functions'] & Database['app']['Functions'] & Database['ai']['Functions'] & Augmentation;
export type FnName = keyof Fns;
export type FnArgs<N extends FnName> = Fns[N]['Args'];
export type FnReturns<N extends FnName> = Fns[N]['Returns'];

export type RpcResult<N extends FnName> = {
  data: FnReturns<N> | null;
  error: PostgrestError | null;
};

// ---------------------------------------------------------------
// Wrapper - single cast site (the RPC version of Gotcha #28).
// v2: `as any` (not `as never`) to keep callable signature.
// Stage 28-a: widen the SchemaName generic of the client param (the 3rd param to any too).
//   Since the server.ts factory changed to <Database, 'app'>, the client the caller passes
//   is SupabaseClient<Database, 'app', Database['app']>. Fixing it to 'public'
//   would mismatch -> accept both generics besides the first as any; as long as RPC works it is OK.
//   .rpc() is independent of the schema generic (RPC uses public.Functions or an explicit schema).
// ---------------------------------------------------------------

export async function rpc<N extends FnName>(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  client: SupabaseClient<Database, any, any>,
  fnName: N,
  args: FnArgs<N>,
): Promise<RpcResult<N>> {
  // single isolated unsafe operation.
  // type safety enforced at wrapper boundary (FnArgs<N>) and return cast.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const result = await (client.rpc as any)(fnName, args);
  return result as RpcResult<N>;
}
