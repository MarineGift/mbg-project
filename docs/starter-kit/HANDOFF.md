# URM Platform — 핸드오프 문서

**날짜:** 2026-05-19
**대상:** 새 Claude 세션
**작성자:** 이전 Claude 세션 (Opus 4.7)

---

## 1. 프로젝트 컨텍스트

**프로젝트:** URM (Universal Relationship Management) Platform — mbg-project
**스택:** Next.js 14.2 + Supabase + Anthropic Claude SDK
**조직 ID:** `b25de8f2-1020-482f-9012-183f63883169` (MBG Project)
**사용자 위치:** Austin, TX
**언어:** 한국어 (영문 SQL 코멘트 + 한글 설명 혼용)

**사업 도메인:** Paper filler 기술 (calcium carbonate, GCC/PCC, hybrid) — paper manufacturing 분야 fundraising 준비 중.

**지리적 fundraising 타깃 (확정):**
- 현재: 🇺🇸 **미국 only**
- 향후: 🇪🇺 EU, 🇯🇵 일본
- **❌ 한국 제외** (확정 - Korean VC 작업 일체 안 함)

---

## 2. 현재 데이터베이스 상태

### Schema 구조 (정규화 완료 — Phase 1)
- `app.parties` (party_type 으로 fund/individual 구분, parent_party_id 로 3-tier 계층)
- `app.investor_profile` (firm 데이터 - subtype, aum_usd, fund_size 등 정규화 컬럼)
- `app.investor_partner_profile` (individual 데이터 - title_text, seniority_level, is_decision_maker, focus_areas 등)
- `app.portfolio_companies` (마스터 테이블 - 회사명 unique per org)
- `app.investor_portfolio_companies` (link 테이블 - portfolio_company_id FK)
- `ingest.runs`, `ingest.rows`, `ingest.failed_rows` (ETL layer)
- v2 promote 함수들 (`ingest.promote_investors`, `ingest.promote_investor_partners`)

### 핵심 enum / CHECK 제약
- `app.party_type`: fund, individual, etc.
- `app.module_type`: investor, investor_partner, paper_mill, ...
- `app.investor_subtype`: vc, cvc, growth_equity, private_equity, family_office, accelerator, angel, crowdfunding, government, other
- `app.partner_seniority`: founder, partner, principal, associate, advisor, other
- `portfolio_companies.company_status` CHECK: `'private', 'public', 'acquired', 'closed', 'spinoff', 'merged', 'unknown', NULL` ← ⚠️ 'active', 'operating' invalid!
- `parties.party_level` CHECK: `'group_hq', 'country_entity', 'plant'`, NULL OK for individuals

### 현재 카운트 (2026-05-19 기준)
- **firms (US-only):** ~106개
- **partners:** 약 102명 (48 original + 39 wave1 + 13 wave2 + 1 Emily Kirsch + 1 Powerhouse fix)
- **decision makers:** ~90명 (88%)
- **portfolio_companies:** ~310개 (Closed Loop/Generate portfolio depth 작업 진행 중)
- **investor_portfolio_companies links:** ~400+

### Top 20 firm 별 파트너 수 (V-C 마지막 결과)
```
Generate Capital              7 (DM: 5)
Energize Capital              7 (DM: 6)
Eclipse Ventures              6 (DM: 6)
Closed Loop Partners          6 (DM: 6)
Energy Impact Partners        6 (DM: 5)
Lowercarbon Capital           5 (DM: 5)
Ironspring Ventures           5 (DM: 2)
At One Ventures               4 (DM: 4)
Multicoin Capital             4 (DM: 4)
Lux Capital                   4 (DM: 4)
M12                           4 (DM: 3)
KdT Ventures                  4 (DM: 4)
G2 Venture Partners           3 (DM: 3)
Galvanize Climate Solutions   3 (DM: 2)
Andreessen Horowitz           3 (DM: 3)  ← a16z RUN 7 실행 후 5명 될 예정
3M Ventures, Founders Fund, Khosla Ventures, The Engine, S3 Ventures  각 2
```

### direct_fit firm 풀 (9개)
Closed Loop Partners, Generate Capital, Amazon Climate Pledge Fund, P&G Ventures, 3M Ventures, Suzano Ventures, **At One Ventures**, **Pangaea Ventures**, **Footprint Coalition**

---

## 3. 진행 완료 작업 요약

### Wave 1 (Phase 2.1 - 직접 fit firm 4개 + 파트너 18명)
- 4개 firm 신규: At One Ventures, Trust Ventures, Pangaea Ventures, Footprint Coalition
- 18 파트너: Tom Chi (At One), Ty Findley/Peter Holt (Ironspring), Cain McClary (KdT), Salen Churi (Trust), etc.

### Wave 2 (Phase 2.2 - 기존 firm 의 파트너 확장 40명)
- RUN 1: CVC heads 5명 (Brandon Middaugh @ Microsoft Climate Innovation Fund, Michelle Gonzalez @ M12 등)
- RUN 2: Climate VC 14명 (Chris Sacca @ Lowercarbon, Dayna Grayson @ Construct, John Tough @ Energize 등)
- RUN 3: Texas 0-partner 8명 (Tushar Jain @ Multicoin, Tom Ball @ Next Coast, Brad Harrison @ Scout 등)
- RUN 4: Climate extra 12명 + 1 실패 (Emily Kirsch @ Powerhouse — firm 미존재로 실패 → 후속 fix 완료)

### Powerhouse Fix
- Powerhouse firm 적재 + Emily Kirsch (Founder & CEO, DM) 적재 완료

### Wave 2-Phase 2 (Eclipse + EIP 추가)
- RUN 5: Eclipse Ventures 5명 (Greg Reichow ex-Tesla VP, Pierre Lamond ex-Sequoia 등)
- RUN 6: Energy Impact Partners 6명 (Hans Kobler $4.5B AUM 설립자, Shayle Kann Frontier Fund 등)
- **RUN 7 (미완료):** a16z American Dynamism — Erin Price-Wright, Ryan McEntush ← **새 세션에서 처리 필요**

### Regex 패치 완료 (350_patch_seniority_regex.sql)
seniority_level 자동 분류 + is_decision_maker = seniority IN (founder, partner). DM 67% → 90% 향상.

### Suzano Senior Manager 수동 DM 승격
Paula Puzzi, Álvaro Gómez Rodríguez (Senior Manager 직책이지만 CVC 의 실질적 결정권자)

### Yun Young Heo cleanup
사용자 본인이 잘못 적재된 stub. DELETE 완료.

---

## 4. **현재 진행 중 — Portfolio Depth 작업 (미완료)**

**파일:** `us_vc_portfolio_depth_FINAL_2026Q2.sql` (이전 세션에서 생성, 사용자에게 전달됨)

**상태:**
- STEP 1 (Closed Loop 16개): **❌ 'operating' 으로 시도해서 CHECK 제약 위반** → FINAL 버전에서 'private'/'public' 등 정확한 값으로 매핑함
- STEP 2 (Generate 15개): 마찬가지로 FINAL 버전 사용 필요
- STEP 3 (a16z RUN 7): 같이 묶음
- STEP 4 검증: STEP 1-3 후 실행

**중요한 발견:**
- **⭐⭐ Earthodic** — Closed Loop 의 portfolio 회사. 호주 biotech. **paper 산업의 lignin 부산물** 로 paper packaging water-resistant coating 만듦. 본인 사업과 거의 완벽한 인접 fit. Closed Loop 의 6명 DM 에게 outreach 시 "Earthodic 과 동일 카테고리" 로 positioning 가능.

---

## 5. **새 세션에서 처리할 작업 (우선순위 순)**

### A. 즉시 (Critical)
1. **`us_vc_portfolio_depth_FINAL_2026Q2.sql` 실행 결과 확인**
   - STEP 1, 2, 3 모두 성공했는지 (각 promoted 카운트)
   - STEP 4 검증 결과 (특히 4.1 portfolio 카운트, 4.3 paper-relevant)

### B. 단기 (High priority)
2. **At One Ventures portfolio 5-8개 추가 보강**
   - Air Company, Nature Coatings, Beewise, Apis Cor 등 paper/material-relevant 위주

3. **Outreach 1순위 명단 export** — 본인 사업 fit 인물 + 회사 매핑된 outreach plan
   - 6개 direct_fit firm × 18 DM
   - + 추가로 fit 높은 firm 의 DM (Lowercarbon Sacca, EIP Kobler, a16z Erin Price-Wright 등)
   - LinkedIn URL + 이메일 패턴 + 직접 fit 회사 (Earthodic, Cruz Foam, Cloud Paper 등) 매핑

### C. 중기 (Continue expansion)
4. **CVC heads 추가** — Walmart Strategic, PepsiCo Greenhouse, Coca-Cola Ventures, Unilever Ventures
   - 포장재 buyer 직접 contact 가능
5. **Family offices** — Pritzker Group (industrial 가문 — 직접 fit), Cascade Investment (Gates), MSD Capital, Walton Enterprises
6. **다른 climate VC** — Playground Global, TPG Rise Climate, Anzu Partners 의 파트너
7. **3M Ventures, P&G Ventures, Amazon CPF 의 portfolio 깊이 보강** (paper-relevant 만 5-8개씩)

### D. 장기 (Phase 3)
8. **Korean → EU + Japan 확장** (현재는 미국만, 향후 단계)
9. **paper_mill module** 적재 (정규화된 패턴 그대로 재사용)
10. **Cleanup 마이그레이션** (`303_normalization_cleanup_OPTIONAL.sql`) — 미실행 상태. app code 가 새 컬럼 사용 확인된 후 실행.

---

## 6. 기술적 주의사항

### v2 ingest 함수 사용 패턴
```sql
SELECT ingest.start_run('label', 'module', org_id, '...');
SELECT ingest.stage_rows_bulk('label', '[...]'::jsonb);
SELECT * FROM ingest.promote_investors('label');  -- 또는 promote_investor_partners
```

### Idempotent direct SQL 패턴 (portfolio 추가 시)
```sql
BEGIN;
WITH portfolio_data AS (VALUES (...)),
upsert_companies AS (
    INSERT INTO app.portfolio_companies (...)
    SELECT ... FROM portfolio_data
    ON CONFLICT (organization_id, name_normalized) DO UPDATE SET ...
    RETURNING id, name_normalized
),
insert_links AS (
    INSERT INTO app.investor_portfolio_companies (...)
    SELECT ... 
    WHERE NOT EXISTS (...)
    RETURNING id
)
SELECT (SELECT COUNT(*) FROM upsert_companies) AS upserted, 
       (SELECT COUNT(*) FROM insert_links) AS linked;
COMMIT;
```

### 자주 발생한 문제 + 해결
1. **`runs_label_key` duplicate** — start_run 두 번 호출하면 발생. 첫 시도가 사실 성공했는지 먼저 확인: `SELECT * FROM ingest.runs WHERE label = '...'`
2. **Parent firm not found** — firm 이 DB 에 없는 상태에서 partner 적재 시. 사전 진단 필수: `SELECT id, name FROM app.parties WHERE module='investor'::app.module_type AND name ILIKE '%...%'`
3. **company_status CHECK 위반** — 'active', 'operating' 등 invalid 값. **valid: 'private', 'public', 'acquired', 'closed', 'spinoff', 'merged', 'unknown', NULL**
4. **linkedin_url 컬럼 위치** — `app.parties` 에 있음 (`p.linkedin_url`), NOT on `investor_partner_profile`
5. **"syntax error at or near -"** — Supabase SQL Editor 의 부분 선택 문제. 전체 statement 를 한 번에 선택해야 함
6. **Seniority regex** (350_patch 적용 후 안정):
   - founder: founder/CEO/chairman/president (NOT vice president)
   - partner: managing partner/director, head of, investment director, "partner" alone
   - principal: director (general), VP, vice president
   - is_decision_maker = seniority IN ('founder', 'partner')

### 사용자 의사소통 패턴
- **한국어 응답 선호**, 영문 SQL 은 그대로
- **간결한 보고 선호** — 표 활용, 핵심만
- **검증 쿼리 CSV 로 받아 분석**
- **권장 + 옵션 제시 → 사용자 선택** 패턴 (ask_user_input_v0 도구 활용)
- **6시간 휴식 등 명시적 시간 안내** 시 자동 작업 불가 함을 솔직히 안내 (Claude 는 메시지 받을 때만 작동)

### 사용자 메모리 정책
- **회사 affiliation 일체 노출 금지** — 사용자가 명시적으로 익명 처리 요청. "anonymous individual without business affiliations or role context"
- **이름:** YunYoung (영문/한글), Yun Young Heo (전체 영문)
- **언어:** 한국어/영어/일본어 모두 가능

---

## 7. 파일 inventory (참고)

이전 세션에서 생성된 SQL 파일들 (모두 `/mnt/user-data/outputs/ingest_layer/` 위치):
- 100_ingest_layer.sql (base ingest schema)
- 200_promote_investor_partners.sql + 201_patch
- 250_diagnose_for_normalization.sql
- 300_normalization_phase1_schema.sql
- 301_normalization_phase1_backfill.sql
- 302_ingest_functions_v2.sql
- 303_normalization_cleanup_OPTIONAL.sql (미실행)
- 350_patch_seniority_regex.sql (적용 완료)
- us_vc_2026Q2_b.sql (50 firms)
- us_vc_partners_2026Q2.sql (35 partners)
- us_vc_partners_direct_fit_2026Q2.sql (13 partners)
- us_vc_paper_tx_specialty_2026Q2.sql (4 firms + 18 partners)
- us_vc_massive_expansion_2026Q2.sql (Wave 2 — 40 partners)
- us_vc_wave2_expansion_2026Q2.sql (Eclipse + EIP + a16z 13 partners)
- **us_vc_portfolio_depth_FINAL_2026Q2.sql** ← 현재 실행 대상

---

**다음 세션 시작 시 사용자 메시지:** `NEW_SESSION_KICKOFF.md` 파일 내용을 보내드릴 예정.
