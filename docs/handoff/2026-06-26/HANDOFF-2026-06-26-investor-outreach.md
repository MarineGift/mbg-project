# Handoff -- 2026-06-26 Investor Outreach Culmination (Intel Inside + Pangaea First Meeting)

> 다음 세션은 이 파일만 읽으면 이어서 작업 가능합니다. UTF-8 BOM 으로 저장됨.

---

## 0. 한 줄 요약

Intel Inside 2-step sequence 로 9개 VC firm 에 cold outreach Day 0 발송 완료(open 4/7), 첫 사람 답장(Andrew Haughian @ Pangaea Ventures)으로 7/8 09:30 PDT intro call 확정 -> URM 에 Deal + Meeting + Attendees 생성 완료, IR Deck 기반 정정된 One-pager(v2) 작성 완료. 다음은 Pangaea 미팅 준비(portfolio 리서치 / 예상 질문 답변).

---

## 1. 고정 환경 (변하지 않음)

- 로컬 repo: `C:\\dev\\mbg-project` (양쪽 머신: Samsung SS_LAPTOP-HEO 집, Lenovo 회사)
- GitHub: `MarineGift/mbg-project`, branch `marinebiogroup` (PUBLIC). push = Railway auto-deploy -> urm.marinebiogroup.com
- Supabase project `ogenmrgxwhpbfepeldqx`, org `b25de8f2-1020-482f-9012-183f63883169`
- user_id: `551fc4a0-b365-47eb-bf2f-0c3f594001c0`
- 발송 계정: `yunyoung.heo@marinebiogroup.com` (from_account_id `4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2`)
- SQL 은 ALWAYS Supabase SQL Editor 에서만 실행 (PowerShell 금지 - PS 5.x 가 SQL 깨뜨림)
- PS1 은 ASCII-only, `Unblock-File` 먼저 또는 `powershell -ExecutionPolicy Bypass -File`
- 한글 .md 는 UTF-8 BOM 으로 저장

### 스키마 주의 (실수 방지)
- parties: `country_code`(not country), `region`, `city`, `street_address`, `email`, `website`
- contacts: `title_text`(not title), `email`, `phone_mobile`, `is_decision_maker`, `is_primary`
- engagements: `occurred_at`(not engagement_at), `direction`, `channel`, `title/summary/content`(no subject), no contact_id
- meetings: enum `app.meeting_status` = cancelled/completed/no_show/rescheduled/scheduled. 컬럼 `occurred_at`, `scheduled_at`, `duration_min`, `meeting_type`, `meeting_mode`, `status`, `stage_id`, `calendar_event_id`
- meeting_attendees: enum 타입명은 동적 발견 권장(pg_attribute -> atttypid::regtype::text). role/response 컬럼
- calendar_events: 별도 테이블(Google/Outlook sync). meetings 와 calendar_event_id 로 연결
- email_sequences: `created_by`, `updated_by` audit 컬럼 이번에 추가됨
- IMAP/메일 상태: `app.inbound_mailboxes`(not email_accounts), `app.mailcarrier_state`(last_processed_uid, kind=account/role/shared)

---

## 2. 이번 세션에서 DB 에 실제 적용 완료된 것 (재실행 불필요)

1. **Investor enrich Batch 8** -- 4개 이메일 추가(Breakout/G2 VP/Creative/Spring Lane). 확인된 VC general email 총 17개.
2. **Intel Inside 2-step sequence 생성** (id `ceccfb05-f735-4ebb-a28b-d352bd6b8aae`)
   - email_sequences 에 created_by/updated_by 추가 + 기존 7행 backfill
   - Step Day 0(main pitch) + Step Day 5(short bump), `{{contact.firstName}}` 변수
   - **9개 firm enroll + Day 0 발송 완료(2026-06-26 16:08 UTC)**. Day 5 = 2026-07-01 자동 발송 예정
   - 발송 firm: Phoenix VP, SOSV, Playground, Voyager, Prelude, Generate, Founder Collective, G2 VP, Spring Lane
3. **Pangaea/Andrew backfill** -- Andrew Haughian contact 보강(email andrew@pangaeaventures.com, Partner, +1.604.787.3478, decision_maker, primary). Pangaea party 보강(info@/website). deck-send engagement retroactive INSERT.
4. **Pangaea Deal 생성** -- "Pangaea Ventures -- FCC Seed", Investor pipeline, **First meeting stage**(be415dbe-...), priority high, probability 20%, USD, close 2026-10-31
5. **Pangaea Meeting 생성** -- "Pangaea Ventures -- Intro Call (Andrew Haughian)", **2026-07-08 16:30 UTC = 09:30 PDT = 11:30 AM CDT(Austin)**, 30min, scheduled, intro_call, video. meeting id `45371cd8-5664-4c51-a97...`
6. **Attendees 2명** -- Andrew(external organizer accepted) + Yun-Young(internal required accepted)
7. **IMAP UID reset** -- mailcarrier_state last_processed_uid 770 으로 reset 후 catch-up 정상화(774 까지 진행). Playground 자동응답 캡처됨.

### Calendar 확인 결과
- URM /calendar 에서 7/8 미팅 정상 표시(11:30 AM-12:00 PM CDT). 시간대 정확.
- **알려진 버그**: `/meetings/[id]` 페이지 404. DB row 는 정상, Next.js route 파일 미생성. -> `src/app/(app)/meetings/[id]/page.tsx` 만들어야 함(아래 TODO).

---

## 3. 핵심 사실 (One-pager / 미팅에서 쓸 정확한 수치 -- IR Deck Ver1_6 기준)

- **Ask: $1M for 5% equity, $20M pre-money**
- Use of funds: $500K patent transfer / $200K tissue testing / $300K operations
- Traction: 19,000 t (9,000 confirmed + ~10,000 in motion), GCC+PCC 양쪽 validated
- Royalty: 3-5% of $250-350/ton = $7.5-$17.5/ton. 10-15년 supply contract
- 가격: Pulp $600-800 vs FCC $250-350 (~$350/ton saving)
- Revenue 전망: Y1 $2.9M(0.29M t) / Y2 $8.2M(0.82M t) / Y3 $22.4M(2.24M t)
- 밸류 논리: $20M = 0.9x Year-3 royalty. Royalty business 는 5-15x multiple
- Tech: CaCO3 in-situ on cellulose-nanofibril core (Strong Fiber-Mineral Bonding). 경쟁사는 physical mixing(Omya/Imerys) 또는 solid particle(Specialty Minerals/FulFill). FCC 만 tissue validated.
- 시장: Graphic 84M / Packaging 267M / Tissue 40-45M t/yr. Tissue ~2M t/yr FCC 신규시장(first ever filler in tissue)
- IP: 5 granted(Korea 2013-2025) + 7 pending(Korea/PCT/US, 확장 EU/JP/CN/IN/ID) + 3 SCI papers
- Team: Heo(CEO, ex-Samsung) / Seo(CTO, PhD&Postdoc SUNY, 충남대 교수, 해양 나노섬유 50+ 특허) / Lee(CPO, 충남대 석사, 정부 펄프연구소, 30+ 특허)
- "Two giants under NDA": 40-50% satellite PCC market(SMI/MTI) + 글로벌 top GCC maker(Omya). deck 에서는 blinded("the two giants") 처리.

---

## 4. 다음 세션 TODO (우선순위)

### A. 미팅 준비 (가장 중요, 미팅까지 ~11일)
1. **Pangaea portfolio + Andrew 이전 deals 리서치** -- 그가 backed 한 advanced materials 회사들, thesis 패턴 파악. FCC 와의 fit angle 도출. (web_search 활용)
2. **예상 질문 + 답변 준비** -- advanced materials VC 가 30분에 물을 8-12개: $1M 충분한가 / Y3 $22.4M risk 어디 / two giants NDA detail / exit 시나리오 / 경쟁 방어 / customer pipeline / unit economics / 다른 투자자 / founder background 등.
3. **Andrew pre-meeting email draft** -- one-pager v2 첨부, 7/5(토) 발송 권장. + 미팅 다음날(7/9) thank-you+next steps draft.

### B. 엔지니어링
4. **`/meetings/[id]` 404 fix** -- `src/app/(app)/meetings/[id]/page.tsx` 생성. party detail 페이지의 meeting 렌더 패턴 참고. (in-place PS patch + inline block 둘 다 제공 규칙)
5. (non-urgent) FC 자동응답 IMAP 캡처 실패 조사 -- FC 메일은 INBOX 에 있으나 engagement 미생성(Playground 형제는 캡처됨)
6. (non-urgent) IMAP graceful shutdown on Railway redeploy -- `src/lib/mail/`
7. (non-urgent) mailcarrier_state 의 role/shared kind stale entry 정리
8. (non-urgent) 빈 "15 min..." sequence 중복(`2d77575d-...`) archive

### C. 자동 진행 (액션 불필요, 모니터링만)
9. **2026-07-01: Intel Inside Day 5 자동 발송** -- 9개 enrollment 시스템 자동 처리
10. **2026-07-08 09:30 PDT: Pangaea 미팅** (Andrew calendar invite 이미 도착, accept 됨)
11. **late July: 4-week dormancy 만료** -- 6개 hold firm 에 Intel Inside 발송:
    - Ara `6c8ff4bb-810f-4a62-a9b3-2a77e5dc9a11`
    - Bain Cap `174b5996-41a7-44fc-a1e9-3767c6b26314`
    - Breakout `f49a8284-70c1-47c2-9473-5a0e765c5b1b`
    - Material Impact `744a668f-fbb2-46e5-bfa5-ce79692c52f4`
    - The Engine `0ea97617-28c5-40fb-a545-06a3b13f095f`
    - Creative Ventures `f31631a0-aa56-46fc-8533-ff3f83c4a602`
    - Part 5 enrollment 패턴 재사용. (Lux Capital 은 manual-only, Pangaea 는 이미 미팅 단계라 제외)

---

## 5. 주요 UUID 빠른 참조

| 항목 | UUID |
|---|---|
| org | b25de8f2-1020-482f-9012-183f63883169 |
| user | 551fc4a0-b365-47eb-bf2f-0c3f594001c0 |
| from_account (yunyoung.heo@) | 4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2 |
| Intel Inside sequence | ceccfb05-f735-4ebb-a28b-d352bd6b8aae |
| Pangaea party | 97d63e5e-5e8d-4719-b170-588f1d184d99 |
| Andrew contact | 7b954ce5-17bc-4282-b50e-9180660651d8 |
| Investor pipeline | de80525d-5537-4971-ad8f-d2080a8e65b0 |
| First meeting stage | be415dbe-f07a-4869-9989-254f27e25b0c |
| Pangaea meeting | 45371cd8-5664-4c51-a97... (full id: SQL 로 조회) |

---

## 6. 이번 세션 산출물 파일 (repo 보관용)

`docs/handoff/2026-06-26/` 폴더에 보관:
- 이 handoff md
- SQL 마이그레이션들 (이미 Supabase 에서 실행 완료, 기록 보관용):
  - 20260626008000_investor_enrich_batch8_emails.sql
  - 20260626009100_intel_inside_sequence_create_v2.sql
  - 20260626009200_intel_inside_add_two_firms.sql
  - 20260627000000_pangaea_andrew_backfill.sql
  - 20260627000200_pangaea_deal_and_meeting_v2.sql
- Marinebio_OnePager_v2.docx (IR deck 기반 정정 버전. 이게 최신, MarineBio_OnePager.docx 구버전은 폐기)

---

_생성: 2026-06-26 세션 종료 시. 다음 세션은 새로 시작 권장(이번 세션 매우 길어짐)._
