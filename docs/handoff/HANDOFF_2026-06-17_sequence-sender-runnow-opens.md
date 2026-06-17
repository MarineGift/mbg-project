# URM CRM 작업 핸드오프 — 2026-06-17 (이메일 시퀀스: 발신자 라우팅 · Run Now · 수신확인)

대상: YunYoung / mbg-project (Next.js 14.2 + TypeScript + Supabase `app` schema)
레포: **MarineGift/mbg-project** (PUBLIC), 브랜치 **`marinebiogroup`**
배포: `marinebiogroup`에 push -> Railway 자동배포. 웹 서비스 **`mbg-project`** (www/urm.marinebiogroup.com), 워커 서비스 **`lucky-patience`** (둘은 분리됨). Railway 프로젝트명 `joyful-celebration`.

이 세션 최종 커밋: **`c1065a3`** (그 위 `7d88b75`, `388bc00`, `fb3744d`, `09bd7f3`, `741447b`, `6de5de9`).

---

## 0. 운영 메모 (다음 세션 필독)

- **레포가 PUBLIC이다.** 파일을 사용자에게 업로드시키지 말고 직접 읽어라:
  `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<경로>`
  (라우트 그룹 괄호는 URL 인코딩: `(app)` -> `%28app%29`. curl이면 따옴표로 감싸 그대로 사용.)
  또는 `git clone --depth 1 --branch marinebiogroup https://github.com/MarineGift/mbg-project.git`.
- **마이그레이션은 CLI가 아니라 Supabase SQL Editor에서 수동 실행한다.** `supabase/migrations/*.sql`은 사실상 기록/스크립트 보관용이다. 파일 push만으로는 DB에 적용되지 않는다. 새 DDL을 만들면 "SQL Editor에서 실행하라"고 명시할 것.
- **파일 전달 컨벤션:** 산출물은 다운로드로 주고, ASCII 전용 PowerShell mover로 `$env:USERPROFILE\Downloads` -> repo 경로 이동(`Unblock-File`, `Move-Item -Force`, 영어 콘솔), 이어서 finish block(`npm run build` -> `git add` -> `git status -sb` -> `commit` -> `git push origin marinebiogroup`). push가 production 배포다.
- **PowerShell 5.x:** 콘솔 출력은 ASCII만(한글은 CP949로 깨져 구문 오류). 한글은 UTF-8 BOM `.md`에만.
- **수동 처리기 트리거(cron):** `POST https://urm.marinebiogroup.com/api/sequences/process` 헤더 `x-cron-secret: <CRON_SECRET>`. 이번 세션에서 쓴 값: `a3f8e1c97b24d605fae8923c1d47b60e9f5128a7c3e0b94d6172fa8be35c0d49` (Railway env `CRON_SECRET`).
- **Railway 워커(`lucky-patience`)의 배포 시 SIGTERM은 정상**(배포 교체에 의한 graceful shutdown). 재가동 후 `get_due_enrollments` UID 추적으로 따라잡으므로 메일 유실 없음. Restart Policy=**Always** 설정됨. (Teardown ON은 선택 권장 — 옛 워커 중복폴링 방지.)

---

## 1. 이번 세션에서 한 일 (요약)

이메일 **시퀀스 발송 파이프라인**을 실사용 가능한 상태로 완성하고, 투자자 콜드아웃리치 1차를 실제 발송했다.

1. **발신자 라우팅을 계정 기반으로 전환** (`6de5de9`, `741447b`, migration `…130000`)
   - 시퀀스별 발신 계정을 `app.email_sequences.from_account_id`(= `app.inbound_mailboxes` id, 작성/답장 From 드롭다운과 동일한 계정군)로 지정.
   - 처리기가 자체 transport를 버리고 **`sendOutboundEmail()`에 위임** (답장/작성/벌크와 동일 경로). 발신 계정 변경 = SQL 한 줄, 코드/재배포 불필요.
   - 투자자 시퀀스 발신자 = **yunyoung.heo@marinebiogroup.com** (display "YunYoung Heo").
   - 과거 `from_kind`(env 종류) 방식은 폐기. 컬럼 드롭됨.

2. **처리기 버그 2개 수정** (`09bd7f3`) — production에서 라이브 검증 완료
   - **머지 버그:** `renderMergeFields(template, data)`는 **평면 키맵**(`"contact.firstName"`)을 받는데 중첩 객체를 넘겨 모든 토큰이 공란("Hi ,")이었음. -> 평면맵으로 수정, `firstName` 없으면 `"there"` 폴백.
   - **advance 버그:** 라이브 `advance_enrollment`는 **6-인자**(`p_enrollment_id, p_step_id, p_step_order, p_communication_id, p_is_last_step, p_status`). 처리기가 2-인자 무동작 오버로드를 불러 step이 안 올라가 **Day 0 재발송 위험**. -> 6-인자 호출로 수정, `email_sequence_sends` insert는 advance가 하므로 처리기 자체 insert 제거.

3. **시퀀스별 Run Now + 전체 Run All** (`fb3744d`)
   - `processSequence(sequenceId?)`가 due 행을 해당 시퀀스로 필터.
   - API route가 `?sequence_id=` 읽어 전달. 각 행 **Run Now**(그 시퀀스만), 상단 **Run All**(전체=cron과 동일).

4. **수신확인(Opens) 팝업** (`388bc00`, `c1065a3`)
   - 각 시퀀스 행 **Opens** 버튼 -> 모달: Sent/Opened/Open rate/Clicked 요약 + 수신자별(오픈수·최초오픈·클릭) 표 + Refresh.
   - `app.communications`(external_data.sequence_id로 필터) ⋈ `app.email_tracking`.
   - 회사명은 **investor 상세 링크**(`/{party_type}/parties/{id}`, 새 탭). `c1065a3`에서 추가.

5. **정리** (`7d88b75`)
   - 폐기된 `20260617120000_email_sequences_from_kind.sql` 삭제(from_account로 대체됨).

### 라이브 운영 결과 (이 세션 중 실제 수행)
- 투자자 콜드 **29건 발송 성공** (From "YunYoung Heo <yunyoung.heo@marinebiogroup.com>", 인사말 정상 치환). 첫날 오픈율 ~72%(21/29). 클릭 0. 다회 오픈: Boost VC, Pangaea, Ecliptic 등.
- **중복 Day 0 방지:** 29건을 보정 SQL로 step 0->1, `next_send_at = enrolled_at + 3일`(**Day 3 = 2026-06-20 18:16:56 UTC**)로 정렬. 현재 29건 `next_step_order=1, status=active`.
- **MBG Mailing Test로 3수정 라이브 검증:** Gmail 테스트 연락처 enroll -> 트리거 -> From=yunyoung.heo@, body "Hi Gmail," 치환, `next_step_order` 0->1 확인. 테스트 enrollment는 cancel 정리.

---

## 2. 시퀀스 발송 파이프라인 — 동작 흐름 (전체 그림)

```
enroll_in_sequence (RPC)              -> app.email_sequence_enrollments (status=active, next_step_order=0, next_send_at=now)
  └ Bulk Enroll UI / enrollParty 액션 / 직접 RPC

cron 또는 Run Now
  -> POST /api/sequences/process [?sequence_id=]   (x-cron-secret)
     -> processSequence(sequenceId?)
        1) get_due_enrollments()  (RPC, public)  : status=active AND next_send_at<=now AND step_order=next_step_order
                                                    LEFT JOIN LATERAL app.contacts (enrollment.contact_id 우선 -> primary -> 최古)
                                                    is_last_step 계산해서 반환
        2) (sequenceId 있으면) 그 시퀀스 행만 필터
        3) 시퀀스별 from_account_id 조회 (app.email_sequences)
        4) renderMergeFields(평면맵)로 subject/body 치환
        5) sendOutboundEmail({ mailAccountId: from_account_id, skipWhitelist:true, useSignature:true,
                               externalData:{source:'sequence', sequence_id, step_id, enrollment_id, step_order} })
             -> 계정 해석/SMTP 복호화/transport/서명/오픈픽셀/communications insert/email_tracking insert
        6) advance_enrollment(6-arg, status sent|failed|skipped)
             -> email_sequence_sends insert + next_step_order/next_send_at 전진 (마지막 step이면 status=completed)

수신확인
  -> getSequenceOpenReport(sequenceId)
     communications(external_data.sequence_id=seq) ⋈ email_tracking -> 요약 + 수신자별 오픈
```

발신 계정을 바꾸려면 (코드 X, 재배포 X):
```sql
UPDATE app.email_sequences SET from_account_id =
  (SELECT id FROM app.inbound_mailboxes WHERE organization_id='b25de8f2-1020-482f-9012-183f63883169'
     AND lower(address)='<원하는주소>' AND is_active=true LIMIT 1)
WHERE id='<sequence_id>';   -- NULL이면 org 기본 계정
```

---

## 3. 핵심 파일 맵

| 파일 | 역할 / 핵심 |
|---|---|
| `src/lib/utils/sequence-processor.ts` | `processSequence(sequenceId?)`. due 조회 -> (필터) -> from_account 조회 -> 머지(평면맵, firstName 폴백 "there") -> `sendOutboundEmail` -> `advance_enrollment`(6-arg). 반환 `{processed,sent,failed,skipped, errors?}`. |
| `src/app/api/sequences/process/route.ts` | cron 엔드포인트. `x-cron-secret`/`Authorization: Bearer` 인증. `?sequence_id=` 읽어 `processSequence`에 전달. GET=POST. |
| `src/lib/actions/email-sequences.ts` | `triggerSequenceProcessor(sequenceId?)`(API로 fetch, `?sequence_id=` 부착, 반환 `{processed,sent,failed,skipped,errors?}`), `createSequence/updateSequence/archiveSequence/getSequenceForEdit`, bulk-enroll 계열, `enrollParty`(RPC `enroll_in_sequence` 호출). |
| `src/components/settings/email-sequences-client.tsx` | 시퀀스 목록 UI. 행별 **Run Now**(`runProcessor(seq.id)`)·**Opens**(`setOpensTarget`)·Bulk Enroll·Edit·Archive, 상단 **Run All**(`runProcessor()`). `runningSeqId` 상태로 행/전체 로딩 구분. |
| `src/lib/actions/sequence-opens.ts` | `getSequenceOpenReport(sequenceId)`. communications(external_data.sequence_id) ⋈ email_tracking, parties+party_types로 회사명·type코드 해석. 반환 `{sent,opened,clicked,openRate,rows[]}`. row에 `partyId, partyType(code), partyName`. |
| `src/components/settings/sequence-opens-dialog.tsx` | 수신확인 모달. 열릴 때/Refresh 시 액션 호출(스냅샷). 회사명 -> `/{partyType}/parties/{partyId}` 새 탭 링크. |
| `src/lib/actions/sequence-sender.ts` | `getSequenceFromAccountId`, `setSequenceFromAccount`, `previewSequenceStep` (Edit 다이얼로그의 Sender&Preview 패널용). |
| `src/components/settings/sequence-sender-preview.tsx` | Edit 다이얼로그 내 발신계정 선택 + 발송 미리보기 패널. |
| `src/components/settings/sequence-form-dialog.tsx` | New/Edit 다이얼로그. **기존(Edit)일 때만** `SequenceSenderPreview` 렌더(New에는 없음 — 후보 참고). |
| `src/lib/email/send-outbound.ts` | `sendOutboundEmail(...)` — 모든 발신의 공통 경로(계정 해석/SMTP 복호화/서명/오픈픽셀/communications). 시퀀스가 위임. (관련: `src/lib/email/mail-accounts.ts`, `src/lib/actions/mail-account-options.ts`) |
| `src/lib/utils/merge-fields.ts` | `renderMergeFields(template, flatMap)` — **평면 키맵**(`"contact.firstName"`) 필수. |
| `src/workers/all-workers.ts` | mailcarrier(IMAP 수신) + mailrun(벌크 큐) 동시 실행. Railway 워커 서비스 start: `npx tsx src/workers/all-workers.ts`. |
| `supabase/migrations/20260617130000_email_sequences_from_account.sql` | `from_account_id` 추가 + 투자자 시퀀스 지정 + `from_kind` 드롭. (SQL Editor에서 이미 실행됨.) |

---

## 4. DB 객체 / 상수

테이블: `app.email_sequences`(+ `from_account_id uuid -> app.inbound_mailboxes`), `app.email_sequence_steps`, `app.email_sequence_enrollments`, `app.email_sequence_sends`, `app.communications`, `app.email_tracking`(`communication_id, sent_to, subject, sent_at, first_opened_at, open_count, click_count, party_id, contact_id`), `app.inbound_mailboxes`, `app.parties`(`party_type_id` -> `app.party_types.code`), `app.contacts`.

ENUM: `app.send_status` = pending/sent/skipped/bounced/failed. `app.enrollment_status` = active/completed/cancelled/failed. `app.email_sequence_status` = draft/active/paused/archived.

RPC(public):
- `get_due_enrollments()` -> due 행(+`is_last_step`). 조건: active AND `next_send_at<=now()` AND `step_order=next_step_order`. 연락처는 LEFT JOIN LATERAL(enrollment.contact_id 우선).
- `advance_enrollment(p_enrollment_id uuid, p_step_id uuid, p_step_order int, p_communication_id uuid, p_is_last_step boolean, p_status app.send_status)` -> `email_sequence_sends` insert + next_step_order/next_send_at 전진(마지막이면 completed).
- `enroll_in_sequence(p_organization_id, p_sequence_id, p_party_id, p_contact_id, p_enrolled_by)` -> enrollment_id. **unique `idx_unique_active_enrollment` on (sequence_id, party_id) partial(active)** => party당 active 1개. 중복 시 23505.
- `bulk_enroll_filtered(...)` (Bulk Enroll UI 백엔드, dry-run 지원).

중요 ID:
- ORG: `b25de8f2-1020-482f-9012-183f63883169`
- 투자자 콜드아웃리치 시퀀스: **`151d5454-8efc-4ecb-90a6-ff4f0d18520d`** (3 step: Day 0/3/7, step_order 0/1/2). 발신=yunyoung.heo@.
  - 보관(archived) 중복본: `025f2c6f-4fa5-4126-bf1c-b2ea9ba96704`, `87050eeb-8cc2-4b68-b2d5-c1a5cd9903af`.
- MBG Mailing Test party(테스트 발송용, 개인메일 6): **`8fd7b4ae-73b7-4d33-8fb5-f7876109eef7`** — 연락처: ceo@marinapad.kr, ceo@marine-gift.com(primary), ceo@marinepad.com, marinegift4u@gmail.com(`125b142d-04c0-49f4-8965-d50c12a3604e`), marinepad@naver.com, moreworld@marinebio.kr.
- yunyoung.heo@ inbound_mailbox id: `4b07c210-8f28-4ad1-a04c-bc5ad6ded8d2`.
- Supabase project ref: `ogenmrgxwhpbfepeldqx`.
- 주의: `app.users`에 yunyoung/heo 이메일 행이 없다(enroll의 p_enrolled_by는 NULL 허용).

---

## 5. 운영 방법 (How-to)

**시퀀스 발송:** Mailing -> Email Sequences -> 행에서 **Bulk Enroll**(필터로 대상 등록, Preview로 수 확인; 발송 안 함) -> **Run Now**(그 시퀀스의 **지금 due**인 것만 즉시 발송). 미래 예약(Day 3 등)은 `next_send_at` 시각이 돼야 나간다. cron이 자동으로도 돈다.
**발신자/미리보기:** 행 **Edit** -> Sender & Preview 패널에서 계정 선택·미리보기.
**수신확인:** 행 **Opens** -> 요약+수신자표, 회사명 클릭=상세, **Refresh**로 갱신(스냅샷; 자동갱신 아님). +3h/+6h/+1d에 다시 열거나 Refresh.
**수동 트리거(전체):** `POST /api/sequences/process` (x-cron-secret). 특정 시퀀스만: `?sequence_id=<id>`.

---

## 6. 알려진 한계 / 주의

- **party당 active enrollment 1개**(unique 제약). MBG Test처럼 한 party에 연락처 6개여도 enrollment는 1개 -> 한 번에 1개 연락처로만 발송. 6개 다 테스트하려면 contact_id 바꿔 enroll->trigger->cancel 반복.
- UI **"TOTAL SENT" 컬럼이 0**으로 보일 수 있음(별도 stale 집계). 실제 발송은 `communications`/`email_sequence_sends`/Opens 팝업으로 확인.
- `sendOutboundEmail` 위임 시 **List-Unsubscribe 헤더가 빠진다**(콜드아웃리치 deliverability 사소한 약점).
- **오픈은 과소집계**(이미지 차단 메일함). 과대집계는 없음.
- `processSequence` 반환 타입 선언은 `{processed,sent,failed,skipped}`인데 `errors`도 함께 반환(빌드는 `Skipping validation of types`라 통과). 정리하려면 반환 타입에 `errors?` 추가.
- New Sequence 다이얼로그엔 Sender&Preview 패널이 없음(Edit에만). 필요 시 추가.
- 워커(`lucky-patience`)와 웹(`mbg-project`)이 별 서비스지만 워커도 배포마다 `next build`까지 함(메모리 스파이크 ~530MB). 동작엔 무해, 원하면 워커 빌드 최소화 가능.

---

## 7. 미해결 / 다음 세션 후보

- [ ] **2026-06-20 Day 3 발송 후 검증:** Opens 팝업 Refresh로 (a) 29건 `next_step_order` 1->2 전진(advance 라이브 정상), (b) Day 3 오픈율 확인.
- [ ] (선택) 워커 안정화: `lucky-patience` **Teardown ON**(중복폴링 방지), 워커 빌드 최소화.
- [ ] (선택) New Sequence에도 Sender&Preview 패널.
- [ ] (선택) `processSequence` 반환 타입에 `errors?` 명시.
- [ ] (선택) List-Unsubscribe 헤더 보존(콜드아웃리치 deliverability).
- [ ] **무관 untracked 파일 정리:** `scripts/import-linkedin-messages.ts`, `sql/verify_linkedin_import.sql` (이번 작업과 무관, git status에 `??`로 계속 뜸). 필요 없으면 삭제. (`cleanup_dead_files.ps1` 3번 주석 해제용 블록 있음.)

---

## 8. 커밋 로그 (이 세션)

```
c1065a3 feat(sequences): link company name in Opens popup to party detail page
7d88b75 chore(sequences): remove superseded from_kind migration (replaced by from_account_id)
388bc00 feat(sequences): read-receipts (Opens) popup per sequence
fb3744d feat(sequences): per-sequence Run Now (sequence_id filter) + correct run-result summary
09bd7f3 fix(sequences): merge flat-map + firstName fallback; advance_enrollment full 6-arg call (stops step re-send)
741447b feat(sequences): sender-account select + send-document preview in edit dialog (reuses compose account list)
6de5de9 refactor(sequences): delegate sending to sendOutboundEmail; per-sequence from_account_id (reuses compose account dropdown)
```
(그 이전 `c55ef63`, `01e38b5`는 폐기된 from_kind 접근 — 히스토리에만 존재.)
