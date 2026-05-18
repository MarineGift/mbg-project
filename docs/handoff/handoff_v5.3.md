# URM Platform Handoff v5.3

**날짜**: 2026-05-14
**이전**: v5.2
**다음**: v5.4 (Phase 7-c 설계)

---

## v5.2 → v5.3 변경점

### 완료된 작업

**Phase 7-b 완전 종료 (commit e79729a)**
- 'buyer' → 'paper_mill' cascade: TS 25 files, SQL enum, i18n 3 locales
- 안전 패턴 정립: PS 5.1의 -Raw/Set-Content UTF-8 함정
  → Node fs API + `[System.IO.File]::WriteAllText` 우회

**V11.4 Sappi 중복 정리 완전 종료 (이번 세션 신규)**
- 10b: `8262f16e` FK NULL UPDATE
- 10e (신규): `supplier_mill_linkages` 5 rows `807→54` retarget
- 10c: `industry.paper_companies` 807 DELETE
- 10a: `ae4eb7f1` hard DELETE (26/26 references zero 확인 후)

### v5.2 가설 정정

- **"보이지 않는 공백" (v5.2 332-337) → 오답 확정**
  - 진짜 원인: V11.4 + app.parties 양 레이어 Sappi 중복
- **"party_type 컬럼이 tier" 추측 → 오답**
  - party_type은 company/person 구분용
- **"807은 단순 dead duplicate" → 부분 오답**
  - paper_mills엔 mill 0이지만 supplier_mill_linkages 5 row 보유
  - 단일 테이블 count만으로 dead 판정하면 false negative

---

## Schema 발견 (핵심 reference — 새 세션 시작 시 필수)

### 3개 컨셉 분리 (오늘 가장 중요한 mental model 정정)

| 컨셉 | 컬럼 | 값 | 의미 |
|---|---|---|---|
| Entity 종류 | `party_type` | company / person | 법인 vs 개인 |
| Evidence quality | `tier` | tier_1 / tier_2 / tier_3 | V11.4 신뢰도 A/B/C |
| 계층 구조 | `parent_party_id` | UUID or NULL | group_hq/country/plant |

**중요**: `tier`는 evidence quality이지 hierarchy가 아닙니다. 계층은 `parent_party_id` self-FK로 인코딩.

### app.parties 구조

- FK 컬럼 (둘 다 ON DELETE SET NULL):
  - `industry_paper_company_id` → industry.paper_companies
  - `industry_filler_supplier_id` → industry.filler_suppliers
- Check constraint: `chk_parties_industry_exclusive` (두 FK mutually exclusive)
- `parent_party_id` (self-FK) — **3-tier hierarchy latent capability**
  - 현재 모든 parties parent NULL (운영 미사용)
  - 7-c가 parent_party_id 첫 활용 작업

### app schema — party_id 류 FK 보유 27개 테이블

```
buyer_inquiries, buyer_profile, campaign_backers, communications,
consultations, contacts, customer_profile, customer_purchases,
dedup_review_queue (final_party_id / suggested_party_id), engagements,
events_timeline, investor_portfolio_companies (investor_party_id),
investor_profile, invoices, meetings, parties (parent_party_id),
partner_audits, partner_capabilities, partner_profile, payments,
quotations, response_strategies, sales_orders, scraping_normalized,
tasks
```

⚠️ `app.deals`는 **존재하지 않음** — 추측 금지

### industry.supplier_mill_linkages

- 3자 관계: `(filler_supplier_id, paper_company_id, paper_mill_id)`
- `legacy_id`, `market_code` 컬럼 (V11.4 import 흔적)
- filler_supplier_id 예시: Omya(37), IMI Fabi(43), Thiele Kaolin(42), Mississippi Lime(347), Artemyn(305)

### industry.paper_mills

- 식별 컬럼명 `name` 아님 (다음 세션 information_schema로 확인 필요)

### 022 promotion 스크립트 동작

- `WHERE NOT EXISTS (FK 채워진 row 스킵)` → idempotent
- evidence_level A/B/C → tier_1/2/3 매핑
- `module_data` jsonb에 V11.4 메타 보존 (evidence_level, auto_promoted_at 등)
- **parent_party_id는 INSERT 컬럼에 없음** → hierarchy 미설정으로 promote됨

---

## Sappi ecosystem 실측 (Step 3 결과)

총 **21개** Sappi-named parties, 모두 `parent_party_id = NULL`

### Clean tier entities (16개)

| id | name | FK | 비고 |
|---|---|---|---|
| 8262f16e | Sappi | NULL | v5.3 작업 결과, group_hq latent |
| bc001644 | Sappi Limited | 204 | 진짜 global group_hq 후보 |
| b317d9d6 | Sappi Europe | 1 | regional |
| a7e5841b | Sappi North America | 54 | country, v5.3에서 확정 |
| 42eea549 | Sappi Finland | 1018 | country |
| e93efe36 | Sappi Italy | 370 | country |
| da1b8828 | Sappi Portugal (limited) | 396 | country |
| 4d5a635d | Sappi Switzerland (closed 2011) | 334 | "closed" 메타 보유 |
| 1586524f | Sappi Ngodwana | 566 | mill |
| 7edfa494 | Sappi Springs | 431 | mill |
| 347bfdde | Sappi Stanger | 551 | mill |
| a6363ac3 | Sappi Saiccor (dissolving pulp) | 494 | mill |
| e4279b7e | Sappi Alfeld | 267 | mill |
| f22327c3 | Sappi Gratkorn | 341 | mill |
| dccbd88c | Sappi Lanaken NV (Belgium adjacent) | 373 | mill |
| ea3594ff | Sappi Finland Operations Oy | 260 | mill |

### Compound/aggregate entities (6개) — V11.4 design choice

| id | name | FK | 패턴 |
|---|---|---|---|
| 6932e81e | Sappi + Mondi | 1070 | JV/shared mill |
| db1e3137 | Sappi Finland (former M-real, 2 FI mills) | 757 | 인수 이력 메타 |
| 7a2907e1 | Sappi Gratkorn + Heinzel | 877 | 2-way joint |
| 0b635240 | Sappi Gratkorn + Lenzing + Heinzel | 1057 | 3-way joint |
| 321c535e | Sappi Italy + Sappi Lanaken Belgium | 455 | cross-border |
| 4f0c80a3 | Sappi multi-mill | 797 | generic catch-all |

→ 삭제 대상 아님, 단 7-c plant parent 매칭에서 제외 규칙 필요

---

## 운영 lesson (재발 방지)

1. **Supabase SQL editor multi-statement = single transaction**
   → 각 step 개별 Run 권장. 마지막 실패가 앞 UPDATE까지 rollback함.

2. **Dead duplicate 판정**: 단일 테이블 count만으론 false negative
   → V11.4 master ID 추정 시 모든 참조 테이블 (paper_mills, supplier_mill_linkages 등) 전수 점검

3. **Schema 추측 대신 information_schema.columns 일괄 조회**
   → 추측 시간이 점검 시간보다 빨리 누적됨

4. **FK constraint 동작 미리 파악**
   → ON DELETE SET NULL / RESTRICT / CASCADE 확인하면 cascade 영향 예측 가능

---

## v5.4 첫 세션: Phase 7-c 설계 prep

### 선행 점검 (설계 전 30분)

**1. industry.paper_mills 실제 컬럼 확인**
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'industry' AND table_name = 'paper_mills'
ORDER BY ordinal_position;
```

**2. mill ↔ paper_company FK 매핑 통계**
```sql
SELECT
  COUNT(*) FILTER (WHERE paper_company_id IS NOT NULL) AS matched,
  COUNT(*) FILTER (WHERE paper_company_id IS NULL) AS orphan,
  COUNT(*) AS total
FROM industry.paper_mills;

-- multi-parent 가능성 (1 mill → N company)?
SELECT paper_mill_id, COUNT(DISTINCT paper_company_id) AS company_count
FROM industry.supplier_mill_linkages
GROUP BY paper_mill_id
HAVING COUNT(DISTINCT paper_company_id) > 1
ORDER BY company_count DESC
LIMIT 20;
```

**3. Sappi 외 회사들의 compound entity 패턴 audit**
```sql
SELECT module, COUNT(*) AS cnt
FROM app.parties
WHERE name LIKE '%+%' AND module IN ('buyer', 'filler')
GROUP BY module;

-- 패턴 예시 보기
SELECT name FROM app.parties
WHERE name LIKE '%+%' AND module = 'buyer'
ORDER BY name
LIMIT 50;
```

**4. 기존 compound entities의 module_data 메타 분석**
```sql
SELECT id, name, 
       module_data->>'main_product_category' AS category,
       module_data->>'evidence_level' AS evidence,
       module_data->>'main_products' AS products
FROM app.parties
WHERE name LIKE '%+%' AND module = 'buyer'
LIMIT 20;
```

### 설계 결정 사항 (v5.4 본 작업)

**A. parent_party_id 매칭 규칙**
- 단일 mill → 단일 country_entity 매칭 알고리즘
- Compound parent 후보 제외 패턴 (`name LIKE '%+%'`, `name LIKE '%multi-mill%'` 등)
- 매칭 실패 시 fallback: group_hq? NULL? 별도 unassigned tier?

**B. Plant tier 표시 컨벤션**
- `parent_party_id IS NOT NULL` 을 plant 시그널로 사용?
- 또는 새 컬럼/enum 추가? (예: app.parties.hierarchy_tier ENUM)
- 기존 mill-level entities (Sappi Alfeld 등 11개)와의 정합성

**C. Mill의 multi-tenant 가능성**
- "Sappi + Mondi" 같은 joint operation을 어떻게 표현?
- plant 1개가 parent 2개 가질 수 있는가? (FK 1:1 vs M:M 결정)
- 현 schema는 1:1 (parent_party_id 단일 컬럼)

**D. Compound entity 자체 처리**
- 그대로 유지? deprecate? 별도 type 부여?
- "Sappi Limited" (FK=204, group_hq 후보) vs "Sappi" (8262f16e, FK NULL) 관계 정리
- 8262f16e의 존재 의미 재검토 — promotion 부산물인가, 의도적 group_hq인가?

---

## Phase 7-c 진입 조건

- ✅ Sappi 양 레이어 중복 정리 완료
- ✅ 8262f16e (group_hq 후보) FK NULL — LEFT JOIN 자동 가드
- ⏸ Compound entity 처리 정책 결정 필요 (v5.4 설계 작업)
- ⏸ industry.paper_mills schema 미파악 (선행 점검 1번)

---

## 미해결 항목 (장기/optional)

- **#8**: Supabase 타입 재생성 (`.schema('industry' as never)` 8곳)
- **#9**: i18n 라벨 cosmetic (ko line 45 등)
- **#12**: 3-tier 운영화 (parent_party_id backfill — 7-c 작업에 자연 흡수 가능)

---

## 다음 세션 시작 프롬프트 (template)

```
v5.3 핸드오프 첨부합니다. Phase 7-c 설계 시작하려고 합니다.
선행 점검 1번 (industry.paper_mills 컬럼 확인)부터 가겠습니다.
```

---

**오늘 세션 성과 요약**:
1. ✅ 3개 컨셉 분리 mental model 확정 (party_type / tier / parent_party_id)
2. ✅ 022 promotion 스크립트 의도 완전 이해
3. ✅ industry.supplier_mill_linkages 3자 관계 schema 발견
4. ✅ app schema 27 테이블 reference map 확보
5. ✅ 3-tier hierarchy: schema 인코딩, 운영 미사용 결론
6. ✅ Sappi ecosystem 21 parties + 6 compound entities 발견
7. ✅ 무손실 데이터 정리 (V11.4 4 step + app 1 step, 데이터 유실 0)
