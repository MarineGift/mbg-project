# =============================================================================
# Phase D2e: email-compose fix + email-tracking queries migration
# Properly quoted (double quotes for `r`n escape sequences)
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

function Set-LinePatch {
    param([string]$Path, [int]$LineIdx, [string]$ExpectedMatch, [string]$NewContent, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) { Write-Host ("  [MISS] " + $Path) -ForegroundColor DarkGray; return }
    $lines = Get-Content -LiteralPath $Path
    if ($LineIdx -ge $lines.Count) { Write-Host ("  [FAIL] " + $Desc + " - line OOR") -ForegroundColor Red; return }
    if ($lines[$LineIdx] -notmatch $ExpectedMatch) {
        Write-Host ("  [SKIP] " + $Desc + " - L" + ($LineIdx+1) + " content unexpected: '" + $lines[$LineIdx].Trim() + "'") -ForegroundColor DarkYellow
        return
    }
    Write-Host ("  [OK] " + $Desc + " (L" + ($LineIdx+1) + ")") -ForegroundColor Green
    if ($Apply) {
        $lines[$LineIdx] = $NewContent
        [System.IO.File]::WriteAllLines((Resolve-Path -LiteralPath $Path), $lines, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# === STEP 1: email-compose.ts select to_address -> to_addresses (4 errors) ===
Write-Host '== STEP 1: email-compose to_address -> to_addresses ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\actions\email-compose.ts' `
    '.select("subject, body_html, body_plain, from_address, to_address, sent_at")' `
    '.select("subject, body_html, body_plain, from_address, to_addresses, sent_at")' `
    'L315 select to_address -> to_addresses'

# === STEP 2: email-compose.ts L286 attachment_paths remove ===
Write-Host ''
Write-Host '== STEP 2: email-compose attachment_paths line remove ==' -ForegroundColor Cyan
Set-LinePatch 'src\lib\actions\email-compose.ts' 285 'attachment_paths' '      // attachment_paths: payload.attachmentPaths ?? [], // column does not exist in communications' 'L286 attachment_paths comment-out'

# === STEP 3: email-compose.ts L216 contactId null fix (line-based) ===
Write-Host ''
Write-Host '== STEP 3: email-compose contactId null fix ==' -ForegroundColor Cyan
Set-LinePatch 'src\lib\actions\email-compose.ts' 215 'payload\.contactId$' '        payload.contactId ?? undefined' 'L216 contactId ?? undefined'

# === STEP 4: email-tracking.ts queries native rpc -> typed ===
Write-Host ''
Write-Host '== STEP 4: email-tracking queries native -> typed rpc ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\email-tracking.ts' `
    "import { createSupabaseServerClient } from '@/lib/supabase/server';" `
    "import { createSupabaseServerClient } from '@/lib/supabase/server';`r`nimport { rpc } from '@/lib/rpc/typed-rpc';" `
    'Add rpc import (single quote variant)'

Set-PatchAll 'src\lib\queries\email-tracking.ts' `
    'import { createSupabaseServerClient } from "@/lib/supabase/server";' `
    "import { createSupabaseServerClient } from `"@/lib/supabase/server`";`r`nimport { rpc } from `"@/lib/rpc/typed-rpc`";" `
    'Add rpc import (double quote variant)'

Set-PatchAll 'src\lib\queries\email-tracking.ts' `
    'await supabase.rpc(' `
    'await rpc(supabase, ' `
    'native supabase.rpc -> rpc(supabase, (might match 2)'

# === STEP 5: email-tracking.ts queries cast fixes ===
Write-Host ''
Write-Host '== STEP 5: email-tracking queries cast as unknown as ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\email-tracking.ts' `
    'as DraftTrackingSummary[]' `
    'as unknown as DraftTrackingSummary[]' `
    'cast DraftTrackingSummary[]'

Set-PatchAll 'src\lib\queries\email-tracking.ts' `
    'as { communication_id: string; tracking_id: string; open_count: number; click_count: number; first_opened_at: string | null; sent_at: string; }[]' `
    'as unknown as { communication_id: string; tracking_id: string; open_count: number; click_count: number; first_opened_at: string | null; sent_at: string; }[]' `
    'cast tracking summary array'

# === STEP 6: email-tracking.ts queries return data casts (4 patches) ===
Write-Host ''
Write-Host '== STEP 6: email-tracking queries return data casts ==' -ForegroundColor Cyan
# Line numbers from error report: 32, 49, 64, 79 (1-indexed). Use line-based.
Set-LinePatch 'src\lib\queries\email-tracking.ts' 31 'return data' '  return data as unknown as EmailTracking | null;' 'L32 return -> EmailTracking|null'
Set-LinePatch 'src\lib\queries\email-tracking.ts' 48 'return data' '  return data as unknown as EmailTracking | null;' 'L49 return -> EmailTracking|null'
Set-LinePatch 'src\lib\queries\email-tracking.ts' 63 'return data' '  return data as unknown as EmailTracking[];' 'L64 return -> EmailTracking[]'
Set-LinePatch 'src\lib\queries\email-tracking.ts' 78 'return data' '  return data as unknown as EmailTrackingEvent[];' 'L79 return -> EmailTrackingEvent[]'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
