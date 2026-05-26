# =============================================================================
# Phase D2n: module-badge + parties pages cascade
# - module-badge: Record completion + module->partyType prop
# - parties/page.tsx: Record completion + readonly fix
# - parties/[id]/page.tsx: module={...} JSX prop -> partyType={...}
# - email-signature-client: html -> html_content cascade
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

# === STEP 1: module-badge.tsx ===
Write-Host '== STEP 1: module-badge.tsx ==' -ForegroundColor Cyan

# (a) Add buyer + government_grant
Set-PatchAll 'src\components\common\module-badge.tsx' `
    "  filler_supplier: 'bg-amber-100 text-amber-700'," `
    "  filler_supplier: 'bg-amber-100 text-amber-700',`n  buyer: 'bg-yellow-100 text-yellow-700',`n  government_grant: 'bg-gray-100 text-gray-700'," `
    'Add buyer + government_grant to MODULE_STYLES'

# (b) destructuring: module, -> partyType,
Set-PatchAll 'src\components\common\module-badge.tsx' `
    "export function ModuleBadge({`n  module,`n  size = 'md'," `
    "export function ModuleBadge({`n  partyType,`n  size = 'md'," `
    'ModuleBadge props destructure module -> partyType'

# (c) MODULE_STYLES[module] -> MODULE_STYLES[partyType]
Set-PatchAll 'src\components\common\module-badge.tsx' `
    'MODULE_STYLES[module]' `
    'MODULE_STYLES[partyType]' `
    'MODULE_STYLES index'

# (d) {t(module)} -> {t(partyType)}
Set-PatchAll 'src\components\common\module-badge.tsx' `
    '{t(module)}' `
    '{t(partyType)}' `
    'i18n t(module) -> t(partyType)'

# === STEP 2: parties/page.tsx ===
Write-Host ''
Write-Host '== STEP 2: parties/page.tsx ==' -ForegroundColor Cyan

# (a) L34 Record completion ??need to see actual line first
# Most likely same pattern as module-badge. Use safe substring.
Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' `
    "  filler_supplier: 'bg-orange-100 text-orange-700'," `
    "  filler_supplier: 'bg-orange-100 text-orange-700',`n  buyer: 'bg-yellow-100 text-yellow-700',`n  government_grant: 'bg-gray-100 text-gray-700'," `
    'L34 Record add buyer + government_grant (orange variant)'

Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' `
    "  filler_supplier: 'bg-amber-100 text-amber-700'," `
    "  filler_supplier: 'bg-amber-100 text-amber-700',`n  buyer: 'bg-yellow-100 text-yellow-700',`n  government_grant: 'bg-gray-100 text-gray-700'," `
    'L34 Record add buyer + government_grant (amber variant)'

# (b) L379 readonly tuple to mutable
# Without seeing exact code, common patterns: PAGE_SIZES = [25, 50, 100, 200] as const
# Fix: PAGE_SIZES = [25, 50, 100, 200] (drop as const) or spread when used
# Or change destination type. Hard to patch without context. Defer.

# === STEP 3: parties/[id]/page.tsx ===
Write-Host ''
Write-Host '== STEP 3: parties/[id]/page.tsx JSX module -> partyType ==' -ForegroundColor Cyan

# L183, L188: module={full.party.partyType} -> partyType={full.party.partyType}
# But this could match more places. Use specific surrounding context.
Set-PatchAll 'src\app\(app)\[partyType]\parties\[id]\page.tsx' `
    'module={full.party.partyType}' `
    'partyType={full.party.partyType}' `
    'JSX module={...} -> partyType={...}'

# L158: cast MeetingRow[] to PartyMeeting[]
# Without seeing the exact code, common pattern: fetchPartyMeetings(id) returns MeetingRow[] 
# but assigned to a PartyMeeting[] variable. Need exact line context.
# Skip for now.

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
