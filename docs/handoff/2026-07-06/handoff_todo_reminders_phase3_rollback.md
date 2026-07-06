# Handoff — Phase 3 롤백 (중복 리마인더 제거) (2026-07-06)

## 왜 롤백하나
Phase 3(태스크 리마인더)는 **내가 만들기 전에 이미 리포에 존재**했다. 완성된 시스템:
- `src/lib/reminders/process.ts` + `src/workers/reminder-worker.ts` ("todo_v2 Phase 1 - reminder delivery")
- **이미 `all-workers.ts`에 배선 → `npm run worker:all`로 프로덕션에서 실행 중**
- 대상: `todo_items` + 딜 태스크 + 딜 next-step 마일스톤 (내 것보다 넓음)
- 담당자별 1일 1회 다이제스트, `app.reminder_log`로 idempotent
- 설정: `REMINDER_SEND_HOUR`(기본 8), `REMINDER_TZ`(Asia/Seoul), `REMINDER_FROM_*` 등

내가 Phase 3를 만들 때 이 기존 구현을 확인 못 하고 중복 구현했다. 따라서 내가 추가한 것을 제거하고 기존 것을 쓴다.

**주의 — 이름 충돌**: 내 것은 `src/lib/tasks/reminder-worker.ts`, 기존 것은 `src/workers/reminder-worker.ts`. **기존(`src/workers/`)은 절대 삭제 금지.**

## 제거 대상 (내가 추가한 중복만)
**파일 2개:**
- `src/lib/tasks/reminder-worker.ts` (내 워커 — 기존 `src/workers/`와 다름)
- `src/app/api/tasks/reminders/route.ts` (+ 빈 폴더)

**DB 객체 4개:**
- 함수 `app.get_due_task_reminders(date)`
- 함수 `app.mark_task_reminders_sent(uuid[], date)`
- 인덱스 `app.ix_todo_items_due_reminder`
- 컬럼 `app.todo_items.reminded_at`

## 검증 (실 Postgres 16)
- 기존 시스템(process.ts / src/workers/reminder-worker.ts)이 내 RPC/컬럼/인덱스를 참조하는지 grep → **0** (완전 무관, 안전).
- 롤백 SQL 실행: phase3 함수 0, reminded_at 0, 인덱스 0. **Phase 2 recurrence 컬럼은 생존(1)** — over-drop 없음.
- 재실행 idempotent(IF EXISTS), 에러 없음.

## 파일 (2개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `rollback_todo_reminders_phase3.sql` | 롤백 SQL | `sql\` |
| `handoff_todo_reminders_phase3_rollback.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 무버
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② Supabase SQL Editor에서 롤백 실행
`rollback_todo_reminders_phase3.sql` 전체 실행. VERIFY:
- phase3_functions_left = 0
- reminded_at_left = 0
- recurrence_still_present = 1 (Phase 2 생존 확인)

### ③ 중복 파일 git 제거 (커밋돼 있으므로 git rm)
```powershell
cd C:\dev\mbg-project
git rm src\lib\tasks\reminder-worker.ts
git rm src\app\api\tasks\reminders\route.ts
# 빈 폴더 정리 (git은 빈 폴더를 추적 안 하므로 파일만 지우면 됨; 폴더가 남으면 수동 삭제)
if (Test-Path 'src\app\api\tasks\reminders') {
  Remove-Item 'src\app\api\tasks\reminders' -Recurse -Force -ErrorAction SilentlyContinue
}
```

### ④ 빌드 (라우트 목록에서 /api/tasks/reminders 사라졌는지 확인)
```powershell
npm run build
```

## 마무리
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql\rollback_todo_reminders_phase3.sql docs\handoff\2026-07-06\handoff_todo_reminders_phase3_rollback.md
git commit -m "revert(todo): remove duplicate Phase 3 reminders; existing src/workers reminder system already covers this"
git push origin marinebiogroup
```

## 기존 리마인더 시스템 활성화 확인 (진짜 할 일)
cron 등록이 아니라, **기존 워커가 Railway에서 실제 실행 중인지 + REMINDER env가 설정됐는지**만 확인하면 된다.

**(a) 워커 서비스 실행 여부**: Railway에 `npm run worker:all` (또는 `worker:reminder`)로 도는 서비스가 있는지. `all-workers.ts`가 mailcarrier+mailrun+sequence+reminder를 한 프로세스로 돌린다. 이미 메일 워커가 돌고 있다면 리마인더도 같이 돌고 있을 가능성 높음.

**(b) REMINDER env (process.ts 기준, 미설정 시 기본값 사용)**:
- `REMINDER_SEND_HOUR` (기본 8) — 로컬 아침 8시 이후 발송
- `REMINDER_TZ` (기본 Asia/Seoul)
- `REMINDER_FROM_ADDRESS` (기본 yunyoung.heo@marinebiogroup.com)
- `REMINDER_FROM_NAME` (기본 MBG URM)
- `REMINDER_FROM_ACCOUNT_ID` (선택, 미설정 시 org 기본 계정)
- `REMINDER_APP_URL` (기본 https://urm.marinebiogroup.com)

**(c) 즉시 테스트 (로컬)**:
```powershell
npx tsx --env-file=.env.local src/workers/reminder-worker.ts --force
# --force = send hour 게이트 무시하고 지금 발송. 결과 JSON(sent/skipped/failed) 출력.
```
스크린샷의 미완료 태스크(오늘/연체)가 담당자 이메일로 다이제스트 발송되면 정상.

## 남은 것 (오늘 To-do 세션 최종)
Phase 1(quick-add), Phase 2(반복)+2b(UI), Phase 4(AI 분해), enum→table 전환은 전부 정상 완료·검증됨. Phase 3만 기존 시스템으로 대체(이 롤백).

## 미해결 (이월)
- 기존 리마인더 워커 Railway 실행/env 확인 (위 (a)(b)(c)).
- Calendar 뷰 드래그 리스케줄.
- `migration_campaign_rename_trigger.sql` (별건).
- 수요일 Pangaea 미팅(7/8 9:30 PT) 준비.
