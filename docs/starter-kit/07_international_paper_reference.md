# International Paper (IP) — Family Reference

**작성일**: 2026-05-15  
**용도**: paper_companies / paper_mills 에서 International Paper family rows 정리 가이드  
**참조 핸드오프**: handoff_v5_7.md #15 #20 #23 #33 #42

---

## ⚠️ 중요 구조 변화 (2024–2026)

이 family는 **두 차례 대규모 구조 변화**를 겪었음. 정리 시 반드시 인지:

1. **2025-01-31: DS Smith 인수 완료** (Enterprise Value GBP 7.8B ≈ USD 9.9B). IP가 DS Smith plc를 흡수. LSE 부 listing 추가 (티커 IPC).
2. **2026-01-29: 두 회사로 분할 발표** — 12~15개월 내 완료 예정:
   - **International Paper (NA)**: North America 사업 + 기존 IP 자산 + 북미 내 DS Smith 자산. Memphis HQ, NYSE listed. CEO Andy Silvernail.
   - **EMEA Packaging (신설 spin-off)**: 유럽·중동·아프리카 30개국, "operating as DS Smith" 브랜드. LSE + NYSE dual listing 예정. CEO Tim Nicholls.

**현재 (2026-05) 시점**: 아직 단일 회사. 분할은 진행 중. → 정리 시 **현재 단일 family 구조**로 매핑하되 notes 컬럼에 분할 진행 중임을 명시.

---

## 1. 그룹 정보

| 항목 | 값 |
|---|---|
| 법인명 | International Paper Company |
| HQ | Memphis, Tennessee, USA |
| 설립 | 1898-01-31 (북동부 미국·캐나다 동부 17개 mill 합병) |
| 상장 | NYSE: IP, LSE: IPC (secondary, 2025-02-04~) |
| 2024 매출 | USD 18.62B (DS Smith 통합 전) |
| 2025 매출 | USD 23.63B (+49% YoY, DS Smith 통합 후) |
| 2025 순손실 | USD 3.52B (DS Smith goodwill 손상 USD 2.5B 포함) |
| 직원 | ~65,000 (2025) |
| 운영국가 | 30개국 이상 (DS Smith 인수 후) |

---

## 2. Business segments / Divisions

DS Smith 인수 이후 (2025+) 두 segment:

### A. Industrial Packaging (North America)
- **2025 매출**: USD 15.2B (분할 후 NA 회사가 됨)
- 북미 corrugated 시장 점유율: **33%** (압도적 1위)
- containerboard (linerboard + medium) → 박스 plants 수직 통합
- 통합 자산: legacy IP mills + DS Smith 북미 자산

### B. EMEA Packaging  
- **2025 매출**: USD 8.5B
- 30개국 운영
- DS Smith 브랜드로 운영 중 (분할 후에도 유지 예상)
- 통합 자산: legacy DS Smith + IP EMEA

### 매각/축소된 segment
- **Global Cellulose Fibers (GCF)**: 2024 매출 USD 2.8B, 9개 제조시설, 3,300 직원. fluff pulp 사업. **2024-2025 매각 진행** (Suzano에 매각 협상 보도). Riegelwood + Pensacola pulp machine 영구 폐쇄 (2024-Q1).
- **Printing Papers / Sylvamo**: 2021-10 spin-off 완료 (Sylvamo Corporation 별도 상장)

---

## 3. Regional tier 후보

paper_companies 매핑 시 다음 tier 구조 예상:

| tier_role | 후보 회사명 | country |
|---|---|---|
| 🟣 HQ | International Paper Company | usa |
| 🔵 Regional | International Paper EMEA / DS Smith | united_kingdom or europe_composite |
| 🔵 Regional | International Paper Latin America | brazil or latam_composite |
| 🟢 Country | International Paper France / Germany / Italy / Spain / Portugal | (각 country) |
| 🟢 Country | DS Smith (Italia / France / Polska / Deutschland 등) | (각 country) |

---

## 4. 주요 활성 Mill 목록

### 4.1 Legacy IP — North America Containerboard
| Mill | 위치 | 주요 제품 | 비고 |
|---|---|---|---|
| Mansfield | Mansfield, LA | Containerboard | |
| Pine Bluff | Pine Bluff, AR | Containerboard | |
| Pensacola | Pensacola, FL | Containerboard | 2024 pulp machine 폐쇄 |
| Vicksburg | Vicksburg, MS | Containerboard | |
| Cedar River | Cedar Rapids, IA | Containerboard | |
| Maysville | Maysville, KY | Containerboard | |
| Bogalusa | Bogalusa, LA | Containerboard | |
| Henderson | Henderson, KY | Containerboard | |
| Springfield | Springfield, OR | Containerboard | |
| Valliant | Valliant, OK | Containerboard | |
| Prattville | Prattville, AL | Containerboard | |
| Rome | Rome, GA | Containerboard | |
| Riverdale (Selma) | Selma, AL | UFS→Containerboard | 2026-Q3 #16 머신 전환 예정 (USD 250M 투자) |
| Riegelwood | Riegelwood, NC | Pulp/Containerboard | 2024 pulp machine 폐쇄 |
| New Bern | New Bern, NC | Specialty | |

### 4.2 Legacy IP — Global Cellulose Fibers (fluff pulp)
| Mill | 위치 | 비고 |
|---|---|---|
| Eastover | Eastover, SC | fluff pulp |
| Flint River | Oglethorpe, GA | fluff pulp |
| Franklin | Franklin, VA | fluff pulp |
| Pensacola | Pensacola, FL | fluff pulp (partial) |
| Riegelwood | Riegelwood, NC | fluff pulp (machine 축소) |
| Columbus | Columbus, MS | fluff pulp |
| Port Wentworth | Port Wentworth, GA | fluff pulp |

> **주의**: GCF 사업이 매각 진행 중. 매각 완료 시 이 mill들은 IP family에서 제거 필요.

### 4.3 Legacy IP — Europe (DS Smith 인수 전 기존 IP EMEA)
| Mill | 위치 | 비고 |
|---|---|---|
| Madrid Mill | Fuenlabrada, Spain | Containerboard |
| Saillat | Saillat-sur-Vienne, France | UFS (Sylvamo로 매각됨) |
| Świecie | Świecie, Poland | Containerboard, 통합 자산 |
| Kwidzyn | Kwidzyn, Poland | UFS (Sylvamo로 매각됨) |

### 4.4 Legacy DS Smith — Paper Mills (2025 인수로 IP 산하 진입)
**주요 paper mills** (DS Smith는 paper + corrugated 통합 회사):

| Mill | 위치 | 주요 제품 |
|---|---|---|
| Kemsley | Sittingbourne, UK | recycled CCM, 연 830,000톤, UK 최대 |
| Aschaffenburg | Aschaffenburg, Germany | 100% recycled light medium |
| Witzenhausen | Witzenhausen, Germany | recycled CCM |
| De Hoop | De Hoop, Netherlands | recycled CCM |
| Lucca | Lucca, Italy | recycled CCM |
| Viana | Viana do Castelo, Portugal | recycled CCM |
| Nantes | Nantes, France | recycled CCM |
| Kaysersberg | Kaysersberg, France | recycled CCM |
| Chouanard (La Fosse) | Coullons, France | recycled CCM |
| Belišće | Belišće, Croatia | recycled CCM |
| Bilbao | Bilbao, Spain | recycled CCM |
| Spechthausen | Eberswalde, Germany | recycled CCM (Lessebo 인수 후) |

### 4.5 Legacy DS Smith — Latin America paper mills
| Mill | 위치 | 비고 |
|---|---|---|
| Río de Janeiro / São Paulo | Brazil | DS Smith Brasil |
| Various | Mexico | DS Smith Mexico |

---

## 5. 폐쇄/매각된 Mill (Legacy IP 중심)

### 5.1 2024-2025 폐쇄/매각 (최근 가장 중요)
| Mill | 위치 | 일자 | 조치 | 출처 |
|---|---|---|---|---|
| Orange Mill | Orange, TX | 2024-Q1 | 영구 폐쇄 (containerboard) | IP 10-Q |
| Georgetown | Georgetown, SC | 2024 말 | 영구 폐쇄 (fluff pulp 300kt + UFS) | Recycling Today |
| Riceboro | Riceboro, GA | 2025-Q3 | 단계적 폐쇄 (containerboard) | IP IR |
| Savannah | Savannah, GA | 2025-Q3 | 단계적 폐쇄 (containerboard + packaging) | IP IR |
| Pensacola pulp machine | Pensacola, FL | 2024-Q1 | machine만 폐쇄 (mill은 유지) | IP 10-Q |
| Riegelwood pulp machine | Riegelwood, NC | 2024-Q1 | machine만 폐쇄 (mill은 유지) | IP 10-Q |
| 5 European corrugated box plants | Saint-Amand/Mortagne/Cabourg(FR) + Ovar(PT) + Bilbao(ES) | 2025-Q2 | PALM Group 매각 (EU 규제 commitment) | IP IR |
| St. Paul | St. Paul, MN | 2025 | packaging plant 폐쇄 |
| Union Gap (Yakima) | Union Gap, WA | 2026 | container facility 폐쇄 (102 직원) |

### 5.2 더 오래된 매각 (Spin-off)
| 자산 | 일자 | 매각 대상 |
|---|---|---|
| Printing Papers (UFS) | 2021-10 | Sylvamo Corporation (spin-off, NYSE 별도 상장) |
| Kwidzyn (Poland) UFS | 2021 | → Sylvamo |
| Saillat (France) UFS | 2021 | → Sylvamo |
| Eastover UFS portion | 2021 | → Sylvamo |
| Ticonderoga | 2021 | → Sylvamo |

---

## 6. 5-Year Corporate Events 타임라인

| 일자 | 이벤트 |
|---|---|
| 2021-10 | Sylvamo (UFS 사업) spin-off 완료. IP는 packaging + GCF 집중 |
| 2022 | DS Smith는 별도 회사로 운영. IP는 corrugated/containerboard 강화 |
| 2024-Q1 | Orange TX 폐쇄, Pensacola+Riegelwood pulp machine 폐쇄 |
| 2024-04-16 | IP, DS Smith plc 인수 합의 발표 (USD 7.2B EV at announcement) |
| 2024-05 | Andy Silvernail CEO 취임 |
| 2024-말 | Georgetown SC 폐쇄 (~700명) |
| 2025-01-31 | DS Smith 인수 완료. LSE 부 listing (IPC) 추가 |
| 2025-04-14 | 5개 유럽 box plants PALM Group 매각 발표 (EU regulatory commitment) |
| 2025-Q3 | Riceboro + Savannah 단계적 폐쇄 |
| 2025-말 | Riverdale (Selma AL) #16 머신 containerboard 전환 발표 (USD 250M) |
| 2026-01-29 | **두 회사 분할 발표** (NA IP + EMEA spin-off, 12–15개월 일정) |
| 2026-02 | Silvernail 개인 USD 2M IP 주식 매수 (내부자 신호) |
| 2026-Q1 | Union Gap WA container facility 폐쇄 |

---

## 7. tier_role 매핑 가이드 (paper_companies)

handoff #19 Sappi 패턴 적용 (HQ/Regional/Country 3-tier):

```sql
-- HQ tier (1 row 예상)
🟣 International Paper Company         → headquarters: 'Memphis, Tennessee, USA'

-- Regional tier (2~3 row 예상)
🔵 International Paper EMEA / DS Smith → europe_composite
🔵 International Paper Latin America   → latam_composite or brazil
🔵 DS Smith (영국 기반 자산)            → united_kingdom (Regional 성격으로 분류 가능)

-- Country tier (5~10 row 예상)
🟢 DS Smith Italia                     → italy
🟢 DS Smith France                     → france
🟢 DS Smith Deutschland                → germany
🟢 DS Smith Polska                     → poland
🟢 DS Smith España                     → spain
🟢 DS Smith Portugal                   → portugal
🟢 DS Smith Nederland                  → netherlands
🟢 International Paper Brasil          → brazil
🟢 International Paper Mexico          → mexico
```

> **검증 방법**: CSV에서 family_group='International Paper' 그룹 row의 `name`, `country`, `headquarters` 컬럼 확인 → 위 매핑 적용.

---

## 8. mill_name 정규화 후보 (#20 generalized)

Sappi에서 발견된 "광역주 단위 mill_name" 문제가 IP에서도 빈번할 것:

| 잘못된 패턴 (의심) | 정규화 권장 |
|---|---|
| `"Mississippi"` (광역) | `"Vicksburg, MS"` 또는 `"Columbus, MS"` (city level) |
| `"Louisiana"` | `"Mansfield, LA"` / `"Campti, LA"` / `"Bogalusa, LA"` (mill 구분) |
| `"South Carolina"` | `"Eastover, SC"` 또는 `"Georgetown, SC (폐쇄)"` |
| `"DS Smith UK"` | `"Kemsley, UK"` 또는 `"Various UK"` |
| `"DS Smith Germany"` | `"Aschaffenburg, DE"` / `"Witzenhausen, DE"` |
| `"DS Smith France"` | 4개 mill 분리 (Nantes/Kaysersberg/Chouanard 등) |

---

## 9. multi-region rollup split 후보 (#23)

| 의심 row | 권장 분할 |
|---|---|
| `"DS Smith Europe"` (단일 row로 통합 표기) | DS Smith UK + DE + FR + IT + ES + PT + NL + PL + HR 각각 country tier |
| `"International Paper Global"` (single row) | NA + EMEA + LATAM 3 regional |
| `"IP Packaging Solutions"` (segment 단위) | 무효 (segment는 tier가 아님 — segment 컬럼으로 이동 필요) |

---

## 10. compound entity 정책 (#15)

| 의심 라벨 | 정책 적용 |
|---|---|
| `"International Paper / DS Smith"` | **두 row 분리** — IP HQ + DS Smith Regional 각각 |
| `"IP Latin America (Brasil + Mexico)"` | brazil + mexico 분리 |
| `"DS Smith Iberia (ES+PT)"` | spain + portugal 분리 |

---

## 11. headquarters 정정 후보 (#33 generalized)

Sappi에서 `headquarters="Public — JSE-listed"` (메모 침입) 패턴 발견됨. IP에서 의심:

| 의심 패턴 | 정정 |
|---|---|
| `"NYSE-listed"` / `"Public — NYSE"` | `"Memphis, Tennessee, USA"` |
| `"DS Smith — LSE-listed"` | `"London, UK"` (legacy HQ) |
| `"Fortune 500"` | `"Memphis, Tennessee, USA"` |
| 회사 소개·sustainability 메모 | 도시·국가 형식으로 정정 |

---

## 12. evidence_level + source_url 권장 (Tier 1 출처)

| 항목 | 출처 URL | evidence_level |
|---|---|---|
| 매출/직원/segment | IP 10-K (SEC EDGAR) / 2025 Annual Report | A |
| DS Smith 인수 완료 | https://www.prnewswire.com/news-releases/international-paper-completes-acquisition-of-ds-smith-302365680.html | A |
| 2026 분할 발표 | https://internationalpaper2022rd.q4web.com/news/news-details/2026/International-Paper-to-Create-Two-Independent-Public-Companies/default.aspx | A |
| Mill 위치 | DS Smith 공식 site (www.dssmith.com/company/locations) + IP corporate map | A |
| 폐쇄 mill | Packaging Dive / Recycling Today / IP press releases | B |
| 산업 통계 | Statista, RISI / Fastmarkets | C |

---

## 13. Risk / Caution 항목

1. **분할 진행 중**: 12~15개월 내 EMEA spin-off 완료. 이후 family를 둘로 분리해야 함. 현재는 단일 family로 두되 notes에 명시.
2. **DS Smith goodwill 손상 USD 2.5B**: 자산 가치 평가 변동 가능. 일부 EMEA 자산 추가 매각 가능성.
3. **GCF 사업 매각 진행**: 7~9개 fluff pulp mill이 곧 family에서 제외될 수 있음. 매각 완료 모니터링 필요.
4. **Sylvamo 자산 혼동 주의**: Kwidzyn, Saillat, Eastover 일부, Ticonderoga 등은 **Sylvamo (IP가 아님)** 소속. 잘못 IP family에 분류된 row 있을 가능성 점검.
5. **Smurfit Westrock와 혼동 금지**: Smurfit Kappa는 WestRock과 합병 (2024-07). DS Smith는 **IP와 합병** (2025-01). 두 사건이 가까운 시점에 발생해 데이터에 혼동 가능성 있음. **DS Smith ≠ Smurfit Westrock 일부 아님.**
6. **Mill 이름 동음이의 위험**:
   - "Springfield": IP (OR) vs Weyerhaeuser (OR) — 동일 도시 다른 회사 가능
   - "Pensacola": IP 운영
   - "Henderson": IP (KY)
7. **Riverdale 진행 중 전환**: 2026-Q3까지 UFS→containerboard, 진행 중 row의 product 컬럼 timing 주의.

---

## 14. 누락 가능한 Mill INSERT SQL 템플릿

CSV에서 누락 발견 시 사용:

```sql
INSERT INTO paper_mills (
    paper_company_id, mill_name, country,
    main_products, capacity_metric_tons_per_year,
    status, family_group, evidence_level, source_url, notes
)
VALUES
(
    {DS_Smith_UK_company_id},
    'Kemsley',
    'united_kingdom',
    ARRAY['Containerboard (recycled)', 'Light medium', 'White liner'],
    830000,
    'active',
    'International Paper',
    'A',
    'https://www.dssmith.com/company/locations/our-paper-mills/kemsley-mill',
    'UK 최대 recycled paper mill, Europe #2. 2008 DS Smith 단독 인수 후 GBP 100M 투자. 2025-01 IP family 진입.'
);
```

---

## 15. 매핑 우선순위 (다음 세션 작업 순서)

1. **B step**: paper_companies CSV 추출 (family_group='International Paper') → tier 매핑
2. **C step**: paper_mills CSV 추출 (family_group='International Paper') → mill_name 정규화
3. **D step**: DS Smith 라벨 row 별도 확인 (family_group='DS Smith' 또는 'International Paper / DS Smith' 모두 IP family로 통합)
4. **E step**: Sylvamo 자산이 IP family로 잘못 분류된 row 발견 → Sylvamo family로 이동 (별도 family 생성)
5. **F step**: 폐쇄 mill (Orange, Georgetown, Riceboro, Savannah) status='closed' 업데이트
6. **G step**: notes 컬럼에 "분할 진행 중 (2026-01 발표, EMEA spin-off 예정)" 표기
7. **검증**: `/industry/paper-mills?search=International Paper` + `/industry/paper-mills?search=DS Smith` → 양쪽 모두 동일 family 색상

---

## 16. Tier 1 출처

| 출처 | URL |
|---|---|
| IP 공식 IR | https://www.internationalpaper.com |
| IP SEC filings (10-K, 10-Q, 8-K) | https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0000051434 |
| DS Smith 공식 (현 IP 산하) | https://www.dssmith.com/company/locations |
| 2026 분할 보도 | https://www.packagingdive.com/news/international-paper-ds-smith-split-two-companies-spinoff/810809/ |
| 5 EU box plant 매각 | https://www.prnewswire.com/news-releases/international-paper-announces-exclusive-negotiations-to-divest-five-european-corrugated-box-plants-302427168.html |

---

**END OF DOCUMENT — International Paper Family Reference**
