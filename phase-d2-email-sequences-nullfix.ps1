# =============================================================================
# Phase D2a: email-sequences.ts null vs undefined fix
# Fixes ~15 TS errors. RPC params expect string|undefined not string|null.
# DryRun by default. Set $Apply = $true at top and re-run to apply.
# =============================================================================

$ErrorActionPreference = 'Stop'
$Apply = $true

function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("  [MISS] file not found: " + $Path) -ForegroundColor DarkGray
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

$P = 'src\lib\actions\email-sequences.ts'

Write-Host '== email-sequences.ts null -> undefined fix ==' -ForegroundColor Cyan

# L93: p_contact_id null vs string
Set-PatchAll $P 'p_contact_id:  contactId,' 'p_contact_id:  contactId ?? undefined,' 'L93 contact_id ?? undefined'

# L161: EmailSequenceWithSteps cast
Set-PatchAll $P 'return { data: data as EmailSequenceWithSteps };' 'return { data: data as unknown as EmailSequenceWithSteps };' 'L161 cast via unknown'

# RPC param || null patterns (3 functions x 6 params)
Set-PatchAll $P 'p_module:        filters.module       || null,'                'p_module:        filters.module       ?? undefined,'                'p_module ?? undefined'
Set-PatchAll $P 'p_tiers:         filters.tiers && filters.tiers.length > 0 ? filters.tiers : null,' 'p_tiers:         filters.tiers && filters.tiers.length > 0 ? filters.tiers : undefined,' 'p_tiers ternary -> undefined'
Set-PatchAll $P 'p_status:        filters.status       || null,'                'p_status:        filters.status       ?? undefined,'                'p_status ?? undefined'
Set-PatchAll $P 'p_country_code:  filters.countryCode  || null,'                'p_country_code:  filters.countryCode  ?? undefined,'                'p_country_code ?? undefined'
Set-PatchAll $P 'p_industry_tag:  filters.industryTag  || null,'                'p_industry_tag:  filters.industryTag  ?? undefined,'                'p_industry_tag ?? undefined'
Set-PatchAll $P 'p_name_contains: filters.nameContains || null,'                'p_name_contains: filters.nameContains ?? undefined,'                'p_name_contains ?? undefined'

# L200: p_enrolled_by enrolledBy (callBulkEnrollRpc)
Set-PatchAll $P 'p_enrolled_by:   enrolledBy,' 'p_enrolled_by:   enrolledBy ?? undefined,' 'L200 enrolledBy ?? undefined'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
