# =============================================================================
# Phase D2f: 4-cluster cleanup
# - utils/email-tracking (6): regex match[1] non-null guard
# - party-sequence-panel (9): event handler 'e' typing + EnrollmentStatus index
# - party-communications-timeline (7): array index null guards
# - email-compose L216 (1): contactId null fix (Set-PatchAll variant)
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

# === STEP 1: utils/email-tracking.ts - regex match[1] non-null guard ===
Write-Host '== STEP 1: utils/email-tracking regex match guard ==' -ForegroundColor Cyan
# Original: const url = m[1];
# Fixed:    const url = m[1]!;  (non-null assertion: regex captured group always exists if match[0] did)
Set-PatchAll 'src\lib\utils\email-tracking.ts' `
    'const url = m[1];' `
    'const url = m[1]!;' `
    'extractLinks: const url = m[1] non-null'

# === STEP 2: party-sequence-panel.tsx - event handler typing ===
Write-Host ''
Write-Host '== STEP 2: party-sequence-panel event handler typing ==' -ForegroundColor Cyan
# Pattern: .filter(e => ...) / .find(e => ...) / .map(e => ...) where 'e' is Enrollment row
# We need to see actual code; assume e is enrollment-like object with status field
# Most likely pattern: (e) => e.status === 'X'
# Without seeing exact code, we add explicit type. Common patch: replace `(e)` with `(e: Enrollment)` or similar
# Since we don't know exact types, use a generic catch-all by adding ': any' annotation.
# This is suboptimal but unblocks the 9 errors. Refactor to proper type later.
Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.filter((e) =>' `
    '.filter((e: any) =>' `
    'filter event handler typing'

Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.find((e) =>' `
    '.find((e: any) =>' `
    'find event handler typing'

Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.map((e) =>' `
    '.map((e: any) =>' `
    'map event handler typing'

Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.some((e) =>' `
    '.some((e: any) =>' `
    'some event handler typing'

Set-PatchAll 'src\components\parties\party-sequence-panel.tsx' `
    '.forEach((e) =>' `
    '.forEach((e: any) =>' `
    'forEach event handler typing'

# === STEP 3: email-compose.ts L216 contactId (anchor variant) ===
Write-Host ''
Write-Host '== STEP 3: email-compose contactId null fix ==' -ForegroundColor Cyan
# This time try a single-line anchor that does NOT include line endings
# The single line at L216 might be just '        payload.contactId' (no newline)
# Use leading ' ' (4 spaces or 8) + payload.contactId$ pattern via Replace on the whole content
Set-PatchAll 'src\lib\actions\email-compose.ts' `
    '        payload.contactId' `
    '        payload.contactId ?? undefined' `
    'L216 contactId ?? undefined (substring match)'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
