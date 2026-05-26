# Klabin S.A. — Family Reference

**작성일**: 2026-05-15  
**용도**: paper_companies / paper_mills 에서 Klabin family rows 정리 가이드  
**참조 핸드오프**: handoff_v5_7.md #15 #20 #23 #33 #42

---

## 1. 그룹 정보

| 항목 | 값 |
|---|---|
| 법인명 | Klabin S.A. |
| HQ | São Paulo, Brazil |
| 설립 | 1899 |
| 상장 | B3: KLBN11 (units, Brazil) |
| 산업 지위 | **브라질 최대 paper 생산자/수출자/recycler**, 브라질 **2위 pulp 생산자** (Suzano 다음) |
| Pulp capacity | ~4.0M 톤 (Puma II 가동 후) |
| Paper capacity | ~5M 톤 (containerboard + kraftliner + paperboard + sack kraft) |
| 직원 | ~25,000 |

**특징**: Suzano와 달리 **integrated paper company**. pulp 시장 판매 + 자체 paper/packaging 변환 둘 다 운영. Eukaliner® (세계 최초 100% eucalyptus kraftliner) 보유.

---

## 2. Business segments

### A. Pulp (펄프) — 시장 판매 + 자체 사용
- **3가지 펄프 통합 생산 세계 최초** (Puma 가동 후): hardwood (eucalyptus) + softwood (pine) + fluff
- BEK + BSK + fluff 동일 mill에서 생산 — 매우 드문 구조

### B. Paper (Packaging Papers)
- Kraftliner (raw 가공용)
- Eukaliner® — 세계 최초 100% eucalyptus kraftliner (Puma II에서 생산)
- Containerboard (corrugated용)
- Sack kraft (시멘트 포대 등)
- Paperboard for liquid packaging (long-life milk/juice 카톤)
- Paperboard for processed foods (시리얼/초콜릿/피자 등)
- Cupstock + foodservice paperboard

### C. Corrugated Packaging
- 브라질 최대 corrugated box 제조사
- 다수 corrugated converting plants

### D. 산업 가방 (Industrial Bags)
- Sack kraft 기반 시멘트/곡물 산업용 가방

---

## 3. Regional tier 후보

```
🟣 HQ: Klabin S.A.                   → 'São Paulo, Brazil'
🔵 Regional: Klabin Argentina        → argentina (sub-소유)
🔵 Regional: Klabin (overseas sales) → 거의 없음 — 브라질 mill 중심
```

> Klabin은 Suzano와 마찬가지로 **거의 모든 자산이 브라질 내**. country tier 매핑 row가 적을 것.

---

## 4. 주요 활성 Mill 목록

### 4.1 핵심 통합 Pulp + Paper Mills

| Mill Unit | 위치 (도시, 주) | 종류 | Capacity | 비고 |
|---|---|---|---|---|
| **Puma Unit (Ortigueira)** | Ortigueira, Paraná | Pulp (BEK+BSK+Fluff) + Paper | 1.5M 톤 pulp (Puma I, 2016) + Puma II (2021~ MP27/MP28) | 세계 최초 hardwood+softwood+fluff 통합 mill. Puma II MP27 (Eukaliner kraftliner 450kt, 2021-08 가동), MP28 (paperboard 460kt, 2023). 총 USD 4B+ 투자 |
| **Monte Alegre Unit** | Telêmaco Borba, Paraná | Pulp + Paper (integrated) | 1.0M+ 톤 (paper) | 1934 설립. 2008 세계 top 10 paper mill 진입. long-life carton, virgin paperboard 생산. Klabin 발상지 |
| **Correia Pinto Unit** | Correia Pinto, Santa Catarina | Pulp (작은 규모) | | 통합 운영. Olinkraft 합병으로 1958 가동 |
| **Otacílio Costa Unit** | Otacílio Costa, Santa Catarina | Pulp (작은 규모) + Paper | | Correia Pinto와 인근 |

### 4.2 Paper / Sack Kraft only

| Mill | 위치 | 종류 | 비고 |
|---|---|---|---|
| **Angatuba** | Angatuba, São Paulo | Sack kraft paper | |
| **Lages** | Lages, Santa Catarina | Sack kraft | |
| **Itajaí** | Itajaí, Santa Catarina | Packaging paper | |
| **Goiana** | Goiana, Pernambuco | Corrugated converting | (paper 미생산) |
| **다수 corrugated plants** | Brazil 전국 | Box converting | 18+ plants |

### 4.3 Argentina

| Mill | 위치 | 비고 |
|---|---|---|
| Klabin Argentina | (다수 packaging plants) | corrugated converting |

---

## 5. 폐쇄/매각된 자산

| 자산 | 일자 | 조치 |
|---|---|---|
| Various converting plants | continual | 소규모 통합/이동 |

> Klabin은 closure가 거의 없음. 확장 중심 전략.

---

## 6. 5-Year Corporate Events 타임라인

| 일자 | 이벤트 |
|---|---|
| 2016 | **Puma I Unit 가동** (Ortigueira, PR) — 1.5Mt pulp, USD 8.5B 투자. 브라질 역사상 PR주 최대 민간 투자 |
| 2018 | Embalplan (Rio Negro, PR) 인수, Hevi Embalagens (Manaus, AM) 자산 인수 |
| 2019-2020 | Puma II Project 발표 — BRL 12.9B (USD 2.7B) 투자, MP27+MP28 |
| 2021-08-30 | **Puma II MP27 가동** — 450kt Eukaliner® (세계 최초 100% eucalyptus kraftliner) |
| 2022 | 신규 컨테이너 철도 터미널 가동 (PR주, BRL 300M 투자) |
| 2023 | Puma II MP28 가동 — 460kt paperboard (long-life carton + foodservice) |
| 2024 | 통합 운영 안정화 단계 |

---

## 7. tier_role 매핑 가이드

```sql
🟣 HQ: Klabin S.A.                         → 'São Paulo, Brazil'
🔵 Regional: Klabin Argentina               → 'argentina' (있을 경우)
🟢 Country: (거의 없음, 브라질 외 자산 적음)
```

---

## 8. mill_name 정규화 후보 (#20)

| 잘못된 패턴 (의심) | 정규화 권장 |
|---|---|
| `"Paraná"` (광역주) | `"Ortigueira (Puma)"` + `"Telêmaco Borba (Monte Alegre)"` 분리 |
| `"Santa Catarina"` | `"Correia Pinto"` + `"Otacílio Costa"` + `"Lages"` + `"Itajaí"` 분리 (4개 mill 있음) |
| `"São Paulo"` (state) | `"Angatuba"` 명시 |
| `"Puma"` (단독) | `"Puma Unit (Ortigueira)"` 또는 `"Ortigueira"` |
| `"Olinkraft legacy"` | `"Monte Alegre Unit (Telêmaco Borba)"` |

---

## 9. multi-region rollup split 후보 (#23)

| 의심 row | 권장 분할 |
|---|---|
| `"Klabin Brazil"` (단일) | Puma + Monte Alegre + Correia Pinto + Otacílio Costa + Angatuba 등 개별 분리 |
| `"Klabin South Region"` | PR + SC 주별 mill 분리 |

---

## 10. compound entity 정책 (#15)

| 의심 라벨 | 정책 |
|---|---|
| `"Klabin / Suzano"` | **분리** — 두 회사는 별개 (브라질 1·2위 펄프) |
| `"Klabin (incl. Argentina)"` | Klabin Brazil HQ + Klabin Argentina Regional 분리 |

---

## 11. headquarters 정정 후보 (#33)

| 의심 패턴 | 정정 |
|---|---|
| `"B3-listed"` | `"São Paulo, Brazil"` |
| `"Brazil's largest paper exporter"` | `"São Paulo, Brazil"` (메모는 notes로) |
| `"Telêmaco Borba"` (Monte Alegre mill을 HQ로 오인) | `"São Paulo, Brazil"` |

---

## 12. evidence_level + source_url

| 항목 | 출처 | evidence_level |
|---|---|---|
| Capacity, mill list | https://klabin.com.br/en/nossa-essencia/onde-estamos (공식) | A |
| Puma II MP27/28 가동 | ANDRITZ + PaperAge press releases | A |
| Eukaliner 출시 | Klabin IR + Packaging Strategies | A |
| 산업 분석 | BankTrack — https://www.banktrack.org/company/klabin | C (NGO) |

---

## 13. Risk / Caution

1. **Puma II 진행 중**: MP27 (2021) + MP28 (2023) 단계적 가동. capacity 표기 timing 주의.
2. **Eukaliner® 신규 grade**: 다른 회사와 구분 위해 명시. Klabin 독자 grade.
3. **Suzano와 혼동 금지**: 둘 다 브라질 펄프 거인. Klabin은 paper 통합, Suzano는 시장 펄프 중심.
4. **Olinkraft / Sack Kraft S.A.**: 1958년 Monte Alegre의 원래 이름. legacy 라벨일 가능성.

---

## 14. INSERT SQL 템플릿

```sql
INSERT INTO paper_mills (...)
VALUES
(
    {Klabin_HQ_company_id},
    'Ortigueira (Puma)',
    'brazil',
    ARRAY['BEK Pulp', 'BSK Pulp', 'Fluff Pulp', 'Eukaliner® (kraftliner)', 'Paperboard'],
    1500000,  -- pulp only; paper 추가
    'active',
    'Klabin',
    'A',
    'https://klabin.com.br/en/nossa-essencia/onde-estamos',
    '2016 Puma I 가동 (USD 8.5B). 2021-08 Puma II MP27 Eukaliner kraftliner (450kt). 2023 MP28 paperboard (460kt). 세계 최초 hardwood+softwood+fluff 통합 mill.'
);
```

---

## 15. 매핑 우선순위

1. paper_companies 'Klabin' family CSV → tier 매핑 (HQ 1개 + Argentina 1개 정도)
2. paper_mills 'Klabin' family CSV → Puma/Monte Alegre/Correia Pinto/Otacílio Costa 정규화
3. Eukaliner® product 표기 확인 (Puma II MP27 only)
4. legacy "Olinkraft" 라벨 통합 (Monte Alegre = Olinkraft)

---

## 16. Tier 1 출처

| 출처 | URL |
|---|---|
| Klabin IR | https://klabin.com.br/en/investidores |
| 공식 mill 목록 | https://klabin.com.br/en/nossa-essencia/onde-estamos |
| 타임라인 | https://klabin.com.br/en/nossa-essencia/memoria-klabin/linha-do-tempo |
| ANDRITZ Puma 보도 | https://www.andritz.com/spectrum-en/klabin-puma-mill-a-pulp-and-papermakers-dream |

---

**END — Klabin Family Reference**
