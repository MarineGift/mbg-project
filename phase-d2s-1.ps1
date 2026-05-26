# phase-d2s-1.ps1
# Phase: D2s-1 (destructure rename + JSX prop rename + strict null assertions)
# Baseline: 29 errors. Target: ~13 (-16).
# Strategy: 3 pattern groups, 16 anchor fixes.
#
# CRITICAL: per-file EOL handling (CRLF vs LF per diagnostic)
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2s-1.ps1" . -Force
#   Unblock-File .\phase-d2s-1.ps1
#   .\phase-d2s-1.ps1          # DryRun
#   .\phase-d2s-1.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2s-1 ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 29 errors. Target: ~13 (-16)" -ForegroundColor DarkGray
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

# ============================================================
# GROUP A: Destructure rename
# Convert `{ module }: Props` -> `{ partyType: module }: Props`
# ============================================================
Write-Host "=== GROUP A: Destructure rename ===" -ForegroundColor Cyan

Write-Host "`n--- A1: engagement-form.tsx L110 (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\engagements\engagement-form.tsx" `
    -A "  module,`r`n  partyId," `
    -R "  partyType: module,`r`n  partyId," `
    -Desc "engagement-form destructure"

Write-Host "`n--- A2: party-engagements-list.tsx L32 (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\parties\party-engagements-list.tsx" `
    -A ", partyId, module }: Props)" `
    -R ", partyId, partyType: module }: Props)" `
    -Desc "party-engagements-list destructure"

Write-Host "`n--- A3: party-tasks-list.tsx L29 (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\parties\party-tasks-list.tsx" `
    -A ", partyId, module }: Props)" `
    -R ", partyId, partyType: module }: Props)" `
    -Desc "party-tasks-list destructure"

Write-Host "`n--- A4: task-form-dialog.tsx L61 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\tasks\task-form-dialog.tsx" `
    -A "  engagementId,`n  module,`n  existing," `
    -R "  engagementId,`n  partyType: module,`n  existing," `
    -Desc "task-form-dialog destructure"

# ============================================================
# GROUP B: JSX prop rename
# Convert `module={module}` -> `partyType={module}` for components that
# now expect partyType in Props
# ============================================================
Write-Host "`n=== GROUP B: JSX prop rename ===" -ForegroundColor Cyan

Write-Host "`n--- B1: engagements/page.tsx L65+L67 (LF, 2 sites) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\engagements\page.tsx" `
    -A "module={module} />" `
    -R "partyType={module} />" `
    -Desc "engagements page module JSX prop"

Write-Host "`n--- B2: engagements/new/page.tsx L66 (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\engagements\new\page.tsx" `
    -A "        module={module}`r`n        partyId=" `
    -R "        partyType={module}`r`n        partyId=" `
    -Desc "engagements/new page module JSX prop"

Write-Host "`n--- B3: engagements/[id]/edit/page.tsx L39 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\engagements\[id]\edit\page.tsx" `
    -A "module={engagement.partyType}" `
    -R "partyType={engagement.partyType}" `
    -Desc "engagements/[id]/edit page module JSX prop"

Write-Host "`n--- B4: parties/page.tsx L231 (LF, SavedViewsDropdown) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\parties\page.tsx" `
    -A "entityType=`"party`" module={module}" `
    -R "entityType=`"party`" partyType={module}" `
    -Desc "parties page SavedViewsDropdown module JSX prop"

# ============================================================
# GROUP C: Strict null `!` assertions
# Add non-null assertion to possibly-undefined accesses
# ============================================================
Write-Host "`n=== GROUP C: Strict null `!` assertions ===" -ForegroundColor Cyan

Write-Host "`n--- C1: delete-communication.ts L82 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\actions\delete-communication.ts" `
    -A "session.access_token.split('.')[1]" `
    -R "session.access_token.split('.')[1]!" `
    -Desc "delete-comm access_token split non-null"

Write-Host "`n--- C2: api/calendar/google/callback/route.ts L35 (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\api\calendar\google\callback\route.ts" `
    -A ".update(nonce)" `
    -R ".update(nonce!)" `
    -Desc "calendar callback nonce non-null"

Write-Host "`n--- C3: calendar-event-chip.tsx L42 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\calendar\calendar-event-chip.tsx" `
    -A "?? CHIP_STYLES.event_internal" `
    -R "?? CHIP_STYLES.event_internal!" `
    -Desc "calendar-event-chip fallback non-null"

Write-Host "`n--- C4: topbar-search-input.tsx L27 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\layout\topbar-search-input.tsx" `
    -A "VALID_MODULES.includes(segments[0])" `
    -R "VALID_MODULES.includes(segments[0]!)" `
    -Desc "topbar-search segments non-null"

Write-Host "`n--- C5: merge-fields.ts L39 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\utils\merge-fields.ts" `
    -A "out.add(m[1])" `
    -R "out.add(m[1]!)" `
    -Desc "merge-fields regex match non-null"

Write-Host "`n--- C6: pipelines/page.tsx L54 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\settings\pipelines\page.tsx" `
    -A "stagesByDef[s.pipeline_definition_id].push(s)" `
    -R "stagesByDef[s.pipeline_definition_id]!.push(s)" `
    -Desc "pipelines page index access non-null"

Write-Host "`n--- C7: PipelinesAdminClient.tsx L95 (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\settings\pipelines\PipelinesAdminClient.tsx" `
    -A "group.stages[group.stages.length - 1].sort_order" `
    -R "group.stages[group.stages.length - 1]!.sort_order" `
    -Desc "PipelinesAdminClient last stage non-null"

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 29 - $errs

    Write-Host ("  Total errors: " + $errs + " (was 29, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 29) { "Green" } elseif ($errs -eq 29) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Errors by file (top 20) ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match '^(.+?\.tsx?)\(\d+,\d+\):') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    Write-Host "`n--- Errors by TS code ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match 'error (TS\d+)') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    if ($errs -lt 29) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2s-1: destructure + JSX prop + strict null (29 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
