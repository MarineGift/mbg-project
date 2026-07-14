# Handoff — Marinebio IR + Climate Email Sequence (2026-07-13 세션 종료)

다음 세션은 이 문서만 읽으면 바로 이어받을 수 있음. 사용자가 최신 파일을 업로드하면 그것이 기준. 사용자가 PowerPoint/Supabase에서 직접 수정하는 경우가 많으므로 **항상 diff로 변경점부터 파악**할 것.

---

## PART A — IR 덱 (콜드덱)

### 현재 최신 파일
- **`Marinebio_IR_ColdDeck_v12.pptx`** (16장) — 콜드 아웃리치 최신, 발송 준비 완료
- 풀덱: `Marinebio_IR_Ver3_21.pptx` (40장) — 폰트 통일+메타데이터만, 콘텐츠 동일
- 덱은 Drive/로컬 보관 대상 (mbg-project repo 아님) → mover/git 불필요

### v12까지 이번 세션 변경 요약 (v5 → v12)
- v6: 슬라이드4 오타/숨은 $100-250 박스 삭제/부제 클리핑, 슬라이드10 20%→25%, 슬라이드15 팀 표기 통일, 발표노트 전환멘트 9곳 순서 재정렬 + $33.6M 훅 수정
- v7: 슬라이드3 CarbonCure 문구 자기설명형("permanent mineral lock-in") + MFC 3% → "under 1%" 후 최종 "0.3% of the pulp ton", "negative-abatement-cost" 삽입 / 슬라이드5 결과라인
- v8: 슬라이드5 문제→해결 서사 재구성(수소결합 파괴 원인), 슬라이드4 QUALITY DEGRADATION 메커니즘화, 슬라이드3 "0.3%" 확정
- v9: 사용자가 추가한 슬라이드6("The Breakthrough, Up Close") 카피 전면 재작성 (수소결합 다이어그램 설명형)
- v10: 슬라이드6을 "One Bond Solves All 4 Requirements"로 통합 — 결합 다이어그램 + 4대 요건 결과카드(BULK/STRENGTH/STIFFNESS/SMOOTHNESS) + "No trade-off" 배너
- v11: 사용자 편집본
- **v12: 슬라이드4 빨간 부제 클리핑 최종 해결** (원인=흰 카드배경 Shape 27이 텍스트를 z-순서로 덮음 → 부제를 제목 하단·카드 상단 사이 갭으로 이동)

### 확정 핵심 숫자 (전 슬라이드 정합, 변동 금지)
- 로열티 5-10% / 대표 $15/ton · Y1/Y2/Y3 = $4.4M/$12.3M/$33.6M (0.29/0.82/2.24M t)
- 밸류 $27M = 0.8× Y3 royalty · SOM ~1.6M t · 필러 25-30M t (GCC ~5× PCC) · 로열티풀 $93-112M/yr
- 라운드: $3M @ $27M pre / $30M post, $30M cap SAFE
- 라이선스→로열티 모델. FCC = Flexible Calcium Carbonate 종이 충전제, 펄프 대체

### 덱 미결 (사용자 결정 대기)
1. **커버 날짜 "June 2026" → "July 2026"** — 이메일이 7/14 발송되므로 발송 전 변경 권장 (1분 작업, v12 커버 slide1)
2. 슬라이드13 두 거인 카드: "(GCC+PCC)" 헤더 밑 MTI 특징 / "(PCC)" 밑 Omya풍 설명이 교차. 익명화 의도면 유지, 실수면 스왑 — 사용자 확인 필요
3. SEM 커버 이미지 2019 타임스탬프 크롭 (권장, 스케일바 100µm 유지)
4. 풀덱(Ver3_21)에 커버 크레딧 라인/SEM/슬라이드6 반영 여부 — 현재 콜드덱에만 있음

### 덱 편집 컨벤션
- pptx 작업 전 `/mnt/skills/public/pptx/SKILL.md` 필독
- zipfile extractall → slideN.xml 편집(unique str.replace) → 디렉토리 내 `rm -f ../out.pptx && zip -Xrq ../out.pptx .` → `validate.py OUT --original ORIG` → soffice pdf + pdftoppm 렌더 QA
- 슬라이드 삭제: presentation.xml sldIdLst 트림 → clean.py → slidenum 캐시 갱신 → viewProps.xml outline-view 참조 + .rels 정리
- defusedxml.minidom로 well-formed 검증. Pretendard 런 추가 시 rPr에 latin+ea+cs 3종 typeface
- 팔레트: navy 1F3864/203864, blue 2E5496/4472C4, teal 5B9BD5, green 548235/138A6B, red C0392B/C00000, orange ED7D31
- LibreOffice 렌더는 폰트폭이 Pretendard와 달라 근사치 → 최종 발송 PDF는 **사용자 PC PowerPoint 내보내기** (docProps 정리돼 메타데이터 자동 클린)

---

## PART B — Climate 이메일 시퀀스 (URM / Supabase)

### 시퀀스 상태
- **"Climate Investor Cold Outreach -- FCC"** — 4-step, active
  - Step 1 (Day 0) 임팩트 / Step 2 (Day 7) 마켓산수 / Step 3 (Day 14) 방어성 / Step 4 (Day 21) 브레이크업
  - 주간 offset(0/7/14/21) + quiet_hours(화 09:00 America/Los_Angeles, 주말차단)
  - 등록 인원 ~69명, 전원 **화요일 7/14 09:00 PT** 예약 (16:00 UTC, PDT)
  - 병합토큰 `{{contact.firstName}}`
- 발신계정 from_account_id = `4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2` (기존 시퀀스와 동일)
- org_id = `b25de8f2-1020-482f-9012-183f63883169`

### 스키마 확정 사실 (중요 — 삽질 방지)
- 테이블: `app.email_sequences` / `email_sequence_steps`(body_plain, day_offset, step_order) / `email_sequence_enrollments`(next_send_at, next_step_order, recipient_email, status)
- **`enrollment_status` enum 유효값 = active | completed | cancelled | paused | failed** (unsubscribed 없음!). enum 대입 시 `::app.enrollment_status` 캐스트 필수
- 섹터: `app.sectors`(id smallint 1-16). 코드: advanced_materials, industrial, deep_tech, climate, energy, ai, software, fintech, healthcare, consumer, mobility, food_ag, defense, enterprise, crypto, **life_science(id16)**
- 섹터 링크: parties → investor_profile(party_id) → investor_sector_focus(investor_profile_id) → sectors
- **스테이지: `investor_stage_focus.stage_id` = SMALLINT(값 0-20). app.stages(id=uuid)가 아님 → 별도 smallint 키 lookup 테이블. 실제 테이블명 미확정** (probe 20260713240000 블록2로 FK 조회 필요). 분포: id 3=254, 2=250, 10=179, 11=138, 4=125...
- Form-only 판별: `parties.preferred_contact_method IN ('web_form','portal')` + `contact_form_url` (migration_027)
- Supabase SQL Editor: 세미콜론/`into`가 문자열에 있으면 파싱 오류 → 본문은 dollar-quote($body$)로 감쌀 것. DO 블록도 $migration$ 사용

### 타겟팅 규칙 (사용자 확정)
- **타겟 섹터**: deep_tech, advanced_materials, industrial, climate
- **제외 섹터**: healthcare, life_science, consumer (→ 다른 덱으로 별도 발송 예정)
- **스테이지**: Series A 이상 (단 stage 데이터 커버리지 불확실 → 실무상 nostage 방식 채택함)
- **Form-only**: 이메일 발송 제외, 수동 제출 목록 별도 (`20260713200000_form_only_investor_worklist.sql`)
- **중복 발송 금지**: 한 투자자가 2+ 시퀀스 동시 active 불가

### ⚠️ 지금 실행 중인 마지막 작업 (다음 세션 즉시 이어서)
**`20260713250000_dedup_active_enrollments.sql`** — 중복/테스트 정리 중.
- Part 0b 미리보기 **확인 완료**: 중지 대상 10건 = overlap 8곳(Ara Partners, Asahi Kasei, Azolla, Circulate Capital, Emerald Technology, Khosla Ventures, Regeneration.VC, The Engine) + test 2건(MBG Mailing Test, test)
- 이들은 "Investor Cold Outreach - FCC Seed"(발송 7/20)에서 `cancelled`로 중지 → Climate(7/14)에서만 발송되게
- **다음 액션: Part 1 실행 → Part 2 검증(2+ 시퀀스 active = 0건 확인)**
- v_stop_status = 'cancelled' (enum 유효값으로 확정, 캐스트 포함됨)

### repo에 커밋된 SQL (sql/)
- 20260713140000_climate_investor_sequence_create.sql (시퀀스 생성)
- 20260713150000_climate_sequence_tuesday_9am_pt.sql (화요일 재조정 — 실행됨)
- 20260713160000_climate_sequence_enroll_more.sql (energy+industrial 확장 — 실행됨)
- 20260713170000_investor_send_audit.sql (읽기전용 감사)
- 20260713180000_climate_sequence_enroll_all_remaining.sql
- 20260713190000_climate_sequence_enroll_targeted.sql (4섹터+SeriesA, app.stages 조인 — stage 테이블명 미확정으로 미사용)
- 20260713200000_form_only_investor_worklist.sql
- 20260713220000_climate_sequence_enroll_targeted_nostage.sql (**실제 사용됨** — 섹터+dedup only)
- 20260713230000/240000 stage probe (읽기전용)
- 20260713250000_dedup_active_enrollments.sql (**진행중 — Part1 미실행**)

### 발송 전 남은 체크리스트 (우선순위)
1. **[진행중] dedup Part 1 실행 + Part 2로 0건 검증** ← 새 세션 첫 작업
2. **커버 날짜 June→July** (덱 v12) — 이메일과 함께 나가므로
3. **발송량 확인**: 69통 화요일 동시 발송. 발신계정 워밍업 상태 확인. 새 계정이면 여러 화요일로 분산하는 SQL 필요 (next_send_at을 배치별로 +7일)
4. **겹치는 빈 시퀀스 정리**: "Investor Cold Outreach - FCC Climate Tech"(0 active) archive 여부
5. 이메일 없는 최상위 기후펀드 백필: Breakthrough Energy, Amazon Climate Pledge, Bezos Earth Fund, DCVC 등 (CSV로 받은 70개 firm 전부 email=null). info@/contact@ 웹에서 확보 → UPDATE app.parties 배치. 이게 가장 가치있는 후속작업

### mbg-project 작업 컨벤션 (핵심만)
- repo PUBLIC: raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<path> 로 직접 읽기. route-group `(app)`→`%28app%29`
- SQL 파일명 프리픽스로 자동 라우팅(tools\move-downloads.ps1): seed_/migration_/repair_/enrich_/backfill_/fix_*.sql → sql\, handoff_*.md → docs\handoff\<today>\
- 모든 핸드오프에 붙여넣기용 PowerShell mover 블록 + finish 블록(commit+push origin marinebiogroup = 웹 자동배포) 포함. push 전 git status -sb
- PowerShell: Downloads = $env:USERPROFILE\Downloads. .ps1은 Unblock-File. 콘솔 ASCII-only(PS5.x가 UTF-8 no-BOM을 CP949로 오인). Korean은 .md에 UTF-8 BOM
- 소통: 한국어(논의) + 영어(덱/코드/SQL)
- SaaS 멀티테넌트: RLS org-scoping, 엔티티테이블 created_by uuid default auth.uid()
