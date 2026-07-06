# Handoff — To-do Phase 3: 태스크 리마인더 (2026-07-06)

## 이번 세션 완료 내용
Phase 3 **태스크 리마인더** 구현 + 실 Postgres 16 / 워커 런타임 검증 완료.

당일 마감 + 연체 태스크를 스캔해 **Slack 다이제스트(org당 1건) + 이메일(담당자당 1건)** 발송. 발송 후 `reminded_at` 마킹으로 하루 1회만 발화(cron이 매시간 돌아도 중복 없음). 발송 채널·시점·빈도는 요청대로: Slack+이메일 병행 / 당일+연체 / cron 빈도 유연.

## 아키텍처 (기존 인프라 재활용)
- **DB**: `app.get_due_task_reminders(p_today)` RPC가 대상 태스크를 담당자 이메일·이름까지 resolve해서 반환. `app.mark_task_reminders_sent(ids, today)`로 발송 완료 마킹.
- **Slack**: 기존 `notifySlack(orgId, text)` (org webhook, never-throws).
- **이메일**: 기존 `sendOutboundEmail` (org 기본 계정으로 발송, whitelist skip — 내부 팀원 대상).
- **cron**: `/api/tasks/reminders`, 기존 `/api/sequences/process`와 동일한 `CRON_SECRET` 가드 패턴.

## 스키마 변경
- `app.todo_items.reminded_at date` 추가 — 하루 1회 dedupe 마커.
- 인덱스 `ix_todo_items_due_reminder (organization_id, due_date) where archived_at is null`.
- RPC 2개(`get_due_task_reminders`, `mark_task_reminders_sent`), `security definer`, `service_role`에 execute grant.

**대상 조건** (RPC): archived 아님 + done 아님(보드별 `is_done` anti-join) + `due_date <= today` + (`reminded_at` null 또는 < today).

## 검증 결과
**DB (실 Postgres 16)**: 8종 시드로 RPC 스코프 검증 — 당일마감/연체/미배정만 반환, future·done·archived·no-due·이미발송은 정확히 제외. `is_overdue` 플래그 정확. 담당자 이메일/이름 resolve 정확(미배정은 null). mark-sent 후 재조회 시 해당 태스크 제외. 마이그레이션 재실행 idempotent.

**워커 (Node 런타임, capturing stub)**: scanned=4/orgs=2 그룹핑 정확. Slack 다이제스트가 org당 1건, Overdue/Due-today 섹션 분리 + `[URGENT]`/`[High]` 태그. 이메일은 담당자당 1건(Alice 2태스크 묶음 → "2 tasks", Bob 1태스크 → 단건 제목). 미배정 태스크는 이메일 없이 Slack 커버리지로 마킹. marked=4(전부).

## 파일 (4개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `migration_todo_reminders_phase3.sql` | 마이그레이션 | `sql\` |
| `reminder-worker.ts` | 신규 소스 | `src\lib\tasks\reminder-worker.ts` |
| `reminders-route.ts` | 신규 소스(cron) | `src\app\api\tasks\reminders\route.ts` |
| `handoff_todo_reminders_phase3.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 유니버설 무버 (migration_*.sql → sql\, handoff → docs\handoff\)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② 소스 파일 2개 인라인 무버 (`.ts`는 유니버설 무버 대상 아님)
```powershell
# reminder-worker.ts -> src\lib\tasks\
$src = Get-ChildItem "$env:USERPROFILE\Downloads\reminder-worker*.ts" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File $src.FullName
  $d = 'C:\dev\mbg-project\src\lib\tasks'
  [System.IO.Directory]::CreateDirectory($d) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $d 'reminder-worker.ts'), $true)
  Remove-Item $src.FullName
  Write-Host 'MOVED: reminder-worker.ts -> src\lib\tasks\'
} else { Write-Host 'reminder-worker.ts NOT FOUND' }

# reminders-route.ts -> src\app\api\tasks\reminders\route.ts
$src = Get-ChildItem "$env:USERPROFILE\Downloads\reminders-route*.ts" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File $src.FullName
  $d = 'C:\dev\mbg-project\src\app\api\tasks\reminders'
  [System.IO.Directory]::CreateDirectory($d) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $d 'route.ts'), $true)
  Remove-Item $src.FullName
  Write-Host 'MOVED: reminders-route.ts -> src\app\api\tasks\reminders\route.ts'
} else { Write-Host 'reminders-route.ts NOT FOUND' }
```

### ③ Supabase SQL Editor에서 마이그레이션 실행
`migration_todo_reminders_phase3.sql` 전체 실행. 하단 VERIFY:
- (a) `reminded_at` 컬럼 present
- (b) `get_due_task_reminders`, `mark_task_reminders_sent` 함수 present

### ④ 빌드
```powershell
cd C:\dev\mbg-project
npm run build
```

## cron 등록 (실제 발송 시작하려면 필요)
`CRON_SECRET` 환경변수가 이미 있어야 함(sequences/process가 쓰던 것과 동일). Vercel `vercel.json` 예:
```json
{ "crons": [{ "path": "/api/tasks/reminders", "schedule": "0 8 * * *" }] }
```
- 아침 1회: `0 8 * * *` (08:00). 매시간: `0 * * * *`. dedupe가 있어 매시간도 안전.
- Railway 등 외부 cron이면: `curl -X POST https://urm.marinebiogroup.com/api/tasks/reminders -H "x-cron-secret: <CRON_SECRET>"`

## 수동 테스트 (cron 없이 즉시)
```powershell
# 로컬 dev 서버 기준 (CRON_SECRET을 .env.local 값으로)
curl -X POST http://localhost:3000/api/tasks/reminders -H "x-cron-secret: <CRON_SECRET>"
# -> {"scanned":N,"orgs":..,"slackSent":..,"emailsSent":..,"marked":..}
```
대상 태스크가 없으면 `scanned:0`. 당일 마감 태스크 하나 만들어(due=오늘) 실행하면 Slack #all-marinebiogroup + 담당자 이메일로 리마인더가 온다.

## 마무리 (푸시해야 웹에 반영됨)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql\migration_todo_reminders_phase3.sql src\lib\tasks\reminder-worker.ts src\app\api\tasks\reminders\route.ts docs\handoff\2026-07-06\handoff_todo_reminders_phase3.md
git commit -m "feat(todo): task reminders (Phase 3) - due/overdue Slack digest + per-assignee email, CRON_SECRET route"
git push origin marinebiogroup
```

## 남은 Phase
- Phase 4: AI 태스크 분해 (generateAIEmail과 동일한 Anthropic API 패턴, "딜 클로징 준비" → 체크리스트 자동 생성)

## 미해결 (이월)
- Calendar 뷰 드래그 리스케줄 지원 여부.
- `migration_campaign_rename_trigger.sql` (별건, 미적용 시 실행).
- 리마인더 시점 확장 여지: 현재 "당일+연체". "마감 1일 전"을 원하면 RPC의 due 조건을 `due_date <= today + 1`로 넓히고 다이제스트에 "내일 마감" 섹션 추가하면 됨.
