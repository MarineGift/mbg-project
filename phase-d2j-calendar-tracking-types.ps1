# =============================================================================
# Phase D2j: calendar/sync-engine conn guard + EmailTracking type redefine
# - calendar L256 conn declaration: non-null at source (4 cascading errors)
# - phase21.ts EmailTracking: redefine to Database Row (4 errors via type compat)
# DryRun by default. Set $Apply = $true at top to apply.
# =============================================================================

$ErrorActionPreference = 'Stop'
$Apply = $true

function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("  [MISS] " + $Path) -ForegroundColor DarkGray
        return
    }
    $c = [System.IO.File]::ReadAllText($Path)
    $count = ([regex]::Matches($c, [regex]::Escape($A))).Count
    if ($count -eq 0) {
        Write-Host ("  [SKIP] " + $Desc) -ForegroundColor DarkYellow
        return
    }
    Write-Host ("  [OK x" + $count + "] " + $Desc) -ForegroundColor Green
    if ($Apply) {
        $new = $c.Replace($A, $R)
        [System.IO.File]::WriteAllText($Path, $new, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# === STEP 1: calendar/sync-engine conn non-null at source ===
Write-Host '== STEP 1: calendar/sync-engine conn non-null ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\calendar\sync-engine.ts' `
    "    const conn = connections[i]" `
    "    const conn = connections[i]!" `
    'L256 conn non-null (eliminates 4 cascade errors)'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
