# Mondi family — 진단 보고서 (v5.8 Step A-2.1)

**작성일**: 2026-05-15  
**입력**: Supabase CSV — `paper_companies` (44 row) + `paper_mills` (23 row)  
**참조**: `01_mondi_reference.md` + `12_cross_family_normalization_patterns.md`

---

## 0. 전체 요약

- **44 paper_companies row** 중 `tier_role` 채워진 것 **0개** → 100% 작업 필요
- **DS Smith mislabeled** 2 row (handoff #13 risk 적중) — IP family로 이동 또는 family_group 제거
- **HQ 중복 3 row** (id 9, 205, 337) → 1개로 consolidate
- **Auto-created skeleton rows** 14개 (null만 있음) — mill 자동 생성, Country tier로 채우거나 mill로 통합
- **Compound entities** 11 row — `supplier_mill_linkages` 출처, `Sector` tier 또는 별도 처리

---

## 1. paper_companies — 카테고리별 분류 (44 row)

### 1A. HQ 후보 (3 row — consolidate 필요)

| id | name | market_code | headquarters | 권장 처리 |
|---|---|---|---|---|
| 9 | Mondi | europe_composite | UK/Austria/Europe | **DEMOTE → 'Regional' tier** (Mondi Europe로 재활용) — main_products에 풍부한 정보 있음 |
| 205 | Mondi Group | south_africa | Public — LSE/JSE | **DELETE** 또는 **DEMOTE → 'Country'** (이전 Mondi Limited 잔재) |
| 337 | Mondi Group (HQ) | austria | Public — JSE+LSE listed (FTSE 100) | **HQ로 채택** — 정보 가장 풍부. 단 `market_code` → **`united_kingdom`** 정정 + `headquarters` → "Weybridge, UK" |

**의사결정**: 단 1개의 HQ row만 유지 권장. **id=337을 HQ로**, id=9를 Regional Europe으로 활용, id=205는 폐기.

---

### 1B. Country tier (정상적인 row, 채우면 됨 — 8 row)

| id | name | market_code | 권장 tier_role | 메모 |
|---|---|---|---|---|
| 64 | Mondi Świecie | poland | Country | ⭐ 폴란드 #1 paper. 핵심 mill |
| 81 | Mondi Turkey | turkey | Country | 2021 IP 인수 |
| 246 | Mondi Sweden (Wäja Frantschach) | sweden | Country | 소규모 Frantschach 브랜드 site |
| 338 | Mondi Frantschach | austria | Country | St. Gertraud, 사크 kraft |
| 339 | Mondi Neusiedler | austria | Country | 다중 site 통합 (Klein-Neusiedl + Hausmening + Kematen + Theresienthal) |
| 340 | Mondi Grünburg | austria | Country | 코러게이트 |
| 372 | Mondi Duino (post-Burgo 2023) | italy | Country | 2023-01 인수 |
| 412 | Mondi SCP a.s. Ružomberok | slovakia | Country | 핵심 통합 mill |

---

### 1C. 잘못된 market_code (Austria → Germany 오기) — 2 row

| id | name | 현재 market_code | 정정 후 | 이유 |
|---|---|---|---|---|
| 266 | Mondi Neusiedler GmbH | germany ❌ | **austria** | Neusiedler는 Klein-Neusiedl(AT) + Hausmening(AT) + Kematen(AT) — Austria사이트 |
| 271 | Mondi Frantschach Germany | germany ❌ | **austria** | Frantschach는 St. Gertraud, Austria — "Germany" 라벨이 잘못됨 |

> 단, 266 / 271은 id=339 / 338과 **중복** — Austria Neusiedler / Frantschach가 이미 별도 row 존재. 권장: **중복 row로 처리 (DELETE 또는 notes flag)** + 정확한 row(338/339)로 mill 재할당.

---

### 1D. DS Smith mislabeled — Mondi family 아님 (2 row)

| id | name | 권장 처리 |
|---|---|---|
| 274 | DS Smith Germany (post-Mondi 2024) | **family_group 제거** — DS Smith는 IP family (2025-01 인수). 별도 처리 |
| 379 | DS Smith Iberica (post-Mondi 2024) | **family_group 제거** — 동상 |

> `headquarters="Foreign — DS Smith (Mondi acquired 2024)"` 메모가 **잘못된 사실**임 — Mondi 입찰은 2024-03 실패, IP가 결국 인수.

---

### 1E. UK Country — split 필요 (1 row)

| id | name | 권장 처리 |
|---|---|---|
| 401 | Mondi UK (Caledonian + Mondi Heathfield) | **#15 compound — split**: Caledonian (Scotland, **2022 폐쇄 추정**) + Heathfield (England, specialty) 2개 site |

⚠️ Caledonian 폐쇄 사실 확인 필요 — reference에 미명시. notes에 flag.

---

### 1F. Russia divested (3 row 중복)

| id | name | 권장 처리 |
|---|---|---|
| 120 | Mondi Syktyvkar (former) | **Country, divested 라벨** — Russia 매각 2023-09 |
| 743 | Mondi/SLPK Syktyvkar | **중복 — DELETE 또는 id=120과 merge** |
| 817 | Mondi/SLPK Syktyvkar (post-2023) | **중복 — DELETE 또는 id=120과 merge** |

---

### 1G. Auto-created skeleton rows (14 row — null만 있음)

`notes="Auto-created from paper_mills (no legacy companies entry)"`로 표시된 row들. 이들은 paper_mills 자동 생성으로, 대부분 sub-site 수준. 정책 결정 필요:

| id | name | market_code | 정책 옵션 |
|---|---|---|---|
| 459 | Mondi Richards Bay | south_africa | 신규 Country row로 채움 (Richards Bay site 별도 법인 아니지만 site 단위로 둘 수 있음) |
| 477 | Mondi SCP biomass power plant (2027 completion) | slovakia | **DELETE 또는 notes로 통합** — power plant는 mill 아님 |
| 489 | Mondi Felixton | south_africa | Country (단, Felixton mill **2024-07 폐쇄** 보도 있음 — 확인 필요) |
| 499 | Mondi Wäja Frantschach | sweden | id=246과 **중복** — DELETE |
| 511 | Mondi Duino | italy | id=372과 **중복** — DELETE |
| 542 | Mondi Neusiedler Kematen | austria | id=339의 sub-site — DELETE 또는 mill만 유지 |
| 549 | Mondi Heathfield | united_kingdom | id=401의 sub-site — keep + split from 401 |
| 679 | Mondi Caledonian (Scotland) | united_kingdom | id=401의 sub-site — keep + split from 401, **closed 라벨** |
| 690 | Mondi SCP PM19 corrugated (post-2017 ECO Plus) | slovakia | id=412의 sub-component — DELETE (PM은 mill의 일부) |
| 720 | Mondi Neusiedler Hausmening | austria | id=339의 sub-site — DELETE 또는 mill만 |
| 751 | Mondi Neusiedler Klein-Neusiedl | austria | id=339의 sub-site — DELETE 또는 mill만 |
| 754 | Mondi Merebank | south_africa | site 별도 row (Durban, KZN) |
| 774 | Mondi Neusiedler Hilversum | germany ❌ | market_code → **netherlands**. Hilversum (Color Copy 생산). 별도 Country row로 |
| 783 | Mondi SCP Ružomberok integrated mill | slovakia | id=412와 **중복** — DELETE |

**권장**: site 단위 (Richards Bay, Felixton, Heathfield, Caledonian, Merebank, Hilversum)는 Country tier로 채움. PM/component (PM19, biomass, sub-site Neusiedler)는 mill로만 유지.

---

### 1H. Compound entities — `supplier_mill_linkages` 자동 생성 (11 row — `Sector` 처리)

이 row들은 paper_companies가 아니라 **공급망 분석용 aggregate**. tier 계층에서는 별도 처리 권장:

| id | name | 권장 처리 |
|---|---|---|
| 817 | Mondi/SLPK Syktyvkar (post-2023) | (1F에 포함) |
| 908 | Mondi multi-region | **tier_role='Sector'** 또는 family_group='Mondi_aggregate' |
| 916 | Mondi multi-mill | 동상 |
| 954 | Mondi + Smurfit Westrock + Holmen UK | 동상 — multi-family aggregate |
| 972 | Mondi SCP + Smurfit Westrock + DS Smith | 동상 |
| 979 | Mondi SCP PM19 + biomass power | 동상 (단일 family aggregate) |
| 994 | Mondi SCP Ružomberok | id=412 중복 — DELETE |
| 1002 | DS Smith + Saica + Mondi UK | multi-family aggregate |
| 1004 | Mondi UK + Smurfit Westrock UK | multi-family aggregate |
| 1052 | Mondi multi-region 5 mills | aggregate |
| 1065 | Mondi Neusiedler 3 mills | aggregate (Neusiedler 자체 통합 row) |
| 1066 | Mondi SCP | id=412 중복 — DELETE |
| 1069 | Lucart + RDM + ICT + Mondi Duino | multi-family aggregate |

**의사결정 필요** (Q1): supplier_mill_linkages aggregate rows를 어떻게 처리할지:
- Option A: `tier_role='Sector'` 신설하여 유지 (검색 화면에서 색깔 구분)
- Option B: `family_group=NULL` 또는 별도 family_group으로 이동 (검색 결과에서 제외)
- Option C: 그대로 두되 `notes`에 "supplier-linkage aggregate" 명시

---

## 2. paper_mills — 카테고리별 분류 (23 row)

### 2A. 정상 mill rows (15 row — city + market_code OK)

| id | mill_name | city | market_code | 비고 |
|---|---|---|---|---|
| 90 | Containerboard PM2 + PM5 (2024 rebuild) | Świecie, Kujawsko-pomorskie | poland | Świecie #1 |
| 91 | Pulp mill (integrated) | Świecie, Kujawsko-pomorskie | poland | Świecie #2 |
| 92 | Recycled fibre line | Świecie | poland | Świecie #3 |
| 93 | White-top liner / specialty grade (probable) | Świecie | poland | Świecie #4 (uncertain) |
| 125 | Corrugated packaging (post-2021 IP 인수) | Multi-site Turkey | turkey | rollup |
| 206 | Syktyvkar Komi | UFP + containerboard | russia | divested |
| 306 | Richards Bay KwaZulu-Natal | Pulp | south_africa | Richards Bay |
| 307 | Durban KZN | Containerboard + paper | south_africa | Merebank |
| 360 | Wäja | Sack paper | sweden | Wäja |
| 456 | St. Gertraud | Sack kraft + MG specialty kraft + specialty market pulp | austria | Frantschach |
| 457 | Klein-Neusiedl | UWF + NAUTILUS + PERGRAPHICA + Color Copy | austria | Neusiedler #1 |
| 458 | Hausmening | UWF | austria | Neusiedler #2 |
| 459 | Kematen | UWF | austria | Neusiedler #3 |
| 460 | Grünburg | Corrugated + offset + flexo | austria | Grünburg |
| 496 | Duino (Trieste) | Containerboard | italy | Duino |
| 531 | Heathfield | Specialty | united_kingdom | Heathfield |
| 540 | Ružomberok Liptov | UFP (580k) + containerboard (310k) + kraft paper (67k) + market pulp (100k) | slovakia | SCP integrated |

> **메모**: `main_products` 컬럼이 **city + 구분** 형식인 경우 있음 — schema가 헷갈림. 위 표는 CSV 원본 그대로.

---

### 2B. mill_name 정규화 필요 (3 row)

| id | mill_name (현재) | 권장 정정 | 이유 |
|---|---|---|---|
| 308 | KwaZulu-Natal | **Felixton** | 광역주 단위 → mill 이름 (Sappi #20 동일 패턴) |
| 530 | Scotland | **Caledonian (Inverurie)** | 광역 단위 → mill 이름 (단, 폐쇄 추정) |

---

### 2C. market_code 잘못 (2 row)

| id | mill_name | 현재 market_code | 정정 |
|---|---|---|---|
| 391 | Hilversum | germany ❌ | **netherlands** (Hilversum, NL) |
| 395 | Frantschach | germany ❌ | **austria** (Frantschach, AT) — id=456과 중복? 확인 필요 |

---

### 2D. Sector / Sub-component rows (3 row)

| id | mill_name | 권장 처리 |
|---|---|---|
| 107 | Sector — Mondi Świecie + Stora Enso Ostrołęka + MM Kwidzyn kraft | **tier_role='Sector'** (이미 tag 있음) — paper_company_name=`[Sector] Polish containerboard` |
| 541 | Ružomberok PM19 corrugated (post-2017 ECO Plus) | id=540의 sub — DELETE 또는 main_products 통합 |
| 542 | Ružomberok biomass power | id=540의 sub — DELETE (power plant) |

---

## 3. 누락된 row — INSERT 후보 (reference §14 적용)

| 후보 | reason | 권장 |
|---|---|---|
| **Mondi Hinton Inc.** (Canada, 2024-02 인수) | 데이터에 없음 | **INSERT** — paper_companies + paper_mills 양쪽 |
| **Mondi Stambolijski** (Bulgaria, **2024-10 폐쇄**) | 데이터에 없음 | **INSERT with closed status** — 폐쇄 사실 기록 위해 |
| **Mondi Lohja** (Finland, **2015 폐쇄**) | 데이터에 없음 | **INSERT with closed status** — 단, 옵션 — 닫힌지 오래되어 생략 가능 |
| **Mondi Bupak** (Czech, České Budějovice) | 데이터에 없음 | **INSERT** — corrugated converting (mill 아닐 수 있음, paper_companies만) |
| **Mondi Štětí** (Czech, sack kraft, 2024-12 PM10 startup) | 데이터에 없음 | **INSERT** — paper_companies + paper_mills 양쪽 |
| **Schumacher Packaging WE** (2025-03 인수, DE/NL/BE) | 데이터에 없음 | **INSERT** — paper_companies (site list TBD) |

⚠️ 데이터에 **Mondi Štětí (체코, paper-heavy)** 가 **없음** — 이는 큰 누락 (Mondi의 가장 큰 mill 중 하나).

---

## 4. 의사결정 필요 질문 (User에게)

### Q1. supplier_mill_linkages aggregate rows (11개) 처리 방식?
- **A**: `tier_role='Sector'` 신설 (검색에 별도 색상 표시)
- **B**: `family_group=NULL` (Mondi family에서 제외)
- **C**: 그대로 두되 notes에만 marker 추가

### Q2. Mondi Neusiedler sub-sites (4개 — Klein-Neusiedl, Hausmening, Kematen, Hilversum)
- **A**: 각 sub-site를 별도 `Country` row 유지 (현재 542, 720, 751, 774)
- **B**: id=339 (Mondi Neusiedler)만 Country로 유지, sub-site는 paper_mills row만으로 표현

### Q3. Mondi SCP sub-components (PM19 corrugated, biomass power plant)
- **A**: 별도 row 유지 (677, 690 + mills 541, 542)
- **B**: id=412 (Mondi SCP)만 유지, sub는 mill의 main_products에 통합

### Q4. DS Smith mislabeled rows (274, 379)
- **A**: `family_group='International Paper'`로 이동 (IP가 실제 인수자)
- **B**: `family_group=NULL` + notes에 "Mondi bid failed 2024" 명시
- **C**: DELETE

### Q5. 누락 mill INSERT 범위?
- **A**: 핵심만 — Hinton (캐나다), Štětí (체코), Stambolijski (불가리아 closed)
- **B**: 전체 — 위 + Bupak + Schumacher WE + Lohja
- **C**: 보류 — 이번 세션은 cleanup만, INSERT는 후속

---

## 5. 추정 결과 (모든 권장 적용 후)

| tier_role | 예상 row 수 | 비고 |
|---|---|---|
| 🟣 HQ | 1 | id=337 채택, 나머지 demote/delete |
| 🔵 Regional | 1~2 | id=9 (Mondi Europe), 추가로 Mondi NA 있을 수 있음 |
| 🟢 Country | 12~16 | Świecie, Turkey, Sweden, Frantschach, Neusiedler, Grünburg, Duino, SCP, Heathfield, Caledonian (closed), Hilversum, Richards Bay, Merebank, Felixton (closed?), Syktyvkar (divested) |
| 🟤 Sector (if Q1=A) | 9~11 | supplier_mill_linkages aggregate |
| NULL or DELETE | ~14~18 | duplicates, sub-components |

**Sappi 8 row 4 tier 패턴 vs Mondi**: Mondi는 훨씬 큼 — **~16 row 4 tier** 예상 (HQ 1 + Regional 1 + Country 14).

---

**END — Diagnosis Report**
