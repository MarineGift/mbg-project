# MBG 대량 메일링 시스템 — 핸드오프 (Phase 1~4 완료)

작성: 2026-06-15 세션 종료 시점
브랜치: `marinebiogroup` (PUBLIC) · 최종 커밋: `f6318f5`
배포: push = urm.marinebiogroup.com 자동 배포 / 워커는 별도 서비스(아래)

---

## 1. 한 줄 요약

템플릿을 **파이프라인 스테이지의 deal 파티들** 또는 **직접 고른 파티들**에게 보내는 대량 메일링.
- **Send now**: 동기 발송(동시성 4, 상한 100) — 소량용
- **Queue (background)**: 워커가 백그라운드로 발송 — 상한·타임아웃 없음, rate-limit, 진행률, 재개
- **dedup**: 같은 템플릿을 이미 받은 파티는 자동 제외

검증 완료: 테스트 파티 `MBG Mailing Test`(컨택 6명)로 **sent 6 / failed 0**, 머지/서명 렌더링 정상.

---

## 2. 이번 세션에 만든 것 (커밋 순)

| 커밋 | 내용 |
|------|------|
| `6a8db15` | Phase 1~3: send-outbound에 template_id 기록(dedup), `bulk-mail.ts` 쿼리/액션, `/mailing` UI, per-recipient 모델 |
| (template fixes) | email-templates `module`→`party_type` 컬럼키 수정 / send-outbound body_plain 폴백 |
| `194f08d` | 동기 발송 동시성 최적화(bounded concurrency 4, 페이싱 제거) |
| `b9615cd` | Phase 4 백엔드: `mailrun-worker.ts`, `enqueueBulkMail`/`getMailRunStatus`/`listRecentMailRuns`, Queue UI |
| `351f291` | 결합 워커 `all-workers.ts`(mailcarrier+mailrun), `worker:all` 스크립트 |
| `f6318f5` | tracking 워커 컨텍스트 수정: `createEmailTracking`이 client 주입 받음 |

---

## 3. 스키마 (적용 완료)

`app.mail_runs` — 백그라운드 발송 작업 1건
- 템플릿 스냅샷(`template_subject`/`template_body`), `mail_account_id`, 옵션(`recipient_mode`/`bypass_whitelist`/`rate_per_minute`/`concurrency`)
- `status`(queued/running/paused/completed/failed/canceled), 카운터(total/sent/failed/blocked)
- RLS: `app.current_organization_id()`

`app.mail_run_recipients` — run의 수신자 큐
- party_id/contact_id/email/status(pending/sending/sent/failed/blocked/skipped)/communication_id/error/attempts
- unique(run_id, email), index(run_id, status)
- ON DELETE CASCADE (run 삭제 시 같이 삭제)

DDL 원본: `phase4_mail_runs_schema.sql` (migrations/ 기록 권장)

---

## 4. 코드 구조

- `src/lib/queries/bulk-mail.ts` — `resolveBulkCandidates`(후보 해석, dedup, 화이트리스트 판정)
- `src/lib/actions/bulk-mail.ts` — `previewBulkMail` / `sendBulkMail`(동기) / `enqueueBulkMail`(큐) / `getMailRunStatus` / `listRecentMailRuns`
- `src/app/(app)/mailing/page.tsx` + `bulk-mail-client.tsx` — UI(Audience → Message/옵션 → Preview → Send now/Queue)
- `src/workers/mailrun-worker.ts` — 큐 드레이너. `runMailRunWorker({once})` export. `sendOutboundEmail` 재사용(화이트리스트/머지/communications insert→engagement/tracking 그대로). per-tick budget ≈ rate_per_minute, concurrency 레인.
- `src/workers/all-workers.ts` — mailcarrier + mailrun 한 프로세스(`Promise.allSettled`).

발송 코어: `src/lib/email/send-outbound.ts` (`sendOutboundEmail`) — 큐/즉시 공통.
tracking: `src/lib/actions/email-tracking.ts` — `client?: SbClient` 받음(워커는 service-role 주입, 앱은 request client).

---

## 5. 배포 / 운영 (중요)

### 워커 서비스 (Railway)
- 앱 서비스(`mbg-project`)와 워커 서비스(`lucky-patience`)가 **같은 GitHub 레포**를 공유.
- 워커 서비스 **Custom Start Command**: `npx tsx src/workers/all-workers.ts`
  - `npm run worker:all` 아님! Railway엔 `.env.local`이 없어 `--env-file=.env.local`이 죽음. 직접 tsx 호출 사용.
  - **Pre-deploy Command**는 비워둘 것(워커 같은 무한 루프를 넣으면 배포가 멈춤).
  - Start Command 칸엔 `$` 등 프롬프트 장식 넣지 말 것(`/bin/bash: $: command not found`).
- `railway.json`로 startCommand 코드 고정은 **금지** — 두 서비스가 같은 레포라 앱 서비스까지 워커로 시작돼 충돌.
- 정상 기동 로그 3줄:
  ```
  [all-workers] starting: mailcarrier + mailrun
  [mailcarrier-worker] using 9 DB mailbox(es) ...
  [mailrun-worker] starting (once=false, poll=10000ms, maxRuns/tick=3)
  ```
- 워커 env 필요: `NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`(service-role=RLS 우회) + SMTP/복호화 변수.

### 로컬
- `npm run worker:all` (로컬은 `.env.local` 있으니 OK), `npm run worker:mailrun -- --once`(한 번 드레인).

---

## 6. 테스트 베드 (라이브)

- 파티 `MBG Mailing Test`, 컨택 6명(given_name: Marine/MarinePad/MarinaPad/Naver/Gmail/MoreWorld).
- 화이트리스트 6개 테스트 주소. 발신 기본: `yunyoung.heo@marinebiogroup.com`.
- 머지 템플릿 `MBG Merge Test` (id `2c9da388-1f43-45f3-b2d4-28a227e7f999`, body_html에 토큰).

### 재테스트 절차
```sql
-- dedup 리셋
update app.communications c set template_id = null
where c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and c.template_id = '2c9da388-1f43-45f3-b2d4-28a227e7f999'
  and exists (select 1 from app.contacts ct join app.parties p on p.id = ct.party_id
              where ct.id = c.contact_id and p.party_name = 'MBG Mailing Test');
-- 이전 테스트 run 정리(선택)
delete from app.mail_runs where organization_id='b25de8f2-1020-482f-9012-183f63883169' and source_kind='parties';
```
그다음 `/mailing` → Pick parties → MBG Mailing Test → All contacts → Queue → Preview → Queue 6.
검증: `select status, count(*) from app.mail_run_recipients group by status;`

---

## 7. 알려진 운영 메모 / 트러블슈팅

- **컬럼명**: parties의 이름 컬럼은 `name`이 아니라 **`party_name`**.
- **부분 실패는 코드 문제 아님**: 수신서버 거부(예: `551 5.1.1 User not local`)는 `error` 컬럼에 기록되고 해당 recipient만 `failed`. 발송 시스템 정상 동작의 증거.
  - 실제 사례: `morewrold@marinebio.kr`(오타) → `moreworld@marinebio.kr` 교정 후 6/6 성공.
  - 실패 원인 확인: `select email, status, error from app.mail_run_recipients where status='failed';`
- **tracking**: 워커에서 `[sendOutbound] tracking setup failed` 가 보이면 → 워커가 아직 `f6318f5` 이전 코드. 재배포 필요. (이 로그는 non-blocking이라 발송은 됐었음.)
- **PowerShell 러너** `run_patches.ps1`: git stderr 경고(LF→CRLF)에 안 죽게 git 구간을 `ErrorActionPreference=Continue`로 감쌈. `core.autocrlf false` 설정됨.
- **apply 스크립트 파일명 유니크**: 같은 Downloads 파일명 재사용 시 충돌 → v3/v4/v5/v6 식 suffix 사용.

---

## 8. 다음에 할 만한 것 (미착수)

- run 취소/일시정지 UI(스키마에 `paused`/`canceled` status 이미 있음 — 액션/버튼만 추가).
- 실패 recipient 재시도(현재 attempts=1 고정, 자동 재시도 없음).
- mail_run에 발신 계정/스테이지 이름 등 메타 표시(현재 source_ref만 저장).
- 개봉/클릭 추적 결과를 run 패널에 노출.
