# Handoff — To-do 보강 Phase 1: 자연어 Quick-Add (2026-07-06)

## 이번 세션 완료 내용
`handoff_todo_enhancement.md`의 gap 분석 1순위였던 **자연어 quick-add(NLP 파서)** 구현 완료.

칸반 컬럼 헤더의 quick-add 입력이 이제 한 줄에서 날짜/우선순위/파티를 파싱한다:

| 입력 예 | 결과 |
|---|---|
| `Pangaea 팔로업 next thu p1 @pangaea` | title="Pangaea 팔로업", due=다음주 목, priority=urgent, party_id=Pangaea Ventures |
| `IR deck 검토 내일 !high` | due=내일, priority=high |
| `Batch 9c-2 이메일 7/10~7/12` | start=7/10, due=7/12 (Gantt에 바로 표시) |
| `원페이저 업데이트 다음주 목` | due=다음주 목요일 |
| `이메일 재확인 3일 후 !긴급` | due=+3일, priority=urgent |

**지원 토큰** (한/영 병행):
- 우선순위: `p1`~`p4`, `!urgent !high !med !low`, `!긴급 !높음 !보통 !낮음`
- 날짜: `today/tomorrow/tmr`, `오늘/내일/모레`, `next week/다음주`, `next thu`, `다음주 목`, `목요일/목욜`, `mon..sun`, `in 3 days`, `3일 후`, `7/10`, `7월 10일`, `2026-07-10`
- 범위: `7/10~7/12`, `2026-07-10~2026-07-12` → start_date + due_date
- 파티: `@pangaea`, `@"Pangaea Ventures"` (서버에서 exact → prefix → substring 순 매칭, RLS org 스코프)

**설계 포인트**:
- 파서는 **클라이언트에서 실행** — "내일" 등 상대 날짜가 Railway UTC가 아닌 사용자 로컬 타임존으로 계산됨. 서버 왕복은 @party 조회 1건뿐.
- due_date/start_date는 DATE-only 컬럼이므로 시각 토큰("3pm", "오후 3시")은 의도적으로 title에 남김.
- 인식 안 된 텍스트는 그대로 title 보존. 파티 조회 실패해도 태스크 생성은 진행(단순 party_id null).
- 유닛 테스트 20케이스 전부 통과(고정 now=2026-07-06 기준, 연도 롤오버 포함).

## 파일 (3개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `quick-add-parser.ts` | 신규 소스 | `src\lib\tasks\quick-add-parser.ts` |
| `patch_todo_quickadd_p1.ps1` | 패치 (idempotent) | `tools\patches\` |
| `handoff_todo_quickadd_phase1.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 유니버설 무버 (patch/handoff 라우팅)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② 파서 파일 인라인 무버 (`.ts`는 유니버설 무버 프리픽스 대상 아님 — 반드시 실행)
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads\quick-add-parser*.ts" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host 'NOT FOUND in Downloads'; return }
Unblock-File $src.FullName
$destDir = 'C:\dev\mbg-project\src\lib\tasks'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
[System.IO.File]::Copy($src.FullName, (Join-Path $destDir 'quick-add-parser.ts'), $true)
Remove-Item $src.FullName
Write-Host 'MOVED: quick-add-parser.ts -> src\lib\tasks\'
```

### ③ 패치 실행
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_todo_quickadd_p1.ps1
```

### ③-fallback: 인라인 paste-able 패치 (위 -File이 무반응이면 아래 전체를 콘솔에 붙여넣기)
```powershell
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
function NL([string]$s) { return $s.Replace("`r`n", "`n") }

$actionsPath = Join-Path $repo 'src\lib\tasks\actions.ts'
$t = [System.IO.File]::ReadAllText($actionsPath)
$t = $t.Replace("`r`n", "`n")
if ($t.Contains('resolvePartyIdByName')) {
  Write-Host 'SKIP (already patched): actions.ts'
} else {
  $append = NL @'

// ---------------------------------------------------------------------------
// Quick-add helpers (Phase 1: natural-language capture)
// ---------------------------------------------------------------------------

/**
 * Resolve an @mention captured by the quick-add parser to a party.
 * Match order: exact name (case-insensitive) -> prefix -> first substring hit.
 * RLS scopes the lookup to the caller's org. Returns null when nothing matches.
 */
export async function resolvePartyIdByName(
  q: string,
): Promise<{ id: string; name: string } | null> {
  const query = q.trim();
  if (!query) return null;
  const supabase = await createClient();
  const esc = query.replace(/[%_]/g, (c) => `\\${c}`);
  const { data, error } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('id,name')
    .ilike('name', `%${esc}%`)
    .limit(10);
  if (error) throw new Error(`resolvePartyIdByName: ${error.message}`);
  const rows = (data ?? []) as unknown as Array<{ id: string; name: string }>;
  if (!rows.length) return null;
  const lower = query.toLowerCase();
  return (
    rows.find((r) => r.name.toLowerCase() === lower) ??
    rows.find((r) => r.name.toLowerCase().startsWith(lower)) ??
    rows[0] ??
    null
  );
}
'@
  $t = $t.TrimEnd("`n") + "`n" + $append + "`n"
  [System.IO.File]::WriteAllText($actionsPath, $t, [System.Text.UTF8Encoding]::new($false))
  Write-Host 'PATCHED: actions.ts (+resolvePartyIdByName)'
}

$viewPath = Join-Path $repo 'src\components\tasks\task-board-view.tsx'
$v = [System.IO.File]::ReadAllText($viewPath)
$v = $v.Replace("`r`n", "`n")
if ($v.Contains('parseQuickAdd')) {
  Write-Host 'SKIP (already patched): task-board-view.tsx'
} else {
  $oldImp = NL @'
import {
  moveItem,
  createItem,
  updateItem,
  deleteItem,
} from '@/lib/tasks/actions';
'@
  $newImp = NL @'
import {
  moveItem,
  createItem,
  updateItem,
  deleteItem,
  resolvePartyIdByName,
} from '@/lib/tasks/actions';
import { parseQuickAdd } from '@/lib/tasks/quick-add-parser';
'@
  if (-not $v.Contains($oldImp)) { throw 'ANCHOR NOT FOUND: import block' }
  $v = $v.Replace($oldImp, $newImp)

  $oldQC = NL @'
  // Quick add from a kanban column header (title only).
  async function quickCreate(title: string, status: string) {
    try {
      const created = await createItem({
        boardId: board.id,
        title,
        status,
        position: nextPos(status),
      });
      setItems((prev) => [...prev, created]);
    } catch (e) {
      console.error('createItem failed', e);
    }
  }
'@
  $newQC = NL @'
  // Quick add from a kanban column header, with natural-language parsing.
  // "Pangaea follow-up next thu p1 @pangaea" -> due_date / priority / party_id
  // are extracted; unrecognized text stays in the title. Parsing runs on the
  // CLIENT so relative dates resolve in the user's local timezone; only the
  // @party lookup goes to the server (RLS-scoped).
  async function quickCreate(title: string, status: string) {
    try {
      const parsed = parseQuickAdd(title);
      let partyId: string | null = null;
      if (parsed.partyQuery) {
        try {
          const p = await resolvePartyIdByName(parsed.partyQuery);
          partyId = p?.id ?? null;
        } catch (e) {
          console.error('resolvePartyIdByName failed', e);
        }
      }
      const created = await createItem({
        boardId: board.id,
        title: parsed.title,
        status,
        priority: parsed.priority,
        startDate: parsed.startDate,
        dueDate: parsed.dueDate,
        partyId,
        position: nextPos(status),
      });
      setItems((prev) => [...prev, created]);
    } catch (e) {
      console.error('createItem failed', e);
    }
  }
'@
  if (-not $v.Contains($oldQC)) { throw 'ANCHOR NOT FOUND: quickCreate' }
  $v = $v.Replace($oldQC, $newQC)

  $oldPh = 'placeholder="Task title (Enter)"'
  $newPh = 'placeholder="Task (e.g. follow up thu p1 @party)"'
  if (-not $v.Contains($oldPh)) { throw 'ANCHOR NOT FOUND: placeholder' }
  $v = $v.Replace($oldPh, $newPh)

  [System.IO.File]::WriteAllText($viewPath, $v, [System.Text.UTF8Encoding]::new($false))
  Write-Host 'PATCHED: task-board-view.tsx (NL quick-add wired)'
}
Write-Host 'DONE. Next: npm run build to verify, then commit + push.'
```

## 검증
1. `cd C:\dev\mbg-project` → `npm run build` (또는 `npm run dev`) — 타입/빌드 에러 없어야 함.
2. `/todo` 보드 → 칸반 컬럼 `+` → `Pangaea 팔로업 next thu p1 @pangaea` 입력 → 카드에 due 날짜·urgent 배지 표시, 카드 상세에서 party 링크 확인.
3. `테스트 내일 !high` 입력 → due=내일, high 배지.
4. 토큰 없는 일반 제목 → 기존과 동일하게 생성(회귀 없음).

## 마무리 (푸시해야 웹에 반영됨)
```powershell
cd C:\dev\mbg-project
git status -sb
git add src\lib\tasks\quick-add-parser.ts src\lib\tasks\actions.ts src\components\tasks\task-board-view.tsx tools\patches\patch_todo_quickadd_p1.ps1 docs\handoff\2026-07-06\handoff_todo_quickadd_phase1.md
git commit -m "feat(todo): natural-language quick-add parser (Phase 1) - date/priority/@party tokens KO+EN"
git push origin marinebiogroup
```

## 남은 Phase (handoff_todo_enhancement.md 기준)
- **Phase 2**: 반복 작업(recurring) — todo_items에 rrule 컬럼 + 완료 시 다음 인스턴스 생성(마이그레이션 필요). 기존 drip worker 패턴 재활용.
- **Phase 3**: 리마인더 — 기존 이메일/Slack(#all-marinebiogroup) 알림 인프라 재활용.
- **Phase 4**: AI 태스크 분해 — generateAIEmail과 동일한 Anthropic API 패턴.
- **확장 아이디어(quick-add v2)**: `#group` 토큰으로 그룹 지정, task-form-dialog title 필드에도 파서 적용, 파싱 결과 실시간 미리보기 칩.

## 미해결 확인 항목 (이월)
- todo_* 테이블 실제 DB 스키마 vs types.ts 대조 (FK probe) — 이번 패치는 기존 createItem 경로만 사용하므로 무관하나, Phase 2 마이그레이션 전 필수.
- Calendar 뷰 드래그 리스케줄 지원 여부.
- `migration_campaign_rename_trigger.sql`(캠페인 리네임 토큰 치환 트리거) — 별건, 미적용이면 Supabase SQL Editor에서 실행.
