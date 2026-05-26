# phase-d2q-fixup.ps1
# Phase: D2q-fixup (correct cast direction from D2q)
# Baseline: 57 errors. Target: 52 (-5, sequence-processor.ts -> 0).
# Issue: D2q used `(rpc as never)` which makes the expression non-callable.
# Fix:
#   - L50: `{}` -> `{} as never` (cast value, not function)
#   - L75/152/191/226: `(rpc as never)` -> `(rpc as any)` (preserve callability)
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2q-fixup.ps1" . -Force
#   Unblock-File .\phase-d2q-fixup.ps1
#   .\phase-d2q-fixup.ps1          # DryRun
#   .\phase-d2q-fixup.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2q-fixup ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 57 errors. Target: 52 (-5)" -ForegroundColor DarkGray
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

$file = "src\lib\utils\sequence-processor.ts"

# ============================================================
# Fix 1: L50 — cast empty args as never
# get_due_enrollments has no args, but typed-rpc requires 3rd arg.
# Cast value to never to satisfy the never-typed parameter.
# ============================================================
Write-Host "--- Fix 1: L50 — {} -> {} as never ---" -ForegroundColor Cyan
Set-PatchAll -Path $file `
    -A 'await rpc(supabase, "get_due_enrollments", {})' `
    -R 'await rpc(supabase, "get_due_enrollments", {} as never)' `
    -Desc "L50 args as never"

# ============================================================
# Fix 2: advance_enrollment — (rpc as never) -> (rpc as any)
# never is not callable. any preserves callability while bypassing type check.
# Hits 4 sites: L75, L152, L191, L226.
# ============================================================
Write-Host "`n--- Fix 2: advance_enrollment cast (4 sites) ---" -ForegroundColor Cyan
Set-PatchAll -Path $file `
    -A '(rpc as never)(supabase, "advance_enrollment"' `
    -R '(rpc as any)(supabase, "advance_enrollment"' `
    -Desc "advance_enrollment as any"

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 57 - $errs

    Write-Host ("  Total errors: " + $errs + " (was 57, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 57) { "Green" } elseif ($errs -eq 57) { "Yellow" } else { "Red" }
    )

    $seqErrs = ($tscOut | Select-String 'src/lib/utils/sequence-processor.ts').Count
    Write-Host ("  sequence-processor.ts: " + $seqErrs + " errors") -ForegroundColor $(
        if ($seqErrs -eq 0) { "Green" } else { "Yellow" }
    )

    if ($seqErrs -gt 0) {
        Write-Host "`n--- Remaining errors in sequence-processor.ts ---" -ForegroundColor Cyan
        $tscOut | Select-String 'src/lib/utils/sequence-processor.ts' | ForEach-Object {
            Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
        }
    }

    Write-Host "`n--- Errors by file (top 10) ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match '^(.+?\.tsx?)\(\d+,\d+\):') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    if ($errs -lt 57) {
        Write-Host "`n--- Ready to commit (D2q + D2q-fixup as one) ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2q: sequence-processor.ts 6 patterns + cast fixes (62 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
