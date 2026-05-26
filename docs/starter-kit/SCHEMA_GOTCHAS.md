# SCHEMA_GOTCHAS — URM Platform 작업 함정 모음 (v2)

> **버전:** 2026-05-19 (검증완료 — 8/8 섹션 + 41 함수 반영)
> SQL 작성 시 발생할 수 있는 함정을 카테고리별로 정리. **새 세션 시작 시 5분 안에 훑고 시작.**
> 새 함정 발견되면 이 파일에 추가.

---

## 0. ⭐ Helper 함수 먼저 확인 — 직접 SQL 작성 전에

**reinventing the wheel 금지.** 다음 helper 가 이미 존재:

| 하려는 작업 | 직접 작성 (X) | helper 사용 (O) |
|------------|-------------|----------------|
| portfolio_companies 적재 | WITH cte → INSERT ... ON CONFLICT | `SELECT ingest.upsert_portfolio_company(org, name, web, country, sector)` |
| Run rollback | DELETE 직접 | `SELECT ingest.rollback_run(label, true)` |
| 도메인 정규화 | `LOWER(regexp_replace(...))` | `ingest.normalize_domain(url)` / `app.normalize_domain(url)` |
| LinkedIn URL 정규화 | regex 직접 | `ingest.normalize_linkedin(url)` |
| 텍스트 → investor_subtype | CASE WHEN ... | `ingest.coerce_investor_subtype(raw_text)` |
| Title → seniority | CASE WHEN ... | `ingest.infer_seniority(title)` (promote 내부 자동 호출) |
| Title → DM 여부 | regex | `ingest.infer_is_decision_maker(title)` (promote 내부 자동 호출) |
| jsonb → text[] | 수동 변환 | `ingest.coerce_text_array(jsonb)` |
| 현재 org 확인 (RLS) | 하드코딩 | `app.current_organization_id()` |
| Dedup 유사도 측정 | levenshtein | `app.fuzzy_match_score(a, b)` |
| Lead score 계산 | 수동 | `app.calculate_lead_score(party_id)` |

---

## 1. NOT NULL + No-default 컬럼

### 1.1 `app.investor_portfolio_companies` — denormalized hybrid
이 테이블은 link 테이블이지만 **마스터 회사 정보를 denormalize 해서 보관**:

```
NOT NULL (no default):
  organization_id
  investor_party_id
  portfolio_company_name      ⭐ 자주 누락
  
nullable but FK:
  portfolio_company_id        (마스터 portfolio_companies 로의 FK)
```

**의도:** quick mode (name 만) + linked mode (FK 까지) 두 적재 패턴 지원.
**실수:** FK 만 채우고 name 누락 → ERROR 23502.

### 1.2 `app.parties` 핵심 NOT NULL
```
NOT NULL (no default):  organization_id, name, module
NOT NULL (with default): party_type, tier, status, industry_tags, interest_tags, module_data
nullable but auto-set:   name_normalized  ← trigger 가 채움. 비워둬도 OK
```

### 1.3 `app.investor_partner_profile`
```
NOT NULL (no default):  party_id, organization_id, firm_party_id
NOT NULL (with default): seniority_level, is_decision_maker, focus_areas
```
**`firm_party_id` 미적재 시 partner promote 실패.** firm 이 먼저 DB 에 있어야 함.

### 1.4 `app.portfolio_companies`
```
NOT NULL (no default):  organization_id, name, name_normalized  ← 수동 set 필요!
NOT NULL (with default): module_data
```
⚠️ `parties` 와 달리 `name_normalized` 가 NOT NULL. trigger 없음. 직접 채우거나 `ingest.upsert_portfolio_company()` 사용.

---

## 2. CHECK 제약 함정

### 2.1 Enum-like CHECK (text 컬럼이지만 허용값 제한)
| Table.Column | Valid values | 실수한 적 있는 값 |
|--------------|--------------|------------------|
| `portfolio_companies.company_status` | `private`, `public`, `acquired`, `closed`, `spinoff`, `merged`, `unknown`, NULL | `active`, `operating` ❌ |
| `parties.party_level` | `group_hq`, `country_entity`, `plant` (NULL 도 허용) | — |
| `plant_supply_links.supply_status` | `inquiry`, `qualification`, `qualified`, `active`, `dormant`, `terminated` | — |
| `plant_supply_links.source_channel` | `mill_first`, `filler_first`, `industry_master` | — |
| `organizations.plan` | `free`, `starter`, `growth`, `enterprise` | — |
| `organizations.default_language` | `ko`, `en`, `ja`, `zh-CN` | — |
| `ingest.rows.status` | `staged`, `promoted`, `merged`, `skipped`, `failed`, ... | — |

### 2.2 진짜 enum 타입 (text 가 아닌 enum 타입 — 더 엄격)
| Table.Column | Enum type | 값 |
|--------------|-----------|---|
| `parties.module` | `app.module_type` | investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier |
| `parties.party_type` | `app.party_type` | company, organization, individual, fund, government |
| `parties.tier` | `app.tier_level` | tier_1 ~ tier_5 |
| `parties.status` | `app.entity_status` | active, inactive, archived, blocked |
| `investor_profile.subtype` | `app.investor_subtype` | vc, cvc, growth_equity, private_equity, family_office, accelerator, angel, crowdfunding, government, other |
| `investor_partner_profile.seniority_level` | `app.partner_seniority` | founder, partner, principal, associate, advisor, other |

⚠️ **`investor_partner` 가 `module_type` enum 에 없음.** HANDOFF.md 의 `'investor_partner'::app.module_type` 사용은 잘못된 표기 가능 — 실제 enum 확장이 됐는지 확인 필요. 대안: `partner` 사용 또는 enum 확장 마이그레이션.

### 2.3 범위 CHECK
| Column | Range |
|--------|-------|
| `parties.founded_year`, `portfolio_companies.founded_year` | 1500–2200 (NULL 허용) |
| `parties.relationship_score` | 0–100 |
| `investor_profile.fund_vintage_year` | 1980–2100 |
| `investor_partner_profile.joined_year` | 1900–2200 |
| `investor_portfolio_companies.investment_year` | 1980–2100 |
| `country_code` (여러 테이블) | length = 2 ⭐ |
| `organizations.default_currency` | length = 3 |
| `organizations.slug` | `^[a-z0-9][a-z0-9-]*[a-z0-9]$`, 3-63 길이 |

### 2.4 ⚠️ enum 과 text CHECK 의 혼동 (GPT-5.5 + GPT-5.5 Pro 검증 추가)

**`app.meetings.meeting_type`** — 컬럼은 **text** 이지만 CHECK 제약값과 enum 값이 **다름**:

| 위치 | 허용 값 |
|------|---------|
| `app.meetings.meeting_type` (text CHECK) | `call, visit, zoom, meet, other` |
| `app.meeting_type` (enum, 별개) | `intro, discovery, pitch, negotiation, due_diligence, kickoff, review, closing, other` |

→ enum 값을 컬럼에 넣으면 CHECK 위반! **두 시스템은 무관**. 컬럼은 채널/방식, enum 은 미팅 목적/단계 — 의도된 분리일 가능성 (별개 컬럼이 있을 수 있음).

### 2.5 추가로 자주 INSERT 실패 유발 CHECK (GPT-5.5 Pro 권고)

| Table.Column | 함정 |
|--------------|------|
| `app.tasks` | `status='done'` ↔ `completed_at IS NOT NULL` 일관성 — trigger 가 처리할 수도 |
| `app.calendar_events` | `end_at >= start_at` CHECK |
| `app.contacts.email` | regex CHECK (이메일 형식 검증) |
| `app.attachments` | `file_size_bytes >= 0` CHECK |
| `app.sales_orders.status` | text CHECK — `app.order_status` enum 과 값이 **완전히 같지 않음** |
| `app.quotations.status` | `app.order_status` enum 사용 — 'accepted' 같은 quote 전용 값 넣으면 실패 |
| `app.mail_merge_jobs` | recipient_filter='{}' + recipient arrays 비어 있으면 CHECK 실패 |

### 2.6 상호 배타 CHECK
- `parties`: `industry_paper_company_id` 와 `industry_filler_supplier_id` 중 **최대 하나만** (둘 다 NULL 가능)
- `investor_profile`: `ticket_max_usd >= ticket_min_usd` (둘 다 NULL 도 OK)

### 2.7 ⚠️ `plant_supply_links.id` — NOT NULL no-default (Minimax 검증)

| 컬럼 | 타입 | NN | default |
|------|------|:--:|---------|
| `plant_supply_links.id` | uuid | ⚠️ | **없음** |

→ INSERT 시 `gen_random_uuid()` 명시 필요. 다른 테이블처럼 default 가 알아서 처리 안 됨. `safe_insert_templates.sql` TEMPLATE 7 에 반영됨.

---

## 3. UNIQUE 함정

### 3.1 `ingest.runs.label` — UNIQUE
같은 label 로 `ingest.start_run` 두 번 호출 시 `runs_label_key` 위반.
**해결:** 첫 시도 성공 여부 먼저 확인:
```sql
SELECT id, finished_at, rows_promoted FROM ingest.runs WHERE label = '...';
```
또는 명시적 롤백:
```sql
SELECT * FROM ingest.rollback_run('...', true);
```

### 3.2 `portfolio_companies` — `(organization_id, name_normalized)` UNIQUE
조직 내 중복 회사명 방지. ON CONFLICT 시 사용. `ingest.upsert_portfolio_company()` 가 내부에서 처리.

### 3.3 `investor_profile.party_id` UNIQUE / `investor_partner_profile.party_id` UNIQUE
한 party 당 하나의 profile. 동일 party_id 두 번 INSERT 불가. ON CONFLICT 패턴 필요.

### 3.4 `party_supply_links` — `(filler_party_id, mill_party_id)` UNIQUE
**주의:** `plant_supply_links` 는 UNIQUE 가 PK(id) 만. 중복 방지 직접 처리 필요.

### 3.5 `investor_portfolio_companies` — UNIQUE 없음
PK 만 존재. 같은 (investor, portfolio_company) 쌍 중복 가능. 적재 시 `WHERE NOT EXISTS` 패턴 필수.

---

## 4. FK 의존성 (적재 순서 함정)

핵심 의존 그래프:

```
organizations (root)
   └─ users, teams
   └─ parties (1764 rows, 32 테이블이 FK 참조)
        ├─ investor_profile          (party_id FK + UNIQUE)
        ├─ investor_partner_profile  (party_id UNIQUE + firm_party_id FK)
        ├─ portfolio_companies       (party_id FK, optional)
        ├─ investor_portfolio_companies (investor_party_id FK)
        ├─ party_supply_links        (filler + mill FK + UNIQUE 쌍)
        ├─ plant_supply_links        (filler_plant + paper_mill_plant)
        ├─ parties.parent_party_id   (self-FK, 3-tier 계층)
        └─ ... 32 other tables
```

**규칙:**
1. firm 이 없으면 partner 적재 불가 (`firm_party_id` FK)
2. portfolio_companies 가 없어도 `investor_portfolio_companies` 적재 가능 (FK nullable, 단 name 필수)
3. parent_party_id 채울 시 부모가 먼저 적재 (group_hq → country_entity → plant)
4. **users/teams 가 없는 dev 환경**: created_by, owner_user_id 등은 nullable 이므로 NULL 가능

---

## 5. Ingest layer 사용 패턴

### 5.1 표준 3단계
```sql
SELECT ingest.start_run(
    p_label, p_module, p_organization_id, p_description, p_sources
);
SELECT ingest.stage_rows_bulk('label', '[...]'::jsonb);
SELECT * FROM ingest.promote_investors('label');  -- or promote_investor_partners
```

### 5.2 promote 결과 해석
| action | 의미 |
|--------|------|
| `promoted` | 신규 row 적재됨 |
| `merged` | 기존 row 와 dedup 되어 병합 |
| `skipped` | 이미 존재 (no-op) |
| `failed` | 검증 실패 (`ingest.failed_rows` 확인) |

### 5.3 실패 행 확인 + 안전 롤백
```sql
-- 실패 원인 확인
-- ⚠️ ingest.failed_rows 는 VIEW 이고 컬럼은 run_label, seq, name, dedup_key, 
--    error_message, payload, created_at — run_id 컬럼 없음!
SELECT * FROM ingest.failed_rows 
 WHERE run_label = 'my_unique_label_2026Q2'
 ORDER BY seq;

-- 전체 롤백 (확인 필요)
SELECT * FROM ingest.rollback_run('label', true);
-- returns: deleted_table, n  (각 테이블에서 몇 행 삭제됐는지)
```

### 5.4 부분 rollback — 특정 party / partner 만 되돌리기
`ingest.rollback_run` 은 run 전체를 롤백. 단일 row 만 되돌리려면 직접 DELETE:

```sql
-- 패턴 1: 잘못 적재된 특정 partner 1명 + 그 party 삭제
BEGIN;
-- (1) profile 먼저 삭제 (FK 의존)
DELETE FROM app.investor_partner_profile 
 WHERE party_id = (
   SELECT id FROM app.parties 
    WHERE name = 'Wrong Person Name' 
      AND module = 'partner'::app.module_type
 );
-- (2) party 본체 삭제
DELETE FROM app.parties 
 WHERE name = 'Wrong Person Name' 
   AND module = 'partner'::app.module_type;
-- (3) ingest.rows status 도 정정 (audit trail)
UPDATE ingest.rows SET status = 'reverted' 
 WHERE name = 'Wrong Person Name' 
   AND run_id = (SELECT id FROM ingest.runs WHERE label = '...');
COMMIT;
```

⚠️ FK CASCADE 가 설정 안 됐을 수 있으므로 의존 테이블 순서: profile → party 본체.
의심되는 경우 GOTCHAS 의 D6 diagnostic 쿼리로 FK in 의존성 확인.

---

## 6. Trigger 자동 처리 (수동 set 불필요)

| Trigger 함수 | 대상 | 효과 |
|-------------|------|------|
| `parties_set_normalized()` | `parties` INSERT/UPDATE | `name_normalized` 자동 set |
| `set_updated_at()` | 모든 테이블 | `updated_at = NOW()` |
| `communications_touch_engagement()` | `communications` INSERT | 관련 engagement 갱신 |
| `engagements_record_stage_change()` | `engagements` UPDATE | stage_history 자동 기록 |
| `check_party_supply_link()` | `party_supply_links` | 사전 검증 |
| `tasks_set_completed_at()` | `tasks` | status='done' 시 timestamp |
| `email_templates_snapshot_version()` | `email_templates` | 버전 스냅샷 |
| `fn_auto_link_inbound_reply()` | email 인바운드 | 자동 link |

⭐ **즉, INSERT 작성 시 위 컬럼들은 비워두면 자동 처리됨.**

---

## 7. INSERT 작성 시 안전 체크리스트 (매번 확인)

다음 5개 + helper 체크:

1. **Helper 함수가 있나?** (Section 0 표) → 있으면 그것 사용
2. **`organization_id`** 채웠나? (`'b25de8f2-...'::uuid`)
3. **NOT NULL no-default 컬럼** 모두 채웠나? (각 테이블 카드 참고)
4. **CHECK 제약** 어기지 않나? (특히 company_status, party_level, party.module 등)
5. **FK 참조 대상** 이 이미 DB 에 존재하나? (parent firm 등)
6. **UNIQUE 제약** 충돌 없나? (label, name_normalized, party_id 등)

위 6개 통과하면 INSERT 성공률 99%+.

---

## 8. 이번 세션에서 부딪힌 함정 회상

| 시도 | 증상 | 원인 |
|------|------|------|
| v0 | `organization_id` NULL | link 테이블 INSERT 에 org_id 누락 |
| v1 (org_id 추가) | `portfolio_company_name` NULL | denormalized 컬럼 누락 |
| v2 (name/website/country 추가) | ✅ 성공 | 모든 NOT NULL 충족 |

**교훈 1:** information_schema 5초 쿼리로 사전 검증.
**교훈 2:** `ingest.upsert_portfolio_company()` 함수를 알았으면 CTE 작성 자체가 불필요했음.

---

## 9. 검증 발견 사항 (v1 → v2 업데이트)

이전 분석 (v1) 의 누락 및 부정확 사항을 v2 에서 수정:

| 항목 | v1 (이전) | v2 (수정) |
|------|----------|----------|
| enum 개수 | 28 (`app` 만) | **31** (`app` 30 + `public.tier_role` 1) |
| 누락된 enum | `investor_subtype`, `partner_seniority`, `tier_role` 빠짐 | 전부 포함 |
| 함수 카탈로그 | 없음 (Section 7 누락) | **41 함수** (`app` 26 + `ingest` 15) |
| 핵심 helper 인지 | 직접 CTE 작성 권장 | `ingest.upsert_portfolio_company()` 등 helper 우선 |
| `parties.name_normalized` 처리 | "수동 set 필요" 라고 기재 | **trigger 자동 처리** (수동 불필요) |
| `module_type` 에 `investor_partner` | "HANDOFF 패턴 그대로" 사용 | enum 에 **없음** — 확인 필요 표시 |
