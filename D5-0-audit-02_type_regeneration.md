### Subdir: `02_type_regeneration`

#### `REGEN_TYPES.md` (4438 bytes)

```markdown
# Stage 29-c — Type Regeneration

## §1. 왜 필요한가

현재 `database.ts` 는 `ai`, `app`, `audit`, `public` 4 schema 만 포함. **`urm` schema 부재**. Stage 29-c cutover 가 진행되려면 `urm` 타입이 반드시 있어야 함.

## §2. 1순위: Supabase CLI 로 재생성

### 2-1. 사전 조건
- Supabase project ref / access token 보유
- npx 사용 가능

### 2-2. 명령 (PowerShell)

```powershell
# 환경 변수 설정 (기존 값 사용)
$env:SUPABASE_ACCESS_TOKEN = "sbp_xxx..."  # Supabase Dashboard > Account > Access Tokens

# project ref 확인 (Supabase Dashboard > Settings > General)
$projectRef = "your-project-ref"   # ex: "abcdefghijklmnop"

# 백업
Copy-Item src\lib\supabase\database.ts src\lib\supabase\database.ts.v1_backup -Force

# 재생성 (--schema 에 urm 반드시 포함)
npx supabase gen types typescript `
  --project-id $projectRef `
  --schema app,ai,audit,urm,public `
  | Out-File -FilePath src\lib\supabase\database.ts -Encoding UTF8
```

### 2-3. 검증

```powershell
# urm schema 가 들어왔는지 확인
Select-String -Path src\lib\supabase\database.ts -Pattern "^  urm: " | Format-List
# 1 개 이상 매치되어야 함

# urm 의 테이블 list 확인
Select-String -Path src\lib\supabase\database.ts -Pattern "^      [a-z_]+: \{$" `
  | Where-Object { $_.Context -match "urm:" } `
  | Measure-Object
# Stage 29-b 종결 시점의 urm 테이블 19 개 이상 (parties, contacts, contacts_history, investor_profile, paper_mill_profile, filler_supplier_profile, investor_portfolio_companies, party_supply_links, plant_supply_links, pipelines, stages, deals, deal_stage_history, deal_checklists, tasks, engagements, engagement_attendees, engagement_documents, party_types)
```

## §3. 2순위 (CLI fail 시): GraphQL endpoint 활용

`urm` schema 가 Supabase 의 GraphQL 노출 (Settings > API > Exposed schemas) 에 없으면 CLI 도 fail. 그 경우:

```powershell
# Dashboard 에서 추가
# Settings > API > "Exposed schemas" 에 "urm" 추가 + Save
# 그 후 §2-2 재실행
```

## §4. 3순위 (CLI 도 fail, GraphQL 도 fail): 수기 타입 fallback

`urm_schema_typescript_stub.ts` 사용. 이 파일은 Stage 29-b handoff §7 + §8 의 정보를 기반으로 수기 작성된 type stub. 완전하지 않을 수 있음 (모든 컬럼 커버 안 됨), 컴파일 통과만 보장.

### 사용법

```typescript
// src/lib/supabase/database.ts 가 V1 이라면, 별도 import:
import type { Database as DatabaseV1 } from "./database";
import type { UrmSchema } from "./urm_schema_typescript_stub";

// Merge type
export type Database = DatabaseV1 & {
  urm: UrmSchema;
};
```

이 패턴은 임시방편. 정식 재생성이 가능해지면 즉시 §2 로 전환.

## §5. 재생성 후 검증 SQL

재생성된 타입이 실제 DB 와 sync 인지 확인:

```sql
-- Supabase SQL Editor 에서 실행
SELECT
  table_schema,
  COUNT(*) AS table_count,
  string_agg(table_name, ', ' ORDER BY table_name) AS tables
FROM information_schema.tables
WHERE table_schema = 'urm'
  AND table_type = 'BASE TABLE'
GROUP BY table_schema;

-- 기대: 19 테이블 이상 (handoff §7 + §8 의 list)
```

다른 측면 검증:

```sql
-- urm.parties 의 컬럼 list
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'urm' AND table_name = 'parties'
ORDER BY ordinal_position;

-- 기대 컬럼: id, party_type_id (FK), name, name_normalized,
--           website, domain_normalized, country_code, ... (V2 컬럼)
-- 기대 부재: parent_party_id, party_level (3-tier DROP), party_type (직접 enum, FK 로 대체)
```

## §6. 재생성 실패 시 trouble shooting

| 증상 | 원인 | 해결 |
|---|---|---|
| `gen types` 가 빈 출력 | access token 만료 | Dashboard 에서 재발급 |
| urm schema 누락 | --schema 에 urm 미포함 | --schema 인자 확인 |
| urm schema 부분 누락 | RLS 로 select 권한 없음 | service role token 사용 |
| `column ... does not exist` 빌드 에러 | types 와 DB 비동기 | types 재생성 후 `tsc --noEmit` 재실행 |

## §7. 적용 후 git diff 확인

```powershell
git diff src\lib\supabase\database.ts | Out-File -FilePath stage29c_database_ts_diff.patch -Encoding UTF8
```

이 diff 가 cutover 의 actual scope. 검토 후 commit.
```

#### `urm_schema_typescript_stub.ts` (23016 bytes)

```typescript
/**
 * urm schema TypeScript stub
 *
 * 출처: SESSION_HANDOFF_2026-05-24_stage29b_complete.md
 * 작성: Stage 29-c 진입 시점 (2026-05-24)
 *
 * 용도: `npx supabase gen types` 가 urm schema 를 못 잡을 때의 fallback.
 *       이 파일은 handoff §7, §8 의 정보만으로 작성. 모든 컬럼이 완벽히 정확하진 않음.
 *       정식 gen types 가 가능해지면 즉시 deprecate.
 *
 * 사용 패턴:
 *   import type { Database as V1Database } from "./database";
 *   import type { UrmSchema } from "./urm_schema_typescript_stub";
 *
 *   export type Database = V1Database & { urm: UrmSchema };
 *
 *   // SbClient
 *   const sbUrm = createClient(url, key, { db: { schema: "urm" } }) as
 *     SupabaseClient<Database, "urm">;
 */

import type { Json } from "./database"; // V1 의 Json 타입 재사용

// ============================================================================
// Enums (urm-side)
// ============================================================================

// handoff §6 #5: 7 party_types codes (lookup row 값)
export type UrmPartyTypeCode =
  | "investor"
  | "paper_mill"
  | "filler_supplier"
  | "buyer"
  | "customer"
  | "partner"
  | "government_grant";

// γ 의 supply_type→link_type cast 결과 (handoff §8 매핑 logic)
export type UrmSupplyLinkType =
  | "potential"
  | "active"
  | "historical";

// 추정 — 실제 DB 에서 확인 필요
export type UrmContactSeniority = string; // text (γ 에서 enum→text cast)

// ============================================================================
// urm.party_types (lookup)
// ============================================================================

export interface UrmPartyType {
  id: number;             // 1..7
  code: UrmPartyTypeCode;
  display_name_ko: string;
  display_name_en?: string | null;
  sort_order?: number | null;
}

// ============================================================================
// urm.parties (1532 active, handoff §7)
// ============================================================================

export interface UrmPartyRow {
  id: string;                              // uuid (V1 id 보존)
  party_type_id: number;                   // FK to urm.party_types (handoff §6 #2)
  name: string;
  name_normalized: string | null;
  legal_name: string | null;
  website: string | null;
  domain_normalized: string | null;
  country_code: string | null;             // handoff §A4: country → country_code
  city: string | null;
  region: string | null;
  timezone: string | null;
  phone_e164: string | null;
  phone_normalized: string | null;
  linkedin_url: string | null;
  industry_tags: string[];
  interest_tags: string[];
  employee_count: number | null;
  annual_revenue_usd: number | null;
  founded_year: number | null;
  tier: string | null;                     // text (urm) — V2 enum 여부 불명
  status: string;                          // text (active/inactive/...)
  relationship_score: number | null;
  notes: string | null;
  source: string | null;
  source_external_id: string | null;
  module_data: Json;                       // _app_* prefix 로 V1 데이터 보존
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
  // 부재 (handoff §8 "3-tier hierarchy DROP"):
  // - parent_party_id, party_level
  // 부재 (urm single-tenant, handoff §8):
  // - organization_id
}

export interface UrmPartyInsert extends Partial<UrmPartyRow> {
  party_type_id: number;
  name: string;
}

export type UrmPartyUpdate = Partial<UrmPartyRow>;

// ============================================================================
// urm.contacts (217 active, handoff §7)
// ============================================================================

export interface UrmContactRow {
  id: string;                              // uuid (V1 id 보존)
  firm_party_id: string;                   // FK to urm.parties — NOT NULL (handoff §6 #4)
  full_name: string;
  given_name: string | null;
  family_name: string | null;
  email: string | null;
  email_secondary: string | null;
  phone: string | null;
  phone_mobile: string | null;
  title: string | null;
  department: string | null;
  seniority_level: UrmContactSeniority | null;  // text (γ cast)
  linkedin_url: string | null;
  preferred_language: string | null;
  timezone: string | null;
  is_primary: boolean;                     // stage29a 신설 (handoff §6 #7), default false
  is_decision_maker: boolean | null;       // module_data._app_is_decision_maker 로 보존된 케이스도
  do_not_contact: boolean;
  do_not_contact_reason: string | null;
  notes: string | null;
  module_data: Json;                       // _app_* prefix 로 V1 데이터 보존
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
}

export interface UrmContactInsert extends Partial<UrmContactRow> {
  firm_party_id: string;
  full_name: string;
}

export type UrmContactUpdate = Partial<UrmContactRow>;

// ============================================================================
// urm.contacts_history (109 row, handoff §7 - γ INSERT 118 - ε DELETE 9)
// ============================================================================

export interface UrmContactsHistoryRow {
  id: string;                              // uuid
  contact_id: string;                      // FK to urm.contacts (V1 person_party_id rename, γ)
  firm_party_id: string;                   // FK to urm.parties (V1 firm_party_id 보존)
  role_title: string | null;
  started_at: string | null;               // date (V1 joined_at::date)
  ended_at: string | null;                 // date (V1 left_at::date)
  is_current: boolean;
  notes: string | null;
  module_data: Json;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface UrmContactsHistoryInsert extends Partial<UrmContactsHistoryRow> {
  contact_id: string;
  firm_party_id: string;
}

export type UrmContactsHistoryUpdate = Partial<UrmContactsHistoryRow>;

// ============================================================================
// urm.party_supply_links (117 row, handoff §7)
// ============================================================================

export interface UrmPartySupplyLinkRow {
  id: string;                              // uuid
  supplier_party_id: string;               // FK to urm.parties
  buyer_party_id: string;                  // FK to urm.parties
  link_type: UrmSupplyLinkType;            // text (V1 supply_type::text cast)
  product_grade: string | null;
  volume_estimate: string | null;          // text (V1 volume_tpy + ' tpy')
  contracted_at: string | null;
  contract_end_at: string | null;
  confidence_grade: string | null;
  source: string | null;
  notes: string | null;
  module_data: Json;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface UrmPartySupplyLinkInsert extends Partial<UrmPartySupplyLinkRow> {
  supplier_party_id: string;
  buyer_party_id: string;
  link_type: UrmSupplyLinkType;
}

export type UrmPartySupplyLinkUpdate = Partial<UrmPartySupplyLinkRow>;

// ============================================================================
// urm.plant_supply_links (0 row, handoff §7 skip)
// ============================================================================

export interface UrmPlantSupplyLinkRow {
  id: string;
  plant_party_id: string;
  supplier_party_id: string;
  link_type: UrmSupplyLinkType;
  product_grade: string | null;
  volume_estimate: string | null;
  contracted_at: string | null;
  contract_end_at: string | null;
  confidence_grade: string | null;
  source: string | null;
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.investor_profile (101 row, handoff §7 - 106 - 5 fund)
// ============================================================================

export interface UrmInvestorProfileRow {
  id: string;
  party_id: string;                        // FK to urm.parties (1:1)
  fund_type: string | null;
  stage_focus: string[];
  sector_focus: string[];
  geo_focus: string[];
  aum_usd: number | null;
  fund_size_usd: number | null;
  ticket_size_min: number | null;
  ticket_size_max: number | null;
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.paper_mill_profile (1074 row, handoff §7 - 변동 없음)
// ============================================================================

export interface UrmPaperMillProfileRow {
  id: string;
  party_id: string;
  mill_capacity_tpy: number | null;
  grades_produced: string[];
  segments: string[];                      // P&W / Packaging / Specialty / Tissue
  filler_usage_pct: number | null;
  preferred_fillers: string[];
  current_filler_supplier_party_ids: string[];
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.filler_supplier_profile (232 row, 3 HQ 포함 - handoff §7)
// ============================================================================

export interface UrmFillerSupplierProfileRow {
  id: string;
  party_id: string;
  filler_types: string[];                  // GCC / PCC / HFCC / FCC / talc / kaolin
  product_grades: string[];
  capacity_tpy: number | null;
  hq_location: string | null;
  is_hq: boolean;                          // Carmeuse/Schaefer Kalk/Sibelco/Omya HQ flag
  technical_capabilities: string[];
  certifications: string[];
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.investor_portfolio_companies (422 row, δ Port-1 신설)
// handoff §7: "18 columns, 5 indexes, FK to urm.parties CASCADE"
// ============================================================================

export interface UrmInvestorPortfolioCompanyRow {
  id: string;                                       // uuid (V1 id 보존)
  investor_party_id: string;                        // FK to urm.parties (investor)
  portfolio_company_name: string;
  portfolio_company_name_normalized: string | null; // δ 신설 컬럼 (LEFT JOIN result)
  portfolio_company_party_id: string | null;        // FK to urm.parties (만약 portfolio company 자체도 party 인 경우)
  investment_round: string | null;
  investment_year: number | null;
  investment_amount_usd: number | null;
  ownership_pct: number | null;
  status: string;                                   // active / exited / written_off
  exit_year: number | null;
  exit_type: string | null;
  notes: string | null;
  source: string | null;
  module_data: Json;                                // _app_portfolio_company_id 보존
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface UrmInvestorPortfolioCompanyInsert extends Partial<UrmInvestorPortfolioCompanyRow> {
  investor_party_id: string;
  portfolio_company_name: string;
}

export type UrmInvestorPortfolioCompanyUpdate = Partial<UrmInvestorPortfolioCompanyRow>;

// ============================================================================
// urm.pipelines (0 row, α+β TRUNCATE)
// ============================================================================

export interface UrmPipelineRow {
  id: string;
  name: string;
  module: string;                          // text (V1 module_type::text)
  description: string | null;
  is_default: boolean;
  is_active: boolean;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.stages (0 row, α+β TRUNCATE)
// handoff §6 #3: 정렬 컬럼명 = sort_order (NOT stage_position)
// ============================================================================

export interface UrmStageRow {
  id: string;
  pipeline_id: string;                     // FK to urm.pipelines
  code: string;
  name: string;
  sort_order: number;                      // ← 핵심: stage_position 아님
  color_hex: string | null;
  stage_type: string;                      // text
  default_probability_pct: number;
  is_won: boolean;
  is_lost: boolean;
  is_terminal: boolean;
  description: string | null;
  auto_actions: Json;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.deals (0 row, V2 신설 컨셉, α+β TRUNCATE)
// handoff §6 #1: app 에 deals 부재. urm 가 정식 위치.
// ============================================================================

export interface UrmDealRow {
  id: string;
  pipeline_id: string;                     // FK to urm.pipelines
  current_stage_id: string | null;         // FK to urm.stages
  name: string;
  party_id: string;                        // FK to urm.parties (counterparty)
  primary_contact_id: string | null;       // FK to urm.contacts
  owner_user_id: string | null;
  status: string;                          // open / won / lost / paused
  value_amount: number | null;
  value_currency: string;
  weighted_amount: number | null;
  probability_pct: number;
  expected_close_date: string | null;
  actual_close_date: string | null;
  last_activity_at: string | null;
  next_action_at: string | null;
  priority: string;                        // low / medium / high / urgent
  source: string | null;
  won_lost_reason: string | null;
  description: string | null;
  module: string;
  module_data: Json;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
}

// ============================================================================
// urm.deal_stage_history (0 row, stage29a 신설)
// ============================================================================

export interface UrmDealStageHistoryRow {
  id: string;
  deal_id: string;
  from_stage_id: string | null;
  to_stage_id: string;
  changed_at: string;
  changed_by: string | null;
  duration_in_prev_stage_days: number | null;
  reason: string | null;
  notes: string | null;
}

// ============================================================================
// urm.deal_checklists (0 row, stage29a 신설)
// ============================================================================

export interface UrmDealChecklistRow {
  id: string;
  deal_id: string;
  name: string;
  is_completed: boolean;
  completed_at: string | null;
  sort_order: number;
  description: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.tasks (0 row, α+β TRUNCATE)
// handoff §6 #8: checklist_id 컬럼 신설 (FK to urm.deal_checklists ON DELETE SET NULL)
// ============================================================================

export interface UrmTaskRow {
  id: string;
  title: string;
  description: string | null;
  status: string;                          // open / in_progress / done / cancelled
  priority: string;
  assigned_to_user_id: string | null;
  assigned_to_team_id: string | null;
  due_at: string | null;
  reminder_at: string | null;
  started_at: string | null;
  completed_at: string | null;
  estimated_minutes: number | null;
  actual_minutes: number | null;
  party_id: string | null;
  contact_id: string | null;
  deal_id: string | null;                  // V2 신규 (V1 의 engagement_id 일부 흡수)
  engagement_id: string | null;
  checklist_id: string | null;             // FK to urm.deal_checklists (stage29a)
  parent_task_id: string | null;
  module: string | null;
  module_data: Json;
  tags: string[];
  completion_notes: string | null;
  blocked_reason: string | null;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
}

// ============================================================================
// urm.engagements (0 row, α+β TRUNCATE)
// ============================================================================

export interface UrmEngagementRow {
  id: string;
  name: string;
  type: string;                            // meeting / call / email / event / ...
  status: string;
  scheduled_at: string | null;
  started_at: string | null;
  ended_at: string | null;
  duration_minutes: number | null;
  location: string | null;
  meeting_link: string | null;
  party_id: string | null;
  deal_id: string | null;
  primary_contact_id: string | null;
  owner_user_id: string | null;
  description: string | null;
  notes: string | null;
  module: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.engagement_attendees (0 row, V2 신설 컨셉)
// ============================================================================

export interface UrmEngagementAttendeeRow {
  id: string;
  engagement_id: string;
  contact_id: string | null;
  user_id: string | null;
  party_id: string | null;
  role: string | null;                     // attendee / organizer / optional
  rsvp_status: string | null;
  attended: boolean | null;
  notes: string | null;
  created_at: string;
}

// ============================================================================
// urm.engagement_documents (0 row, V2 신설 컨셉)
// ============================================================================

export interface UrmEngagementDocumentRow {
  id: string;
  engagement_id: string;
  attachment_id: string | null;
  document_type: string | null;            // agenda / minutes / slides / contract
  title: string;
  description: string | null;
  created_at: string;
}

// ============================================================================
// Aggregate: UrmSchema (Database 합치기용)
// ============================================================================

export type UrmSchema = {
  Tables: {
    parties: {
      Row: UrmPartyRow;
      Insert: UrmPartyInsert;
      Update: UrmPartyUpdate;
      Relationships: [];
    };
    contacts: {
      Row: UrmContactRow;
      Insert: UrmContactInsert;
      Update: UrmContactUpdate;
      Relationships: [];
    };
    contacts_history: {
      Row: UrmContactsHistoryRow;
      Insert: UrmContactsHistoryInsert;
      Update: UrmContactsHistoryUpdate;
      Relationships: [];
    };
    party_supply_links: {
      Row: UrmPartySupplyLinkRow;
      Insert: UrmPartySupplyLinkInsert;
      Update: UrmPartySupplyLinkUpdate;
      Relationships: [];
    };
    plant_supply_links: {
      Row: UrmPlantSupplyLinkRow;
      Insert: Partial<UrmPlantSupplyLinkRow>;
      Update: Partial<UrmPlantSupplyLinkRow>;
      Relationships: [];
    };
    investor_profile: {
      Row: UrmInvestorProfileRow;
      Insert: Partial<UrmInvestorProfileRow> & { party_id: string };
      Update: Partial<UrmInvestorProfileRow>;
      Relationships: [];
    };
    paper_mill_profile: {
      Row: UrmPaperMillProfileRow;
      Insert: Partial<UrmPaperMillProfileRow> & { party_id: string };
      Update: Partial<UrmPaperMillProfileRow>;
      Relationships: [];
    };
    filler_supplier_profile: {
      Row: UrmFillerSupplierProfileRow;
      Insert: Partial<UrmFillerSupplierProfileRow> & { party_id: string };
      Update: Partial<UrmFillerSupplierProfileRow>;
      Relationships: [];
    };
    investor_portfolio_companies: {
      Row: UrmInvestorPortfolioCompanyRow;
      Insert: UrmInvestorPortfolioCompanyInsert;
      Update: UrmInvestorPortfolioCompanyUpdate;
      Relationships: [];
    };
    pipelines: {
      Row: UrmPipelineRow;
      Insert: Partial<UrmPipelineRow> & { name: string; module: string };
      Update: Partial<UrmPipelineRow>;
      Relationships: [];
    };
    stages: {
      Row: UrmStageRow;
      Insert: Partial<UrmStageRow> & {
        pipeline_id: string;
        code: string;
        name: string;
        sort_order: number;
        stage_type: string;
      };
      Update: Partial<UrmStageRow>;
      Relationships: [];
    };
    deals: {
      Row: UrmDealRow;
      Insert: Partial<UrmDealRow> & { pipeline_id: string; name: string; party_id: string };
      Update: Partial<UrmDealRow>;
      Relationships: [];
    };
    deal_stage_history: {
      Row: UrmDealStageHistoryRow;
      Insert: Partial<UrmDealStageHistoryRow> & { deal_id: string; to_stage_id: string };
      Update: Partial<UrmDealStageHistoryRow>;
      Relationships: [];
    };
    deal_checklists: {
      Row: UrmDealChecklistRow;
      Insert: Partial<UrmDealChecklistRow> & { deal_id: string; name: string };
      Update: Partial<UrmDealChecklistRow>;
      Relationships: [];
    };
    tasks: {
      Row: UrmTaskRow;
      Insert: Partial<UrmTaskRow> & { title: string };
      Update: Partial<UrmTaskRow>;
      Relationships: [];
    };
    engagements: {
      Row: UrmEngagementRow;
      Insert: Partial<UrmEngagementRow> & { name: string; type: string };
      Update: Partial<UrmEngagementRow>;
      Relationships: [];
    };
    engagement_attendees: {
      Row: UrmEngagementAttendeeRow;
      Insert: Partial<UrmEngagementAttendeeRow> & { engagement_id: string };
      Update: Partial<UrmEngagementAttendeeRow>;
      Relationships: [];
    };
    engagement_documents: {
      Row: UrmEngagementDocumentRow;
      Insert: Partial<UrmEngagementDocumentRow> & { engagement_id: string; title: string };
      Update: Partial<UrmEngagementDocumentRow>;
      Relationships: [];
    };
    party_types: {
      Row: UrmPartyType;
      Insert: UrmPartyType;
      Update: Partial<UrmPartyType>;
      Relationships: [];
    };
  };
  Views: Record<string, never>;
  Functions: Record<string, never>;
  Enums: Record<string, never>;
  CompositeTypes: Record<string, never>;
};
```

