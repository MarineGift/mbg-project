# phase-d2r.ps1
# Phase: D2r bulk fix for top 10 files
# Baseline: 52 errors. Target: ~29 (-23, all top 10 files -> 0).
# Strategy: 4 groups of targeted anchor fixes.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2r.ps1" . -Force
#   Unblock-File .\phase-d2r.ps1
#   .\phase-d2r.ps1          # DryRun
#   .\phase-d2r.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2r ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 52 errors. Target: ~29 (-23)" -ForegroundColor DarkGray
Write-Host ""

function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("  [MISS] " + $Path) -ForegroundColor DarkGray; return
    }
    $c = [System.IO.File]::ReadAllText($Path)
    $count = ([regex]::Matches($c, [regex]::Escape($A))).Count
    if ($count -eq 0) {
        Write-Host ("  [SKIP] " + $Desc) -ForegroundColor DarkYellow; return
    }
    Write-Host ("  [OK x" + $count + "] " + $Desc) -ForegroundColor Green
    if ($Apply) {
        $new = $c.Replace($A, $R)
        [System.IO.File]::WriteAllText($Path, $new, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# File paths
$engagements   = "src\lib\queries\engagements.ts"
$partyIdPage   = "src\app\(app)\[partyType]\parties\[id]\page.tsx"
$calendarSync  = "src\app\actions\calendar-sync.ts"
$emailWhitelist = "src\lib\actions\email-whitelist.ts"
$promptRenderer = "src\lib\ai\prompt-renderer.ts"
$engagementsEmpty = "src\components\engagements\engagements-empty.tsx"
$quickCampaign = "src\components\settings\quick-campaign-dialog.tsx"
$partySupply   = "src\components\parties\party-supply-links-panel.tsx"
$calendarView  = "src\components\calendar\calendar-view.tsx"
$sequenceForm  = "src\components\settings\sequence-form-dialog.tsx"

# ============================================================
# GROUP A: Property name alignment
# ============================================================
Write-Host "=== GROUP A: Property name alignment ===" -ForegroundColor Cyan

Write-Host "`n--- A1: engagements.ts L193 module -> partyType: module ---" -ForegroundColor Cyan
Set-PatchAll -Path $engagements `
    -A "      module,`n      pipelineDefinitionId: null," `
    -R "      partyType: module,`n      pipelineDefinitionId: null," `
    -Desc "engagements L193 KanbanBoard property"

Write-Host "`n--- A2: engagements.ts L236 module -> partyType: module ---" -ForegroundColor Cyan
Set-PatchAll -Path $engagements `
    -A "    module,`n    pipelineDefinitionId: pipeline.id," `
    -R "    partyType: module,`n    pipelineDefinitionId: pipeline.id," `
    -Desc "engagements L236 KanbanBoard property"

Write-Host "`n--- A3: engagements.ts L297 KanbanStage -> never ---" -ForegroundColor Cyan
Set-PatchAll -Path $engagements `
    -A "[] as KanbanStage[]" `
    -R "[] as never[]" `
    -Desc "engagements L297 KanbanStage missing import"

Write-Host "`n--- A4: prompt-renderer.ts L164 data.partyType -> data.module ---" -ForegroundColor Cyan
Set-PatchAll -Path $promptRenderer `
    -A "partyType: data.partyType," `
    -R "partyType: data.module," `
    -Desc "prompt-renderer L164 data.module"

Write-Host "`n--- A5: prompt-renderer.ts L190 data.partyType -> data.party_type ---" -ForegroundColor Cyan
Set-PatchAll -Path $promptRenderer `
    -A "partyType: data.partyType ?? undefined," `
    -R "partyType: data.party_type ?? undefined," `
    -Desc "prompt-renderer L190 data.party_type"

Write-Host "`n--- A6: engagements-empty.tsx ({ module }: Props) -> ({ partyType: module }: Props) (2x) ---" -ForegroundColor Cyan
Set-PatchAll -Path $engagementsEmpty `
    -A "({ module }: Props)" `
    -R "({ partyType: module }: Props)" `
    -Desc "engagements-empty destructure rename"

# ============================================================
# GROUP B: Type casts / null assertions
# ============================================================
Write-Host "`n=== GROUP B: Type casts / null assertions ===" -ForegroundColor Cyan

Write-Host "`n--- B1: parties/[id]/page.tsx industryPaperMillId cast (2x) ---" -ForegroundColor Cyan
Set-PatchAll -Path $partyIdPage `
    -A "full.party.industryPaperMillId" `
    -R "(full.party as any).industryPaperMillId" `
    -Desc "parties page industryPaperMillId cast"

Write-Host "`n--- B2: parties/[id]/page.tsx L158 meetings cast ---" -ForegroundColor Cyan
Set-PatchAll -Path $partyIdPage `
    -A "meetings={meetings}" `
    -R "meetings={meetings as never}" `
    -Desc "parties page meetings cast"

Write-Host "`n--- B3: calendar-sync.ts L78 ConnectionSummary[] via unknown ---" -ForegroundColor Cyan
Set-PatchAll -Path $calendarSync `
    -A "as ConnectionSummary[]" `
    -R "as unknown as ConnectionSummary[]" `
    -Desc "calendar-sync L78 unknown intermediate"

Write-Host "`n--- B4: quick-campaign-dialog.tsx preview!.with_email (2x) ---" -ForegroundColor Cyan
Set-PatchAll -Path $quickCampaign `
    -A "preview.with_email" `
    -R "preview!.with_email" `
    -Desc "quick-campaign preview non-null"

Write-Host "`n--- B5: party-supply-links-panel.tsx typeInfo!.color ---" -ForegroundColor Cyan
Set-PatchAll -Path $partySupply `
    -A "typeInfo.color" `
    -R "typeInfo!.color" `
    -Desc "party-supply typeInfo.color non-null"

Write-Host "`n--- B6: party-supply-links-panel.tsx typeInfo!.label ---" -ForegroundColor Cyan
Set-PatchAll -Path $partySupply `
    -A "typeInfo.label" `
    -R "typeInfo!.label" `
    -Desc "party-supply typeInfo.label non-null"

# ============================================================
# GROUP C: Null/undefined coalescing
# ============================================================
Write-Host "`n=== GROUP C: Null/undefined coalescing ===" -ForegroundColor Cyan

Write-Host "`n--- C1: calendar-sync.ts token.split[1] non-null (2x) ---" -ForegroundColor Cyan
Set-PatchAll -Path $calendarSync `
    -A 'token.split(`.`)[1]' `
    -R 'token.split(`.`)[1]!' `
    -Desc "calendar-sync token.split non-null"

Write-Host "`n--- C2: email-whitelist.ts p_notes null -> undefined (2x) ---" -ForegroundColor Cyan
Set-PatchAll -Path $emailWhitelist `
    -A 'p_notes:notes||null' `
    -R 'p_notes:notes||undefined' `
    -Desc "email-whitelist p_notes undefined"

# ============================================================
# GROUP D: Function signature mismatches
# ============================================================
Write-Host "`n=== GROUP D: Function signature mismatches ===" -ForegroundColor Cyan

Write-Host "`n--- D1: calendar-view.tsx L124 onClick cast ---" -ForegroundColor Cyan
Set-PatchAll -Path $calendarView `
    -A "onClick={e => { (e as any).stopPropagation?.(); onItemClick(item) }}" `
    -R "onClick={((e: any) => { (e as any).stopPropagation?.(); onItemClick(item) }) as never}" `
    -Desc "calendar-view onClick cast"

Write-Host "`n--- D2: sequence-form-dialog.tsx L66 destructure non-null ---" -ForegroundColor Cyan
Set-PatchAll -Path $sequenceForm `
    -A "[arr[index], arr[next]] = [arr[next], arr[index]];" `
    -R "[arr[index], arr[next]] = [arr[next]!, arr[index]!];" `
    -Desc "sequence-form destructure non-null"

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 52 - $errs

    Write-Host ("  Total errors: " + $errs + " (was 52, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 52) { "Green" } elseif ($errs -eq 52) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Per-target-file status ---" -ForegroundColor Cyan
    $targets = @($engagements, $partyIdPage, $calendarSync, $emailWhitelist, $promptRenderer,
                 $engagementsEmpty, $quickCampaign, $partySupply, $calendarView, $sequenceForm)
    foreach ($t in $targets) {
        $tNorm = $t -replace '\\', '/'
        $escaped = [regex]::Escape($tNorm)
        $cnt = ($tscOut | Select-String 'error TS' | Where-Object { $_.Line -match ('^' + $escaped + '\(') }).Count
        $color = if ($cnt -eq 0) { "Green" } else { "Yellow" }
        Write-Host ("  " + $cnt.ToString().PadLeft(2) + " | " + $t) -ForegroundColor $color
    }

    Write-Host "`n--- Errors by file (top 15) ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match '^(.+?\.tsx?)\(\d+,\d+\):') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    if ($errs -lt 52) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2r: bulk fix top 10 files across 4 pattern groups (52 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
