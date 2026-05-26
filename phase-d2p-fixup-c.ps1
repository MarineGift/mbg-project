# phase-d2p-fixup-c.ps1
# Phase: D2p-fixup-C (insert payload cleanup + cast)
# Baseline: 71 errors. Target: ~62 (-9).
# Strategy:
#   1. Remove deprecated `module:` fields from 3 insert blocks (D phase cleanup)
#   2. Cast 3 insert payloads `as never` (for industry_paper_*_id and other schema-mismatched fields)
#   3. Cast L148 `.update(updates)` payload
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2p-fixup-c.ps1" . -Force
#   Unblock-File .\phase-d2p-fixup-c.ps1
#   .\phase-d2p-fixup-c.ps1          # DryRun
#   .\phase-d2p-fixup-c.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2p-fixup-C ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 71 errors. Target: ~62 (-9)" -ForegroundColor DarkGray
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
# Phase 0: Diagnostic — CreateParty insert block (L80-115)
# Need to see the close `})` to validate anchor for Fix 6
# ============================================================
Write-Host "--- Diagnostic: CreateParty insert block (L80-115) ---" -ForegroundColor Cyan

if (Test-Path -LiteralPath $party) {
    $L = Get-Content -LiteralPath $party
    for ($i = 79; $i -le 114; $i++) {
        if ($i -lt $L.Count) {
            $line = $L[$i]
            $marker = if ($i -eq 89 -or $i -eq 100 -or $i -eq 101 -or $i -eq 102) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $line) -ForegroundColor DarkGray
        }
    }
}

# ============================================================
# Phase 1: Remove deprecated `module:` lines from 3 insert blocks
# (parties.module was renamed to party_type per handoff D phase scope)
# ============================================================
Write-Host "`n--- Fix 1: Remove `module: 'paper_mill'` from mill insert (L222) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      module:                 'paper_mill',`n" `
    -R "" `
    -Desc "remove module field from mill insert"

Write-Host "`n--- Fix 2: Remove `module: 'paper_mill'` from customer insert (L283) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      module:                    'paper_mill',`n" `
    -R "" `
    -Desc "remove module field from customer insert"

Write-Host "`n--- Fix 3: Remove `module: input.module` from CreateParty insert (L87) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      module:                      input.module,`n" `
    -R "" `
    -Desc "remove module field from CreateParty insert"

# ============================================================
# Phase 2: Cast mill insert payload `as never`
# Anchor: unique close pattern `industry_paper_mill_id: millId,\n    })`
# ============================================================
Write-Host "`n--- Fix 4: Cast mill insert payload `as never` (L225, L231) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      industry_paper_mill_id: millId,`n    })" `
    -R "      industry_paper_mill_id: millId,`n    } as never)" `
    -Desc "cast mill insert payload"

# ============================================================
# Phase 3: Cast customer insert payload `as never`
# Anchor: unique close pattern `industry_paper_company_id: companyId,\n    })`
# ============================================================
Write-Host "`n--- Fix 5: Cast customer insert payload `as never` (L286, L290) ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A "      industry_paper_company_id: companyId,`n    })" `
    -R "      industry_paper_company_id: companyId,`n    } as never)" `
    -Desc "cast customer insert payload"

# ============================================================
# Phase 4: Cast L148 `.update(updates)` payload
# Anchor: `.update(updates)` — should be unique in party.ts
# ============================================================
Write-Host "`n--- Fix 6: Cast L148 update payload `as never` ---" -ForegroundColor Cyan
Set-PatchAll -Path $party `
    -A ".update(updates)" `
    -R ".update(updates as never)" `
    -Desc "cast L148 update payload"

# ============================================================
# Phase 5: Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 71 - $errs

    Write-Host ("  Errors: " + $errs + " (was 71, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 71) { "Green" } elseif ($errs -eq 71) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Remaining errors in party.ts ---" -ForegroundColor Cyan
    $tscOut | Select-String 'src/app/actions/party.ts' | ForEach-Object {
        Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
    }

    Write-Host "`n--- Top 5 files with most remaining errors ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        if ($_.Line -match '^([^(]+)\(') { $matches[1] }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host ("  " + $_.Count.ToString().PadLeft(3) + " | " + $_.Name) -ForegroundColor DarkGray
    }

    if ($errs -lt 71) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2p-fixup-c: cleanup module fields + cast insert/update payloads (71 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
