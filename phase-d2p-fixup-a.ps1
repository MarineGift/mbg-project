# phase-d2p-fixup-a.ps1
# Phase: D2p-fixup-A (after D2p-final exposed real type bugs)
# Strategy:
#   - Apply 3 high-confidence fixes (party.ts L86, L222, L283)
#   - Diagnose remaining unclear targets (L336, pipeline L50, L81)
#   - Baseline: 76 errors. Target after this patch: 73 (-3). Diagnostic prepares D2p-fixup-B.
#
# Usage:
#   DryRun: .\phase-d2p-fixup-a.ps1
#   Apply : .\phase-d2p-fixup-a.ps1 -Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2p-fixup-A ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 76 errors. Target after Fixup-A: 73 (-3 LOW)" -ForegroundColor DarkGray
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
$pipeline = "src\lib\actions\pipeline-stages.ts"

# ============================================================
# Phase 0: Diagnostic — exact line text for remaining targets
# ============================================================
Write-Host "--- Diagnostic: exact text at uncertain error lines ---" -ForegroundColor Cyan

if (Test-Path -LiteralPath $party) {
    $L = Get-Content -LiteralPath $party
    Write-Host "  [party.ts L336 context, L332-340]:" -ForegroundColor White
    for ($i = 331; $i -le 339; $i++) {
        if ($i -lt $L.Count) {
            $marker = if ($i -eq 335) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $L[$i]) -ForegroundColor DarkGray
        }
    }
}

if (Test-Path -LiteralPath $pipeline) {
    $L = Get-Content -LiteralPath $pipeline
    Write-Host "  [pipeline-stages.ts L46-54, around L50]:" -ForegroundColor White
    for ($i = 45; $i -le 53; $i++) {
        if ($i -lt $L.Count) {
            $marker = if ($i -eq 49) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $L[$i]) -ForegroundColor DarkGray
        }
    }
    Write-Host "  [pipeline-stages.ts L77-85, around L81]:" -ForegroundColor White
    for ($i = 76; $i -le 84; $i++) {
        if ($i -lt $L.Count) {
            $marker = if ($i -eq 80) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $L[$i]) -ForegroundColor DarkGray
        }
    }
    Write-Host "  [pipeline-stages.ts L28-38, around L32-34]:" -ForegroundColor White
    for ($i = 27; $i -le 37; $i++) {
        if ($i -lt $L.Count) {
            $marker = if ($i -eq 31 -or $i -eq 33) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $L[$i]) -ForegroundColor DarkGray
        }
    }
}

# ============================================================
# Phase 1: party.ts L86 — fallback 'company' -> 'partner'
# Anchor: globally unique substring
# ============================================================
Write-Host "`n--- Fix 1: party.ts L86 — input.party_type fallback 'company' -> 'partner' ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "input.party_type ?? 'company'" `
    -R "input.party_type ?? 'partner'" `
    -Desc "party.ts L86 fallback (default partner)"

# ============================================================
# Phase 2: party.ts L222 — paper_mill insert (mill_name context, narrower indent)
# Anchor from D2p-final context: '      party_type:             ' (13 spaces after colon)
# ============================================================
Write-Host "`n--- Fix 2: party.ts L222 — paper_mill insert 'company' -> 'paper_mill' ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      party_type:             'company'," `
    -R "      party_type:             'paper_mill'," `
    -Desc "party.ts L222 mill insert party_type"

# ============================================================
# Phase 3: party.ts L283 — paper_mill insert (customer/tier context, wider indent)
# Anchor from D2p-final context: '      party_type:                ' (16 spaces after colon)
# ============================================================
Write-Host "`n--- Fix 3: party.ts L283 — paper_mill insert 'company' -> 'paper_mill' ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      party_type:                'company'," `
    -R "      party_type:                'paper_mill'," `
    -Desc "party.ts L283 mill insert party_type"

# ============================================================
# Phase 4: Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 76 - $errs

    Write-Host ("  Errors: " + $errs + " (was 76, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 76) { "Green" } elseif ($errs -eq 76) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Remaining errors in target files ---" -ForegroundColor Cyan
    $tscOut | Select-String 'src/app/actions/party.ts|pipeline-stages' | ForEach-Object {
        Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
