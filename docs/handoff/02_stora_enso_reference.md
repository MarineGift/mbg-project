# Stora Enso family — Pre-research Reference

**작성일**: 2026-05-15  
**다음 세션 사용처**: handoff v5.7 권장 시나리오 C (Stora Enso 24 row 정리)

---

## 1. Group level (HQ tier)

| 항목 | 값 |
|---|---|
| 정식명 | **Stora Enso Oyj** |
| HQ | **이중 본사**: Helsinki, Finland + Stockholm, Sweden |
| 상장 | Nasdaq Helsinki (STERV) + Nasdaq Stockholm (STE A / STE R) |
| 형성 | 1998년 Stora AB (SE) + Enso Oyj (FI) 합병 |
| 역사 | Stora Kopparberg 1288년 주식증서 — 세계에서 가장 오래된 주식회사로 알려짐 |
| 직원 | ~20,000명 (2023) |
| CEO | Hans Sohlström (현직, Annica Bresky 후임) |

**DB 적용**:
- `paper_companies` HQ tier row 1개: name = "Stora Enso Oyj" 또는 "Stora Enso"
- `headquarters` = "Helsinki, Finland / Stockholm, Sweden" (이중 표기) — 또는 둘 중 우선
- `market_code` = `finland` 또는 `sweden` (DB convention 확인 필요; 일반적으로 등기 기준 → Finland)
- `tier_role` = `HQ`

**주의**: Sappi #33 패턴 — `headquarters`에 "Public — Nasdaq Helsinki/Stockholm" 같은 회사 성격 메모가 있으면 정정.

---

## 2. Business divisions (2025년 7월 재편 후)

2025년 7월 1일부로 **flatter structure**로 재편:

### Packaging 4 영역 (core business):
1. **Foodservice and Liquid Board** — paper cups, trays, aseptic milk/juice board (FI/SE/CN)
2. **Cartonboard** — premium fresh fibre packaging boards (food/cosmetic/pharma) (FI/SE)
3. **Containerboard** — virgin + recycled (FI/PL/BE)
4. **Packaging Solutions** — corrugated 박스, design/automation services

### 기타 divisions:
5. **Biomaterials** — specialty pulp (UKP, fluff pulp #1 Europe)
6. **Wood and Energy** — Wood Products (Europe 최대 sawn timber), Wood Supply, Energy
7. **Forest** — Swedish forest assets (전략 검토 중, 2025 분리/상장 가능성)

**DB 적용**: Regional tier가 segment-based이면 위 7개 division name이 후보. 또는 지리적 ("Stora Enso Europe", "Stora Enso Asia") 일 수도.

---

## 3. Regional / Sub-region tier 후보

| Regional 후보 | 영역 | 비고 |
|---|---|---|
| **Stora Enso Sweden** | 스웨덴 mills + forest | Skoghall, Skutskär, Fors, Hylte, Nymölla, Kvarnsveden (closed) |
| **Stora Enso Finland** | 핀란드 mills | Imatra, Oulu, Heinola, Varkaus, Anjala, Veitsiluoto (closed), Enocell, Joutseno |
| **Stora Enso Europe (continental)** | DE/PL/CZ/Baltic | Maxau, Kabel, Eilenburg, Ostrołęka, Mosina, Murów, Tychy, Łódź, Ždírec, Planá u ML, Imavere, Launkalne, Kaunas 등 |
| **Stora Enso China** | Beihai, Inpac 잔여 | Cartonboard 공급 |
| **Stora Enso South America** | Montes del Plata JV (UY) | 50% JV with Arauco (Chile) |
| **Stora Enso North America** | Mobile, Norfolk, Thurmont (US) | converting/packaging |

---

## 4. Mill 단위 — 활성 (확정)

### 🇫🇮 Finland mills

| Mill | 도시 | 주요 제품 | Notes |
|---|---|---|---|
| **Oulu Mill** | Oulu | virgin kraftliner + softwood pulp + **신규 consumer board line (€1B, 2025-03 startup)** | 통합 mill, 2026/27 full capacity |
| **Imatra Mills** | Imatra | consumer board + paper (~1 Mt/y) | 세계 최대 Consumer Board mill 중 하나 |
| **Heinola Fluting Mill** | Heinola | semi-chemical fluting (300kt/y) | 1961년 설립, ~190 employees |
| **Varkaus** | Varkaus | pulp, paper, LVL plywood | 통합 site |
| **Enocell (Uimaharju)** | Uimaharju | bleached softwood + hardwood pulp | 시장 펄프 |
| **Joutseno** | Joutseno | BSK pulp | |
| **Inkeroinen / Ingerois (Anjalankoski)** | Inkeroinen, Kouvola | board (Anjala와 인접) | |
| **Anjala Mill** | Anjalankoski | printing paper, mechanical pulp | **2022년 매각 announce 4-mill 중 하나** |

### 🇸🇪 Sweden mills

| Mill | 도시 | 주요 제품 | Notes |
|---|---|---|---|
| **Skoghall** | Skoghall (Hammarö) | consumer packaging board ~900kt | 신규 100kt 확장 (Valmet BM8 rebuild) |
| **Skutskär** | Skutskär (Älvkarleby) | bleached softwood + hardwood pulp, fluff pulp | |
| **Fors** | Fors (Avesta) | cartonboard (premium fresh fibre) | |
| **Hylte** | Hylte | newsprint, magazine paper | **2022년 매각 announce** |
| **Nymölla** | Nymölla (Bromölla) | UFP (woodfree office paper) | **2022년 매각 announce** |

### 🇩🇪 Germany mills

| Mill | 도시 | 주요 제품 | Notes |
|---|---|---|---|
| **Maxau** | Karlsruhe (Maxau) | SC paper, newsprint | **2022년 매각 announce** |
| **Kabel (Werk Kabel)** | Hagen | magazine paper, specialty | |
| **Eilenburg** | Eilenburg | newsprint (recycled) | |

### 🇵🇱 Poland mills

| Mill | 도시 | 주요 제품 | Notes |
|---|---|---|---|
| **Ostrołęka** | Ostrołęka | containerboard (recycled), corrugated | 폴란드 주력 |
| **Mosina** | Mosina | corrugated converting | |
| **Murów** | Murów | sawmill (wood products) | |
| **Tychy** | Tychy | corrugated | |
| **Łódź** | Łódź | corrugated | |

### 🇨🇿 Czech Republic mills

| Mill | 도시 | 주요 제품 | Notes |
|---|---|---|---|
| **Ždírec nad Doubravou** | Ždírec | wood products (sawmill) | |
| **Planá u Mariánských Lázní** | Planá u ML | corrugated | |

### 🇪🇪🇱🇻🇱🇹 Baltic states

| Mill | 도시 / 국가 | 주요 제품 |
|---|---|---|
| **Imavere** | Imavere, EE | sawmill |
| **Tänassilma** | Tänassilma, EE | wood/packaging |
| **Launkalne** | Launkalne, LV | sawmill |
| **Rīga** | Rīga, LV | wood / corrugated |
| **Kaunas** | Kaunas, LT | corrugated |

### 🇧🇪 Belgium

| Mill | 도시 | 주요 제품 |
|---|---|---|
| **Langerbrugge** (확인 필요) | Ghent | recycled containerboard / newsprint |

### 🇦🇹 Austria

| Mill | 도시 | 주요 제품 |
|---|---|---|
| **Ybbs an der Donau** | Ybbs | wood products / packaging |

### 🇮🇹 Italy

| Mill | 도시 | 주요 제품 |
|---|---|---|
| **Vimodrone** | Vimodrone (Milan) | packaging |

### 🇺🇸 USA

| Mill | 도시 | 주요 제품 |
|---|---|---|
| **Mobile** | Mobile, AL | packaging |
| **Norfolk** | Norfolk, VA | packaging |
| **Thurmont** | Thurmont, MD | packaging |

### 🇨🇳🇺🇾 기타

| Mill / Site | 위치 | 주요 제품 |
|---|---|---|
| **Beihai Mill** | Beihai, Guangxi, CN | consumer board (BHKP integrated) |
| **Montes del Plata** | Punta Pereira, UY | BHKP market pulp (~1.3 Mt) | **50% JV with Arauco** |

---

## 5. CLOSED / DIVESTED mills (DB 정리 시 라벨 필요)

| Mill | 국가 | 상태 | 시점 |
|---|---|---|---|
| **Veitsiluoto Mill** | Kemi, FI | **CLOSED** | Q3 2021 (paper + UFP), pulp mill (360kt) integrated — 영구 폐쇄. ~440 직원 |
| **Kvarnsveden Mill** | Borlänge, SE | **CLOSED** | Q3 2021 (newsprint/SC paper), ~440 직원 |
| **Kemijärvi Mill** | Kemijärvi, FI | **CLOSED** | 2008 (pulp) |
| **Baienfurt Mill** | Baienfurt, DE | **CLOSED** | 2008 (cartonboard) |
| **Summa Mill** | Hamina, FI | **CLOSED** | ~2008 |
| **Anjala, Hylte, Nymölla, Maxau** | FI/SE/SE/DE | **SALE ANNOUNCED 2022-03** | 매각 진행 중 (매수자 못 찾으면 운영 지속) |
| **North American operations** | USA/Canada | **DIVESTED** | 2007 (NewPage Corporation 매각) |
| **Bulleh Shah Packaging** | Kasur, PK | **DIVESTED** | 2017 (Packages Ltd.로 35% 매각) |
| **Russia operations (Sveza JV 등)** | Russia | **DIVESTED** | 2022 (Russia 사업 모두 매각) |

---

## 6. 최근 5년 corporate events

| 날짜 | 이벤트 |
|---|---|
| 2021 Q3 | **Veitsiluoto + Kvarnsveden 영구 폐쇄** (~1,110 직원) |
| 2022 Mar | 4 mill 매각 announce: Anjala / Hylte / Nymölla / Maxau |
| 2022 | Russia 사업 매각 |
| 2024 Mar/Apr | 핀란드 항구 파업 — Imatra/Oulu 일시 idle |
| 2024 Oct | **Junnikkala Oy (FI sawmill) 인수 announce** |
| 2025 Mar | **Oulu 신규 €1B consumer packaging board line startup** (full capacity 2027) |
| 2025 Q2 | **Junnikkala 인수 완료** + Swedish forest 12.4% 매각 (€900M, EQT/HEIF 등 buyer) |
| 2025 Jul | **조직 재편**: packaging 4 영역으로 분할 (Foodservice/Liquid Board, Cartonboard, Containerboard, Packaging Solutions) |
| 2025 | Swedish forest 전략 검토 (분리/상장 가능성) |

---

## 7. tier_role 매핑 sketch (24 row → tier 분포 예상)

24 row 분포 추정:
- **HQ × 1**: Stora Enso Oyj
- **Regional × 3-5**: Stora Enso Sweden / Finland / Continental Europe / 등
- **Country × 15-18**: 위 §4 각 mill의 운영 법인
- **NULL / Sector × 2-3**: closed mill placeholder, 분류 미상

**Country tier 운영 법인 후보**:
- Stora Enso Oulu Oy (FI)
- Stora Enso Imatra Mills Oy (FI)
- Stora Enso Skoghall AB (SE)
- Stora Enso Skutskär AB (SE)
- Stora Enso Fors AB (SE)
- Stora Enso Hylte AB (SE)
- Stora Enso Nymölla AB (SE)
- Stora Enso Maxau GmbH (DE)
- Stora Enso Kabel GmbH (DE)
- Stora Enso Eilenburg GmbH (DE)
- Stora Enso Poland Sp. z o.o. / Ostrołęka 법인 (PL)
- Stora Enso Wood Products (multi)
- Sunila Oy 등 자회사

---

## 8. mill_name 정규화 후보 (#20)

| 가능한 광역 표기 | 정규화 후 |
|---|---|
| "North Ostrobothnia" | "Oulu" |
| "South Karelia" | "Imatra" 또는 "Joutseno" |
| "Päijät-Häme" | "Heinola" 또는 "Lahti" |
| "North Savonia" | "Varkaus" |
| "North Karelia" | "Uimaharju" (Enocell) |
| "Kymenlaakso" | "Anjalankoski" 또는 "Inkeroinen" |
| "Lapland" | "Veitsiluoto" 또는 "Kemijärvi" |
| "Värmland County" | "Skoghall" |
| "Uppsala County" | "Skutskär" |
| "Dalarna" | "Kvarnsveden" |
| "Scania" | "Nymölla" |
| "Hallands" | "Hylte" |
| "Saxony-Anhalt" | "Eilenburg" |
| "Baden-Württemberg" | "Maxau" (or "Karlsruhe") |
| "Masovian / Mazowieckie" | "Ostrołęka" |

---

## 9. multi-region rollup split 후보 (#23)

- **Anjalankoski Mills** = Anjala paper + Ingerois board → 2 개로 split 가능
- **Imatra Mills** = Tainionkoski + Kaukopää 2개 sub-site → DB row 1개면 split 검토
- **Varkaus** = pulp + paper + LVL → 1 row면 split 검토
- **Imavere/Launkalne/Tänassilma** = Baltic sawmills 묶음 → 개별 split 권장

---

## 10. compound entity 정책 (#15)

후보:
- "Stora Enso Wood Products (multiple sites)" 묶음 row → 개별 mill로 split
- "Stora Enso Packaging Solutions (Polish 5 plants)" 묶음 row → 개별 split
- "Stora Enso Finland Paper Mills" 같은 묶음 → 개별 split

---

## 11. headquarters 정정 후보 (#33 일반화)

Stora Enso는 dual HQ:
- 권장 표기: `"Helsinki, Finland / Stockholm, Sweden"` (이중)
- 또는: `"Helsinki, Finland"` (등기 기준, Oyj = 핀란드 법인)
- 잘못된 가능 표기: `"Public — Nasdaq listed"`, `"Founded 1998 from Stora + Enso merger"` (회사 성격/역사 메모)

---

## 12. evidence_level + source_url 추천

| 카테고리 | evidence | source_url 패턴 |
|---|---|---|
| 활성 mill (회사 site location 페이지 있음) | **A** | `https://www.storaenso.com/en/about-stora-enso/stora-enso-locations/{slug}-mill` |
| Group HQ | **A** | https://www.storaenso.com/en/about-stora-enso |
| Closed mill (2021 Veitsiluoto/Kvarnsveden) | **A** | 회사 공식 closure announcement |
| 매각 announce (4-mill, 2022) | **A** | 회사 공식 announcement |
| 역사적 closure (Kemijärvi 2008 등) | **B** | Wikipedia + 뉴스 |

---

## 13. 위험 / 주의 항목

1. **Veitsiluoto와 Kemi 혼동**: Veitsiluoto Mill은 Kemi 시에 위치. mill_name이 "Kemi"로 들어있을 수 있음 → Metsä Group의 Metsä Fibre Kemi mill과 동일 도시이므로 혼동 주의 (둘 다 Kemi에 있음).
2. **Anjalankoski multi-mill**: Anjala (paper) + Ingerois (board) 두 mill이 인접 사이트. DB row 1개면 split 후보.
3. **Hylte/Nymölla/Anjala/Maxau 매각 status**: 2022년 announce 이후 진척 확인 필요. 2025년 5월 현재 매수자 확정/미확정 여부 DB 시점 기준 결정.
4. **Junnikkala Oy**: 2025년 Q2 인수 완료. Finnish sawmill — DB에 미반영 가능성. 신규 row INSERT 후보.
5. **Forest 분리 가능성**: 2025년 forest 전략 검토 — 분리/상장 시 별도 family로 분기 가능.
6. **Inpac (China)**: 30% stake 2010년 매입, 현재 status 불명확.
7. **Pakistan Bulleh Shah JV**: 2017년 매각 완료 → DB에 active로 남아있으면 제거.
8. **Lohja**: Lohja에 Sappi Kirkniemi mill이 있지만 Stora Enso는 Lohja에 mill 없음. 혼동 주의.

---

## 14. 누락 row INSERT 후보 (SQL 결과 받고 비교 필요)

```sql
-- Junnikkala (2025 Q2 인수)
INSERT INTO industry.paper_companies (name, market_code, tier_role, headquarters, evidence_level, source_url, main_product_category, main_products, notes)
VALUES
  ('Junnikkala Oy (Stora Enso)', 'finland', 'Country', 'Kalajoki, FI', 'A',
   'https://www.storaenso.com/en/newsroom/regulatory-and-investor-releases/2025/',
   'wood_products', 'Sawn timber',
   'Acquired 2025-Q2. Finnish sawmill company.');

-- Beihai (China consumer board)
INSERT INTO industry.paper_companies (name, market_code, tier_role, headquarters, evidence_level, source_url, main_product_category, main_products, notes)
VALUES
  ('Stora Enso Beihai Mill', 'china', 'Country', 'Beihai, Guangxi, CN', 'A',
   'https://www.storaenso.com/en/about-stora-enso/stora-enso-locations',
   'consumer_board', 'BHKP integrated consumer board',
   'Asia-Pacific main consumer board site.');
```

---

## 15. SQL 결과 받기 전 매핑 우선순위

다음 세션 즉시 적용 가능한 순서:

1. **HQ row**: name LIKE 'Stora Enso%' AND market_code IN ('finland','sweden') → tier_role='HQ'
2. **Regional rows**: name LIKE 'Stora Enso %' AND name 안에 country/region 단어 → 'Regional'  
   (e.g. "Stora Enso Sweden", "Stora Enso Continental Europe")
3. **Country rows**: 개별 mill 운영 법인 → 'Country'
4. **Closed mills**: 별도 status 컬럼 or notes에 closure date 기재
5. **mill_name 정규화** (#20): §8 적용
6. **multi-region split** (#23): §9 적용
7. **evidence_level 'A' 일괄**: 회사 site에 location 페이지 있는 mill 전부

---

## 16. 출처

- https://www.storaenso.com/en/about-stora-enso/stora-enso-locations — 공식 location 목록 (37+ sites)
- https://www.storaenso.com/en/about-stora-enso/our-divisions — 7개 division 구조 (2025-07 재편)
- https://en.wikipedia.org/wiki/Stora_Enso — corporate history (Tier 2)
- https://www.storaenso.com/-/media/documents/download-center/documents/interim-reports/2025/storaenso_results_q225_eng.pdf — Q2 2025 report
- https://www.storaenso.com/en/newsroom/regulatory-and-investor-releases/2021/4/stora-enso-initiates-a-plan-to-permanently-close-down-pulp-and-paper-production-at-kvarnsveden-and-veitsiluoto-mills — 2021 closure announcement
