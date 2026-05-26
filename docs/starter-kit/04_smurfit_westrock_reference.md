# Smurfit Westrock family — Pre-research Reference

**작성일**: 2026-05-15  
**다음 세션 사용처**: handoff v5.7 권장 시나리오 D (Smurfit 26 row 정리)  
**핵심 주의**: **2024-07-05 Smurfit Kappa + WestRock 합병** — DB가 합병 이전 구조면 대규모 재구성 필요

---

## 1. Group level (HQ tier)

| 항목 | 값 |
|---|---|
| 정식명 | **Smurfit Westrock plc** |
| HQ | **Dublin, Ireland** (Smurfit Kappa 본사 계승) |
| 상장 | **NYSE (SW)** + **LSE (SWR)** dual listing |
| 합병 | **2024-07-05 완료** — Smurfit Kappa가 WestRock 인수 + 사명 변경 |
| 형식 | Smurfit Kappa가 acquirer, 다수 주주가 SK 측, 단 사명/사이즈는 WR-major (US 비중 큼) |
| 2024 영업 (Smurfit Kappa 단독 2023) | 합병 전 SKG 매출 €11B+, WR 매출 $20.3B (FY2023) |
| 합병 후 | **세계 최대 listed packaging company** |
| 직원 | ~100,000명+ (50+ 국가) — 합병 후 2025에 4,500명 감원 |
| Footprint | **63 paper mills** + **500+ converting/packaging plants**, 40+ 국가 |
| 재활용 fiber | 14 Mt/y 소비, 60+ recovered fiber mills 보유 |

**DB 적용**:
- `paper_companies` HQ tier row: name = "Smurfit Westrock plc" (현재) — DB가 합병 전이면 "Smurfit Kappa Group plc" + "WestRock Company" 2개 HQ 별도 가능성
- `headquarters` = "Dublin, Ireland"
- `market_code` = `ireland`
- `tier_role` = `HQ`

**중요 주의**: DB에 "Smurfit Kappa" + "WestRock"이 별도 HQ로 들어있으면 **하나로 통합 + 다른 하나는 alias** 처리. 합병 이후 모회사는 Smurfit Westrock plc 단일.

---

## 2. Pre-merger 두 회사 구조 (참고용 — DB가 합병 전이면 필요)

### Smurfit Kappa Group plc (pre-2024-07)
- 본사: Dublin, Ireland
- 1934년 Dublin Rathmines 설립 (Jefferson Smurfit가 1938년 인수)
- 1998: Stone Container와 합병하여 Smurfit-Stone Container (US ops)
- 2002: management buyout (Madison Dearborn + Cinven + CVC)
- 2005: Kappa Packaging과 합병 → Smurfit Kappa Group
- 2007: IPO (NYSE/LSE) 
- 35 국가, ~46,000명 (2017 기준), 매출 €8.6B
- **3개 division**: Paper Division Europe, Corrugated Europe, Americas
- 5 major mill (>400kt 각): Piteå (SE), Facture (FR), Nettingsdorfer (AT), Roermond (NL), Zülpich (DE)

### WestRock Company (pre-2024-07)
- 본사: Sandy Springs (Atlanta), Georgia, USA
- 2015: MeadWestvaco + Rock-Tenn Company 합병으로 형성
- 2018: KapStone 인수
- 2023 FY 매출: $20.3 billion
- 다수 US/Canada/Mexico/Brazil/Argentina mill

---

## 3. Business segments (post-merger 2025 기준)

| Segment | 영역 |
|---|---|
| **Corrugated Packaging** | containerboard + corrugated boxes (전 영업) |
| **Global Paper** | paper mills 직판 (Pulp, paperboard, kraft paper) |
| **Consumer Packaging** | folding cartons, food/healthcare/beverage (WestRock 강세) |

**지역별 세분화** (recent earnings):
- **Europe, MEA, APAC**: $2.61B revenue (Q1 2025)
- **North America**: $4.54B revenue
- **LATAM**: $483.6M revenue

---

## 4. Regional / Sub-region tier 후보

| Regional 후보 | 영역 | 핵심 사이트 |
|---|---|---|
| **Smurfit Westrock Europe** | EU 영업 | Piteå, Facture, Nettingsdorfer, Roermond, Zülpich 등 |
| **Smurfit Westrock North America** | US/CA/MX | 다수 (구 WestRock 대부분) |
| **Smurfit Westrock LATAM** | 멕시코/브라질/아르헨/콜롬비아 | 다수 |
| **Smurfit Westrock MEA** | 모로코/사우디 등 | 소규모 |
| **Smurfit Westrock APAC** | 아시아 minor | 소규모 |
| **Smurfit Westrock UK & Ireland** | UK/Ireland 통합 | SSK Birmingham (closure consultation 진행 중), Townsend Hook |
| **Smurfit Westrock Italy / Iberia / France** | 국가별 sub-region | 다수 |

---

## 5. Mill 단위 — Smurfit Kappa legacy 핵심 paper mills

### Kraftliner mills (3대, Western Europe 40% kraftliner capacity)

| Mill | 도시/국가 | market_code | 용량 | Notes |
|---|---|---|---|---|
| **Smurfit Westrock Piteå** | Piteå, SE | sweden | **700-750kt kraftliner** | **유럽 최대 단일 kraftliner mill**, 510 employees, 1950s 설립 |
| **Smurfit Westrock Facture** | Facture (Biganos, Aquitaine), FR | france | 500-540kt kraftliner | 1928년 (Cellulose du Pin), Maritime pine |
| **Smurfit Westrock Nettingsdorf** | Nettingsdorfer (Ansfelden), AT | austria | 420kt kraftliner | Central/Eastern Europe 공급 |

### Recycled containerboard mills (2대)

| Mill | 도시/국가 | market_code | 용량 |
|---|---|---|---|
| **Smurfit Westrock Roermond** | Roermond, NL | netherlands | 520kt recycled containerboard (fluting + testliner) |
| **Smurfit Westrock Zülpich** | Zülpich, DE | germany | 450kt recycled containerboard |

### UK & Ireland

| Mill | 도시/국가 | 용량 |
|---|---|---|
| **SSK Birmingham (Smurfit Westrock)** | Birmingham, UK | **200kt fluting + linerboard — 2026-05 closure consultation 시작** |
| **Townsend Hook** | Snodland (Kent), UK | recycled containerboard |
| **Smurfit Kappa Ireland (다수 site)** | Dublin/Belfast 등 | corrugated |

### Italy / Iberia

| Mill | 도시/국가 | 비고 |
|---|---|---|
| **Smurfit Kappa Italia (다수)** | Verzuolo, Como, Padova 등 | Italian containerboard + corrugated |
| **Smurfit Kappa España (다수)** | Mengíbar, Sangüesa 등 | 스페인 mills |
| **Smurfit Kappa Portugal** | 다수 | Portuguese ops |

### Eastern Europe

| Mill | 도시/국가 | 비고 |
|---|---|---|
| **Smurfit Kappa Polska** | 다수 PL site | corrugated |
| **Smurfit Kappa Czech Republic** | 다수 | |
| **Smurfit Kappa Hungary** | 다수 | |

---

## 6. Mill 단위 — WestRock legacy paper mills (US 위주, 합병으로 통합)

### US containerboard mills (WestRock 핵심)

| Mill | 도시/주 | 비고 |
|---|---|---|
| **Mahrt Mill** | Cottonton, AL | kraft linerboard, large |
| **Solvay Mill** | Charleston, SC | kraft pulp + linerboard |
| **Hodge Mill** | Hodge, LA | |
| **Florence Mill** | Florence, SC | (KapStone legacy) |
| **Fernandina Beach Mill** | Fernandina Beach, FL | |
| **Roanoke Rapids Mill** | Roanoke Rapids, NC | |
| **Tacoma Mill** | Tacoma, WA | |
| **Longview Mill** | Longview, WA | (KapStone legacy) |
| **Cowpens Mill** | Cowpens, SC | |
| **St. Paul Mill** | St. Paul, MN | **CLOSED 2025-06** (coated recycled board, 200+ employees) |
| **Forney Mill** | Forney, TX | **containerboard production CEASED 2025-06**, specialty coating 유지, 200명 영향 |

### US consumer/specialty board

| Mill | 도시/주 | 비고 |
|---|---|---|
| **Demopolis Mill** | Demopolis, AL | coated white paperboard (SBS) |
| **Covington Mill** | Covington, VA | (구 MeadWestvaco) |
| **Mahrt and Atlanta consumer board** | 다수 | |

### LATAM mills

| Mill | 위치 | 비고 |
|---|---|---|
| **Três Barras Mill** | Três Barras, SC, Brazil | kraftliner |
| **Pacajus Mill** | Pacajus, CE, Brazil | recycled containerboard |
| **WestRock Mexico mills** | 다수 | corrugated |
| **WestRock Argentina** | 다수 | |
| **WestRock Colombia** | 다수 | (구 Smurfit Kappa Colombia + WR Colombia 합쳐졌을 가능성) |

### Canada

| Mill | 위치 | 비고 |
|---|---|---|
| **Tres Barras Brazil** | Brazil — 위 중복 | |

---

## 7. Mill 폐쇄 / 매각 (post-merger 2024-2026, 정리 필수)

후 합병 footprint optimization로 **9+ 폐쇄** announced (2024-07 ~ 2025-12):

| Mill / Plant | 위치 | 종류 | 시점 | 영향 |
|---|---|---|---|---|
| **St. Paul Mill** | St. Paul, MN | CRB mill | **2025-06 폐쇄** | 200명, 500kt+ capacity |
| **Forney Mill (containerboard)** | Forney, TX | containerboard | **2025-06 폐쇄** | 200명, specialty coating은 유지 |
| **Germany converting × 2** | DE | converting | **2025 consultation** | ~250명 |
| **Cedar Rapids Plant** | Cedar Rapids, IA | corrugated (former Longview Fibre/KapStone/WR) | **2025-10 폐쇄** | 100명 |
| **City of Industry** | City of Industry, CA | corrugated sheet/box | **2025-12-14 폐쇄** | 141명 |
| **Bridgeview Plant** | Bridgeview, IL | container | **2025-03 폐쇄** | |
| **Portland Plant** | Portland, OR | corrugated | **2025-06 phased shutdown** | |
| **SSK Birmingham Mill** | Birmingham, UK | 200kt containerboard | **2026-05 consultation 시작** | 130명 |
| **UK/NL converting × 4** | UK + NL | converting | **2026-05 consultation** | (SSK과 함께 announce) |

총 capacity reduction: **500,000+ tons containerboard/CRB**  
총 인력 감축: **4,500+명** (post-merger, 2025-Oct 기준)

---

## 8. 최근 5년 corporate events

| 날짜 | 이벤트 |
|---|---|
| 2023-09 | Smurfit Kappa + WestRock 합병 **announce** |
| 2024-07-05 | **합병 완료** (Smurfit Westrock plc 출범) |
| 2024-Q4 | Footprint optimization 시작 (800명 감원) |
| 2025-03 | Bridgeview IL 폐쇄 announce |
| 2025-04 | Portland OR 폐쇄 announce, St. Paul MN + Forney TX + DE 2 closure announce |
| 2025-06 | St. Paul MN + Forney TX 폐쇄 실행 |
| 2025-08 | Cedar Rapids IA closure announce |
| 2025-10 | City of Industry CA closure announce (9번째 폐쇄) |
| 2025-12 | City of Industry 폐쇄 실행 예정 |
| 2026-05 | SSK Birmingham UK + 4 converting (UK/NL) consultation 시작 |

---

## 9. tier_role 매핑 sketch (26 row → tier 분포 예상)

26 row는 비교적 작은 슬라이스 → DB에는 핵심 mill들만 들어있을 가능성. 예상 분포:

- **HQ × 1-2**: Smurfit Westrock plc (+ 합병 전 별도 HQ row 가능성)
- **Regional × 4-6**: Europe / NA / LATAM / UK&Ireland / 등
- **Country × 12-15**: 개별 mill 운영 법인 (Piteå, Facture, Roermond, Mahrt 등)
- **NULL / Sector × 3-5**: closed mill placeholder, 분류 미상

**합병 전 vs 후 구조 시나리오**:
- **시나리오 A** (합병 미반영): "Smurfit Kappa Group" HQ + "WestRock Company" HQ 둘 다 있음 → 통합 + alias 처리
- **시나리오 B** (합병 반영): "Smurfit Westrock plc" 단일 HQ, 자회사들 산하 정렬
- **시나리오 C** (혼합): 일부는 합병 반영, 일부는 legacy → 일관성 정정 필요

---

## 10. mill_name 정규화 후보 (#20)

| 가능한 광역 표기 | 정규화 후 |
|---|---|
| "Norrbotten County" (SE) | "Piteå" |
| "Aquitaine" 또는 "Nouvelle-Aquitaine" (FR) | "Facture" 또는 "Biganos" |
| "Upper Austria" (AT) | "Nettingsdorf" 또는 "Ansfelden" |
| "Limburg" (NL) | "Roermond" |
| "North Rhine-Westphalia" (DE) | "Zülpich" |
| "West Midlands" (UK) | "Birmingham" (SSK) |
| "Kent" (UK) | "Snodland" (Townsend Hook) |
| "Alabama" | "Cottonton" (Mahrt) 또는 "Demopolis" |
| "South Carolina" | "Charleston" (Solvay) 또는 "Florence" 또는 "Cowpens" |
| "Louisiana" | "Hodge" |
| "Florida" | "Fernandina Beach" |
| "Washington (state)" | "Tacoma" 또는 "Longview" |
| "Santa Catarina" (BR) | "Três Barras" |
| "Ceará" (BR) | "Pacajus" |

---

## 11. multi-region rollup split 후보 (#23)

- "Smurfit Kappa Italia (다수 site)" 묶음 → 개별 split
- "WestRock Brazil mills" 묶음 → Três Barras + Pacajus 분리
- "Smurfit Kappa Eastern Europe" 묶음 → PL/CZ/HU 분리

---

## 12. compound entity 정책 (#15)

후보:
- **"Smurfit Kappa / WestRock"** 합성 row → 둘로 split + "Smurfit Westrock plc" HQ 부모 추가
- "Smurfit Kappa Group plc" + "Smurfit Westrock plc" 둘 다 있으면 → 후자가 정본, 전자는 alias
- "WestRock Company" + "Smurfit Westrock plc" → 마찬가지

---

## 13. headquarters 정정 후보 (#33 일반화)

| 잘못된 가능 표기 | 정정 |
|---|---|
| "Public — NYSE listed" (회사 성격) | "Dublin, Ireland" |
| "Sandy Springs, GA, USA" (구 WestRock HQ) | "Dublin, Ireland" (현재 HQ) — 단, "North America HQ"로는 Sandy Springs 유지 가능 |
| "Founded 2024 from Smurfit Kappa + WestRock merger" (역사) | "Dublin, Ireland" |
| "Atlanta, GA" 또는 유사 | "Dublin, Ireland" |

---

## 14. evidence_level + source_url 추천

| 카테고리 | evidence | source_url |
|---|---|---|
| Group HQ | **A** | https://www.smurfitwestrock.com/ |
| Smurfit Kappa legacy mills (회사 site location 페이지 있음) | **A** | `https://www.smurfitkappa.com/locations/{country}/smurfit-kappa-{mill}-mill` (구 도메인, 일부 redirect) |
| Smurfit Westrock 통합 페이지 | **A** | `https://www.smurfitwestrock.com/locations/{...}` |
| WestRock legacy mills | **B** | 합병 후 통합 site로 migrate 진행 중 |
| Post-merger 폐쇄 mill | **A** | Packaging Dive, Paper Advance 등 뉴스 + 회사 release |

---

## 15. 위험 / 주의 항목

1. **합병 시점 (2024-07-05) DB 정합성**: DB의 마지막 데이터 새로고침 시점이 합병 전이면 대규모 정정 필요. 합병 후 시점이면 일부만.
2. **사명 변경**: "Smurfit Kappa Group plc" + "WestRock Company" → "Smurfit Westrock plc" 단일. DB에 옛 사명 row 있으면 alias 처리 또는 통합.
3. **SK Group → SWR**: Smurfit Kappa는 acquirer지만 사명/HQ는 SK 측이 유지. 즉 **법적으로는 SK가 WR을 acquired**.
4. **본사 위치**: Dublin (구 SK 본사) 유지. NA HQ는 Sandy Springs/Atlanta로 별도 표기 가능.
5. **stock listing**: NYSE (SW) + LSE (SWR) 둘 다 활성. (구 SK는 NYSE+LSE, 구 WR은 NYSE+JSE — JSE는 합병 후 delisted).
6. **Smurfit-Stone Container Corporation**: 1998-2011 시기 별도 US 법인이었음. 2011년 Rock-Tenn에 인수되어 WestRock 일부가 됨. **결국 다시 SWR로 통합** — DB에 "Smurfit-Stone" row가 있으면 묶기.
7. **KapStone**: 2018년 WestRock가 인수한 US mill 그룹 (Longview WA, Florence SC 등). 현재 SWR 산하 통합.
8. **MeadWestvaco**: 2015년 Rock-Tenn과 합병하여 WestRock 형성. 현재 SWR 산하. 별도 row면 통합.
9. **Rock-Tenn**: 2015년 MeadWestvaco와 합병. 현재 SWR 산하.
10. **DS Smith 혼동**: International Paper가 2024년 DS Smith 인수. **DS Smith는 Smurfit Westrock과 무관**. 만약 DB에 DS Smith가 SWR 산하로 잘못 들어있으면 제거.
11. **2026-05 SSK Birmingham UK closure**: DB 시점 기준 — May 15 핸드오프 시점에 consultation 진행 중. closure 확정 대기. 일단 active로 유지하되 notes에 "closure consultation 2026-05~" 표기 권장.

---

## 16. 누락 / 통합 row 처리 후보

```sql
-- 합병 반영 HQ row 정정
UPDATE industry.paper_companies
SET name = 'Smurfit Westrock plc',
    headquarters = 'Dublin, Ireland',
    notes = 'Merged 2024-07-05 from Smurfit Kappa Group plc + WestRock Company. NYSE/LSE listed.'
WHERE name IN ('Smurfit Kappa Group plc', 'Smurfit Kappa Group', 'Smurfit Kappa');

-- 합병 alias 정리 (별도 row면 삭제 또는 merge)
DELETE FROM industry.paper_companies
WHERE name = 'WestRock Company' 
  AND EXISTS (SELECT 1 FROM industry.paper_companies WHERE name = 'Smurfit Westrock plc');
-- ↑ 이건 실제 실행 전 paper_mills 의 FK 영향 확인 필수

-- St. Paul / Forney closure 라벨
UPDATE industry.paper_mills
SET notes = 'Permanently closed 2025-06 (post-merger footprint optimization)'
WHERE city IN ('St. Paul') AND main_products LIKE '%coated recycled board%';
```

---

## 17. 출처

- https://en.wikipedia.org/wiki/Smurfit_Westrock — corporate overview
- https://www.smurfitwestrock.com/ — 공식 사이트
- https://www.smurfitkappa.com/ — Smurfit Kappa legacy 사이트 (일부 redirect)
- https://www.paperadvance.com/news/industry-news/smurfit-westrock-to-cut-capacity-close-four-facilities.html — 2025-04 closure 발표
- https://www.packagingdive.com/news/smurfit-westrock-closures-layoffs-minnesota-texas-germany/746824/ — 2025-05 폐쇄 상세
- https://www.packagingdive.com/news/smurfit-westrock-shutting-down-city-of-industry-california-corrugated-layoffs/804172/ — 2025-10 City of Industry
- https://www.euwid-paper.com/news/companies/smurfit-westrock-mulls-closing-birmingham-paper-mill-and-four-converting-sites-040526/ — 2026-05 SSK Birmingham
