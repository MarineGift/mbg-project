# Oji Holdings Corporation — Family Reference

**작성일**: 2026-05-15  
**용도**: paper_companies / paper_mills 에서 Oji Holdings family rows 정리 가이드  
**참조 핸드오프**: handoff_v5_7.md #15 #20 #23 #33 #42

---

## 1. 그룹 정보

| 항목 | 값 |
|---|---|
| 법인명 | Oji Holdings Corporation (王子ホールディングス株式会社) |
| HQ | Chuo-ku, Tokyo, Japan |
| 설립 | 1873-02-12 (Shoshi Kaisha; Eiichi Shibusawa 설립) |
| 상장 | Tokyo Stock Exchange (티커 3861), Nikkei 225 구성종목 |
| 그룹 매출 (FY2023, JPY) | ~1.6T (USD ~11B) |
| 산업 지위 | 세계 3위 paper 회사 (2012 기준), Asia 최대 |
| 일본 내 생산 사이트 | **99 sites** (2025-06 기준) |
| 해외 운영 | Australia, Brazil, Canada, China, Germany, NZ, Malaysia, Vietnam, India 등 |
| 산림 자산 | 약 **636,000 ha** (2025-03 기준) |
| 직원 | ~37,000+ |

---

## 2. Business segments (Oji는 5개 핵심 사업)

### A. Industrial Materials Business (산업 자재)
- Containerboard + corrugated containers
- Kraftliner / packaging paper
- **자회사**: Oji Container Co., Ltd. (corrugated 최대 자회사)

### B. Functional Materials Business
- Specialty paper, thermal paper, release paper
- **자회사**: Oji F-Tex (Specialty Paper), Kanzaki Paper

### C. Forest Resources & Environment Marketing
- Pulp (시장 펄프)
- Forest plantations (호주, 브라질, NZ, 베트남 등)
- Bio-energy

### D. Printing & Communications Media
- Newsprint, printing paper, fine paper
- **자회사**: Oji Paper Co., Ltd. (지주회사 전환 후 별도 법인)

### E. Household & Industrial Materials
- Tissue paper (Nepia 브랜드 — 일본 가정용 tissue 1위)
- Sanitary products
- **자회사**: Oji Nepia

### F. Paperboard / Materia
- White paperboard, folding boxboard
- **자회사**: Oji Materia (구 Oji Paper Board, 2002 통합)

### 신규 사업
- **Oji Pharma** (2020 신설) — 목재 기반 의약 원료
- **Walki Holding Oy** (2024-04 인수, 핀란드) — sustainable packaging

---

## 3. Regional tier 후보

Oji는 **다국적 운영 강도가 매우 높음** (Mondi/IP 수준). 다단 tier 구조:

```sql
🟣 HQ: Oji Holdings Corporation              → 'Tokyo, Japan'
🟣 HQ-sub: Oji Paper Co., Ltd.               → 'Tokyo, Japan' (지주 산하 paper 법인)

🔵 Regional: Oji Fibre Solutions (NZ + AU)   → 'australia' or 'new_zealand'
🔵 Regional: Oji Paper Asia                  → 'malaysia' or 'asia_composite'
🔵 Regional: Oji Europe / Walki              → 'finland' or 'europe_composite'
🔵 Regional: CENIBRA (Brazil)                → 'brazil'

🟢 Country:
  - PT Korintiga Hutani (KTH)                → 'indonesia'
  - GSPP Holdings                            → 'malaysia'
  - Jiangsu Oji Paper (Nantong)              → 'china'
  - Quy Nhon Plantation Forest Co (QPFL)     → 'vietnam'
  - Albany Plantation Forest Co (APFL)       → 'australia'
  - Pan Pac Forest Products                  → 'new_zealand'
  - JANT PTY LTD (PNG, 2004 철수)            → 'papua_new_guinea' (status: closed)
  - Oji Paper Thailand                       → 'thailand' (있을 경우)
  - Walki                                    → 'finland'
```

---

## 4. 주요 활성 Mill 목록

> Oji는 일본에 99개 생산 사이트가 있어 **모두 나열은 불가능**. 핵심 mill만:

### 4.1 일본 — Key Paper Mills

| Mill | 위치 | 종류 | 비고 |
|---|---|---|---|
| **Tomakomai Mill** | Tomakomai, Hokkaido | Newsprint, 다양 | 1910 가동. 동아시아 최초 대형 paper mill. 일본 newsprint 자급의 시발점 |
| **Kasugai Mill** | Kasugai, Aichi | Woodfree paper | 1952 가동. 일본 최초 continuous evaporation hardwood pulp 성공 (1953) |
| **Kushiro Mill** | Kushiro, Hokkaido | Containerboard | 1959 가동 (former Honshu Paper) |
| **Tomioka Mill** | Tomioka, Gunma | Coated paper | (former Kanzaki Paper) |
| **Ebetsu Mill** | Ebetsu, Hokkaido | Fine paper | 1970 Kita Nihon Paper 합병 |
| **Yonago Mill** | Yonago, Tottori | Pulp + paper | 2000 세계 최초 enzymatic bleaching 가동 |
| **Kure Mill** (Oji Materia) | Kure, Hiroshima | White paperboard | Materia 자회사 운영 |
| **Chitose Mill** | Chitose, Hokkaido | 다양 | (구 Hokkaido 권역) |
| **다수 Oji Container plants** | 일본 전국 | Corrugated converting | 다수 |

### 4.2 중국

| Mill | 위치 | 비고 |
|---|---|---|
| **Jiangsu Oji Paper Nantong** | Nantong, Jiangsu | 2010 가동, paper + pulp |
| 기타 packaging plants | 다수 도시 | |

### 4.3 남미

| Mill | 위치 | 비고 |
|---|---|---|
| **CENIBRA** (Celulose Nipo-Brasileira) | Belo Oriente, Minas Gerais, Brazil | Pulp mill. 1973 Oji + JBP + Brazilian partners 설립. 약 1.2Mt BEK |

### 4.4 NZ + Australia (Oji Fibre Solutions)

| Mill | 위치 | 비고 |
|---|---|---|
| **Kinleith Mill** | Tokoroa, NZ (north of Tokoroa) | Pulp + paper. **2025-06 paper 생산 중단** (펄프만 유지, 230명 영향) |
| **Auckland mill** | Auckland, NZ | **2024-12 폐쇄** (recycled paper) |
| **Pan Pac Forest Products** | Hawke's Bay, NZ | Forestry + mechanical pulp |
| **Albany Plantation Forest Co (APFL)** | Western Australia | Forestry only |

### 4.5 동남아시아

| Mill | 위치 | 비고 |
|---|---|---|
| **GSPP Holdings** | Malaysia | 2010 인수 |
| **Banting Mill** (Malaysia) | Banting, Selangor | Paper. 2024-말 NZ recycled paper 처리 이관 받음 |
| **PT Korintiga Hutani** | Indonesia (Central Kalimantan) | Forestry |
| **QPFL** (Quy Nhon Plantation Forest) | Vietnam | Forestry. 1994 설립 |
| **Oji Paper Vietnam (Saigon)** | Vietnam | Paper |

### 4.6 유럽 (2024 신규)

| Mill | 위치 | 비고 |
|---|---|---|
| **Walki Holding Oy** | Valkeakoski, Finland (HQ) | 2024-04 인수. Specialty/sustainable packaging |
| Walki plants | 다수 유럽 국가 | |

---

## 5. 폐쇄/매각된 자산

| Mill | 일자 | 조치 |
|---|---|---|
| **JANT PTY LTD** (Papua New Guinea) | 2004 | 사업 철수 |
| **Auckland mill** (NZ) | 2024-12 | Oji Fibre Solutions 영구 폐쇄 (recycled paper recycling) |
| **Kinleith paper machine** (NZ) | 2025-06 | paper 생산 중단 (pulp만 유지). 230명 해고 |
| Various 일본 mill 축소 | 2020-2024 | newsprint 수요 감소 대응 |

---

## 6. 5-Year Corporate Events 타임라인

| 일자 | 이벤트 |
|---|---|
| 2010 | PT Korintiga Hutani (Indonesia) Oji 그룹 진입. GSPP Holdings (Malaysia) 인수. Jiangsu Oji Paper Nantong Mill 가동 |
| 2012 | **지주회사 체제 전환** — Oji Holdings 신설. Oji Paper Co. 별도 법인화 |
| 2020 | Oji Pharma 설립 (목재 의약 원료) |
| 2024-04 | **Walki Holding Oy 인수** (Finland) — sustainable packaging 강화 |
| 2024-09 | Oji Fibre Solutions, Auckland mill 폐쇄 발표 |
| 2024-11 | Kinleith Mill paper machine 중단 제안 발표 |
| 2024-12 | Auckland mill 폐쇄 완료 |
| 2025-02 | Kinleith paper machine 중단 확정 (2025-06 완료, 230명) |
| 2025-06 | Kinleith pulp만 운영 지속 |
| 2025 | 산림 자산 636,000 ha 보유 보고 |

---

## 7. tier_role 매핑 가이드

```sql
-- HQ tier
🟣 Oji Holdings Corporation             → 'Tokyo, Japan'

-- HQ-sub (지주회사 산하 사업 법인) — Country tier로 매핑 가능
🟢 Oji Paper Co., Ltd.                  → 'japan' (newsprint, fine paper)
🟢 Oji Materia Co., Ltd.                → 'japan' (paperboard)
🟢 Oji F-Tex Co., Ltd.                  → 'japan' (specialty)
🟢 Oji Nepia Co., Ltd.                  → 'japan' (tissue)
🟢 Oji Container Co., Ltd.              → 'japan' (corrugated)

-- Regional tier
🔵 Oji Fibre Solutions                  → 'new_zealand' or 'oceania_composite'
🔵 Oji Asia                             → 'asia_composite'
🔵 Walki Holding Oy                     → 'finland' (or 'europe_composite')
🔵 CENIBRA                              → 'brazil'

-- Country tier
🟢 Jiangsu Oji Paper (Nantong)          → 'china'
🟢 GSPP Holdings                        → 'malaysia'
🟢 PT Korintiga Hutani                  → 'indonesia'
🟢 QPFL                                 → 'vietnam'
🟢 APFL                                 → 'australia'
🟢 Pan Pac Forest Products              → 'new_zealand'
```

---

## 8. mill_name 정규화 후보 (#20)

| 잘못된 패턴 (의심) | 정규화 권장 |
|---|---|
| `"Hokkaido"` (광역도) | `"Tomakomai"` / `"Kushiro"` / `"Ebetsu"` / `"Chitose"` 분리 (4개+ mill) |
| `"Japan"` (단일 국가 수준) | 99개 사이트라 city 단위로 분리 필요 |
| `"NZ Operations"` | `"Kinleith (Tokoroa)"` / `"Auckland (폐쇄)"` / `"Pan Pac (Hawke's Bay)"` 분리 |
| `"Walki Europe"` | Walki 각 plant city 분리 (Finland 외 다국 운영) |
| `"China Operations"` | `"Nantong (Jiangsu)"` 명시 |

---

## 9. multi-region rollup split 후보 (#23)

| 의심 row | 권장 분할 |
|---|---|
| `"Oji Holdings (global)"` | HQ + 5+ regional 분리 |
| `"Oji Group Japan"` | 5개 사업 법인 (Paper / Materia / F-Tex / Nepia / Container) 분리 |
| `"Oji Fibre Solutions"` (NZ+AU) | NZ Country + AU Forestry 분리 |
| `"Oji Asia"` | China + Malaysia + Indonesia + Vietnam + Thailand 개별 |

---

## 10. compound entity 정책 (#15)

| 의심 라벨 | 정책 |
|---|---|
| `"Oji / Honshu / Jujo"` | **Oji 단일** — Honshu (1996 합병으로 소멸), Jujo (1949 분리 후 다른 경로, 현 Nippon Paper) |
| `"Oji / Walki"` | Walki는 Oji 자회사 (2024-04~). 분리 row 가능하지만 family는 Oji |
| `"Oji / CENIBRA"` | CENIBRA는 Oji JV (Brazilian partners와). family는 Oji, Regional row로 분리 |
| `"Oji / Kanzaki"` | Kanzaki는 1993 합병 (New Oji Paper). 별도 family 아님 |

---

## 11. headquarters 정정 후보 (#33)

| 의심 패턴 | 정정 |
|---|---|
| `"TSE-listed"` / `"Nikkei 225"` | `"Tokyo, Japan"` |
| `"Tomakomai-headquartered"` (mill을 HQ로) | `"Tokyo, Japan"` |
| `"Asia's largest paper company"` | `"Tokyo, Japan"` (메모는 notes) |

---

## 12. evidence_level + source_url

| 항목 | 출처 | evidence_level |
|---|---|---|
| Group 구조 | https://www.ojiholdings.co.jp/en/group/history.html | A |
| Mill 위치 | 공식 site + Wikipedia | A/B |
| NZ closures | https://en.wikipedia.org/wiki/Oji_Paper_Company | B |
| Walki 인수 | 공식 press release | A |
| 통합 보고서 | https://www.ojiholdings.co.jp/en/uploads/ir/docs/2024_all_en.pdf | A |

---

## 13. Risk / Caution

1. **Nippon Paper와 혼동 금지**: 1949 Zaibatsu 해체로 Oji가 3개 회사로 분리됨 → Tomakomai Paper (현 Oji), Honshu Paper, **Jujo Paper (현 Nippon Paper)**. 셋은 별개 family. 데이터에 "Jujo" 표기가 있으면 Nippon Paper로 분류.
2. **Honshu Paper는 다시 Oji와 합병**: 1996 New Oji Paper + Honshu Paper = Oji Paper. Honshu mill (Kushiro 등)은 모두 Oji 자산.
3. **CENIBRA = JV**: Oji 단독 소유 아님 (Brazilian partners 공동). 외부 회사로 분류된 row 있을 수 있음 → Oji family에 통합.
4. **Walki는 신규 자회사**: 2024-04 이전 데이터에 Walki를 독립 회사로 기록되어 있을 가능성. Oji family로 통합.
5. **Oji Fibre Solutions (NZ) 축소 중**: 2024-12 Auckland + 2025-06 Kinleith paper 폐쇄. status 업데이트 필요.
6. **JANT PNG**: 2004 철수 — status='closed' 처리.
7. **Sakhalin/Karafuto legacy**: 1933 Karafuto Industries 합병, 2차대전 후 상실. 역사적 자산만 — 현재 활성 mill 없음.

---

## 14. INSERT SQL 템플릿

```sql
-- Tomakomai (가장 상징적 mill)
INSERT INTO paper_mills (...)
VALUES
(
    {Oji_Paper_company_id},
    'Tomakomai',
    'japan',
    ARRAY['Newsprint', 'Coated paper'],
    NULL,
    'active',
    'Oji Holdings',
    'A',
    'https://www.ojiholdings.co.jp/en/group/history.html',
    '1910 가동. Oji 상징 mill. 일본 newsprint 자급 시발점. 현재도 newsprint 핵심.'
);

-- CENIBRA (브라질)
INSERT INTO paper_mills (...)
VALUES
(
    {CENIBRA_company_id},
    'Belo Oriente (CENIBRA)',
    'brazil',
    ARRAY['BEK Pulp'],
    1200000,
    'active',
    'Oji Holdings',
    'A',
    'https://www.cenibra.com.br',
    'Oji + Brazilian partners JV (1973). Minas Gerais 주 위치. BEK pulp 1.2Mt.'
);
```

---

## 15. 매핑 우선순위

1. Oji Holdings family → 다층 tier 구조 매핑 (HQ + 5 사업 법인 + 5+ Regional + 10+ Country)
2. 일본 mill은 city 단위 정규화 우선 (Tomakomai, Kushiro, Kasugai 등 핵심 5–10개)
3. Walki (2024 인수) → Oji family 통합
4. CENIBRA → Oji family로 분류 (지분 JV)
5. Auckland NZ + Kinleith paper → status='closed' / 'partially closed'
6. JANT PNG → status='closed' (2004)
7. Jujo Paper 라벨 → **Nippon Paper로 이동** (별도 family)

---

## 16. Tier 1 출처

| 출처 | URL |
|---|---|
| Oji Holdings 공식 | https://www.ojiholdings.co.jp/en/ |
| 그룹 역사 | https://www.ojiholdings.co.jp/en/group/history.html |
| 150주년 사이트 | https://www.ojiholdings.co.jp/150th/en/history/ |
| Wikipedia | https://en.wikipedia.org/wiki/Oji_Paper_Company |
| 2024 Integrated Report | https://www.ojiholdings.co.jp/en/uploads/ir/docs/2024_all_en.pdf |

---

**END — Oji Holdings Family Reference**
