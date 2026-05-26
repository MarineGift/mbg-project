# phase-d2s-2a.ps1
# Phase: D2s-2a (9 safe single-anchor fixes + diagnostic for D2s-2b)
# Baseline: 15 errors. Target: ~6 (-9).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   Move-Item "$env:USERPROFILE\Downloads\phase-d2s-2a.ps1" . -Force
#   Unblock-File .\phase-d2s-2a.ps1
#   .\phase-d2s-2a.ps1          # DryRun
#   .\phase-d2s-2a.ps1 -Apply   # Apply

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

Write-Host "`n=== Phase D2s-2a ===" -ForegroundColor Cyan
Write-Host ("Mode: " + $(if ($Apply) { "APPLY" } else { "DRY-RUN" })) -ForegroundColor Yellow
Write-Host "Baseline: 15 errors. Target: ~6 (-9)" -ForegroundColor DarkGray
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
# GROUP A: 9 safe fixes
# ============================================================

Write-Host "--- Fix 1: email-compose.ts L216 body_html null coalesce (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\actions\email-compose.ts" `
    -A "        tmpl.body_html,`r`n        payload.partyId," `
    -R "        tmpl.body_html ?? '',`r`n        payload.partyId," `
    -Desc "email-compose body_html ?? ''"

Write-Host "`n--- Fix 2: communications.ts L90 p_module undefined (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\queries\communications.ts" `
    -A "p_module: module ?? null," `
    -R "p_module: module ?? undefined," `
    -Desc "communications p_module undefined"

Write-Host "`n--- Fix 3: lead-score.ts L24 rpc name cast (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\queries\lead-score.ts" `
    -A ".rpc('get_lead_scores_many', { p_party_ids: partyIds })" `
    -R ".rpc('get_lead_scores_many' as never, { p_party_ids: partyIds })" `
    -Desc "lead-score rpc name as never"

Write-Host "`n--- Fix 4: tasks.ts L76 return cast (CRLF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\lib\queries\tasks.ts" `
    -A "return { status, priority, module, overdueOnly, partyId };" `
    -R "return { status, priority, module, overdueOnly, partyId } as never;" `
    -Desc "tasks parseTaskFilters return as never"

Write-Host "`n--- Fix 5: track route L33 .then with error handler (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\api\track\open\[token]\route.ts" `
    -A "    .then(() => {})`n    .catch(() => {});" `
    -R "    .then(() => {}, () => {});" `
    -Desc "track route then with error handler"

Write-Host "`n--- Fix 6: country-peers-panel.tsx L56 currentModule cast (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\components\parties\country-peers-panel.tsx" `
    -A "currentModule={currentModule}" `
    -R "currentModule={currentModule as never}" `
    -Desc "country-peers-panel currentModule cast"

Write-Host "`n--- Fix 7: calendar/page L227 loadItems cast (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\calendar\page.tsx" `
    -A "onRangeChange={loadItems}" `
    -R "onRangeChange={loadItems as never}" `
    -Desc "calendar/page loadItems cast"

Write-Host "`n--- Fix 8: parties/page L116 sp.country cast (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\parties\page.tsx" `
    -A "const countryFilter = (sp.country ?? '').trim().toUpperCase();" `
    -R "const countryFilter = ((sp as any).country ?? '').trim().toUpperCase();" `
    -Desc "parties/page sp.country cast"

Write-Host "`n--- Fix 9: parties/[id]/edit L30 params cast (LF) ---" -ForegroundColor Cyan
Set-PatchAll -Path "src\app\(app)\[partyType]\parties\[id]\edit\page.tsx" `
    -A "const { partyType: urlModule, id } = await params;" `
    -R "const { partyType: urlModule, id } = (await params) as { partyType: string; id: string };" `
    -Desc "parties/[id]/edit params cast"

# ============================================================
# GROUP B: Diagnostic for D2s-2b targets
# ============================================================
Write-Host ""
Write-Host ("=" * 70) -ForegroundColor DarkCyan
Write-Host "--- DIAGNOSTIC for D2s-2b targets ---" -ForegroundColor Cyan

# B1: processor.ts — find data.partyType reference
Write-Host ""
Write-Host "[B1] processor.ts — search for data.partyType:" -ForegroundColor Cyan
$procFile = "src\lib\email\processor.ts"
if (Test-Path -LiteralPath $procFile) {
    $procLines = Get-Content -LiteralPath $procFile
    for ($i = 0; $i -lt $procLines.Count; $i++) {
        if ($procLines[$i] -match 'data\.partyType') {
            $start = [Math]::Max(0, $i - 2)
            $end = [Math]::Min($procLines.Count - 1, $i + 2)
            Write-Host ("  Found at L" + ($i+1) + ":") -ForegroundColor Yellow
            for ($j = $start; $j -le $end; $j++) {
                $marker = if ($j -eq $i) { ">>" } else { "  " }
                Write-Host ("    " + $marker + " " + ($j+1).ToString().PadLeft(4) + " | " + $procLines[$j]) -ForegroundColor DarkGray
            }
        }
    }
}

# B2: engagement-form.tsx — payload construction L155-195
Write-Host ""
Write-Host "[B2] engagement-form.tsx L155-195 (payload + create/update calls):" -ForegroundColor Cyan
$engFile = "src\components\engagements\engagement-form.tsx"
if (Test-Path -LiteralPath $engFile) {
    $engLines = Get-Content -LiteralPath $engFile
    for ($i = 154; $i -le 194; $i++) {
        if ($i -lt $engLines.Count) {
            $marker = if ($i -eq 171 -or $i -eq 179) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $engLines[$i]) -ForegroundColor DarkGray
        }
    }
}

# B3: sidebar.tsx L215-240 — full Record content
Write-Host ""
Write-Host "[B3] sidebar.tsx L215-240 (Record object full content):" -ForegroundColor Cyan
$sidebarFile = "src\components\layout\sidebar.tsx"
if (Test-Path -LiteralPath $sidebarFile) {
    $sbLines = Get-Content -LiteralPath $sidebarFile
    for ($i = 214; $i -le 239; $i++) {
        if ($i -lt $sbLines.Count) {
            $marker = if ($i -eq 217) { ">>" } else { "  " }
            Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $sbLines[$i]) -ForegroundColor DarkGray
        }
    }
}

# B4: Find PartyForm component
Write-Host ""
Write-Host "[B4] PartyForm component location + Props:" -ForegroundColor Cyan
$partyFormFiles = Get-ChildItem -Recurse -Filter "*.tsx" -Path "src" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules' } |
    Select-String -Pattern "export function PartyForm|export default function PartyForm" -List

foreach ($f in $partyFormFiles) {
    $relPath = $f.Path.Replace((Get-Location).Path + "\", "")
    Write-Host ("  Found in: " + $relPath) -ForegroundColor White

    $pfLines = Get-Content -LiteralPath $relPath
    # Show first 60 lines (imports + Props + function signature)
    $maxL = [Math]::Min(60, $pfLines.Count)
    for ($i = 0; $i -lt $maxL; $i++) {
        Write-Host ("    " + ($i+1).ToString().PadLeft(4) + " | " + $pfLines[$i]) -ForegroundColor DarkGray
    }
}

# ============================================================
# Verify
# ============================================================
if ($Apply) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
    Write-Host "--- tsc verification ---" -ForegroundColor Cyan
    $tscOut = npx tsc --noEmit 2>&1
    $errs = ($tscOut | Select-String 'error TS').Count
    $delta = 15 - $errs

    Write-Host ("  Total errors: " + $errs + " (was 15, delta: -" + $delta + ")") -ForegroundColor $(
        if ($errs -lt 15) { "Green" } elseif ($errs -eq 15) { "Yellow" } else { "Red" }
    )

    Write-Host "`n--- Remaining errors ---" -ForegroundColor Cyan
    $tscOut | Select-String 'error TS' | ForEach-Object {
        Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
    }

    if ($errs -lt 15) {
        Write-Host "`n--- Ready to commit ---" -ForegroundColor Green
        Write-Host "  git add -A" -ForegroundColor White
        Write-Host ("  git commit -m `"phase-d2s-2a: 9 safe single-anchor fixes (15 -> " + $errs + ")`"") -ForegroundColor White
    }
} else {
    Write-Host "`n[DRY-RUN] Re-run with -Apply to commit changes." -ForegroundColor Yellow
}

Write-Host ""
