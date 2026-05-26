# =============================================================================
# Phase D2i: Quick wins from cluster scan
# - email-tracking actions: ?? null -> ?? undefined (5)
# - parties/[id]/page.tsx params type: module -> partyType (cascades 1+)
# - timeline meta non-null (3)
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

# === STEP 1: email-tracking actions ?? null -> ?? undefined ===
Write-Host '== STEP 1: email-tracking actions ?? null -> ?? undefined ==' -ForegroundColor Cyan
# 5 lines all with `??         null,` (varied whitespace before null)
Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    'input.communicationId ?? null,' `
    'input.communicationId ?? undefined,' `
    'p_communication_id ?? undefined'

Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    'input.draftId         ?? null,' `
    'input.draftId         ?? undefined,' `
    'p_draft_id ?? undefined'

Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    'input.partyId         ?? null,' `
    'input.partyId         ?? undefined,' `
    'p_party_id ?? undefined'

Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    'input.contactId       ?? null,' `
    'input.contactId       ?? undefined,' `
    'p_contact_id ?? undefined'

Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    'input.subject         ?? null,' `
    'input.subject         ?? undefined,' `
    'p_subject ?? undefined'

# === STEP 2: parties/[id]/page.tsx params type ===
Write-Host ''
Write-Host '== STEP 2: parties/[id]/page.tsx params type ==' -ForegroundColor Cyan
# Change params: Promise<{ module: string; id: string }> to { partyType: string; id: string }
Set-PatchAll 'src\app\(app)\[partyType]\parties\[id]\page.tsx' `
    'params: Promise<{ module: string; id: string }>;' `
    'params: Promise<{ partyType: string; id: string }>;' `
    'L44 params type'

# === STEP 3: timeline meta non-null (D2h replay) ===
Write-Host ''
Write-Host '== STEP 3: timeline meta non-null ==' -ForegroundColor Cyan
Set-PatchAll 'src\components\parties\party-communications-timeline.tsx' `
    'const meta = intentMeta[intent] || intentMeta.question;' `
    'const meta = (intentMeta[intent] || intentMeta.question)!;' `
    'L531 meta non-null assertion'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
