# URM Platform Handoff v5.4

**날짜**: 2026-05-14 (v5.3과 같은 날, audit + schema 확장 세션 연속)
**이전**: v5.3
**다음**: v5.5 (Phase 7-c Step A 시작 — Paper side 정리)

---

## v5.3 → v5.4 변경점

### 핵심 전환

**7-c 본질 재정의**
- v5.3의 "parent_party_id 매칭 알고리즘 설계" 정의 → **폐기**
- 새 본질: **Paper side 정리(수렴 작업) + Filler side 신규 구축(영업과 병행 발산 작업)**
- 두 측의 데이터 상태가 완전히 다르므로 작업 방식도 분리

### 완료된 작업

**18+ Schema audit 완료**
- 1A/1B/1C: paper_mills 컬럼/FK/식별키 확정
- industry.markets 발견 (country 마스터, v5.3 핸드오프 누락 테이블)
- paper_companies / filler_suppliers 정규화 상태 정량화
- Omya 31 중복의 진짜 정체 진단 (market_code별 의미 분리)

**Schema 확장: industry.filler_plants 신설**
- CREATE TABLE + 4 인덱스 + 2 FK constraint 모두 정상 적용
- paper_mills 대칭 디자인, 도메인 특화 컬럼만 변형

---

## Schema 발견 (audit 결과 — 새 세션 시작 시 필수 reference)

### industry.paper_mills (점검 1A/1B/1C)

**컬럼 (20개)**
```
id (bigint PK, sequence)
paper_company_id (bigint, NULLABLE — 단 552/552 has_company 매핑)
market_code (text, NOT NULL — 552/552 매핑, 38 distinct)
legacy_id (integer, NULLABLE)
mill_name (text, NOT NULL) ★ 식별 컬럼 (name 아님)
company_name_raw, city
region (text, NULLABLE) ★ 552/552 NULL — dead 컬럼, 무시
main_product_category, main_products
filler_probability, basis_for_filler, likely_filler_types (ARRAY),
  likely_supply_structure, likely_supplier_note  -- V11.4 filler 분석
evidence_level (character, A/B/C)
source_url, notes
created_at, updated_at
```

**FK 구조 (1B)**
- outgoing: `paper_company_id → industry.paper_companies(id)` **CASCADE** ⚠️
- outgoing: `market_code → industry.markets(code)` NO ACTION
- incoming: `industry.supplier_mill_linkages.paper_mill_id → id` NO ACTION
- incoming: `app.engagements.mill_id → id` SET NULL ★ **v5.3 27 테이블 reference map 누락 발견**

**제약 (1C)**
- PRIMARY KEY: `id`
- UNIQUE: `(market_code, legacy_id)` — V11.4 natural key

### industry.markets (v5.3 핸드오프 누락, 새 발견)

- 38 countries (algeria, argentina, austria, ... usa)
- region grouping (5): Europe 15, Asia 12, MEA 9, Americas 8, Oceania 1
- 컬럼: `code` (lowercase slug PK), `name` (display), `region` (continent)
- 모두 동일 timestamp seed (2026-05-14) — V11.4와 별개 작업

### industry.filler_suppliers 컬럼 (점검 16, 15 컬럼)

```
id (bigint PK)
market_code (text, NOT NULL)            -- paper_mills와 동일
legacy_id (integer, NULLABLE)
name (text, NOT NULL)
supplier_type, market_role
relevant_filler_types (ARRAY)
supply_model, europe_paper_evidence, onsite_pcc_evidence
evidence_level (character)
source_url, notes
created_at, updated_at
```

⚠️ **`paper_company_id` 없음** — filler_suppliers ↔ paper_company는 supplier_mill_linkages 경유만 가능
⚠️ **`module_data` 없음** — V11.4 메타는 컬럼으로 직접 펴짐. module_data는 app.parties 전용.

### Mill 매핑 상태 (점검 4A/4B/4C)

```
552/552 has_market   (38 distinct markets)
552/552 has_company  (471 distinct companies)
Top markets: usa 29, australia 27, turkey 25, canada 24, korea 24,
             poland 24, sweden 23, finland 22, mexico 20, france 19
```

→ 두 axis 모두 100% 매핑 — orphan mill 0개

---

## 새 schema: industry.filler_plants ✅ 신설 완료

```sql
CREATE TABLE industry.filler_plants (
  id                    BIGSERIAL PRIMARY KEY,
  filler_supplier_id    BIGINT NOT NULL,
  market_code           TEXT NOT NULL,
  legacy_id             INTEGER,
  plant_name            TEXT NOT NULL,         -- 지역명 (paper_mills.mill_name 대응)
  city                  TEXT,
  region                TEXT,                  -- sub-national (Bavaria 등)
  -- filler-specific (수집하면서 채움)
  process_type          TEXT,                  -- GCC / PCC / kaolin / etc.
  capacity_tpy          NUMERIC,               -- tons per year
  product_focus         TEXT,
  -- 공통 메타
  evidence_level        CHAR(1),               -- A/B/C
  source_url            TEXT,
  notes                 TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT filler_plants_supplier_fk
    FOREIGN KEY (filler_supplier_id)
    REFERENCES industry.filler_suppliers(id) ON DELETE CASCADE,
  CONSTRAINT filler_plants_market_fk
    FOREIGN KEY (market_code)
    REFERENCES industry.markets(code) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX filler_plants_market_legacy_uq
  ON industry.filler_plants(market_code, legacy_id)
  WHERE legacy_id IS NOT NULL;

CREATE INDEX filler_plants_supplier_idx ON industry.filler_plants(filler_supplier_id);
CREATE INDEX filler_plants_market_idx   ON industry.filler_plants(market_code);
```

**점검 26/27로 확인된 상태**
- 4 인덱스 모두 정상 (pkey, market_legacy_uq, supplier_idx, market_idx)
- 2 FK constraint 모두 정상 (supplier_fk CASCADE, market_fk RESTRICT)

⚠️ **CASCADE 위험 (paper_mills와 동일 패턴)**
- filler_supplier 삭제 시 plant 모두 CASCADE 삭제
- v5.3 lesson #4 따라 사전 점검 필수

---

## 3-tier 명명 컨벤션 (사용자 결정)

### Entity 분류 모델: (name, location, role) 3-info

모든 paper_companies / filler_suppliers entity는 다음 3가지 정보로 명시적 분류:

| Info | 의미 | 저장 위치 |
|---|---|---|
| **name** | entity 이름 (`Sappi Limited`, `Sappi Europe`, `Sappi Finland`) | 기존 `name` 컬럼 |
| **location** | 위치 (단일 country 또는 multi-country composite) | 기존 `market_code` 컬럼 |
| **role** | tier 분류 라벨 — **HQ / Regional / Country / Plant** | 미정 (v5.5 결정 — #17 참조) |

### Role label 4종 정의

| Role | 의미 | 명명 패턴 | 예시 |
|---|---|---|---|
| **HQ** | 글로벌 본사 | `{Company} {Legal Suffix}` | `Sappi Limited` (SA), `Omya International AG` (Switzerland) |
| **Regional** | 대륙/multi-country 묶음 | `{Company} {Region}` | `Sappi Europe`, `Sappi North America` |
| **Country** | 단일 국가 법인/지사 | `{Company} {Country}` | `Sappi Finland`, `Sappi Italy`, `Omya Korea` |
| **Plant** | 도시/지역 단위 plant | **지역명만 (회사 prefix 없이)** | `Alfeld`, `Gratkorn`, `Cloquet Mill`, `Yeosu`, `Gunsan` |

⚠️ **Plant 명명 정책 (사용자 결정)** — Plant tier entity는 회사 prefix 없이 **지역명만** 표기.
- 이유: paper_mills.mill_name 실측 패턴과 동일 (`Alfeld`, `Cloquet Mill` 등)
- 회사 소속은 parent_party_id (Country tier) → parent_party_id (HQ/Regional tier)로 추적
- 이전 표기(`Sappi Alfeld`)는 v5.5 rename 작업 대상 (#18 참조)

### "3 Tier"의 의미

- **한 회사가 보통 3가지 role만 활용**한다는 뜻 (4가지 다 갖는 회사는 드묾)
- 회사별 활용 패턴 예시:
  - Sappi: HQ + Regional + Country + Plant (4 role 모두, 가장 깊은 hierarchy)
  - Omya (예상): HQ + Country + Plant (Regional 미사용)
  - 작은 회사: HQ + Plant (Country 미사용)
- **Schema 강제 X** — 회사별로 활용 role 자유 선택. parent_party_id로 hierarchy 표현.

### Sappi family 적용 매핑 (사용자 결정)

```
Sappi Limited       :: location=South Africa     :: role=HQ
Sappi Europe        :: location=Europe (multi)   :: role=Regional
Sappi North America :: location=North America    :: role=Regional
Sappi Finland       :: location=Finland          :: role=Country
Sappi Italy         :: location=Italy            :: role=Country
Sappi Portugal      :: location=Portugal         :: role=Country

-- Plant tier (지역명만, 회사 prefix 없음):
Alfeld              :: location=Germany          :: role=Plant
Gratkorn            :: location=Austria          :: role=Plant
Lanaken             :: location=Belgium          :: role=Plant
Cloquet Mill        :: location=USA              :: role=Plant
Somerset Mill       :: location=USA              :: role=Plant
Westbrook Mill      :: location=USA              :: role=Plant
Ngodwana            :: location=South Africa     :: role=Plant
Saiccor             :: location=South Africa     :: role=Plant
Springs             :: location=South Africa     :: role=Plant
Stanger             :: location=South Africa     :: role=Plant

(compound entities — "Sappi + Mondi" 류 6개는 별도 정책 #15)
```

### Omya 적용 매핑 (예상, v5.5 실작업 시 데이터로 검증)

```
Omya International AG :: location=Switzerland :: role=HQ
Omya Korea            :: location=Korea       :: role=Country
Omya Australia        :: location=Australia   :: role=Country

-- Plant tier (지역명만):
Yeosu                 :: location=Korea       :: role=Plant
Gunsan                :: location=Korea       :: role=Plant
(현재 filler_suppliers에 31개 "Omya" 동일명 row가 market_code로만 분리됨 — v5.5 Step B에서 split + rename. plant 정보는 filler_plants에 신규 입력)
```

---

## Paper vs Filler 작업 방식 비대칭 (가장 큰 발견)

| 측면 | Paper side | Filler side |
|---|---|---|
| 데이터 가용성 | 충분 (552 mill 완비) | 빈약 (plant 정보 거의 없음) |
| 7-c 작업 방식 | **정리** (수렴 가능) | **수집 + 구축** (영업과 병행, 발산) |
| Plant 저장소 | paper_mills (기존) | filler_plants (신설 완료) |
| HQ/Country tier 마스터 | paper_companies | filler_suppliers |
| paper_company_id 직접 FK | 있음 (1:1 hard-coded) | 없음 (supplier_mill_linkages 경유) |
| Tier 3 채움 시점 | 즉시 가능 | 점진적 |
| 우선 정리 회사 후보 | Visy 10 mill, Opal 9, MM Kwidzyn 5, Hansol Paper 5 | Omya, Imerys/Artemyn, MTI/Specialty Minerals |

### paper_companies 정규화 상태 (점검 5/6/18)

- 총 1073 row, mill 가진 회사 471개
- **13 multinational family 이미 multi-row 분리됨**:
  ```
  Mondi 43, Smurfit 26, UPM 26, Stora 24, Sappi 21, Hayat 21,
  DS Smith 17, Essity 15, Norske Skog 14, CMPC 14,
  Kimberly-Clark 13, Saica 11, Billerud 10, Arauco 10,
  International Paper 10, Fedrigoni 9, Metsä 8
  ```
- **Placeholder row 183개** (정리 대상):
  - `[Sector]` 137 (산업 segment 분석용)
  - `[Other] Mid-tier mills` 23
  - `Multi-mill` 23
- 동일명 dup 거의 없음 (placeholder 외)

### filler_suppliers 정규화 상태 (점검 9/17)

- 총 361 row
- **동일명 중복 (정리/split 대상)**:
  ```
  Artemyn (former Imerys paper assets) — 39
  Imerys                               — 38
  Specialty Minerals (MTI)             — 34
  Omya                                 — 31
  Schaefer Kalk                        — 12
  Minerals Technologies (MTI) /
    Specialty Minerals                 —  7
                                  합계 ≈ 161
  ```
- **Placeholder/aggregator** (~38 row):
  ```
  "Chinese gray-market" 11, "[Other] EU cross-border" 11,
  "Spain/EU imports" 3, "Mexican imports (Calidra/Cemex)" 3,
  "Brazilian/Chilean cross-border" 2, "Indian imports" 2, ...
  ```
- **통합 관계 발견** (실작업 시 정책 필요):
  - Artemyn = Imerys (former assets) → 두 row family 통합?
  - Specialty Minerals = MTI (모자회사)

### Sappi family 실측 (CSV 48, 점검 21)

- 22 row 중 9개가 paper_mills FK 보유 (plant-linked entity)
- **HQ tier**: `Sappi Limited` (id 204, mill FK 없음)
- **Regional tier**: `Sappi Europe`, `Sappi North America` (id 54, 3 mill FK 보유)
- **Country tier**: `Sappi Finland`, `Sappi Italy`, `Sappi Portugal`, `Sappi Switzerland (closed)` 등
- **Plant tier**: `Sappi Alfeld` (mill 392), `Sappi Gratkorn` (461), `Sappi Ngodwana` (304), `Sappi Saiccor` (303), `Sappi Springs` (302), `Sappi Stanger` (305)
- Compound entities 6개 (`Sappi + Mondi`, `Sappi Gratkorn + Heinzel` 등) — 별도 처리 정책 필요

### Omya 31 중복 진단 (점검 12/13/14)

- 31 row 모두 active (linkage 0개 row 없음, 총 165 linkage)
- max linkage: id 2 (16개), id 37 (12개)
- **단순 중복 아님** — market_code별로 의미 분리:
  - id 2: `europe_composite`, evidence A
  - id 37: `usa`, evidence B
  - id 1: `europe_composite`, evidence A (id 2와 다른 supply_model)
- V11.4가 의도는 있었으나 `name` 컬럼 정규화를 완수 못함 → 사용자 시야 혼란의 진짜 원인
- `europe_composite` 같은 region composite market_code 사용 — markets 테이블에 없는 값

---

## 운영 lesson (v5.3 lessons에 추가)

1. **CSV export truncation 주의** — Supabase SQL editor 결과창에서 31 row 쿼리가 2 row로 잘리는 경우 다수. 행 길이 짧게 (ids 배열 생략) 또는 쿼리 분리 Run.
2. **module_data 컬럼은 app.parties 전용** — industry.* 레이어는 컬럼 직접 보유. paper_companies / paper_mills / filler_suppliers 모두 컬럼 펴짐. 점검 15 실패 (`fs.module_data does not exist`)가 증거.
3. **Multi-statement transaction 함정 (v5.3 #1 재확인)** — multi-statement SELECT는 결과창에 마지막 결과만 노출. INDEX 다중 생성 시 첫 줄 실패하면 뒷줄 미실행 (42P07 already exists 흔히 발생). 각 statement 별도 Run 권장.
4. **Schema 추측 금지 (v5.3 #3 재확인)** — 추측한 `module_data` 컬럼 없음. `information_schema.columns` 일괄 조회로 확인하는 습관 유지.
5. **Schema 대칭 디자인 원칙** — 새 테이블(filler_plants)은 기존 테이블(paper_mills) mirror로 시작, 도메인 특화 컬럼만 변형. 미래의 자연스러운 확장 패턴.
6. **`name LIKE 'X%'` 매칭으로 family 추정 가능** — Sappi 21, Mondi 43 등 V11.4가 이미 multi-row family 만든 회사 식별. 점검 6의 prefix grouping 패턴.

---

## v5.5+ Step 재정의 (7-c 본 작업)

### Step A — Paper side 정리 (v5.5 우선)

- A-1: paper_companies placeholder 분리
  - `[Sector]` 137 + `[Other]` 23 + `Multi-mill` 23 = **183 row**
  - 처리 방식 결정 필요 (별도 분류 메타, app.parties promotion 시 module=meta 격리 등)
- A-2: paper side 3-tier 명명 정규화
  - 13 multinational family 검토 (HQ/Country/Plant 매핑)
  - 단일국가 multi-mill 회사 split (Visy 10, Opal 9, MM Kwidzyn 5, Hansol Paper 5 등)
- A-3: paper compound entity 처리 정책
  - `Sappi + Mondi`, `Sappi Gratkorn + Heinzel` 등 6+ row
  - deprecate vs retain 결정

### Step B — Filler side 컨벤션 + 우선 회사 선정 (v5.5 동시)

- B-1: filler_suppliers 동일명 중복 분석
  - Omya 31 → market_code별 split + name rename ("Omya Korea" 등)
  - Imerys 38, Artemyn 39, MTI 34도 동일 분석
- B-2: 통합 관계 정책 결정
  - Artemyn ↔ Imerys (former assets) 통합 여부
  - MTI ↔ Specialty Minerals (모자회사) 통합 여부
- B-3: 우선 영업 대상 회사 선정 (Omya 등)
- B-4: filler_suppliers placeholder 38 row 격리 정책

### Step C — Filler side 데이터 입력 (v5.5~ 장기, 영업 병행)

- C-1: 수집된 plant 정보로 `industry.filler_plants` seeding
- C-2: filler_suppliers HQ/Country tier row 정규화 (B-1 split 결과 반영)
- C-3: supplier_mill_linkages retarget
  - Omya 165 linkage + Imerys + MTI + α
  - v5.3 step 10e (Sappi 5 linkage) 패턴 확장

### Step D — Axis 분류 오류 정리 (v5.6 이후)

- D-1: `Omya International AG (HQ)` paper_companies id 328 → filler_suppliers 이동
- D-2: 기타 mis-classification 점검 (paper에 filler 회사, filler에 paper 회사)

### Step E — app.parties promotion + parent_party_id backfill (마지막)

- E-1: industry → app promotion (022 스크립트 변형 활용)
  - filler_plants 추가에 따른 022 스크립트 업데이트 필요
- E-2: parent_party_id backfill (corporate axis 단일, markets는 보조 메타)
- E-3: app.parties module_data에 country/region 정보 enrich

---

## Phase 7-c 진입 조건

- ✅ Schema 발견 완료 (18+ audit)
- ✅ industry.filler_plants 신설 완료 (FK + 인덱스 정상)
- ✅ 명명 컨벤션 결정: (name, location, role) 3-info 모델, role 4종(HQ/Regional/Country/Plant)
- ✅ Paper vs Filler 작업 방식 비대칭 확정
- ✅ Sappi family 정리 방향 결정 (Sappi Limited 유지 + 4-role 모두 활용)
- ⏸ **role 컬럼 저장 위치 결정** (#17 — v5.5 첫 schema 결정 사항)
- ⏸ 우선 정리 대상 회사 결정 (v5.5 첫 작업)
- ⏸ 통합 관계 처리 정책 (Artemyn=Imerys, MTI=Specialty Minerals)
- ⏸ 022 promotion 스크립트 filler_plants 반영 (Step E 직전)
- ⏸ supplier_mill_linkages 매핑 sparse 정량화 (#16 v5.5 첫 audit)

---

## 미해결 항목 (장기/optional)

v5.3 미해결 그대로 유지:
- **#8**: Supabase 타입 재생성 (`.schema('industry' as never)` 8곳)
  - **추가**: `industry.filler_plants` 신설로 새 타입 추가 필요
- **#9**: i18n 라벨 cosmetic (ko line 45 등)
- **#12**: 3-tier 운영화 (parent_party_id backfill — Step A/E에 흡수)

v5.4 추가:
- **#13**: 명명 컨벤션 문서를 `src/lib/conventions/` 또는 `docs/`에 영구 저장
- **#14**: `europe_composite` 같은 region composite market_code 정책 결정
  - markets 테이블에 추가? supplier-specific 확장만? composite는 보조 컬럼?
- **#15**: compound entity 정책 (`Sappi + Mondi` 류 6+ row)
  - paper_companies에 V11.4가 만든 design choice
  - deprecate / retain / 별도 type 부여 중 선택 필요 (Step A-3)
- **#16**: supplier_mill_linkages 매핑 sparse 정량화 (v5.5 첫 audit)
  - 사용자 진단: "SMI와 몇 개 외엔 대부분 paper_mill plant와 연결 안 됨"
  - Omya 165 linkage는 행 수, distinct paper_mill 매핑 수는 더 적을 가능성
  - 전체 552 mill 중 filler 매핑 비율 확인 필요
  - 영업 우선순위 결정 (어느 mill에 filler 정보 채울지)
- **#17**: role 컬럼 저장 위치 결정 (v5.5 첫 schema 결정)
  - 4 role label (HQ / Regional / Country / Plant)을 어디에 저장할지
  - 옵션 A: paper_companies / filler_suppliers에 `tier_role` ENUM 컬럼 추가 (industry 레이어, 가장 명시적)
  - 옵션 B: app.parties에만 `tier_role` 컬럼 추가 (운영 레이어, industry는 raw)
  - 옵션 C: app.parties.module_data jsonb에 role 저장 (변경 없음, 추출 어려움)
  - 옵션 D: parent_party_id depth로 암시 (HQ=parent NULL, Plant=2-hop child 등; 명시적 라벨 없음)
  - **추천**: 옵션 A (사용자 의도가 명시적 라벨이므로). 옵션 B는 industry → app promotion 시 필요한 라벨이 industry에 없어 매핑 어려움.
- **#18**: paper_companies plant-tier entity name 정규화 (v5.5 작업)
  - 현재 paper_companies에 회사 prefix 포함 plant entity 8개 (`Sappi Alfeld`, `Sappi Gratkorn`, `Sappi Ngodwana`, `Sappi Saiccor`, `Sappi Springs`, `Sappi Stanger`, `Sappi Lanaken NV (Belgium adjacent)`, `Sappi Finland (former M-real, 2 FI mills)`)
  - 사용자 결정: Plant tier name은 지역명만 (paper_mills.mill_name과 동일 패턴)
  - rename 후 paper_mills.mill_name과 paper_companies.name이 일치하게 됨
  - 부수 결정: 두 테이블 동시 정본 유지 vs paper_mills를 plant 단일 정본화 (v5.5 토의)

---

## 다음 세션 시작 프롬프트 (template)

```
v5.4 핸드오프 첨부합니다. Phase 7-c Step A (Paper side 정리)부터 시작하려고 합니다.

먼저 supplier_mill_linkages 매핑 sparse 정량화 (#16 audit)부터 가고,
그 다음 paper_companies placeholder 183 row 격리 정책 결정,
또는 우선 정리 대상 회사 (Visy 10 mill부터?) 선정으로 진행하겠습니다.
```

---

## 오늘 세션 성과 요약

1. ✅ paper_mills schema 완전 파악 (1A/1B/1C): 20 컬럼 + 2 FK + (market_code, legacy_id) 복합 unique
2. ✅ industry.markets 발견 (v5.3 핸드오프 누락): 38 country 마스터, 5 continent grouping
3. ✅ app.engagements.mill_id FK 발견 (v5.3 27 테이블 reference map 누락)
4. ✅ 7-c 본질 재정의: parent_party_id 매칭 → Paper 정리 + Filler 신규 구축 (병행)
5. ✅ Paper vs Filler 비대칭 확정 (정규화 상태 완전히 다름)
6. ✅ Filler dirtiness 정량화 (Artemyn 39, Imerys 38, MTI 34, Omya 31, Schaefer Kalk 12)
7. ✅ 통합 관계 발견 (Artemyn=Imerys former assets, MTI=Specialty Minerals 모자회사)
8. ✅ Omya 31 중복 진단 (market_code별 의미 분리, V11.4 name 정규화 미완)
9. ✅ paper_companies 13 multinational family 확인 (Mondi 43, Smurfit 26, UPM 26, Stora 24, Sappi 21, ...)
10. ✅ paper_companies placeholder 183 row 식별 ([Sector] 137 + [Other] 23 + Multi-mill 23)
11. ✅ Sappi family 22 row 세분화 (HQ/Regional/Country/Plant tier별 분류)
12. ✅ industry.filler_plants 신설 완료 (CREATE TABLE + 4 인덱스 + 2 FK constraint)
13. ✅ 명명 컨벤션 결정: (name, location, role) 3-info 모델 + 4 role 라벨(HQ/Regional/Country/Plant)
14. ✅ Sappi family role 매핑 완료 (Sappi Limited=HQ + Sappi Europe/NA=Regional + 4 country + 7 plant)
15. ✅ Plant tier 명명 정책 확정 (지역명만, 회사 prefix 없이) — paper_mills.mill_name 패턴과 정렬
16. ✅ Filler-Mill 매핑 sparse 인지 (v5.5 audit 항목으로 등록)
