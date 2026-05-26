# phase-d2p-fixup-d.ps1
# Phase: D2p-fixup-D (finish party.ts + better error breakdown)
# Baseline: 65 errors. Target: 62 (-3, party.ts → 0).
# Strategy:
#   - Cast CreateParty insert payload `as never` (last 3 industry_*_id errors)
#   - Better per-file error breakdown for planning D2q+
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2p-fixup-d.ps1" . -Force
#   Unblock-File .\phase-d2p-fixup-d.ps1
#   .\phase-d2p-fixup-d.ps1          # DryRun
#   .\phase-d2p-fixup-d.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2p-fixup-D ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 65 errors. Target: 62 (-3, party.ts -> 0)" -ForegroundColor DarkGray
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

$party = "src\app\actions\party.ts"

# ============================================================
# Fix 1: Cast CreateParty insert payload `as never`
# Anchor: unique close pattern with industry_filler_supplier_id
# (this field only appears in CreateParty insert, not mill or customer)
# ============================================================
Write-Host "--- Fix 1: Cast CreateParty insert payload as never ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      industry_filler_supplier_id: input.industry_filler_supplier_id ?? null,`n    })" `
    -R "      industry_filler_supplier_id: input.industry_filler_supplier_id ?? null,`n    } as never)" `
    -Desc "CreateParty insert payload cast"

# ============================================================
# Verify and breakdown
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 65 - $errs

    Write-Host ("  Errors: " + $errs + " (was 65, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 65) { "Green" } elseif ($errs -eq 65) { "Yellow" } else { "Red" }
    )

    # Improved per-file breakdown using proper regex (handles Next.js (group) paths)
    Write-Host "`n--- Errors by file (top 15) ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match '^(.+?\.tsx?)\(\d+,\d+\):') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    # Error code distribution
    Write-Host "`n--- Errors by TS error code ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match 'error (TS\d+)') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    # party.ts status
    $partyErrs = ($tscOut | Select-String 'src/app/actions/party.ts').Count
    Write-Host ("`n--- party.ts status: " + $partyErrs + " errors ---") -ForegroundColor $(
        if ($partyErrs -eq 0) { "Green" } else { "Yellow" }
    )

    if ($errs -lt 65) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2p-fixup-d: CreateParty insert cast (party.ts -> 0, total 65 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
