# URM Master Architecture — Unified Relationship Management Platform

> **버전:** 2026-05-19 v2 (Phase 2 완료 반영 — person_firm_history 119 rows + 2 views + sync trigger 적용)
> **상태:** Foundational architecture document. starter kit 의 새 centerpiece.
> **읽는 순서:** **이 문서 → KICKOFF → PROJECT_CONTEXT → DB_SCHEMA_REFERENCE → GOTCHAS → safe_insert_templates**
> **이 문서의 역할:** URM 의 10 가지 핵심 원칙 + 통일 패턴 + Phase 별 실행 plan. 모든 다른 문서가 이걸 기반.

---

## 0. 이 문서가 답하는 본질 질문

> "투자자/정부지원사업/Sales 등 어떤 business 도 같은 포맷으로 추가할 수 있는 통일된 CRM 인프라를 어떻게 만드나?"

→ 답: **Module-based extensible architecture + 6 가지 universal building block + 명시적 phased migration**.

---

## 1. 사용자 정의 10 원칙 (Foundation)

| # | 원칙 | 함의 |
|--:|------|------|
| 1 | **다양한 business module 지원** — investor / govt_grant / sales / 기타 | `module_type` enum 확장 + 통일 profile 패턴 |
| 2 | **Party = Company 기준** — 일의 단위는 회사 | `parties` 가 모든 entity. company 가 root. |
| 3 | **Company 는 직원 보유** | `parent_party_id` self-FK 로 hierarchy |
| 4 | **직원은 lifecycle** (입사/퇴사/다중 firm) | `person_firm_history` 테이블 — 시간 축 |
| 5 | **Engagement/Meeting/Email/LinkedIn = 회사 기준 + 개인 정보** | engagement 는 firm.id, 개인은 participant |
| 6 | **개인 status — 휴직, 은퇴 등** | `parties.activity_status` enum 신설 |
| 7 | **LinkedIn 모델 — 동시 다수 firm 근무** | `person_firm_history.is_primary` boolean |
| 8 | **회사 중심 view + 개인 검색** | firm_dashboard view + person search 함수 |
| 9 | **개인 검색 시 — 현재 firm + 이력 모두** | `v_person_career_history` view |
| 10 | **개인 입력 시 dedup — 이름/전화 유사값** | `find_similar_persons()` 함수 + phone 컬럼 |

---

## 2. 핵심 아키텍처 컨셉

### 2.1 Layered Entity Model

```
Layer 1: parties (모든 entity 의 root — company + person 통합)
            │
            ├─ party_type 으로 구분: company / fund / organization / individual / government
            ├─ module 로 business context: investor / paper_mill / govt_grant / ...
            └─ parent_party_id 로 hierarchy (firm → employee)

Layer 2: {module}_profile  (firm-level 구조화)
         {module}_contact_profile  (person-level 구조화)
         meta tables  (subtype, seniority, role 등)

Layer 3: person_firm_history  (temporal — 누가 언제 어디 근무)

Layer 4: engagements (firm 단위 거래)
         engagement_participants (person 별 역할/시간 배분)

Layer 5: communications / meetings / email_tracking / linkedin_outreach
         (모두 party_id 로 attach — firm 또는 person)
```

### 2.2 Discriminator 규칙 (혼동 방지)

| 의미 | parties.module | parties.party_type | parent_party_id | profile 테이블 |
|------|---------------|-------------------|----------------|---------------|
| VC firm | `'investor'` | `'fund'`/`'organization'` | NULL | `investor_profile` |
| VC partner (GP/MD) | `'investor'` | `'individual'` | firm.id | `investor_partner_profile` |
| Paper mill firm | `'paper_mill'` | `'organization'` | NULL | `paper_mill_profile` (NEW) |
| Paper mill staff | `'paper_mill'` | `'individual'` | firm.id | `paper_mill_contact_profile` (NEW) |
| Govt grant agency | `'government_grant'` (NEW) | `'government'` | NULL | `government_grant_profile` (NEW) |
| Govt grant officer | `'government_grant'` | `'individual'` | firm.id | `government_grant_contact_profile` (NEW) |
| Sales prospect firm | `'sales'` | `'company'` | NULL | `sales_account_profile` (NEW) |
| Sales contact person | `'sales'` | `'individual'` | firm.id | `sales_contact_profile` (NEW) |
| Angel investor (개인) | `'investor'` | `'individual'` | NULL (standalone) | `investor_profile` 직접 연결 |

→ **단 하나의 규칙:** firm 은 `parent_party_id IS NULL`, 직원은 `parent_party_id = firm.id`.

---

## 3. 6 가지 Universal Building Blocks

새 business module 추가 시 **항상 이 6개 패턴 만 만들면 됨**:

### Block 1: `parties` row
- 이미 존재. 모든 module 공통.
- 필수: `organization_id`, `name`, `module`, `party_type`
- 통일된 필드: `country_code`, `website`, `linkedin_url`, `phone_normalized` (NEW), `industry_tags`, `interest_tags`, `relationship_score`, `activity_status` (NEW)

### Block 2: `{module}_profile` (firm-level)
- 1-to-1 with parties (party_id UNIQUE)
- module 별 구조화된 필드 (예: investor 의 AUM, paper_mill 의 main_products, govt_grant 의 funding_total)
- 통일 컬럼: `organization_id`, `party_id`, `created_at`, `updated_at`, `notes`, `module_data jsonb`

### Block 3: `{module}_contact_profile` (person-level)
- 1-to-1 with parties (party_id UNIQUE)
- module 별 person 속성 (예: investor 의 seniority, paper_mill 의 plant_role)
- 통일 컬럼: `firm_party_id`, `title_text`, `is_decision_maker`, `email`, `phone_e164`

### Block 4: `person_firm_history` (universal — 모든 module 공유)
- 한 사람의 다 firm 이력 — module 무관
- `role_category` (7 값): investor/employee/founder/advisor/board_member/consultant/other
- `is_primary` for multi-firm simultaneous
- 이미 설계됨 (`migration_person_firm_history_2026Q2.sql`)

### Block 5: `engagements` + `engagement_participants` (universal)
- `engagements`: firm 단위 거래 (party_id = firm.id, CHECK 강제)
- `engagement_participants` (NEW): person 별 role + time_allocation
- module 무관 — 모든 거래가 같은 구조

### Block 6: `communications` / `meetings` / `email_tracking` / 향후 `linkedin_outreach`
- 이미 존재 (linkedin_outreach 만 NEW)
- 모두 `party_id` 단일 FK — firm 또는 person 둘 다 가능
- 정책: outbound 는 person 에, 결과는 firm 에 attribute

---

## 4. 새 Module 추가 Cookbook — 3-step 패턴

새 business module 추가 시 SOP. 예: 사용자가 "**정부지원사업 module 추가**" 원할 때:

### Step 1: enum 확장
```sql
ALTER TYPE app.module_type ADD VALUE 'government_grant';
```

### Step 2: Profile 테이블 2개 생성
```sql
-- 2a. firm-level (정부 기관 / 지원 프로그램)
CREATE TABLE app.government_grant_profile (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id        uuid UNIQUE NOT NULL REFERENCES app.parties(id),
  organization_id uuid NOT NULL REFERENCES app.organizations(id),
  agency_type     text,                    -- 'federal' / 'state' / 'local'
  program_name    text,                    -- 'SBIR Phase II'
  funding_total_usd numeric,
  application_period_months int2,
  module_data     jsonb NOT NULL DEFAULT '{}',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- 2b. person-level (담당 공무원 등)
CREATE TABLE app.government_grant_contact_profile (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id        uuid UNIQUE NOT NULL REFERENCES app.parties(id),
  organization_id uuid NOT NULL REFERENCES app.organizations(id),
  firm_party_id   uuid NOT NULL REFERENCES app.parties(id),
  title_text      text,
  role_in_program text,                    -- 'program_officer' / 'reviewer' / 'manager'
  email           text,
  phone_e164      text,
  module_data     jsonb NOT NULL DEFAULT '{}',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
```

### Step 3: Helper 함수 (선택)
- `ingest.promote_government_grants(label)` — 적재 시 자동 dedup + normalization
- Investor 패턴 (`promote_investors`) 카피해 module 만 바꿈

→ **30분이면 새 business module 추가 완료**. 기존 모든 인프라 (engagement, communications, person_history, RLS, audit) 자동 재사용.

---

## 5. 현재 상태 vs 목표 상태 (Gap 진단)

| 영역 | 현재 | 목표 | Gap |
|------|------|------|:---:|
| `parties` 통일 entity | ✅ | ✅ | — |
| Investor profile (firm+person) | ✅ | ✅ | — |
| `person_firm_history` | ✅ 적용됨 (119 rows + sync trigger) | ✅ | — |
| **Paper mill profile (firm+person)** | ❌ module_data 만 | ✅ | **Phase 1** |
| **Filler profile (firm+person)** | ❌ module_data 만 | ✅ | **Phase 1** |
| **Engagement-participants 모델** | ❌ | ✅ | **Phase 3** |
| **`parties.activity_status` (휴직 등)** | ❌ `status` 는 entity_status (active/inactive/archived/blocked) — 휴직 표현 안 됨 | ✅ | **Phase 4** |
| **`parties.phone_e164` + dedup** | ❌ phone 컬럼 없음 | ✅ | **Phase 4** |
| **`find_similar_persons()` 함수** | ❌ | ✅ | **Phase 4** |
| **`government_grant` module** | ❌ | ✅ (예시) | **Phase 5** |
| **`sales` module profile** | 🟡 enum 만 있고 profile 없음 | ✅ | **Phase 5** |
| **Firm-centric reporting views** | 🟡 `v_investor_outreach_list` 만 | ✅ 모든 module | **Phase 6** |
| **Subtype meta tables** | ✅ investor + partner_seniority | ✅ 다른 module 도 확장 | Phase 1 곁가지 |

---

## 6. 6-Phase Implementation Plan

각 Phase 는 독립 실행 가능. 의존성 최소화.

### 🟢 Phase 0 — 기 완료 (이미 starter kit 에 반영됨)

- ✅ Phase 1+2 introspection (272 RLS / 5 views / 128 triggers / 451 indexes / 14 함수 본문)
- ✅ Partner 매핑 정정 (`module='investor'` + `party_type='individual'`)
- ✅ `investor_subtype_meta` + `partner_seniority_meta` (트라이링구얼)
- ✅ Footprint Coalition `direct_fit` 태그
- ✅ Outreach Top 30 시드 CSV

### 🟢 Phase 2 — person_firm_history (완료, 2026-05-19)

- ✅ `app.person_firm_history` 테이블 + 6 indexes + RLS 4 policies
- ✅ Backfill: investor_partner_profile 119 → person_firm_history 119
- ✅ Views: `v_person_career_history`, `v_firm_alumni`
- ✅ Trigger: `sync_parent_from_primary_firm()` — primary current 행을 parties.parent_party_id 로 동기화
- ✅ Sync 검증: synced=119 / no_parent=0 / mismatch=0
- ⚠️ 1900-fix 사후 적용: COALESCE + GREATEST(NULL, 1900) 버그로 joined_year IS NULL 인 87 행이 1900-01-01 로 적재됨 → UPDATE 로 2020-01-01 통일

### 🔵 Phase 1 — paper_mill / filler Profile 테이블 (대칭 회복)
**목적:** module_data jsonb 만 사용 → 구조화 profile 로 승격.

**산출물:**
- `app.paper_mill_profile` + `app.paper_mill_contact_profile` 신설
- `app.filler_supplier_profile` + `app.filler_supplier_contact_profile` 신설
- module_data → 컬럼 마이그레이션 (1,073 + 419 = 1,492 행)
- helper `ingest.promote_paper_mills` 신설
- view `v_paper_mill_firms` / `v_filler_suppliers`

**작업 시간:** 90-120분. paper_mill / filler 작업이 활발하다면 가장 가치 큰 phase.

### ✅ Phase 2 — person_firm_history (이력 추적) [DONE 2026-05-19]
이전 위치에 있던 Phase 2 의 SQL/산출물은 위 §6 Phase 0 바로 다음 "Phase 2 완료" 섹션에 통합. `migration_person_firm_history_2026Q2.sql` 은 적용 완료.

### 🔵 Phase 3 — engagement_participants (firm 중심 + 개인 attribution)
**목적:** 사용자 원칙 5 실현.

**산출물:**
- 현재 30 engagement 진단 (firm/person 분포)
- `engagements.party_id` 가 firm 만 가리키도록 CHECK + 마이그레이션
- `engagement_participants` 테이블 신설 (engagement_id + person_party_id + role + time_allocation)
- view `v_engagement_with_participants`

**작업 시간:** 60분.

### 🔵 Phase 4 — Person Status + Dedup + Phone
**목적:** 사용자 원칙 6, 10 실현.

**산출물:**
- `app.activity_status` enum 신설 (active, on_leave, retired, deceased, unknown)
- `parties.activity_status` 컬럼 추가
- `parties.phone_e164` + `phone_normalized` 컬럼 추가
- `app.normalize_phone()` 함수
- `app.find_similar_persons(name, phone, email)` 함수 — pg_trgm 활용
- view `v_person_dedup_candidates`

**작업 시간:** 60-90분.

### 🔵 Phase 5 — 새 Module 추가 (사용자 우선순위)
**목적:** 사용자 원칙 1 실현 — 새 business type 즉시 추가.

**후보 module:**
- `government_grant` (정부지원사업, SBIR 등)
- `sales` profile (현재 enum 만 있고 미정의)
- `manufacturing_partner` (외주 가공)
- 사용자 추가 요구

**산출물 (각 module 당):**
- Profile 테이블 2개 (firm + contact)
- Helper 함수
- View

**작업 시간:** 30-45분 per module.

### 🔵 Phase 6 — Unified Reporting Views
**목적:** 사용자 원칙 8 실현 — 회사 중심 dashboard.

**산출물:**
- `v_firm_dashboard` (universal — 모든 module 의 firm 활동 통합)
- `v_firm_pipeline` (engagement 단계별 가치)
- `v_firm_communication_summary` (firm 별 최근 outreach + 응답률)
- `v_module_health` (module 별 데이터 품질 / 분포)

**작업 시간:** 60-90분.

---

## 7. Phase 의존성 그래프

```
Phase 0 (DONE)
    │
    ├─→ Phase 1 (paper_mill/filler profile) ─┐
    │                                          │
    ├─→ Phase 2 (person_firm_history)  ───────┤ 
    │                                          │
    ├─→ Phase 4 (status + dedup + phone)──────┤
    │                                          │
    │   (Phase 1, 2, 4 모두 독립 — 병행 가능)  │
    │                                          ▼
    │                                       Phase 3 (engagement participants)
    │                                          │
    │                                          ▼
    │                                       Phase 5 (new modules)
    │                                          │
    │                                          ▼
    │                                       Phase 6 (reporting views)
```

→ **권장 순서:** Phase 1 + 2 + 4 병행 가능 (소형 PR 3개) → Phase 3 → Phase 5 → Phase 6.

→ **시간 최소 경로:** 가장 가치 큰 것부터 — Phase 2 (15분) → Phase 1 (120분) → Phase 4 (90분) → Phase 3 (60분) → ...

---

## 8. 사용자 검색 시나리오 (원칙 8, 9 시현)

### 8.1 "VC firm 만 보기"
```sql
SELECT firm_name, firm_aum_usd, COUNT(DISTINCT partner_id) AS partners
  FROM app.v_investor_outreach_list v
  JOIN app.investor_profile ip ON ip.party_id = v.firm_id
 WHERE ip.subtype = 'vc'
 GROUP BY firm_name, firm_aum_usd
 ORDER BY firm_aum_usd DESC NULLS LAST;
```

### 8.2 "한 회사의 전체 view" (firm 중심 dashboard — Phase 6)
```sql
-- v_firm_dashboard (목표 view)
SELECT 
  firm_name,
  module,
  current_employees_count,
  past_employees_count,
  active_engagements,
  recent_communications_30d,
  last_outreach_date,
  pipeline_value_usd
FROM app.v_firm_dashboard
WHERE firm_name = 'a16z';
```

### 8.3 "개인 검색 — 전체 이력" (Phase 2 시현)
```sql
SELECT 
  step,
  firm_name,
  title_text,
  role_category,
  joined_at,
  COALESCE(left_at::text, '현재') AS left_at,
  years_at_firm
FROM (
  SELECT 
    ROW_NUMBER() OVER (ORDER BY joined_at) AS step,
    *
  FROM app.v_person_career_history
  WHERE person_name ILIKE '%Joe Lonsdale%'
) sub
ORDER BY joined_at DESC;
```

### 8.4 "Dedup 시 유사인물 추천" (Phase 4 시현)
```sql
-- 새 person 입력 시 — 이름/전화/이메일 비교
SELECT * FROM app.find_similar_persons(
  p_name  := 'Joe Lonsdale',
  p_phone := '+15125551234',
  p_email := 'joe@example.com',
  p_threshold := 0.7
);
-- 결과: 유사도 점수 + 기존 party_id 반환 → UI 가 "추가" vs "기존 사용" 선택
```

---

## 9. 위험 + 완화 전략

| 위험 | 완화 |
|------|------|
| 1,492 paper_mill/filler 행 마이그레이션 시 데이터 손실 | 단계별 진행 + 전체 트랜잭션 + rollback 가능. module_data 는 보존 (병기) |
| 기존 production view (`v_investor_outreach_list`) 깨짐 | Hybrid 패턴 (parent_party_id cache 유지) + view 재작성 안 함 |
| 마이그레이션 중 app code 가 깨짐 | dev 환경 우선 적용 → 검증 → prod. backward-compatible 컬럼만 추가, 삭제 금지 |
| 사용자가 phase 순서 바뀌 원함 | 독립 phase 설계로 가능. 의존성 최소. |
| 새 module 추가 후 데이터 부족 | 별도 enrichment 세션 필요 (Phase 5 후) |

---

## 10. 새 세션 시작 시 — 이 문서 사용법

새 Claude 세션의 첫 작업:

1. **이 문서 §0-§4 읽기** (5분) — URM vision + 통일 패턴 파악
2. **§5 Gap 표 확인** — 현재까지 완료 상태
3. **§6 Phase plan 확인** — 어디 진행 중인지
4. **사용자에게 진행할 Phase 확인** — 또는 사용자가 직접 지정
5. **해당 Phase SQL 작성** — DB_SCHEMA_REFERENCE / GOTCHAS / safe_insert_templates 참고

새 Claude 가 vision 재설명 받을 필요 없음 — 모두 이 문서에.

---

## 11. 변경 이력

| 버전 | 날짜 | 변경 |
|------|------|------|
| v1 | 2026-05-19 | 사용자 10 원칙 + 6 building blocks + 6 phase plan 정립 |
| v2 | 2026-05-19 | Phase 2 (person_firm_history) 완료 반영 — §5 Gap 표 update + §6 Phase 2 ✅ DONE + 1900-fix postmortem |

---

## 12. 다음 액션 (현재 시점)

✅ **Phase 0 + Phase 2 완료** = URM 통일 패턴의 Layer 3 (temporal) 완성.
→ 다음: **Phase 1 (paper_mill / filler profile)** 진입 — 1,492 행을 module_data jsonb → 구조화 컬럼으로 승격. URM 통일 패턴 시현의 핵심 단계.

대안: Phase 4 (activity_status + phone + dedup), Phase 3 (engagement_participants).
권장 순서: Phase 1 → Phase 4 → Phase 3 → Phase 5 → Phase 6.
