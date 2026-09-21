# IPO ↔ URM pipeline integration — handoff (2026-09-21)

## What it does
| URM object | IPO module | Sync |
|---|---|---|
| Campaign `IPO Program — Nasdaq Listing 2029` | — | container for the deal |
| Pipeline `ipo_program`, stages P0…P6 (`stages.code` = `ipo_phases.code`) | phases | 1:1 |
| Deal `Nasdaq Listing 2029` (party = Self / MarineBio Group) | `ipo_programs.deal_id` | 1 |
| 66 tasks, one per milestone, in the milestone's phase stage | `ipo_milestones.task_id` | status both ways; task `due_at` → milestone `target_date` (one way) |
| 28 stage checklist items = gate questions + pass conditions | `ipo_readiness_gates` | read-only mirror (Playbook page) |
| Engagements | attach to the task via `engagements.task_id` (existing UI) | counted in `v_ipo_milestone_tasks` |

Guard: the program deal cannot be moved into **P5** without a recorded **Gate 2** decision, nor into **P6** without **Gate 3** (`ipo_decision_reviews`, decision ≠ undecided/defer). Raises an error in the kanban drag.

Tested on PostgreSQL 16 with real-shaped tables: seed twice (idempotent), task→milestone, milestone→task, due_at→target_date, guard blocks then passes after a gate2 row.

## Files
| File | Where |
|---|---|
| `migration_ipo_urm_link.sql` | `sql\` (commit) |
| `seed_ipo_urm_link.sql` | `sql\` (commit, placeholder v_org) |
| `paste_seed_ipo_urm_link.sql.txt` | Downloads only — run this one |
| `ipo_page.tsx`, `ipo_gantt.tsx` | `src\app\(app)\ipo\` — "task" link per milestone, "Program deal / tasks →" in header |
| `handoff_ipo_urm_link.md` | `docs\handoff\2026-09-21\` |

## Run (SQL Editor)
```
1) migration_ipo_urm_link.sql
2) paste_seed_ipo_urm_link.sql.txt   → NOTICE: tasks created: 66 / stage checklist rows processed: 28
3) SELECT s.code, count(t.id) FROM app.stages s LEFT JOIN app.tasks t ON t.stage_id = s.id
    WHERE s.pipeline_id = (SELECT id FROM app.pipelines WHERE code='ipo_program') GROUP BY s.code ORDER BY s.code;
   → P0 10, P1 10, P2 10, P3 11, P4 10, P5 8, P6 7
```
Sidebar will show a new pipeline **IPO Program** with one deal. To-Do / Today / Calendar now surface the 66 milestone tasks by due date.

## Files → repo
```powershell
$dl = Join-Path $env:USERPROFILE "Downloads"; $repo = "C:\dev\mbg-project"; $today = "2026-09-21"
foreach ($m in @(
  @{ b="migration_ipo_urm_link"; e="sql"; d="sql";                  n="migration_ipo_urm_link.sql" },
  @{ b="seed_ipo_urm_link";      e="sql"; d="sql";                  n="seed_ipo_urm_link.sql" },
  @{ b="ipo_page";               e="tsx"; d="src\app\(app)\ipo";    n="page.tsx" },
  @{ b="ipo_gantt";              e="tsx"; d="src\app\(app)\ipo";    n="ipo-gantt.tsx" },
  @{ b="handoff_ipo_urm_link";   e="md";  d="docs\handoff\$today";  n="handoff_ipo_urm_link.md" })) {
  $src = Get-ChildItem $dl -Filter "$($m.b)*.$($m.e)" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host "MISS $($m.b)"; continue }
  $dir = Join-Path $repo $m.d; [System.IO.Directory]::CreateDirectory($dir) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $dir $m.n), $true); Write-Host "OK $($m.n)"
}
cd $repo; npm run typecheck
git add sql/migration_ipo_urm_link.sql sql/seed_ipo_urm_link.sql "src/app/(app)/ipo" docs/handoff/2026-09-21/handoff_ipo_urm_link.md
git commit -m "feat(ipo): link program to URM deal/tasks with two-way status sync and stage guards"
git push origin marinebiogroup
```

## Operating rules
- Work milestones from **To-Do / task pages** (assignee, notes, engagements). Status flows back to `/ipo` automatically.
- Change dates on the **task** (`due_at`) — the milestone follows. Changing `target_date` in SQL does not push to the task by design.
- Advisors (underwriter, auditor…) stay as deals in `nasdaq_advisors`; log meetings as engagements on the milestone task (e.g. A-FA-01) with the advisor as participant.
- Do not create tasks by hand on the program deal for things that are milestones; add a milestone in `/ipo` instead, then run the paste seed again — it only creates tasks for milestones without one.
