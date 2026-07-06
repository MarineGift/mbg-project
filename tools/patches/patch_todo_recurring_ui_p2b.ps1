# ============================================================
# patch_todo_recurring_ui_p2b.ps1  (2026-07-06)
# To-do Phase 2b: expose recurrence in the UI (todo_items engine).
#  A) src/lib/tasks/types.ts        -> TaskItem gets recurrence fields
#  B) src/lib/tasks/actions.ts      -> CreateItemInput/UpdateItemPatch + write mapping
#  C) src/components/tasks/task-board-view.tsx
#       - TaskFormValues gains recurrence / recurrenceEnds
#       - createTask / updateTask pass them through
#       - quickCreate forwards parsed recurrence (parser v2)
#       - TaskModal gets a "Repeat" dropdown + end-date field
#       - kanban card shows a repeat glyph
# Prereq: quick-add-parser.ts v2 (with recurrence tokens) delivered alongside,
#         and DB migration migration_todo_recurring_phase2.sql + the org fix
#         already applied in Supabase.
# Idempotent: guarded per hunk. ASCII-only output.
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
function NL([string]$s) { return $s.Replace("`r`n", "`n") }
function WriteUtf8NoBom([string]$path, [string]$text) {
  [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}

# ---------- A) types.ts : TaskItem recurrence fields ----------
$typesPath = Join-Path $repo 'src\lib\tasks\types.ts'
$ty = [System.IO.File]::ReadAllText($typesPath).Replace("`r`n", "`n")
if ($ty.Contains('recurrence:')) {
  Write-Host 'SKIP (already patched): types.ts'
} else {
  $oldTy = NL @'
  party_id: string | null;
  contact_id: string | null;
  communication_id: string | null;
  custom: Record<string, unknown>;
'@
  $newTy = NL @'
  party_id: string | null;
  contact_id: string | null;
  communication_id: string | null;
  recurrence: string | null;         // 'FREQ=WEEKLY;INTERVAL=1' | null
  recurrence_ends: string | null;    // 'YYYY-MM-DD' | null
  recurrence_parent_id: string | null;
  custom: Record<string, unknown>;
'@
  if (-not $ty.Contains($oldTy)) { throw 'ANCHOR NOT FOUND: types.ts TaskItem' }
  $ty = $ty.Replace($oldTy, $newTy)
  WriteUtf8NoBom $typesPath $ty
  Write-Host 'PATCHED: types.ts (+recurrence fields)'
}

# ---------- B) actions.ts : inputs + write mapping ----------
$actionsPath = Join-Path $repo 'src\lib\tasks\actions.ts'
$ac = [System.IO.File]::ReadAllText($actionsPath).Replace("`r`n", "`n")
if ($ac.Contains('recurrence')) {
  Write-Host 'SKIP (already patched): actions.ts recurrence'
} else {
  # B1) CreateItemInput
  $oldCI = NL @'
  partyId?: string | null;
  contactId?: string | null;
  communicationId?: string | null;
}
'@
  $newCI = NL @'
  partyId?: string | null;
  contactId?: string | null;
  communicationId?: string | null;
  recurrence?: string | null;
  recurrenceEnds?: string | null;
}
'@
  if (-not $ac.Contains($oldCI)) { throw 'ANCHOR NOT FOUND: CreateItemInput' }
  $ac = $ac.Replace($oldCI, $newCI)

  # B2) createItem row mapping
  $oldRow = NL @'
    party_id: input.partyId ?? null,
    contact_id: input.contactId ?? null,
    communication_id: input.communicationId ?? null,
    // organization_id + created_by come from column defaults (SaaS: un-spoofable)
'@
  $newRow = NL @'
    party_id: input.partyId ?? null,
    contact_id: input.contactId ?? null,
    communication_id: input.communicationId ?? null,
    recurrence: input.recurrence ?? null,
    recurrence_ends: input.recurrenceEnds ?? null,
    // organization_id + created_by come from column defaults (SaaS: un-spoofable)
'@
  if (-not $ac.Contains($oldRow)) { throw 'ANCHOR NOT FOUND: createItem row' }
  $ac = $ac.Replace($oldRow, $newRow)

  # B3) UpdateItemPatch interface
  $oldUP = NL @'
  startDate?: string | null;
  dueDate?: string | null;
  position?: number;
  archived?: boolean;
}
'@
  $newUP = NL @'
  startDate?: string | null;
  dueDate?: string | null;
  position?: number;
  archived?: boolean;
  recurrence?: string | null;
  recurrenceEnds?: string | null;
}
'@
  if (-not $ac.Contains($oldUP)) { throw 'ANCHOR NOT FOUND: UpdateItemPatch' }
  $ac = $ac.Replace($oldUP, $newUP)

  # B4) updateItem mapping
  $oldUM = NL @'
  if (patch.dueDate !== undefined) row.due_date = patch.dueDate;
  if (patch.position !== undefined) row.position = patch.position;
'@
  $newUM = NL @'
  if (patch.dueDate !== undefined) row.due_date = patch.dueDate;
  if (patch.recurrence !== undefined) row.recurrence = patch.recurrence;
  if (patch.recurrenceEnds !== undefined) row.recurrence_ends = patch.recurrenceEnds;
  if (patch.position !== undefined) row.position = patch.position;
'@
  if (-not $ac.Contains($oldUM)) { throw 'ANCHOR NOT FOUND: updateItem mapping' }
  $ac = $ac.Replace($oldUM, $newUM)

  WriteUtf8NoBom $actionsPath $ac
  Write-Host 'PATCHED: actions.ts (+recurrence in/out)'
}

# ---------- C) task-board-view.tsx ----------
$viewPath = Join-Path $repo 'src\components\tasks\task-board-view.tsx'
$v = [System.IO.File]::ReadAllText($viewPath).Replace("`r`n", "`n")
if ($v.Contains('recurrence')) {
  Write-Host 'SKIP (already patched): task-board-view.tsx recurrence'
} else {

  # C1) TaskFormValues
  $oldFV = NL @'
interface TaskFormValues {
  title: string;
  status: string;
  priority: TaskPriority | null;
  startDate: string | null;
  dueDate: string | null;
  description: string | null;
}
'@
  $newFV = NL @'
interface TaskFormValues {
  title: string;
  status: string;
  priority: TaskPriority | null;
  startDate: string | null;
  dueDate: string | null;
  description: string | null;
  recurrence: string | null;
  recurrenceEnds: string | null;
}

// Repeat dropdown options (maps label -> RRULE subset understood by the DB trigger).
const RECUR_OPTIONS: Array<{ key: string; label: string; rule: string | null }> = [
  { key: 'none',    label: 'Does not repeat', rule: null },
  { key: 'daily',   label: 'Daily',           rule: 'FREQ=DAILY' },
  { key: 'weekly',  label: 'Weekly',          rule: 'FREQ=WEEKLY' },
  { key: 'biweekly',label: 'Every 2 weeks',   rule: 'FREQ=WEEKLY;INTERVAL=2' },
  { key: 'monthly', label: 'Monthly',         rule: 'FREQ=MONTHLY' },
  { key: 'yearly',  label: 'Yearly',          rule: 'FREQ=YEARLY' },
];
function ruleToKey(rule: string | null): string {
  if (!rule) return 'none';
  return RECUR_OPTIONS.find((o) => o.rule === rule)?.key ?? 'none';
}
'@
  if (-not $v.Contains($oldFV)) { throw 'ANCHOR NOT FOUND: TaskFormValues' }
  $v = $v.Replace($oldFV, $newFV)

  # C2) createTask pass-through
  $oldCT = NL @'
        title: v.title,
        status: v.status,
        priority: v.priority,
        startDate: v.startDate,
        dueDate: v.dueDate,
        description: v.description,
        position: nextPos(v.status),
      });
'@
  $newCT = NL @'
        title: v.title,
        status: v.status,
        priority: v.priority,
        startDate: v.startDate,
        dueDate: v.dueDate,
        description: v.description,
        recurrence: v.recurrence,
        recurrenceEnds: v.recurrenceEnds,
        position: nextPos(v.status),
      });
'@
  if (-not $v.Contains($oldCT)) { throw 'ANCHOR NOT FOUND: createTask payload' }
  $v = $v.Replace($oldCT, $newCT)

  # C3) updateTask optimistic state + server patch
  $oldUT = NL @'
              start_date: v.startDate,
              due_date: v.dueDate,
              description: v.description,
            }
          : i,
      ),
    );
    startTransition(async () => {
      try {
        await updateItem(id, {
          title: v.title,
          status: v.status,
          priority: v.priority,
          startDate: v.startDate,
          dueDate: v.dueDate,
          description: v.description,
        });
'@
  $newUT = NL @'
              start_date: v.startDate,
              due_date: v.dueDate,
              description: v.description,
              recurrence: v.recurrence,
              recurrence_ends: v.recurrenceEnds,
            }
          : i,
      ),
    );
    startTransition(async () => {
      try {
        await updateItem(id, {
          title: v.title,
          status: v.status,
          priority: v.priority,
          startDate: v.startDate,
          dueDate: v.dueDate,
          description: v.description,
          recurrence: v.recurrence,
          recurrenceEnds: v.recurrenceEnds,
        });
'@
  if (-not $v.Contains($oldUT)) { throw 'ANCHOR NOT FOUND: updateTask' }
  $v = $v.Replace($oldUT, $newUT)

  # C4) quickCreate forwards parsed recurrence
  $oldQCr = NL @'
        priority: parsed.priority,
        startDate: parsed.startDate,
        dueDate: parsed.dueDate,
        partyId,
        position: nextPos(status),
'@
  $newQCr = NL @'
        priority: parsed.priority,
        startDate: parsed.startDate,
        dueDate: parsed.dueDate,
        recurrence: parsed.recurrence,
        partyId,
        position: nextPos(status),
'@
  if (-not $v.Contains($oldQCr)) { throw 'ANCHOR NOT FOUND: quickCreate recurrence' }
  $v = $v.Replace($oldQCr, $newQCr)

  # C5) TaskModal state
  $oldMS = NL @'
  const [description, setDescription] = useState(item?.description ?? '');
  const [busy, setBusy] = useState(false);
'@
  $newMS = NL @'
  const [description, setDescription] = useState(item?.description ?? '');
  const [recurKey, setRecurKey] = useState<string>(ruleToKey(item?.recurrence ?? null));
  const [recurEnds, setRecurEnds] = useState(item?.recurrence_ends ?? '');
  const [busy, setBusy] = useState(false);
  const recurRule = RECUR_OPTIONS.find((o) => o.key === recurKey)?.rule ?? null;
'@
  if (-not $v.Contains($oldMS)) { throw 'ANCHOR NOT FOUND: TaskModal state' }
  $v = $v.Replace($oldMS, $newMS)

  # C6) TaskModal save payload
  $oldMSave = NL @'
      startDate: startDate || null,
      dueDate: dueDate || null,
      description: description.trim() ? description.trim() : null,
    };
'@
  $newMSave = NL @'
      startDate: startDate || null,
      dueDate: dueDate || null,
      description: description.trim() ? description.trim() : null,
      recurrence: recurRule,
      recurrenceEnds: recurRule ? (recurEnds || null) : null,
    };
'@
  if (-not $v.Contains($oldMSave)) { throw 'ANCHOR NOT FOUND: TaskModal save' }
  $v = $v.Replace($oldMSave, $newMSave)

  # C7) TaskModal Repeat UI (insert after the Gantt hint line)
  $oldHint = '<p className="mb-3 text-[10.5px] text-slate-400">Both a start and a due date are required to appear on the Gantt.</p>'
  $newHint = $oldHint + "`n" + (NL @'

        <div className="mb-3 grid grid-cols-2 gap-3">
          <div>
            <label className={labelCls}>Repeat</label>
            <select value={recurKey} onChange={(e) => setRecurKey(e.target.value)} className={fieldCls}>
              {RECUR_OPTIONS.map((o) => <option key={o.key} value={o.key}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className={labelCls}>Repeat until</label>
            <input
              type="date"
              value={recurEnds}
              onChange={(e) => setRecurEnds(e.target.value)}
              disabled={recurKey === 'none'}
              className={fieldCls + (recurKey === 'none' ? ' opacity-40' : '')}
            />
          </div>
        </div>
        {recurKey !== 'none' && !dueDate && (
          <p className="mb-3 text-[11px] text-amber-600">A due date is required for a repeating task to schedule its next occurrence.</p>
        )}
'@)
  if (-not $v.Contains($oldHint)) { throw 'ANCHOR NOT FOUND: Gantt hint' }
  $v = $v.Replace($oldHint, $newHint)

  # C8) kanban card repeat glyph (next to due date)
  $oldCard = NL @'
                      {it.due_date && (
                        <span className="ml-auto text-[10.5px] text-muted-foreground">
                          {it.due_date}
                        </span>
                      )}
'@
  $newCard = NL @'
                      {it.recurrence && (
                        <span className={it.due_date ? 'ml-auto text-[11px] text-muted-foreground' : 'ml-auto'} title={it.recurrence} aria-label="repeats">
                          &#8635;
                        </span>
                      )}
                      {it.due_date && (
                        <span className={(it.recurrence ? 'ml-1' : 'ml-auto') + ' text-[10.5px] text-muted-foreground'}>
                          {it.due_date}
                        </span>
                      )}
'@
  if (-not $v.Contains($oldCard)) { throw 'ANCHOR NOT FOUND: kanban card due' }
  $v = $v.Replace($oldCard, $newCard)

  WriteUtf8NoBom $viewPath $v
  Write-Host 'PATCHED: task-board-view.tsx (recurrence UI wired)'
}

Write-Host 'DONE. Replace quick-add-parser.ts with the v2 file, then npm run build.'
