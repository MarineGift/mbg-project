# NEXT_SESSION_KICKOFF — 새 Claude 세션 시작 가이드 (v6)

> **버전:** 2026-05-19 v6 (Phase 4 [A2] 완료 — activity_status + phone + 통합 dedup 인프라. Cat 4 acceptance 통과. Person dedup view 가 즉시 가치 3 종 발견)
> **목적:** 새 세션이 첫 메시지에서 즉시 생산성 발휘하도록.
> **이 문서의 위치:** starter kit 첨부 후 Claude 가 README → **이 문서** → URM_MASTER_ARCHITECTURE → 작업 phase 진행.

---

## 0. 첨부 파일 — Starter Kit (이번 세션 산출물 포함)

| 순서 | 파일 | 버전 | 역할 |
|------|------|------|------|
| 0 | **README_STARTER_KIT.md** | v5 | 마스터 인덱스 + 변경 이력 |
| 1 | **URM_MASTER_ARCHITECTURE.md** ⭐ | v4 | 10 원칙 + 6 building blocks + Phase plan (Phase 4 ✅) |
| 2 | **NEXT_SESSION_KICKOFF.md** (이 문서) | v6 | 시작 가이드 + 직전 상태 + 환경 검증 |
| 3 | **DB_SCHEMA_REFERENCE.md** | v2.4 | DB 구조 (parties 3 컬럼 + dedup 함수 + dedup view 추가) |
| 4 | **SCHEMA_GOTCHAS.md** | v3.3 | DB 함정 + dedup 활용 패턴 + GIN trgm tips |
| 5 | **migration_filler_cleanup_2026Q2.sql** | — | ✅ 적용 완료 (Phase 1, 414→260) |
| 6 | **migration_filler_supplier_profile_2026Q2.sql** | — | ✅ 적용 완료 (Phase 1, 260 backfill) |
| 7 | **migration_person_firm_history_2026Q2.sql** | — | ✅ 적용 완료 (Phase 2, 119 backfill) |
| 8 | **migration_subtype_seniority_meta_2026Q2.sql** | — | ✅ 적용 완료 (Phase 0) |
| 9 | **migration_A2_dedup_2026Q2.sql** ⭐ | — | ✅ **적용 완료** (Phase 4 [A2], 이 세션) |

**읽기 순서:** 0 → **1 (URM Master Arch)** → 2 (이 문서) → 3 → 4 → (5-9 lookup)

---

## 1. 직전 세션 상태 (2026-05-19, A2 완료)

### 1.1 완료된 일

**Phase 0+1+2 (이전 세션):**
- ✅ Phase 0 introspection + meta 테이블 (subtype + seniority)
- ✅ Phase 1 filler cleanup (414 → 260) + filler_supplier_profile 260 backfill
- ✅ Phase 2 person_firm_history 119 backfill + 2 views + sync trigger

**A3 cleanup (이 세션 전반):**
- ✅ 3-tier hierarchy audit — filler 측 260 active rows 의 party_level / parent_party_id 분포 매핑
  - group_hq 2 / country_entity 209 / plant 49 (모두 party_level 채워짐)
  - 3-tier 적용 firm: Specialty Minerals (95 variants, 1 HQ + 45 country + 49 plant) + Omya (39 variants, 1 HQ + 38 country)
- ✅ filler 추가 cleanup 25 행 (active 260 → 235)
  - Cat 2 descriptor bucket 19 행 (Local / regional ..., Domestic ... lime, X / regional ... 등)
  - Cat 3 한국 firm 6 행 (Hanil × 2, Sungshin × 2, Tongyang × 2)
- ✅ 외국 firm KR variant 3 행 복구 — Imerys Korea / Omya (Korea) / Specialty Minerals (Korea) 의도 외 cleanup 됐다가 복원
- ✅ filler_supplier_profile orphan 정리 — 260 → 235 (parties active 와 정합)
- ✅ supply_links 영향 확인 (plant_supply_links + party_supply_links 모두 0 ref ✓)

**A2 — Phase 4 dedup 인프라 (이 세션 후반):**
- ✅ **`app.activity_status` enum** (5 값: active / on_leave / retired / deceased / unknown)
- ✅ **`app.parties` 컬럼 3개:** `activity_status` / `phone_e164` / `phone_normalized`
- ✅ **Indexes:** GIN trgm on (name_normalized, phone_normalized) + B-tree on phone_normalized (모두 partial WHERE deleted IS NULL)
- ✅ **Functions:**
  - `app.normalize_phone(text) → text` (IMMUTABLE)
  - `app.find_similar_parties(7 args) → table` (STABLE, name trgm + phone exact)
  - `app.find_similar_persons(6 args) → table` (STABLE, party_type=individual wrapper)
- ✅ **Views:**
  - `app.v_party_dedup_candidates` — recursive root + same-parent + parent-child 자동 제외
  - `app.v_person_dedup_candidates` — wrapper
- ✅ **Acceptance test 통과:**
  - Cat 4 3 쌍 (EGM 1.00, Q-min 0.88, Mikron-S 0.79) 모두 자동 발견 ✓
  - Specialty Minerals 363 → 0 (recursive root 제외 검증) ✓
- 💡 **즉시 가치 3 종 발견:**
  - investor / individual / 3 pair (Brian Smith × 2 동명이인, Lior Susan × 2 multi-firm 가능성, Heather-Mack false positive)
  - filler Cat 4 표기 변형 3 쌍 (위)
  - **Imerys 38 행 mass-duplicate (703 pair)** — Cat 1 cleanup 명확한 next target

### 1.2 핵심 design 결정 (모든 문서에 반영됨)

1. 🔴 **partner 매핑** — VC 측 partner 는 `module='investor'` + `party_type='individual'` + `parent_party_id=firm.id`
2. 🔴 **두 module 컨텍스트** — `parties.module` (enum 9 값) vs `ingest.runs.module` (text)
3. 🟡 **RLS 비활성 테이블** — multi-tenant 운영 전 ALTER 필요 (person_firm_history + filler_supplier_profile + filler_supplier_contact_profile + A2 산출물은 RLS 켜져 있거나 view 라 무관)
4. 🟢 **사용자 10 원칙** — URM_MASTER §1
5. 🟢 **PostgreSQL GREATEST 함정** — `GREATEST(NULL, x) = x` (NULL 무시). SCHEMA_GOTCHAS §11.1.
6. 🟢 **데이터 정규화 원칙** — "검색 가능한 entity 만 의미. Bucket/aggregate 는 garbage." 사용자 합의.
7. 🟢 **systemic ingest bug 패턴** — supply_model URL leak 같은 cross-column placement 오류 가능.
8. 🟢 **외국 firm 의 KR variant 처리 정책** — 본사가 외국이면 KR entity 보존 (좁은 해석). PROJECT_CONTEXT §2 의 "한국 firm" = 본사 한국 firm 만 의미.
9. 🟢 **A2 dedup view 의 3-단계 제외 로직** — same-parent siblings + 직접 parent-child + same-root-ancestor (recursive). SCHEMA_GOTCHAS §12.

### 1.3 DB 현재 카운트 (2026-05-19 A2 완료 후)

```
app.parties                            1,739 (A3 25 net cleanup 반영)
  - module='filler' (active)             235  ← A3 후 (Phase 1 의 260 → 235)
  - module='paper_mill' (active)       ~1,073 (보류)
  - module='investor'                    243
  - 기타                                  ~188
app.investor_profile                     111
app.investor_partner_profile             119
app.portfolio_companies                  342
app.investor_portfolio_companies         445
app.lead_scores                        1,528
app.investor_subtype_meta                 10
app.partner_seniority_meta                 6
app.person_firm_history                  119
app.filler_supplier_profile              235  ← A3 후 (260 → 235)
app.filler_supplier_contact_profile        0
ingest.runs                               15
```

**A2 dedup view 검증 결과 (활용 reference):**
```
v_party_dedup_candidates 전체 pair: 2,848
  - paper_mill / company  : 1,910 (bucket noise, V11.5 ingest 전까지 동결)
  - filler     / company  :   891 (Imerys 703 + 진짜 Cat 4 + 기타)
  - investor   / company  :    44 (검토 후보)
  - investor   / individual:    3 (Brian Smith / Lior Susan / Heather-Mack)
```

---

## 2. 새 세션 첫 작업 — 환경 검증 (3분, 권장)

### Step 1. 핵심 11개 테이블 카운트

```sql
SELECT 'parties' t,                              COUNT(*) FROM app.parties
UNION ALL SELECT 'parties_active',               COUNT(*) FROM app.parties WHERE deleted_at IS NULL
UNION ALL SELECT 'parties_filler_active',        COUNT(*) FROM app.parties WHERE module='filler'::app.module_type AND deleted_at IS NULL
UNION ALL SELECT 'investor_profile',             COUNT(*) FROM app.investor_profile
UNION ALL SELECT 'investor_partner_profile',     COUNT(*) FROM app.investor_partner_profile
UNION ALL SELECT 'portfolio_companies',          COUNT(*) FROM app.portfolio_companies
UNION ALL SELECT 'investor_portfolio_companies', COUNT(*) FROM app.investor_portfolio_companies
UNION ALL SELECT 'lead_scores',                  COUNT(*) FROM app.lead_scores
UNION ALL SELECT 'investor_subtype_meta',        COUNT(*) FROM app.investor_subtype_meta
UNION ALL SELECT 'partner_seniority_meta',       COUNT(*) FROM app.partner_seniority_meta
UNION ALL SELECT 'person_firm_history',          COUNT(*) FROM app.person_firm_history
UNION ALL SELECT 'filler_supplier_profile',      COUNT(*) FROM app.filler_supplier_profile
ORDER BY 1;
```

### Step 2. A2 산출물 검증

```sql
SELECT 
  (SELECT array_agg(enumlabel ORDER BY enumsortorder)
     FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'activity_status') AS enum_values,
  (SELECT array_agg(proname ORDER BY proname)
     FROM pg_proc WHERE pronamespace = 'app'::regnamespace
      AND proname IN ('normalize_phone','find_similar_parties','find_similar_persons')) AS dedup_functions,
  (SELECT array_agg(viewname ORDER BY viewname)
     FROM pg_views WHERE schemaname = 'app'
      AND viewname IN ('v_party_dedup_candidates','v_person_dedup_candidates')) AS dedup_views;

-- 기대:
-- enum_values     : {active, on_leave, retired, deceased, unknown}
-- dedup_functions : {find_similar_parties, find_similar_persons, normalize_phone}
-- dedup_views     : {v_party_dedup_candidates, v_person_dedup_candidates}
```

### Step 3. Dedup view sanity

```sql
-- Cat 4 acceptance 재검증
SELECT name_a, name_b, similarity_score
  FROM app.v_party_dedup_candidates
 WHERE module = 'filler'::app.module_type
   AND (name_a ILIKE 'EGM%' OR name_a ILIKE 'Quality Minerals%' OR name_a ILIKE 'Mikron-S%')
 ORDER BY similarity_score DESC
 LIMIT 5;
-- 기대: EGM 1.0, Q-min 0.88, Mikron-S 0.79
```

---

## 3. 다음 즉시 작업 — Phase plan 진행

URM_MASTER_ARCHITECTURE §6 의 Phase 진행 상태:

| Phase | 산출물 | 시간 | 상태 | 우선순위 |
|-------|--------|------|:----:|:----:|
| 0 | introspection, 매핑 정정, meta 테이블 | — | ✅ DONE | — |
| 2 | `person_firm_history` 119 backfill + 2 views + sync trigger | 30분 | ✅ DONE | — |
| 1 (filler) | cleanup (414→235) + filler_supplier_profile + view | 90분 | ✅ DONE | — |
| 1 (paper_mill) | paper_mill_profile | — | 🟡 보류 (데이터 부재) | 🟢 V11.5 ingest 들어오면 |
| **4** | activity_status + phone + dedup 인프라 (A2) | 90-120분 | ✅ DONE | — |
| **Cat 1 cleanup** | Imerys (42행) / Schaefer Kalk (12) / Carmeuse (3) HQ 신설 + linking | 45-60분 | 🔴 TODO | **🔴 다음 권장** |
| 3 | engagement_participants (firm-centric) | 60분 | 🔴 TODO | 🟡 |
| 5 | 새 module (govt_grant) | 30-45분 | 🔴 TODO | 🟢 향후 |
| 6 | Unified reporting views | 60-90분 | 🔴 TODO | 🟢 향후 |
| (보너스) | filler 측 helper `ingest.promote_filler_suppliers` | 30분 | 🔴 TODO | 🟢 새 filler 적재 시 |
| (보너스) | Lior Susan multi-firm merge | 15분 | 🟡 검토 후 결정 | 🟡 LinkedIn 검증 후 |
| (보너스) | 중복 trigram index 정리 (`idx_parties_name_normalized` vs `_trgm`) | 5분 | 🟡 | 🟢 |

### 3.1 권장 시작 — Cat 1 cleanup (Imerys / Schaefer Kalk / Carmeuse)

A2 dedup view 가 발견한 명확한 cleanup target. 작업 패턴:

1. **HQ 신설** — 3 firm 각각의 group_hq row 생성 (country = 본사 국가)
2. **38 Imerys duplicate row** — country_code 만 다른 빈 row 들을 의미 있는 country_entity 로 transform 또는 consolidate
3. **`parent_party_id` linking** — Specialty/Omya 패턴 복제
4. **검증** — A2 dedup view 의 Imerys 703 pair 가 0 으로 감소 확인

→ Phase 1 의 "3-tier hierarchy 전체 적용" 마무리 작업. 45-60분.

### 3.2 대안 — Phase 3 (engagement_participants, 60분)

dedup 인프라가 갖춰진 상태에서 engagement 측 multi-person attribution 도입. URM_MASTER §3 Block 5.

### 3.3 대안 — Lior Susan multi-firm 검토 (15분)

`https://www.linkedin.com/in/lior-susan` 으로 두번째 row (Galvanize Climate Solutions) 도 같은 사람인지 확인. 같은 사람이면 person_firm_history 두 행 분리 + 한 party_id 로 통합. URM_MASTER §1 원칙 7 의 첫 실용 사례.

---

## 4. 첫 메시지 시 Claude 가 해야 할 일

새 세션 첫 응답에서:

1. **첨부 파일 확인** — 9개 모두 있는지
2. **URM_MASTER §1-4 요약** — vision 한 번 재확인
3. **KICKOFF §2 환경 검증** 권유 — DB 카운트 + A2 산출물 + dedup view sanity
4. **Phase 진행 상태 확인** — §3 표 보여주고 사용자 선택 받기
   - Cat 1 cleanup (45-60분) — 권장
   - Phase 3 engagement_participants (60분)
   - Lior Susan 검토 (15분)
   - 또는 사용자 다른 우선순위

**금기사항:**
- DB 구조 추측 금지 — DB_SCHEMA_REFERENCE 참고
- 한국 firm 적재 금지 (단, 외국 본사의 KR variant 는 OK — 좁은 해석)
- 사용자 본인 정보 적재 금지
- 한국어 응답 + SQL 영문
- 🔴 VC partner 적재 시 `module='partner'` 사용 X — `module='investor'` + `party_type='individual'`
- 🔴 새 module 추가 시 URM_MASTER §4 cookbook 따름
- 🔴 dedup 작업 시 view 결과는 candidate 일 뿐 — 자동 merge 금지. 사용자 검토 후 결정.

---

## 5. 자주 발생하는 첫 메시지 패턴 + 대응

### "이전 세션 어디까지 했지?"
→ 이 §1 + URM_MASTER §6 Phase 표 보여주고 사용자에게 다음 단계 선택권.

### "Cat 1 cleanup 진행하자" (Imerys/Schaefer Kalk/Carmeuse)
→ 1. 각 firm 의 HQ row DDL draft (Specialty Minerals (HQ) 패턴 카피)
  2. 38 Imerys duplicate row 의 처리 방안 (country_entity 로 promote vs 일부 soft-delete)
  3. parent_party_id linking SQL
  4. 검증: dedup view 에서 Imerys pair 감소 확인

### "Phase 3 진행하자" (engagement_participants)
→ URM_MASTER §3 Block 5 + §6 참조. DDL → backfill 불필요 (신규 테이블) → view 작성.

### "X firm 추가해줘"
→ X 가 fit 기준 충족 확인 → D1 diagnostic → web search → ingest 3-step → A2 dedup view 로 중복 확인

### "Lior Susan multi-firm 처리해줘"
→ LinkedIn 확인 후, 같은 사람이면:
  1. 두 party_id 중 하나를 primary 로 선택
  2. person_firm_history 두 행 생성 (Eclipse Ventures + Galvanize)
  3. 다른 party_id soft-delete
  4. investor_partner_profile 정합 확인

### "새 module (예: govt_grant) 추가해줘"
→ URM_MASTER §4 Cookbook 따라 3-step 진행

### "dedup candidate 검토해줘"
→ `app.v_party_dedup_candidates` 결과 가져와서 분류 (진짜 dup / multi-firm / false positive / 동명이인)

---

## 6. 세션 종료 시 (다음 세션 위한 handoff)

작업 끝낼 때:
1. 추가/변경된 데이터 카운트 갱신 (§1.3)
2. 발견한 새 인사이트 메모
3. 다음 세션 즉시 작업 후보 명시
4. 이 KICKOFF §1 (직전 세션 상태) 업데이트
5. URM_MASTER §6 Phase 표 업데이트
6. 변경된 starter kit 파일 새 버전 export

---

## 7. 안전 체크리스트 (매 작업 전 확인)

- [ ] URM_MASTER 의 6 building blocks 패턴 따름?
- [ ] 한국 본사 firm 아닌가? (외국 본사의 KR variant 는 OK)
- [ ] DB_SCHEMA_REFERENCE 에서 해당 테이블 카드 확인?
- [ ] SCHEMA_GOTCHAS 의 helper 함수 + A2 dedup 활용 확인?
- [ ] D1-D6 diagnostic 쿼리로 사전 검증?
- [ ] Idempotent 패턴 (ON CONFLICT / WHERE NOT EXISTS / CREATE OR REPLACE)?
- [ ] 🔴 VC partner 적재 시 `module='investor'` + `party_type='individual'` + `parent_party_id`?
- [ ] 🔴 새 entity 적재 전 dedup view 로 중복 확인? (`app.find_similar_parties(name, ...)`)
- [ ] 트랜잭션 (BEGIN ... COMMIT) 사용?
- [ ] 사용자 익명 처리 유지?
- [ ] 한국어 응답 + 영문 SQL?

11개 모두 ✓ 면 안전하게 진행.
