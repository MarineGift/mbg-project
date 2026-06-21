# HANDOFF (addendum) - 2026-06-21b : duplicate from-account 버그픽스 + 오픈율 보고 SQL

> 직전 핸드오프 `docs/research/HANDOFF_2026-06-21_email_sequence_live_outreach.md` (HEAD `cbd6bcf`) 에 이어지는 **후속 작업분**.
> 이 작업에서 한 일: ① duplicateSequence 발송계정 버그(미해결 항목 #3) 수정, ② 오픈율/발송 모니터링 보고 SQL 정리, ③ Day 3/7 드립 자동발송 모니터링 쿼리.

---

## 0. TL;DR

- duplicate 시퀀스가 발신계정을 **Gmail/null로 흘리던 버그의 근본 원인 확정 + 수정**.
- 오픈율 보고용 검증된 SQL 세트(`docs/research/sequence_reports.sql`) 추가 — 스키마/조인 경로 전부 라이브 코드로 검증.
- 적용 방식: `email-sequences.ts`는 **in-place 패치**(다운로드 X), 신규 파일 2개는 mover로 이동. 단일 스크립트 `apply_session_2026-06-21b.ps1` 가 셋 다 처리.

---

## 1. duplicateSequence 발송계정 버그 (resume #3) — 수정 완료

**증상:** 복제한 시퀀스가 원본 발신계정(yunyoung.heo) 대신 Gmail/null 로 발송됨 → Gmail 계정은 `smtp_use_tls=false` 라 `530 STARTTLS` 실패.

**근본 원인 (코드 추적 결과):**
- 발송 시 from 결정은 `src/lib/email/mail-accounts.ts` `resolveOutboundMailAccount()` 가 담당: **explicit `from_account_id` > reply 규칙 > `is_default` 계정** 순. 시퀀스(신규 메일)는 `from_account_id` 가 null 이면 org 의 active·smtp-ready `is_default` 계정으로 resolve.
- `processSequence` 는 `mailAccountId: seqAccountMap.get(sequence_id) ?? null` 로 위 함수에 위임 (`src/lib/utils/sequence-processor.ts`).
- `duplicateSequence` (`src/lib/actions/email-sequences.ts`) 는 원본 `from_account_id` 가 **명시값일 때만** 복제본에 복사하고, **null 이면 복제본도 null** 로 남김 → 복제본은 발송 시점의 default 에 떠다님. 과거 default 가 깨진 Gmail 이라 "Gmail/null 로 떨어지는" 현상 발생.

**수정 (commit 예정):** `duplicateSequence` 에서 원본 `from_account_id` 가 null 이면 `resolveOutboundMailAccount(supabase, orgId, {})` 로 **현재 effective default 를 resolve 해서 복제본에 명시적으로 pin**. import 추가: `resolveOutboundMailAccount` from `@/lib/email/mail-accounts`.
- 효과: 복제본이 더 이상 발송 시점 default 에 떠다니지 않고, 복제 시점에 동작하는 발신계정(현재 yunyoung.heo, is_default·smtp-ready)으로 고정됨.
- 명시값(원본이 from 지정한 경우, 예: 라이브 시퀀스 `151d5454`=`4b07c210`)은 기존대로 verbatim 복사.

**검증 SQL:** `sequence_reports.sql` [H] — `from_account_id IS NULL` 시퀀스 목록 + 현재 default 계정 확인.

---

## 2. 오픈율 / 모니터링 보고 SQL (resume #1, #2) — 추가

신규 파일 `docs/research/sequence_reports.sql` (읽기 전용 SELECT 모음, ASCII). 조인 경로는 라이브 코드로 검증:
- 성공 발송 시 `advance_enrollment` 가 `email_sequence_sends.communication_id` + `step_order` 기록.
- `sendOutboundEmail` 이 발송당 `email_tracking` 1행 생성(같은 `communication_id`).
- 오픈 조인: `email_tracking.communication_id = email_sequence_sends.communication_id`.
- 오픈 컬럼: `email_tracking.open_count`(>0 이면 열림), `first_opened_at`, `click_count`, `sent_at`, `sent_to`, `open_token`.

쿼리 목록:
- [A] 시퀀스 발송상태 요약
- [B] step 별 발송+오픈 (Day0/3/7) — **오픈율 핵심**
- [C] 시퀀스 전체 오픈율
- [D] 수신자별 상세(누가 몇 번 열었나)
- [E] 실패 상세
- [F] 최근 24h 드립 모니터(워커 자동 Day3/7 발송 확인)
- [G] org 전체 일자별 오픈율(시퀀스+블라스트 통합)
- [H] duplicate-bug 감사 + default 계정 확인

라이브 시퀀스 id `151d5454-8efc-4ecb-90a6-ff4f0d18520d` 가 예시에 박혀 있음(다른 시퀀스는 id 교체).

---

## 3. 적용 방법 (mover / patch)

다운로드 폴더: `%USERPROFILE%\Downloads`. 단일 스크립트가 세 가지를 처리:

| 다운로드 파일 | 처리 | repo 경로 |
|---|---|---|
| `apply_session_2026-06-21b.ps1` | 실행(러너) | - |
| (in-place) | `email-sequences.ts` 패치 | `src/lib/actions/email-sequences.ts` |
| `sequence_reports.sql` | 이동 | `docs/research/sequence_reports.sql` |
| `HANDOFF_2026-06-21b_dupfix_open_reports.md` | 이동 | `docs/research/HANDOFF_2026-06-21b_dupfix_open_reports.md` |

**실행:**
```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply_session_2026-06-21b.ps1"
```
- in-place 패치는 멱등(import 중복/블록 중복 가드). 재실행해도 안전.
- `-File` 가 조용히 안 먹을 때 대비, 패치 본문은 챗 인라인 paste 블록으로도 제공됨.

**패치가 안 먹었을 때 인라인 폴백** (`email-sequences.ts`):
- import 줄(`sequence-sender` import 아래)에 추가:
  ```ts
  import { resolveOutboundMailAccount } from '@/lib/email/mail-accounts';
  ```
- `duplicateSequence` 의 from 복사 블록(`const from = await getSequenceFromAccountId(...)` ~ 닫는 `}`)을:
  ```ts
  const from = await getSequenceFromAccountId(sequenceId);
  let copyFromAccountId: string | null = 'accountId' in from ? from.accountId : null;
  if (!copyFromAccountId) {
    const supabase = await createSupabaseServerClient();
    const def = await resolveOutboundMailAccount(supabase, orgId, {});
    copyFromAccountId = def?.id ?? null;
  }
  if (copyFromAccountId) {
    await setSequenceFromAccount(created.id, copyFromAccountId);
  }
  ```

---

## 4. Finish block

```
cd C:\dev\mbg-project
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply_session_2026-06-21b.ps1"
git status -sb
git add src/lib/actions/email-sequences.ts docs/research/sequence_reports.sql docs/research/HANDOFF_2026-06-21b_dupfix_open_reports.md
git status -sb
git commit -m "fix(sequences): pin resolved default sender on duplicate; add open-rate report SQL"
git push origin marinebiogroup
```
> push = web 자동 배포(`mbg-project`). 로컬 mover/패치만으론 배포 안 됨 — **반드시 push**.
> 워커(`lucky-patience`)는 코드 변경 시 별도 재배포/재시작 필요할 수 있음(이번 변경은 server action 이라 web 배포로 반영).

---

## 5. 남은 항목 / 검증 To-Do

1. 패치 후 `(copy)` 시퀀스를 하나 만들어 `from_account_id` 가 default(yunyoung.heo `4b07c210`)로 pin 되는지 확인 — `sequence_reports.sql` [H].
2. Day 3/7 드립 자동발송 확인 — [F] 쿼리로 step_order 1,2 행이 해당 일자에 생기는지.
3. 오픈율 추이 — [B]/[C]/[G]. 이전 블라스트 ~72% 대비.
4. 테스트 enrollment `a1f7fbc8`(step1 06-24 예약) 정리는 직전 핸드오프 §3-4 SQL 참고(선택).
