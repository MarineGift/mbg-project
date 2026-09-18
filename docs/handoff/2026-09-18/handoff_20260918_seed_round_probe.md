# Handoff 2026-09-18 — Seed Round Step 0 Probe

## What this is

Read-only probe to confirm the real `rounds -> deals -> stages` wiring before any
Step 1-2 migration is written. Nothing is created, altered or deleted.

Background: `app.rounds` already exists with the full round shape
(`name, round_type, target_amount, pre_money_valuation, currency, status,
opened_at, closed_at, notes`), `listRoundsWithRollup()` already computes the
per-round committed / progress / stage breakdown, and the Kanban already has a
Round filter. The round layer is wired but switched off, and the codebase
disagrees with itself about why:

| File | Claim |
|---|---|
| `src/lib/queries/rounds.ts` | reads `deals.round_id` and `deal_parties`, resolves pipeline code `'investor'` (singular) |
| `src/app/(app)/pipelines/[code]/page.tsx` | comment says `app.deals` has **no** `round_id`, round join disabled, returns `round: null` |
| `src/app/(app)/pipelines/[code]/kanban-client.tsx` | shows the Round filter only when `pipeline.code === 'investors'` (plural) |

So one of those paths is dead code. The probe settles it against
`information_schema` instead of against comments.

## Decisions locked before this probe

- `rounds` = real fundraising rounds. `campaigns` = email / outreach campaigns. No overlap.
- Target stage set (8 + 2 exceptions):
  `Target -> Outreach -> Engaged -> Meeting -> Diligence -> Terms -> Committed -> Closed`,
  exceptions `Passed` / `Hold`.
- Stage moves are triggered by the counterparty's observable action, never by ours.
- **No stage code is renamed or deleted until the probe output is read** —
  `deal_stage_history`, the playbook templates and the forecast all key off those codes.

## Run it

1. Open the Supabase SQL Editor.
2. Paste `sql/probe_seed_round_wiring_2026-09-18.sql`.
3. **Press Ctrl+A (select all), then Run.** The editor runs only the highlighted
   text when a selection exists — a partial selection is what produces the
   `relation "X" does not exist` errors.
4. The file is a single statement, so it returns one result set. Click
   **Download CSV** and send that file back.

If section `A_table` reports `MISSING` for any table, say which one and the file
will be reissued without that table's block. Everything else in the file is
safe against missing columns (column reads go through `to_jsonb()`, which yields
NULL rather than an error).

## What the output answers

| Section | Question |
|---|---|
| `A_table` | which tables actually exist |
| `B_column` | real columns of rounds / deals / deal_parties / campaigns / stages / pipelines |
| `C_fk` | does `deals.round_id` have an FK to `rounds` |
| `D_pipeline` | the real pipeline code — `investor` or `investors` — and live deal counts |
| `E_stage` | current stage codes, sort order, live deals per stage, history rows per stage |
| `F_round_link` | `deals.round_id` present, and how many deals already carry one |
| `G_campaign` | campaign names and how many deals hang off each |
| `H_trigger` | triggers on the deal / stage tables (playbook, history) |
| `I_playbook` | checklist / task template counts per stage |
| `J_round` | rounds rows that already exist |
| `K_deal` | every live deal on the investor-side pipeline |
| `L_deal_parties` | `deal_parties` row count and how many carry a commitment amount |

`E_stage` + `I_playbook` together decide whether the 8-stage set can reuse
existing stage codes or needs a mapping table. `K_deal` lists exactly what a
stage rework would touch.

## Next steps after the CSV comes back

1. Create `MarineBio Group, Inc. 2026 Seed Round` in `app.rounds`
   (`target_amount` left null until the real figure is set — it will not be invented).
2. Add or confirm `deals.round_id` + FK, and reconcile the singular/plural
   pipeline code so `queries/rounds.ts`, `page.tsx` and `kanban-client.tsx` agree.
3. Re-enable the round join in `page.tsx`.
4. Map the existing stages onto the 8-stage set — reusing codes wherever possible.
5. Attach the real contacted investors as deals: Jonathan Silver (Engaged),
   Transition VC, Chemical Angels, AccelR8, Earth VC, E8, SustainVC, CTAN.
6. Seed Round playbook (`stage_checklist_templates` / `stage_task_templates`).
7. `/rounds` dashboard page — `listRoundsWithRollup()` already exists, only the screen is missing.

---

## Move the downloaded files into the repo

### Option 1 — universal mover (one line)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

Routing: `probe_*.sql` falls through to `sql\`, `handoff_*.md` goes to
`docs\handoff\2026-09-18\`.

### Option 2 — inline fallback (paste into PowerShell)

```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'

$pairs = @(
  @{ Base = 'probe_seed_round_wiring_2026-09-18'; Ext = '.sql'; Dest = (Join-Path $repo 'sql') },
  @{ Base = 'handoff_20260918_seed_round_probe';  Ext = '.md';  Dest = (Join-Path $repo 'docs\handoff\2026-09-18') }
)

foreach ($p in $pairs) {
  $pattern = $p.Base + '*' + $p.Ext
  $src = Get-ChildItem -LiteralPath $dl -Filter $pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ('SKIP  no match: ' + $pattern); continue }

  Unblock-File -LiteralPath $src.FullName -ErrorAction SilentlyContinue
  [System.IO.Directory]::CreateDirectory($p.Dest) | Out-Null
  $target = [System.IO.Path]::Combine($p.Dest, ($p.Base + $p.Ext))
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host ('OK    ' + $target)
}
```

The glob tolerates `(1)` / `(2)` suffixes and picks the newest match. The source
file in Downloads is deleted after the copy.

## Finish block

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/probe_seed_round_wiring_2026-09-18.sql docs/handoff/2026-09-18/handoff_20260918_seed_round_probe.md
git commit -m "probe: seed round wiring (rounds/deals/stages) - read only"
git push origin marinebiogroup
```

`git push` triggers the Railway auto-deploy, and this repo is public — the pushed
files are visible on the web. Nothing here contains credentials or org ids.
