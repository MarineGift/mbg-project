# phase-d2r-diagnostic.ps1
# Phase: D2r diagnostic (read-only, top 10 files)
# Target: 10 files containing ~23 errors out of 52 remaining
# Goal: identify common patterns across files for bulk fix planning
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2r-diagnostic.ps1" . -Force
#   Unblock-File .\phase-d2r-diagnostic.ps1
#   .\phase-d2r-diagnostic.ps1

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

# Top 10 files from D2q tsc output
# Note: (app) and [partyType] need -LiteralPath handling
$targets = @(
    "src\lib\queries\engagements.ts",
    "src\app\(app)\[partyType]\parties\[id]\page.tsx",
    "src\app\actions\calendar-sync.ts",
    "src\lib\actions\email-whitelist.ts",
    "src\lib\ai\prompt-renderer.ts",
    "src\components\engagements\engagements-empty.tsx",
    "src\components\settings\quick-campaign-dialog.tsx",
    "src\components\parties\party-supply-links-panel.tsx",
    "src\components\calendar\calendar-view.tsx",
    "src\components\settings\sequence-form-dialog.tsx"
)

Write-Host "`n=== Phase D2r Diagnostic ===" -ForegroundColor Cyan
Write-Host ("Targets: " + $targets.Count + " files") -ForegroundColor White
Write-Host ""

# Run tsc once, reuse output
Write-Host "Running tsc..." -ForegroundColor DarkGray
$tscOut = npx tsc --noEmit 2>&1
$tscErrLines = $tscOut | Select-String 'error TS'
Write-Host ("Total errors: " + $tscErrLines.Count) -ForegroundColor White

# ============================================================
# TS code distribution across all targets (pattern spotter)
# ============================================================
Write-Host ""
Write-Host "--- TS error codes across all targets ---" -ForegroundColor Cyan
$targetErrs = @()
foreach ($t in $targets) {
    $tNorm = $t -replace '\\', '/'
    $matched = $tscErrLines | Where-Object { $_.Line.StartsWith($tNorm + "(") }
    $targetErrs += $matched
}
$targetErrs | ForEach-Object {
    if ($_.Line -match 'error (TS\d+)') { $matches[1] }
} | Group-Object | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
}

# ============================================================
# Per-file diagnostic
# ============================================================
foreach ($file in $targets) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
    Write-Host $file -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $file)) {
        Write-Host "  [MISS] File not found" -ForegroundColor Red
        continue
    }

    $lines = Get-Content -LiteralPath $file
    $fileNorm = $file -replace '\\', '/'

    # Pull errors for this file (escape special chars in path for regex)
    $escaped = [regex]::Escape($fileNorm)
    $errLines = $tscErrLines | Where-Object { $_.Line -match ('^' + $escaped + '\(') }

    Write-Host ("  Lines: " + $lines.Count + "  |  Errors: " + $errLines.Count) -ForegroundColor DarkGray

    if ($errLines.Count -eq 0) {
        Write-Host "  (no errors — may have been fixed)" -ForegroundColor Green
        continue
    }

    # Group errors by line
    $errorsByLine = @{}
    $errLines | ForEach-Object {
        if ($_.Line -match '\((\d+),(\d+)\):\s*(error TS\d+:.*)') {
            $lineNum = [int]$matches[1]
            $col = $matches[2]
            $msg = $matches[3]
            if (-not $errorsByLine.ContainsKey($lineNum)) {
                $errorsByLine[$lineNum] = @()
            }
            $errorsByLine[$lineNum] += @{ col = $col; msg = $msg }
        }
    }
    $sortedLineNums = $errorsByLine.Keys | Sort-Object

    foreach ($lineNum in $sortedLineNums) {
        Write-Host ""
        Write-Host ("  [L" + $lineNum + "]") -ForegroundColor Yellow
        foreach ($e in $errorsByLine[$lineNum]) {
            # Truncate long error messages for readability
            $msg = $e.msg
            if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 200) + "..." }
            Write-Host ("    col " + $e.col + ": " + $msg) -ForegroundColor Red
        }

        $start = [Math]::Max(1, $lineNum - 4)
        $end = [Math]::Min($lines.Count, $lineNum + 4)
        for ($i = $start; $i -le $end; $i++) {
            $marker = if ($i -eq $lineNum) { ">>" } else { "  " }
            Write-Host ("      " + $marker + " " + $i.ToString().PadLeft(4) + " | " + $lines[$i-1]) -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor DarkCyan
Write-Host "Diagnostic complete. No files modified." -ForegroundColor Green
Write-Host ""
