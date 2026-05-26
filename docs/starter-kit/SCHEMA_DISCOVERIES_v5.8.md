# URM Platform v5.8 — Schema Discoveries 종합 가이드

**작성**: 2026-05-15 (Mondi family 작업 중)  
**목적**: Mondi family cleanup의 8회 iteration에서 발견한 hidden schema constraints를 다음 family 작업 (Stora Enso, UPM 등)에서 1회 통과하도록 가이드

---

## 1. 핵심 스키마 (industry schema)

### 1.1 `paper_companies` 테이블

| 컬럼 | 타입/제약 | 비고 |
|---|---|---|
| id | int (PK) | auto-increment |
| name | varchar | 검색 핵심 |
| **market_code** | varchar FK → `markets.code` | 필수 등록된 country만 |
| headquarters | varchar | 자유 텍스트 |
| **tier_role** | **ENUM** ('HQ','Regional','Country') | **'Sector' 없음** |
| evidence_level | varchar ('A','B','C','D') | 자유 텍스트 |
| main_product_category | varchar | |
| main_products | text | 자유 텍스트 |
| europe_mills_footprint | text | |
| source_url | varchar | |
| notes | text | |
| **legacy_id** | int + **UNIQUE(market_code, legacy_id)** | hidden! |

### 1.2 `paper_mills` 테이블

| 컬럼 | 타입/제약 | 비고 |
|---|---|---|
| id | int (PK) | |
| mill_name | varchar | |
| **market_code** | varchar FK → `markets.code` | |
| city | varchar | |
| main_products | text | |
| paper_company_id | int FK → paper_companies.id | |
| **tier_role 없음** | — | ⚠️ companies에만 있음 |
| **legacy_id** | int + **UNIQUE(market_code, legacy_id)** | hidden! |

### 1.3 `markets` 테이블 (참조)

| 컬럼 | 비고 |
|---|---|
| **code** | PK — 컬럼명 `market_code` 아님! |
| name | "Czech Republic" 등 |
| region | 'europe', 'americas', etc |
| created_at | timestamp |

**현재 등록된 국가 코드 예시** (확인된):  
`austria, germany, italy, slovakia, united_kingdom, poland, sweden, turkey, russia, south_africa, czech_republic*, bulgaria*, netherlands*, canada, europe_composite`  
(*표시는 v5.8 Step A-2.1에서 신규 추가)

### 1.4 `supplier_mill_linkages` 테이블 (참조)

- `paper_company_id` FK → paper_companies.id
- **DELETE 제약**: 참조된 paper_companies row는 DELETE 불가 → soft-delete 필요

---

## 2. 8회 iteration에서 발견한 5가지 hidden constraint

| # | Constraint | 증상 | 회피 방법 |
|---|---|---|---|
| 1 | `paper_companies_market_code_legacy_id_key` UNIQUE | market_code 변경 시 `(country, legacy_id) already exists` | market_code 변경 회피, headquarters/notes로만 표기 |
| 2 | `paper_mills_market_code_legacy_id_key` UNIQUE | mill market_code 변경 시 같은 에러 | DO BLOCK + EXCEPTION으로 graceful skip |
| 3 | `tier_role` PostgreSQL **ENUM** | 'Sector' 등 새 값 거부 (`invalid input value`) | 'HQ'/'Regional'/'Country' 또는 NULL만 사용 |
| 4 | `paper_mills.market_code` FK → `markets.code` | 미등록 country 사용 시 `not present in markets` | 사전 `INSERT INTO markets ON CONFLICT DO NOTHING` |
| 5 | `supplier_mill_linkages.paper_company_id` FK | 참조된 company DELETE 시 `still referenced` | soft-delete (`[OBSOLETE]` rename + tier_role=NULL) |
| 6 | `paper_mills`에 tier_role 컬럼 **없음** | CSV의 tier_role은 JOIN된 pc.tier_role | mill에 tier_role UPDATE 안 함 |

---

## 3. 안전한 마이그레이션 표준 패턴 (다음 family 자동 적용)

### 3.1 Stage 순서 (DO NOT CHANGE)

```sql
-- STAGE 0: 백업 (TEMP TABLE)
-- STAGE 1: paper_mills.paper_company_id 재할당 (FK 안전 최우선)
-- STAGE 2: 중복/오류 row SOFT-DELETE ([OBSOLETE] rename + tier_role=NULL)
-- STAGE 3: HQ + Regional 설정 (market_code 변경 회피)
-- STAGE 4: Country tier 설정
-- STAGE 5: family error row 정리 (DS Smith 같은 wrong family)
-- STAGE 6: Sector aggregate → NULL (supplier_mill_linkages 출처 row)
-- STAGE 7: paper_mills 정규화 (mill_name 광역 → 도시)
-- STAGE 8: sub-component mill soft-mark
-- STAGE 9: INSERT 누락 mill (DO BLOCK + EXCEPTION 패턴 필수!)
-- STAGE 10: 검증 쿼리 4개
```

### 3.2 market_code 변경 패턴 (DO BLOCK)

```sql
DO $$
BEGIN
  BEGIN
    UPDATE industry.paper_mills SET market_code = 'netherlands' WHERE id = 391;
  EXCEPTION 
    WHEN unique_violation THEN
      UPDATE industry.paper_mills SET 
        main_products = main_products || ' [market_code 유지 — legacy_id 충돌]'
      WHERE id = 391;
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'SKIP: market_code 미등록 in markets';
  END;
END $$;
```

### 3.3 INSERT 패턴 (DO BLOCK)

```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM industry.paper_companies WHERE lower(name) LIKE '%target%') THEN
    BEGIN
      INSERT INTO industry.paper_companies (...) VALUES (...);
      RAISE NOTICE 'INSERTED: target';
    EXCEPTION 
      WHEN foreign_key_violation THEN
        RAISE NOTICE 'SKIP — market 미등록';
      WHEN OTHERS THEN
        RAISE NOTICE 'SKIP — %', SQLERRM;
    END;
  END IF;
END $$;
```

### 3.4 markets 사전 등록 패턴

```sql
INSERT INTO industry.markets (code, name, region) VALUES 
  ('NEW_COUNTRY_CODE', 'Country Name', 'region')
ON CONFLICT (code) DO NOTHING;
```

### 3.5 SOFT-DELETE 패턴 (DELETE 대신)

```sql
UPDATE industry.paper_companies SET
  name = '[OBSOLETE] ' || name || ' (duplicate of id=X)',
  tier_role = NULL,
  evidence_level = 'D',
  notes = COALESCE(notes,'') || E'\n[vX SOFT-DELETE] 사유...'
WHERE id = TARGET_ID;
```

---

## 4. 영업 활용 화면 필터링 (Sappi 패턴)

영업 검색은 `tier_role IN ('HQ', 'Regional', 'Country')`로 필터링 → `[OBSOLETE]`, NULL tier rows 자동 제외.

| Tier | 색상 (Sappi 패턴) | 영업 활용 |
|---|---|---|
| 🟣 HQ | purple | 1개, 그룹 본사 |
| 🔵 Regional | blue | 대륙별 (Europe, Americas) |
| 🟢 Country | green | 국가별 실제 영업 대상 |
| ⚪ NULL/OBSOLETE | gray | 영업 검색에서 자동 제외 |

---

## 5. 다음 family 작업 체크리스트

```
□ CSV 데이터 받기 (Supabase에서 export)
□ 진단: 44+ row 분류 (duplicates, sub-components, family errors)
□ markets 누락 country 미리 등록
□ Stage 순서 그대로 적용 (Mondi v8 SQL 템플릿 참고)
□ market_code 변경은 DO BLOCK으로 감싸기
□ INSERT는 DO BLOCK + EXCEPTION + NOT EXISTS 가드
□ tier_role 변경은 'HQ'/'Regional'/'Country'/NULL만
□ paper_mills에 tier_role UPDATE 안 함
□ DELETE 대신 soft-delete
□ Stage 10 검증 쿼리 4개 결과 확인 후 COMMIT
```

---

## 6. Family Error 발견 패턴 (다음 family에 적용)

작업 중 다른 family가 잘못 라벨된 경우 발견됨:
- **Mondi Caledonian (Inverurie)**: 실제는 International Paper. 2009 폐쇄. → IP family로 이동 필요
- **Mondi Felixton**: 2011 demerge로 Mpact 자산이 됐을 가능성. Mondi 공식 사이트에 없음. → Mpact family로 이동 또는 historical Mondi asset 표기

각 family 작업 시 **반대 가능성도 검색**:
- 공식 사이트 (예: mondigroup.com/locations) 에 mill이 실제 있는지 확인
- 폐쇄 보도 + 인수/매각 이력 확인
- 가족 변경된 mill은 wrong family 라벨일 가능성

---

## 7. CSV 진단 단계 (다음 family 가이드)

작업 전 CSV에서 분류해야 할 row 패턴:

| 패턴 | 처리 |
|---|---|
| Auto-created from supplier_mill_linkages | tier=NULL + notes (DELETE 금지!) |
| Auto-created from paper_mills | soft-delete OK |
| 이름에 region/주(province) 포함 | mill_name 정규화 |
| 같은 city, 다른 market_code | 한 쪽이 잘못 라벨 — 정정 |
| 같은 회사 다른 site (PM-level) | 회사 1개, mill 여러 개 |
| compound name (X + Y) | 각각 split |
| post-acquisition note | 인수 실패면 다른 family로 이동 |

---

**검증 통과 후 적용**: 본 문서는 Mondi (v5.8 A-2.1) 완료 후 작성. Stora Enso + UPM (A-2.2, A-2.3) 작업 시 본 문서를 기반으로 1회 통과 가능.
