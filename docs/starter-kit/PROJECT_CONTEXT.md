# PROJECT_CONTEXT — URM Platform (mbg-project)

> **버전:** 2026-05-19
> **이 문서의 용도:** 새 Claude 세션이 비즈니스 맥락 + 의사결정 기준 + 작업 관행을 한 번에 파악.
> **읽는 순서:** NEXT_SESSION_KICKOFF.md → **이 문서** → DB_SCHEMA_REFERENCE.md → SCHEMA_GOTCHAS.md → safe_insert_templates.sql

---

## 1. 사업 컨텍스트

### 1.1 무엇을 하는가
- **제품:** Paper filler 기술 (calcium carbonate 기반 — GCC / PCC / hybrid). 종이 제조 공정에 들어가는 충전재.
- **단계:** Fundraising 준비 중. US 투자자 대상 outreach 계획 수립 + 데이터베이스 구축.
- **목표:** B2B Relationship Management (URM) Platform — 투자자/파트너/고객/공급망 통합 관리. 현재 핵심은 **investor module**.

### 1.2 왜 이 DB 가 필요한가
1. 미국 climate/industrial VC 풀 체계화 (firm + 파트너 + portfolio)
2. 본 사업과 fit 높은 의사결정자 (DM) 식별
3. Outreach 우선순위 자동 계산
4. 향후 EU + 일본 확장 시 같은 구조 재사용

---

## 2. 지리적 fundraising 타깃 (확정)

| 단계 | 지역 | 상태 |
|------|------|------|
| 현재 | 🇺🇸 미국 only | 진행 중 |
| 향후 | 🇪🇺 EU | 미시작 |
| 향후 | 🇯🇵 일본 | 미시작 |
| **제외** | 🇰🇷 한국 | ❌ **확정 — 한국 VC 작업 일체 금지** |

→ web search 시 `site:linkedin.com US partners` / `american VC` 등 미국 한정 키워드 사용.
→ 한국 firm/파트너 발견해도 DB 적재 금지.

---

## 3. Fit 기준 — "direct fit" 의 정의

### 3.1 카테고리별 fit
**🟢 Direct fit (1순위 outreach):** 본 사업과 직접 인접한 분야 투자 history 가 있는 firm
- Paper/pulp 산업 직접 투자
- Sustainable packaging (paper-based 우선)
- Calcium carbonate 또는 mineral filler 관련
- Paper coatings (특히 Earthodic 같은 lignin/biomaterial)
- Recycling tech (paper recycling 우선)

**🟡 Adjacent fit (2순위):** 인접 영역
- Industrial / materials 일반
- Climate tech 중 manufacturing 측면
- CVC of paper/packaging buyers (P&G, 3M, Amazon, Walmart 등)

**🔴 Out-of-scope:**
- 순수 SaaS / consumer / fintech
- Crypto / Web3
- Biotech (단, paper 산업 byproduct 활용 biotech 는 예외 — Earthodic 같은 경우)

### 3.2 Direct-fit firm 풀 (9개 — 2026-05-19 기준)
1. **Closed Loop Partners** (16 portfolio, 6 DM) — circular economy + recycling
2. **Generate Capital** (15 portfolio, 5 DM) — sustainable infrastructure
3. **Amazon Climate Pledge Fund** — packaging buyer + climate
4. **P&G Ventures** — paper/packaging buyer CVC
5. **3M Ventures** — materials CVC
6. **Suzano Ventures** — paper industry direct (Brazilian giant)
7. **At One Ventures** — frontier industrial (portfolio 추가 보강 필요)
8. **Pangaea Ventures** — materials/chemicals
9. **Footprint Coalition** — sustainability focus

### 3.3 Strategic 발견 — Earthodic
**⭐⭐ Earthodic** (호주 biotech, Closed Loop 의 portfolio) — paper 산업 lignin 부산물로 paper packaging 용 water-resistant coating 개발. 본 사업과 **거의 완벽한 인접 fit**.

→ Closed Loop 의 6 DM 에게 outreach 시 "Earthodic 과 동일 카테고리" positioning 가능. 새 firm 검토 시 비슷한 angle 찾을 것.

---

## 4. 현재 DB 상태 (2026-05-19 기준)

### 4.1 데이터 규모
| 테이블 | rows | 비고 |
|--------|-----:|------|
| `app.parties` | 1,764 | 1,200+ 가 historical/dev data |
| `app.investor_profile` | 111 | US firm 풀 |
| `app.investor_partner_profile` | 119 | partners (90% 가 DM) |
| `app.portfolio_companies` | 342 | |
| `app.investor_portfolio_companies` | 445 | link |

### 4.2 Top 20 firm 별 파트너 수 (DM 수)

```
Generate Capital              7 (DM 5)
Energize Capital              7 (DM 6)
Eclipse Ventures              6 (DM 6)
Closed Loop Partners          6 (DM 6)
Energy Impact Partners        6 (DM 5)
Lowercarbon Capital           5 (DM 5)
Andreessen Horowitz           5 (DM 5)  ← a16z American Dynamism 포함
Ironspring Ventures           5 (DM 2)
At One Ventures               4 (DM 4)
Multicoin Capital             4 (DM 4)
Lux Capital                   4 (DM 4)
M12                           4 (DM 3)
KdT Ventures                  4 (DM 4)
G2 Venture Partners           3 (DM 3)
Galvanize Climate Solutions   3 (DM 2)
3M Ventures, Founders Fund, Khosla Ventures, The Engine, S3 Ventures  각 2
```

### 4.3 정성적 상태
- ✅ US firm 풀 (~111) 충분히 broad
- ✅ DM ratio 90% — 의사결정자 비율 높음
- ✅ Closed Loop / Generate portfolio 깊게 매핑 완료
- ⚠️ At One Ventures portfolio 보강 미완 (paper/material 위주 5-8개 추가 필요)
- ⚠️ CVC 추가 가능 (Walmart, PepsiCo, Coca-Cola, Unilever)
- ⚠️ Family offices 미적재 (Pritzker, Cascade/Gates, MSD, Walton)
- ⚠️ Outreach 1순위 명단 export 미완

---

## 5. 데이터 컨벤션 (이 패턴 따를 것)

### 5.1 명명 규칙
- **Firm 이름:** 공식 등록명 사용. "a16z" 가 아닌 `Andreessen Horowitz`. notes 에 약칭 언급 OK.
- **Person 이름:** "<First> <Last>". 미들네임 보통 생략 ("Mary Jane Smith" → "Mary Smith" 자제, 그대로 두는 게 안전).
- **회사명 normalization:** trigger 가 자동 처리 (parties), 또는 `LOWER(TRIM(name))` (portfolio_companies).

### 5.2 분류 어휘 (snake_case 표준)
**sector / sub_sector — 자유 텍스트지만 일관성 유지:**
- `sustainable_packaging`, `paper_coatings`, `recycling_tech`, `ai_sorting`
- `circular_consumer`, `refill_stations`, `recycling_operations`
- `plastic_recycling`, `pet_chemical`, `chemical_recycling`
- `battery_recycling`, `lithium_ion`, `biogas`, `organic_waste`
- `hydrogen`, `fuel_cells`, `green_compute`, `data_centers`
- `energy_storage`, `behind_meter`, `solar`, `distributed_solar`, `community_solar`
- `ev_charging`, `transportation`, `electric_buses`
- `fintech`, `solar_loans`, `electronics_recycling`, `e_waste`

**investment_stage — 표준 화폐 stage:**
- `pre_seed`, `seed`, `series_a`, `series_b`, `series_c`, `series_d`, `growth`, `late`, `public`
- 특수: `platform`, `project` (Generate 같은 infra)

**country_code:** ISO-3166 alpha-2 **대문자** (US, AU, CA, IL, CL, BR, JP, etc. — **KR 은 형식 예시 외 적재 금지**)

### 5.3 Notes 작성 가이드
- **언어:** 영어 (한국어 절대 사용 금지 in DB notes)
- **길이:** 1-3문장
- **내용 우선순위:** (1) 본 사업과 fit 있는 facts, (2) co-investors / 주요 client, (3) 차별점
- **예시 (좋음):**
  - `Lignin-based water-resistant repulpable coating for paper packaging. Uses pulp/paper industry byproduct. Direct adjacent fit for paper filler tech.`
  - `Hydrogen fuel cells for forklifts. NASDAQ:PLUG. Generate provided $25M loan + $25M sale-leaseback (Walmart counterparty).`
- **예시 (나쁨):**
  - `Good company` (정보 없음)
  - `회사 설명이 좋은 회사` (한국어)

### 5.4 Run label 명명 규칙
**패턴:** `<region>_<module>_<descriptor>_<period>`
- `us_vc_2026Q2_b` — US VC firm batch
- `us_vc_partners_2026Q2` — US VC partners batch
- `us_vc_partners_a16z_amdyn_2026Q2` — 특정 firm 의 partners
- `us_vc_paper_tx_specialty_2026Q2` — texas + paper specialty
- `us_vc_portfolio_depth_FINAL_2026Q2` — portfolio 보강

**룰:**
- snake_case, ASCII only
- `2026Q2` 같은 시간 marker 포함
- 같은 label 재실행 금지 (UNIQUE) — 재시도 시 `_b`, `_c` suffix 또는 `ingest.rollback_run` 사용

### 5.5 Sources 명시 (start_run 의 `p_sources`)
- URL + 날짜 형식: `'a16z.com/erin-price-wright 2024-04'`
- Podcast/article: `'mcj.vc inevitable podcast 2025-07'`
- Multiple sources OK: `ARRAY['source1', 'source2', 'source3']`

---

## 6. Web research 가이드

### 6.1 어디서 검색하나
| 정보 종류 | 1순위 출처 | 2순위 |
|----------|----------|------|
| Firm 기본 정보 | firm 공식 웹사이트 | Crunchbase 무료 |
| Partner 명단 | firm 의 `/team` 또는 `/people` 페이지 | LinkedIn |
| Partner 배경 | LinkedIn `/in/` | personal website / blog |
| Climate VC 인사이트 | MCJ podcast (mcj.vc) | Climate Insiders newsletter |
| Investment thesis | firm blog | TechCrunch, AxiosPro |
| Portfolio | firm `/portfolio` 페이지 | Pitchbook scrape (avoid — 유료) |
| Fund size / AUM | SEC EDGAR Form ADV | press release |

### 6.2 검증 원칙
- **2개 source 교차 확인** — 1개만 보이는 정보는 notes 에 `unverified` flag
- **Firm 웹사이트 우선** — LinkedIn 만 있는 partner 는 firm site 에 등재 여부 재확인
- **Title 정확성** — `General Partner` vs `Partner` vs `Principal` 구분 중요 (`partner_seniority` enum 매핑됨)
- **이메일 패턴 추정 시 명시** — `first.last@firm.com` 같은 패턴은 notes 에 명시, 검증된 직접 메일이 아니면 email 컬럼 비워둘 것

### 6.3 적재 의사결정 트리
```
1. 이 firm/partner 이 fit 기준 (Section 3) 충족하는가?
   NO → skip
   
2. DB 에 이미 있는가? (D1 diagnostic 쿼리)
   YES → ON CONFLICT 패턴으로 update
   NO → 신규 적재
   
3. 한국 관련인가?
   YES → skip (Section 2)
   NO → 진행
   
4. Source 가 2개 이상 있는가?
   NO → notes 에 unverified 표시
   YES → 정상 적재
```

---

## 7. 사용자 (User) 컨텍스트

### 7.1 익명 처리 정책 ⚠️
- 사용자는 **명시적으로 익명 처리 요청**
- 사용자 메모리 정책: `"anonymous individual without business affiliations or role context"`
- ✅ "YunYoung" 호칭 OK (이름 only)
- ❌ 회사명, 직책, role 추측 금지
- ❌ DB 에 사용자 본인 정보 적재 금지 (이전에 적재된 stub 은 cleanup 완료)

### 7.2 언어 / 톤
- **응답 언어:** 한국어 (영문 SQL 그대로 사용)
- **응답 톤:** 간결, 표 활용, 핵심만
- **포맷:** 표 + 핵심 요약 + 권장사항 → 사용자 선택
- **권장 + 옵션** 패턴: `ask_user_input_v0` 도구 활용해 명확한 선택지 제공
- 6시간 휴식 같은 명시적 시간 안내 시: 자동 작업 불가 솔직히 안내 (Claude 는 메시지 받을 때만 작동)

### 7.3 데이터베이스 조작 정책
- **항상 idempotent 패턴** — ON CONFLICT, WHERE NOT EXISTS
- **트랜잭션** — BEGIN/COMMIT 으로 묶어 전체 성공/실패
- **사전 검증** — D1-D6 diagnostic 쿼리 사용 (`safe_insert_templates.sql` 참고)
- **결과 보고** — 카운트 표 + 검증 쿼리 결과 분석

### 7.4 Helper 함수 우선 사용
- `ingest.upsert_portfolio_company` (portfolio 적재)
- `ingest.start_run / stage_rows_bulk / promote_*` (partner/investor 적재 표준)
- `ingest.rollback_run` (안전 롤백)
- ⭐ 직접 INSERT 작성 전 항상 helper 함수 존재 확인 (SCHEMA_GOTCHAS.md Section 0)

---

## 8. 잠재 이슈 / 미확정 사항

### 8.1 `module_type` enum 의 `investor_partner` 의문
- HANDOFF.md 에 `'investor_partner'::app.module_type` 사용 패턴 있음
- 현재 enum 정의에는 **`investor_partner` 없음** (investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier)
- **새 세션 시작 시 확인 권장:** `SELECT unnest(enum_range(NULL::app.module_type))` 실행
- 만약 enum 에 정말 없다면 partner 적재 시 `module='partner'` 사용

### 8.2 `public.tier_role` enum (HQ/Regional/Country/Plant)
- `parties.party_level` (3-tier: group_hq/country_entity/plant) 과 별개 4-tier 체계
- 현재 어느 컬럼에서 사용 중인지 불명 — 미사용 또는 향후 도입 예정 가능성

### 8.3 Yun Young Heo cleanup
- 이전 세션에서 사용자 본인이 잘못 적재된 stub 삭제 완료
- 새 세션에서 우연히 다시 적재되지 않도록 주의

---

## 9. Outreach Priority Scoring Rubric v1 (6 검증자 합의 — Scenario 3 보강)

Top N outreach 명단 추출 시 다음 가중치 사용. 결정론적 (deterministic) — 같은 데이터면 같은 결과.

### 9.1 Partner-level score (max 100)

| 기준 | 가중치 | 계산 |
|------|------:|------|
| Firm 이 direct_fit (Section 3.2 의 9개) | 30 | binary |
| Firm 이 adjacent_fit | 15 | binary (direct_fit 아닐 때만) |
| `is_decision_maker = true` | 25 | binary |
| seniority_level (founder=15, partner=12, principal=6, associate=3, advisor=2, other=0) | 0–15 | enum 매핑 |
| relationship_score (parties 컬럼) | 0–10 | `relationship_score / 10` |
| Paper/packaging fit portfolio 1+ 보유 (Earthodic 같은) | 10 | binary |
| LinkedIn URL 존재 (검증 가능) | 5 | binary |

### 9.2 SELECT 예시 (Phase 2 view 정의 받기 전 baseline)

```sql
WITH partner_scores AS (
  SELECT 
    pp.id, pp.party_id, pp.firm_party_id,
    p_partner.name AS partner_name,
    p_partner.linkedin_url,
    pp.title_text, pp.seniority_level, pp.is_decision_maker,
    p_firm.name AS firm_name,
    -- direct_fit firms
    (p_firm.name IN (
       'Closed Loop Partners','Generate Capital','Amazon Climate Pledge Fund',
       'P&G Ventures','3M Ventures','Suzano Ventures','At One Ventures',
       'Pangaea Ventures','Footprint Coalition'
    ))::int * 30 AS s_directfit,
    pp.is_decision_maker::int * 25 AS s_dm,
    CASE pp.seniority_level
      WHEN 'founder' THEN 15
      WHEN 'partner' THEN 12
      WHEN 'principal' THEN 6
      WHEN 'associate' THEN 3
      WHEN 'advisor' THEN 2
      ELSE 0
    END AS s_seniority,
    COALESCE(p_partner.relationship_score, 0) / 10 AS s_relationship,
    (p_partner.linkedin_url IS NOT NULL)::int * 5 AS s_linkedin
  FROM app.investor_partner_profile pp
  JOIN app.parties p_partner ON p_partner.id = pp.party_id
  JOIN app.parties p_firm    ON p_firm.id    = pp.firm_party_id
  WHERE p_partner.deleted_at IS NULL
)
SELECT 
  partner_name, firm_name, title_text, linkedin_url,
  (s_directfit + s_dm + s_seniority + s_relationship + s_linkedin) AS priority_score
FROM partner_scores
ORDER BY priority_score DESC
LIMIT 10;
```

→ Phase 2 (view 정의) 받은 후 `v_investor_outreach_list` 와 통합. 점수 가중치는 사용자 피드백 반영해 v2 조정.

### 9.3 Earthodic-like 검색 키워드 뱅크 (Claude 독립 검증 권고)

새 portfolio 회사 추가 시 다음 키워드 조합으로 검색:

| 카테고리 | 키워드 |
|---------|--------|
| Paper byproduct | lignin, kraft lignin, black liquor, pulp waste, cellulose nanofiber, hemicellulose |
| Coatings | repulpable coating, water-resistant paper, biocoating, MFC, NFC, barrier coating |
| Biomaterials | mycelium, seaweed-based packaging, bagasse, agricultural fiber, hemp pulp |
| Filler-adjacent | calcium carbonate, GCC, PCC, mineral filler, kaolin, talc replacement |
| Climate/circular | circular packaging, paper recycling tech, repulpable, compostable paper |
| Excluded | plastic-based (out of scope), consumer-only CPG (out of scope) |

### 9.4 Earthodic-like Fit Score (직관적 평가)

```
+3  Paper/pulp byproduct 직접 활용
+3  Paper packaging 또는 coating 직접 관련
+2  Recyclable / repulpable claim
+2  Mineral / filler / coating adjacency
+1  Existing direct-fit investor portfolio 에 등재
-3  Pure plastic / consumer-only
-5  Korea-related target  → 즉시 skip
```

총점 5+ → 적재 후보. 3-4 → 사용자 확인 후 결정. <3 → skip.

---

## 10. `module_type` 모델링 결정 (6 검증자 합의)

**확정 사항 (Phase 1 결론):**
- `app.module_type` enum 의 9개 값에 **`investor_partner` 없음** (06_enums.csv 직접 확인됨)
- HANDOFF.md 의 `'investor_partner'::app.module_type` 패턴은 **잘못된 표기로 추정** (실행 시 에러)
- 단, 새 세션 시작 시 KICKOFF Section 2 의 enum_range 쿼리로 **재확인 필수** (마이그레이션이 이후에 적용됐을 가능성 배제)

**권장 모델링 패턴:**

| 엔티티 | parties.module | parties.party_type | profile 테이블 |
|--------|---------------|-------------------|---------------|
| VC firm | `'investor'` | `'fund'` 또는 `'organization'` | `investor_profile` |
| CVC firm | `'investor'` | `'organization'` | `investor_profile` (subtype='cvc') |
| Investor side person (GP, MD 등) | **`'partner'`** | `'individual'` | `investor_partner_profile` |
| 일반 business partner (공급망) | `'partner'` | `'company'` | `partner_profile` |
| Paper mill firm | `'paper_mill'` | `'organization'` | (별도 module_data) |
| Filler supplier | `'filler_supplier'` | `'organization'` | (별도 module_data) |

⭐ **핵심:** parties.module 만으로는 "이 partner 가 investor 의 GP 인가, 공급망 partner 인가" 구분 불가. **profile 테이블 (investor_partner_profile vs partner_profile) 의 존재 여부로 판별**.

---

## 11. `module_data jsonb` 사용 패턴 (Phase 2 후 완성)

5개 테이블이 `module_data jsonb DEFAULT '{}'` 보유. **현재 키 분포는 Phase 2 introspection (Section 15) 후 확정 예정**.

추정 사용 예 (introspection 전 placeholder):

```json
// parties.module_data (investor module)
{
  "preferred_contact_method": "email",
  "last_outreach_at": "2026-05-15",
  "intro_source": "Closed Loop intro",
  "investment_check_size_usd": 5000000
}

// portfolio_companies.module_data
{
  "co_investors": ["Sequoia", "Khosla"],
  "ipo_target_year": 2027,
  "patent_count": 12
}
```

→ Phase 2 SECTION 15 결과로 실제 키 분포 확정.

---

## 9. 향후 작업 우선순위 (HANDOFF.md 와 동기화)

### 즉시 (Critical)
- ✅ `us_vc_portfolio_depth_FINAL_2026Q2.sql` 실행 — **완료 (2026-05-19)**
- ✅ DB Schema 영구 참조 문서화 — **완료 (2026-05-19)**

### 단기 (High)
1. `module_type` enum 의 `investor_partner` 존재 여부 확정
2. At One Ventures portfolio 5-8개 보강 (paper/material 위주)
3. **Outreach 1순위 명단 export** — direct_fit 6개 firm × 18 DM + 추가 fit 높은 DM (Sacca, Kobler, Price-Wright)

### 중기
4. CVC heads 추가 (Walmart Strategic, PepsiCo Greenhouse, Coca-Cola Ventures, Unilever Ventures)
5. Family offices (Pritzker, Cascade Investment, MSD, Walton)
6. 다른 climate VC (Playground Global, TPG Rise Climate, Anzu Partners)
7. 3M Ventures / P&G Ventures / Amazon CPF 의 portfolio 깊이 보강

### 장기
8. EU 확장
9. 일본 확장
10. paper_mill module 적재
11. `303_normalization_cleanup_OPTIONAL.sql` 실행 (app code 검증 후)
