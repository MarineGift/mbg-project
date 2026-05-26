# =============================================================================
# Phase D2k: phase21.ts EmailTracking + EmailTrackingEvent type fix
# - EmailTracking: add communication_id field
# - EmailTrackingEvent: widen event_type from union to string
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

# === STEP 1: EmailTracking add communication_id ===
Write-Host '== STEP 1: phase21.ts EmailTracking add communication_id ==' -ForegroundColor Cyan
# Use LF newlines (`n) since file is LF in working tree
$old1 = "  contact_id: string | null;`n  subject: string | null;"
$new1 = "  contact_id: string | null;`n  communication_id: string | null;`n  subject: string | null;"
Set-PatchAll 'src\types\phase21.ts' $old1 $new1 'Add communication_id field after contact_id (LF)'

# Fallback if file is CRLF
$old1crlf = "  contact_id: string | null;`r`n  subject: string | null;"
$new1crlf = "  contact_id: string | null;`r`n  communication_id: string | null;`r`n  subject: string | null;"
Set-PatchAll 'src\types\phase21.ts' $old1crlf $new1crlf 'Add communication_id field after contact_id (CRLF)'

# === STEP 2: EmailTrackingEvent.event_type widen to string ===
Write-Host ''
Write-Host '== STEP 2: EmailTrackingEvent.event_type widen ==' -ForegroundColor Cyan
Set-PatchAll 'src\types\phase21.ts' `
    "event_type: 'open' | 'click';" `
    'event_type: string;' `
    'event_type narrowed union -> string'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
