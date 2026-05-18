# UPM family — Pre-research Reference

**작성일**: 2026-05-15  
**다음 세션 사용처**: handoff v5.7 권장 시나리오 C (UPM 26 row 정리)

---

## 1. Group level (HQ tier)

| 항목 | 값 |
|---|---|
| 정식명 | **UPM-Kymmene Oyj** (UPM-Kymmene Corporation) |
| 통칭 | UPM, "The Biofore Company", "Beyond fossils" |
| HQ | **Helsinki, Finland** (Biofore House, 도심) |
| 상장 | Nasdaq Helsinki (UPM1V) |
| 형성 | 1995/1996 — Kymmene Corp + Repola Oy + United Paper Mills Ltd 합병 |
| 2024 매출 | €10.3B / Comparable EBIT €1.22B |
| 직원 | ~15,800–16,000명 (2024), 12+ 국가 production sites |
| 산림 | Finland 522,000 hectares 자체 보유 (100% certified) |
| Verla mill | UNESCO World Heritage Site (1996년 지정, 박물관) |

**DB 적용**:
- `paper_companies` HQ tier row: name = "UPM-Kymmene Oyj" or "UPM-Kymmene Corporation"
- `headquarters` = "Helsinki, Finland"
- `market_code` = `finland`
- `tier_role` = `HQ`

---

## 2. Business areas (6개)

UPM은 6개 business area로 구성:

| Business Area | 영역 | 주요 사이트 |
|---|---|---|
| **UPM Fibres** | pulp + sawn timber + timber JV | 3 FI pulp + 2 UY pulp + 4 FI sawmill |
| **UPM Communication Papers** | magazine/news/fine paper | 10 mills (Europe + USA) — Augsburg HQ |
| **UPM Specialty Papers** | release liner, label, food contact | FI + DE + CN |
| **UPM Raflatac / Adhesive Materials** | self-adhesive label stock | 글로벌 (CN/US/EU/SEA) |
| **UPM Plywood** | plywood + LVL veneer | 8 mills (FI + EE) |
| **UPM Biorefining** (구 분리, 현재 통합) | UPM Biofuels + Biochemicals + Biomedicals + Biocomposites | Lappeenranta (FI), Leuna (DE) |
| **UPM Energy** | hydro + nuclear + thermal | FI 두 번째 큰 전력 producer |

**참고**: UPM Biorefining 부문은 시기에 따라 별도 BA로 표기되거나 묶여서 표기됨. 2024 Annual Report 기준 정리 권장.

---

## 3. Regional / Sub-region tier 후보

| Regional 후보 | 영역 | Notes |
|---|---|---|
| **UPM Communication Papers** | 10 paper mills (EU+US) | Augsburg head office |
| **UPM Specialty Papers** | 5+ mills | release liner / siliconized base / label |
| **UPM Fibres (Pulp)** | 5 pulp mill (3 FI + 2 UY) | |
| **UPM Fibres (Timber)** | 4 sawmill (FI) | |
| **UPM Plywood** | 8 plywood mill (FI + EE) | |
| **UPM Biorefining** | 2 site (FI Lappeenranta + DE Leuna) | |
| **UPM Energy** | FI hydro/nuclear/thermal | site로 잡힐 가능성 낮음 |
| **UPM Adhesive Materials (구 Raflatac)** | 글로벌 | Tampere + Dixon + 등 |

---

## 4. Mill 단위 — UPM Communication Papers (10 mill, 2024년 9월 기준)

| Mill | 도시 | 국가 | market_code | 주요 제품 | Notes |
|---|---|---|---|---|---|
| **UPM Augsburg** | Augsburg | DE | germany | UFP + 머신 paper | 1849년 설립, ~282명, CP HQ 사무소 동거 |
| **UPM Ettringen** | Ettringen | DE | germany | 비코팅 mechanical paper (270kt/y) | ~235명. **closure 발표 (지연 — 법적 분쟁)** |
| **UPM Schongau** | Schongau | DE | germany | newsprint/SC paper | 큰 mill |
| **UPM Plattling** | Plattling | DE | germany | newsprint/SC | (2021년 active 였으나 closure 가능성 확인 필요) |
| **UPM Hürth** | Hürth (Köln 근교) | DE | germany | recycled newsprint | (2021년 active) |
| **UPM Nordland Papier** | Dörpen | DE | germany | UFP / fine paper | EU에서 큰 fine paper mill |
| **UPM Jämsänkoski** | Jämsä | FI | finland | magazine paper (LWC, SC) | |
| **UPM Kaukas** | Lappeenranta | FI | finland | magazine paper + 별도 pulp+saw mill | 통합 site |
| **UPM Kymi** | Kuusankoski (Kouvola) | FI | finland | fine paper + pulp | 통합 site |
| **UPM Rauma** | Rauma | FI | finland | magazine paper (LWC) | |
| **UPM Caledonian** | Irvine | UK | united_kingdom | LWC magazine paper | Scotland — 단일 영국 mill |
| **UPM Blandin** | Grand Rapids, MN | USA | usa | LWC magazine paper | 단일 US CP mill |

**Communication Papers 2024 → 10 mill** (위 12에서 2개 폐쇄됨, 확인 필요):
- 2024년 공식 list: Augsburg / Blandin / Caledonian / Ettringen / Jämsänkoski / Kaukas / Kymi / Nordland Papier / Rauma / Schongau (10개)
- 빠진 것: **Plattling, Hürth** — 폐쇄 가능성 (verification 필요)

---

## 5. Mill 단위 — UPM Fibres pulp mills

| Mill | 도시 | 국가 | Pulp 종류 | 용량 |
|---|---|---|---|---|
| **UPM Kaukas pulp mill** | Lappeenranta | FI | BSK + BHKP | (Kaukas 통합) |
| **UPM Kymi pulp mill** | Kuusankoski | FI | BSK + BHKP | (Kymi 통합) |
| **UPM Pietarsaari (Jakobstad)** | Pietarsaari | FI | BSK + 별도 | |
| **UPM Fray Bentos** | Fray Bentos | UY | BHKP (eucalyptus) | 1.3 Mt/y, 2007 startup |
| **UPM Paso de los Toros** | Paso de los Toros (Durazno/Tacuarembó) | UY | BHKP | 2.1 Mt/y, 2023-04 startup, **세계 최대 단일 BHKP mill 중 하나** |

UPM Fibres 총 pulp capacity: **5.8 Mt/y**

---

## 6. Mill 단위 — UPM Sawmills (4개)

| Sawmill | 도시 | Notes |
|---|---|---|
| **UPM Kaukas sawmill** | Lappeenranta | (Kaukas 통합) |
| **UPM Korkeakoski** | Korkeakoski | |
| **UPM Pellos** | Pellosniemi | |
| **UPM Seikku** | Pori | |

(Alholma 등 추가 가능성 — DB 결과 보고 확인)

---

## 7. Mill 단위 — UPM Plywood (8 mill)

| Plywood mill | 위치 | 국가 |
|---|---|---|
| **UPM Joensuu** | Joensuu | FI |
| **UPM Savonlinna** | Savonlinna | FI |
| **UPM Jyväskylä** | Jyväskylä | FI | **2025 closure planning announced** |
| **UPM Pellos** | Ristiina | FI |
| **UPM Kalso** | Kalso | FI |
| **UPM Lohja** | Lohja | FI (Plywood — Sappi/Mondi Lohja와 별개) |
| **UPM Säynätsalo** | Säynätsalo (Jyväskylä) | FI |
| **UPM Otepää** | Otepää | EE (Estonia) |
| **UPM Chudovo** | Chudovo | RU — **DIVESTED 2022** |

---

## 8. Mill 단위 — UPM Specialty Papers

| Mill | 위치 | 국가 | 주요 제품 |
|---|---|---|---|
| **UPM Tervasaari** | Valkeakoski | FI | release liner, label |
| **UPM Jämsänkoski (specialty section)** | Jämsä | FI | (Communication과 별도) |
| **UPM Nordland Papier (specialty section)** | Dörpen | DE | (Communication과 동거 사이트) |
| **UPM Changshu** | Changshu | CN | release liner, fine paper |

UPM Communication과 일부 site sharing — DB row 분리 패턴 확인 필요.

---

## 9. Mill 단위 — Biorefining + Adhesive Materials

| Site | 위치 | 국가 | 주요 제품 |
|---|---|---|---|
| **UPM Lappeenranta Biorefinery** | Lappeenranta | FI | 재생 디젤, biofuels (crude tall oil 기반) |
| **UPM Leuna Biorefinery** | Leuna (Saxony-Anhalt) | DE | BioMEG + lignin (€750M, 2024-Q4 commissioning, H2 2025 commercial) |
| **UPM Raflatac Tampere** | Tampere | FI | 라벨 stock |
| UPM Raflatac Dixon / Fletcher / Mills River / Nancy / Toronto | US/FR/CA | 다수 | label/adhesive |
| **UPM Adhesive Materials Malaysia** | Johor | MY | 2025+ 신규 |

(이 영역은 paper_mills 테이블에 안 들어갈 가능성 큼)

---

## 10. CLOSED / DIVESTED mills (정리 필수)

| Mill | 국가 | 상태 | 시점 |
|---|---|---|---|
| **UPM Kaipola** | Jämsä, FI | **CLOSED** | 2020 (paper mill — newsprint, SC) |
| **UPM Tervasaari paper** | Valkeakoski, FI | partial closure | 일부 paper line 축소 |
| **UPM Plattling** | Plattling, DE | (status 확인 필요 — 2024 list 없음) | 추정 closure or 매각 |
| **UPM Hürth** | Hürth, DE | (status 확인 필요) | 추정 closure |
| **UPM Stracel** | Strasbourg, FR | **CLOSED/SOLD** | (2010s, ~2014) |
| **UPM Docelles** | Docelles, FR | **CLOSED** | 2014 |
| **UPM Chapelle Darblay** | Grand-Couronne (Rouen), FR | **CLOSED** | 2020s, 일부 buyer Veolia/Fibre Excellence-related |
| **UPM Steyrermühl** | Steyrermühl, AT | **CLOSED** | 2024 (paper line) |
| **UPM Schwedt** | Schwedt, DE | **DIVESTED** | 2017 (LEIPA에 매각) |
| **UPM Madison Paper Industries** | Madison, ME, USA | **CLOSED** | 2017 |
| **UPM Shotton** | Wales, UK | **DIVESTED** | 2022 (DS Smith에 매각) |
| **UPM Myllykoski mills (3개)** | FI | partial closure | 2011 Myllykoski 인수 후 일부 폐쇄 |
| **UPM Ettringen** | Ettringen, DE | **CLOSURE planned (지연)** | 2025 발표, 법적 분쟁 |
| **UPM Jyväskylä Plywood** | Jyväskylä, FI | **CLOSURE planning** | 2025 announce |
| **UPM Chudovo Plywood (Russia)** | Chudovo, RU | **DIVESTED** | 2022 |
| **UPM Biofuels Rotterdam** | Rotterdam, NL | **DISCONTINUED** (development) | 2025-05 cancellation |

---

## 11. 최근 5년 corporate events

| 날짜 | 이벤트 |
|---|---|
| 2020 | **Kaipola mill 폐쇄** (FI) |
| 2020 | Chapelle Darblay 폐쇄 (FR) |
| 2022 | Russia 사업 (Chudovo plywood) 매각 |
| 2022 | Shotton (UK) → DS Smith 매각 |
| 2023-04 | **Paso de los Toros pulp mill startup** (UY, $3.47B, 2.1Mt) — 세계 최대 BHKP mill 진입 |
| 2024 | Steyrermühl (AT) paper line 폐쇄 |
| 2024-Q4 | **Leuna Biorefinery commissioning** (DE, €750M) — 차세대 wood-based biochemicals |
| 2025-03 | UPM Communication Papers DE 구조조정 announce (Ettringen closure 등) |
| 2025-05 | Biofuels Rotterdam 개발 중단 |
| 2025-H2 | Leuna 상업 production 예정 |
| 2025 | Jyväskylä Plywood 폐쇄 planning |
| 2026 | Adhesive Materials Malaysia (Johor) 투자 발표 |

---

## 12. tier_role 매핑 sketch (26 row → tier 분포 예상)

26 row 분포 추정:
- **HQ × 1**: UPM-Kymmene Oyj
- **Regional × 5-7**: business area별 (Communication Papers, Specialty Papers, Fibres, Plywood, Biorefining, Raflatac 등)
- **Country × 14-18**: 개별 mill 운영 법인
- **NULL / Sector × 2-4**: closed/divested placeholder

**Country tier 후보 (운영 법인)**:
- UPM Communication Papers (Augsburg 본사) → Regional
- UPM Communication Papers (각 mill 개별 법인) → Country
- UPM Pulp (각 국가)
- UPM Fibras del Plata (Uruguay 법인)
- UPM Plywood Oy (FI 법인)

**Country tier mill operating 법인 후보 패턴**:
- UPM Kymmene Augsburg GmbH
- UPM Kymmene Nordland Papier GmbH
- UPM Kymmene Schongau GmbH
- UPM Kymmene Ettringen GmbH
- UPM Forestal Oriental S.A. (Uruguay forest)
- UPM Fray Bentos S.A.
- UPM Paso de los Toros S.A. 등

---

## 13. mill_name 정규화 후보 (#20)

| 가능한 광역 표기 | 정규화 후 |
|---|---|
| "Bavaria" (DE) | "Augsburg" or "Schongau" or "Ettringen" or "Plattling" — 어느 mill인지 |
| "Lower Saxony" (DE) | "Dörpen" (Nordland Papier) |
| "North Rhine-Westphalia" (DE) | "Hürth" |
| "Saxony-Anhalt" (DE) | "Leuna" (biorefinery) |
| "South Karelia" (FI) | "Lappeenranta" (Kaukas) 또는 "Kuusankoski" (Kymi) |
| "Kymenlaakso" (FI) | "Kuusankoski" 또는 "Valkeakoski" |
| "Central Finland" | "Jämsä" (Jämsänkoski) |
| "North Karelia" (FI) | "Joensuu" |
| "Ostrobothnia" (FI) | "Pietarsaari" (Jakobstad) |
| "Satakunta" (FI) | "Rauma" or "Pori" |
| "Pirkanmaa" (FI) | "Tampere" |
| "Ayrshire" (UK) | "Irvine" (Caledonian) |
| "Minnesota" (US) | "Grand Rapids" (Blandin) |
| "Río Negro" (UY) | "Fray Bentos" |
| "Durazno" (UY) | "Paso de los Toros" |
| "Estonia" (EE) | "Otepää" |
| "Upper Austria" (AT) | "Steyrermühl" |
| "Brandenburg" (DE) | "Schwedt" (구 site, 매각됨) |

---

## 14. multi-region rollup split 후보 (#23)

- **UPM Kaukas** = paper mill + pulp mill + sawmill 3개 단위 → DB 1 row면 split 필요
- **UPM Kymi** = paper mill + pulp mill 2개 단위 → split 가능
- **UPM Plywood (FI 7 mill)** = 묶음 row면 개별 split

---

## 15. compound entity 정책 (#15)

후보:
- "UPM Finland Paper Mills" 같은 묶음 row → 5개 FI mill로 split
- "UPM Germany Paper Mills" 묶음 → Augsburg/Schongau/Nordland/Ettringen/Hürth/Plattling 분리
- "UPM Raflatac (multiple sites)" → 개별 site split

---

## 16. headquarters 정정 후보 (#33 일반화)

UPM HQ row 정정 후보 표기:
- `"Public — Nasdaq Helsinki listed"` (회사 성격 메모) → "Helsinki, Finland" 으로 정정
- `"Biofore — Beyond fossils"` (브랜드 슬로건) → 정정
- `"Founded 1995 from Kymmene + Repola merger"` (역사) → 정정

**권장 표기**: `"Helsinki, Finland"` (Biofore House)

---

## 17. evidence_level + source_url 추천

| 카테고리 | evidence | source_url 패턴 |
|---|---|---|
| Communication Papers 10 mill | **A** | `https://www.upmpaper.com/about-us/paper-mills-offices/upm-{mill}/` |
| UPM Fibres pulp 5 mill | **A** | https://www.upmpulp.com/ + EMAS report |
| Plywood 8 mill | **A** | UPM Plywood 공식 사이트 |
| Group HQ | **A** | https://www.upm.com/about-us/ |
| Closed mill (2020 Kaipola 등) | **A** | UPM 공식 announcement |
| Russia divested (2022) | **A** | UPM 2022 results |

EMAS Report 출처 (2024년 인증 mill):
- UPM Kaukas, UPM Kymi, UPM Nordland Papier, UPM Paso de los Toros, UPM Pietarsaari, UPM Rauma, UPM Schongau, UPM Tervasaari (8 EMAS-certified, 2024 기준)
- 제외: Caledonian (UK), Blandin (US) — EMAS 비대상

URL: https://www.upm.com/siteassets/reporting-hub/emas-reports/emas-corporate-report-2024---upm-paper-and-pulp-mills-english.pdf

---

## 18. 위험 / 주의 항목

1. **UPM 1995 vs 1996 형성**: 합병이 1995년 announce, 1996년 등록 완료 — DB 표기 일관성.
2. **Kaipola (FI) — 폐쇄 후 site 상태**: 2020 폐쇄. 일부 시설은 다른 용도 (Bioteollisuus) 전환 가능성. DB에 active로 남아있으면 closed 처리.
3. **Russia 자산 매각**: 2022년 Chudovo plywood 매각 완료. **Pestovo, Tchudovo 등 잔여 사이트 확인 필요**. DB에 active로 있으면 divested 처리.
4. **Communication Papers 10 mill list (2024-09 기준)**: Plattling/Hürth 제외됨 — 폐쇄 또는 분리. SQL 결과 확인 후 closed 라벨 추가.
5. **Ettringen closure**: 2025 발표했으나 법적 분쟁으로 지연. 2025-05 시점 상태는 still operating이나 곧 폐쇄 예정.
6. **UPM Lohja (Plywood)**: Sappi Lohja, Mondi Lohja 와는 별개. plywood mill — DB에 paper mill로 잘못 분류돼 있을 가능성 확인.
7. **Schwedt (DE)**: 2017년 LEIPA에 매각 → LEIPA family로 분기. UPM 산하 active로 있으면 잘못된 매핑.
8. **Shotton (UK)**: 2022년 DS Smith 매각 (현재 International Paper). UPM 산하 active로 있으면 잘못된 매핑.
9. **Madison (USA)**: 2017년 폐쇄. DB에 active로 있으면 closed 처리.
10. **UPM Fibres Uruguay**: 환경/사회 분쟁 보도 다수 (Extinction Rebellion 등 COP30 기간 시위). DB에는 영향 없지만 source_url 검증 시 균형 잡힌 기사 우선.

---

## 19. 누락 row INSERT 후보 (SQL 결과 받고 비교 필요)

```sql
-- Paso de los Toros (2023 startup)
INSERT INTO industry.paper_companies (name, market_code, tier_role, headquarters, evidence_level, source_url, main_product_category, main_products, notes)
VALUES
  ('UPM Paso de los Toros', 'uruguay', 'Country', 'Paso de los Toros, UY', 'A',
   'https://www.upm.com/businesses/upm-fibres/',
   'market_pulp', 'BHKP (eucalyptus, 2.1 Mt/y)',
   'Startup 2023-04, $3.47B investment. 세계 최대 단일 BHKP mill 중 하나.');

-- Leuna Biorefinery (2024 commissioning)
INSERT INTO industry.paper_companies (name, market_code, tier_role, headquarters, evidence_level, source_url, main_product_category, main_products, notes)
VALUES
  ('UPM Biochemicals Leuna', 'germany', 'Country', 'Leuna, Saxony-Anhalt, DE', 'A',
   'https://www.upmbiochemicals.com/',
   'biochemicals', 'BioMEG + lignin-based fillers',
   'Commissioning 2024-Q4, €750M, H2 2025 commercial. wood-based biochemicals.');
```

---

## 20. 출처

- https://en.wikipedia.org/wiki/UPM_(company) — corporate overview
- https://www.upmpaper.com/about-us/our-paper-mills — Communication Papers 10 mill 공식
- https://www.upm.com/siteassets/reporting-hub/emas-reports/emas-corporate-report-2024---upm-paper-and-pulp-mills-english.pdf — 2024 EMAS report
- https://www.upm.com/about-us/for-media/releases/2025/03/upm-communication-papers-plans-to-reduce-paper-capacity-in-germany-and-streamline-its-structure-to-ensure-performance/ — 2025-03 DE 구조조정
- UPM Annual Report 2024 (2026-03-04 공개): https://www.upm.com/investors/reports-and-presentations/
