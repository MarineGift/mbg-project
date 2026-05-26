# URM Master Architecture — Unified Relationship Management Platform

> **버전:** 2026-05-19 v4 (Phase 4 [A2] 완료 — activity_status + phone + 통합 dedup 인프라. Cat 4 acceptance 통과.)
> **상태:** Foundational architecture document. starter kit 의 centerpiece.
> **읽는 순서:** **이 문서 → KICKOFF → DB_SCHEMA_REFERENCE → GOTCHAS**
> **이 문서의 역할:** URM 의 10 가지 핵심 원칙 + 통일 패턴 + Phase 별 실행 plan.

---

## 0. 이 문서가 답하는 본질 질문

> "투자자/정부지원사업/Sales 등 어떤 business 도 같은 포맷으로 추가할 수 있는 통일된 CRM 인프라를 어떻게 만드나?"

→ 답: **Module-based extensible architecture + 7 가지 universal building block + 명시적 phased migration**.

---

## 1. 사용자 정의 10 원칙 (Foundation)

| # | 원칙 | 함의 | 구현 상태 |
|--:|------|------|:--:|
| 1 | 다양한 business module 지원 — investor / govt_grant / sales / 기타 | `module_type` enum 확장 + 통일 profile 패턴 | ✅ |
| 2 | Party = Company 기준 — 일의 단위는 회사 | `parties` 가 모든 entity. company 가 root. | ✅ |
| 3 | Company 는 직원 보유 | `parent_party_id` self-FK 로 hierarchy | ✅ |
| 4 | 직원은 lifecycle (입사/퇴사/다중 firm) | `person_firm_history` 테이블 — 시간 축 | ✅ Phase 2 |
| 5 | Engagement/Meeting/Email = 회사 기준 + 개인 정보 | engagement 는 firm.id, 개인은 participant | 🟡 Phase 3 |
| 6 | 개인 status — 휴직, 은퇴 등 | `parties.activity_status` enum | ✅ **Phase 4 [A2]** |
| 7 | LinkedIn 모델 — 동시 다수 firm 근무 | `person_firm_history.is_primary` boolean | ✅ Phase 2 |
| 8 | 회사 중심 view + 개인 검색 | firm_dashboard view + person search 함수 | 🟡 Phase 6 |
| 9 | 개인 검색 시 — 현재 firm + 이력 모두 | `v_person_career_history` view | ✅ Phase 2 |
| 10 | 개인 입력 시 dedup — 이름/전화 유사값 | `find_similar_persons()` 함수 + phone 컬럼 | ✅ **Phase 4 [A2]** |

---

## 2. 핵심 아키텍처 컨셉

### 2.1 Layered Entity Model

```
Layer 1: parties (모든 entity 의 root — company + person 통합)
            │
            ├─ party_type 으로 구분: company / fund / organization / individual / government
            ├─ module 로 business context: investor / paper_mill / govt_grant / ...
            ├─ parent_party_id 로 hierarchy (firm → employee, group_hq → country_entity → plant)
            └─ activity_status 로 person lifecycle  (NEW Phase 4)

Layer 2: {module}_profile  (firm-level 구조화)
         {module}_contact_profile  (person-level 구조화)
         meta tables  (subtype, seniority, role 등)

Layer 3: person_firm_history  (temporal — 누가 언제 어디 근무)

Layer 4: engagements (firm 단위 거래)
         engagement_participants (person 별 역할/시간 배분)   ← Phase 3 TODO

Layer 5: communications / meetings / email_tracking / linkedin_outreach
         (모두 party_id 로 attach — firm 또는 person)

Layer 6: dedup infra  (NEW Phase 4)
         find_similar_parties() + find_similar_persons() 함수
         v_party_dedup_candidates + v_person_dedup_candidates view
         phone_normalized + GIN trgm index
```

### 2.2 Discriminator 규칙 (혼동 방지)

| 의미 | parties.module | parties.party_type | parent_party_id | profile 테이블 |
|------|---------------|-------------------|----------------|---------------|
| VC firm | `'investor'` | `'fund'`/`'organization'` | NULL | `investor_profile` |
| VC partner (GP/MD) | `'investor'` | `'individual'` | firm.id | `investor_partner_profile` |
| Paper mill firm | `'paper_mill'` | `'organization'` | NULL | `paper_mill_profile` (NEW) |
| Paper mill staff | `'paper_mill'` | `'individual'` | firm.id | `paper_mill_contact_profile` (NEW) |
| Filler firm | `'filler'` | `'organization'` | optional (3-tier) | `filler_supplier_profile` |
| Filler contact | `'filler'` | `'individual'` | firm.id | `filler_supplier_contact_profile` |
| Govt grant agency | `'government_grant'` (NEW) | `'government'` | NULL | `government_grant_profile` (NEW) |
| Govt grant officer | `'government_grant'` | `'individual'` | firm.id | `government_grant_contact_profile` (NEW) |
| Sales prospect firm | `'sales'` | `'company'` | NULL | `sales_account_profile` (NEW) |
| Sales contact person | `'sales'` | `'individual'` | firm.id | `sales_contact_profile` (NEW) |
| Angel investor (개인) | `'investor'` | `'individual'` | NULL (standalone) | `investor_profile` 직접 연결 |

→ **단 하나의 규칙:** firm 은 `parent_party_id IS NULL`, 직원은 `parent_party_id = firm.id`.

### 2.3 3-Tier Industry Hierarchy (Phase 1 + A3 발견)

filler module 에 부분 적용된 group_hq → country_entity → plant 패턴.

```
group_hq         (e.g. "Omya (HQ)", "Specialty Minerals (HQ)")
  parent_party_id = NULL
  party_level = 'group_hq'
       │
       ├─ country_entity      (e.g. "Omya (USA)", "Specialty Minerals (Korea)")
       │   parent_party_id = group_hq.id
       │   party_level = 'country_entity'
       │     │
       │     └─ plant         (e.g. "Specialty Minerals (USA - Adams MA)")
       │         parent_party_id = country_entity.id
       │         party_level = 'plant'
       │
       └─ ...
```

**현재 적용 상태 (filler 235 active):**
- Specialty Minerals: 1 HQ + 45 country + 49 plant (fully linked) ✓
- Omya: 1 HQ + 38 country (plant 없음) (fully linked) ✓
- **Imerys**: 38 행이 모두 그냥 "Imerys" (country_code 만 다름) — Cat 1 cleanup target 🔴
- **Schaefer Kalk**: 12 행 모두 "Schaefer Kalk" — Cat 1 🔴
- **Carmeuse**: 3 distinct 행 — Cat 1 🔴

---

## 3. 7 가지 Universal Building Blocks

새 business module 추가 시 **항상 이 7개 패턴 만 만들면 됨**:

### Block 1: `parties` row
- 이미 존재. 모든 module 공통.
- 필수: `organization_id`, `name`, `module`, `party_type`
- 통일된 필드: `country_code`, `website`, `linkedin_url`, `phone_e164`, `phone_normalized` (NEW Phase 4), `industry_tags`, `interest_tags`, `relationship_score`, `activity_status` (NEW Phase 4)

### Block 2: `{module}_profile` (firm-level)
- 1-to-1 with parties (party_id UNIQUE)
- module 별 구조화된 필드 (예: investor 의 AUM, filler 의 supplier_type, govt_grant 의 funding_total)
- 통일 컬럼: `organization_id`, `party_id`, `created_at`, `updated_at`, `notes`, `module_data jsonb`

### Block 3: `{module}_contact_profile` (person-level)
- 1-to-1 with parties (party_id UNIQUE)
- module 별 person 속성 (예: investor 의 seniority, filler 의 plant_role)
- 통일 컬럼: `firm_party_id`, `title_text`, `is_decision_maker`, `email`, `phone_e164`

### Block 4: `person_firm_history` (universal — 모든 module 공유, ✅ Phase 2 적용)
- 한 사람의 다 firm 이력 — module 무관
- `role_category` (7 값): investor/employee/founder/advisor/board_member/consultant/other
- `is_primary` for multi-firm simultaneous
- 자동 sync trigger: primary + current 행을 `parties.parent_party_id` 로 자동 동기화

### Block 5: `engagements` + `engagement_participants` (universal, 🟡 Phase 3 TODO)
- `engagements`: firm 단위 거래 (party_id = firm.id, CHECK 강제)
- `engagement_participants`: person 별 role + time_allocation
- module 무관 — 모든 거래가 같은 구조

### Block 6: `communications` / `meetings` / `email_tracking` / `linkedin_outreach`
- 이미 존재 (linkedin_outreach 만 NEW)
- 모두 `party_id` 단일 FK — firm 또는 person 둘 다 가능
- 정책: outbound 는 person 에, 결과는 firm 에 attribute

### Block 7: ⭐ **Dedup infra (NEW Phase 4 [A2])**
- `app.normalize_phone(text)` — IMMUTABLE, digits-only
- `app.find_similar_parties(...)` — generic (firm + person), name trgm + phone exact
- `app.find_similar_persons(...)` — wrapper (party_type=individual)
- `app.v_party_dedup_candidates` — pair list, recursive root + 3 단계 자동 제외
- `app.v_person_dedup_candidates` — wrapper
- 사용 패턴: **새 entity 적재 전 사전 확인** + **주기적 dedup audit**

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
  agency_type     text,
  program_name    text,
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
  role_in_program text,
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

### Step 4 (NEW): Dedup 사전 검증 패턴
```sql
-- 새 정부 기관 적재 전 중복 확인
SELECT * FROM app.find_similar_parties(
  p_name => 'New Agency Name',
  p_module => 'government_grant'::app.module_type,
  p_threshold => 0.5
);
-- → 결과 검토 후 진행
```

→ **30-45분이면 새 business module 추가 완료**. 기존 모든 인프라 (engagement, communications, person_history, RLS, audit, **dedup**) 자동 재사용.

---

## 5. 현재 상태 vs 목표 상태 (Gap 진단)

| 영역 | 현재 | 목표 | Gap |
|------|------|------|:---:|
| `parties` 통일 entity | ✅ | ✅ | — |
| Investor profile (firm+person) | ✅ | ✅ | — |
| `person_firm_history` | ✅ (119 rows, sync trigger) | ✅ | — |
| **Paper mill profile** | 🟡 보류 (V11.4 sector-bucket data) | 미래 ingest | **데이터 부재** |
| **Filler supplier profile** | ✅ (235 rows + view) + 3-tier 부분 적용 | ✅ + 3-tier 전체 | **Cat 1 cleanup** |
| **Engagement-participants** | ❌ | ✅ | **Phase 3** |
| **`parties.activity_status`** | ✅ | ✅ | — (Phase 4 적용) |
| **`parties.phone_e164` + dedup** | ✅ | ✅ | — (Phase 4 적용) |
| **`find_similar_persons()` 함수** | ✅ | ✅ | — (Phase 4 적용) |
| **Dedup view 인프라** | ✅ | ✅ | — (Phase 4 적용) |
| **`government_grant` module** | ❌ | ✅ | **Phase 5** |
| **`sales` module profile** | 🟡 enum 만 있고 profile 없음 | ✅ | **Phase 5** |
| **Firm-centric reporting views** | 🟡 (`v_investor_outreach_list` 만) | ✅ 모든 module | **Phase 6** |

---

## 6. 6-Phase Implementation Plan

### 🟢 Phase 0 — 완료
- ✅ introspection (31 enums / 41 functions / 272 RLS / 5 views / 128 triggers / 451 indexes)
- ✅ Partner 매핑 정정
- ✅ `investor_subtype_meta` + `partner_seniority_meta` (트라이링구얼)
- ✅ Outreach Top 30 시드 CSV

### 🟢 Phase 2 — 완료 (person_firm_history)
- ✅ `app.person_firm_history` + 6 indexes + RLS 4 policies + 2 views
- ✅ Trigger: `sync_parent_from_primary_firm()` 자동 동기화
- ✅ Sync 검증: synced=119 / mismatch=0
- ⚠️ 1900-fix (GREATEST NULL 함정)

### 🟢 Phase 1 (filler) — 완료 + A3 추가 cleanup
- ✅ Cleanup 414 → 260 (Phase 1) → 235 (A3 추가)
- ✅ `filler_supplier_profile` (235 rows) + `filler_supplier_contact_profile` (schema)
- ✅ View `v_filler_suppliers` + RLS + trigger
- 💡 3-tier hierarchy 부분 적용 — Specialty (95) + Omya (39) 만. **Imerys 38 / Schaefer 12 / Carmeuse 3 은 Cat 1 cleanup 대기.**

### 🟡 Phase 1 (paper_mill) — 보류 (V11.5 ingest 들어올 때까지)

### ✅ **Phase 4 [A2] — 완료 (2026-05-19, 이 세션)**

**산출물:**
- `app.activity_status` enum (active/on_leave/retired/deceased/unknown)
- `parties` 컬럼 3개: `activity_status` / `phone_e164` / `phone_normalized`
- GIN trgm + B-tree partial index 3개 (모두 WHERE deleted IS NULL)
- 함수 3개: `normalize_phone()` / `find_similar_parties()` / `find_similar_persons()`
- View 2개: `v_party_dedup_candidates` (recursive root + 3 단계 제외) / `v_person_dedup_candidates`

**Acceptance test 통과:**
- Cat 4 (EGM 1.00 / Q-min 0.88 / Mikron-S 0.79) 자동 발견 ✓
- Specialty Minerals 363 → 0 (recursive root 제외) ✓

**즉시 가치 발견 3 종:**
1. investor / individual 3 pair: Brian Smith 동명이인 / Lior Susan multi-firm 가능성 / Heather-Mack false positive
2. filler Cat 4 표기 변형 3 쌍 (EGM, Q-min, Mikron-S)
3. **Imerys 38 행 mass-duplicate (703 pair) — Cat 1 cleanup 명확한 target**

### 🔴 다음 Phase — Cat 1 cleanup (Imerys / Schaefer Kalk / Carmeuse, 45-60분)

A2 dedup view 가 발견한 명확한 cleanup target. 작업:

1. **HQ 신설** — 3 firm 각각의 group_hq row 생성
2. **38 Imerys / 12 Schaefer / 3 Carmeuse duplicate row** 처리:
   - 의미 있는 country_entity 로 transform 또는 일부 soft-delete
3. **`parent_party_id` linking** — Specialty/Omya 패턴 복제
4. **검증** — A2 dedup view 의 Imerys 703 pair 가 ~0 으로 감소 확인

### 🔴 Phase 3 — engagement_participants (60분)
- `app.engagements` + `app.engagement_participants` 테이블 신설
- meeting / email / linkedin_outreach 와의 attribution 통일
- view: `v_firm_engagement_summary`, `v_person_engagement_contribution`

### 🔴 Phase 5 — 새 module (govt_grant, sales) 추가 (30-45분 each)
- URM_MASTER §4 Cookbook 그대로 적용
- govt_grant enum value 추가 + profile 2개 + dedup view 활용

### 🔴 Phase 6 — Unified reporting views (60-90분)
- `v_firm_dashboard` (모든 module)
- `v_person_dashboard`
- `v_pipeline_by_module`
- `v_dedup_audit` (주기적 검토용)

### 🟡 보너스 작업
- (1) `ingest.promote_filler_suppliers` helper (30분, 새 filler 적재 시)
- (2) Lior Susan multi-firm merge (15분, LinkedIn 검증 후)
- (3) 중복 trigram index 정리 — `idx_parties_name_normalized` (구) vs `_trgm` (신) (5분)

---

## 7. Phase 의존성 그래프

```
Phase 0 ──┬─→ Phase 2 ──→ (Phase 1 paper_mill 보류)
          ├─→ Phase 1 (filler) ──→ Cat 1 cleanup ──┐
          └─→ Phase 4 [A2] ────────────────────────┴──→ Phase 5 (new modules)
                  │                                                │
                  └─→ Phase 3 (engagement_participants) ────────────┴──→ Phase 6 (reporting)
```

핵심 path: **Phase 0 → Phase 2 → Phase 4 ✅ → Cat 1 cleanup → Phase 3 → Phase 6**

---

## 8. 핵심 안전 원칙 (모든 Phase 공통)

1. 🔴 **새 entity 적재 전 dedup 사전 확인** — `app.find_similar_parties()` 호출
2. 🔴 **한국 본사 firm 적재 금지** (단, 외국 본사의 KR variant 는 OK)
3. 🔴 **VC partner 적재 시** `module='investor'` + `party_type='individual'` + `parent_party_id`
4. 🟢 **Idempotent 마이그레이션** — `CREATE OR REPLACE` / `IF NOT EXISTS` / `DO $$ guard` 패턴
5. 🟢 **Soft-delete 우선** — `deleted_at = now()` + `notes` cleanup 사유
6. 🟢 **트랜잭션 BEGIN-COMMIT** 모든 schema/data 변경에
7. 🟢 **PostgreSQL GREATEST NULL 함정 주의** — COALESCE fallback 안 됨
8. 🟢 **systemic ingest bug scan** — 새 module 적용 전 컬럼 misuse 확인

→ URM 의 통일성 보장 + 사용자 본인 활동 안전 보장.
