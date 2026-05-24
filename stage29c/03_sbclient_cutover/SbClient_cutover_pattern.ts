/**
 * SbClient Cutover Pattern (Stage 29-c)
 *
 * 출처: handoff §A3 Gotcha #45 + §8 "SbClient default schema: 'app' → 'urm' 단일 cast site"
 * 작성: 2026-05-24
 *
 * ===========================================================================
 * 핵심 전략: 2-tier client (sbApp + sbUrm) 단일 schema cutover 보다 안전
 * ===========================================================================
 *
 * 이유:
 *   - app.* 의 잔존 운영 데이터 (email/sales/finance/communications 등)
 *     는 Stage 29-d 까지 1-2주 carry. 그 동안 caller 는 app + urm 양쪽 다 접근 필요.
 *   - 단일 schema cast (app → urm) 로 일괄 cutover 하면, app 측 호출이 모두 깨짐.
 *   - 2-tier 로 가면 caller 가 의도적으로 sbUrm.from(...) / sbApp.from(...) 선택.
 *     점진적 이전 가능, rollback 안전.
 *
 * Stage 29-d 종료 후 sbApp 은 deprecate, sbUrm 만 남김.
 *
 * ===========================================================================
 * 파일 위치 (추정 — 실제 프로젝트에서 audit script A1 결과로 확인)
 * ===========================================================================
 *
 * 변경 대상:
 *   - src/lib/supabase/server.ts        (Server Components / API Routes)
 *   - src/lib/supabase/client.ts        (Client Components / Browser)
 *   - src/lib/supabase/service.ts       (service-role / admin)
 *   - src/lib/supabase/middleware.ts    (Next.js middleware, 있을 경우)
 *
 * 변경 패턴:
 *   기존:  createServerClient<Database>(...)
 *   기존:  createServerClient<Database, 'app'>(...)
 *   변경:  export const sbApp = ... <Database, 'app'>(...)
 *   변경:  export const sbUrm = ... <Database, 'urm'>(...) // 신규
 *
 * ===========================================================================
 * BEFORE — 예시 (src/lib/supabase/server.ts)
 * ===========================================================================
 */

// import { createServerClient, type CookieOptions } from "@supabase/ssr";
// import { cookies } from "next/headers";
// import type { Database } from "./database";
//
// export type SbClient = SupabaseClient<Database, "app">;
//
// export async function createClient(): Promise<SbClient> {
//   const cookieStore = await cookies();
//   return createServerClient<Database, "app">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
//     {
//       cookies: {
//         get(name: string) { return cookieStore.get(name)?.value; },
//         set(name: string, value: string, options: CookieOptions) {
//           try { cookieStore.set({ name, value, ...options }); }
//           catch { /* Server Component */ }
//         },
//         remove(name: string, options: CookieOptions) {
//           try { cookieStore.set({ name, value: "", ...options }); }
//           catch {}
//         },
//       },
//       db: { schema: "app" },
//     }
//   );
// }

/*
 * ===========================================================================
 * AFTER — 2-tier (server.ts)
 * ===========================================================================
 */

import {
  createServerClient,
  type CookieOptions,
} from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import type { Database } from "./database";

// ─── Type aliases ──────────────────────────────────────────────────────────
export type SbAppClient = SupabaseClient<Database, "app">;
export type SbUrmClient = SupabaseClient<Database, "urm">;

/** @deprecated Stage 29-d 종료 후 제거. 점진적으로 sbUrm 으로 이전 */
export type SbClient = SbAppClient;

// ─── Common cookie handler ─────────────────────────────────────────────────
async function getCookieHandler() {
  const cookieStore = await cookies();
  return {
    get(name: string) {
      return cookieStore.get(name)?.value;
    },
    set(name: string, value: string, options: CookieOptions) {
      try {
        cookieStore.set({ name, value, ...options });
      } catch {
        /* Server Component context — Next.js 가 set 막음 */
      }
    },
    remove(name: string, options: CookieOptions) {
      try {
        cookieStore.set({ name, value: "", ...options });
      } catch {}
    },
  };
}

// ─── App client (legacy carry, Stage 29-d 까지) ────────────────────────────
export async function createAppClient(): Promise<SbAppClient> {
  return createServerClient<Database, "app">(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: await getCookieHandler(),
      db: { schema: "app" },
    }
  );
}

// ─── URM client (V2 primary) ────────────────────────────────────────────────
export async function createUrmClient(): Promise<SbUrmClient> {
  return createServerClient<Database, "urm">(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: await getCookieHandler(),
      db: { schema: "urm" },
    }
  );
}

// ─── Backward-compat (Stage 29-d 종료 후 제거) ──────────────────────────────
/** @deprecated Stage 29-d 종료 후 제거. createAppClient() 또는 createUrmClient() 사용 */
export const createClient = createAppClient;

/*
 * ===========================================================================
 * AFTER — 2-tier (src/lib/supabase/client.ts, Browser)
 * ===========================================================================
 */

// import { createBrowserClient } from "@supabase/ssr";
// import type { SupabaseClient } from "@supabase/supabase-js";
// import type { Database } from "./database";
//
// export type SbAppClient = SupabaseClient<Database, "app">;
// export type SbUrmClient = SupabaseClient<Database, "urm">;
//
// export function createAppBrowserClient(): SbAppClient {
//   return createBrowserClient<Database, "app">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
//     { db: { schema: "app" } }
//   );
// }
//
// export function createUrmBrowserClient(): SbUrmClient {
//   return createBrowserClient<Database, "urm">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
//     { db: { schema: "urm" } }
//   );
// }
//
// /** @deprecated Stage 29-d 종료 후 제거 */
// export const createClient = createAppBrowserClient;

/*
 * ===========================================================================
 * AFTER — 2-tier (src/lib/supabase/service.ts, Service Role)
 * ===========================================================================
 *
 * service-role client 는 RLS 우회. urm/app 모두 동일 token 으로 접근 가능.
 */

// import { createClient as createSupabaseClient } from "@supabase/supabase-js";
// import type { SupabaseClient } from "@supabase/supabase-js";
// import type { Database } from "./database";
//
// export type SbAppServiceClient = SupabaseClient<Database, "app">;
// export type SbUrmServiceClient = SupabaseClient<Database, "urm">;
//
// export function createAppServiceClient(): SbAppServiceClient {
//   return createSupabaseClient<Database, "app">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.SUPABASE_SERVICE_ROLE_KEY!,
//     {
//       auth: { persistSession: false, autoRefreshToken: false },
//       db: { schema: "app" },
//     }
//   );
// }
//
// export function createUrmServiceClient(): SbUrmServiceClient {
//   return createSupabaseClient<Database, "urm">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.SUPABASE_SERVICE_ROLE_KEY!,
//     {
//       auth: { persistSession: false, autoRefreshToken: false },
//       db: { schema: "urm" },
//     }
//   );
// }
//
// /** @deprecated Stage 29-d 종료 후 제거 */
// export const createServiceClient = createAppServiceClient;

/*
 * ===========================================================================
 * Caller 측 호출 패턴 (변경 예시)
 * ===========================================================================
 *
 * BEFORE:
 *   const sb = await createClient();
 *   const { data } = await sb.from("parties").select("*");
 *   // → app.parties select
 *
 * AFTER (urm 으로 이전):
 *   const sb = await createUrmClient();
 *   const { data } = await sb.from("parties").select("*");
 *   // → urm.parties select
 *
 * AFTER (app 잔존 영역, 예: communications, sales_orders):
 *   const sb = await createAppClient();
 *   const { data } = await sb.from("communications").select("*");
 *   // → app.communications select
 *
 * AFTER (혼합 — 한 함수에서 양쪽 필요):
 *   const [sbApp, sbUrm] = await Promise.all([
 *     createAppClient(),
 *     createUrmClient(),
 *   ]);
 *   const [comms, parties] = await Promise.all([
 *     sbApp.from("communications").select("*"),
 *     sbUrm.from("parties").select("*"),
 *   ]);
 */

/*
 * ===========================================================================
 * 호출 분기 (어느 쪽 client 를 쓸지)
 * ===========================================================================
 *
 * URM (sbUrm) 이 1차 선택지인 테이블:
 *   - parties, contacts, contacts_history, party_supply_links, plant_supply_links
 *   - investor_profile, paper_mill_profile, filler_supplier_profile
 *   - investor_portfolio_companies
 *   - pipelines, stages, deals, deal_stage_history, deal_checklists
 *   - tasks, engagements, engagement_attendees, engagement_documents
 *   - party_types
 *
 * APP (sbApp) carry 영역 (Stage 29-d 까지):
 *   - email_whitelist, communications, drafts, email_tracking, email_templates, ...
 *   - sales_orders, sales_order_items, invoices, payments, shipments, quotations
 *   - mailcarrier_state, scraping_jobs, scraping_raw, scraping_sources, scraping_targets
 *   - users, roles, permissions, role_permissions, user_roles, teams, team_members
 *   - organizations  (urm 은 single-tenant 라 organization_id 없음)
 *   - meetings, meeting_attendees, calendar_events, calendar_connections, ...
 *   - tags, entity_tags, custom_field_definitions, custom_field_values
 *   - response_strategies, strategy_actions, strategy_outcomes
 *   - templates_* (email_templates 외 다수)
 *   - lookup: investor_subtype_meta, partner_seniority_meta, engagement_type_registry
 *   - 잔재: investor_partner_profile (108), person_firm_history (109), investor_portfolio_companies (422)
 *           ← Stage 29-d 시 자동 drop, 그동안 read-only carry
 *
 * 결정 시 의문 발생할 때: handoff §8 의 schema 정의 참조.
 */

/*
 * ===========================================================================
 * 마이그레이션 안내 (caller 측, 단계적)
 * ===========================================================================
 *
 * 1. 본 cutover 적용 후 build (npm run build) 통과 확인 (기존 caller 는 sbApp 유지하므로 무손실)
 * 2. caller code 를 한 도메인씩 sbUrm 으로 이전 (예: parties 도메인 먼저)
 * 3. 각 도메인 이전 시:
 *    a. 해당 호출 사이트 list (audit script A1, A2 매치)
 *    b. createClient → createUrmClient 또는 createAppClient 명시
 *    c. 컬럼 rename (party_type → party_type_id 등) 적용
 *    d. 빌드 + 테스트
 * 4. 모든 URM 도메인 이전 완료 후 sbApp 사용 사이트 list 가 §결정 표의 "APP carry 영역" 과 일치하는지 검증
 * 5. Stage 29-d 진입 시 sbApp 도 deprecate
 */
