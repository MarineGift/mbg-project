# phase-d2s-2-diagnostic.ps1
# Phase: D2s-2 diagnostic (read-only)
# Re-diagnose all 15 remaining errors with current file state.
# Detects EOL per file. Shows ±3 lines context.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2s-2-diagnostic.ps1" . -Force
#   Unblock-File .\phase-d2s-2-diagnostic.ps1
#   .\phase-d2s-2-diagnostic.ps1

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2s-2 Diagnostic ===" -ForegroundColor Cyan
Write-Host "Read-only. Re-diagnose 15 remaining errors with current state." -ForegroundColor White
Write-Host ""

# Run tsc
Write-Host "Running tsc..." -ForegroundColor DarkGray
$tscOut = npx tsc --noEmit 2>&1
$errLines = $tscOut | Select-String 'error TS'
Write-Host ("Total errors: " + $errLines.Count) -ForegroundColor White

# Group errors by file
$errorsByFile = @{}
foreach ($el in $errLines) {
    if ($el.Line -match '^(.+?\.tsx?)\((\d+),(\d+)\):\s*(error TS\d+:.*)') {
        $filePath = $matches[1]
        $lineNum = [int]$matches[2]
        $col = $matches[3]
        $msg = $matches[4]
        if (-not $errorsByFile.ContainsKey($filePath)) {
            $errorsByFile[$filePath] = @()
        }
        $errorsByFile[$filePath] += @{ line = $lineNum; col = $col; msg = $msg }
    }
}

$sortedFiles = $errorsByFile.Keys | Sort-Object -Property @{Expression={$errorsByFile[$_].Count}; Descending=$true}, @{Expression={$_}}
Write-Host ("Files with errors: " + $sortedFiles.Count) -ForegroundColor White

# TS code distribution
Write-Host ""
Write-Host "--- TS error codes ---" -ForegroundColor Cyan
$errLines | ForEach-Object {
    if ($_.Line -match 'error (TS\d+)') { $matches[1] }
} | Group-Object | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
}

# Per-file diagnostic
foreach ($filePath in $sortedFiles) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan

    $localPath = $filePath -replace '/', '\'
    if (-not (Test-Path -LiteralPath $localPath)) {
        Write-Host ("[MISS] " + $localPath) -ForegroundColor Red
        continue
    }

    # Detect EOL
    $bytes = [System.IO.File]::ReadAllBytes($localPath)
    $hasCRLF = $false
    for ($i = 0; $i -lt [Math]::Min($bytes.Length, 5000); $i++) {
        if ($bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i+1] -eq 10) { $hasCRLF = $true; break }
    }
    $eol = if ($hasCRLF) { "CRLF" } else { "LF" }
    $eolColor = if ($hasCRLF) { "Yellow" } else { "White" }

    $lines = Get-Content -LiteralPath $localPath
    $errs = $errorsByFile[$filePath]

    Write-Host $filePath -ForegroundColor Cyan
    Write-Host ("  Lines: " + $lines.Count + "  |  EOL: " + $eol + "  |  Errors: " + $errs.Count) -ForegroundColor $eolColor

    $sortedErrs = $errs | Sort-Object { $_.line }

    foreach ($e in $sortedErrs) {
        $lineNum = $e.line
        $col = $e.col

        Write-Host ""
        Write-Host ("  [L" + $lineNum + "]") -ForegroundColor Yellow

        $msg = $e.msg
        if ($msg.Length -gt 250) { $msg = $msg.Substring(0, 250) + "..." }
        Write-Host ("    col " + $col + ": " + $msg) -ForegroundColor Red

        $start = [Math]::Max(1, $lineNum - 3)
        $end = [Math]::Min($lines.Count, $lineNum + 3)
        for ($i = $start; $i -le $end; $i++) {
            $marker = if ($i -eq $lineNum) { ">>" } else { "  " }
            Write-Host ("      " + $marker + " " + $i.ToString().PadLeft(4) + " | " + $lines[$i-1]) -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor DarkCyan
Write-Host "Diagnostic complete." -ForegroundColor Green
Write-Host ""
