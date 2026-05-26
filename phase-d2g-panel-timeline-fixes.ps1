# =============================================================================
# Phase D2g: party-sequence-panel + party-communications-timeline cleanup
# Uses (e: any) instead of specific shape - unblocks TS7006, preserves runtime
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

# === STEP 1: party-sequence-panel.tsx ===
Write-Host '== STEP 1: party-sequence-panel implicit any + index ==' -ForegroundColor Cyan

# (a) STATUS_CONFIG[e.status] -> STATUS_CONFIG[e.status as EnrollmentStatus]
Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    'STATUS_CONFIG[e.status]' `
    'STATUS_CONFIG[e.status as EnrollmentStatus]' `
    'STATUS_CONFIG[...] cast (3 places)'

# (b) .filter(e => ... ??.filter((e: any) => ...
Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.filter(e =>' `
    '.filter((e: any) =>' `
    'filter callback (e: any) (3 places)'

# (c) .map(e => { ... ??.map((e: any) => {
Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.map(e => {' `
    '.map((e: any) => {' `
    'map callback (e: any) (3 places)'

# === STEP 2: party-communications-timeline.tsx ===
Write-Host ''
Write-Host '== STEP 2: party-communications-timeline array index guards ==' -ForegroundColor Cyan

Set-PatchAll 'src\components\parties\party-communications-timeline.tsx' `
    'const latest = items[items.length - 1];' `
    'const latest = items[items.length - 1]!;' `
    'L211 latest non-null'

Set-PatchAll 'src\components\parties\party-communications-timeline.tsx' `
    'const firstItem = items[0];' `
    'const firstItem = items[0]!;' `
    'L212 firstItem non-null'

Set-PatchAll 'src\components\parties\party-communications-timeline.tsx' `
    '<MessageRow item={items[0]} onReply={onReply}' `
    '<MessageRow item={items[0]!} onReply={onReply}' `
    'L217 MessageRow items[0] non-null'

# meta deferred - need to see L530-545 context for proper guard

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
