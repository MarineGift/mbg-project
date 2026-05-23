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
// URM 의 single source for all supabase.rpc(...) calls.
// caller 측은 cast 없이 fn name + args 자동완성 + 결과 type 추론.
//
// Augmentation: Supabase CLI gen types 가 PostgreSQL 함수 오버로드를 처리
// 하지 못해 3 함수 type 누락 (DB 에 short + long 두 버전 공존). long-signature
// 채택 (industry_tag + name_contains 포함). short 는 long 의 subset 이라 호환.

import type { SupabaseClient, PostgrestError } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

// ---------------------------------------------------------------
// Augmentation — CLI overload 미지원 보완 (3 함수)
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
    };
    Returns: {
      total_matching: number | null;
      enrolled_count: number | null;
      skipped_already_enrolled: number | null;
      skipped_no_email: number | null;
      sample_names: string[] | null;
    }[];
  };

  preview_campaign_filter: {
    Args: {
      p_org_id: string;
      p_module?: string | null;
      p_tiers?: string[] | null;
      p_status?: string | null;
      p_country_code?: string | null;
      p_industry_tag?: string | null;
      p_name_contains?: string | null;
    };
    Returns: {
      total_matching: number | null;
      with_email: number | null;
      no_email: number | null;
      sample_names: string[] | null;
    }[];
  };

  create_campaign_from_template: {
    Args: {
      p_organization_id: string;
      p_template_id: string;
      p_campaign_name: string;
      p_module?: string | null;
      p_tiers?: string[] | null;
      p_status?: string | null;
      p_country_code?: string | null;
      p_enrolled_by?: string | null;
      p_industry_tag?: string | null;
      p_name_contains?: string | null;
    };
    Returns: {
      sequence_id: string | null;
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

type Fns = Database['public']['Functions'] & Augmentation;
export type FnName = keyof Fns;
export type FnArgs<N extends FnName> = Fns[N]['Args'];
export type FnReturns<N extends FnName> = Fns[N]['Returns'];

export type RpcResult<N extends FnName> = {
  data: FnReturns<N> | null;
  error: PostgrestError | null;
};

// ---------------------------------------------------------------
// Wrapper — single cast site (Gotcha #28 의 RPC 버전).
// v2: `as any` (not `as never`) to keep callable signature.
// Stage 28-a: client param의 SchemaName generic widen (3번째 param도 any로).
//   server.ts factory가 <Database, 'app'>으로 변경되면서 caller가 넘기는
//   client는 SupabaseClient<Database, 'app', Database['app']>. 'public' 고정
//   하면 mismatch → 첫번째 외 두 generic 모두 any로 받아 RPC만 가능하면 OK.
//   .rpc()는 schema generic과 무관 (RPC는 public.Functions 또는 명시 schema).
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
