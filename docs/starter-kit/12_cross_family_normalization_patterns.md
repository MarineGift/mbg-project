# 횡단(Cross-Family) 정규화 패턴 가이드

**작성일**: 2026-05-15  
**용도**: 11개 family reference 작성 중 발견된 **공통 정규화 패턴** 정리  
**참조 핸드오프 이슈**: #15 (compound entity), #20 (mill_name), #23 (multi-region rollup), #33 (headquarters)

---

## 0. 사용 방법

이 문서는 family별 reference (01~11)에 분산된 정규화 패턴을 **횡단(cross-family) 카테고리**로 재조직한 것입니다. 다음 작업 시 함께 참조:

1. **family 정리 SQL 작성 전** — 이 문서로 패턴 패밀리화 후 reference 세부 확인
2. **개별 row 결정이 어려울 때** — 비슷한 패턴이 다른 family에 있는지 검색
3. **신규 family 추가 시** — 이 패턴 카테고리 기준 새 reference 작성

---

## 1. handquarters 정정 패턴 (#33 generalized)

**Sappi에서 발견**: `headquarters="Public — JSE-listed"` (회사 성격 메모가 city/country 자리에 침입)

**Cross-family 빈도**: **매우 높음** — 11 family 모두 동일 패턴 의심됨

### 1.1 상장 정보 침입 패턴
| 잘못된 패턴 | 정정 |
|---|---|
| `"NYSE-listed"` / `"Public — NYSE"` | 회사 실제 본사 도시·국가 |
| `"LSE-listed"` / `"FTSE100"` | 실제 본사 |
| `"HKEX: 2689"` | `"Dongguan, Guangdong, China"` (Nine Dragons 예) |
| `"TSE / Nikkei 225"` | `"Tokyo, Japan"` (Oji 예) |
| `"Nasdaq Helsinki + Stockholm"` | `"Helsinki, Finland"` 또는 `"Stockholm, Sweden"` (Stora Enso 예) |
| `"B3: KLBN11"` / `"B3-listed"` | `"São Paulo, Brazil"` (Klabin/Suzano 예) |
| `"FTSE100 + JSE"` (Sappi/Mondi) | 각각의 본사 도시 |

### 1.2 회사 별명/위상 침입 패턴
| 잘못된 패턴 | 정정 |
|---|---|
| `"Paper Queen — Cheung Yan"` | `"Dongguan, China"` (Nine Dragons) |
| `"World's largest paper company"` | 본사 도시·국가 |
| `"Brazil's largest paper exporter"` | `"São Paulo, Brazil"` (Klabin) |
| `"Asia's largest paper company"` | `"Tokyo, Japan"` (Oji) |
| `"World's largest hardwood pulp producer"` | `"São Paulo, Brazil"` (Suzano) |
| 회사 description / sustainability copy | 도시·국가 형식으로 단순화 |

### 1.3 Mill 위치를 HQ로 오인하는 패턴
| 잘못된 패턴 | 정정 |
|---|---|
| `"Tomakomai"` (Oji mill 위치) | `"Tokyo, Japan"` |
| `"Telêmaco Borba"` (Klabin Monte Alegre 위치) | `"São Paulo, Brazil"` |
| `"Ribas do Rio Pardo"` (Suzano Cerrado 위치) | `"São Paulo, Brazil"` |
| `"Memphis, TN"` (IP는 정확) vs `"Stamford, CT"` (옛 IP) | 현재 본사로 |
| `"Verona"` (Fedrigoni — 정확) | Fedrigoni는 실제 Verona가 본사 |

### 1.4 상장지를 HQ로 오인 (Hong Kong, London 등)
| 패턴 | 정정 |
|---|---|
| Nine Dragons: `"Hong Kong"` | `"Dongguan, China"` (HKEX 상장이지만 본사는 중국 본토) |
| IP: `"London"` (2025 LSE secondary) | `"Memphis, TN, USA"` (primary HQ 그대로) |
| Smurfit Westrock: `"Dublin"` (정확) vs `"Memphis, TN"` (옛 WestRock) | Dublin (현재) |

### 1.5 행정 권역명 침입 (state/province 단위)
| 잘못된 패턴 | 정정 |
|---|---|
| `"South Africa"` (단독) | `"Johannesburg, South Africa"` (Sappi) |
| `"Brazil"` (단독) | `"São Paulo, Brazil"` |
| `"Czech Republic"` | 도시 명시 |

---

## 2. mill_name 정규화 패턴 (#20 generalized)

**Sappi에서 발견**: `mill_name="KwaZulu-Natal"` (광역주 단위, 4개 row 중 2개 중복)

**Cross-family 빈도**: **극도로 높음** — 모든 family에서 발견 의심

### 2.1 광역 행정구역 → city 변환

#### 브라질 — 주 단위가 자주 등장
| 광역 패턴 | 분리 권장 |
|---|---|
| `"Mato Grosso do Sul"` | Suzano: Três Lagoas vs Ribas do Rio Pardo (Cerrado) 2개 분리 |
| `"São Paulo (state)"` | Suzano: Suzano(city) + Limeira + Jacareí + Rio Verde (4개 mill) |
| `"Paraná"` | Klabin: Ortigueira (Puma) + Telêmaco Borba (Monte Alegre) 2개 분리 |
| `"Santa Catarina"` | Klabin: Correia Pinto + Otacílio Costa + Lages + Itajaí (4개 mill) |
| `"Espírito Santo"` | Suzano: Aracruz (pulp) + Cachoeiro de Itapemirim (tissue) 분리 |
| `"Bahia"` | Suzano: Mucuri |
| `"Maranhão"` | Suzano: Imperatriz |
| `"Minas Gerais"` | Oji: CENIBRA (Belo Oriente) |

#### 미국 — state 단위가 자주 등장
| 광역 패턴 | 분리 권장 |
|---|---|
| `"Mississippi"` | IP: Vicksburg or Columbus (2개 mill) |
| `"Louisiana"` | IP: Mansfield + Campti + Bogalusa (3+개 mill) |
| `"South Carolina"` | IP: Eastover (활성) + Georgetown (2024 폐쇄) |
| `"Alabama"` | IP: Prattville + Riverdale(Selma) + Mahrt(Smurfit WR) |
| `"Maine"` | Nine Dragons (ND Paper): Rumford + Old Town 2개 분리 |
| `"Wisconsin"` | Nine Dragons (ND Paper): Biron (Wisconsin Rapids) |

#### 일본 — 도(都/道/府/県) 단위
| 광역 패턴 | 분리 권장 |
|---|---|
| `"Hokkaido"` | Oji: Tomakomai + Kushiro + Ebetsu + Chitose (4+개 mill) |
| `"Aichi"` | Oji: Kasugai |
| `"Tottori"` | Oji: Yonago |
| `"Hiroshima"` | Oji: Kure |

#### 유럽 — 국가/지역 단위
| 광역 패턴 | 분리 권장 |
|---|---|
| `"DS Smith UK"` (IP family) | Kemsley 등 city 명시 |
| `"DS Smith Germany"` (IP family) | Aschaffenburg + Witzenhausen + Spechthausen 분리 |
| `"DS Smith France"` (IP family) | Nantes + Kaysersberg + Chouanard + 5 box plants 분리 |
| `"Mondi Austria"` | Frantschach + Neusiedler + Grünburg 분리 |
| `"Mondi South Africa"` | Richards Bay + Merebank 분리 |
| `"Stora Enso Sweden"` | Skoghall + Skutskär + Värmlands(closed) + Hylte(sold) 분리 |
| `"Smurfit Westrock Europe"` | Piteå + Nettingsdorf + Roermond + Zülpich + Facture 등 분리 |
| `"UPM Finland"` | Kaukas + Kymi + Rauma + Jämsänkoski + Pietarsaari 등 분리 |

#### 중국 — 광역시/성 단위
| 광역 패턴 | 분리 권장 |
|---|---|
| `"Guangdong"` | Nine Dragons: Dongguan Base (+ Beihai의 경우 Guangxi) |
| `"Jiangsu"` | Nine Dragons: Taicang |
| `"Fujian"` | Nine Dragons: Quanzhou |
| `"Hubei"` | Nine Dragons: Jingzhou |
| `"Hebei"` | Nine Dragons: Tangshan |

### 2.2 Brand/Legacy 이름 정리
| 패턴 | 정정 |
|---|---|
| `"Olinkraft"` (Klabin legacy) | `"Monte Alegre (Telêmaco Borba)"` |
| `"Fibria assets"` (Suzano legacy) | Aracruz / Três Lagoas / Jacareí 명시 |
| `"Jujo Paper"` | 사실 다른 family (현 Nippon Paper) — Oji가 아님 |
| `"Honshu Paper"` (Oji legacy) | Oji 산하 mill 명시 (Kushiro 등) |
| `"M-real"` (Metsä legacy) | Husum / 기타 Metsä Board mill로 |
| `"Crown Van Gelder"` (Sappi data error) | 네덜란드 회사, Sappi 외 |

### 2.3 PM 번호 + city 혼동
| 패턴 | 정정 |
|---|---|
| `"PM32 Coated Ivory"` | mill_name='Dongguan' + main_products에 PM32 명시 |
| `"MP27 Eukaliner"` | mill_name='Puma Unit (Ortigueira)' + product에 표기 |

### 2.4 매각/이전 자산의 옛 family 라벨
| 패턴 | 정정 |
|---|---|
| `"Pactiv Pine Bluff"` (현 Suzano) | Suzano family로 family_group 변경 |
| `"Catalyst Old Town"` (현 Nine Dragons) | Nine Dragons family로 |
| `"Burgo Duino"` (현 Mondi) | Mondi family로 |
| `"Norske Skog Walsum"` (옛) | 매각된 mill — 현재 소유자 family로 |

---

## 3. multi-region rollup split 패턴 (#23 generalized)

**핵심 원칙**: 단일 row가 `"X (모든 지역)"` 형태라면 **국가/지역 단위 분리** 필요.

### 3.1 "All Region" rollup 패턴

| 잘못된 단일 row | 권장 분할 |
|---|---|
| `"Sappi Europe"` | Sappi DE + AT + BE + NL + UK 분리 |
| `"Sappi North America"` | Sappi NA 단일 OK, 단 mill은 Cloquet/Somerset/Westbrook 분리 |
| `"Mondi Europe"` | Mondi AT + DE + CZ + SK + PL + IT 분리 |
| `"Stora Enso Nordics"` | FI + SE 분리 |
| `"UPM Continental Europe"` | DE + FR + AT + PL 분리 |
| `"Smurfit Westrock Europe"` | UK + IE + DE + FR + NL + IT + AT + ES + PT + 동유럽 분리 |
| `"IP EMEA"` | EU 국가들 + ME + 아프리카 분리 (30개국) |
| `"DS Smith Europe"` | UK + DE + FR + IT + ES + PT + NL + PL + HR 분리 |
| `"Oji Asia"` | China + Malaysia + Indonesia + Vietnam + Thailand 분리 |
| `"Oji Fibre Solutions (NZ+AU)"` | NZ + AU 분리 |
| `"Nine Dragons China (all)"` | 10개 base + 8개 packaging 분리 |
| `"Walki Europe"` (Oji 산하) | 다국 운영 — country 별 분리 |

### 3.2 Compound 국가 grouping
| 패턴 | 정책 |
|---|---|
| `"Iberia (ES + PT)"` | ES + PT 분리 |
| `"DACH (DE + AT + CH)"` | DE + AT + CH 분리 |
| `"Benelux"` | BE + NL + LU 분리 |
| `"Nordics (FI + SE + NO + DK)"` | 각 국 분리 |
| `"Baltics (EE + LV + LT)"` | 각 국 분리 (Stora Enso, Metsä 등) |
| `"LATAM"` | BR + AR + MX + CL 등 분리 |
| `"ASEAN"` | MY + VN + TH + ID + PH 분리 |
| `"Greater China"` | CN + HK + TW 분리 (정책 결정 필요) |

### 3.3 Segment-Region 혼동
| 잘못된 패턴 | 정책 |
|---|---|
| `"IP Packaging Solutions EMEA"` | **segment 컬럼**으로 이동 (region 아님) |
| `"Stora Enso Forest Division"` | segment 컬럼 |
| `"Mondi Corrugated Packaging"` | segment 컬럼 |

> Segment는 tier가 아님. paper_companies 테이블에 segment 컬럼이 있으면 그쪽으로, 없으면 notes로.

---

## 4. compound entity 정책 (#15 generalized)

**핵심 원칙**: `"A / B"` 또는 `"A + B"` 라벨은 거의 항상 **별도 row로 분리**.

### 4.1 합병/인수로 사라진 회사 — 통합 family
| 패턴 | 정책 |
|---|---|
| `"Suzano / Fibria"` | **Suzano 단일** (2019 합병 완료) |
| `"Oji / Honshu"` | **Oji 단일** (1996 합병 완료) |
| `"Smurfit / Kappa"` | **Smurfit Kappa 단일** (2005 합병) |
| `"Smurfit Kappa / WestRock"` | **Smurfit Westrock 단일** (2024-07 합병) |
| `"Stora / Enso"` | **Stora Enso 단일** (1998 합병) |
| `"UPM / Kymmene"` | **UPM-Kymmene 단일** (1995-96 합병) |
| `"International Paper / DS Smith"` | **IP 단일** (2025-01 합병 완료). 단 2026-말 분할 예정 |
| `"Metsä / M-real"` | **Metsä 단일** (M-real → Metsä Board 명칭 변경) |
| `"IP / Sylvamo"` | **분리** — Sylvamo는 2021-10 IP에서 spin-off된 별도 상장회사 |

### 4.2 자회사 정책 — Regional/Country tier로 표현
| 패턴 | 정책 |
|---|---|
| `"Nine Dragons / ND Paper"` | **Nine Dragons family에 통합**, ND Paper는 Regional row |
| `"Oji / Walki"` | Oji family, Walki는 Regional |
| `"Oji / CENIBRA"` | Oji family (지분 JV), Regional row |
| `"Suzano + Pactiv Evergreen"` | Pactiv은 별도 회사 — Suzano family에 Pine Bluff/Waynesville 자산만 |
| `"Smurfit Westrock / DS Smith"` | **두 별개 family** (DS Smith는 IP family) |
| `"Mondi / Schumacher"` | Mondi family (2025-03 인수) |
| `"Fedrigoni / Mohawk"` | Fedrigoni family (2024 인수) |

### 4.3 JV 정책
| 패턴 | 정책 |
|---|---|
| `"Suzano + Kimberly-Clark JV"` (2025-06 발표) | JV 결성 완료 후 별도 family 검토. 현재는 모니터링. |
| `"Stora Enso + Sumitomo"` (Sunila 등) | 보통 모회사 family로 분류 |

### 4.4 Spin-off
| 패턴 | 정책 |
|---|---|
| `"IP / Sylvamo"` | **분리** — Sylvamo는 별도 family |
| `"IP / EMEA Packaging (new)"` | 2026-말 분할 완료 후 **분리** 예정. 현재는 IP 단일 |
| `"Metsä Board (formerly M-real)"` | Metsä family 내. M-real는 옛 이름 |

---

## 5. Country mapping 권장 (참고)

여러 family에서 등장하는 country tier 매핑 권장:

| family | 주요 country tier 매핑 |
|---|---|
| Sappi | south_africa (HQ), usa, italy, portugal, finland, united_kingdom |
| Mondi | united_kingdom (HQ), south_africa, czech_republic, slovakia, austria, poland, italy, bulgaria(closed), canada |
| Stora Enso | finland (HQ), sweden, poland, baltic(EE/LV/LT), germany, china |
| UPM | finland (HQ), germany, austria, france, uk, poland, china, uruguay, usa |
| Smurfit Westrock | ireland (HQ), usa, sweden, france, austria, netherlands, germany, italy, uk, mexico, latam, africa |
| Metsä | finland (HQ), sweden, germany, slovakia, poland |
| Fedrigoni | italy (HQ), france, china, usa, spain |
| International Paper | usa (HQ), uk, france, germany, spain, portugal, italy, brazil, mexico |
| Suzano | brazil (HQ), usa, switzerland |
| Klabin | brazil (HQ), argentina |
| Oji Holdings | japan (HQ), china, malaysia, indonesia, vietnam, australia, new_zealand, brazil, finland(Walki) |
| Nine Dragons | china (HQ), usa, malaysia, vietnam |

---

## 6. status (active / closed / sold) 결정 가이드

각 reference §5에 명시. 핵심 최근 (2024-2026) closures:

### 2024
- **IP** Orange TX, Georgetown SC (closed)
- **IP** 5 EU box plants → PALM (sold)
- **Oji Fibre Solutions** Auckland NZ (closed 2024-12)
- **Mondi** Stambolijski BG fire (closed 2024-10)

### 2025
- **IP** Riceboro + Savannah GA, St. Paul MN, Cedar Rapids IA (closed/closing)
- **Smurfit Westrock** 9+ closures (St. Paul, Forney, etc.)
- **Oji Fibre Solutions** Kinleith paper machines (closed 2025-06, pulp 유지)
- **UPM** Ettringen 발표 (legal dispute)

### 2026
- **Smurfit Westrock** SSK Birmingham UK 발표 (2026-05 협의 시작)
- **IP** Union Gap WA (closed Q1)

---

## 7. capacity / 매출 단위 권장

| 항목 | 권장 단위 | 변환 |
|---|---|---|
| Pulp/paper capacity | metric tonnes / year (Mt/y or kt/y) | short tons → ×0.9072 |
| 매출 | local 통화 + USD 환산 | report 시점 환율 사용 |
| 직원 | 정수 (full-time equivalent) | |

> 미국 자료의 short tons (ST)와 metric tons (MT) 혼동 주의. ND Paper Rumford "550,000 mt/year" 명시 좋은 예.

---

## 8. evidence_level 일관성 가이드

handoff #36에서 Sappi 8 row 중 1 row만 evidence_level='B' 발견 → 전 family audit 권장.

| 출처 종류 | 권장 evidence_level |
|---|---|
| 회사 IR / 공식 site / 10-K (SEC) | A |
| 회사 press release / Annual Report | A |
| 전문 산업 매체 (Fastmarkets, EUWID, Packaging Dive, PaperAge) | B |
| Wikipedia, Statista | B |
| 일반 매체 / Bloomberg / Reuters | B |
| NGO (BankTrack 등) — 비판적 시각 | C |
| 회사 자체 sustainability copy | C (편향 가능) |
| 미확인 출처 | NULL |

---

## 9. source_url 일관성

각 reference §16 (Tier 1 출처)에 family별 공식 URL 정리됨. 권장:

1. **회사 공식 IR/About** URL을 HQ row에 적용
2. **Mill 공식 page** (가능시) — 특정 mill에 직접 link
3. **press release 전문 URL** — 합병/인수/폐쇄 이벤트 row에

---

## 10. notes 컬럼 활용 권장

handoff #35: Sappi NA `main_products`에 "미국 mill 3개: Cloquet MN ..." 메모 발견 → **notes로 이동** 필요.

### notes 사용 적절 사례
- 폐쇄 사유 (예: "2024-10 화재 후 영구 폐쇄")
- 인수/이전 이력 (예: "옛 IP→Evergreen→Pactiv→Suzano 2024-10")
- 진행 중 변화 (예: "2026-Q3 PM16 containerboard 전환 예정 (USD 250M)")
- 산업 의미 (예: "세계 최초 100% eucalyptus kraftliner")
- 분할/spin-off 예고 (예: "EMEA 자산 2026-말 spin-off 예정")

### notes 부적절 사례 (다른 컬럼으로 이동)
- 도시/국가 정보 → `country` / `headquarters`
- 제품 정보 → `main_products` (ARRAY)
- segment → `segment` 컬럼 (있을 경우)
- 매출/직원 수치 → 전용 컬럼

---

## 11. 일관성 체크리스트 (다음 세션 시 활용)

각 family CSV 매핑 SQL 작성 후 다음 항목 확인:

- [ ] HQ row 정확히 1개 (도시, 국가 정확)
- [ ] Regional row 수가 reference §3과 일치
- [ ] Country row 수가 reference §3과 일치
- [ ] tier_role 색상 (HQ 🟣, Regional 🔵, Country 🟢) 매핑 정확
- [ ] family_group 컬럼 모든 row 일관성 (예: 'International Paper' vs 'IP' vs 'Int Paper' 혼용 금지)
- [ ] mill_name이 city 수준 (광역주/국가 단위 없음)
- [ ] headquarters 컬럼이 도시+국가 형식 ("상장 정보", "회사 설명" 침입 없음)
- [ ] 폐쇄 mill status='closed', sold mill 별도 처리
- [ ] 합병 legacy 라벨 (Fibria, Honshu, M-real 등) 통합 완료
- [ ] evidence_level 모든 row 채워짐 (NULL 최소화)
- [ ] source_url 핵심 row에 채워짐

---

**END — 횡단 정규화 패턴 가이드**
