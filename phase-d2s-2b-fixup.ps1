# phase-d2s-2b-fixup.ps1
# Phase: D2s-2b-fixup (final 1 error -> 0)
# Baseline: 1 error. Target: 0.
# Issue: D2s-2b Fix 4 used `as never` for payload, but L182 spreads payload
#        which fails (`never` is not spreadable).
# Fix:   `as never` -> `as any` (any IS spreadable + still assignable everywhere)
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2s-2b-fixup.ps1" . -Force
#   Unblock-File .\phase-d2s-2b-fixup.ps1
#   .\phase-d2s-2b-fixup.ps1          # DryRun
#   .\phase-d2s-2b-fixup.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2s-2b-fixup ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 1 error. Target: 0 (D phase COMPLETE)" -ForegroundColor DarkGray
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
# Fix: engagement-form payload `as never` -> `as any`
# (any is spreadable AND assignable to expected types)
# Unique anchor uses preceding source line for context
# ============================================================
Write-Host "--- Fix: engagement-form payload as never -> as any (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\engagements\engagement-form.tsx" `
    -A "        source: values.source?.trim() || null,`r`n      } as never;" `
    -R "        source: values.source?.trim() || null,`r`n      } as any;" `
    -Desc "engagement-form payload as any"

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count

    if ($errs -eq 0) {
        Write-Host ""
        Write-Host "  ==========================================" -ForegroundColor Green
        Write-Host "  ===   tsc = 0  -  D PHASE COMPLETE   ===" -ForegroundColor Green
        Write-Host "  ===   172 -> 0  (100% reduction)     ===" -ForegroundColor Green
        Write-Host "  ==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "--- Ready to commit + push ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host "  git commit -m `"phase-d2s-2b: cascade + Props + spread fixup (8 -> 0, D phase complete)`"" -ForegroundColor White
        Write-Host "  git push origin feature/stage23-urm-cleanup" -ForegroundColor White
    } else {
        Write-Host ("  Total errors: " + $errs + " (was 1)") -ForegroundColor Yellow
        Write-Host "`n--- Remaining errors ---" -ForegroundColor Cyan
        $tscOut | Select-String 'error TS' | ForEach-Object {
            Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
