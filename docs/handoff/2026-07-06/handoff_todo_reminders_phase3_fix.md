# Handoff — Phase 3 FIX: 리마인더 RPC users 조인 버그 (2026-07-06)

## 무엇이 문제였나
Phase 3 마이그레이션을 SQL Editor에서 실행하니:
```
ERROR: 42703: column u.given_name does not exist
LINE 69: nullif(trim(concat_ws(' ', u.given_name, u.family_name)), ''),
```

**원인**: `get_due_task_reminders`가 `app.users`를 조인해 `given_name`/`family_name`으로 담당자 이름을 만들려 했는데, 실제 `app.users`엔 그 컬럼이 없다. 이름은 이메일 인사말용 nicety였을 뿐이다. (로컬 테스트에서 내가 stub에 그 컬럼을 넣어서 안 드러났음 — org fix 때와 같은 패턴.)

## 수정 내용
`app.users` 조인을 **완전히 제거**하고, 담당자 이름을 이메일 로컬파트(`@` 앞)에서 파생한다. users 테이블 형태에 의존하지 않으므로 스키마 드리프트에 안전. 이메일은 여전히 `auth.users`에서 가져온다.

reader 함수만 교체. `reminded_at` 컬럼·인덱스·mark-sent 헬퍼·grant는 그대로. 워커는 `assignee_name`을 이메일 인사말에만 쓰므로 **워커 변경 불필요**.

## 검증 (실 Postgres 16)
- **버그 재현**: `app.users`를 `id`만 있는 테이블로 만든 뒤 원본 RPC 실행 → 동일한 `42703 column u.given_name does not exist` 재현.
- **수정 적용 후**: 같은 조건에서 RPC 정상 실행. 8종 시드 회귀 통과 — 스코프 동일(당일마감/연체/미배정), `assignee_name`이 이메일 로컬파트(`yy@marinebiogroup.com` → `yy`)로 파생, 미배정은 null. mark-sent 정상.

## 파일 (2개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `fix_todo_reminders_users_join.sql` | 수정 마이그레이션 | `sql\` |
| `handoff_todo_reminders_phase3_fix.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 무버
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② SQL Editor에서 실행
`fix_todo_reminders_users_join.sql` 전체 실행. VERIFY가 `due_today_or_overdue` 카운트(숫자)를 반환하면 성공(42703 안 남).

## !! 소스 파일 2개 아직 리포에 없음 (중요)
이전 세션 콘솔에서 `reminder-worker.ts` / `reminders-route.ts`가 "NOT FOUND"였다 → 다운로드가 Downloads에 안 들어감. 이 두 `.ts`는 DB와 무관하지만 cron 엔드포인트·워커라 **리포에 있어야 빌드·배포됨**. 재다운로드 후 인라인 무버(원 Phase 3 핸드오프 ② 참고)로 넣어야 한다.

필요 소스 위치:
- `src\lib\tasks\reminder-worker.ts`
- `src\app\api\tasks\reminders\route.ts`

## 마무리 (전체 Phase 3 커밋)
소스 2개 이동 + fix SQL 실행 후:
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql\migration_todo_reminders_phase3.sql sql\fix_todo_reminders_users_join.sql src\lib\tasks\reminder-worker.ts src\app\api\tasks\reminders\route.ts docs\handoff\2026-07-06\handoff_todo_reminders_phase3.md docs\handoff\2026-07-06\handoff_todo_reminders_phase3_fix.md
git commit -m "feat(todo): task reminders (Phase 3) + fix RPC to drop app.users name join"
git push origin marinebiogroup
```

## 검증 (전체 동작)
```powershell
npm run build
# 당일 마감 태스크 하나 만든 뒤:
curl -X POST http://localhost:3000/api/tasks/reminders -H "x-cron-secret: <CRON_SECRET>"
# -> {"scanned":N,...}; Slack #all-marinebiogroup + 담당자 이메일로 리마인더 도착
```
