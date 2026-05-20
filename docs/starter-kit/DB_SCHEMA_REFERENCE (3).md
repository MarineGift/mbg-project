# DB_SCHEMA_REFERENCE — URM Platform (mbg-project)

> **버전:** 2026-05-19 v2.3 (Phase 1 filler 완료 — filler_supplier_profile 260 rows + filler_supplier_contact_profile + v_filler_suppliers view)
> **DB:** Supabase Postgres
> **조직 ID:** `b25de8f2-1020-482f-9012-183f63883169` (MBG Project)
> **이 문서의 용도:** SQL 작성 전 5분 훑어보고 함정 회피. 모든 INSERT/UPSERT 작성 시 NOT NULL/CHECK/FK/UNIQUE 확인.

**검증 결과 (누적):**
- v1 → v2 (Phase 1): 28 enums + functions 없음 → 31 enums + 41 functions
- v2 → v2.1 (Phase 2 introspection): 451 indexes, 128 triggers, 272 RLS policies, 5 views, 14 함수 본문 분석
- v2.1 → v2.2 (Phase 2 적용): `person_firm_history` 119 rows + `v_person_career_history` + `v_firm_alumni` + `sync_parent_from_primary_firm` trigger
- v2.2 → v2.3 (Phase 1 filler 적용): `filler_supplier_profile` 260 rows + `filler_supplier_contact_profile` 0 rows + `v_filler_suppliers` view + filler module cleanup (414 → 260)
- ⭐ **partner 매핑 정정:** investor side person 은 `module='investor'` + `party_type='individual'` (이전 표기 `module='partner'` 는 오류 — §3 `app.parties` 카드 참조)

---

## 0. 한눈 요약

| 항목 | 값 |
|------|---|
| 전체 relations (app + ingest) | **87 base tables + 8 views = 95** |
| ┗ app schema | 85 base tables + 6 views |
| ┗ ingest schema | 2 base tables + 2 views |
| 전체 컬럼 | 1,605 (Phase 1+2 추가분 포함) |
| 전체 FK | 302 (filler_supplier_profile + contact_profile FK 추가) |
| 전체 enum 타입 | **30 (app) + 1 (public) = 31** |
| Semantic CHECK 제약 (not_null 제외) | 124+ |
| 함수 (app + ingest) | **27 + 15 = 42** |
| Multi-tenant 테이블 (org_id 보유, FK 여부 무관) | 77/95 |
| Soft-delete 테이블 (deleted_at 보유) | 35 |

⚠️ **이전 v2 doc 의 오류 정정 (GPT-5.5 Pro 검증):** 이전에 "85 + 2 = 87 base tables" 라고 적혀 있던 것은 잘못이었습니다. `01_tables.csv` 의 app 85개는 base 82 + views 3 을 모두 포함한 숫자였습니다. 정확한 base 합계는 v2.1 기준 84개, views 5개였습니다. v2.2 부터 Phase 2 가 +1 base (person_firm_history) + 2 views (v_person_career_history, v_firm_alumni) 추가. v2.3 부터 Phase 1 filler 가 +2 base (filler_supplier_profile, filler_supplier_contact_profile) + 1 view (v_filler_suppliers) 추가.

### 데이터 규모 (2026-05-19 v2.3)

| 테이블 | rows |
|--------|-----:|
| `app.parties` | ~1,609 (filler cleanup 134 soft-delete 반영) |
| `app.investor_portfolio_companies` | 445 |
| `app.portfolio_companies` | 342 |
| `app.filler_supplier_profile` ⭐ NEW | **260** |
| `app.filler_supplier_contact_profile` ⭐ NEW | **0** (schema-only) |
| `app.investor_partner_profile` | 119 |
| `app.person_firm_history` | 119 |
| `app.investor_profile` | 111 |
| `app.investor_subtype_meta` | 10 |
| `app.partner_seniority_meta` | 6 |
| `ingest.rows` | 180 |
| `ingest.runs` | 15 |
| `ingest.failed_rows` | 1 |

**parties.module 분포 (cleanup 후):**

```
paper_mill:        ~1,070  (변동 없음, 보류 상태)
filler:               260  (414 → cleanup 134)
investor:             243
partner:               15
customer:              14
filler_supplier:        0  (enum 만 있고 데이터 없음)
crowdfunding, product_launch, sales: 0 또는 소수
```

---

## 1. 핵심 패턴 (모든 작업 전 숙지)

### 1.1 Multi-tenancy: `organization_id` 는 거의 모든 테이블의 NOT NULL **tenant key**
74개 테이블이 `organization_id` 컬럼 보유. INSERT 시 **항상 명시적으로 채움**.
조직 ID: `'b25de8f2-1020-482f-9012-183f63883169'::uuid` (MBG Project)

⚠️ **NOT NULL ≠ FK 항상 함의 아님 (GPT-5.5 검증).** 다음 테이블은 `organization_id` 가 NOT NULL 이지만 명시적 FK 가 안 걸려 있습니다:
- `app.portfolio_companies.organization_id`
- `app.investor_partner_profile.organization_id`
- `app.plant_supply_links.organization_id`
- `ingest.runs.organization_id`

→ 의미: 오타로 잘못된 UUID 를 넣어도 DB 가 막아주지 않음. **반드시 상수 `'b25de8f2-...'::uuid` 사용**.

조직 ID 없는 15개: organizations 자체, email_sequence_* 군 (단 일부는 `org_id` 라는 alias 컬럼 보유 — Section 1.8 참고), email_tracking_*, permissions, role_permissions, ingest.rows, 모든 view (v_*).

### 1.2 Soft delete: `deleted_at IS NULL` 필터 항상 권장
32개 테이블이 `deleted_at timestamptz` 컬럼 보유. 활성 행만 보려면 `WHERE deleted_at IS NULL`.

### 1.3 Denormalized link tables (이번에 부딪힌 함정)
일부 link 테이블은 FK 외에 **denormalized 컬럼**을 NOT NULL 로 보유:
- `app.investor_portfolio_companies.portfolio_company_name` (NOT NULL) ⭐
- `portfolio_company_id` 는 nullable FK (quick-mode 적재 허용)

→ INSERT 시 FK 만 넣으면 NOT NULL 위반. **name 도 같이 박을 것**.
→ **하지만 더 좋은 방법:** `ingest.upsert_portfolio_company(...)` 함수 사용 (Section 7 참고).

### 1.4 `module_type` enum 으로 다중 도메인 통합
한 `app.parties` 테이블에서 module 값으로 도메인 구분.
**현재 허용값 (9개):** `investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier`

⭐ **`investor_partner` 는 enum 에 없음 (Phase 2 확인 완료).** 두 컨텍스트가 별도로 존재:

| 컨텍스트 | 컬럼 타입 | 사용값 | 의미 |
|---------|---------|-------|------|
| `parties.module` | `app.module_type` enum (9 값) | `'investor'` ⭐ | investor side 의 firm + partner 모두 (partner 는 `party_type='individual'` 로 구분) |
| `ingest.runs.module` | text (자유) | `'investor_partner'` | partner 적재 run 의 식별자 (text 리터럴) |

→ 즉 `'investor_partner'::app.module_type` 같은 **enum cast 는 항상 에러**. SCHEMA_GOTCHAS §10.1 + PROJECT_CONTEXT §10 참조.

### 1.5 자동 처리 trigger 들 (Phase 2 검증 완료)

⭐ Phase 2 introspection 으로 모두 production binding 확인됨. 수동 INSERT 시 비워두면 자동 처리:

| Trigger 함수 | 부착 테이블 | 효과 |
|-------------|-----------|------|
| `parties_set_normalized()` | `app.parties` (BEFORE INSERT/UPDATE) | `name_normalized` 자동 set |
| `set_updated_at()` | 60+ 테이블 (BEFORE UPDATE) | `updated_at = NOW()` |
| `communications_touch_engagement()` | `app.communications` (AFTER INSERT) | 관련 engagement 갱신 |
| `engagements_record_stage_change()` | `app.engagements` (AFTER UPDATE) | stage_history 자동 기록 |
| `check_party_supply_link()` | `app.party_supply_links` (BEFORE) | 사전 검증 — ⚠️ `plant_supply_links` 에는 부착 안 됨 |
| `tasks_set_completed_at()` | `app.tasks` (BEFORE INSERT/UPDATE) | `status='done'` 시 `completed_at` 자동 |
| `fn_auto_link_inbound_reply()` | `app.communications` (AFTER INSERT) | 이메일 인바운드 자동 link |
| `log_change()` | 50+ 테이블 (AFTER INSERT/UPDATE/DELETE) | 감사 추적 |
| `sync_parent_from_primary_firm()` ⭐ NEW | `app.person_firm_history` (AFTER INSERT/UPDATE) | primary+current 행을 `parties.parent_party_id` 로 동기화 (Phase 2 적용) |
| `set_updated_at()` | `app.filler_supplier_profile` + `app.filler_supplier_contact_profile` (BEFORE UPDATE) | Phase 1 새 테이블 2개에 부착 |

⚠️ **trigger 부재 테이블 (주의):**
- `app.portfolio_companies` — `name_normalized` 자동 처리 trigger 없음. 수동 set 또는 `ingest.upsert_portfolio_company()` 사용
- `app.plant_supply_links` — `check` trigger 없음 + RLS off + id no-default = 3중 risk
- `app.email_templates` — trigger 0 + RLS off (감사 추적 안 됨)

### 1.6 `module_data jsonb` 확장 패턴
5개 테이블 (parties, portfolio_companies 등) 이 `module_data jsonb DEFAULT '{}'` 보유.
모듈별 추가 필드를 정규화 없이 박을 수 있는 escape hatch.

### 1.7 Ingest layer: 2단계 적재 + helper 함수
- `ingest.runs` (UNIQUE `label`) — run metadata
- `ingest.rows` — staged payloads (jsonb) + status
- `ingest.promote_investors(label)` / `promote_investor_partners(label)` → app 테이블 promote
- **`ingest.rollback_run(label, true)` 로 안전 롤백 가능** ⭐ (몰랐던 안전장치)

---

## 2. Enum 카탈로그 (31개 전체)

| Schema | Enum | 허용 값 |
|--------|------|---------|
| `app` | `attendee_response` | no_response, accepted, declined, tentative |
| `app` | `attendee_role` | organizer, required, optional, resource |
| `app` | `calendar_provider` | google, microsoft, internal |
| `app` | `calendar_sync_status` | pending, syncing, success, partial, failed |
| `app` | `channel_type` | email, phone, sms, linkedin, kakaotalk, wechat, whatsapp, in_person, video_call, webform, other, slack |
| `app` | `consultation_channel` | inbound_email, meeting_notes, phone_call, manual_entry, attachment |
| `app` | `decision_role` | champion, decision_maker, influencer, gatekeeper, user, unknown |
| `app` | `dedup_status` | pending, auto_merged, manual_merged, rejected_duplicate, kept_separate |
| `app` | `direction_type` | inbound, outbound, internal |
| `app` | `engagement_status` | open, in_progress, on_hold, won, lost, archived |
| `app` | `entity_status` | active, inactive, archived, blocked |
| `app` | `event_status` | confirmed, tentative, cancelled |
| `app` | `investor_subtype` | vc, cvc, growth_equity, private_equity, family_office, accelerator, angel, crowdfunding, government, other |
| `app` | `invoice_status` | draft, issued, partial_paid, paid, overdue, void |
| `app` | `meeting_mode` | in_person, video_call, phone_call, hybrid |
| `app` | `meeting_status` | scheduled, completed, cancelled, no_show, rescheduled |
| `app` | `meeting_type` | intro, discovery, pitch, negotiation, due_diligence, kickoff, review, closing, other |
| `app` | `module_type` | investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier |
| `app` | `order_status` | draft, confirmed, in_production, ready_to_ship, shipped, delivered, cancelled, returned |
| `app` | `partner_seniority` | founder, partner, principal, associate, advisor, other |
| `app` | `party_type` | company, organization, individual, fund, government |
| `app` | `pipeline_stage_type` | lead, qualified, proposal, negotiation, won, lost |
| `app` | `priority_level` | low, medium, high, urgent |
| `app` | `scraping_job_status` | queued, running, completed, failed, cancelled, rate_limited |
| `app` | `scraping_source_type` | industry_directory, public_disclosure, company_website, gleif_lei, sec_edgar, dart_kr, press_release, other |
| `app` | `strategy_status` | draft, active, completed, abandoned |
| `app` | `strategy_type` | immediate, short_term, long_term |
| `app` | `task_status` | todo, in_progress, blocked, done, cancelled |
| `app` | `template_status` | draft, active, archived, deprecated |
| `app` | `tier_level` | tier_1, tier_2, tier_3, tier_4, tier_5 |
| `public` | `tier_role` | HQ, Regional, Country, Plant |

**중요 enum 사용처:**
- `app.module_type` — 10 컬럼에서 사용. 모든 cross-domain 통합의 기반.
- `app.investor_subtype` — 2 컬럼 (`investor_profile.subtype` 등). VC/CVC/등 분류.
- `app.partner_seniority` — 2 컬럼. founder/partner/principal 등.
- `app.party_type` — 1 컬럼. `parties.party_type` (company/fund/individual/...).
- `app.priority_level` — 8 컬럼. 우선순위 표준화.
- `app.tier_level` — 1 컬럼. `parties.tier` (tier_1~5).
- `public.tier_role` — **`parties.party_level` 과 별개 4-tier** (HQ/Regional/Country/Plant). 미사용일 가능성 / 향후 사용 예정일 수 있음.

---

## 3. 핵심 테이블 카드 (10개)

각 카드: 모든 컬럼 + NN 표시 + CHECK + FK + UNIQUE. ⚠️ = NOT NULL no-default (INSERT 필수).


### `app.parties`  *(rows: 1764)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `organization_id, name, module`

⭐ **module + party_type 조합 → 엔티티 의미 결정 (Phase 2 production 확정):**

| 의미 | `module` | `party_type` | `parent_party_id` | profile 테이블 |
|------|---------|-------------|------|-----------|
| VC firm | `'investor'` | `'fund'` 또는 `'organization'` | NULL | `investor_profile` |
| **VC 측 partner (GP/MD)** | `'investor'` ⭐ | `'individual'` | firm.id | `investor_partner_profile` |
| Paper mill firm | `'paper_mill'` | `'organization'` | NULL | (별도 industry FK) |
| Filler supplier | `'filler_supplier'` | `'organization'` | NULL | (별도 industry FK) |
| 일반 공급망 partner | `'partner'` | `'company'/'individual'` | optional | `partner_profile` |

→ `module='partner'` 은 **공급망 파트너 전용**. VC GP 는 `module='investor'` + `party_type='individual'` + `parent_party_id=firm.id` 사용.

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `organization_id` | uuid | ⚠️ |  |
| 3 | `name` | text | ⚠️ |  |
| 4 | `name_normalized` | text |  |  |
| 5 | `legal_name` | text |  |  |
| 6 | `party_type` | party_type | ✓ | `'company'::app.party_type` |
| 7 | `module` | module_type | ⚠️ |  |
| 8 | `country_code` | text |  |  |
| 9 | `region` | text |  |  |
| 10 | `city` | text |  |  |
| 11 | `address` | text |  |  |
| 12 | `timezone` | text |  |  |
| 13 | `website` | text |  |  |
| 14 | `domain_normalized` | text |  |  |
| 15 | `linkedin_url` | text |  |  |
| 16 | `industry_tags` | text[] | ✓ | `'{}'::text[]` |
| 17 | `interest_tags` | text[] | ✓ | `'{}'::text[]` |
| 18 | `employee_count` | integer |  |  |
| 19 | `annual_revenue_usd` | numeric |  |  |
| 20 | `lei_code` | text |  |  |
| 21 | `tax_id` | text |  |  |
| 22 | `tier` | tier_level | ✓ | `'tier_3'::app.tier_level` |
| 23 | `status` | entity_status | ✓ | `'active'::app.entity_status` |
| 24 | `relationship_score` | integer |  |  |
| 25 | `module_data` | jsonb | ✓ | `'{}'::jsonb` |
| 26 | `source` | text |  |  |
| 27 | `source_external_id` | text |  |  |
| 28 | `owner_user_id` | uuid |  |  |
| 29 | `owner_team_id` | uuid |  |  |
| 30 | `notes` | text |  |  |
| 31 | `created_at` | timestamptz | ✓ | `now()` |
| 32 | `updated_at` | timestamptz | ✓ | `now()` |
| 33 | `created_by` | uuid |  |  |
| 34 | `updated_by` | uuid |  |  |
| 35 | `deleted_at` | timestamptz |  |  |
| 36 | `industry_paper_company_id` | bigint |  |  |
| 37 | `industry_filler_supplier_id` | bigint |  |  |
| 38 | `parent_party_id` | uuid |  |  |
| 39 | `party_level` | text |  |  |
| 40 | `industry_paper_mill_id` | bigint |  |  |
| 41 | `founded_year` | integer |  |  |

**UNIQUE / PK:**

- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `created_by` → `app.users.id`
- `organization_id` → `app.organizations.id`
- `owner_team_id` → `app.teams.id`
- `owner_user_id` → `app.users.id`
- `parent_party_id` → `app.parties.id`
- `updated_by` → `app.users.id`

**FK in:** 32 테이블에서 참조. 주요: `app.buyer_inquiries`, `app.buyer_profile`, `app.calendar_events`, `app.campaign_backers`, `app.communications`, `app.consultations`, `app.contacts`, `app.customer_profile` +24 more


**Semantic CHECK 제약:**

- `((country_code IS NULL) OR (length(country_code) = 2))`
- `(party_level = ANY (ARRAY['group_hq'::text, 'country_entity'::text, 'plant'::text]))`
- `((founded_year IS NULL) OR ((founded_year >= 1500) AND (founded_year <= 2200)))`
- `((relationship_score >= 0) AND (relationship_score <= 100))`
- `((industry_paper_company_id IS NULL) OR (industry_filler_supplier_id IS NULL))`

---

### `app.investor_profile`  *(rows: 111)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `party_id, organization_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `party_id` | uuid | ⚠️ |  |
| 3 | `organization_id` | uuid | ⚠️ |  |
| 4 | `fund_name` | text |  |  |
| 5 | `fund_size_usd` | numeric |  |  |
| 6 | `fund_vintage_year` | integer |  |  |
| 7 | `investment_stages` | text[] | ✓ | `'{}'::text[]` |
| 8 | `ticket_min_usd` | numeric |  |  |
| 9 | `ticket_max_usd` | numeric |  |  |
| 10 | `sector_focus` | text[] | ✓ | `'{}'::text[]` |
| 11 | `geographic_focus` | text[] | ✓ | `'{}'::text[]` |
| 12 | `is_lead_investor` | boolean | ✓ | `false` |
| 13 | `is_strategic` | boolean | ✓ | `false` |
| 14 | `created_at` | timestamptz | ✓ | `now()` |
| 15 | `updated_at` | timestamptz | ✓ | `now()` |
| 16 | `created_by` | uuid |  |  |
| 17 | `updated_by` | uuid |  |  |
| 18 | `subtype` | investor_subtype |  |  |
| 19 | `aum_usd` | numeric |  |  |

**UNIQUE / PK:**

- 🔒 UQ `(party_id)`
- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `created_by` → `app.users.id`
- `organization_id` → `app.organizations.id`
- `party_id` → `app.parties.id`
- `updated_by` → `app.users.id`


**Semantic CHECK 제약:**

- `((fund_vintage_year >= 1980) AND (fund_vintage_year <= 2100))`
- `((ticket_max_usd IS NULL) OR (ticket_min_usd IS NULL) OR (ticket_max_usd >= ticket_min_usd))`
- `((aum_usd IS NULL) OR (aum_usd >= (0)::numeric))`

---

### `app.investor_partner_profile`  *(rows: 119)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `party_id, organization_id, firm_party_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `party_id` | uuid | ⚠️ |  |
| 3 | `organization_id` | uuid | ⚠️ |  |
| 4 | `firm_party_id` | uuid | ⚠️ |  |
| 5 | `title_text` | text |  |  |
| 6 | `seniority_level` | partner_seniority | ✓ | `'other'::app.partner_seniority` |
| 7 | `is_decision_maker` | boolean | ✓ | `false` |
| 8 | `joined_year` | integer |  |  |
| 9 | `focus_areas` | text[] | ✓ | `'{}'::text[]` |
| 10 | `background` | text |  |  |
| 11 | `education` | text |  |  |
| 12 | `twitter_handle` | text |  |  |
| 13 | `email` | text |  |  |
| 14 | `phone` | text |  |  |
| 15 | `source` | text |  |  |
| 16 | `notes` | text |  |  |
| 17 | `created_at` | timestamptz | ✓ | `now()` |
| 18 | `updated_at` | timestamptz | ✓ | `now()` |
| 19 | `created_by` | uuid |  |  |
| 20 | `updated_by` | uuid |  |  |

**UNIQUE / PK:**

- 🔒 UQ `(party_id)`
- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `firm_party_id` → `app.parties.id`
- `party_id` → `app.parties.id`


**Semantic CHECK 제약:**

- `((joined_year IS NULL) OR ((joined_year >= 1900) AND (joined_year <= 2200)))`

---

### `app.person_firm_history`  *(rows: 119)* ⭐ Phase 2 (2026-05-19 적용)

**역할:** 모든 module 의 person ↔ firm 직장 이력. URM 통일 패턴 Layer 3 (temporal). 사용자 원칙 4/7/9 실현 (입사/퇴사, 다중 firm, 전체 career 검색).

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `organization_id, person_party_id, firm_party_id, role_category, joined_at`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `organization_id` | uuid | ⚠️ |  |
| 3 | `person_party_id` | uuid | ⚠️ |  |
| 4 | `firm_party_id` | uuid | ⚠️ |  |
| 5 | `title_text` | text |  |  |
| 6 | `seniority_level` | partner_seniority |  |  |
| 7 | `role_category` | text | ⚠️ |  |
| 8 | `module` | module_type |  |  |
| 9 | `joined_at` | date | ⚠️ |  |
| 10 | `left_at` | date |  | (NULL = 현재 재직 중) |
| 11 | `is_primary` | boolean | ✓ | `true` |
| 12 | `is_decision_maker` | boolean |  |  |
| 13 | `source` | text |  |  |
| 14 | `notes` | text |  |  |
| 15 | `module_data` | jsonb | ✓ | `'{}'::jsonb` |
| 16 | `created_at` | timestamptz | ✓ | `now()` |
| 17 | `updated_at` | timestamptz | ✓ | `now()` |
| 18 | `created_by` | uuid |  |  |
| 19 | `updated_by` | uuid |  |  |
| 20 | `deleted_at` | timestamptz |  |  |

**UNIQUE / PK:**

- 🔑 PK `(id)`
- 🔒 UQ partial `(person_party_id, firm_party_id, joined_at) WHERE deleted_at IS NULL` — 같은 (사람, firm, 입사일) 중복 방지

**FK out:**

- `person_party_id` → `app.parties.id` ON DELETE CASCADE
- `firm_party_id` → `app.parties.id`
- `organization_id` → `app.organizations.id`
- `created_by`, `updated_by` → `app.users.id`

**Semantic CHECK 제약:**

- `pfh_different_parties`: `person_party_id != firm_party_id`
- `pfh_time_order`: `left_at IS NULL OR left_at >= joined_at`
- `pfh_role_category_valid`: `role_category IN ('investor','employee','founder','advisor','board_member','consultant','other')`
- `pfh_joined_at_reasonable`: `joined_at >= '1900-01-01' AND joined_at <= '2200-12-31'`

**Trigger:**

- `trg_pfh_updated_at` (BEFORE UPDATE) — `set_updated_at()`
- `trg_pfh_sync_parent` (AFTER INSERT OR UPDATE OF firm_party_id, is_primary, left_at, deleted_at) — `sync_parent_from_primary_firm()` ⭐ 핵심: primary + current 행을 parties.parent_party_id 로 자동 동기화

**RLS:** ENABLED (4 policies — select/insert/update/delete 모두 `organization_id = current_organization_id()` 기반).

**Indexes (6개):**

- `idx_pfh_person` (person_party_id) WHERE deleted_at IS NULL
- `idx_pfh_firm` (firm_party_id) WHERE deleted_at IS NULL
- `idx_pfh_current` (person_party_id, firm_party_id) WHERE left_at IS NULL AND deleted_at IS NULL
- `idx_pfh_org` (organization_id) WHERE deleted_at IS NULL
- `idx_pfh_module` (module) WHERE module IS NOT NULL AND deleted_at IS NULL
- `uq_pfh_person_firm_joined` UNIQUE (위 UNIQUE 제약)

**관련 view 2개:**

- `app.v_person_career_history` — 개인별 이력 (person_party_id 로 필터 후 정렬)
- `app.v_firm_alumni` — firm 별 현직원 + alumni + 떠난 사람들의 현재 firm

**적재 패턴:**

```sql
-- 새 partner/employee 입사 적재 시
INSERT INTO app.person_firm_history (
  organization_id, person_party_id, firm_party_id,
  title_text, seniority_level, role_category, module,
  joined_at, is_primary, is_decision_maker, source
) VALUES (
  'b25de8f2-1020-482f-9012-183f63883169', <person_id>, <firm_id>,
  'General Partner', 'partner'::app.partner_seniority, 'investor',
  'investor'::app.module_type,
  '2024-01-01', true, true, 'linkedin'
);
-- trigger 가 자동으로 parties.parent_party_id 동기화 (is_primary=true AND left_at IS NULL 일 때)
```

**1900-01-01 sentinel 함정 (Phase 2 발견):** `GREATEST(NULL, 1900) = 1900` PostgreSQL 동작으로 COALESCE fallback 이 발동 안 함. 87 행이 1900 으로 적재됐다가 UPDATE 로 2020 통일. 새 마이그레이션 작성 시 `CASE WHEN col IS NULL THEN default ELSE make_date(...)` 패턴 권장.

---

### `app.filler_supplier_profile`  *(rows: 260)* ⭐ Phase 1 (2026-05-19 적용)

**역할:** Filler supplier (calcium carbonate / mineral filler 제조사) 의 firm-level structured profile. URM Master Arch Block 2. `parties.module='filler'` 와 1-to-1.

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `party_id, organization_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `party_id` | uuid | ⚠️ |  |
| 3 | `organization_id` | uuid | ⚠️ |  |
| 4 | `supplier_type` | text |  |  |
| 5 | `market_role` | text |  |  |
| 6 | `supply_model` | text |  |  |
| 7 | `onsite_pcc_evidence` | text |  |  |
| 8 | `evidence_level` | text |  |  |
| 9 | `industry_source` | text | ✓ | `'v11.4'` |
| 10 | `auto_promoted_at` | timestamptz |  |  |
| 11 | `notes` | text |  |  |
| 12 | `module_data` | jsonb | ✓ | `'{}'::jsonb` |
| 13 | `created_at` | timestamptz | ✓ | `now()` |
| 14 | `updated_at` | timestamptz | ✓ | `now()` |
| 15 | `created_by` | uuid |  |  |
| 16 | `updated_by` | uuid |  |  |
| 17 | `deleted_at` | timestamptz |  |  |

**UNIQUE / PK:**
- 🔑 PK `(id)`
- 🔒 UQ `(party_id)` — firm 1 profile

**FK out:**
- `party_id` → `app.parties.id` ON DELETE CASCADE
- `organization_id` → `app.organizations.id`

**도메인 필드 의미:**
- `supplier_type` — text. 짧은 카테고리 ("Mineral solutions supplier") + 긴 서술 ("Domestic-Turkey — Niğde-based major producer") 혼재.
- `market_role` — text. "Multi-region" / "Cross-border" 짧은 값 + plant capacity 등 긴 서술 혼재.
- `supply_model` — text. "Merchant", "Merchant + application support". em-dash `"—"` sentinel 은 backfill 시 NULL 로 정규화됨.
- `onsite_pcc_evidence` — text. "A"/"B"/"C" grade 가 90% (68/76 non-NULL), free text 10% (8/76). enum 적합도 약함, text 유지.

**현재 데이터 밀도 (260 rows):**
- supplier_type 채워짐: ~245 (94%)
- market_role: ~245 (94%)
- supply_model: ~186 (72%)
- onsite_pcc_evidence: ~76 (29%)

**RLS:** ENABLED + 4 policies (다른 profile 패턴).

**Trigger:** `trg_fsp_updated_at` — `set_updated_at()`.

**Indexes:**
- `idx_fsp_org` (organization_id) WHERE deleted_at IS NULL
- `idx_fsp_supplier_type` (supplier_type) WHERE supplier_type IS NOT NULL AND deleted_at IS NULL
- `idx_fsp_industry_source` (industry_source) WHERE deleted_at IS NULL

**연관 view:** `app.v_filler_suppliers` — firm + profile + parent_party_id (3-tier hierarchy) 통합. `has_full_supplier_data` flag.

**적재 패턴 (새 filler firm 추가 시):**
```sql
-- 1. parties row 먼저
INSERT INTO app.parties (organization_id, name, module, party_type, country_code, website)
VALUES ('b25de8f2-...'::uuid, 'New Filler Co.', 'filler'::app.module_type, 'organization', 'US', 'https://...')
RETURNING id;

-- 2. profile row
INSERT INTO app.filler_supplier_profile (
  organization_id, party_id,
  supplier_type, market_role, supply_model, onsite_pcc_evidence,
  industry_source
) VALUES (
  'b25de8f2-...'::uuid, <party_id>,
  'Domestic — US', 'Merchant', 'Merchant',  'B',
  'manual_entry'   -- 'v11.4' 외 source 명시
);
```

---

### `app.filler_supplier_contact_profile`  *(rows: 0)* ⭐ Phase 1 (schema-only, 미적재)

**역할:** Filler supplier 측 person-level profile (plant manager / VP sales / R&D head 등). URM Master Arch Block 3. **현재 0 rows** — 향후 적재 대비 schema 준비.

**필수 INSERT 컬럼:** `party_id, organization_id, firm_party_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `party_id` | uuid | ⚠️ |  |
| 3 | `organization_id` | uuid | ⚠️ |  |
| 4 | `firm_party_id` | uuid | ⚠️ |  |
| 5 | `title_text` | text |  |  |
| 6 | `role_in_firm` | text |  | (e.g., 'plant_manager', 'sales', 'r_and_d') |
| 7 | `is_decision_maker` | boolean | ✓ | `false` |
| 8 | `email` | text |  |  |
| 9 | `phone_e164` | text |  |  |
| 10 | `linkedin_url` | text |  |  |
| 11 | `notes` | text |  |  |
| 12 | `module_data` | jsonb | ✓ | `'{}'::jsonb` |
| 13 | `created_at` | timestamptz | ✓ | `now()` |
| 14 | `updated_at` | timestamptz | ✓ | `now()` |
| 15 | `created_by`, `updated_by`, `deleted_at` |  |  |  |

**Semantic CHECK:**
- `fscp_different_parties`: `party_id != firm_party_id`

**UQ / PK:**
- 🔑 PK `(id)`
- 🔒 UQ `(party_id)`

**FK out:**
- `party_id` → `app.parties.id` ON DELETE CASCADE
- `firm_party_id` → `app.parties.id`
- `organization_id` → `app.organizations.id`

**RLS:** ENABLED + 4 policies. **Trigger:** `trg_fscp_updated_at`.

**Indexes:**
- `idx_fscp_org` (organization_id) WHERE deleted_at IS NULL
- `idx_fscp_firm` (firm_party_id) WHERE deleted_at IS NULL
- `idx_fscp_dm` (firm_party_id) WHERE is_decision_maker = true AND deleted_at IS NULL

→ 향후 적재 패턴: investor_partner_profile 과 거의 동일. `parties.module='filler'` + `party_type='individual'` + `parent_party_id=<firm_id>` 도 같이 세팅.

---

### `app.portfolio_companies`  *(rows: 342)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `organization_id, name, name_normalized`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `organization_id` | uuid | ⚠️ |  |
| 3 | `name` | text | ⚠️ |  |
| 4 | `name_normalized` | text | ⚠️ |  |
| 5 | `website` | text |  |  |
| 6 | `domain_normalized` | text |  |  |
| 7 | `country_code` | text |  |  |
| 8 | `sector` | text |  |  |
| 9 | `sub_sector` | text |  |  |
| 10 | `founded_year` | integer |  |  |
| 11 | `current_valuation_usd` | numeric |  |  |
| 12 | `company_status` | text |  |  |
| 13 | `notes` | text |  |  |
| 14 | `module_data` | jsonb | ✓ | `'{}'::jsonb` |
| 15 | `party_id` | uuid |  |  |
| 16 | `source` | text |  |  |
| 17 | `source_external_id` | text |  |  |
| 18 | `created_at` | timestamptz | ✓ | `now()` |
| 19 | `updated_at` | timestamptz | ✓ | `now()` |
| 20 | `created_by` | uuid |  |  |
| 21 | `updated_by` | uuid |  |  |
| 22 | `deleted_at` | timestamptz |  |  |

**UNIQUE / PK:**

- 🔑 PK `(id)`
- 🔒 UQ `(organization_id, name_normalized)`


**FK out (이 테이블이 참조):**

- `party_id` → `app.parties.id`

**FK in (이 테이블을 참조):**

- `app.investor_portfolio_companies`


**Semantic CHECK 제약:**

- `((company_status IS NULL) OR (company_status = ANY (ARRAY['private'::text, 'public'::text, 'acquired'::text, 'closed'::text, 'spinoff'::text, 'merged'::text, 'unknown'::text])))`
- `((current_valuation_usd IS NULL) OR (current_valuation_usd >= (0)::numeric))`
- `((founded_year IS NULL) OR ((founded_year >= 1500) AND (founded_year <= 2200)))`

---

### `app.investor_portfolio_companies`  *(rows: 445)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `organization_id, investor_party_id, portfolio_company_name`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `organization_id` | uuid | ⚠️ |  |
| 3 | `investor_party_id` | uuid | ⚠️ |  |
| 4 | `portfolio_company_name` | text | ⚠️ |  |
| 5 | `portfolio_company_website` | text |  |  |
| 6 | `portfolio_company_country` | text |  |  |
| 7 | `investment_year` | integer |  |  |
| 8 | `investment_stage` | text |  |  |
| 9 | `investment_amount_usd` | numeric |  |  |
| 10 | `is_lead` | boolean | ✓ | `false` |
| 11 | `is_active` | boolean | ✓ | `true` |
| 12 | `notes` | text |  |  |
| 13 | `created_at` | timestamptz | ✓ | `now()` |
| 14 | `updated_at` | timestamptz | ✓ | `now()` |
| 15 | `created_by` | uuid |  |  |
| 16 | `updated_by` | uuid |  |  |
| 17 | `deleted_at` | timestamptz |  |  |
| 18 | `portfolio_company_id` | uuid |  |  |

**UNIQUE / PK:**

- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `created_by` → `app.users.id`
- `investor_party_id` → `app.parties.id`
- `organization_id` → `app.organizations.id`
- `portfolio_company_id` → `app.portfolio_companies.id`
- `updated_by` → `app.users.id`


**Semantic CHECK 제약:**

- `((investment_year >= 1980) AND (investment_year <= 2100))`

---

### `app.plant_supply_links`  *(rows: ?)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `id, organization_id, paper_mill_plant_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ⚠️ |  |
| 2 | `organization_id` | uuid | ⚠️ |  |
| 3 | `paper_mill_plant_id` | uuid | ⚠️ |  |
| 4 | `filler_plant_id` | uuid |  |  |
| 5 | `filler_type` | text |  |  |
| 6 | `supply_status` | text |  |  |
| 7 | `source_channel` | text |  |  |
| 8 | `notes` | text |  |  |
| 9 | `created_at` | timestamptz |  | `now()` |
| 10 | `updated_at` | timestamptz |  | `now()` |
| 11 | `first_contact_at` | timestamptz |  |  |
| 12 | `contracted_at` | timestamptz |  |  |
| 13 | `confidence_grade` | char |  |  |

**UNIQUE / PK:**

- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `filler_plant_id` → `app.parties.id`
- `paper_mill_plant_id` → `app.parties.id`


**Semantic CHECK 제약:**

- `(source_channel = ANY (ARRAY['mill_first'::text, 'filler_first'::text, 'industry_master'::text]))`
- `(supply_status = ANY (ARRAY['inquiry'::text, 'qualification'::text, 'qualified'::text, 'active'::text, 'dormant'::text, 'terminated'::text]))`

---

### `app.party_supply_links`  *(rows: ?)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `organization_id, filler_party_id, mill_party_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `organization_id` | uuid | ⚠️ |  |
| 3 | `filler_party_id` | uuid | ⚠️ |  |
| 4 | `mill_party_id` | uuid | ⚠️ |  |
| 5 | `supply_type` | text | ✓ | `'active'::text` |
| 6 | `product_grade` | text |  |  |
| 7 | `volume_tpy` | integer |  |  |
| 8 | `notes` | text |  |  |
| 9 | `created_at` | timestamptz |  | `now()` |
| 10 | `updated_at` | timestamptz |  | `now()` |

**UNIQUE / PK:**

- 🔒 UQ `(filler_party_id, mill_party_id)`
- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `filler_party_id` → `app.parties.id`
- `mill_party_id` → `app.parties.id`
- `organization_id` → `app.organizations.id`

---

### `app.organizations`  *(rows: ?)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `name, slug`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `name` | text | ⚠️ |  |
| 3 | `slug` | text | ⚠️ |  |
| 4 | `logo_url` | text |  |  |
| 5 | `domain` | text |  |  |
| 6 | `country_code` | text |  |  |
| 7 | `default_language` | text | ✓ | `'ko'::text` |
| 8 | `default_timezone` | text | ✓ | `'Asia/Seoul'::text` |
| 9 | `default_currency` | text | ✓ | `'USD'::text` |
| 10 | `allowed_modules` | module_type[] | ✓ | `ARRAY['investor'::app.module_type, 'paper_mill'::app.module_type, 'partner'::app.module_type, 'customer'::app.module_type]` |
| 11 | `plan` | text | ✓ | `'free'::text` |
| 12 | `plan_expires_at` | timestamptz |  |  |
| 13 | `settings` | jsonb | ✓ | `'{}'::jsonb` |
| 14 | `created_at` | timestamptz | ✓ | `now()` |
| 15 | `updated_at` | timestamptz | ✓ | `now()` |
| 16 | `deleted_at` | timestamptz |  |  |

**UNIQUE / PK:**

- 🔑 PK `(id)`
- 🔒 UQ `(slug)`

**FK in:** 71 테이블에서 참조. 주요: `app.attachments`, `app.buyer_inquiries`, `app.buyer_profile`, `app.calendar_connections`, `app.calendar_events`, `app.campaign_backers`, `app.campaign_rewards`, `app.campaign_updates` +63 more


**Semantic CHECK 제약:**

- `((country_code IS NULL) OR (length(country_code) = 2))`
- `(length(default_currency) = 3)`
- `(default_language = ANY (ARRAY['ko'::text, 'en'::text, 'ja'::text, 'zh-CN'::text]))`
- `(plan = ANY (ARRAY['free'::text, 'starter'::text, 'growth'::text, 'enterprise'::text]))`
- `((slug ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$'::text) AND ((length(slug) >= 3) AND (length(slug) <= 63)))`

---

### `ingest.runs`  *(rows: 15)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `label, module, organization_id`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `label` | text | ⚠️ |  |
| 3 | `module` | text | ⚠️ |  |
| 4 | `organization_id` | uuid | ⚠️ |  |
| 5 | `description` | text |  |  |
| 6 | `sources` | text[] | ✓ | `'{}'::text[]` |
| 7 | `actor` | text | ✓ | `'claude'::text` |
| 8 | `started_at` | timestamptz | ✓ | `now()` |
| 9 | `finished_at` | timestamptz |  |  |
| 10 | `rows_staged` | integer | ✓ | `0` |
| 11 | `rows_promoted` | integer | ✓ | `0` |
| 12 | `rows_merged` | integer | ✓ | `0` |
| 13 | `rows_skipped` | integer | ✓ | `0` |
| 14 | `rows_failed` | integer | ✓ | `0` |
| 15 | `notes` | text |  |  |

**UNIQUE / PK:**

- 🔒 UQ `(label)`
- 🔑 PK `(id)`

**FK in (이 테이블을 참조):**

- `ingest.rows`

---

### `ingest.rows`  *(rows: 180)*

**필수 INSERT 컬럼 (⚠️ NOT NULL no-default):** `run_id, module, name, payload`

| pos | column | type | NN | default |
|----:|--------|------|:--:|---------|
| 1 | `id` | uuid | ✓ | `gen_random_uuid()` |
| 2 | `run_id` | uuid | ⚠️ |  |
| 3 | `seq` | integer |  |  |
| 4 | `module` | text | ⚠️ |  |
| 5 | `name` | text | ⚠️ |  |
| 6 | `dedup_key` | text |  |  |
| 7 | `payload` | jsonb | ⚠️ |  |
| 8 | `promoted_party_id` | uuid |  |  |
| 9 | `status` | text | ✓ | `'staged'::text` |
| 10 | `error_message` | text |  |  |
| 11 | `created_at` | timestamptz | ✓ | `now()` |
| 12 | `updated_at` | timestamptz | ✓ | `now()` |

**UNIQUE / PK:**

- 🔑 PK `(id)`


**FK out (이 테이블이 참조):**

- `run_id` → `ingest.runs.id`


**Semantic CHECK 제약:**

- `(status = ANY (ARRAY['staged'::text, 'promoted'::text, 'merged'::text, 'skipped'::text, 'failed'::text]))`

---

## 4. 함수 카탈로그 (41개)

⭐ = SQL 작성 시 적극 활용해야 할 helper 함수


### `ingest` schema (15 함수)

**일반 함수:**

| 함수 | 인자 | 반환 |
|------|------|------|
| `coerce_investor_subtype` ⭐ | p_raw text | app.investor_subtype |
| `coerce_text_array` | p_value jsonb | text[] |
| `finish_run` | p_run_label text | void |
| `infer_is_decision_maker` ⭐ | p_title text | boolean |
| `infer_seniority` ⭐ | p_title text | app.partner_seniority |
| `normalize_domain` ⭐ | p_url text | text |
| `normalize_linkedin` ⭐ | p_url text | text |
| `promote_investor_partners` ⭐ | p_run_label text | TABLE(action text, n integer) |
| `promote_investors` ⭐ | p_run_label text | TABLE(action text, n integer) |
| `rollback_run` ⭐ | p_run_label text, p_confirm boolean DEFAULT false | TABLE(deleted_table text, n integer) |
| `stage_row` | p_run_label text, p_payload jsonb | uuid |
| `stage_rows_bulk` ⭐ | p_run_label text, p_payloads jsonb | integer |
| `start_run` ⭐ | p_label text, p_module text, p_organization_id uuid, p_description text DEFAULT NULL::text, p_sources text[] DEFAULT ... | uuid |
| `upsert_portfolio_company` ⭐ | p_org_id uuid, p_name text, p_website text, p_country text, p_sector text DEFAULT NULL::text | uuid |

**Trigger 함수:**

- `set_partner_dedup_key()` — trigger

### `app` schema (26 함수)

**일반 함수:**

| 함수 | 인자 | 반환 |
|------|------|------|
| `calculate_lead_score` | p_party_id uuid | integer |
| `compute_default_lead_score` | p_party_id uuid | integer |
| `current_is_owner` |  | boolean |
| `current_organization_id` ⭐ |  | uuid |
| `current_preferred_language` |  | text |
| `current_user_id` |  | uuid |
| `decrypt_calendar_token` | p_encrypted bytea | text |
| `encrypt_calendar_token` | p_plain text | bytea |
| `fuzzy_match_score` ⭐ | text, text | numeric |
| `get_pipeline_forecast` | p_org_id uuid, p_months integer DEFAULT 6 | TABLE(month_start date, open_count integer, total_value numeric, weighted_val... |
| `is_member_of_organization` | p_organization_id uuid | boolean |
| `is_organization_owner` | p_organization_id uuid | boolean |
| `normalize_domain` ⭐ | url text | text |
| `upsert_calendar_connection` | p_organization_id uuid, p_user_id uuid, p_provider text, p_account_email text, p_account_name text, p_access_token te... | uuid |

**Trigger 함수:**

- `check_party_supply_link()` — trigger
- `communications_touch_engagement()` — trigger
- `consultations_notify_worker()` — trigger
- `email_templates_snapshot_version()` — trigger
- `engagements_record_stage_change()` — trigger
- `fn_auto_link_inbound_reply()` — trigger
- `parties_set_normalized()` — trigger
- `scraping_normalized_set_norm()` — trigger
- `set_updated_at()` — trigger
- `strategy_actions_sync_task_status()` — trigger
- `tasks_set_completed_at()` — trigger
- `update_invoice_paid_amount()` — trigger

### 핵심 함수 사용 가이드

#### `ingest.upsert_portfolio_company(org, name, website, country, sector)` ⭐
portfolio_companies 마스터 적재의 표준. WITH CTE 로 직접 INSERT 하지 말고 이것 사용.

```sql
SELECT ingest.upsert_portfolio_company(
    'b25de8f2-1020-482f-9012-183f63883169'::uuid,
    'Earthodic',
    'https://www.earthodic.com',
    'AU',
    'sustainable_packaging'
);  -- returns portfolio_company.id
```

#### `ingest.start_run / stage_rows_bulk / promote_*` 표준 3단계
```sql
SELECT ingest.start_run('label', 'module', org_id, 'desc', sources);
SELECT ingest.stage_rows_bulk('label', '[{...}, {...}]'::jsonb);
SELECT * FROM ingest.promote_investors('label');  -- or promote_investor_partners
```

#### `ingest.rollback_run(label, confirm := true)` — 안전 롤백
```sql
SELECT * FROM ingest.rollback_run('my_label', true);
-- returns: deleted_table, n
```

#### `ingest.infer_seniority(title)` / `infer_is_decision_maker(title)` — 자동 분류
promote 함수 내부에서 자동 호출됨. 별도 호출 불필요.

#### `ingest.coerce_investor_subtype(raw_text)` — text → enum
"vc" / "Venture Capital" / "VC" 등 다양한 표기 → `vc` enum 으로 정규화.

---

## 5. 기타 테이블 (compact reference)

핵심 카드 외 75개 테이블. NOT-NULL no-default 컬럼만 표시.


### CRM / engagement

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.engagements` | 30 | ? | `organization_id`, `party_id`, `module`, `name` |
| `app.engagement_stage_history` | 10 | ? | `organization_id`, `engagement_id`, `to_stage_id` |
| `app.contacts` | 28 | ? | `organization_id`, `party_id`, `full_name` |
| `app.communications` | 49 | ? | `organization_id`, `channel`, `direction` |
| `app.meetings` | 29 | ? | `organization_id`, `party_id`, `meeting_type`, `title`, `occurred_at` |
| `app.meeting_attendees` | 12 | ? | `organization_id`, `meeting_id`, `email` |
| `app.consultations` | 34 | ? | `organization_id`, `channel`, `content_raw` |
| `app.tasks` | 29 | ? | `organization_id`, `title` |
| `app.calendar_connections` | 21 | ? | `organization_id`, `user_id`, `provider`, `account_email`, `access_token` |
| `app.calendar_events` | 32 | ? | `organization_id`, `user_id`, `source`, `start_at`, `end_at` |
| `app.attachments` | 19 | ? | `organization_id`, `entity_type`, `entity_id`, `file_name`, `file_size_bytes`, `mime_type` +1 |

### Email / templates

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.email_sequences` | 7 | ? | `org_id`, `name` |
| `app.email_sequence_steps` | 8 | ? | `sequence_id`, `step_order`, `subject`, `body_text` |
| `app.email_sequence_enrollments` | 14 | ? | `org_id`, `sequence_id` |
| `app.email_sequence_sends` | 7 | ? | `enrollment_id`, `step_id`, `step_order` |
| `app.email_templates` | 12 | ? | `organization_id`, `name`, `subject`, `body_plain` |
| `app.email_tracking` | 14 | ? | `org_id` |
| `app.email_tracking_events` | 8 | ? | `tracking_id`, `event_type` |
| `app.email_tracking_links` | 5 | ? | `tracking_id`, `original_url` |
| `app.email_whitelist` | 8 | ? | `organization_id`, `pattern`, `kind` |
| `app.template_categories` | 16 | ? | `organization_id`, `code`, `name` |
| `app.template_variables` | 18 | ? | `organization_id`, `variable_path`, `display_name`, `data_type`, `source_entity` |
| `app.template_versions` | 17 | ? | `organization_id`, `template_id`, `version_number`, `subject_template`, `body_template` |
| `app.template_ab_tests` | 24 | ? | `organization_id`, `name`, `variant_a_template_id`, `variant_b_template_id` |
| `app.mail_merge_jobs` | 33 | ? | `organization_id`, `name`, `template_id`, `from_address` |
| `app.mailcarrier_state` | 6 | ? | `organization_id`, `kind`, `username` |

### Sales / commerce

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.products` | 20 | ? | `organization_id`, `sku`, `name` |
| `app.quotations` | 27 | ? | `organization_id`, `party_id`, `quote_number` |
| `app.sales_orders` | 24 | ? | `organization_id`, `party_id`, `order_number` |
| `app.sales_order_items` | 13 | ? | `organization_id`, `order_id`, `line_number`, `description` |
| `app.invoices` | 21 | ? | `organization_id`, `party_id`, `invoice_number` |
| `app.payments` | 14 | ? | `organization_id`, `party_id`, `amount` |
| `app.shipments` | 14 | ? | `organization_id`, `order_id`, `shipment_number` |
| `app.buyer_inquiries` | 16 | ? | `organization_id`, `party_id`, `inquiry_type` |
| `app.buyer_profile` | 16 | ? | `party_id`, `organization_id` |
| `app.customer_profile` | 16 | ? | `party_id`, `organization_id` |
| `app.customer_purchases` | 13 | ? | `organization_id`, `party_id`, `purchase_date`, `product_name` |
| `app.customer_segments` | 11 | ? | `organization_id`, `name` |

### Pipeline / strategy

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.pipeline_definitions` | 12 | ? | `organization_id`, `module`, `name` |
| `app.pipeline_stages` | 17 | ? | `organization_id`, `pipeline_definition_id`, `code`, `name`, `stage_type`, `sort_order` |
| `app.response_strategies` | 29 | ? | `organization_id`, `situation_analysis`, `recommended_approach` |
| `app.strategy_actions` | 21 | ? | `organization_id`, `strategy_id`, `title`, `action_type` |
| `app.strategy_outcomes` | 20 | ? | `organization_id`, `strategy_id`, `was_successful` |
| `app.lead_scores` | 12 | ? | `organization_id`, `party_id` |

### Crowdfunding / launch

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.crowdfunding_campaigns` | 20 | ? | `organization_id`, `name`, `platform` |
| `app.campaign_backers` | 16 | ? | `organization_id`, `campaign_id`, `party_id`, `pledge_amount_usd` |
| `app.campaign_rewards` | 15 | ? | `campaign_id`, `organization_id`, `tier_name`, `tier_order`, `pledge_min_usd`, `description` |
| `app.campaign_updates` | 14 | ? | `organization_id`, `campaign_id`, `title`, `body`, `update_number` |
| `app.product_launches` | 17 | ? | `organization_id`, `name` |
| `app.launch_milestones` | 13 | ? | `organization_id`, `launch_id`, `name`, `phase`, `target_date`, `order_no` |
| `app.launch_risks` | 15 | ? | `organization_id`, `launch_id`, `title` |
| `app.launch_tasks` | 17 | ? | `organization_id`, `launch_id`, `title` |

### Partner module

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.partner_profile` | 16 | ? | `party_id`, `organization_id`, `partner_type` |
| `app.partner_capabilities` | 10 | ? | `organization_id`, `party_id`, `capability_type`, `capability_name` |
| `app.partner_audits` | 17 | ? | `organization_id`, `party_id`, `audit_type`, `audit_date`, `pass_status` |

### Scraping

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.scraping_jobs` | 30 | ? | `organization_id`, `source_id`, `job_name` |
| `app.scraping_normalized` | 32 | ? | `organization_id`, `raw_id`, `target_id`, `name`, `name_normalized` |
| `app.scraping_raw` | 20 | ? | `organization_id`, `target_id` |
| `app.scraping_sources` | 32 | ? | `organization_id`, `code`, `name`, `source_type`, `base_url` |
| `app.scraping_targets` | 19 | ? | `organization_id`, `source_id`, `url`, `url_hash` |

### Industry collections

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.industry_collections` | 21 | ? | `organization_id`, `code`, `name`, `primary_module` |

### Tags / custom fields

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.tags` | 11 | ? | `organization_id`, `code`, `name` |
| `app.entity_tags` | 7 | ? | `organization_id`, `tag_id`, `entity_type`, `entity_id` |
| `app.custom_field_definitions` | 16 | ? | `organization_id`, `entity_type`, `field_key`, `field_label`, `field_type` |
| `app.custom_field_values` | 10 | ? | `organization_id`, `definition_id`, `entity_type`, `entity_id`, `value` |
| `app.saved_views` | 18 | ? | `user_id`, `organization_id`, `name`, `entity_type` |

### Identity / access

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.users` | 23 | ? | `id`, `organization_id`, `email`, `full_name` |
| `app.teams` | 13 | ? | `organization_id`, `name`, `slug` |
| `app.team_members` | 6 | ? | `team_id`, `user_id`, `organization_id` |
| `app.roles` | 9 | ? | `organization_id`, `code`, `name` |
| `app.user_roles` | 6 | ? | `user_id`, `role_id`, `organization_id` |
| `app.role_permissions` | 4 | ? | `role_id`, `permission_id` |
| `app.permissions` | 5 | ? | `resource`, `action` |

### Dedup

| Table | cols | rows | required (NOT NULL no-default) |
|-------|-----:|-----:|-------------------------------|
| `app.dedup_review_queue` | 16 | ? | `organization_id`, `normalized_id` |
