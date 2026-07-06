# Handoff — To-do Phase 2b: 반복 지정 UI (2026-07-06)

## 이번 세션 완료 내용
Phase 2 반복 트리거가 라이브 검증됐으므로(`Investor 정보 추가` → 07-13 인스턴스 생성 확인), 이제 **SQL 없이 UI에서 반복을 지정**할 수 있게 보강.

## 중요한 발견 (엔진 구분)
리포에 task 시스템이 **둘** 있다. 혼동 주의:
- `app.tasks` (Deal→Checklist→Task) — `src/components/tasks/task-form-dialog.tsx`, `@/lib/actions/tasks`, priority=`low/medium/high/urgent`. **반복과 무관.**
- `app.todo_items` (To-do 엔진) — `src/components/tasks/task-board-view.tsx`의 인라인 `TaskModal`, `@/lib/tasks/actions.ts`, priority=`low/med/high/urgent`. **반복 트리거가 여기 걸려있음.**

Phase 2b는 후자(`todo_items`)만 건드린다.

## 변경 내용
**A) `src/lib/tasks/types.ts`** — `TaskItem`에 `recurrence` / `recurrence_ends` / `recurrence_parent_id` 필드 추가.

**B) `src/lib/tasks/actions.ts`** — `CreateItemInput`/`UpdateItemPatch`에 `recurrence`/`recurrenceEnds` 추가 + createItem/updateItem 쓰기 매핑.

**C) `src/components/tasks/task-board-view.tsx`**
- `TaskFormValues`에 recurrence 필드 + `RECUR_OPTIONS`(없음/매일/매주/격주/매월/매년) 매핑 테이블.
- createTask/updateTask가 recurrence 전달.
- quickCreate가 파서 v2의 `parsed.recurrence` 전달.
- `TaskModal`에 **Repeat 드롭다운 + Repeat until 종료일** 필드. 반복 있고 due 없으면 경고 표시.
- 칸반 카드에 반복 글리프(↻, `&#8635;`) 표시.

**D) `src/lib/tasks/quick-add-parser.ts`** — v2로 교체. 반복 토큰 추가:
- EN: `!daily !weekly !monthly !yearly`, `every day|week|month|year`, `every N days|weeks|months|years`
- KO: `매일 매주 매월(매달) 매년`, `N일마다 N주마다 N개월마다 N년마다`
- 예: `주간 팔로업 매주 @pangaea` → recurrence=FREQ=WEEKLY, party=pangaea. `sprint review every 2 weeks` → FREQ=WEEKLY;INTERVAL=2.

## 검증 (전부 통과)
- 패치 8개 hunk(C1~C8) 전부 현재 리포 파일에서 유일 매칭 확인, 패치 시뮬레이션 후 types/actions/board-view 3파일 esbuild 컴파일 통과.
- 파서 v2: 신규 반복 12케이스 통과 + **기존 Phase 1 20케이스 회귀 통과**(날짜/우선순위/파티 무손상).
- `매월 1일`처럼 매월+특정일은 recurrence만 잡고 `1일`은 title에 남김(FREQ+INTERVAL 서브셋 설계상 BYMONTHDAY 미지원, 의도된 동작).

## 파일 (3개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `quick-add-parser.ts` | 소스 교체(v2) | `src\lib\tasks\quick-add-parser.ts` |
| `patch_todo_recurring_ui_p2b.ps1` | 패치(idempotent) | `tools\patches\` |
| `handoff_todo_recurring_phase2b.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 유니버설 무버
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② 파서 v2 인라인 무버 (`.ts`는 유니버설 무버 대상 아님 — 기존 파일 덮어씀)
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads\quick-add-parser*.ts" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host 'NOT FOUND in Downloads'; return }
Unblock-File $src.FullName
$destDir = 'C:\dev\mbg-project\src\lib\tasks'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
[System.IO.File]::Copy($src.FullName, (Join-Path $destDir 'quick-add-parser.ts'), $true)
Remove-Item $src.FullName
Write-Host 'MOVED: quick-add-parser.ts (v2) -> src\lib\tasks\'
```

### ③ 패치 실행
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_todo_recurring_ui_p2b.ps1
```
(인라인 fallback은 길어서 생략 — `-File` 실행이 각 hunk를 guard로 검증하며 idempotent. 무반응이면 알려주면 paste-able 버전 제공.)

## 검증 (빌드 + 동작)
1. `cd C:\dev\mbg-project` → `npm run build` — 에러 없어야 함.
2. `/todo` 보드 → 카드 클릭 → Edit 모달에 **Repeat 드롭다운** + Repeat until 보임. Weekly 선택 + due 지정 → Save.
3. 그 카드를 done 컬럼으로 드래그 → 다음 주 due의 새 카드가 첫 컬럼에 생성(반복 글리프 ↻ 표시).
4. quick-add: 컬럼 `+` → `주간 리뷰 매주 금` → 카드에 ↻ + due=금요일.

## 마무리 (푸시해야 웹에 반영됨)
```powershell
cd C:\dev\mbg-project
git status -sb
git add src\lib\tasks\quick-add-parser.ts src\lib\tasks\types.ts src\lib\tasks\actions.ts src\components\tasks\task-board-view.tsx tools\patches\patch_todo_recurring_ui_p2b.ps1 docs\handoff\2026-07-06\handoff_todo_recurring_phase2b.md
git commit -m "feat(todo): recurrence UI + parser tokens (Phase 2b) - Repeat dropdown, card glyph, KO/EN recur tokens"
git push origin marinebiogroup
```

## !! 선행 미완료 항목 (중요)
아래 두 DB 마이그레이션이 **아직 리포에 커밋 안 됐고, DB 적용 상태 확인 필요**:
1. `migration_todo_recurring_phase2.sql` — 리포엔 커밋됨(`1963fa9`), DB 적용 확인됨(날짜 헬퍼 VERIFY 통과).
2. `fix_todo_recurring_org_inherit.sql` — **DB엔 적용된 듯하나(라이브 스폰 성공), 파일이 리포에 커밋 안 됨**(콘솔에서 "0 files moved / did not match" → 다운로드 실패 추정). Phase 2b present_files와 함께 재다운로드 후 `move-downloads.ps1`로 `sql\`에 넣고 커밋 필요.

Phase 2b UI는 DB에 recurrence 컬럼+트리거+org fix가 다 있어야 정상 동작한다. 라이브 검증 결과상 DB엔 전부 있으므로 UI는 바로 쓸 수 있다. 파일 이력만 맞추면 됨.

## 남은 Phase
- Phase 3: 리마인더 (이메일/Slack 인프라 재활용)
- Phase 4: AI 태스크 분해 (generateAIEmail 패턴)

## 미해결 (이월)
- Calendar 뷰 드래그 리스케줄 지원 여부.
- `migration_campaign_rename_trigger.sql` (별건, 미적용 시 실행).
