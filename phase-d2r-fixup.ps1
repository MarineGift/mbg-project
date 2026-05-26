# phase-d2r-fixup.ps1
# Phase: D2r-fixup (re-apply engagements.ts with CRLF anchors)
# Baseline: 31 errors. Target: 29 (-2).
# Root cause: D2r used LF anchors but engagements.ts is CRLF (per handoff).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2r-fixup.ps1" . -Force
#   Unblock-File .\phase-d2r-fixup.ps1
#   .\phase-d2r-fixup.ps1          # DryRun
#   .\phase-d2r-fixup.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2r-fixup ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 31 errors. Target: 29 (-2)" -ForegroundColor DarkGray
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

$engagements = "src\lib\queries\engagements.ts"

# Verify line ending (sanity check)
$bytes = [System.IO.File]::ReadAllBytes($engagements)
$hasCRLF = $false
for ($i = 0; $i -lt [Math]::Min($bytes.Length, 5000); $i++) {
    if ($bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i+1] -eq 10) { $hasCRLF = $true; break }
}
$eol = if ($hasCRLF) { "CRLF" } else { "LF" }
Write-Host ("engagements.ts line ending: " + $eol) -ForegroundColor White
Write-Host ""

# ============================================================
# Fix A1: engagements.ts L193 with CRLF
# ============================================================
Write-Host "--- A1 (retry): engagements.ts L193 module -> partyType: module (CRLF anchor) ---" -ForegroundColor Cyan
Set-PatchAll -Path $engagements `
    -A "      module,`r`n      pipelineDefinitionId: null," `
    -R "      partyType: module,`r`n      pipelineDefinitionId: null," `
    -Desc "engagements L193 KanbanBoard property (CRLF)"

# ============================================================
# Fix A2: engagements.ts L236 with CRLF
# ============================================================
Write-Host "`n--- A2 (retry): engagements.ts L236 module -> partyType: module (CRLF anchor) ---" -ForegroundColor Cyan
Set-PatchAll -Path $engagements `
    -A "    module,`r`n    pipelineDefinitionId: pipeline.id," `
    -R "    partyType: module,`r`n    pipelineDefinitionId: pipeline.id," `
    -Desc "engagements L236 KanbanBoard property (CRLF)"

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 31 - $errs

    Write-Host ("  Total errors: " + $errs + " (was 31, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 31) { "Green" } elseif ($errs -eq 31) { "Yellow" } else { "Red" }
    )

    $engErrs = ($tscOut | Select-String 'src/lib/queries/engagements.ts').Count
    Write-Host ("  engagements.ts: " + $engErrs + " errors") -ForegroundColor $(
        if ($engErrs -eq 0) { "Green" } else { "Yellow" }
    )

    Write-Host "`n--- Errors by file (top 20) ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match '^(.+?\.tsx?)\(\d+,\d+\):') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    if ($errs -lt 31) {
        Write-Host "`n--- Ready to commit (D2r + D2r-fixup as one) ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2r: bulk fix top 10 files + CRLF fixup (52 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
