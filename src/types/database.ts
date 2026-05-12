/**
 * types/database.ts
 *
 * Supabase generated Database type stub.
 *
 * 운영 환경에서는 다음 명령으로 자동 갱신:
 *   supabase gen types typescript --linked --schema public,app,ai,audit \
 *     > src/types/database.ts
 *
 * 본 stub은 SupabaseClient의 제네릭 인자로만 사용되며, 실제 컬럼 타입 검증은
 * 각 lib/queries, lib/actions에서 명시적으로 수행한다.
 *
 * stub이 정확하지 않더라도 SupabaseClient는 `unknown`을 반환할 뿐이므로
 * 런타임에는 영향 없음 — 타입 단언만 적절히 사용하면 안전.
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: Record<string, never>;
    Views: Record<string, never>;
    Functions: {
      custom_access_token_hook: {
        Args: { event: Json };
        Returns: Json;
      };
    };
    Enums: Record<string, never>;
  };
  app: {
    Tables: Record<string, never>;
    Views: Record<string, never>;
    Functions: {
      current_user_id: { Args: Record<string, never>; Returns: string | null };
      current_organization_id: {
        Args: Record<string, never>;
        Returns: string | null;
      };
      current_is_owner: { Args: Record<string, never>; Returns: boolean };
      current_preferred_language: {
        Args: Record<string, never>;
        Returns: string;
      };
      is_member_of_organization: {
        Args: { p_organization_id: string };
        Returns: boolean;
      };
      is_organization_owner: {
        Args: { p_organization_id: string };
        Returns: boolean;
      };
    };
    Enums: Record<string, never>;
  };
  ai: {
    Tables: Record<string, never>;
    Views: Record<string, never>;
    Functions: {
      expire_stale_drafts: {
        Args: Record<string, never>;
        Returns: { expired_count: number; organization_id: string }[];
      };
      search_knowledge: {
        Args: {
          p_organization_id: string;
          p_query_embedding: string;
          p_collection?: string;
          p_language?: string;
          p_top_k?: number;
          p_min_similarity?: number;
        };
        Returns: {
          id: string;
          collection: string;
          title: string | null;
          content: string;
          language: string;
          similarity: number;
          metadata: Json;
          source_url: string | null;
        }[];
      };
    };
    Enums: Record<string, never>;
  };
}
