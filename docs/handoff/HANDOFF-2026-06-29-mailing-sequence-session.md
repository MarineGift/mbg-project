# HANDOFF - mbg-project 메일링/시퀀스 세션 (2026-06-29)

org_id `b25de8f2-1020-482f-9012-183f63883169` · Supabase `ogenmrgxwhpbfepeldqx` · created_by `551fc4a0-b365-47eb-bf2f-0c3f594001c0`
Repo PUBLIC `MarineGift/mbg-project` branch `marinebiogroup` · push -> Railway 자동배포 (urm.marinebiogroup.com)
로컬 `C:\dev\mbg-project` · `next.config.mjs`에 `typescript.ignoreBuildErrors:true`(=tsc 에러로 배포 안 막힘)

---

## A. 완료(배포됨)

1. **Bulk mail 템플릿 필터 - Pipeline stage 모드** (commit 6987612)
   - `mailing/page.tsx`: stages에 `code`, email_templates에 `stage_code` 로드 추가
   - `mailing/bulk-mail-client.tsx`: 파이프라인 코드(복수 investors/filler_suppliers) -> 템플릿 module(단수 investor/filler_supplier) 매핑 후 module+stage_code로 템플릿 필터. 매칭 stage 템플릿 없으면 module 전체 유지(빈 목록 방지). audience 변경 시 선택 템플릿 자동 해제.

2. **`let stages` 타입 누락(TS2322) 수정** - page.tsx 선언에 `code:string|null` 추가.

3. **기존 tsc 에러 15개 전부 정리** (제 변경과 무관, ignoreBuildErrors로 가려져 있던 것)
   - `lib/queries/calendar.ts`(9): `ymd.split('-').map(Number)` -> `as [number,number,number]`
   - `calendar/page.tsx`: `WEEKDAY_CODES[d.getDay()]!`
   - `settings/inbound-mailboxes-client.tsx`: onSaved에 smtp_host/port/use_tls/username + has_smtp_pw 추가
   - `lib/actions/email-sequences.ts`: `p_contact_id:(contactId??null) as string`, 그리고 숨어있던 `p_recipient_email` -> rpc 인자 `} as never` (commit 8083c3d). 생성타입(database.ts)이 실제 enroll_in_sequence보다 낡음.
   - `lib/queries/bulk-mail.ts`: `loadActiveBlocklist(supabase as unknown as Parameters<typeof loadActiveBlocklist>[0], orgId)`
   - `lib/reminders/process.ts`: upsert 페이로드 `} as never`

4. **Bulk mail 템플릿 필터 - Pick parties 모드** - 선택 party들의 `party_type_id` -> `PARTY_TYPE_CODE_BY_ID`(`@/types/party-type`)로 단일 module 도출, 그 module 템플릿만. 혼합/없음이면 전체.

5. **콜드 메일 템플릿 본문 교정** ("Investor Cold Outreach - Advanced Materials")
   - 문제: 빈 `[...]` 플레이스홀더 발송 + 본문 서명 + 자동서명 = 서명 2개
   - 수정: 확정본 카피로 교체, 본문 끝 서명 제거(자동서명 1회), 인사 `{{contact.given_name}}`(fallback 문법 없음)
   - 최종 제목: `9,000-ton order confirmed - paper that beats plastic on cost and quality (Seed round)`

6. **4단계 이메일 시퀀스 생성** "Investor Cold Outreach - FCC Seed" (SQL)
   - 스텝 0/1/2/3, day_offset 0/7/14/21, From=yunyoung.heo@marinebiogroup.com 자동연결
   - 본문: 9,000톤 확정/tissue/IP 5건+7건/royalty·asset-light/first seed. Day0=신규, 7=bump, 14=tissue, 21=breakup

7. **"예약시각(Scheduled start)" 기능 신규** (commit 3596576)
   - DB: `email_sequences.start_at timestamptz` + `trg_enrollment_apply_start_at`(BEFORE INSERT, enrollment.next_send_at을 start_at으로 핀, 단건/대량 enroll 모두 자동)
   - `lib/actions/sequence-sender.ts`: `get/setSequenceStartAt`
   - `settings/sequence-form-dialog.tsx`: datetime-local 입력(저장=로컬->UTF ISO, 로드)

---

## B. 미완료 / 다음 작업

1. **[먼저] `fix-bulk-enroll.sql` 실행** - bulk_enroll_filtered RPC의 `left join investor_profile`가 party 행을 곱해(>1 profile) 프리뷰 부풀림(168 vs 139) + 중복 enroll로 `idx_unique_active_enrollment`(sequence_id,party_id,active) 23505. 수정: priority를 EXISTS로, per-party enroll에 unique_violation 가드. **함수 create-or-replace라 SQL Editor 실행만으로 반영.**
2. 콜드 템플릿/시퀀스 본문이 실제 DB에 반영됐는지 최종 확인(사용자가 적용 여부 미확정).
3. 시퀀스 enroll -> Scheduled start(6/30 08:00) -> 실제 발송 E2E 확인.
4. (선택) 후속 스텝(7/14/21일)도 매주 정확히 08:00에 가도록 워커 time-of-day 고정.
5. (선택) 머지 fallback: `given_name` 비면 "there" 등으로. 현재 엔진은 `| fallback` 미지원.
6. (선택) Supabase 타입 재생성 -> email-sequences/start_at의 `as never`/`as any` 캐스트 제거.

---

## C. 핵심 사실 / 주의점 (다음에 시간 아끼려면)

**메일 머지 엔진** (`lib/email/send-outbound.ts`)
- 토큰: `{{party.name|party_name|company_name|fund_name}}`=party_name; `{{contact.given_name|contact.firstName|contact_first_name}}`=given_name; `{{contact.family_name|full_name|email|title|...}}`; `{{sender_name|sender_title}}`.
- **`| fallback` 문법 없음**(그대로 노출됨). 자동서명 `useSignature` 기본 true -> 템플릿 본문에 서명 넣지 말 것.

**Bulk mail dedup** (`lib/queries/bulk-mail.ts`)
- already_sent: communications에서 organization_id + channel='email' + direction='outbound' + template_id + party_id + status in ('sending','sent','delivered'). 재발송 테스트하려면 그 행 삭제(자식 email_tracking/engagement_email_details 없으면 communications만 삭제 가능).
- 발송 버튼은 **Preview recipients 먼저** 눌러야 활성(`checkedCount=checked.size`, preview가 checked 채움).

**시퀀스 스키마**
- `email_sequence_steps`: subject + body_plain **직접 저장**(템플릿 참조 안 함), step_order **0-based**, day_offset=시작 누적일.
- `email_sequences` 컬럼: name, description, status(draft|active|paused|archived), from_account_id(=inbound_mailboxes.id), quiet_hours(jsonb), **start_at**(신규).
- enrollment_status: active|completed|cancelled|failed|paused. send_status: pending|sent|skipped|bounced|failed.
- `idx_unique_active_enrollment` = UNIQUE (sequence_id, party_id) WHERE status='active'. party당 active 1개, 중복=23505.
- 스케줄: enrollment.next_send_at이 발송시각. start_at 트리거가 첫 발송을 핀. 후속은 advance_enrollment RPC + day_offset.
- **quiet_hours start/end = 막는(blocked) 구간**(보내는 창 아님). 예: 18:00-08:00 막음 -> 08:00-18:00만 발송. 라벨은 "Send window"지만 내부는 quiet.
- `bulk_enroll_filtered`는 **public 스키마**, party 루프 -> party당 enroll_in_sequence 1회.

**시각 변환**: Austin CDT(UTC-5). 08:00 CDT = 13:00 UTC.

**배포/전달 관례**
- 인라인 단일행 `P($f,$o,$n)` .Replace 블록이 사용자 PS 5.x에서 가장 안정적. **here-string은 실패한 적 있음**. 멀티라인 new는 `+ "\`n" +` 연결로. 새 문자열에 `"` 있으면 single-quoted, `'` 있으면 double-quoted PS literal로.
- 멀티파일 패치: ReadAllText -> CRLF->LF -> .Replace(리터럴) -> WriteAllText(UTF-8 no-BOM). 멱등 가드.
- repo 파일은 `raw.githubusercontent.com`로 읽기((app)->%28app%29). **GitHub API 레이트리밋 시 `git clone --depth 1` (codeload 허용)로 우회** 가능.
- next.config ignoreBuildErrors=true라 tsc 에러는 배포 안 막지만, 커밋 전 `npx tsc --noEmit` 0 유지가 관례.

**Finish 블록**: `npx tsc --noEmit` -> `git add -A` -> commit -> `git pull --rebase` -> `git push origin marinebiogroup`.

---

## D. 다음 세션 작업 계획 - Paper Mill 연락처 이메일 보강

**목표**: `party_type='paper_mill'` party들 중 이메일 연락처가 없는 곳에 담당자/이메일을 추가(메일링·시퀀스 발송 대상 확대).

**방법 (3채널 병행)**
1. **웹서치**: "<회사명> contact / sales / procurement / paper mill" 로 공식 도메인·담당부서 확인.
2. **홈페이지**: Contact/About/Team 페이지에서 일반 inbox(info@/sales@/procurement@) + 가능하면 담당자.
3. **LinkedIn**: 구매/조달/R&D 의사결정자 검색 -> 이름/직책/회사. (LinkedIn은 이메일 직접 노출 X -> 도메인 패턴으로 추정 후 검증.)

**이메일 처리 원칙**
- 추정 시 패턴 명시(firstname.lastname@domain, f.lastname@, info@ 등)하고 검증 단계 표시. 미검증 주소는 바운스/스팸·도메인 평판 위험 -> 가능하면 일반 inbox(info@/sales@) 우선, 담당자 추정은 보조.
- 잘못된 주소 대량 발송은 SPF/DKIM/도메인 평판 손상. mail-tester/소량 테스트 권장.

**스코핑 SQL (이메일 연락처 없는 paper_mill 수/목록)**
```sql
select p.id, p.party_name, p.country_code, p.website
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and pt.code = 'paper_mill'
  and p.deleted_at is null
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and c.deleted_at is null and c.email is not null)
order by p.party_name;
```

**저장 대상**: `app.contacts`. 주요 컬럼:
- 필수: `organization_id`, `party_id`, `contact_type_id`(FK contact_types - 기존 paper_mill 연락처와 동일 값 사용; 아래 SELECT로 확인)
- 권장: `email`, `given_name`, `family_name`, `full_name`, `title_text`, `linkedin_url`, `is_primary`(true=발송 기본), `is_decision_maker`, `role_category`, `seniority_level`, `source`('web'/'linkedin'/'homepage'), `phone_e164`

```sql
-- contact_type_id 확인(기존 연락처에서 가장 흔한 값)
select contact_type_id, count(*) from app.contacts
where organization_id='b25de8f2-1020-482f-9012-183f63883169'
group by 1 order by 2 desc;

-- INSERT 템플릿(값만 채우면 됨)
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, given_name, family_name,
   full_name, title_text, linkedin_url, is_primary, is_decision_maker, source)
values
  ('b25de8f2-1020-482f-9012-183f63883169', '<PARTY_ID>', <CONTACT_TYPE_ID>,
   'info@example.com', null, null, null, null, null, true, false, 'homepage');
```

**워크플로우(효율)**: 다음 세션에 Claude가 (1) 위 스코핑 SQL 결과(또는 회사 리스트)를 받아 웹서치로 회사별 도메인/담당자/이메일을 리서치 -> (2) party_id에 매핑된 contacts INSERT SQL(또는 CSV+mover) 일괄 생성 -> (3) 사용자가 Supabase 실행. 회사명 ILIKE 매칭이 모호하면 party_id를 함께 받는 게 정확.

**먼저 해둘 것**: 이번 세션 미완료 B-1(`fix-bulk-enroll.sql`)을 먼저 실행해두면, 보강된 연락처로 바로 대량 enroll/발송 테스트 가능.
