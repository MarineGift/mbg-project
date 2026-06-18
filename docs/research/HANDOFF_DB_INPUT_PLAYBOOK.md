# 핸드오프 — Paper Mill / Filler 공급관계 DB 입력 플레이북

최종 갱신: 2026-06-17 / 작성 맥락: Omya·SMI 거래 제지사 데이터 보강 작업
대상 DB: Supabase `ogenmrgxwhpbfepeldqx`, ORG `b25de8f2-1020-482f-9012-183f63883169`
이 문서 하나로 다음 세션에서 **바로 이어서 데이터 입력**을 진행할 수 있게 정리함.

---

## 0. 가장 중요한 것 (먼저 읽기)

1. **`industry.*` 스키마는 라이브에 없다.** `sql/020~022_industry_*.sql`은 설계만 됐고 SQL Editor에서 실행된 적 없음. 절대 타깃으로 쓰지 말 것. 제지사·공급사·공급관계는 모두 **`app.*`** 에 있다.
2. **컬럼명은 반드시 `information_schema`로 확인 후 INSERT를 작성한다.** 옛 시드/구 스키마(d3-archive)의 컬럼명과 라이브가 다르다:
   - `app.parties` 이름 컬럼 = **`party_name`** (옛 `name` 아님). `module`/`legal_name`/`tier` 없음. 타입은 **`party_type_id smallint`** (→ `app.party_types`).
   - `app.party_supply_links`에는 **`supply_type` 컬럼이 없다.** 상태는 **`link_type`(text)** 에 넣는다. (enum `app.supply_link_type`는 존재하지만 이 컬럼의 타입이 아님.)
3. **마이그레이션은 SQL Editor에서 수동 실행.** repo push는 파일 기록일 뿐 DB에 반영되지 않는다. 새 .sql을 만들면 항상 "SQL Editor에서 실행" 명시.
4. **공급사 위치 변형명 ≠ 거래 증거.** DB의 `Specialty Minerals (USA - Escanaba MI)` 같은 변형이 있어도, **Escanaba의 on-site PCC는 실제로 Omya**다(2013). 위치 이름만 보고 mill↔filler를 자동 연결하면 틀린다. **모든 링크는 1차 출처로 검증 후 입력.**
5. **일부 SM 변형은 제지사 satellite가 아니라 SM 자체 광산/가공소**다: `Barretts MT`, `Lucerne Valley CA`, `Ste. Genevieve MO`, `Adams MA`, `Canaan CT` 등. 이런 건 mill에 연결하지 말 것.

---

## 1. 데이터 모델 (라이브 확정)

### `app.parties` (제지사·공급사 공통 엔티티)
주요 컬럼: `id uuid`, `party_type_id smallint`(FK→party_types), `party_name text`, `country_code`, `region`, `city`, `address`, `website`, `domain_normalized`, `email`, `linkedin_url`, `founded_year`, `employee_count`, `annual_revenue_usd`, `status text`, `source text`, `notes text`, `interest_tags jsonb`, `industry_tag_id smallint`, `entity_type_id smallint`, `intro_ko/intro_en text`, `organization_id uuid`, `created_at/updated_at/deleted_at`.

`app.party_types` 코드→id:
| id | code | | id | code |
|---|---|---|---|---|
| 1 | investor | | 6 | partner |
| 2 | **paper_mill** | | 7 | government_grant |
| 3 | **filler_supplier** | | 8 | consultant |
| 4 | buyer | | 9 | crowdfunding_platform |
| 5 | customer | | 10 | self |

- 제지사 = `party_type_id = 2` (paper_mill). 라이브에 약 600+ 등록됨(글로벌). 다수가 `Company - Site (City)` 형태의 plant 단위 행도 포함.
- 공급사(Omya/SMI/Imerys 등) = `party_type_id = 3` (filler_supplier). Omya는 국가별 변형, **Specialty Minerals는 국가 + plant 단위 변형**까지 등록됨(예: `Specialty Minerals (India - Rayagada)`).

### `app.party_supply_links` (★ mill ↔ filler 공급관계 = 이번 작업의 핵심 테이블)
컬럼: `id uuid`, `mill_party_id uuid`(제지사), `filler_party_id uuid`(공급사), `organization_id uuid`, `link_type text`, `product_grade text`, `volume_estimate text`, `confidence text`, `active_since date`, `active_until date`, `notes text`, `extra_data jsonb`, `created_at/updated_at/deleted_at`.
- **`link_type` 값**(앱 UI `SUPPLY_TYPES` 기준): `active` / `potential` / `pilot` / `historical`. ← 여기에 공급 상태를 넣음.
- satellite/on-site/near-site 같은 **구조 구분은 컬럼이 없으므로** `extra_data.link_kind`(예: `pcc_satellite`/`pcc_onsite`/`pcc_nearsite`)와 `notes`에 보존.
- `confidence`도 text (`high`/`medium`/`low`).
- 앱 POST 허용 컬럼(참고): `filler_party_id, mill_party_id, organization_id, link_type, product_grade, confidence, active_since, active_until, volume_estimate, notes, extra_data`.
- 소프트삭제: `deleted_at`.

### `app.paper_mill_profile` (제지사 프로필 확장 — 2차 보강 대상)
컬럼: `id uuid`, `party_id uuid`, `organization_id uuid`, `main_product_category text`, `main_products text`, `headquarters text`, `filler_use_intensity text`, `europe_mills_footprint text`, `evidence_level text`, `industry_source text`, `extra_data jsonb`, `auto_promoted_at`, `created_at/updated_at/deleted_at`. (party당 1행, party_id로 연결.)

---

## 2. 표준 작업 절차 (매 배치 반복)

1. **진단(읽기전용)**: SQL Editor에서 아래 캐논 쿼리 실행 → 컬럼·enum·대상 party UUID 확보. 결과 Export(CSV) 또는 붙여넣기로 공유. (스키마가 바뀌었을 수 있으니 **항상 컬럼 재확인**.)
2. **검증**: 넣을 mill↔filler 관계를 **1차 출처**(제조사 보도자료, SEC 8-K, 제지사/공급사 공식)로 확인. 위치명 추정 금지.
3. **작성**: 확보한 **실제 UUID**로 idempotent INSERT (CTE VALUES 패턴, 아래 템플릿).
4. **적용**: SQL Editor에서 실행 → VERIFY 쿼리로 확인.
5. **기록**: mover로 Downloads→repo 이동(.sql→`supabase/migrations/`, .md→`docs/research/`), finish block(`git add`→`status -sb`→`commit`→`push origin marinebiogroup`). push는 기록일 뿐, **반영은 1·4단계의 SQL Editor 실행**.

### 진단 캐논 쿼리 (한 표로 반환)
```sql
SELECT * FROM (
  SELECT 1 ord,'party_types' section, pt.id::text c1, pt.code c2, NULL::text c3, NULL::text c4, NULL::text c5 FROM app.party_types pt
  UNION ALL
  SELECT 2,'supply_link_type_enum', e.enumlabel,NULL,NULL,NULL,NULL FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid WHERE t.typname ILIKE '%supply%link%'
  UNION ALL
  SELECT 3,'party_supply_links_cols', column_name, data_type,NULL,NULL,NULL FROM information_schema.columns WHERE table_schema='app' AND table_name='party_supply_links'
  UNION ALL
  SELECT 4,'paper_mill_profile_cols', column_name, data_type,NULL,NULL,NULL FROM information_schema.columns WHERE table_schema='app' AND table_name='paper_mill_profile'
  UNION ALL
  SELECT 5,'suppliers', p.id::text, p.party_name, pt.code, p.country_code, p.status
    FROM app.parties p JOIN app.party_types pt ON pt.id=p.party_type_id
    WHERE p.organization_id='b25de8f2-1020-482f-9012-183f63883169' AND p.deleted_at IS NULL
      AND (p.party_name ILIKE 'omya%' OR p.party_name ILIKE 'specialty mineral%'
           OR p.party_name ILIKE 'minerals technolog%' OR p.party_name ILIKE 'imerys%')
  UNION ALL
  SELECT 6,'paper_mills', p.id::text, p.party_name, pt.code, p.country_code, NULL
    FROM app.parties p JOIN app.party_types pt ON pt.id=p.party_type_id
    WHERE p.organization_id='b25de8f2-1020-482f-9012-183f63883169' AND p.deleted_at IS NULL
      AND pt.code='paper_mill'
) z ORDER BY ord, c2;
```
(특정 제지사만 찾을 땐 section 6에 `AND p.party_name ILIKE '%키워드%'` 추가.)

### INSERT 템플릿 (party_supply_links, idempotent·reversible)
```sql
BEGIN;
WITH rel(mill_id, filler_id, link_kind, product_grade, volume_estimate, confidence,
         active_since, evidence_url, src, structure, label) AS (
  VALUES
  ('<mill_uuid>'::uuid,'<filler_uuid>'::uuid,'pcc_satellite','PCC filler-grade','~XX,000 mt/yr','high','YYYY-01-01'::date,'<url>','<source>','on-site satellite PCC','<mill> - <site>')
  -- ... more rows
)
INSERT INTO app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, notes, extra_data, created_at, updated_at)
SELECT gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169',
  r.mill_id, r.filler_id, 'active',
  r.product_grade, r.volume_estimate, r.confidence, r.active_since,
  r.label || ' | ' || r.structure || ' | src: ' || r.src,
  jsonb_build_object('evidence_url',r.evidence_url,'supply_structure',r.structure,
    'link_kind',r.link_kind,'source',r.src,'batch','<batch_tag>','researched_at','2026-06-17'),
  now(), now()
FROM rel r
WHERE NOT EXISTS (SELECT 1 FROM app.party_supply_links x
  WHERE x.mill_party_id=r.mill_id AND x.filler_party_id=r.filler_id AND x.deleted_at IS NULL);
COMMIT;
```
- **idempotent**: `NOT EXISTS (mill, filler, deleted_at IS NULL)`.
- **reversible**: `UPDATE ... SET deleted_at=now() WHERE extra_data->>'batch'='<batch_tag>'`.
- 폐쇄/종료된 관계는 `link_type='historical'`로.

### 제지사/공급사 party 신설이 필요할 때
대상 mill/filler가 없으면 `app.parties`에 먼저 INSERT (그 뒤 supply_link). 최소 컬럼:
```sql
INSERT INTO app.parties (id, organization_id, party_type_id, party_name, country_code, region, city, website, status, source, notes, created_at, updated_at)
VALUES (gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169', 2 /*paper_mill*/, '<name>', '<CC>', '<region>', '<city>', '<url>', 'active', 'industry-research', '<note>', now(), now());
```
중복 방지: `WHERE NOT EXISTS (... lower(party_name)=lower('<name>') AND party_type_id=2 AND deleted_at IS NULL)`로 감쌀 것. (filler 신설 시 party_type_id=3.)

### 파일/PowerShell 컨벤션 (기존 규칙 그대로)
- 산출물: 다운로드 → ASCII 전용 PS mover로 `$env:USERPROFILE\Downloads` → repo 경로 이동(`New-Item -Force`, `Unblock-File`, `Move-Item -Force`, 영어 콘솔). 이어서 finish block(`git add`→`git status -sb`→`commit`→`git push origin marinebiogroup`).
- .md는 UTF-8 BOM(한글). .ps1·콘솔 출력·SQL은 ASCII.
- 새 .sql은 SQL Editor 실행 필수(“push만으로 미반영”) 명시.

---

## 3. 진행 현황 (배치 로그)

| 배치 | tag (`extra_data.batch`) | 건수 | 파일 |
|---|---|---|---|
| Batch 1 | `omya_smi_batch1` | 14 (SMI 12 + Omya 2) | `20260617150000_app_party_supply_links_omya_smi_batch1.sql` |
| Batch 2 | `omya_smi_batch2` | 4 (SMI 3 + Omya 1) | `20260617160000_app_party_supply_links_omya_smi_batch2.sql` |
| Batch 3 | `omya_smi_batch3` | 3 (SMI 3) | `20260617170000_app_party_supply_links_omya_smi_batch3.sql` |
| Batch 4 | `omya_smi_batch4` | 14 (SMI 14) | `20260617180000_app_party_supply_links_omya_smi_batch4.sql` |

폐기: `20260617140000_industry_*` (industry.* 참조, 실행 불가 — 제거 권장).

**Batch 1 (14)**: JK Paper-Rayagada, Sabah Forest-Sipitang, West Coast-Dandeli, BILT-Ballarshah, BILT Sewa-Gaganapur, Phoenix Paper-Wickliffe, Century-Lalkuan, Suzano-Mucuri, Phoenix Pulp-Nam Phong, ABC Paper-Saila Khurd, Zhumadian Baiyun-Suiping, International Paper(company, 8 plants), Domtar Nekoosa-Omya(on-site), Domtar Rothschild-Omya(near-site).

**Batch 2 (4)**: Billerud Escanaba-Omya(on-site, 2013), Andhra Paper Rajahmundry-SM(2024, NewYield LO), Nine Dragons Beihai-SM(2024), Zhejiang Zhefeng Quzhou-SM(2024).

**Batch 3 (3)**: Gold East Paper=APP Dagang-SM(active), Gold Huasheng=APP Suzhou-SM(active), Consolidated Papers Wisconsin Rapids-SM(historical; MTI first satellite 1986).

**Batch 4 (14, MTI 2006 10-K Item 2)**: Sylvamo Ticonderoga, Gold East Zhenjiang, PT Indah Kiat Perawang 1&2, Nippon Paper Shiraoi, Mondi Merebank(Durban), Double A/Advance Agro Tha Toom, Navigator Figueira da Foz, Sylvamo Saillat, Metsa Board Aanekoski, Mondi SCP Ruzomberok, UPM Schongau, Suzano(SP) -- all active; Pixelle Androscoggin/Jay ME -- historical(closed 2023). Mills mapped to CURRENT owner; 2006 customer in extra_data.principal_customer_2006.

---

## 4. 다음 작업 백로그 (검증 후 입력)

### 검증 필요한 고확률 후보 (위치 추정 — 반드시 1차 출처 확인)
- ~~APP China Dagang / Suzhou~~ **완료(batch3)**: Dagang=Gold East Paper, Suzhou=Gold Huasheng Paper로 매핑(신설 불필요).
- **JK Paper Songadh** (`JK Paper - Unit CPM (Songadh)`) ↔ SM `India - Songadh` — JK 2nd mill. satellite 여부 1차 출처 확인 필요.
- 미국 SM satellite-at-mill (소유 변동·가동상태 확인 필수, active vs historical 주의):
  - 남은 미국 satellite(party·SM변형 매칭 + 상태확인 필요): SM `USA - Rumford ME` ↔ ND Paper Rumford / SM `USA - Biron WI` ↔ ND Paper Biron / SM `USA - Spring Grove PA` ↔ Pixelle Spring Grove. (Ticonderoga·Jay·Wisconsin Rapids는 완료.)
- 유럽 SM 변형(Finland Lappeenranta/Oulu/Tervakoski/Äänekoski, France Saillat/Arches, Germany Stockstadt, Sweden Hallstavik, UK Kemsley, Portugal Figueira da Foz 등) ↔ 인접 mill.
- **권장 방법(적용중)**: MTI 10-K **Item 2 'Properties'**(satellite 위치+주고객사)가 1차 출처. batch4가 2006 10-K(node/12751/html, 51개 satellite)에서 추출. **다음**: 최신 10-K의 Properties를 fetch해 (a) 2006 이후 신규 satellite 추가, (b) 현재 가동/폐쇄로 active↔historical 갱신.
- **2006 10-K 잔여 satellite(미입력 — party 또는 SM변형 부재/상태확인 필요)**: US Courtland/Selma/Pensacola/Eastover/Franklin(IP), Jackson/Intl Falls/Wallula(Boise), Port Hudson/Camas(GP), Madison(closed)/Millinocket(Katahdin,closed)/Quinnesec(Verso)/Plymouth(Weyerhaeuser)/Chillicothe(Glatfelter)/West Carrollton(Appleton)/Cloquet(Sappi)/Kimberly(Stora,closed)/Park Falls(Flambeau)/Longview(Weyerhaeuser)/Ashdown(Domtar); Canada Dryden/St-Jerome/Windsor; Brazil Jacarei/Luiz Antonio(VCP→Suzano/Sylvamo); Finland Anjalankoski/Tervakoski; France Alizay/Docelles(closed); Mexico Chihuahua(Copamex); Poland Kwidzyn(→MM). 대부분 mill party는 있으나 전용 SM 변형이 없거나 상태확인 필요.
- **Omya 추가 on-site**: Finch Paper(Glens Falls NY — mill party 없음, 신설 필요), 구 J.M. Huber on-site PCC(2005 Omya 인수, mill별 확인), 유럽 Omya PCC(Austria Golling 등).

### 절대 연결 금지 (제지사 satellite 아님 = SM 자체 광산/가공)
`Barretts MT`, `Lucerne Valley CA`, `Ste. Genevieve MO`, `Adams MA`, `Canaan CT`, `Regional HQ`, `Global - PCC`, `HQ` 등.

### 2차 보강 (선택)
- `app.paper_mill_profile` 채우기(연결된 제지사의 filler_use_intensity, main_products, evidence_level, industry_source) — party_id 기준 UPSERT(기존 값 보존: 신규 행만 INSERT 권장).
- Imerys / Schaefer Kalk / Carmeuse 등 다른 filler_supplier로 확장.

### 참고 통계 (MTI/SMI)
SMI satellite 전세계 ~55–70개(시기별), 인도 8개 plant(322 KTPA). MTI 최대 고객은 International Paper. Omya는 50+개국, on-site/near-site PCC 다수(유럽 강세). 신규 발표는 MTI investors.mineralstech.com / GLOBE NEWSWIRE, 업계 Papermart·Paperadvance·PulpaperNews에서 추적.
