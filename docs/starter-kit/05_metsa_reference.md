# Metsä Group family — Pre-research Reference

**작성일**: 2026-05-15  
**다음 세션 사용처**: handoff v5.7 권장 시나리오 D (Metsä 8 row 정리)

---

## 1. Group level (HQ tier)

| 항목 | 값 |
|---|---|
| 정식명 | **Metsäliitto Cooperative** (parent) — 영업명 **Metsä Group** |
| 형태 | **협동조합 (Cooperative)** — Finnish private forest owners 약 **90,000-103,000명**이 소유 |
| HQ | **Espoo, Finland** (헬싱키 인근) |
| 상장 | **Metsäliitto Cooperative는 비상장** — 단 산하 **Metsä Board Oyj는 Nasdaq Helsinki 상장** |
| 매출 (2021) | EUR 6.0B / 직원 ~9,500-11,500명 |
| 활동 국가 | ~30 |

**DB 적용**:
- `paper_companies` HQ tier row: name = "Metsä Group" or "Metsäliitto Cooperative"
- `headquarters` = "Espoo, Finland"
- `market_code` = `finland`
- `tier_role` = `HQ`

**주의**: 협동조합 구조라 일반 corporation과 다름. `notes`에 "Cooperative ownership — 90k+ Finnish forest owner members" 기재 권장.

---

## 2. Business structure (5+ business areas)

| Business Area | 영역 | 본부 | Type |
|---|---|---|---|
| **Metsä Forest** | 임업, 목재 procurement | 핀란드 | Metsäliitto Cooperative 직속 |
| **Metsä Wood** | wood products, plywood, LVL (Kerto), sawn timber | 핀란드 | Metsäliitto Cooperative 직속 |
| **Metsä Fibre** | pulp + sawn timber + biochemicals + bioenergy | 핀란드 | 자회사 (Cooperative 다수 지분) |
| **Metsä Board (Oyj)** | premium fresh fibre paperboard | 핀란드 | **자회사, Nasdaq Helsinki 상장** |
| **Metsä Tissue** | tissue, cooking papers, hygiene | 핀란드 | 자회사 |
| **Metsä Spring** | 혁신/innovation (textile, packaging 신소재) | 핀란드 | 자회사 (R&D / start-up unit) |

**브랜드**: Lambi, Serla, Mola, Tento, Katrin (B2B), Saga (tissue/cooking)

---

## 3. Regional tier 후보 (Metsä Group → 산하 6개 BA)

DB 8 row에서 Regional tier는 위 6 BA가 후보 (5-6 row 가능):
- **Metsä Board** → name = "Metsä Board Oyj" (가장 유력한 자회사 row)
- **Metsä Fibre**
- **Metsä Tissue**
- **Metsä Wood**
- **Metsä Forest**
- **Metsä Spring** (작아서 별도 row가 없을 수도 있음)

---

## 4. Mill 단위 — 핵심 site

### Metsä Fibre (pulp 강자)

| Mill | 도시 | 국가 | 용량 / Type | Notes |
|---|---|---|---|---|
| **Äänekoski Bioproduct Mill** | Äänekoski | FI | 1.3 Mt BSK/BHKP/y | **2017 startup, €1.2B** — Nordic 최대 단일 bioproduct mill, 2.4 TWh 전력 |
| **Kemi Bioproduct Mill** | Kemi | FI | 1.5 Mt | **2023-09 startup, €2.0B 새 mill** — 세계 최대 단일 BSK mill (replaced old Kemi mill) |
| **Joutseno** | Joutseno (Lappeenranta) | FI | ~700kt BSK | (Stora Enso Joutseno와 별개 ← Metsä가 운영) |
| **Rauma** | Rauma | FI | ~700kt BSK | (UPM Rauma paper mill과 같은 도시지만 별도) |
| **Kemi Sawmill** | Kemi | FI | sawn timber | bioproduct mill과 통합 |

### Metsä Board (paperboard)

| Mill | 도시 | 국가 | 주요 제품 | Notes |
|---|---|---|---|---|
| **Husum Mill** | Husum (Örnsköldsvik) | SE | folding boxboard (FBB) + white kraftliner + market pulp | 통합 mill, 큰 사이트 |
| **Kyröskoski (Kyro)** | Kyröskoski (Hämeenkyrö) | FI | folding boxboard (FBB) | |
| **Simpele** | Rautjärvi | FI | folding boxboard | **2025년 renewal 완료** |
| **Tako** | Tampere | FI | linerboard, premium board | |
| **Joutseno Board Mill** | Joutseno | FI | (Fibre pulp mill과 동거) | |

### Metsä Tissue

| Mill | 도시 | 국가 | 용량 / 제품 | Notes |
|---|---|---|---|---|
| **Mariestad Tissue Mill** | Mariestad | SE | 77kt → **145kt (확장 완료 2025)**, €230M 투자 | 1765년 설립 (Anders Rodin) |
| **Pauliström + Nyboholm (Småland mills)** | Pauliström / Nyboholm | SE | tissue | Pauliström 1726년 설립 (구 iron mill) |
| **Katrinefors** | Mariestad area | SE | tissue | |
| **Žilina Mill** | Žilina | SK | 80kt tissue (2 PM + 6 processing lines) | 1905년 설립 (구 pulp/synthetic fibre), 1983년부터 tissue 전용 |
| **Krapkowice** | Krapkowice | PL | tissue (Tento, Lambi 브랜드) | |
| **Düren Mill** | Düren | DE | SAGA cooking paper (biodegradable greaseproof) | 1857 설립 (Reflex Feinpapiere), Metsä 2010 인수 |
| **Mänttä Mill** | Mänttä | FI | tissue + cooking paper | Finnish tissue 핵심 |
| **Stotzheim** | Stotzheim | DE | tissue (예상 확인 필요) | |
| **Russia (구 Metsä Tissue Russia)** | (구 Naro-Fominsk 등) | **DIVESTED 2022** (Russia 시장 철수) | |

### Metsä Wood

| Mill / Plant | 도시 | 국가 | 제품 |
|---|---|---|---|
| **Punkaharju** | Punkaharju | FI | Kerto LVL, plywood |
| **Lohja** | Lohja | FI | Kerto LVL (Sappi/Mondi Lohja와 별개 — wood products) |
| **Äänekoski Kerto LVL** | Äänekoski | FI | **신규 Kerto LVL mill 건설 중 (2025+)** |
| **Suolahti** | Suolahti | FI | plywood |
| **Pärnu** | Pärnu | EE | sawmill / plywood |
| **King's Lynn** | King's Lynn | UK | engineered wood |
| **Boston** | Boston | UK | engineered wood |
| **Eskilstuna** | Eskilstuna | SE | engineered wood |

---

## 5. CLOSED / DIVESTED mills (정리 필수)

| Mill | 국가 | 상태 | 시점 |
|---|---|---|---|
| **Old Kemi pulp mill** | Kemi, FI | **REPLACED 2023-09** by new Bioproduct Mill | 구 mill 폐쇄 후 신규 가동 |
| **Russia tissue ops** | Russia | **DIVESTED** | 2022 |
| **Kaskinen pulp mill** | Kaskinen, FI | **CLOSED** | 2009 (M-real 시절) |
| **Sittingbourne (UK)** | Sittingbourne, Kent, UK | **DIVESTED** | 2010 (전 M-real) |
| **Husum Mill 일부 PM** | Husum, SE | partial closure | (UFP → 전 segment 매각, 2017년 Metsä Board 매각) |

**M-real 역사**: Metsä Group의 paper 부문 (구 M-real)이 2017년경 UFP 사업을 매각 (Sappi 등) → Metsä Board는 paperboard 전용 회사로 전환. **이 점이 DB에 영향**: 구 M-real mill이 Metsä family에 남아있으면 매각 처리 필요.

---

## 6. 최근 5년 corporate events

| 날짜 | 이벤트 |
|---|---|
| 2017 | Äänekoski Bioproduct Mill startup (€1.2B) |
| 2017 | M-real UFP 사업 매각 → Metsä Board는 paperboard 전용 |
| 2022 | Russia tissue 사업 매각 |
| 2023-09 | **Kemi Bioproduct Mill startup** (€2.0B, 세계 최대 BSK mill) |
| 2023 | Mariestad tissue 확장 시작 |
| 2025 | **Mariestad 확장 완료** (77 → 145kt) |
| 2025 | **Simpele paperboard mill renewal 완료** |
| 2025+ | **Äänekoski Kerto LVL** 신규 mill 건설 중 |

---

## 7. tier_role 매핑 sketch (8 row → tier 분포)

8 row의 작은 슬라이스. 가능한 분포:
- **HQ × 1**: Metsä Group / Metsäliitto Cooperative
- **Regional × 4-5**: Metsä Board / Metsä Fibre / Metsä Tissue / Metsä Wood / Metsä Forest
- **Country × 2-3**: 특정 mill operating 법인 (e.g. Metsä Tissue Slovakia s.r.o.)
- **NULL × 0-1**: closed mill placeholder

(8 row는 너무 작아서 각 BA가 Country tier로 간주됐을 가능성도 있음)

---

## 8. mill_name 정규화 후보 (#20)

| 가능한 광역 표기 | 정규화 후 |
|---|---|
| "Central Finland" | "Äänekoski" |
| "Lapland" | "Kemi" |
| "Pirkanmaa" | "Tampere" (Tako) 또는 "Kyröskoski" |
| "South Karelia" | "Joutseno" or "Simpele" |
| "Satakunta" | "Rauma" |
| "Västernorrland County" (SE) | "Husum" or "Örnsköldsvik" |
| "Västra Götaland" (SE) | "Mariestad" |
| "Žilina Region" (SK) | "Žilina" |
| "North Rhine-Westphalia" (DE) | "Düren" |

---

## 9. multi-region rollup split 후보 (#23)

- **Pauliström + Nyboholm = "Småland mills"** 묶음 → 둘로 split
- **Mariestad + Katrinefors** = 같은 도시 area → 별도 mill로 split

---

## 10. 위험 / 주의 항목

1. **Metsä Board Oyj는 별도 상장**: Metsäliitto Cooperative가 majority shareholder이지만 publicly traded 회사. DB의 ownership 표기 일관성.
2. **M-real legacy**: 2017년 사업 재편으로 Metsä Board가 paperboard 전용. 구 M-real UFP mill이 family에 남아있으면 분리 (Sappi 등 매수자에게 이전).
3. **Kemi multiple operations**: Metsä Fibre Kemi Bioproduct Mill + Stora Enso Veitsiluoto (Kemi 시 소재) 둘 다 있음 — 회사 이름으로 구분.
4. **Lohja**: Metsä Wood Lohja (LVL) ≠ Sappi/Mondi Lohja (paper). 회사 이름 확인 필수.
5. **Joutseno**: Metsä Fibre Joutseno (pulp) + Stora Enso Joutseno (pulp) 둘 다 있음 — 회사 이름 확인 필수.
6. **Mariestad 확장**: 2025년 완료 — 용량 표기 77kt에서 145kt로 업데이트.
7. **Russia (구 Naro-Fominsk tissue)**: 2022 매각 — DB에 active로 있으면 divested 라벨.

---

## 11. evidence_level + source_url 추천

| 카테고리 | evidence | source_url |
|---|---|---|
| HQ Group | **A** | https://www.metsagroup.com/metsa-group/about-us/ |
| Metsä Fibre mills | **A** | https://www.metsagroup.com/metsafibre/ |
| Metsä Board mills | **A** | https://www.metsagroup.com/metsaboard/ |
| Metsä Tissue mills | **A** | https://www.metsagroup.com/metsatissue/ |
| Metsä Wood plants | **A** | https://www.metsagroup.com/metsawood/ |

---

## 12. 출처

- https://en.wikipedia.org/wiki/Mets%C3%A4_Group — overview
- https://www.metsagroup.com/metsa-group/about-us/business-structure/ — 공식 구조
- https://www.metsagroup.com/globalassets/metsa-group/documents/investors/financial-reporting/annual-reports/2025/metsa-group-annual-review-2025.pdf — 2025 Annual Review
- https://www.pulpapernews.com/20251107/17167/finnish-bioeconomy-hub-grows-around-metsa-fibres-flagship-mill — Äänekoski overview 2025
