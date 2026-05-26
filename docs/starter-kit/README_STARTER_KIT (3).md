# README — URM Platform Starter Kit (2026-05-19 v5)

> **이 파일이 마스터 인덱스.** 새 Claude 세션 시작 시 가장 먼저 본다.

---

## 1. 이 Starter Kit 의 목적

`mbg-project` (URM Platform — Unified Relationship Management) 의 DB 작업을 새 Claude 세션에서 즉시 이어갈 수 있게 하는 자료 묶음.

**URM 의 vision:** 다양한 business module (투자자 / 정부지원사업 / paper mill / filler / sales / 향후 추가) 을 **동일한 통일 포맷**으로 추가/관리/조회/engagement 할 수 있는 B2B CRM 인프라.

**핵심 가치:**
- 새 세션의 첫 3분 안에 URM vision + DB 구조 + 사업 맥락 + 직전 작업 상태 파악
- 새 business module 추가 시 30-45분 (URM_MASTER §4 cookbook)
- INSERT 작성 전 함정 회피 (NOT NULL / CHECK / FK / UNIQUE / RLS)
- **A2 (Phase 4) 후:** 신규 entity 적재 전 dedup view 로 자동 중복 확인

---

## 2. 파일 구성

### 핵심 문서 (5) — 새 세션 필수 읽기

| 파일 | 버전 | 크기 (대략) | 첫 방문자 읽는 시간 |
|------|------|------|---------------------|
| **URM_MASTER_ARCHITECTURE.md** ⭐ | v4 | ~20 KB | 7분 (필수, 가장 먼저) |
| **NEXT_SESSION_KICKOFF.md** | v6 | ~16 KB | 5분 (필수) |
| **DB_SCHEMA_REFERENCE.md** | v2.4 | ~46 KB | 10분 (skim) |
| **SCHEMA_GOTCHAS.md** | v3.3 | ~28 KB | 5분 (skim) |
| **README_STARTER_KIT.md** (이 파일) | v5 | — | 2분 |

### Migration 산출물 (5, 모두 적용 완료, 참고용 보관)

| 파일 | 상태 | 적용 시기 |
|------|:----:|----------|
| **migration_subtype_seniority_meta_2026Q2.sql** | ✅ | Phase 0 |
| **migration_person_firm_history_2026Q2.sql** | ✅ | Phase 2 |
| **migration_filler_cleanup_2026Q2.sql** | ✅ | Phase 1 (filler 414→260) |
| **migration_filler_supplier_profile_2026Q2.sql** | ✅ | Phase 1 (filler_supplier_profile 260 backfill) |
| **migration_A2_dedup_2026Q2.sql** ⭐ | ✅ | **Phase 4 [A2] (이번 세션)** |

---

## 3. 읽는 순서 (최단 경로)

```
README (2분)
    ↓
URM_MASTER_ARCHITECTURE §1-§4 (5분)    ← URM vision + 통일 패턴 파악
    ↓
KICKOFF §1 직전 상태 (2분) → §2 환경 검증 SQL 실행 (3분)
    ↓
작업 시작 — KICKOFF §3 의 Phase 표에서 선택
       
[작업 중 lookup]
    → URM_MASTER §4 (새 module 추가 시)
    → URM_MASTER §3 (6 building blocks 패턴)
    → SCHEMA_GOTCHAS §0 (helper 표 — 작업 전 항상)
    → SCHEMA_GOTCHAS §12 (A2 dedup view 활용 패턴 — NEW)
    → DB_SCHEMA_REFERENCE 해당 테이블 카드
    → migration SQL 해당 패턴
```

---

## 4. 버전 이력 + Phase 진행 상태

### Phase 0 — 완료
- ✅ Phase 1+2 introspection (31 enums / 41 functions / 272 RLS / 5 views / 128 triggers / 451 indexes)
- ✅ Partner 매핑 정정 + meta 테이블 (`investor_subtype_meta` × 10 + `partner_seniority_meta` × 6)
- ✅ Outreach Top 30 시드 CSV

### Phase 2 — 완료
- ✅ `app.person_firm_history` + 6 indexes + RLS 4 policies + 2 views + sync trigger
- ✅ 119 backfill (investor_partner_profile 전체)
- ⚠️ 1900-fix 사후 적용 (PostgreSQL GREATEST NULL 함정)

### Phase 1 (filler) — 완료 + A3 추가 cleanup
- ✅ Cleanup 414 → 260 (Phase 1 본체) → **235 (A3 추가 cleanup, 이 세션)**
- ✅ `filler_supplier_profile` 235 backfill + 4 도메인 + 3 메타
- ✅ `filler_supplier_contact_profile` (schema-only)
- ✅ `v_filler_suppliers` view
- ✅ Systemic ingest bug 봉합 (`supply_model` URL leak, 113 rows)
- 💡 3-tier hierarchy 부분 적용 — Specialty Minerals (95 variants) + Omya (39) 만 적용. Imerys/Schaefer/Carmeuse 는 cleanup 대기.

### Phase 1 (paper_mill) — 🟡 보류
1,070 paper_mill rows 가 V11.4 industry_master 의 sector-level bucket. profile 승격 가치 없음.

### A3 (이 세션, 2026-05-19) — 완료
- ✅ 3-tier hierarchy audit — filler 측 party_level / parent_party_id 분포 매핑
- ✅ 25 행 cleanup (active 260 → 235)
  - Cat 2 descriptor bucket 19 (Local / regional, Domestic ... lime, X / regional 등)
  - Cat 3 한국 firm 6 (Hanil/Sungshin/Tongyang × 2)
- ✅ 외국 firm KR variant 3 행 복구 (Imerys Korea / Omya (Korea) / Specialty Minerals (Korea))
- ✅ supply_links 영향 0 확인 + filler_supplier_profile orphan 정리 (260 → 235)

### **A2 — Phase 4 (이 세션, 2026-05-19) — ✅ 완료**

**산출물:**
- `app.activity_status` enum (5 값)
- `parties.activity_status` / `phone_e164` / `phone_normalized` 컬럼 3개
- GIN trgm + B-tree partial index 3개
- `normalize_phone(text)` + `find_similar_parties(...)` + `find_similar_persons(...)` 함수 3개
- `v_party_dedup_candidates` (recursive root + 3 단계 제외) + `v_person_dedup_candidates` (wrapper) view 2개

**Acceptance test 통과:**
- Cat 4 (EGM 1.00 / Q-min 0.88 / Mikron-S 0.79) 자동 발견 ✓
- Specialty Minerals 363 → 0 (recursive root 제외) ✓

**즉시 가치 발견 3 종:**
1. investor / individual 3 pair (Brian Smith 동명이인 / Lior Susan multi-firm 가능성 / Heather-Mack false positive)
2. filler Cat 4 표기 변형 3 쌍 (위)
3. **Imerys 38 행 mass-duplicate (703 pair) — Cat 1 cleanup target**

### Phase 3-6 + Cat 1 cleanup — 향후

| Phase | 산출물 | 시간 | 상태 |
|-------|--------|------|:----:|
| **Cat 1 cleanup** | Imerys/Schaefer Kalk/Carmeuse HQ 신설 + linking | 45-60분 | 🔴 **다음 권장** |
| 3 | engagement_participants | 60분 | 🔴 |
| 5 | govt_grant module | 30-45분 | 🔴 |
| 6 | Unified reporting views | 60-90분 | 🔴 |
| (보너스) | filler 측 helper `ingest.promote_filler_suppliers` | 30분 | 🔴 |
| (보너스) | Lior Susan multi-firm merge | 15분 | 🟡 LinkedIn 검증 후 |
| (보너스) | 중복 trigram index 정리 | 5분 | 🟡 |

→ 권장 시작: **Cat 1 cleanup** — A2 dedup view 가 발견한 명확한 target.

---

## 5. Quick Reference Card

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
```

### 5.4 핵심 enum 함정
- `app.meetings.meeting_type` = text + CHECK, enum `app.meeting_type` 과 별개
- `parties.module` enum 9 값: investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier
  - **실제 사용:** filler 만 (`filler_supplier` 는 enum 에만 있고 0 row)

### 5.5 RLS 비활성 테이블 (multi-tenant 운영 전 ALTER 필요)
- 🔴 `app.investor_partner_profile`, `app.portfolio_companies`, `app.meetings`
- 🟢 (운영상 OK) `app.email_templates`, `app.email_whitelist`, `app.mailcarrier_state`, `app.saved_views`, `app.plant_supply_links`, `ingest.rows`, `ingest.runs`

### 5.6 ⭐ 새 module 추가 (URM 통일 패턴) — URM_MASTER §4
```sql
ALTER TYPE app.module_type ADD VALUE '<new_module>';
-- profile 테이블 2개 (firm + contact) 생성 (cookbook 패턴)
-- helper 함수 (선택)
```

### 5.7 ⭐ Investor subtype dropdown
```sql
SELECT code, display_name_ko, firm_count 
  FROM app.v_investor_subtype_options 
 ORDER BY sort_order;
```

### 5.8 ⭐ Person career history
```sql
SELECT person_name, firm_name, title_text, role_category, 
       joined_at, COALESCE(left_at::text, '현재') AS left_at, years_at_firm
  FROM app.v_person_career_history
 WHERE person_name = '<name>'
 ORDER BY joined_at DESC;

SELECT person_name, title_text, joined_at, left_at, 
       tenure_status, current_firm_name, current_title
  FROM app.v_firm_alumni
 WHERE firm_name = '<firm>';
```

### 5.9 ⭐ Filler supplier search
```sql
SELECT firm_name, country_code, supplier_type, market_role, supply_model, onsite_pcc_evidence
  FROM app.v_filler_suppliers
 WHERE has_full_supplier_data = true
 ORDER BY firm_name;
```

### 5.10 ⭐ A2 dedup view (NEW)
```sql
-- 모든 dedup candidate 보기 (firm + person)
SELECT name_a, name_b, country_a, country_b, similarity_score, match_kind, module::text
  FROM app.v_party_dedup_candidates
 ORDER BY similarity_score DESC
 LIMIT 50;

-- Person dedup 만
SELECT name_a, name_b, country_a, country_b, similarity_score
  FROM app.v_person_dedup_candidates
 ORDER BY similarity_score DESC;

-- 새 entity 적재 전 사전 확인
SELECT * FROM app.find_similar_parties(
  p_name => 'New Company Name',
  p_module => 'filler'::app.module_type,
  p_threshold => 0.5
);

-- Person 사전 확인
SELECT * FROM app.find_similar_persons(
  p_name => 'John Doe',
  p_phone => '+1-555-0123',
  p_module => 'investor'::app.module_type
);
```

**Dedup view 의 3 단계 자동 제외:**
1. same-parent siblings (같은 firm 의 country variants)
2. 직접 hierarchy (parent-child)
3. same-root-ancestor (recursive, group 전체)

→ 결과는 **검토 후 결정** — 자동 merge 금지. 동명이인 / multi-firm / false positive 가능성.

### 5.11 ⭐ Phone 정규화
```sql
-- 정규화: digits only
SELECT app.normalize_phone('+82-10-1234-5678');  -- '821012345678'
SELECT app.normalize_phone('(415) 555-0123');     -- '4155550123'
SELECT app.normalize_phone(NULL);                 -- NULL

-- Parties 적재 시: phone_e164 (표시용) + phone_normalized (계산 결과)
INSERT INTO app.parties (
  organization_id, name, module, party_type,
  phone_e164, phone_normalized
) VALUES (
  ..., '+1-512-555-0123', app.normalize_phone('+1-512-555-0123')
);
```

### 5.12 ⚠️ PostgreSQL GREATEST NULL 함정
```sql
GREATEST(NULL, 1900)       -- = 1900 (NULL 이 무시됨!)
-- 올바른 패턴:
CASE WHEN col IS NULL THEN default_val ELSE make_date(GREATEST(col,1900),1,1) END
```

### 5.13 ⚠️ Systemic ingest bug scan
새 module migration 전 컬럼 misuse scan 필수:
```sql
SELECT id, name, module_data->>'X' AS suspicious_X
  FROM app.parties
 WHERE module = 'Y'::app.module_type AND deleted_at IS NULL
   AND module_data->>'X' LIKE 'http%';
```

### 5.14 🗑️ Bucket / placeholder cleanup 원칙 (사용자 합의)
- "검색 가능한 entity 만 의미. Bucket/aggregate 는 garbage" — 2026-05-19
- 발견 패턴:
  - `[Other]%`, `[Sector]%`, `[TEST]%`, `[미등록]%` — bracket prefix bucket
  - `<Country/Region> imports`, `Chinese gray-market`, `Domestic X limestone` — descriptor pseudo-bucket
  - `Local / regional X (cluster)`, `X / regional ... suppliers`, `X / similar regional producers` — A3 추가 발견 패턴
  - `<Firm> (former <OldName> assets)` × N empty — legacy duplicate
- 처리: soft-delete (`deleted_at = now()`) + `notes` 에 cleanup 사유 기록

### 5.15 🗑️ 한국 firm 정책 — 좁은 해석 (A3 결정)
- "한국 firm 적재 금지" = **본사가 한국인 firm 만 금지**
- 외국 본사의 KR variant (Imerys Korea / Omya (Korea) / Specialty Minerals (Korea) 등) → **보존**
- A3 의 Hanil Cement / Sungshin / Tongyang 같은 한국 본사 firm 은 soft-delete

---

## 6. 작업 종료 시 (이 starter kit 갱신)

작업 끝나면 다음 파일들 새 버전 export:

1. **URM_MASTER §6** — Phase 표 업데이트 (완료된 Phase 표시)
2. **변경된 starter kit 파일** — 모든 핵심 문서를 outputs 로 출력
3. **migration SQL** — 적용한 작업 idempotent migration 파일로
4. **KICKOFF §1 갱신** — "직전 세션 상태" 업데이트
5. **이 README §4 갱신** — Phase 진행 상태 표

다음 세션은 새 파일들로 즉시 진행 가능.

---

## 7. 비상 시 — Starter Kit 안에서 답 못 찾을 때

- **Schema 신규 정보 필요:** introspection SQL 재실행
- **새 마이그레이션 적용된 듯:** KICKOFF §2 Step 4 (enum/table 수 비교)
- **함수 본문 다시 보고 싶음:** `pg_get_functiondef(oid)` 활용
- **사용자 본인 적재 우려:** 익명 처리 정책 준수 (한국 본사 firm 만 거부, 외국 본사 KR variant 는 OK)
- **새 module 추가 패턴 모르겠음:** URM_MASTER §4 Cookbook
- **Phase 작업 순서 모르겠음:** URM_MASTER §6 + KICKOFF §3
- **Dedup 작업 어떻게:** SCHEMA_GOTCHAS §12 + README §5.10
