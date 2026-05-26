# SESSION HANDOFF — 2026-05-19 (A3 cleanup + A2 dedup 인프라)

> **세션 범위:** 3-tier hierarchy audit + filler 추가 cleanup + Phase 4 [A2] dedup 인프라 도입
> **소요 시간:** 한 세션 (대략 2-3 시간)
> **이전 세션:** Phase 0 + Phase 1 (filler) + Phase 2 완료
> **다음 세션 권장:** Cat 1 cleanup (Imerys / Schaefer Kalk / Carmeuse, 45-60분)

---

## TL;DR

A2 dedup 인프라 도입 완료. 새 entity 적재 전 자동 중복 확인 가능. acceptance test 통과 (EGM 1.00 / Q-min 0.88 / Mikron-S 0.79). **Imerys 38 행 mass-duplicate (703 pair) 발견** — 다음 cleanup target.

---

## 1. DB 변경 — Before / After

### parties (active)

| module | Before | After | 변화 |
|--------|------:|------:|-----:|
| filler | 260 | **235** | -25 (Cat 2 19 + Cat 3 한국 본사 6) |
| paper_mill | ~1,073 | ~1,073 | 보류 |
| investor | 243 | 243 | — |
| 기타 | ~188 | ~188 | — |
| **합계 (active)** | ~1,764 | **~1,739** | -25 |

### filler_supplier_profile

| 항목 | Before | After |
|------|------:|------:|
| rows | 260 | **235** (orphan 25 hard-delete) |

### Schema 신규

| 종류 | 신규 | 이름 |
|------|:----:|------|
| enum | 1 | `app.activity_status` (active/on_leave/retired/deceased/unknown) |
| 컬럼 | 3 | `parties.activity_status` / `phone_e164` / `phone_normalized` |
| index | 3 | GIN trgm × 2 (name, phone) + B-tree × 1 (phone), 모두 partial WHERE deleted_at IS NULL |
| 함수 | 3 | `normalize_phone()` / `find_similar_parties()` / `find_similar_persons()` |
| view | 2 | `v_party_dedup_candidates` / `v_person_dedup_candidates` |

---

## 2. Acceptance Test 결과

### Cat 4 near-dup 자동 발견 (filler module) ✅

| pair | similarity | match_kind |
|------|:----------:|------------|
| EGM Wierzbica ↔ EGM (Wierzbica) | **1.00** | name_trgm |
| Quality Minerals Public Co. (Q-min) ↔ ...Public Co., Ltd. (Q-min) | 0.88 | name_trgm |
| Mikron-S Mikronize (TURKCARB) ↔ ...Mineral (TURKCARB) | 0.79 | name_trgm |

### Same-root-ancestor 자동 제외 ✅

Specialty Minerals 95 variants 끼리 dedup candidate: **363 → 0** (recursive CTE 적용 후)

### 즉시 가치 발견

1. **investor / individual 3 pair** (`v_person_dedup_candidates`):
   - Brian Smith × 2 — 별개 인물 (LinkedIn 다름)
   - **Lior Susan × 2 — multi-firm 가능성 (Eclipse Ventures + Galvanize Climate Solutions). LinkedIn 검증 후 merge 결정**
   - Heather Mack ↔ Mack Healy — false positive
2. **filler Cat 4 (3 쌍)** — 위 표
3. **Imerys 38 행 mass-duplicate (703 pair)** — Cat 1 cleanup 명확한 target

---

## 3. 의사결정 메모 (Why)

### 3.1 외국 firm 의 KR variant 처리 — 좁은 해석 채택

PROJECT_CONTEXT §2 "한국 firm 적재 금지" 의 해석:
- ❌ 넓은 해석: country_code='KR' 인 모든 row 금지 → Omya HQ child 38 → 37 됨
- ✅ **좁은 해석 (채택):** 본사가 한국인 firm 만 금지

근거:
- Imerys Korea / Omya (Korea) / Specialty Minerals (Korea) 는 외국 본사의 한국 자회사 — 영업 충돌 가능성 없음
- 3-tier hierarchy 일관성 (Specialty 45 / Omya 38 child 카운트) 보존
- 사용자 본인 활동 보호의 의도는 한국 본사 firm 만 적용

### 3.2 Dedup 함수 — generic + wrapper 패턴

- `find_similar_parties()` 가 generic (firm + person 모두 cover)
- `find_similar_persons()` 는 `party_type='individual'` 강제 wrapper
- 미래에 `find_similar_firms()` 도 같은 패턴으로 추가 가능

### 3.3 Threshold 0.5 hard floor — view 안 minimum

- view 안에 `similarity >= 0.5` hard floor 두고, caller 가 더 높은 threshold (0.6, 0.7) 로 추가 filter
- 0.5 미만은 noise (Heather Mack ↔ Mack Healy 케이스 예방)
- 사용자가 `WHERE match_kind IN ('both','phone_exact')` 같이 종류별 filter 도 가능

### 3.4 Recursive CTE depth 5 — 무한 루프 방지

현재 hierarchy 3-tier (group_hq → country_entity → plant) 라 depth 5 충분. 향후 더 깊은 tier 도입 시 view 재정의 필요.

### 3.5 Soft-delete 우선 — Hard-delete 는 profile orphan 만

- parties 의 cleanup 25 행: `deleted_at = now()` + `notes` 에 cleanup 사유 (escape hatch)
- filler_supplier_profile orphan 25 행: `DELETE` (FK 정합성 위해)

---

## 4. 발생한 함정 + 회피 메모

### 4.1 Cat 3 UPDATE 의 WHERE 절 너무 광범위

내가 작성한 `WHERE country_code = 'KR'` 가 외국 본사 KR variant 3 행 (Imerys Korea / Omya / Specialty Korea) 까지 잡음. dry-run 결과 (8 행 — 기대 2) 의 차이를 사용자에게 검토 요청 전에 BEGIN-COMMIT 가 실행됨.

**복구:** 좁은 해석 채택해서 3 행 deleted_at = NULL 로 복원. notes 에서 cleanup 라인만 regexp 로 제거.

**교훈:** dry-run 결과의 카운트가 기대치와 다르면 즉시 짚고 의도 재확인 후 진행.

### 4.2 COMMENT ON ... IS 의 `||` syntax error

```sql
COMMENT ON VIEW ... IS 'line 1 ' || 'line 2';  -- ERROR
```

PostgreSQL 의 COMMENT ON 은 string literal only. expression 불가. 전체 트랜잭션 ROLLBACK 야기.

**해결:** 한 줄 string 으로 합쳐서 재시도. SCHEMA_GOTCHAS §13.1 에 기록.

### 4.3 컬럼명 추정 실수 — supply_links / person_firm_history

- `plant_supply_links.mill_party_id` (추정) → 실제 `paper_mill_plant_id`
- `person_firm_history.party_id` (추정) → 실제 `person_party_id`

**교훈:** schema 카드 확인 후 SQL 작성. 추정 절대 금지.

### 4.4 기존 trigram index 와 중복

`parties.name_normalized` 에 이미 `idx_parties_name_normalized` GIN trgm index 있는데 신규 partial (`_trgm`) 도 만듦. 기능 영향 없지만 storage 중복.

**조치:** 별도 cleanup 작업으로 기존 DROP 권고. SCHEMA_GOTCHAS §13.5.

---

## 5. Migration 파일

`migration_A2_dedup_2026Q2.sql` — 단일 idempotent migration:
- `CREATE TYPE IF NOT EXISTS` (DO block guard)
- `ALTER TABLE ADD COLUMN IF NOT EXISTS`
- `CREATE INDEX IF NOT EXISTS`
- `CREATE OR REPLACE FUNCTION / VIEW`
- 끝 검증 SELECT + COMMIT

재실행 안전. 새 환경에 적용하려면 그대로 실행 가능.

---

## 6. 후속 작업 — 우선순위 정렬

| Phase | 산출물 | 시간 | 우선순위 | 비고 |
|-------|--------|------|:----:|------|
| **Cat 1 cleanup** | Imerys (42) / Schaefer Kalk (12) / Carmeuse (3) HQ 신설 + linking | 45-60분 | 🔴 **다음** | A2 dedup view noise 의 명확한 source |
| Phase 3 | engagement_participants | 60분 | 🟡 | dedup 인프라 후 자연스러운 다음 |
| Lior Susan merge | LinkedIn 검증 후 multi-firm 케이스 처리 | 15분 | 🟡 | URM 원칙 7 의 첫 실용 사례 |
| 중복 index 정리 | `idx_parties_name_normalized` (구) DROP | 5분 | 🟢 | A2 cleanup |
| Phase 5 | govt_grant module | 30-45분 | 🟢 향후 | URM_MASTER §4 cookbook 활용 |
| Phase 6 | Unified reporting views | 60-90분 | 🟢 향후 | |

---

## 7. 새 세션에서 즉시 컨텍스트 복원하는 법

1. **README v5** (12 KB, 2분) — 마스터 인덱스 + Quick reference
2. **KICKOFF v6** (15 KB, 5분) — 직전 상태 + 환경 검증 SQL
3. **URM_MASTER v4 §1-4** (16 KB, 5분) — 10 원칙 + 7 building blocks + cookbook

작업 중 lookup:
- **DB_SCHEMA_REFERENCE v2.4** — 테이블 카드 + A2 함수/view 카드 (§4 + §4.1)
- **SCHEMA_GOTCHAS v3.3 §13** — A2 활용 패턴 + 발생한 함정 회피
- **migration_A2_dedup_2026Q2.sql** — A2 코드 reference

---

## 8. Reproducibility — 새 환경에서 재현

```bash
# 1. Migration 파일들 순서대로 적용
psql -f migration_subtype_seniority_meta_2026Q2.sql
psql -f migration_person_firm_history_2026Q2.sql
psql -f migration_filler_cleanup_2026Q2.sql
psql -f migration_filler_supplier_profile_2026Q2.sql
psql -f migration_A2_dedup_2026Q2.sql  # ← 이 세션

# 2. 검증 (KICKOFF §2 의 Step 1-3 SQL)
# → 11 테이블 카운트 + A2 산출물 + dedup view sanity

# 3. Acceptance test (filler Cat 4 자동 발견)
psql -c "SELECT * FROM app.v_party_dedup_candidates 
         WHERE module='filler'::app.module_type 
           AND (name_a ILIKE 'EGM%' OR name_a ILIKE 'Quality Minerals%' OR name_a ILIKE 'Mikron-S%')
         ORDER BY similarity_score DESC;"
# 기대: 3 행
```

---

**작성:** 2026-05-19 (Claude 세션)
**Starter kit 버전:** README v5 / KICKOFF v6 / URM v4 / DB_SCHEMA_REFERENCE v2.4 / SCHEMA_GOTCHAS v3.3
