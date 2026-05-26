# phase-d2s-diagnostic.ps1
# Phase: D2s diagnostic (read-only, all remaining ~29 errors across ~26 files)
# Includes line-ending detection per file to avoid CRLF/LF anchor mistakes.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2s-diagnostic.ps1" . -Force
#   Unblock-File .\phase-d2s-diagnostic.ps1
#   .\phase-d2s-diagnostic.ps1

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2s Diagnostic ===" -ForegroundColor Cyan
Write-Host "Read-only. Show all remaining errors with code context + line endings." -ForegroundColor White
Write-Host ""

# ============================================================
# 1. Run tsc and parse all errors
# ============================================================
Write-Host "Running tsc..." -ForegroundColor DarkGray
$tscOut = npx tsc --noEmit 2>&1
$errLines = $tscOut | Select-String 'error TS'
Write-Host ("Total errors: " + $errLines.Count) -ForegroundColor White

# ============================================================
# 2. Group errors by file
# ============================================================
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

# Sort files by error count desc, then alphabetical
$sortedFiles = $errorsByFile.Keys | Sort-Object -Property @{Expression={$errorsByFile[$_].Count}; Descending=$true}, @{Expression={$_}}

Write-Host ("Files with errors: " + $sortedFiles.Count) -ForegroundColor White

# ============================================================
# 3. TS code distribution
# ============================================================
Write-Host ""
Write-Host "--- TS error codes ---" -ForegroundColor Cyan
$errLines | ForEach-Object {
    if ($_.Line -match 'error (TS\d+)') { $matches[1] }
} | Group-Object | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
}

# ============================================================
# 4. Per-file: line ending + context for each error
# ============================================================
foreach ($filePath in $sortedFiles) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan

    # Convert forward slashes back to backslash for Windows path
    $localPath = $filePath -replace '/', '\'

    if (-not (Test-Path -LiteralPath $localPath)) {
        Write-Host ("[MISS] " + $localPath) -ForegroundColor Red
        continue
    }

    # Detect line ending
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

    # Sort errors by line number
    $sortedErrs = $errs | Sort-Object { $_.line }

    foreach ($e in $sortedErrs) {
        $lineNum = $e.line
        $col = $e.col

        Write-Host ""
        Write-Host ("  [L" + $lineNum + "]") -ForegroundColor Yellow

        # Truncate long messages
        $msg = $e.msg
        if ($msg.Length -gt 220) { $msg = $msg.Substring(0, 220) + "..." }
        Write-Host ("    col " + $col + ": " + $msg) -ForegroundColor Red

        # Show ±3 lines context
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
Write-Host "Note: Files with EOL=CRLF (highlighted yellow) require ``r``n in anchors." -ForegroundColor DarkGray
Write-Host ""
