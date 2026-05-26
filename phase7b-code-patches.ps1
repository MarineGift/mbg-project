# =============================================================================
# Phase 7-b code patches: Replace-Or-Fail with DryRun default
# =============================================================================
# Two surgical patches in src/lib/actions/email-compose.ts:
#   1. communications insert: to_address (single) -> to_addresses (array)
#   2. email_whitelist filter: value -> pattern
#
# Default mode: DryRun (no writes). Pass -Apply to actually modify files.
# Each anchor must match exactly once or the script aborts without writing.
#
# English-only. UTF-8 no-BOM preserved on output.
# =============================================================================

param([switch]$Apply)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\dev\mbg-project'

function Invoke-ReplaceOnce {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Anchor,
        [Parameter(Mandatory)] [string]$Replacement,
        [Parameter(Mandatory)] [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ('File not found: ' + $Path)
    }

    $original = [System.IO.File]::ReadAllText($Path)

    # Try as-is first (matches the file's existing line endings exactly)
    $count = ([regex]::Matches($original, [regex]::Escape($Anchor))).Count

    # If zero, try with LF-normalized anchor against an LF-normalized copy
    $matchMode = 'as-is'
    if ($count -eq 0) {
        $lfOriginal = $original -replace "`r`n", "`n"
        $lfAnchor   = $Anchor   -replace "`r`n", "`n"
        $count = ([regex]::Matches($lfOriginal, [regex]::Escape($lfAnchor))).Count
        if ($count -gt 0) { $matchMode = 'LF-normalized' }
    }

    if ($count -eq 0) {
        throw ('Anchor NOT FOUND in ' + $Path + ' --- ' + $Description)
    }
    if ($count -gt 1) {
        throw ('Anchor matched ' + $count + ' times in ' + $Path + ' (expected 1) --- ' + $Description)
    }

    Write-Host ('[OK  ] match=' + $matchMode + '  ' + $Description) -ForegroundColor Yellow

    if ($matchMode -eq 'LF-normalized') {
        $lfOriginal = $original -replace "`r`n", "`n"
        $lfAnchor   = $Anchor   -replace "`r`n", "`n"
        $lfReplace  = $Replacement -replace "`r`n", "`n"
        $new = $lfOriginal.Replace($lfAnchor, $lfReplace)
        # Restore CRLF only if the original used CRLF
        if ($original.Contains("`r`n")) {
            $new = $new -replace "`n", "`r`n"
        }
    } else {
        $new = $original.Replace($Anchor, $Replacement)
    }

    if ($Apply) {
        $enc = New-Object System.Text.UTF8Encoding($false)  # no BOM
        [System.IO.File]::WriteAllText($Path, $new, $enc)
        Write-Host ('[WRITE] ' + $Path) -ForegroundColor Green
    }
}

# =============================================================================
# Patch 1: communications.to_address (single string) -> to_addresses (array)
# Location: src/lib/actions/email-compose.ts L281 area
# =============================================================================

$p1Anchor = @'
      to_address: payload.to,
      message_id: smtpMessageId,
'@

$p1Replacement = @'
      to_addresses: [payload.to],
      message_id: smtpMessageId,
'@

Invoke-ReplaceOnce `
    -Path 'src\lib\actions\email-compose.ts' `
    -Anchor $p1Anchor `
    -Replacement $p1Replacement `
    -Description 'email-compose.ts: communications.to_address (string) -> to_addresses ([string])'

# =============================================================================
# Patch 2: email_whitelist filter column 'value' -> 'pattern'
# Location: src/lib/actions/email-compose.ts L198 area
# =============================================================================

$p2Anchor = @'
      .or(`value.eq.${domain},value.eq.${payload.to.toLowerCase()}`)
'@

$p2Replacement = @'
      .or(`pattern.eq.${domain},pattern.eq.${payload.to.toLowerCase()}`)
'@

Invoke-ReplaceOnce `
    -Path 'src\lib\actions\email-compose.ts' `
    -Anchor $p2Anchor `
    -Replacement $p2Replacement `
    -Description 'email-compose.ts: email_whitelist .or() column value -> pattern'

# =============================================================================
# Summary
# =============================================================================
Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
    Write-Host 'Re-run tsc to measure:' -ForegroundColor Cyan
    Write-Host '  (npx tsc --noEmit 2>&1 | Select-String ''error TS'').Count'
} else {
    Write-Host '== DRY-RUN OK ==' -ForegroundColor Cyan
    Write-Host 'No files modified. Re-run with -Apply to write changes:' -ForegroundColor Yellow
    Write-Host '  .\phase7b-code-patches.ps1 -Apply'
}
