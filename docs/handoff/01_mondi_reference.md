# Mondi family — Pre-research Reference

**작성일**: 2026-05-15  
**다음 세션 사용처**: handoff v5.7 권장 시나리오 B (Mondi 43 row 정리)  
**용도**: SQL CSV 결과 받기 전 매핑 사전 준비

---

## 1. Group level (HQ tier)

| 항목 | 값 |
|---|---|
| 정식명 | **Mondi plc** |
| 본사 | Weybridge, England, United Kingdom (Mercedes-Benz World 인근) |
| 상장 | LSE (MNDI, FTSE100) + JSE (MNP, secondary, ESCC category) |
| 법인 등록 | England and Wales, Registered No. 6209386 |
| 2025 매출 | €7.7B / Underlying EBITDA €1.0B |
| 직원 | ~24,000명, 30+ 국가, 100+ production sites |
| CEO | Andrew King (2020년 4월 ~) |
| 모회사 (구) | Anglo American plc (2007년 7월 demerger) |
| 단일 holdco 전환 | 2019년 (이전엔 dual listed: Mondi plc + Mondi Limited) |

**DB 적용**:
- `paper_companies` HQ tier row 1개: name = "Mondi plc" 또는 "Mondi Group"
- `headquarters` = "Weybridge, UK" (#33 Sappi 유사 fix 패턴 유의: "Public — LSE/JSE-listed" 같은 회사 성격 메모가 들어있으면 정정)
- `market_code` = `united_kingdom`
- `tier_role` = `HQ`

---

## 2. Business segments (2025 재편 후)

2025년에 **Uncoated Fine Paper + Corrugated Packaging → 통합 "Corrugated Packaging" enlarged segment**로 합쳐짐. 즉 현재 2개 enlarged segment:

1. **Corrugated Packaging** (구 UFP 통합) — virgin containerboard + uncoated fine paper + corrugated solutions
2. **Flexible Packaging** — kraft paper + paper bags + consumer flexibles + functional paper/films + market pulp

**DB 적용**:
- segment 자체는 별도 tier가 아님 → main_product_category 컬럼에 반영 권장
- Regional tier row가 segment 기준으로 분리될 수 있음 (e.g. "Mondi Kraft Paper", "Mondi Containerboard")

---

## 3. Regional / business unit tier (예상)

Mondi 공식 발표 brand-level 묶음으로 보이는 단위들:

| Regional 후보 | 영역 | 주요 mill 묶음 |
|---|---|---|
| **Mondi Uncoated Fine Paper (UFP)** | UFP 5개 mill | Neusiedler (AT), Frantschach 일부, SCP (SK), Merebank (ZA), Richards Bay (ZA, 일부) |
| **Mondi Kraft Paper** | sack kraft 등 | Frantschach (AT), Štětí (CZ), Świecie (PL), Stambolijski (BG, **closed 2024**), Lohja (FI, **closed 2015**), Richards Bay (ZA), Syktyvkar (RU, **divested 2023**), Hinton (CA) |
| **Mondi Containerboard** | virgin + recycled | Świecie (PL), Richards Bay (ZA), Duino (IT), Štětí (CZ) |
| **Mondi Corrugated Solutions (Europe)** | corrugated converting plants | Mondi Bupak (CZ), Mondi Grünburg (AT), 다수 EU 국가 converting plants |
| **Mondi Paper Bags / Flexible Packaging** | paper bag converting + flexibles | Mondi Bags Świecie (PL), Schumacher WE operations (DE/NL/BE 등), 10+ paper bag plants in Americas |
| **Mondi North America** | NA 사업 | Hinton pulp mill (CA) + 10 paper bag plants (US/CA/Mexico) |
| **Mondi South Africa** | 남아공 영업 | Limited 별도 법인 (구 dual list 잔재), Merebank + Richards Bay |

**DB 적용**:
- "Mondi Europe" / "Mondi North America" / "Mondi South Africa" 같은 지역 묶음이 paper_companies에 있을 가능성 (Sappi 패턴과 유사)
- 또는 segment-based ("Mondi Kraft Paper", "Mondi Containerboard") 묶음일 수도
- SQL 결과 받기 전엔 단정 불가 → 둘 다 후보로 열어둠

---

## 4. Country / Subsidiary tier (법인명 단위)

확인된 회사 법인 (가능한 한 정식명):

| 국가 | 법인명 | 비고 |
|---|---|---|
| 🇸🇰 Slovakia | **Mondi SCP a.s.** (Ružomberok) | 가장 큰 통합 mill |
| 🇨🇿 Czech Republic | **Mondi Štětí a.s.** | Litoměřická 272, 41108 Štětí |
| 🇨🇿 Czech Republic | **Mondi Bupak s.r.o.** (České Budějovice) | corrugated 전용 |
| 🇦🇹 Austria | **Mondi Frantschach GmbH** | St. Gertraud, Carinthia |
| 🇦🇹 Austria | **Mondi Neusiedler GmbH** | Ulmerfeld-Hausmening + Kematen 2개 site |
| 🇦🇹 Austria | **Mondi Grünburg GmbH** | corrugated, offset printing |
| 🇵🇱 Poland | **Mondi Świecie sp. z o.o.** | KRS 0001107981, 주요 paper mill |
| 🇵🇱 Poland | **Mondi Bags Świecie sp. z o.o.** | Bydgoska 12, 86-100 Świecie (별도 법인, paper bag conversion) |
| 🇧🇬 Bulgaria | **Mondi Stambolijski EAD** | FISCAL 130839571 — **2024년 10월 영구 폐쇄** |
| 🇿🇦 South Africa | **Mondi Limited** | JSE secondary listing 잔재 법인 |
| 🇨🇦 Canada | **Mondi Hinton Inc.** | Alberta, 2024년 2월 acquired |
| 🇹🇷 Turkey | **Mondi Tire Kutsan** | corrugated, Turkish ops |
| 🇩🇪 Germany | (Schumacher WE 인수 통합 중) | 2025년 3월 acquisition completed |

---

## 5. Mill 단위 (paper/pulp/board mill only — converting plant 제외)

확인된 핵심 mill (도시 단위로 #20 정규화):

| Mill | 도시/국가 | market_code | 주요 제품 | tier_role (소속회사) | Notes |
|---|---|---|---|---|---|
| Mondi Štětí | Štětí, CZ | czech_republic | sack kraft, pulp (7 PM) | Country (Mondi Štětí a.s.) | 2024년 12월 PM10 startup (kraft) |
| Mondi SCP Ružomberok | Ružomberok, SK | slovakia | uncoated fine paper, pulp, kraft top white | Country (Mondi SCP a.s.) | 300kt KTW machine added; 슬로바키아 최대 통합 mill |
| Mondi Frantschach | St. Gertraud, AT | austria | sack kraft, MG kraft, specialty pulp | Country (Mondi Frantschach GmbH) | Group R&D Innovation Centre |
| Mondi Neusiedler (Hausmening) | Ulmerfeld-Hausmening, AT | austria | UFP (PERGRAPHICA) | Country (Mondi Neusiedler GmbH) | 1793 설립 |
| Mondi Neusiedler (Kematen) | Kematen, AT | austria | UFP, pulp | Country (Mondi Neusiedler GmbH) | 별도 site, **multi-region rollup split #23 주의 — 1 row면 split 필요** |
| Mondi Świecie | Świecie, PL | poland | kraftliner, recycled containerboard | Country (Mondi Świecie sp. z o.o.) | 폴란드 주력 paper mill |
| Mondi Richards Bay | Richards Bay, ZA | south_africa | Baycel pulp (eucalyptus), Baywhite kraft linerboard | Country (Mondi Limited) | 1984 commissioned |
| Mondi Merebank | Durban, ZA | south_africa | UFP (Mondi Rotatrim), office paper | Country (Mondi Limited) | 1967 — Mondi 발상지 |
| Mondi Duino | Duino-Aurisina, IT | italy | recycled containerboard (420kt 신기) | Country (Mondi Duino S.r.l. 추정) | 2023년 1월 Burgo Group에서 €40M에 인수, 2025년 4월 신규 PM start |
| Mondi Hinton | Hinton, Alberta, CA | canada | unbleached kraft pulp (UKP, 250kt) | Country (Mondi Hinton Inc.) | 2024년 2월 West Fraser에서 $5M에 인수, 향후 200kt kraft PM 추가 검토 |
| Mondi Stambolijski | Stambolijski, BG | bulgaria | sack kraft (100kt, 1 PM) | **CLOSED 2024-10-25** (Country, Mondi Stambolijski EAD) | 2024-09-24 화재 → 영구 폐쇄. **DB에 active로 남아있으면 closed 처리 필요** |
| Mondi Lohja | Lohja, FI | finland | specialty kraft (release liner, medical) | **CLOSED ~2015** (Country) | 2014 PM1 idle → 2015년 전면 폐쇄. **#34 type 라벨 정정 후보** |
| Mondi Syktyvkar | Syktyvkar, Komi Republic, RU | russia | pulp + paper | **DIVESTED 2023-09** | Russia 자산 매각, Feb 2024 주주 환원 완료. **DB에 active로 남아있으면 divested 처리 필요** |

**총 paper/pulp/board mill 수**: 활성 ~10개 + closed/divested 3개

**남는 ~30 row 추정 (43 - 13)**: 대부분 corrugated/converting plant (Bupak, Grünburg, Mondi Tire Kutsan Turkey, Schumacher WE 인수 site 등) — 회사 측 분류로는 mill이 아닐 수 있으나 DB에서 동일 테이블에 들어있을 가능성.

---

## 6. 최근 5년 corporate events (DB에 영향)

| 날짜 | 이벤트 | 영향 |
|---|---|---|
| 2022-05 | Russia 자산 매각 발표 | Syktyvkar 등 |
| 2023-01 | Burgo Group에서 **Duino mill 인수** (€40M) | Italy 신규 site |
| 2023-09 | **Russia 매각 완료** (Syktyvkar) | active → divested |
| 2024-02 | **Hinton pulp mill 인수** ($5M, West Fraser) | Canada 신규 진입 |
| 2024-02 | Russia 매각 proceeds 주주 환원 | 회계상 정리 |
| 2024-03 | DS Smith £5.1B 인수 제안 | **실패** (International Paper가 결국 인수). **Mondi에 DS Smith mill이 있으면 잘못된 매핑** |
| 2024-09 | Stambolijski 화재 | Bulgaria mill |
| 2024-10 | **Stambolijski 영구 폐쇄 결정** | active → closed |
| 2024-12 | Štětí **PM10 startup** (kraft) | 신규 capacity |
| 2025-03 | **Schumacher Packaging Western Europe 인수 완료** | DE/NL/BE paper bag 다수 site 추가 |
| 2025-04 | Duino 신규 **420kt 재활용 containerboard PM startup** | capacity 증가 |
| 2025년 | UFP + Corrugated Packaging segment 통합 | 조직 재편 (DB segment 컬럼 영향 없음, but main_product_category 분류 영향) |

---

## 7. tier_role 매핑 sketch (SQL 결과 받으면 빠르게 적용 가능)

### HQ tier (1 row)
- name LIKE '%Mondi plc%' OR LIKE '%Mondi Group%' OR LIKE 'Mondi' (id 단일) → `tier_role = 'HQ'`, `market_code = 'united_kingdom'`, `headquarters = 'Weybridge, UK'`

### Regional tier (예상 2-4 row)
후보:
- "Mondi Europe" / "Mondi Europe & International" → `tier_role = 'Regional'`, market_code = `europe_composite`
- "Mondi North America" → `tier_role = 'Regional'`, market_code = `usa`
- "Mondi South Africa" (구 Mondi Limited JSE 잔재) → `tier_role = 'Regional'`, market_code = `south_africa`
- segment-based ("Mondi Kraft Paper" 등)가 들어있으면 그것도 Regional

### Country tier (~10-15 row)
국가별 법인:
- Mondi SCP (Slovakia)
- Mondi Štětí (Czech), Mondi Bupak (Czech)
- Mondi Frantschach, Mondi Neusiedler, Mondi Grünburg (Austria — 3 row)
- Mondi Świecie, Mondi Bags Świecie (Poland — 2 row)
- Mondi Stambolijski (Bulgaria — **CLOSED**)
- Mondi Limited (South Africa)
- Mondi Hinton (Canada)
- Mondi Duino (Italy)
- Mondi Lohja (Finland — **CLOSED**)
- Mondi Syktyvkar (Russia — **DIVESTED**)
- Mondi Tire Kutsan (Turkey)
- (잠재) Schumacher 흡수 법인 (DE/NL/BE)

### NULL / Sector / Closed (#34 라벨 정정 대상)
- Lohja 폐쇄 mill — closure 라벨 명확화
- Stambolijski — closure 라벨 추가
- Syktyvkar — divested 라벨 추가
- DS Smith 잘못 매핑 row 있으면 제거 (International Paper로 넘어감)

---

## 8. mill_name 정규화 후보 (#20 적용)

DB에 `KwaZulu-Natal` 같은 광역주 단위로 들어있을 가능성 (Sappi에서 발견된 #31 패턴):

| 가능한 광역 표기 | 정규화 후 |
|---|---|
| "Carinthia" (Sappi 케이스와 유사) | "St. Gertraud" 또는 "Wolfsberg" (Frantschach 위치) |
| "Lower Austria" | "Hausmening" 또는 "Kematen" (Neusiedler) |
| "Ústí Region" | "Štětí" |
| "South Bohemia" | "České Budějovice" (Bupak) |
| "Upper Austria" | "Grünburg" 또는 "Hilm" |
| "Žilina Region" | "Ružomberok" |
| "Kuyavian-Pomeranian" | "Świecie" |
| "Plovdiv Province" | "Stambolijski" |
| "KwaZulu-Natal" | "Richards Bay" 또는 "Durban" (어느 mill인지에 따라) |
| "Alberta" | "Hinton" |
| "Friuli-Venezia Giulia" | "Duino" 또는 "Duino-Aurisina" |
| "Uusimaa" | "Lohja" |

---

## 9. multi-region rollup split 후보 (#23)

**Mondi Neusiedler** = Hausmening + Kematen 2개 site인데 DB에 1 row면 split 필요.

**Mondi Świecie** = paper mill (Mondi Świecie sp. z o.o.) + paper bag plant (Mondi Bags Świecie) 2개 법인인데 같은 도시 — DB row가 어떻게 분리되어 있는지 결과 보고 판단.

**Mondi North America paper bag operations** = 10개 plant. DB에 묶음으로 들어있을 가능성.

---

## 10. compound entity 정책 (#15)

Mondi family에서 compound 가능성:
- "Mondi Neusiedler / Mondi Frantschach" 결합 row (둘 다 Austria) — split 필요
- "Mondi Europe (Štětí + Świecie + Ružomberok)" 같은 묶음 row — split 필요
- "Mondi Schumacher acquisitions" 묶음 — 개별 site로 split 필요

Sappi의 "Crown Van Gelder / Sappi UK closures" 같은 잘못된 묶음 (#34) 패턴 유의.

---

## 11. evidence_level 추천값 (#36 일반화)

| Mill | evidence_level | 출처 |
|---|---|---|
| 모든 활성 Mondi mill (회사 site에 location 페이지 존재) | **A** | `https://www.mondigroup.com/locations/{country}/{mill}/` |
| Stambolijski (closed) | **A** | https://www.mondigroup.com/locations/bulgaria/mondi-stambolijski/ + 뉴스 |
| Lohja (closed) | **B** | EUWID + News24 |
| Syktyvkar (divested) | **B** | Wikipedia + Mondi 2024 results |
| Schumacher 인수 site | **B** (구체 site list 미확정) | https://www.mondigroup.com/news-and-insight/ |
| HQ (Mondi plc) | **A** | https://www.mondigroup.com/about-mondi/ + 2025 Integrated Report |

전 row evidence_level 채움 SQL 패턴 (Sappi #36 일반화):
```sql
UPDATE industry.paper_companies 
SET evidence_level = 'A', 
    source_url = 'https://www.mondigroup.com/locations/{country}/{slug}/'
WHERE id IN (...);
```

---

## 12. headquarters 정정 후보 (#33 일반화)

Mondi plc HQ row가 잘못 채워져 있을 수 있는 후보 텍스트:
- `"Public — LSE/JSE dual-listed"` (회사 성격)
- `"Anglo American spinoff"` (역사 메모)
- `"London, UK"` (정확하진 않음 — Weybridge가 맞음. 그러나 London도 허용 가능 시 표기 통일)

**권장 표기**: `"Weybridge, United Kingdom"` 또는 `"Weybridge, Surrey, UK"`

---

## 13. 위험 / 주의 항목

1. **DS Smith 혼동**: Mondi가 2024년 3월 DS Smith £5.1B 제안했으나 **실패**. International Paper가 인수. DB에 DS Smith mill이 Mondi 산하로 잘못 들어있으면 제거 (별도 family).
2. **Mpact**: 2011년 Mondi Packaging South Africa demerger → 별도 JSE 상장사. Mondi family에서 분리 확인.
3. **Lohja Sappi vs Mondi 혼동**: 같은 도시(Lohja, FI)에 **Sappi Kirkniemi Mill** + **구 Mondi Lohja mill** 둘 다 있었음. mill_name으로 명확히 구분.
4. **South Africa "Mondi Limited"**: 구 dual-listed 잔재. 현재는 JSE secondary listing만 유지. Mondi plc 단일 holdco 하위. tier 표기 시 "Country" 권장 (Regional 아님).
5. **Schumacher 인수**: 2025년 3월 통합 완료. Western Europe paper bag operations — DE/NL/BE 등 site. DB에 미반영 가능성 큼 → 누락 row INSERT 후보.
6. **Hinton**: 250kt UKP. 향후 paper machine 추가 계획. main_products에 "pulp only (kraft paper machine planned)" 명시 권장.

---

## 14. 누락된 paper_companies row INSERT 후보 (SQL 결과 받고 비교 필요)

만약 DB에서 누락됐다면 추가 후보:

```sql
-- 예시 (실제 컬럼은 v5.7에서 확정된 schema에 맞춰 조정 필요)
INSERT INTO industry.paper_companies (name, market_code, tier_role, headquarters, evidence_level, source_url, main_product_category, main_products, notes)
VALUES
  ('Mondi Hinton Inc.', 'canada', 'Country', 'Hinton, Alberta, CA', 'A',
   'https://www.mondigroup.com/locations/canada/mondi-hinton/',
   'pulp', 'Unbleached kraft pulp (250kt/y)',
   'Acquired 2024-02 from West Fraser, $5M. Future kraft paper machine planned (~200kt).'),
  ('Mondi Duino S.r.l.', 'italy', 'Country', 'Duino-Aurisina, IT', 'A',
   'https://www.mondigroup.com/locations/italy/mondi-duino/',
   'containerboard', 'Recycled containerboard (420kt/y new PM, 2025-04 startup)',
   'Acquired 2023-01 from Burgo Group, €40M.'),
  ('Schumacher Packaging WE (Mondi)', 'germany', 'Country', 'TBD', 'B',
   'https://www.mondigroup.com/news-and-insight/2025/',
   'paper_bags', 'Industrial paper bags',
   'Acquired Western Europe operations 2025-03. Sites TBD.');
```

---

## 15. 다음 세션 즉시 사용 가능한 SQL 작업 패턴

YunYoung이 SQL CSV 결과 첨부 시 매핑 순서:

**Stage 1**: SQL 결과 → 본 reference의 §5 mill 표와 mill_name 매칭
- 정확 매칭: 그대로 tier 채움
- 광역주 표기: §8 mill_name 정규화 후보로 정정
- 미확인 mill: SQL UPDATE에서 보류

**Stage 2**: SQL 결과 → 본 reference의 §4 회사 표와 paper_companies 매칭
- HQ 1 row 확인 (Mondi plc)
- Regional 2-4 row 후보 식별
- Country ~10-15 row tier_role 채움
- 누락된 Hinton/Duino/Schumacher row INSERT

**Stage 3**: Closure/Divestiture 처리
- Stambolijski → closed 라벨
- Lohja → closed 라벨
- Syktyvkar → divested 라벨

**Stage 4**: evidence_level 일괄 'A' 채움 (대부분 회사 site에 location 페이지 있음)

**Stage 5**: mill_name 정규화 (§8 적용) + multi-region split (§9 적용)

---

## 16. 출처 (Tier 1 우선)

- https://www.mondigroup.com/locations/ — 공식 location 디렉토리
- https://www.mondigroup.com/investors/results-reports-and-presentations/2025/integrated-report/mondi-group-integrated-report-and-financial-statements-2025.pdf — 2025 Integrated Report
- https://www.mondigroup.com/globalassets/mondigroup.com/investors/results-reports-and-presentations/2025/fy-results/mondi-group---full-year-results-announcement-2025.pdf — 2025 FY results
- https://en.wikipedia.org/wiki/Mondi — corporate history (Tier 2)
- https://www.euwid-paper.com/news/companies/mondi-to-permanently-close-stambolijski-sack-kraft-paper-mill-in-bulgaria-251024/ — Stambolijski closure
- https://www.mondigroup.com/news-and-insight/2024/mondi-completes-acquisition-of-hinton-pulp-mill/ — Hinton 인수

---

## 17. 본 reference 사용 권장 워크플로 (YunYoung 다음 세션)

1. Supabase SQL Editor에서 v5.7 handoff §B의 두 쿼리 실행 → CSV로 받아 새 세션에 첨부
2. 본 reference 같이 첨부 (이 문서)
3. Claude에게: "본 reference §5(mill) + §4(company)와 CSV 매칭해서 마이그레이션 SQL 생성해줘"
4. Claude 생성한 SQL을 Supabase SQL Editor에 paste → 실행 → 결과 검증
5. v5.7 Sappi처럼 시각 검증: `/industry/paper-mills?search=mondi` 화면에서 row 수 + tier 색깔 확인

이 reference 덕분에 SQL 결과 받은 후 매핑 작업은 **20-30분 내로 완료 가능**할 것으로 예상.
