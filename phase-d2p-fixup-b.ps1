# phase-d2p-fixup-b.ps1
# Phase: D2p-fixup-B (10 well-defined fixes from D2p-fixup-A diagnostic)
# Baseline: 78 errors. Target: 68 (-10).
# Excludes (handled in fixup-C): L148, L225, L231, L286, L290 (need wider view).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2p-fixup-b.ps1" . -Force
#   Unblock-File .\phase-d2p-fixup-b.ps1
#   .\phase-d2p-fixup-b.ps1          # DryRun
#   .\phase-d2p-fixup-b.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2p-fixup-B ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 78 errors. Target: 68 (-10)" -ForegroundColor DarkGray
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
# Phase 0: Diagnostic — show insert blocks at L215-235 and L275-295
# (for fixup-C planning — never-type fields L225/L231/L286/L290)
# ============================================================
Write-Host "--- Diagnostic: insert block contexts (for fixup-C) ---" -ForegroundColor Cyan

if (Test-Path -LiteralPath $party) {
    $L = Get-Content -LiteralPath $party
    Write-Host "  [party.ts mill insert block L213-238]:" -ForegroundColor White
    for ($i = 212; $i -le 237; $i++) {
        if ($i -lt $L.Count) {
            $line = $L[$i]
            $marker = if ($i -eq 224 -or $i -eq 230) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $line) -ForegroundColor DarkGray
        }
    }
    Write-Host "  [party.ts customer insert block L273-298]:" -ForegroundColor White
    for ($i = 272; $i -le 297; $i++) {
        if ($i -lt $L.Count) {
            $line = $L[$i]
            $marker = if ($i -eq 285 -or $i -eq 289) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $line) -ForegroundColor DarkGray
        }
    }
    Write-Host "  [party.ts L143-152 context for L148 update]:" -ForegroundColor White
    for ($i = 142; $i -le 151; $i++) {
        if ($i -lt $L.Count) {
            $line = $L[$i]
            $marker = if ($i -eq 147) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $line) -ForegroundColor DarkGray
        }
    }
}

# ============================================================
# Phase 1: party.ts L89 — PartyType union cast
# ============================================================
Write-Host "`n--- Fix 1: party.ts L89 — wrap fallback with as never cast ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "input.party_type ?? 'partner'" `
    -R "(input.party_type ?? 'partner') as never" `
    -Desc "party.ts L89 PartyType cast"

# ============================================================
# Phase 2: party.ts L171, L311 — industry_paper_mill_id column cast
# ============================================================
Write-Host "`n--- Fix 2: party.ts industry_paper_mill_id cast (L171, L311) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "'industry_paper_mill_id'" `
    -R "'industry_paper_mill_id' as never" `
    -Desc "party.ts industry_paper_mill_id cast"

# ============================================================
# Phase 3: party.ts L206, L255, L322 — industry_paper_company_id column cast
# ============================================================
Write-Host "`n--- Fix 3: party.ts industry_paper_company_id cast (L206, L255, L322) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "'industry_paper_company_id'" `
    -R "'industry_paper_company_id' as never" `
    -Desc "party.ts industry_paper_company_id cast"

# ============================================================
# Phase 4: party.ts L336 — result conversion via unknown
# ============================================================
Write-Host "`n--- Fix 4: party.ts L336 — result conversion via unknown ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "(data ?? []) as Array<{" `
    -R "(data ?? []) as unknown as Array<{" `
    -Desc "party.ts L336 result conversion"

# ============================================================
# Phase 5: pipeline-stages.ts L32-34 — .from('pipeline_definitions') cast
# ============================================================
Write-Host "`n--- Fix 5: pipeline-stages.ts L32-34 — pipeline_definitions table cast ---" -ForegroundColor Cyan
Set-PatchAll -Path $pipeline `
    -A ".from('pipeline_definitions')" `
    -R ".from('pipeline_definitions' as never)" `
    -Desc "pipeline-stages.ts pipeline_definitions cast"

# ============================================================
# Phase 6: pipeline-stages.ts L50, L81 — stage_type enum cast
# ============================================================
Write-Host "`n--- Fix 6: pipeline-stages.ts L50, L81 — stage_type cast ---" -ForegroundColor Cyan
Set-PatchAll -Path $pipeline `
    -A "stage_type: input.stage_type," `
    -R "stage_type: input.stage_type as never," `
    -Desc "pipeline-stages.ts stage_type cast"

# ============================================================
# Phase 7: Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 78 - $errs

    Write-Host ("  Errors: " + $errs + " (was 78, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 78) { "Green" } elseif ($errs -eq 78) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Remaining errors in target files ---" -ForegroundColor Cyan
    $tscOut | Select-String 'src/app/actions/party.ts|pipeline-stages' | ForEach-Object {
        Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
    }

    if ($errs -lt 78) {
        Write-Host "`n--- Ready to commit (D2p + fixup-A + fixup-B as one) ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2p: remove .schema as never + surfaced type fixes (78 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
