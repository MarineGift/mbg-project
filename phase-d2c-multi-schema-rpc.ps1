# =============================================================================
# Phase D2c: typed-rpc multi-schema + migrate communications/whitelist
# Step 1: extend Fns union to include app + ai schemas
# Step 2: replace native supabase.rpc() with typed rpc() helper
# Step 3: add as unknown as for cast errors
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

# === STEP 1: typed-rpc.ts Fns union ?•ìž¥ ===
Write-Host '== STEP 1: typed-rpc Fns union extension ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\rpc\typed-rpc.ts' `
    "type Fns = Database['public']['Functions'] & Augmentation;" `
    "type Fns = Database['public']['Functions'] & Database['app']['Functions'] & Database['ai']['Functions'] & Augmentation;" `
    'Fns union extended (public + app + ai)'

# === STEP 2: communications.ts migrate to typed rpc() ===
Write-Host ''
Write-Host '== STEP 2: communications.ts native -> typed rpc() ==' -ForegroundColor Cyan

# Add rpc import (after createSupabaseServerClient import)
Set-PatchAll 'src\lib\queries\communications.ts' `
    'import { createSupabaseServerClient } from "@/lib/supabase/server";' `
    "import { createSupabaseServerClient } from `"@/lib/supabase/server`";`r`nimport { rpc } from `"@/lib/rpc/typed-rpc`";" `
    'Add rpc import'

# Replace native rpc calls with typed rpc()
# Pattern 1: multiline (data, error) form
Set-PatchAll 'src\lib\queries\communications.ts' `
    '  const { data, error } = await supabase.rpc(' `
    '  const { data, error } = await rpc(supabase,' `
    'native supabase.rpc -> rpc(supabase,'

# Pattern 2: single-line form .rpc("name", { ... })
Set-PatchAll 'src\lib\queries\communications.ts' `
    '  const { data, error } = await supabase.rpc("get_thread_context", {' `
    '  const { data, error } = await rpc(supabase, "get_thread_context", {' `
    'inline rpc get_thread_context'

Set-PatchAll 'src\lib\queries\communications.ts' `
    '  const { data, error } = await supabase.rpc("list_templates_for_compose", {' `
    '  const { data, error } = await rpc(supabase, "list_templates_for_compose", {' `
    'inline rpc list_templates_for_compose'

# === STEP 3: email-whitelist.ts migrate ===
Write-Host ''
Write-Host '== STEP 3: email-whitelist.ts native -> typed rpc() ==' -ForegroundColor Cyan

# Add rpc import
Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    'import { createSupabaseServerClient } from "@/lib/supabase/server";' `
    "import { createSupabaseServerClient } from `"@/lib/supabase/server`";`r`nimport { rpc } from `"@/lib/rpc/typed-rpc`";" `
    'Add rpc import'

# Replace 5 unique sb.rpc("name", ...) patterns
Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    'await sb.rpc("list_email_whitelist",{p_org_id:ORG_ID})' `
    'await rpc(sb,"list_email_whitelist",{p_org_id:ORG_ID})' `
    'rpc list_email_whitelist'

Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    'await sb.rpc("get_unregistered_party_domains",{p_org_id:ORG_ID})' `
    'await rpc(sb,"get_unregistered_party_domains",{p_org_id:ORG_ID})' `
    'rpc get_unregistered_party_domains'

Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    'await sb.rpc("add_email_whitelist",' `
    'await rpc(sb,"add_email_whitelist",' `
    'rpc add_email_whitelist (2x)'

Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    'await sb.rpc("toggle_email_whitelist",' `
    'await rpc(sb,"toggle_email_whitelist",' `
    'rpc toggle_email_whitelist'

Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    'await sb.rpc("delete_email_whitelist",' `
    'await rpc(sb,"delete_email_whitelist",' `
    'rpc delete_email_whitelist'

# Whitelist cast fixes
Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    '(data||[]) as WhitelistEntry[]' `
    '(data||[]) as unknown as WhitelistEntry[]' `
    'cast WhitelistEntry[]'

Set-PatchAll 'src\lib\actions\email-whitelist.ts' `
    '(data||[]) as UnregisteredDomain[]' `
    '(data||[]) as unknown as UnregisteredDomain[]' `
    'cast UnregisteredDomain[]'

# === STEP 4: communications.ts cast errors ===
Write-Host ''
Write-Host '== STEP 4: communications.ts cast fixes ==' -ForegroundColor Cyan

Set-PatchAll 'src\lib\queries\communications.ts' `
    'as CommunicationTimelineItem[]' `
    'as unknown as CommunicationTimelineItem[]' `
    'cast CommunicationTimelineItem[]'

Set-PatchAll 'src\lib\queries\communications.ts' `
    'as ThreadContext' `
    'as unknown as ThreadContext' `
    'cast ThreadContext'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
