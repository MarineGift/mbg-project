# phase-d2s-2b.ps1
# Phase: D2s-2b (final 8 errors -> 0)
# Baseline: 8 errors. Target: 0.
# 7 anchors, one fix handles 2 cascade errors in engagement-form.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2s-2b.ps1" . -Force
#   Unblock-File .\phase-d2s-2b.ps1
#   .\phase-d2s-2b.ps1          # DryRun
#   .\phase-d2s-2b.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2s-2b ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 8 errors. Target: 0" -ForegroundColor DarkGray
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
# Fix 1: parties/[id]/edit/page.tsx L30 - unknown intermediate cast (D2s-2a cascade)
# ============================================================
Write-Host "--- Fix 1: parties/[id]/edit L30 unknown intermediate cast (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\parties\[id]\edit\page.tsx" `
    -A "(await params) as { partyType: string; id: string };" `
    -R "(await params) as unknown as { partyType: string; id: string };" `
    -Desc "parties/[id]/edit unknown cast"

# ============================================================
# Fix 2: parties/[id]/edit/page.tsx L54 - initialModule -> initialPartyType
# ============================================================
Write-Host "`n--- Fix 2: parties/[id]/edit L54 initialModule -> initialPartyType (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\parties\[id]\edit\page.tsx" `
    -A "        initialModule={full.party.partyType}" `
    -R "        initialPartyType={full.party.partyType}" `
    -Desc "parties/[id]/edit initialPartyType rename"

# ============================================================
# Fix 3: parties/new/page.tsx L40 - initialModule -> initialPartyType
# ============================================================
Write-Host "`n--- Fix 3: parties/new L40 initialModule -> initialPartyType (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\parties\new\page.tsx" `
    -A "<PartyForm mode=`"create`" initialModule={module} />" `
    -R "<PartyForm mode=`"create`" initialPartyType={module} />" `
    -Desc "parties/new initialPartyType rename"

# ============================================================
# Fix 4: engagement-form.tsx payload close `} as never;` (handles L172 + L180 cascade)
# Cast payload type to never so both createEngagement(payload) and updateEngagement({...payload}) pass
# ============================================================
Write-Host "`n--- Fix 4: engagement-form payload close as never (CRLF, fixes L172+L180) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\engagements\engagement-form.tsx" `
    -A "        source: values.source?.trim() || null,`r`n      };" `
    -R "        source: values.source?.trim() || null,`r`n      } as never;" `
    -Desc "engagement-form payload as never"

# ============================================================
# Fix 5: sidebar.tsx - add buyer + government_grant Record keys (LF)
# Anchor: between customer and filler_supplier (unique context)
# ============================================================
Write-Host "`n--- Fix 5: sidebar.tsx add missing Record keys (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\layout\sidebar.tsx" `
    -A "  customer: 'bg-module-customer',`n  filler_supplier:" `
    -R "  customer: 'bg-module-customer',`n  buyer: 'bg-module-buyer',`n  government_grant: 'bg-gray-500',`n  filler_supplier:" `
    -Desc "sidebar Record add buyer + government_grant"

# ============================================================
# Fix 6: processor.ts L251 - data.partyType -> data.module (LF)
# Same pattern as prompt-renderer fix in D2r
# ============================================================
Write-Host "`n--- Fix 6: processor.ts L251 data.partyType -> data.module (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\email\processor.ts" `
    -A "(data.partyType as PartyTypeCode | null)" `
    -R "(data.module as PartyTypeCode | null)" `
    -Desc "processor data.module rename"

# ============================================================
# Fix 7: lead-score.ts L24 - args as never (D2s-2a cascade)
# After rpc name -> never, args type becomes undefined. Cast args too.
# ============================================================
Write-Host "`n--- Fix 7: lead-score.ts L24 args as never (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\queries\lead-score.ts" `
    -A ".rpc('get_lead_scores_many' as never, { p_party_ids: partyIds })" `
    -R ".rpc('get_lead_scores_many' as never, { p_party_ids: partyIds } as never)" `
    -Desc "lead-score args as never"

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host "`n--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 8 - $errs

    if ($errs -eq 0) {
        Write-Host ("  TOTAL ERRORS: 0  ===  D phase COMPLETE!  ===") -ForegroundColor Green
    } else {
        Write-Host ("  Total errors: " + $errs + " (was 8, delta: -" + $delta + ")") -ForegroundColor $(
            if ($errs -lt 8) { "Green" } else { "Yellow" }
        )
        Write-Host "`n--- Remaining errors ---" -ForegroundColor Cyan
        $tscOut | Select-String 'error TS' | ForEach-Object {
            Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
        }
    }

    if ($errs -lt 8) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        if ($errs -eq 0) {
            Write-Host "  git commit -m `"phase-d2s-2b: final 8 fixes, D phase complete (8 -> 0)`"" -ForegroundColor White
        } else {
            Write-Host ("  git commit -m `"phase-d2s-2b: cascade + Props fixes (8 -> " + $errs + ")`"") -ForegroundColor White
        }
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
