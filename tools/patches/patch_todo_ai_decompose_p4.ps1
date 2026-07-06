# ============================================================
# patch_todo_ai_decompose_p4.ps1  (2026-07-06)
# To-do Phase 4: AI task decomposition UI + wiring.
#  A) src/types/ai.ts                -> AgentRole gains 'task_decomposer'
#  B) src/lib/tasks/actions.ts       -> createItem accepts parentItemId
#  C) src/components/tasks/task-board-view.tsx
#       - import decomposeTask
#       - TaskModal (edit mode) gets an "AI decompose" button that calls it,
#         then closes + refreshes so the new subtasks appear
# Prereq: decompose-actions.ts delivered alongside; migration
#         migration_todo_ai_decompose_phase4.sql applied in Supabase.
# Idempotent: guarded per hunk. ASCII-only output.
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
function NL([string]$s) { return $s.Replace("`r`n", "`n") }
function W([string]$p, [string]$t) {
  [System.IO.File]::WriteAllText($p, $t, [System.Text.UTF8Encoding]::new($false))
}

# ---------- A) ai.ts : AgentRole ----------
$aiPath = Join-Path $repo 'src\types\ai.ts'
$ai = [System.IO.File]::ReadAllText($aiPath).Replace("`r`n", "`n")
if ($ai.Contains('task_decomposer')) {
  Write-Host 'SKIP (already patched): ai.ts'
} else {
  $oldA = "  | 'content_extractor'; // scraping-result normalizer (Haiku)"
  $newA = "  | 'content_extractor' // scraping-result normalizer (Haiku)`n  | 'task_decomposer'; // goal -> subtasks (Haiku, JSON)"
  if (-not $ai.Contains($oldA)) { throw 'ANCHOR NOT FOUND: ai.ts AgentRole' }
  $ai = $ai.Replace($oldA, $newA)
  W $aiPath $ai
  Write-Host 'PATCHED: ai.ts (+task_decomposer role)'
}

# ---------- B) actions.ts : createItem parentItemId ----------
$acPath = Join-Path $repo 'src\lib\tasks\actions.ts'
$ac = [System.IO.File]::ReadAllText($acPath).Replace("`r`n", "`n")
if ($ac.Contains('parentItemId')) {
  Write-Host 'SKIP (already patched): actions.ts parentItemId'
} else {
  # B1) input field
  $oldB1 = NL @'
  boardId: string;
  title: string;
  status: string;                 // a status_options.key for this board
  description?: string | null;
  groupId?: string | null;
'@
  $newB1 = NL @'
  boardId: string;
  title: string;
  status: string;                 // a status_options.key for this board
  description?: string | null;
  groupId?: string | null;
  parentItemId?: string | null;   // for AI-decomposed subtasks
'@
  if (-not $ac.Contains($oldB1)) { throw 'ANCHOR NOT FOUND: CreateItemInput parent' }
  $ac = $ac.Replace($oldB1, $newB1)

  # B2) row mapping
  $oldB2 = NL @'
    board_id: input.boardId,
    group_id: input.groupId ?? null,
    title: input.title,
'@
  $newB2 = NL @'
    board_id: input.boardId,
    group_id: input.groupId ?? null,
    parent_item_id: input.parentItemId ?? null,
    title: input.title,
'@
  if (-not $ac.Contains($oldB2)) { throw 'ANCHOR NOT FOUND: createItem row parent' }
  $ac = $ac.Replace($oldB2, $newB2)

  W $acPath $ac
  Write-Host 'PATCHED: actions.ts (+parentItemId)'
}

# ---------- C) task-board-view.tsx : AI decompose button ----------
$vPath = Join-Path $repo 'src\components\tasks\task-board-view.tsx'
$v = [System.IO.File]::ReadAllText($vPath).Replace("`r`n", "`n")
if ($v.Contains('decomposeTask')) {
  Write-Host 'SKIP (already patched): task-board-view.tsx decompose'
} else {

  # C1) import (add after the tasks/actions import block)
  $oldC1 = "import { parseQuickAdd } from '@/lib/tasks/quick-add-parser';"
  $newC1 = "import { parseQuickAdd } from '@/lib/tasks/quick-add-parser';`nimport { decomposeTask } from '@/lib/tasks/decompose-actions';"
  if (-not $v.Contains($oldC1)) { throw 'ANCHOR NOT FOUND: parser import' }
  $v = $v.Replace($oldC1, $newC1)

  # C2) TaskModal: decompose state (add next to busy state)
  $oldC2 = NL @'
  const recurRule = RECUR_OPTIONS.find((o) => o.key === recurKey)?.rule ?? null;
'@
  $newC2 = NL @'
  const recurRule = RECUR_OPTIONS.find((o) => o.key === recurKey)?.rule ?? null;
  const [decomposing, setDecomposing] = useState(false);
  const [decomposeMsg, setDecomposeMsg] = useState<string | null>(null);

  async function aiDecompose() {
    if (!item) return;
    setDecomposeMsg(null);
    setDecomposing(true);
    try {
      const res = await decomposeTask(item.id);
      if (res.ok) {
        onClose();      // close so the refreshed board shows the new subtasks
      } else {
        setDecomposeMsg(res.errorMessage ?? 'Decompose failed');
      }
    } catch (e) {
      setDecomposeMsg(e instanceof Error ? e.message : 'Decompose failed');
    } finally {
      setDecomposing(false);
    }
  }
'@
  if (-not $v.Contains($oldC2)) { throw 'ANCHOR NOT FOUND: recurRule (modal state)' }
  $v = $v.Replace($oldC2, $newC2)

  # C3) the button, in the edit-mode footer next to Delete
  $oldC3 = NL @'
          {mode === 'edit' && (
            <button type="button" onClick={remove} disabled={busy}
              className="rounded-lg border border-red-200 px-3 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50">
              Delete
            </button>
          )}
'@
  $newC3 = NL @'
          {mode === 'edit' && (
            <button type="button" onClick={remove} disabled={busy}
              className="rounded-lg border border-red-200 px-3 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50">
              Delete
            </button>
          )}
          {mode === 'edit' && (
            <button type="button" onClick={aiDecompose} disabled={busy || decomposing}
              title="Break this task into subtasks with AI"
              className="rounded-lg border border-violet-200 px-3 py-2 text-sm font-semibold text-violet-600 hover:bg-violet-50 disabled:opacity-50">
              {decomposing ? 'AI...' : 'AI decompose'}
            </button>
          )}
'@
  if (-not $v.Contains($oldC3)) { throw 'ANCHOR NOT FOUND: Delete button' }
  $v = $v.Replace($oldC3, $newC3)

  # C4) surface any decompose error message (above the footer row)
  $oldC4 = NL @'
        <div className="mt-2 flex items-center gap-2">
          {mode === 'edit' && (
            <button type="button" onClick={remove} disabled={busy}
'@
  $newC4 = NL @'
        {decomposeMsg && (
          <p className="mb-2 text-[11px] text-red-500">{decomposeMsg}</p>
        )}

        <div className="mt-2 flex items-center gap-2">
          {mode === 'edit' && (
            <button type="button" onClick={remove} disabled={busy}
'@
  if (-not $v.Contains($oldC4)) { throw 'ANCHOR NOT FOUND: footer row' }
  $v = $v.Replace($oldC4, $newC4)

  W $vPath $v
  Write-Host 'PATCHED: task-board-view.tsx (AI decompose button)'
}

Write-Host 'DONE. Move decompose-actions.ts into src\lib\tasks\, then npm run build.'
