# Family Reference 사용 가이드 (v5.7 autonomous output — 확장판)

**작성일**: 2026-05-15  
**작업**: 2회 autonomous 세션 (각 약 1시간) — 총 12개 reference document 작성  
**용도**: URM Platform Industry UI v5.8+ family 정리 (Step A-2)  
**컨텍스트**: handoff v5.7의 미해결 항목 #42 — Sappi 외 11 family 정리 진입 전 사전 리서치

---

## 작성 동기

YunYoung이 1시간 휴식 동안 Claude가 자동으로 할 수 있는 일을 요청. Claude는 Supabase 직접 접근 불가 → SQL 결과 받기 전에는 매핑 작업 불가능. 따라서 **다음 세션 효율 극대화**를 목표로 family 공개 자료를 사전 리서치하여 reference document를 빌드함.

이 reference들은 SQL CSV 결과와 결합하면 매핑 SQL을 **15-30분 내** 생성할 수 있도록 설계됨.

---

## 파일 목록 (12개 문서, 총 ~60,000+ 자)

| 파일 | family | 우선순위 | 예상 row 수 | 핵심 구조 변화 |
|---|---|---|---|---|
| `00_README_사용가이드.md` | (이 파일) | — | — | 인덱스/워크플로 |
| `01_mondi_reference.md` | Mondi plc | 세션 +1 | 43 | 2024 Hinton CA 인수, Stambolijski BG 화재 폐쇄, Schumacher 인수 |
| `02_stora_enso_reference.md` | Stora Enso Oyj | 세션 +2 | 24 | 2025-07 7-division 재편, Oulu 신규 line |
| `03_upm_reference.md` | UPM-Kymmene Oyj | 세션 +2 | 26 | 2023 Paso de los Toros startup, Leuna biorefinery 2024 |
| `04_smurfit_westrock_reference.md` | Smurfit Westrock plc | 세션 +3 | 26 | **2024-07 Smurfit Kappa + WestRock 합병** + 9+ 폐쇄 |
| `05_metsa_reference.md` | Metsä Group | 세션 +3 | 8 | 2023 Kemi Bioproduct mill startup |
| `06_fedrigoni_reference.md` | Fedrigoni S.p.A. | 세션 +3 | 9 | Mohawk(2024), Arjowiggins China(2024) 인수 |
| `07_international_paper_reference.md` | International Paper | **세션 +4 (최대 규모)** | 추정 50+ | **2025-01 DS Smith 인수 + 2026-01 두 회사 분할 발표** |
| `08_suzano_reference.md` | Suzano S.A. | 세션 +5 | 추정 15-20 | 2024-07 Cerrado mega-mill startup, 2024 Pine Bluff 인수, 2025 K-C JV |
| `09_klabin_reference.md` | Klabin S.A. | 세션 +5 | 추정 10-15 | 2021-23 Puma II MP27/MP28 (Eukaliner) startup |
| `10_oji_holdings_reference.md` | Oji Holdings | 세션 +6 | 추정 30+ | 99 sites Japan, 2024 Walki 인수, NZ Kinleith paper 폐쇄 |
| `11_nine_dragons_reference.md` | Nine Dragons Paper | 세션 +6 | 추정 20+ | 23M tpa 세계 최대, 2018 ND Paper(USA) 인수, virgin fiber 전환 |
| `12_cross_family_normalization_patterns.md` | 횡단 정규화 가이드 | **모든 세션 참조** | — | #15/#20/#23/#33 패턴 종합 |

**총 row 커버**: 약 250-300 row (Sappi 13 row v5.7에서 이미 처리됨, 합쳐서 12 family 완전 커버)

---

## 각 reference 공통 구조 (16개 섹션)

모든 family reference는 동일 패턴:

1. 그룹 정보 (HQ, 상장, 매출, 직원)
2. Business segments / divisions
3. Regional tier 후보 매핑
4. 활성 mill 목록 (도시 + 국가 + 제품)
5. 폐쇄/매각 mill (status 정정)
6. 5-year corporate events 타임라인
7. tier_role 매핑 가이드 SQL
8. mill_name 정규화 후보 (#20)
9. multi-region rollup split 후보 (#23)
10. compound entity 정책 (#15)
11. headquarters 정정 후보 (#33)
12. evidence_level + source_url 추천
13. Risk / Caution 항목
14. 누락 row INSERT SQL 템플릿
15. 매핑 우선순위 (작업 순서)
16. Tier 1 출처 목록

---

## 다음 세션 작업 권장 분배 (6 세션, 각 ~30분 내)

### Session +1: Mondi (43 row, 단독, 최대 규모 European family)
- 참조: `01_mondi_reference.md` + `12_cross_family_normalization_patterns.md`
- 특별 주의: Hinton CA (2024 인수), Stambolijski BG (2024-10 화재 폐쇄), DS Smith는 IP family (Mondi 아님)

### Session +2: Stora Enso + UPM (24 + 26 = 50 row, 핀란드/스웨덴 묶음)
- 참조: `02_stora_enso_reference.md` + `03_upm_reference.md` + `12`
- 특별 주의: 도시 동음이의 (Joutseno, Lohja, Kemi, Rauma는 둘 다 사용)

### Session +3: Smurfit Westrock + Metsä + Fedrigoni (26 + 8 + 9 = 43 row)
- 참조: `04_smurfit_westrock_reference.md` + `05_metsa_reference.md` + `06_fedrigoni_reference.md` + `12`
- **특별 주의**: Smurfit Kappa + WestRock 2024-07-05 합병 — 가장 큰 정정 필요

### Session +4: International Paper (추정 50+ row, 가장 복잡)
- 참조: `07_international_paper_reference.md` + `12`
- **특별 주의**: 
  - DS Smith 인수 (2025-01) — DS Smith family를 IP에 통합
  - 2026-01 분할 발표 — 현재 단일 family로 두되 notes 표기
  - Sylvamo (2021 spin-off) → IP family 아님
  - GCF (Global Cellulose Fibers) 매각 진행 중

### Session +5: Suzano + Klabin (브라질 1위·2위 묶음)
- 참조: `08_suzano_reference.md` + `09_klabin_reference.md` + `12`
- 특별 주의: 
  - Fibria legacy 라벨 → Suzano family로 통합 (2019 합병)
  - Olinkraft legacy → Klabin Monte Alegre로 통합
  - 두 회사 혼동 금지 (Suzano = 시장 펄프, Klabin = paper 통합)

### Session +6: Oji Holdings + Nine Dragons (아시아 2개 거인)
- 참조: `10_oji_holdings_reference.md` + `11_nine_dragons_reference.md` + `12`
- 특별 주의:
  - Oji는 다층 tier (5 사업 법인 + Regional + Country) — 가장 복잡한 구조
  - Jujo Paper 라벨 → **Nippon Paper로 이동** (Oji 아님)
  - Nine Dragons HQ = Dongguan (Hong Kong 아님, HKEX 상장지일 뿐)

---

## 다음 세션 시작 프롬프트 (template, copy 가능)

```
v5.7 handoff + autonomous reference 첨부합니다. v5.8 Step A-2 — {FAMILY_NAME} family 정리 진입.

[v5.7 handoff 파일]
[해당 family reference .md 파일]
[12_cross_family_normalization_patterns.md]  ← 필수 (공통 패턴)
[Supabase SQL 쿼리 1 결과 CSV — paper_companies WHERE family_group='{FAMILY_NAME}']
[Supabase SQL 쿼리 2 결과 CSV — paper_mills WHERE family_group='{FAMILY_NAME}']

작업 요청:
1. CSV 결과와 reference §4(companies) + §5(mills) 매칭
2. tier_role 일괄 채움 SQL 생성 (HQ/Regional/Country)
3. mill_name 정규화 SQL (§8 + cross-family §2 적용)
4. closed/divested 라벨 추가 SQL (§5 + §6 적용)
5. 누락된 row INSERT SQL (§14 + §15 적용)
6. evidence_level + source_url 채움 SQL (§11 + §12 적용)
7. headquarters 메모 정정 SQL (§11 + cross-family §1 적용)
8. multi-region rollup 분리 SQL (cross-family §3 적용)
9. compound entity 분리 SQL (cross-family §4 적용)
10. 최종 통합 마이그레이션 스크립트 (Supabase SQL Editor에 paste 가능)
11. 실행 후 검증할 화면 시뮬레이션 (예상 row 수, tier 색깔 분포)

산출물: 한 번에 paste할 수 있는 마이그레이션 SQL + 검증 체크리스트
```

---

## Supabase 쿼리 템플릿 (handoff v5.7 §B 보완)

각 family 진입 전 다음 쿼리들로 데이터 추출:

### Query 1: paper_companies — family 그룹의 모든 row
```sql
select id, name, tier_role, country, headquarters, 
       parent_company_id, family_group, evidence_level, 
       source_url, notes, segment, main_products, 
       capacity_metric_tons_per_year, status
from industry.paper_companies
where family_group ilike '%{FAMILY_NAME}%'
   or name ilike '%{FAMILY_NAME}%'
order by tier_role nulls last, name;
```

### Query 2: paper_mills — family의 모든 mill
```sql
select pm.id, pm.mill_name, pm.country, 
       pm.main_products, pm.capacity_metric_tons_per_year,
       pm.status, pm.evidence_level, pm.source_url, pm.notes,
       pc.name as company_name, pc.tier_role, pc.headquarters
from industry.paper_mills pm
left join industry.paper_companies pc on pc.id = pm.paper_company_id
where pm.family_group ilike '%{FAMILY_NAME}%'
   or pc.family_group ilike '%{FAMILY_NAME}%'
   or pc.name ilike '%{FAMILY_NAME}%'
order by pc.tier_role nulls last, pm.country, pm.mill_name;
```

### Query 3 (handoff v5.7 §D — 미커버 family 식별)
```sql
-- 가장 row 수가 많은 paper_company 묶음 식별
select 
  coalesce(family_group, name) as family_name,
  count(*) as company_count,
  (select count(*) from industry.paper_mills pm 
   where pm.family_group = coalesce(pc.family_group, pc.name)) as mill_count
from industry.paper_companies pc
group by coalesce(family_group, name)
order by mill_count desc nulls last
limit 30;
```

이 결과로 reference에 없는 추가 family 식별 가능.

---

## 11 family 횡단 핵심 패턴 (cross-family 문서 §11 체크리스트 요약)

다음 체크리스트는 모든 family에 공통 적용:

- [ ] HQ row 정확히 1개 (도시, 국가 정확 — 회사 메모/상장 정보 침입 없음)
- [ ] Regional row 수가 reference §3과 일치
- [ ] Country row 수가 reference §3과 일치
- [ ] tier_role 색상 (HQ 🟣, Regional 🔵, Country 🟢) 매핑 정확
- [ ] family_group 컬럼 모든 row 동일 표기 (혼용 없음)
- [ ] mill_name이 city 수준 (광역주/국가 단위 없음)
- [ ] headquarters 컬럼이 도시+국가 형식
- [ ] 폐쇄 mill status='closed', sold mill 별도 처리
- [ ] 합병 legacy 라벨 (Fibria, Honshu, M-real 등) 통합 완료
- [ ] evidence_level 모든 row 채워짐
- [ ] source_url 핵심 row에 채워짐

---

## 12 family 횡단 corporate event 타임라인 (참조용)

### 2020
- COVID-19 → newsprint/UFP demand 급감
- UPM Kaipola, Stora Enso 일부 closure 시작

### 2021
- Stora Enso Veitsiluoto + Kvarnsveden 영구 폐쇄 (핀란드+스웨덴)
- IP Sylvamo spin-off 완료
- Klabin Puma II MP27 (Eukaliner) 가동
- 중국 RCP 수입 금지 시행 (Nine Dragons 큰 영향)

### 2022
- **Russia 자산 일괄 매각/철수** (Stora Enso, UPM, Mondi, Metsä 모두)
- 핀란드+스웨덴 paper 매각 announce (Stora Enso 4 mill 등)
- Suzano Kimberly-Clark Brazil tissue 인수
- Klabin Puma II 확장
- Nine Dragons virgin cartonboard 본격 전환

### 2023
- Mondi Duino (IT) 인수 (Burgo에서)
- UPM Paso de los Toros (UY) startup
- Metsä Kemi Bioproduct mill startup
- Klabin Puma II MP28 가동

### 2024
- **Smurfit Kappa + WestRock 합병** (7/5)
- Mondi Hinton (CA) 인수
- Mondi Stambolijski (BG) 화재 폐쇄
- Fedrigoni Mohawk (US) + Arjowiggins China 인수
- Oji Holdings Walki Holding Oy (FI) 인수
- **Suzano Cerrado mega-mill startup** (7/21) + Pine Bluff (10/1) 인수
- IP Georgetown SC 폐쇄

### 2025
- **IP DS Smith 인수 완료** (1/31)
- IP Riceboro + Savannah 폐쇄
- IP 5 EU box plants → PALM 매각
- Smurfit Westrock 9+ closure
- Stora Enso 7-division 재편 (Jul) + Oulu 신규 line
- Oji Fibre Solutions Kinleith paper 폐쇄 (NZ)
- UPM Ettringen 발표 (legal dispute)
- Suzano K-C Global Tissue JV 발표 (6월)
- Mondi Schumacher 인수 (3월)

### 2026 (현재)
- **IP 두 회사 분할 발표 (1/29)** — NA IP + EMEA Packaging (12-15개월 일정)
- Smurfit Westrock SSK Birmingham UK 협의 (5월)

---

## 작업 결과 요약

| 항목 | 수치 |
|---|---|
| 총 reference 파일 수 | 12 (11 family + 1 cross-family + 1 README) |
| 총 문서 자수 | ~60,000+ 자 (한국어 + SQL + URL) |
| 작업 시간 | 2회 autonomous 세션 (각 ~1시간) |
| 커버 family | 12개 (Sappi + 11 family 전체) |
| Tier 1 출처 활용 | 회사 IR / 10-K(SEC) / Annual Report / 공식 mill location pages |
| Tier 2 출처 | Fastmarkets, EUWID, Packaging Dive, PaperAge, Wikipedia |
| 작성 일자 | 2026-05-15 |

**예상 효율 향상**: 다음 세션 매핑 SQL 작성 시간을 **CSV 받은 후 15-30분 내** 완료 (사전 리서치 없으면 2-3시간 소요).

---

## 사용 안내

1. **시작**: 위 "다음 세션 작업 권장 분배" 표에서 다음 작업할 family 선택
2. **준비**: 해당 family `.md` + `12_cross_family_normalization_patterns.md` + v5.7 handoff 첨부
3. **데이터**: Supabase에서 위 Query 1/2 실행 → CSV 첨부
4. **요청**: 위 "다음 세션 시작 프롬프트" template 사용
5. **검증**: handoff v5.7 §C/§D 검증 화면 (예: `/industry/paper-mills?search=mondi`)
6. **커밋**: 성공 시 v5.8 Step A-2.{family순번} 으로 git commit

---

**END — README**
