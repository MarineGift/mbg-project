# Handoff — To-do 보강 Phase 2: 반복 작업 (2026-07-06)

## 이번 세션 완료 내용
Phase 2 **반복 작업(recurring tasks)** DB 마이그레이션 구현 + 실 Postgres 16 검증 완료.

선택된 설계: **DB 트리거(완료 즉시, 서버리스) + 전용 컬럼(recurrence text)**.

반복 태스크를 done 상태로 옮기면 AFTER-UPDATE 트리거가 다음 인스턴스를 자동 생성한다 (제목·보드·그룹·우선순위·파티·담당자 승계, 날짜는 규칙대로 롤포워드).

## 스키마 변경 (실측 probe 기반)
probe로 확인한 실제 `app.todo_items` 컬럼(21개, `custom jsonb`, `status default 'todo'`, `position double precision`, `created_by default auth.uid()`)에 정확히 맞춰 설계. 기존 BEFORE UPDATE 트리거 `trg_task_items_updated`(→`app.set_updated_at()`)와 **충돌 없음**(신규는 AFTER UPDATE).

추가 컬럼 3개 (`app.todo_items`):
- `recurrence text` — RRULE 서브셋. `FREQ=DAILY|WEEKLY|MONTHLY|YEARLY` + 선택적 `INTERVAL=n`. null이면 단발.
- `recurrence_ends date` — 이 날짜 초과하면 생성 중단. null이면 무기한.
- `recurrence_parent_id uuid` — 체인 루트(첫 태스크) 참조. self-FK `on delete set null`.

추가 함수 2개:
- `app.todo_advance_date(date, rule)` — immutable, 날짜를 규칙대로 1스텝 전진. 리포트 재사용 가능.
- `app.todo_spawn_next_occurrence()` — 트리거 함수.

## 동작 규칙 (검증 완료)
- **완료 판정**: status가 해당 보드의 `todo_status_options.is_done=true` 상태로 바뀔 때. done 상태 목록을 트리거가 런타임에 board_id+key로 조인 조회하므로 값을 하드코딩 안 함.
- **not-done → done 전이에서만** 발화. done→done 재저장, done 내 드래그는 재생성 안 함.
- **루프 방지**: 새 인스턴스는 보드의 첫 not-done 상태(position 최소)로 삽입 → 트리거 재발화 불가.
- **Gantt 유지**: start_date 있으면 start→due 오프셋 보존.
- **앵커 필요**: due_date 없는 반복 태스크는 그냥 완료(생성 안 함).
- **SaaS**: organization_id/created_by는 컬럼 디폴트로 채워짐(un-spoofable).

## 실 Postgres 16 검증 결과 (6/6 통과)
1. 주간 반복 완료 → due 07-06 → 07-13, start 오프셋 보존, priority 승계 ✓
2. done 재저장/done→done → 중복 생성 없음(총 2행 유지) ✓
3. recurrence_ends(07-10) 초과 시(다음 due 07-13) 생성 안 함 ✓
4. 비반복 태스크 완료 → 생성 없음 ✓
5. due_date 없는 반복 → 완료만, 생성 없음 ✓
6. 체인 무결성: 생성된 태스크 완료 시 3번째 생성, 모두 같은 루트 parent_id 공유 ✓
- 날짜 헬퍼: 주간/월간/연간 정확, Jan-31 월간은 Feb-28로 클램프(잘못된 날짜 방지) ✓
- 마이그레이션 재실행 idempotent(“already exists, skipping”만, 에러 없음, 데이터 보존) ✓

## 파일 (2개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `migration_todo_recurring_phase2.sql` | 마이그레이션 | `sql\` |
| `handoff_todo_recurring_phase2.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 유니버설 무버 (sql/handoff 자동 라우팅)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ①-fallback: 마이그레이션 인라인 무버
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads\migration_todo_recurring_phase2*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host 'NOT FOUND in Downloads'; return }
Unblock-File $src.FullName
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
[System.IO.File]::Copy($src.FullName, (Join-Path $destDir 'migration_todo_recurring_phase2.sql'), $true)
Remove-Item $src.FullName
Write-Host 'MOVED: migration_todo_recurring_phase2.sql -> sql\'
```

### ② Supabase SQL Editor에서 실행
`migration_todo_recurring_phase2.sql` 전체를 붙여넣고 실행. 하단 VERIFY 3종이 함께 출력됨:
- (a) 컬럼 3개 present
- (b) 트리거 present + enabled(O)
- (c) 날짜 헬퍼: `2026-07-13 / 2026-08-06 / 2026-02-28`

## 검증 (라이브 DB)
`/todo` 보드에서 임의 태스크에 recurrence를 넣고(현재는 SQL로 직접, UI 노출은 아래 Phase 2b) done으로 옮겨 다음 인스턴스 자동 생성 확인:
```sql
-- 예: 기존 태스크 하나를 주간 반복으로 지정
update app.todo_items
   set recurrence = 'FREQ=WEEKLY;INTERVAL=1'
 where id = '<some_task_id>';
-- 그 태스크를 UI에서 done으로 드래그 -> 다음 주 due의 새 카드가 첫 컬럼에 생성됨
```

## 마무리 (푸시해야 웹에 반영됨 — 단, 이건 DB 마이그레이션이라 push는 파일 이력용. 실제 반영은 Supabase 실행)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql\migration_todo_recurring_phase2.sql docs\handoff\2026-07-06\handoff_todo_recurring_phase2.md
git commit -m "feat(todo): recurring tasks via AFTER-UPDATE trigger + recurrence columns (Phase 2)"
git push origin marinebiogroup
```

## 다음 단계 (Phase 2b — UI 노출)
마이그레이션만으로는 recurrence를 SQL로만 설정 가능. UI에서 반복을 지정하려면:
- `CreateItemInput`/`UpdateItemPatch`(actions.ts)에 `recurrence` / `recurrenceEnds` 필드 추가.
- `task-form-dialog.tsx`에 반복 드롭다운(없음/매일/매주/매월/매년 + 종료일) 추가.
- quick-add 파서(Phase 1)에 `!weekly` / `매주` 등 반복 토큰 추가 검토.
- 카드/상세에 반복 아이콘 표시.

## 남은 Phase (handoff_todo_enhancement.md 기준)
- Phase 3: 리마인더 — 기존 이메일/Slack(#all-marinebiogroup) 알림 인프라 재활용.
- Phase 4: AI 태스크 분해 — generateAIEmail과 동일한 Anthropic API 패턴.

## 미해결 확인 항목 (이월)
- Calendar 뷰 드래그 리스케줄 지원 여부.
- `migration_campaign_rename_trigger.sql`(캠페인 리네임 토큰 치환 트리거) — 별건, 미적용이면 Supabase SQL Editor에서 실행.
