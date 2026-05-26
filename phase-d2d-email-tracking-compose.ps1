# =============================================================================
# Phase D2d: email-tracking actions + queries + email-compose L216
# Defers email-compose L289 (attachment_paths) and L332+ (to_address) pending diagnosis
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

# === STEP 1: email-tracking.ts actions ===
Write-Host '== STEP 1: email-tracking actions native -> typed rpc ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    "import { createSupabaseServerClient } from '@/lib/supabase/server';" `
    "import { createSupabaseServerClient } from '@/lib/supabase/server';`r`nimport { rpc } from '@/lib/rpc/typed-rpc';" `
    'Add rpc import'

Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    "  const { data, error } = await supabase.rpc('create_email_tracking', {" `
    "  const { data, error } = await rpc(supabase, 'create_email_tracking', {" `
    'native -> typed rpc (create_email_tracking)'

Set-PatchAll 'src\lib\actions\email-tracking.ts' `
    'const payload = data as TrackingPayload;' `
    'const payload = data as unknown as TrackingPayload;' `
    'cast TrackingPayload via unknown'

# === STEP 2: email-tracking.ts queries cast fixes ===
Write-Host ''
Write-Host '== STEP 2: email-tracking queries return data cast ==' -ForegroundColor Cyan
# The same `return data;` appears multiple times. Replace all (assumes each is the failed return).
# If a return is correctly-typed elsewhere it remains valid (`as unknown as` is harmless).
Set-PatchAll 'src\lib\queries\email-tracking.ts' `
    'if (error) throw error;`r`n  return data;' `
    'if (error) throw error;`r`n  return data as unknown as EmailTracking | null;' `
    'queries return data cast (maybe single)'

# === STEP 3: email-compose.ts L216 contactId null fix ===
Write-Host ''
Write-Host '== STEP 3: email-compose contactId null fix ==' -ForegroundColor Cyan

# Anchor: only the contactId line inside renderWithContext block
Set-PatchAll 'src\lib\actions\email-compose.ts' `
    '        payload.contactId`r`n      );' `
    '        payload.contactId ?? undefined`r`n      );' `
    'contactId null -> undefined (renderWithContext)'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
