# HANDOFF — MBG CRM 투자자/그랜트/파이프라인 (2026Q3)

> 새 세션에서 이 파일을 raw GitHub로 읽고 바로 이어가기 위한 핸드오프.
> 경로: `docs/research/HANDOFF_2026Q3_investor_grant_pipeline.md`
> raw: `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/docs/research/HANDOFF_2026Q3_investor_grant_pipeline.md`
> 작성 기준 시점: 2026-06-20. 마지막 커밋 `95df199` (branch `marinebiogroup`).

---

## 0) 한 줄 요약
이번 세션에서 마이그레이션 `20260620370000` ~ `20260620370020` 으로 글로벌 투자자 대량 추가 + intro/priority + paper_mill 복원 + filler 갭/프로필 + government_grant 시딩 + 파이프라인 deal 시딩을 끝냈다. **남은 작업 3개**: ① deal 디테일 채우기 ② 아웃리치 실행 ④ CVC 더 추가.

---

## 1) 프로젝트 기본
- Repo: `MarineGift/mbg-project` (PUBLIC), branch `marinebiogroup`. Local `C:\dev\mbg-project`.
- Supabase project `ogenmrgxwhpbfepeldqx`, org_id(=organization_id) `b25de8f2-1020-482f-9012-183f63883169`.
- 소스 읽기: `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<path>` (route-group 괄호는 `%28%29` 인코딩).
- 대화는 한국어, 코드/SQL/식별자/console 출력은 영어.

## 2) 워크플로우 규약 (중요)
- 마이그레이션은 `supabase/migrations/`에 `.sql`. **데이터 반영은 Supabase SQL Editor 실행**으로 됨(커밋/푸시는 파일 이력만 기록).
- 전부 **멱등**(`NOT EXISTS` 가드, `where ... not exists(...)`).
- PowerShell: 다운로드는 `$env:USERPROFILE\Downloads`; `.ps1`/`.sql`은 `Unblock-File`; console 출력 ASCII 전용. 한국어는 UTF-8 BOM `.md`에만.
- **이번 세션 교훈: 다운로드가 자주 누락됨.** ASCII `.sql`은 다운로드 대신 PowerShell here-string + `Set-Content -Encoding ascii`로 repo에 직접 생성 후, SQL Editor엔 인라인으로 붙여 실행하는 게 가장 안정적이었음. 한국어 `.md`는 console 붙여넣기 시 PS 5.x가 CP949로 깨뜨리므로 **반드시 다운로드**해서 옮길 것.
- 적용 후 검증 쿼리 → 결과 CSV 확인 → `git add supabase/migrations/ ; git commit ; git push origin marinebiogroup`.
- 다음 마이그레이션 번호: `20260620370021` 부터 이어가면 됨(또는 새 날짜 prefix).

## 3) 라이브 vocab (2026-06-20 확정)
- `app.party_types`: investor=1, paper_mill=2, filler_supplier=3, government_grant=7, other_supplier=11 (그 외 partner/self 등 존재).
- `app.investor_types`: vc=1, growth_equity=2, cvc=3, accelerator=4, private_equity=5, family_office=6, angel=7, government=9, other=10, endowment=11.
- `app.sectors` (smallint): advanced_materials=1, industrial=2, deep_tech=3, climate=4, energy=5, ai=6, software=7, fintech=8, healthcare=9, consumer=10, mobility=11, food_ag=12, defense=13, enterprise=14, crypto=15, life_science=16.
- investor stages (smallint, `app.investor_stage_focus.stage_id`): seed=2, series_a=3, series_b=4, series_c=5, early=10, growth=11, late=12.
- `app.entity_types`: company=1 (모든 insert에 entity_type_id=1 사용).
- country_code: 2자리 ISO. 범유럽 프로그램은 `'EU'`(ISO 예약코드) 사용. 실리콘밸리 본사 일본/한국 CVC는 본사 기준 `US` 태깅(예: LG Technology Ventures, Diamond Edge, Mitsui GI, Presidio).

## 4) 테이블 스키마 (insert 시 NOT NULL 주의)
### app.parties (핵심 컬럼)
party_type_id(smallint), entity_type_id(smallint), party_name, status, source, country_code, region, city, website, email, linkedin_url, intro_ko, intro_en, notes, interest_tags(jsonb), industry_tag_id, organization_id, created_at/updated_at/deleted_at.

### 투자자 4단계 인서트 (확립된 패턴)
1. `app.parties` (party_type_id=1, entity_type_id=1, ...)
2. `app.investor_profile` (party_id, investor_type_id, sector_focus text[], geographic_focus text[], is_lead_investor, organization_id, priority default 'medium')
3. `app.investor_sector_focus` (investor_profile_id, sector_id smallint, organization_id NOT NULL)
4. `app.investor_stage_focus` (investor_profile_id, stage_id smallint, organization_id NOT NULL)
※ 긴 한국어 dollar-quote 다중행 UPDATE는 SQL Editor 붙여넣기에서 truncation 발생 → intro/priority는 **per-firm 개별 UPDATE**로.

### app.deals (NOT NULL: id, party_id, pipeline_id, current_stage_id, deal_name, status, value_currency, priority, extra_data, created_at, updated_at)
기타: description, probability_pct, value_amount, expected_close_date, owner_user_id, source, notes, campaign_id, stage_entered_at, next_step, next_step_date, organization_id.
- 관례값: `status='active'` (라이브 187건이 active; 'open'도 유효하나 active로 통일함), `priority` in 'high'/'medium'(/'low'), `value_currency='USD'`, `extra_data='{}'::jsonb`.
- 연결 보조: `app.deal_parties`(deal_id, party_id, role, currency NOT NULL), `app.deal_participation`(party_id, pipeline_id, deal_id 전부 NOT NULL).

### app.filler_supplier_profile (NOT NULL: id, party_id, industry_source, extra_data, organization_id, created_at, updated_at)
컬럼: supplier_type, market_role(짧은 라벨), supply_model('merchant'/'satellite'), onsite_pcc_evidence, evidence_level(NULL/A/B/C/D), mineral_class, notes.
- 규칙: supply_model satellite→evidence 'B', merchant→'C'.

### app.paper_mill_profile (party당 1행, party_id UNIQUE)
main_product_category, main_products, headquarters, filler_use_intensity, europe_mills_footprint, evidence_level(NULL/A/B/C/D), industry_source, extra_data.

## 5) 파이프라인 + 스테이지 UUID
- **Investors** `de80525d-5537-4971-ad8f-d2080a8e65b0`
  - Cold outreach `1147f55e-297d-4c82-b74d-0e7976a2db8e` (시작)
  - Reply received `3a311827-dc9f-47f1-a6cd-3073ff985658`
  - First meeting `be415dbe-f07a-4869-9989-254f27e25b0c`
  - Follow-up meeting `052a2fb2-82b1-4a79-ad62-3a6d6118c384`
  - Due diligence `5584bab5-765e-418e-8364-a0694b9e5564`
  - Term sheet `fc2949cc-97a4-481e-b191-5ee8176fc927`
  - Contract `47a72672-b603-47f1-a8a3-2724f3352166`
- **Government Grant** `4f898bc2-27ef-45d0-8aea-14143888b850`
  - Identified `a6059681-3965-45d7-9bc2-d45902cee290` (시작)
  - Eligibility `f454b0ce-480c-4b46-96f7-76c91f818719`
  - Preparing `2a1c9e3b-de80-4a38-916f-ed704a3c80be`
  - Submitted `63b6c7ba-9857-4848-98d8-eaf705e019b1`
  - Under review `e7c41c4a-f2c0-4ead-bd61-bf82aebbd41a`
  - Awarded `f97c64ac-8689-4b64-b2d9-d1e2627c7ce5`
  - Rejected `e3ffea52-d43b-430c-a3ba-9abbd99644ab`
- **Filler Suppliers** `fb74a367-9b9a-4493-9277-ddf2c440c8a1`
  - Prospect `5e8737cc-f381-4987-9a1f-63617edc11d7` (시작)
  - Contacted `653703d1-653f-4468-8efa-7a3f38ac726d`, NDA `c29626b3-f07d-4c31-86ee-d84aab966436`, Evaluation `42316f1f-0707-44db-a19d-eca9ac85b545`, Lab test `29c929ab-fdf8-414b-a3f2-8ae11c5b5a2f`, Pilot `0af59491-0cf9-4d43-adea-fd6e555b8064`, Mass Production `50aa6800-ee1d-4386-9d93-0f6f9306e8e0`, Royalty Agreement `7bd0bb0c-57a3-4159-8a25-3c31386a0198`, Lost `c7304e5d-1498-4337-a395-14ee16af9e0b`
- **Paper Mill** `6395056e-cbfb-4732-8ca6-9000972076d8` (Lead `82db756d-a5d9-4028-82ab-e68efeedc03e` 시작; Qualified/Sample sent/Trial/Quotation/Negotiation/Won/Lost)
- **Crowdfunding** `69460e08-b65e-4a8a-bae7-03b6393c6c73` (Research/Outreach/Application/Review/Live campaign/Funded/Closed)

## 6) 이번 세션 산출물 (370000~370020, 전부 적용+커밋됨)
- 글로벌 investor 74곳 신규: source `investor_global_2026Q3_b1`~`b7`.
  - b1 25(370000), b2 20(370002), b3 11(370003), b4 7(370006), b5 5(370007), b6 3(370011, 실제 신규 2 — Diamond Edge는 기존 `investor_enrich_2026Q3_b3`), b7 2(370015).
- intro_ko/intro_en + priority='high' 17곳: 370004/370005(1차 8), 370009(2차 5), 370012(3차 4).
- paper_mill: 370008(majors no-op), 370010(UPM·Oji 회사 anchor 복원+프로필).
- filler_supplier 갭 6 신규: 370013 (source `filler_gap_2026Q3`) = Specialty Minerals Inc., Minerals Technologies Inc., Schaefer Kalk, Calcinor, Huber Engineered Materials, Lhoist (HQ). (Sibelco·Shiraishi는 기존이라 스킵.)
- filler 프로필 백필: 370017 (위 6곳 supply_model='merchant', evidence 'C').
- government_grant 0→17: 370014 (source `gov_grant_2026Q3`, US5/EU5/KR7) + 370016 notes 적합도 보강(HIGH/VERY HIGH/MEDIUM).
- 파이프라인 deal 시딩(source `pipeline_seed_2026Q3`, 전부 status='active'):
  - 370018: Investors(Cold outreach) **78** (priority='high' 투자자 전원 중 미등록분) + Government Grant(Identified) **8**(notes fit HIGH/VERY HIGH).
  - 370019: 위 deal status open→active 정규화 기록.
  - 370020: Filler Suppliers(Prospect) **6**(신규 filler).
  - 합계 92 deal.

### dedup 기준 (재추가 금지)
위 전부 + 사전 존재분: Evonik VC, Emerald, Henkel Tech Ventures, Pangaea, Atomico, Balderton, Generation IM, Northzone, Temasek/GIC/Circulate, CPP, ADIA/Mubadala, QIA, PIF, Norges, Suzano, L'Oreal BOLD, Material Impact, BASF VC, Saint-Gobain NOVA, Diamond Edge Ventures, Sibelco, Shiraishi Calcium, Stora Enso Oyj, Mondi (HQ), UPM, Oji Holdings Corporation. 신규 추가 전 이름으로 먼저 조회.

## 7) 남은 작업 (다음 세션)

### ① deal 디테일 채우기 (저~중위험)
- 대상: `app.deals where source='pipeline_seed_2026Q3'` (92건). 현재 next_step / expected_close_date / owner_user_id 비어있음.
- 먼저 확인할 것:
  - 사용자(담당자) UUID: `select id, email from app.users;` (또는 auth.users — 실제 테이블명 확인).
  - 단계별 next_step 문구/마감 오프셋을 어떻게 줄지 결정(파이프라인별 다르게).
- 접근: `update app.deals set owner_user_id=..., next_step='...', next_step_date=current_date+interval 'N days', expected_close_date=... where source='pipeline_seed_2026Q3' and pipeline_id=...`.
- 열린 결정: 담당자 1인 일괄 vs 분배 / next_step 문구 / 마감 기준.

### ② 아웃리치 실행 (HIGH STAKES — 실제 발송)
- 맥락: 이메일 시퀀스 발송 파이프라인 구축됨(merge field, per-sequence Run Now, opens/read-receipt 모달). 워커 Railway `lucky-patience`(project `joyful-celebration`), `npx tsx src/workers/all-workers.ts`. 큐 스키마 `app.mail_runs`/`app.mail_run_recipients`.
- **테스트 타깃**: MBG Mailing Test party `8fd7b4ae...`(개인 이메일 6 contact). 항상 여기로 먼저 테스트.
- 후보: Investors 파이프라인 Cold outreach 78 deal. 단, **strict verified-only로 추가돼 많은 투자자 party가 검증된 contact 이메일이 없음** → 1단계는 "Cold outreach deal 중 verified email 있는 contact 보유 party" 식별, 그다음 subset 선정 → 시퀀스 등록.
- 주의: 발송 모드(live/background), 수신자 검증, 테스트 우선. 전용 세션에서 신중히.

### ④ CVC 더 추가 (독립·중위험: 검증 필요)
- 후보(검증 후): Mitsubishi Corporation(상사 CVC), JSR Corporation, Sumitomo Chemical, Asahi Kasei. 일본 CVC는 실리콘밸리 본사면 US 태깅.
- 패턴: §4 투자자 4단계 인서트, source `investor_global_2026Q3_b8`, 번호 370021~. web_search로 HQ/CVC 실존/섹터 검증, dedup 후 추가. 소재/화학 핏이면 intro/priority 'high'도 후속.

## 8) 다음 세션 시작 멘트 예
"mbg-project 이어서. docs/research/HANDOFF_2026Q3_investor_grant_pipeline.md 읽고, ①/②/④ 중 X 진행하자."
