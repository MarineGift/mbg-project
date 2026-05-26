# phase-d2q-diagnostic.ps1
# Phase: D2q diagnostic (read-only)
# Target: src/lib/utils/sequence-processor.ts (10 errors)
# No -Apply mode. Pure diagnostic.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2q-diagnostic.ps1" . -Force
#   Unblock-File .\phase-d2q-diagnostic.ps1
#   .\phase-d2q-diagnostic.ps1

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

$file = "src\lib\utils\sequence-processor.ts"

Write-Host "`n=== Phase D2q Diagnostic ===" -ForegroundColor Cyan
Write-Host "Target: $file" -ForegroundColor White
Write-Host ""

if (-not (Test-Path -LiteralPath $file)) {
    Write-Host "[MISS] File not found" -ForegroundColor Red
    exit 1
}

# ============================================================
# 1. File info
# ============================================================
$lines = Get-Content -LiteralPath $file
$bytes = [System.IO.File]::ReadAllBytes($file)
$hasCRLF = $false
for ($i = 0; $i -lt [Math]::Min($bytes.Length, 5000); $i++) {
    if ($bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i+1] -eq 10) { $hasCRLF = $true; break }
}
$eol = if ($hasCRLF) { "CRLF" } else { "LF" }

Write-Host ("Total lines: " + $lines.Count + "  |  Line ending: " + $eol) -ForegroundColor White
Write-Host ""

# ============================================================
# 2. Pull tsc errors for this file
# ============================================================
Write-Host "Running tsc..." -ForegroundColor DarkGray
$tscOut = npx tsc --noEmit 2>&1
$errLines = $tscOut | Select-String 'src/lib/utils/sequence-processor.ts'

Write-Host ""
Write-Host ("--- All " + $errLines.Count + " errors in this file ---") -ForegroundColor Cyan
$errLines | ForEach-Object { Write-Host ("  " + $_.Line) -ForegroundColor DarkGray }

# ============================================================
# 3. Group errors by line, sort
# ============================================================
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

# ============================================================
# 4. File header (imports / types — usually first 40 lines)
# ============================================================
Write-Host ""
Write-Host "--- File header (L1-40) for imports and type definitions ---" -ForegroundColor Cyan
$headerEnd = [Math]::Min(40, $lines.Count)
for ($i = 0; $i -lt $headerEnd; $i++) {
    Write-Host ("    " + ($i+1).ToString().PadLeft(4) + " | " + $lines[$i]) -ForegroundColor DarkGray
}

# ============================================================
# 5. Per-error context (+/- 6 lines)
# ============================================================
Write-Host ""
Write-Host "--- Per-error context (+/- 6 lines) ---" -ForegroundColor Cyan

foreach ($lineNum in $sortedLineNums) {
    Write-Host ""
    Write-Host ("[L" + $lineNum + "]") -ForegroundColor Yellow
    foreach ($e in $errorsByLine[$lineNum]) {
        Write-Host ("  col " + $e.col + ": " + $e.msg) -ForegroundColor Red
    }

    $start = [Math]::Max(1, $lineNum - 6)
    $end = [Math]::Min($lines.Count, $lineNum + 6)
    for ($i = $start; $i -le $end; $i++) {
        $marker = if ($i -eq $lineNum) { ">>" } else { "  " }
        Write-Host ("    " + $marker + " " + $i.ToString().PadLeft(4) + " | " + $lines[$i-1]) -ForegroundColor DarkGray
    }
}

# ============================================================
# 6. Pattern hints from handoff
# ============================================================
Write-Host ""
Write-Host "--- Handoff pattern hints (line numbers may have shifted) ---" -ForegroundColor Cyan
Write-Host "  L50  : rpc() typed helper called with 2 args, requires 3" -ForegroundColor DarkGray
Write-Host "  L56  : 'as DueEnrollment[]' cast -> 'as unknown as DueEnrollment[]'" -ForegroundColor DarkGray
Write-Host "  L77  : 'skipped_no_email' not in enum 'pending'|'failed'|'sent'|'skipped'|'bounced'" -ForegroundColor DarkGray
Write-Host "  L92,93,97: MergeFieldValues shape mismatch" -ForegroundColor DarkGray
Write-Host "  L152,191,226: record_send_result RPC missing args (p_communication_id, p_is_last_step, p_step_id, p_step_order)" -ForegroundColor DarkGray
Write-Host "  L217 : insert payload has excess 'status' property" -ForegroundColor DarkGray

Write-Host ""
Write-Host "Diagnostic complete. No files modified." -ForegroundColor Green
Write-Host ""
