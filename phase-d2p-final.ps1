# phase-d2p-final.ps1
# Target: actions/party.ts (4 errors) + pipeline-stages.ts (3 errors) = 7 errors
# Root cause: .schema('app' as never) cast breaks insert/update typing -> never[] / never
# Strategy: Remove `as never` cast. If `.schema('app')` typing still fails, fallback to payload cast.
#
# Usage:
#   DryRun (default):  .\phase-d2p-final.ps1
#   Apply:             .\phase-d2p-final.ps1 -Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2p-final ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host ("Baseline: 69 errors (target: ~62 after D2p-final)") -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# Helper (Korean-safe, LF-aware)
# ============================================================
function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("  [MISS] " + $Path) -ForegroundColor DarkGray
        return $false
    }
    $c = [System.IO.File]::ReadAllText($Path)
    $count = ([regex]::Matches($c, [regex]::Escape($A))).Count
    if ($count -eq 0) {
        Write-Host ("  [SKIP] " + $Desc) -ForegroundColor DarkYellow
        return $false
    }
    Write-Host ("  [OK x" + $count + "] " + $Desc) -ForegroundColor Green
    if ($Apply) {
        $new = $c.Replace($A, $R)
        [System.IO.File]::WriteAllText($Path, $new, (New-Object System.Text.UTF8Encoding($false)))
    }
    return $true
}

# ============================================================
# Phase 0: Diagnostic — show what we're working with
# ============================================================
Write-Host "--- Diagnostic: pattern occurrence counts ---" -ForegroundColor Cyan

$party = "src\app\actions\party.ts"
$pipeline = "src\lib\actions\pipeline-stages.ts"

foreach ($f in @($party, $pipeline)) {
    if (Test-Path -LiteralPath $f) {
        $content = [System.IO.File]::ReadAllText($f)

        $schemaAsNever = ([regex]::Matches($content, [regex]::Escape(".schema('app' as never)"))).Count
        $schemaPlain   = ([regex]::Matches($content, [regex]::Escape(".schema('app')"))).Count
        $schemaDouble  = ([regex]::Matches($content, [regex]::Escape('.schema("app" as never)'))).Count

        Write-Host ("  " + $f) -ForegroundColor White
        Write-Host ("    .schema('app' as never): " + $schemaAsNever) -ForegroundColor Gray
        Write-Host ("    .schema(`"app`" as never): " + $schemaDouble) -ForegroundColor Gray
        Write-Host ("    .schema('app') (already clean): " + $schemaPlain) -ForegroundColor Gray
    } else {
        Write-Host ("  [MISS] " + $f) -ForegroundColor Red
    }
}

# ============================================================
# Phase 1: Context preview (error lines)
# ============================================================
Write-Host "`n--- Context: party.ts error lines ---" -ForegroundColor Cyan
if (Test-Path -LiteralPath $party) {
    $lines = Get-Content -LiteralPath $party
    foreach ($n in @(86, 148, 222, 283)) {
        $start = [Math]::Max(1, $n - 3)
        $end   = [Math]::Min($lines.Count, $n + 3)
        Write-Host ("  L" + $start + "-" + $end + " (around L" + $n + "):") -ForegroundColor DarkYellow
        for ($i = $start; $i -le $end; $i++) {
            $marker = if ($i -eq $n) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + $i.ToString().PadLeft(4) + " | " + $lines[$i-1]) -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n--- Context: pipeline-stages.ts error lines ---" -ForegroundColor Cyan
if (Test-Path -LiteralPath $pipeline) {
    $lines = Get-Content -LiteralPath $pipeline
    foreach ($n in @(45, 77, 109)) {
        $start = [Math]::Max(1, $n - 3)
        $end   = [Math]::Min($lines.Count, $n + 3)
        Write-Host ("  L" + $start + "-" + $end + " (around L" + $n + "):") -ForegroundColor DarkYellow
        for ($i = $start; $i -le $end; $i++) {
            $marker = if ($i -eq $n) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + $i.ToString().PadLeft(4) + " | " + $lines[$i-1]) -ForegroundColor DarkGray
        }
    }
}

# ============================================================
# Phase 2: Apply the patch (remove `as never` from .schema calls)
# ============================================================
Write-Host "`n--- Patch 1: .schema('app' as never) -> .schema('app') ---" -ForegroundColor Cyan
$p1a = Set-PatchAll -Path $party    -A ".schema('app' as never)" -R ".schema('app')" -Desc "party.ts: remove as never cast"
$p1b = Set-PatchAll -Path $pipeline -A ".schema('app' as never)" -R ".schema('app')" -Desc "pipeline-stages.ts: remove as never cast"

Write-Host "`n--- Patch 2 (double-quote variant, just in case): .schema(`"app`" as never) -> .schema(`"app`") ---" -ForegroundColor Cyan
$p2a = Set-PatchAll -Path $party    -A '.schema("app" as never)' -R '.schema("app")' -Desc "party.ts: double-quote variant"
$p2b = Set-PatchAll -Path $pipeline -A '.schema("app" as never)' -R '.schema("app")' -Desc "pipeline-stages.ts: double-quote variant"

# ============================================================
# Phase 3: Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 69 - $errs

    Write-Host ("  Errors: " + $errs + " (was 69, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 69) { "Green" } elseif ($errs -eq 69) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Remaining errors in target files ---" -ForegroundColor Cyan
    $tscOut | Select-String 'src/app/actions/party.ts|pipeline-stages' | ForEach-Object {
        Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
    }

    if ($errs -lt 69) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2p-final: actions/party + pipeline-stages remove .schema as never cast (-" + $delta + ")`"") -ForegroundColor White
    } else {
        Write-Host "`n[WARN] No reduction. .schema cast removal alone is insufficient." -ForegroundColor Red
        Write-Host "       Fallback: revert and try payload-cast approach (.insert(payload as never))." -ForegroundColor Red
        Write-Host "       To revert: git checkout -- " $party $pipeline -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] No files modified. Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
