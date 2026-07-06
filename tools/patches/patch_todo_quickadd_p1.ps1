# ============================================================
# patch_todo_quickadd_p1.ps1  (2026-07-06)
# To-do Phase 1: natural-language quick-add.
#  A) src/lib/tasks/actions.ts        -> append resolvePartyIdByName()
#  B) src/components/tasks/task-board-view.tsx
#       - import parseQuickAdd + resolvePartyIdByName
#       - quickCreate() parses date / priority / @party from the title
#       - kanban quick-add placeholder hints the syntax
# Prereq: src/lib/tasks/quick-add-parser.ts must already be in the repo
#         (delivered alongside this patch).
# Idempotent: guarded, safe to run on both machines. ASCII-only output.
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'

function NL([string]$s) { return $s.Replace("`r`n", "`n") }

# ---------- A) actions.ts : append resolvePartyIdByName ----------
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

# ---------- B) task-board-view.tsx : wire the parser ----------
$viewPath = Join-Path $repo 'src\components\tasks\task-board-view.tsx'
$v = [System.IO.File]::ReadAllText($viewPath)
$v = $v.Replace("`r`n", "`n")
if ($v.Contains('parseQuickAdd')) {
  Write-Host 'SKIP (already patched): task-board-view.tsx'
} else {

  # B1) imports
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

  # B2) quickCreate with NL parsing
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

  # B3) placeholder hint (ASCII only)
  $oldPh = 'placeholder="Task title (Enter)"'
  $newPh = 'placeholder="Task (e.g. follow up thu p1 @party)"'
  if (-not $v.Contains($oldPh)) { throw 'ANCHOR NOT FOUND: placeholder' }
  $v = $v.Replace($oldPh, $newPh)

  [System.IO.File]::WriteAllText($viewPath, $v, [System.Text.UTF8Encoding]::new($false))
  Write-Host 'PATCHED: task-board-view.tsx (NL quick-add wired)'
}

Write-Host 'DONE. Next: npm run build (or dev) to verify, then commit + push.'
