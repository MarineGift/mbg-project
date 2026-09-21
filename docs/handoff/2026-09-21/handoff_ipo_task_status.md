# Handoff — IPO tasks visibility + October milestones (2026-09-21, session 2)

## Finding: why the IPO tasks are not on /todo
- `/todo` renders `app.todo_items` (board engine: `todo_boards`, `todo_status_options`).
- The 66 IPO tasks live in `app.tasks` (deal tasks). They can never appear on `/todo`, whatever their status.
  Changing `pending` -> `todo` would fix nothing. Not done.
- Where `app.tasks` do show: `/tasks` (open = status <> 'completed'), deal page Tasks tab
  (`/pipelines/ipo_program/deals/<id>`), `/today` cockpit (due this week or blocked), daily reminder digest.
- Real bug found instead: milestone `done` mapped to task `done`, but `/tasks` treats only `completed` as finished,
  so a done milestone left its task "open". Fixed in `sql/fix_ipo_task_status_completed.sql`.
- Deliberately NOT mirroring IPO tasks into `todo_items` (would duplicate 66 rows and need a third sync path).

## Applied by fix_ipo_task_status_completed.sql
1. `app.ipo_milestone_status_to_task()`: done -> 'completed' (pending default unchanged).
2. Existing IPO tasks at 'done' -> 'completed'.
3. F-IP-01, F-IP-03, F-CM-01 -> in_progress (tasks follow via trigger). A-FA-01 stays not_started until Nov.

## Entered in the UI (not SQL, not in repo)
- Patents tab -> Edit: US 19/396,332 recordation_date (USPTO Assignment Center, recorded date of the reel/frame),
  JP row application_no (placeholder `PCT/KR2024/009859-JP` -> real JP number from the JP agent).
- Criteria & KPIs -> Save snapshot: stockholders_equity (verified off until review/audit), operating_history_years,
  active_licensees = 0, cash, monthly_burn, cash_runway_months (= cash / monthly_burn, entered with the same as_of).

## Still open
- `sql/migration_ipo_module.sql` is referenced in handoffs but is NOT in the repo. Export the DDL from Supabase
  (tables, enums, views, triggers of the ipo_* module) and commit it so the schema is reproducible.
- KR priorities 10-2023-0092012 / 10-2024-0089038 grant status.
- Royalty ledger entry screen (by 2027 Q3), advisor<->milestone linking (2028 H2), decision-log page.

## Mover (inline, fallback for tools\move-downloads.ps1)
```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map  = @(
  @{ name='fix_ipo_task_status_completed'; ext='.sql'; dest='sql\fix_ipo_task_status_completed.sql' },
  @{ name='handoff_ipo_task_status';       ext='.md';  dest='docs\handoff\2026-09-21\handoff_ipo_task_status.md' }
)
foreach ($m in $map) {
  $src = Get-ChildItem -LiteralPath $dl -File | Where-Object { $_.Name -like ($m.name + '*' + $m.ext) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ('MISSING ' + $m.name); continue }
  Unblock-File -LiteralPath $src.FullName
  $dst = Join-Path $repo $m.dest
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dst)) | Out-Null
  [System.IO.File]::Copy($src.FullName, $dst, $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host ('OK ' + $m.dest)
}
```
