# =============================================================================
# Phase D2l: type alignments
# - EmailTracking: organization_id -> org_id (match DB)
# - EmailSignature: html -> html_content, remove plain_text
# - engagements: module variable typo -> partyType
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

# === STEP 1: EmailTracking organization_id -> org_id ===
Write-Host '== STEP 1: phase21.ts EmailTracking org_id ==' -ForegroundColor Cyan
Set-PatchAll 'src\types\phase21.ts' `
    "  id: string;`n  organization_id: string;" `
    "  id: string;`n  org_id: string;" `
    'EmailTracking: organization_id -> org_id (match DB)'

# === STEP 2: EmailSignature alignment with DB ===
Write-Host ''
Write-Host '== STEP 2: email-signatures.ts EmailSignature ==' -ForegroundColor Cyan
# Replace html: string + plain_text: string with html_content: string + add created_at, updated_at
$old2 = "  name: string;`n  html: string;`n  plain_text: string;`n  is_default: boolean;`n}"
$new2 = "  name: string;`n  html_content: string;`n  is_default: boolean;`n  created_at: string;`n  updated_at: string;`n}"
Set-PatchAll 'src\lib\queries\email-signatures.ts' $old2 $new2 'EmailSignature align with DB (html_content + dates)'

# === STEP 3: engagements.ts module variable typo ===
Write-Host ''
Write-Host '== STEP 3: queries/engagements module variable typo ==' -ForegroundColor Cyan
# L189: fetchPipelineForModule(module) -> fetchPipelineForModule(partyType)
Set-PatchAll 'src\lib\queries\engagements.ts' `
    'fetchPipelineForModule(module)' `
    'fetchPipelineForModule(partyType)' `
    'L189 module var -> partyType (arg name)'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
