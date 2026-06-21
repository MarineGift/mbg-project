# HANDOFF - 2026-06-21 이메일 시퀀스 / 라이브 cold outreach / SMTP UI

> 이전 핸드오프(`docs/research/HANDOFF_2026Q3_investor_grant_pipeline.md`, commit `4e98169`)를 잇는 **세션 통합본**.
> 이 세션에서 한 일: ① deal-detail backfill, ④ CVC 4건 추가, ② 이메일 시퀀스 outreach 디버깅 + 기능 4종 빌드 + **실제 29 VC 라이브 발송**.

---

## 0. 현재 상태 (TL;DR)

- repo: `MarineGift/mbg-project`, branch `marinebiogroup`, **HEAD = `cbd6bcf`**
- 웹 서비스 `mbg-project` (push 시 자동 배포), 워커 `lucky-patience` (`npx tsx src/workers/all-workers.ts`)
- **이메일 시퀀스 드립이 이제 워커에서 상시 자동 발송됨** (Day 0/3/7). 더 이상 Run Now/외부 cron 불필요.
- **라이브 발송 완료**: 투자자 cold-outreach 시퀀스 `151d5454-...` 의 active 29건 -> 전원 `sent` (failed 0), 발신 `yunyoung.heo@marinebiogroup.com`. Day 3/7 후속은 워커가 자동 발송 예정.

---

## 1. 완료 항목

### (1) Deal detail backfill  [commit c9ecea6]
- 마이그레이션 `20260620370021_pipeline_seed_deal_details.sql`
- `source='pipeline_seed_2026Q3'` deal 92건에 owner_user_id / next_step / next_step_date / expected_close_date / probability_pct 채움.
- owner = `(select id from app.users where is_owner=true and is_active=true order by created_at limit 1)` = marinegift4u@gmail.com (HEO YunYoung).
- 멱등 가드 `where next_step is null`. 검증: Investors 78 / Government Grant 8 / Filler Suppliers 6.

### (2) CVC 투자자 4건 추가  [commit f2f6660]
- 마이그레이션 `20260620370022_global_investors_batch8.sql` (ASCII) + `20260620370023_investors_b8_intro_ko.sql` (UTF-8 BOM, 한글 intro).
- 추가: MC Global Innovation (JP), JSR Corporation (JP), Sumitomo Chemical (US), Asahi Kasei CVC (US). investor_profile priority='high', sector/stage focus, Investors/Cold-outreach deal seed(4).
- source: `investor_global_2026Q3_b8`.

### (3) 이메일 시퀀스 outreach - 디버깅 + 기능 빌드 + 라이브 발송

**근본 원인(왜 0건 발송이었나):** 상시 워커(`all-workers.ts`)가 mailcarrier+mailrun만 돌고 **시퀀스는 안 돌았음**. `processSequence`는 HTTP `/api/sequences/process`(Run Now) 또는 외부 cron으로만 실행됐는데 cron이 없었음 -> 29건이 한 번도 처리 안 됨.

**빌드된 기능:**
- **발송자 선택 in "New Sequence" 다이얼로그**  [commit c30d3ce] - `src/components/settings/sequence-form-dialog.tsx` (생성 시 From 계정 지정).
- **시퀀스 복제(Duplicate)**  [commit 4a422bc] - `src/lib/actions/email-sequences.ts` `duplicateSequence()` + `src/components/settings/email-sequences-client.tsx` 복제 버튼.
- **워커 시퀀스 드립 루프**  [commit a0c9707] - 신규 `src/workers/sequence-worker.ts` (`runSequenceWorker()`: 60초마다 `processSequence(null)`, admin 클라이언트, graceful shutdown, `--once`) + `src/workers/all-workers.ts`에 등록. **이게 자동 발송의 핵심.**
- **enroll contact null 버그픽스**  [commit cbd6bcf] - `src/lib/actions/email-sequences.ts`: `p_contact_id: contactId ?? ''` -> `?? null`. (contact 없이 enroll 시 빈 문자열을 uuid로 캐스팅하다 `invalid input syntax for type uuid: ""` 발생하던 것)
- **SMTP(sending) 편집 UI**  [commit 6a48541] - 아래 (5) 참조.

**검증/발송:**
- 테스트: copy 시퀀스 enrollment의 contact를 ceo@marine-gift.com으로 지정 후 재무장 -> 워커가 yunyoung.heo로 발송 -> 수신 확인 (message_id 발급). Gmail/ceo 양쪽 도착 확인.
- **라이브**: 아래 SQL 1회 실행으로 29건 재무장 -> 워커 자동 발송 -> `sent 29 / failed 0`.
```sql
update app.email_sequence_enrollments
set next_step_order = 0, next_send_at = now(), updated_at = now()
where sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and status = 'active';
```

### (4) SMTP(sending) 편집 UI  [commit 6a48541]
- 앱에 SMTP 설정 화면이 없었음(Inbound Mailboxes는 IMAP만 편집, SMTP 컬럼은 SQL backfill).
- 추가: 마이그레이션 `20260620370024_update_inbound_mailbox_smtp_rpc.sql` (RPC `app.update_inbound_mailbox_smtp`, `pgp_sym_encrypt` + IMAP과 동일 키 `CALENDAR_TOKEN_ENCRYPTION_KEY`) + 액션 `updateMailboxSmtp` + 편집 폼에 "SMTP (sending)" 섹션(host/port/TLS/username/app-password, 독립 "Save SMTP" 버튼).
- **RPC는 SQL Editor에 붙여넣어 적용 완료** (push만으론 RPC 안 생김).
- TLS 매핑(전송단과 일치): **587 + TLS체크 = STARTTLS**, 465 = SSL.

---

## 2. 핵심 ID / 상수

- 투자자 cold-outreach 시퀀스(원본, 라이브 대상): `151d5454-8efc-4ecb-90a6-ff4f0d18520d` ("15 min on a filler tech two mineral giants gave up on", 3 steps, from=yunyoung.heo `4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2`)
- 발신 계정 yunyoung.heo: mail.marinebiogroup.com:587, smtp_use_tls=false (작동), is_default
- Gmail 계정 marinegift4u@gmail.com (`1cfe939a-6a44-4b45-a132-ed59b45416e9`): smtp.gmail.com:587, **smtp_use_tls=false -> 530 STARTTLS 실패**. 발송용 미사용. 고치려면 `smtp_use_tls=true`.
- MBG Mailing Test party(테스트 대상): `8fd7b4ae-73b7-4d33-8fb5-f7876109eef7` (contacts: ceo@marine-gift.com, marinegift4u@gmail.com 등)
- 테스트 enrollment(copy 시퀀스): `a1f7fbc8-71b9-478a-adea-cbe4e865927a`
- contacts 테이블: `app.contacts (id, given_name, family_name, email, party_id)`
- parties 이름 컬럼: `app.parties.party_name` (NOT `name`)
- org owner user: `551fc4a0-b365-47eb-bf2f-0c3f594001c0`

---

## 3. 다음 세션 재개 포인트 / 알려진 이슈

1. **Day 3/7 후속 자동 발송 모니터링** - 워커 루프가 상시 도므로 후속 step이 자동 발송됨. `email_sequence_sends`에서 step_order=1,2 행이 그날 생기는지 확인.
2. **오픈율 보고** - 수신자가 열면 `app.email_tracking`에 쌓임(이전 블라스트 ~72%). 보고 쿼리 작성 필요.
3. **복제(duplicate) 발송계정 버그** - `duplicateSequence`가 원본 from(yunyoung.heo) 대신 Gmail/null로 떨어진 적 있음. `getSequenceFromAccountId`/copy 경로 점검 필요(미해결).
4. **테스트 아티팩트 정리(선택)** - "(copy)" 및 "삭제 - 15 min..." 시퀀스, 테스트 enrollment `a1f7fbc8`(step1 06-24 예약)는 테스트용. 정리하려면:
```sql
update app.email_sequence_enrollments set status='cancelled', updated_at=now()
where id='a1f7fbc8-71b9-478a-adea-cbe4e865927a'::uuid;
```
5. **Gmail 발송 활성화(원할 때)** - 새 SMTP UI에서 Gmail 편집 -> Use TLS/STARTTLS ON -> Save SMTP -> 워커 재시작. 또는 `update app.inbound_mailboxes set smtp_use_tls=true where address='marinegift4u@gmail.com';`
6. **재무장 중복 주의** - 재무장 SQL은 step_order를 0으로 리셋하므로 **여러 번 실행하면 step 0이 중복 발송**됨. 1회만.
7. `src/types/database.ts`는 stale(여러 라이브 컬럼 누락). 신뢰는 live DB(information_schema).

---

## 4. 적용된 마이그레이션 (이 세션)

- `supabase/migrations/20260620370021_pipeline_seed_deal_details.sql`  [c9ecea6]
- `supabase/migrations/20260620370022_global_investors_batch8.sql`     [f2f6660]
- `supabase/migrations/20260620370023_investors_b8_intro_ko.sql`        [f2f6660]
- `supabase/migrations/20260620370024_update_inbound_mailbox_smtp_rpc.sql`  [6a48541] -- **SQL Editor에 붙여넣어 RPC 생성 완료**

push는 파일 이력만 기록. 실제 RPC/데이터는 SQL Editor 실행으로 반영(완료).

---

## 5. 모니터링 쿼리 (참고)

```sql
-- 발송 집계 (최근 15분)
select snd.status, count(*) as n
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.sent_at >= now() - interval '15 minutes'
group by snd.status;

-- 실패 상세
select p.party_name, c.email, cm.error_message, snd.sent_at
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
join app.parties p on p.id = e.party_id
left join app.contacts c on c.id = e.contact_id
left join app.communications cm on cm.id = snd.communication_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.status = 'failed'
order by snd.sent_at desc;
```
