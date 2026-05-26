# README — URM Platform Starter Kit (2026-05-19 v4)

> **이 파일이 마스터 인덱스.** 새 Claude 세션 시작 시 가장 먼저 본다.

---

## 1. 이 Starter Kit 의 목적

`mbg-project` (URM Platform — Unified Relationship Management) 의 DB 작업을 새 Claude 세션에서 즉시 이어갈 수 있게 하는 자료 묶음.

**URM 의 vision:** 다양한 business module (투자자 / 정부지원사업 / paper mill / filler / sales / 향후 추가) 을 **동일한 통일 포맷**으로 추가/관리/조회/engagement 할 수 있는 B2B CRM 인프라.

**핵심 가치:**
- 새 세션의 첫 3분 안에 URM vision + DB 구조 + 사업 맥락 + 직전 작업 상태 파악
- 새 business module 추가 시 30-45분 (URM_MASTER_ARCHITECTURE §4 cookbook 사용)
- INSERT 작성 전 함정 회피 (NOT NULL / CHECK / FK / UNIQUE / RLS)

---

## 2. 파일 구성 (12개)

### 핵심 문서 (6) — 새 세션 필수 읽기

| 파일 | 버전 | 크기 | 첫 방문자 읽는 시간 |
|------|------|------|---------------------|
| **URM_MASTER_ARCHITECTURE.md** ⭐ | v3 | ~18 KB | 7분 (필수, 가장 먼저) |
| **NEXT_SESSION_KICKOFF.md** | v5 | ~14 KB | 5분 (필수) |
| **PROJECT_CONTEXT.md** | v2 | ~22 KB | 5분 (필수) |
| **DB_SCHEMA_REFERENCE.md** | v2.3 | ~42 KB | 10분 (skim) |
| **SCHEMA_GOTCHAS.md** | v3.2 | ~25 KB | 5분 (skim) |
| **safe_insert_templates.sql** | v3 | ~19 KB | 작업 시 lookup |

### Reference / 작업 carryover (5)

| 파일 | 용도 |
|------|------|
| **db_schema_introspect_v2.sql** | Phase 2 introspection 재실행 시. 마이그레이션 후 schema 변경 점검 |
| **migration_subtype_seniority_meta_2026Q2.sql** | ✅ 적용 완료 (참고용 보관) |
| **migration_person_firm_history_2026Q2.sql** | ✅ 적용 완료 (Phase 2, 119 backfill + 2 views + sync trigger) |
| **migration_filler_cleanup_2026Q2.sql** | ✅ 적용 완료 (Phase 1, 414→260 cleanup + supply_model URL fix) |
| **migration_filler_supplier_profile_2026Q2.sql** | ✅ 적용 완료 (Phase 1, 260 backfill + 2 tables + v_filler_suppliers) |
| **outreach_seed_top30_2026Q2.csv** | 진행 중 outreach 시드 (30명, status 추적) |

### 이 파일

| 파일 | 용도 |
|------|------|
| **README_STARTER_KIT.md** (이 파일) | 마스터 인덱스 |

---

## 3. 읽는 순서 (최단 경로)

```
README (2분)
    ↓
URM_MASTER_ARCHITECTURE §1-§4 (5분)    ← URM vision + 통일 패턴 파악
    ↓
KICKOFF §1 직전 상태 (2분) → §2 환경 검증 SQL 실행 (3분)
    ↓
PROJECT_CONTEXT §1-§3 사업 맥락 (2분)
    ↓
작업 시작 — KICKOFF §3 의 Phase 표에서 선택
       
[작업 중 lookup]
    → URM_MASTER_ARCHITECTURE §4 (새 module 추가 시)
    → URM_MASTER_ARCHITECTURE §3 (6 building blocks 패턴)
    → SCHEMA_GOTCHAS §0 (helper 표 — 작업 전 항상)
    → DB_SCHEMA_REFERENCE 해당 테이블 카드
    → safe_insert_templates 해당 TEMPLATE
    → SCHEMA_GOTCHAS §1-§10 함정 카테고리
```

---

## 4. 버전 이력 + Phase 진행 상태

### Phase 0 — 완료 (2026-05-19 세션)

**Phase 1+2 introspection:**
- ✅ 31 enums + 41 functions + 272 RLS policies + 5 views + 128 triggers + 451 indexes + 14 함수 본문

**🔴 Critical 정정 (3건):**

1. **partner 매핑** — VC 측 partner 는 `module='investor'` + `party_type='individual'` + `parent_party_id=firm.id`
   - 영향: `PROJECT_CONTEXT §10`, `DB_SCHEMA_REFERENCE §1.4 + parties 카드`, `SCHEMA_GOTCHAS §10.1`, `safe_insert_templates Template 2b + 4`

2. **`ingest.runs.module` vs `parties.module` 두 컨텍스트 분리**
   - `runs.module` (text): `'investor_partner'` 유효
   - `parties.module` (enum): 9 값, `investor_partner` 없음

3. **10개 테이블 RLS 비활성** — `investor_partner_profile` (119) 등 multi-tenant 운영 전 ALTER 필요

**🟢 마이그레이션 적용:**
- `investor_subtype_meta` (10 rows, 트라이링구얼)
- `partner_seniority_meta` (6 rows, outreach_score_weight 포함)
- `v_investor_subtype_options`, `v_partner_seniority_options` views
- Footprint Coalition `direct_fit` 태그

**🟢 작업 산출물:**
- Outreach Top 30 시드 CSV
- `migration_person_firm_history_2026Q2.sql` 작성 (실행 대기)
- **URM Master Architecture v1 작성** — 10 원칙 + 6 phase plan

### Phase 2 — 완료 (2026-05-19 세션)

**`person_firm_history` 적용 완료:**
- ✅ 테이블 + 6 indexes + RLS 4 policies
- ✅ 119 backfill (investor_partner_profile 전체)
- ✅ Views: `v_person_career_history`, `v_firm_alumni`
- ✅ Trigger: `sync_parent_from_primary_firm()` — primary current 행을 parties.parent_party_id 로 자동 동기화
- ✅ 검증: synced=119, mismatch=0
- ⚠️ 1900-fix: `GREATEST(NULL, x) = x` PostgreSQL 동작으로 87 행 1900 적재 → UPDATE 로 2020 통일

### Phase 1 (filler) — 완료 (2026-05-19 세션)

**Cleanup + filler_supplier_profile 적용 완료:**
- ✅ `app.parties module=filler`: 414 → 260 rows (134 buckets soft-deleted)
  - Cat 1 bracket buckets (25): `[Other]%` / `[Sector]%` / `[TEST]%` / `[미등록]%`
  - Cat 2 descriptor pseudo-buckets (~62): Chinese gray-market, Domestic X limestone, imports 류
  - Cat 3 Artemyn legacy duplicates (40): "Artemyn (former Imerys paper assets)" all empty
  - Cat 4 near-duplicate consolidation (8): Arabian Cement → Arabian Cement Company 등
- ✅ Systemic ingest bug 봉합: `supply_model` 컬럼의 corporate URL 113 rows → `parties.website` 이전
- ✅ `app.filler_supplier_profile` (260 rows): 4 도메인 + 3 메타 + audit
- ✅ `app.filler_supplier_contact_profile` (0 rows, schema-only)
- ✅ View `v_filler_suppliers` — firm + profile + parent linking + has_full_supplier_data flag
- ✅ RLS 8 policies + 2 trigger
- 💡 발견: 3-tier hierarchy 부분 적용됨 (Omya 의 country variants 20+ 가 "Omya (HQ)" 로 parent linking)

### Phase 1 (paper_mill) — 🟡 보류 (데이터 부재)

1,070 paper_mill rows 가 V11.4 industry_master 의 `[Sector]` country-level bucket. 8 도메인 키 모두 schema 만 있고 값 99% NULL. profile 승격 가치 없음. **V11.5 ingest 또는 별도 mill-level 데이터 들어올 때까지 동결.**

### Phase 3-6 — 향후 (URM_MASTER_ARCHITECTURE §6 참조)

| Phase | 산출물 | 시간 | 상태 |
|-------|--------|------|:----:|
| **4** | activity_status + phone + find_similar_persons() + view | 60-90분 | 🔴 **다음 권장** |
| 3 | engagement_participants | 60분 | 🔴 |
| 5 | govt_grant module (enum 이미 있음) | 30-45분 | 🔴 |
| 6 | Unified reporting views | 60-90분 | 🔴 |
| (보너스) | filler 측 helper `ingest.promote_filler_suppliers` | 30분 | 🔴 |
| (보너스) | 3-tier hierarchy 전체 audit | 30분 | 🔴 |

→ 권장 시작: **Phase 4 (activity_status + dedup)** — Phase 1 발견 multi-country variants (Specialty Minerals 95, Omya 39 등) dedup 인프라.

---

## 5. Quick Reference Card — 자주 헷갈리는 것

### 5.1 VC partner 적재
```
parties.module        = 'investor'::app.module_type      ⭐ NOT 'partner'
parties.party_type    = 'individual'::app.party_type
parties.parent_party_id = <firm.id>
```

### 5.2 Ingest run 시작
```sql
ingest.start_run(p_module := 'investor_partner', ...)    ⭐ text 리터럴
ingest.promote_investor_partners(label)                  ⭐ 헬퍼
```

### 5.3 portfolio_companies 적재
```sql
SELECT ingest.upsert_portfolio_company(org, name, web, country, sector)
-- 직접 INSERT 시 name_normalized 수동 (trigger 없음)
```

### 5.4 핵심 enum 함정
- `app.meetings.meeting_type` = text + CHECK, enum `app.meeting_type` 과 별개
- `parties.module` enum 9 값: investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier

### 5.5 RLS 비활성 테이블 (multi-tenant 운영 전 ALTER 필요)
- 🔴 `app.investor_partner_profile`, `app.portfolio_companies`, `app.meetings`
- 🟢 (운영상 OK) `app.email_templates`, `app.email_whitelist`, `app.mailcarrier_state`, `app.saved_views`, `app.plant_supply_links`, `ingest.rows`, `ingest.runs`

### 5.6 ⭐ 새 module 추가 (URM 통일 패턴) — URM_MASTER_ARCHITECTURE §4
```sql
-- Step 1: enum 확장
ALTER TYPE app.module_type ADD VALUE '<new_module>';
-- Step 2: profile 테이블 2개 (firm + contact) 생성 (cookbook 패턴)
-- Step 3: helper 함수 (선택)
```

### 5.7 ⭐ Investor subtype dropdown (Phase 0 완료)
```sql
SELECT code, display_name_ko, firm_count 
  FROM app.v_investor_subtype_options 
 ORDER BY sort_order;
-- has_data=false 면 dropdown disable 가능
```

### 5.8 ⭐ Person career history (Phase 2 완료)
```sql
-- 한 사람의 전체 이력
SELECT person_name, firm_name, title_text, role_category, 
       joined_at, COALESCE(left_at::text, '현재') AS left_at, years_at_firm
  FROM app.v_person_career_history
 WHERE person_name = '<name>'
 ORDER BY joined_at DESC;

-- 한 firm 의 alumni + 현직원
SELECT person_name, title_text, joined_at, left_at, 
       tenure_status, current_firm_name, current_title
  FROM app.v_firm_alumni
 WHERE firm_name = '<firm>'
 ORDER BY left_at DESC NULLS FIRST;
```

### 5.9 ⭐ Filler supplier search (Phase 1 완료)
```sql
-- High-quality data 있는 filler 만 (UI 우선 표시용)
SELECT firm_name, country_code, supplier_type, market_role, supply_model, onsite_pcc_evidence
  FROM app.v_filler_suppliers
 WHERE has_full_supplier_data = true
 ORDER BY firm_name;

-- 한 supplier 의 country variants (parent_party_id 활용)
SELECT firm_name, country_code, supplier_type, supply_model
  FROM app.v_filler_suppliers
 WHERE firm_name LIKE 'Omya%'   -- 또는 parent_name = 'Omya (HQ)'
 ORDER BY country_code;
```

### 5.10 ⚠️ PostgreSQL GREATEST NULL 함정 (Phase 2 후 발견)
```sql
-- NULL fallback 의도 시 GREATEST 의 NULL-무시 동작에 주의
GREATEST(NULL, 1900)       -- = 1900 (NULL 이 무시됨!)
COALESCE(GREATEST(...), x) -- COALESCE 가 영원히 fallback 안 함

-- 올바른 패턴:
CASE WHEN col IS NULL THEN default_val ELSE make_date(GREATEST(col,1900),1,1) END
```

### 5.11 ⚠️ Systemic ingest bug 패턴 (Phase 1 발견)
이전 ingest 가 컬럼을 잘못 매핑한 경우 발견 (filler 의 `module_data->>'supply_model'` 에 corporate URL 박힘, 113 rows). 새 module migration 전 컬럼 misuse scan 필수:
```sql
-- URL/email/phone 등이 엉뚱한 컬럼에 있는지 scan
SELECT id, name, module_data->>'X' AS suspicious_X
  FROM app.parties
 WHERE module = 'Y'::app.module_type AND deleted_at IS NULL
   AND module_data->>'X' LIKE 'http%';
```

### 5.12 🗑️ Bucket / placeholder cleanup 원칙 (사용자 합의)
- "검색 가능한 entity 만 의미. Bucket/aggregate 는 garbage" — 합의 2026-05-19
- 발견 패턴:
  - `[Other]%`, `[Sector]%`, `[TEST]%`, `[미등록]%` — 모두 bracket prefix bucket
  - `<Country/Region> imports`, `Chinese gray-market`, `Domestic X limestone` — descriptor pseudo-bucket
  - `<Firm> (former <OldName> assets)` × N empty — legacy duplicate
- 처리: soft-delete (`deleted_at = now()`) + `notes` 에 cleanup 사유 기록

---

## 6. 작업 종료 시 (이 starter kit 갱신)

작업 끝나면 다음 파일들 새 버전 export:

1. **URM_MASTER_ARCHITECTURE §6** — Phase 표 업데이트 (완료된 Phase 표시)
2. **변경된 starter kit 파일** — 모든 핵심 문서를 outputs 로 출력
3. **CSV / 작업 산출물** — `outreach_seed_top30_2026Q2.csv` 처럼 진행 중 작업
4. **KICKOFF §1 갱신** — "직전 세션 상태" 업데이트
5. **이 README §4 갱신** — Phase 진행 상태 표

다음 세션은 새 파일들로 즉시 진행 가능.

---

## 7. 비상 시 — Starter Kit 안에서 답 못 찾을 때

- **Schema 신규 정보 필요:** `db_schema_introspect_v2.sql` Section 9-15 재실행
- **새 마이그레이션 적용된 듯:** KICKOFF §2 Step 4 (enum/table 수 비교)
- **함수 본문 다시 보고 싶음:** Phase 2 Section 14 SQL 재실행
- **사용자 본인 적재 우려:** PROJECT_CONTEXT §7.1 (익명 처리 정책)
- **한국 firm 발견:** PROJECT_CONTEXT §2 (즉시 skip)
- **새 module 추가 패턴 모르겠음:** URM_MASTER_ARCHITECTURE §4 Cookbook
- **Phase 작업 순서 모르겠음:** URM_MASTER_ARCHITECTURE §6 + §7 (의존성 그래프)
