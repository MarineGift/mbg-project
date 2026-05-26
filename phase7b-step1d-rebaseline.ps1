# =============================================================================
# Phase 7-b Step 1-d: re-baseline after domain corrections
# =============================================================================
# User clarified:
#   - party_contacts is NOT used; contacts is queried directly
#   - org_members has been removed (no longer used)
#   - email_signatures is genuinely missing (CREATE still needed)
#
# This script confirms three things before the SQL/spec is rewritten:
#   1. `app.contacts` Row block (does it have party_id / is_primary?)
#   2. The canonical pattern other files use to obtain organization_id
#   3. Every file in src/ that still references org_members or party_contacts
#
# Read-only. English-only (no BOM).
# =============================================================================

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\dev\mbg-project'

$dbPath = 'src\types\database.ts'
$content = Get-Content -LiteralPath $dbPath

$out = 'phase7b-step1d-output.md'
$lines = New-Object System.Collections.Generic.List[string]
function Add-Line { param([string]$s = '') $script:lines.Add($s) }

Add-Line '# Phase 7-b Step 1-d output'
Add-Line ('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ''

# =============================================================================
# 1. app.contacts Row block
# =============================================================================
Add-Line '## 1. `app.contacts` Row block'
Add-Line ''

function Find-RowBlock {
    param([string]$tableName)
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match ('^\s{4,8}' + [regex]::Escape($tableName) + ':\s*\{\s*$')) {
            for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $content.Length); $j++) {
                if ($content[$j] -match '^\s+Row:\s*\{') {
                    return @{ TableLine = $i; RowLine = $j }
                }
            }
        }
    }
    return $null
}

$contactsFound = Find-RowBlock -tableName 'contacts'

if ($null -eq $contactsFound) {
    Add-Line '**Status: NOT FOUND** --- this is a serious problem; aborting analysis.'
} else {
    Add-Line ('Found at L' + ($contactsFound.TableLine + 1) + ' (Row at L' + ($contactsFound.RowLine + 1) + ')')
    Add-Line ''
    Add-Line '```ts'
    $depth = 0
    for ($i = $contactsFound.RowLine; $i -lt $contactsFound.RowLine + 200; $i++) {
        $line = $content[$i]
        Add-Line ('L' + ($i + 1) + ': ' + $line)
        $opens = ([regex]::Matches($line, '\{')).Count
        $closes = ([regex]::Matches($line, '\}')).Count
        $depth += $opens - $closes
        if ($i -gt $contactsFound.RowLine -and $depth -le 0) { break }
    }
    Add-Line '```'

    # Quick sanity check
    Add-Line ''
    Add-Line '**Quick check:**'
    $hasPartyId = $false
    $hasIsPrimary = $false
    for ($i = $contactsFound.RowLine; $i -lt $contactsFound.RowLine + 100; $i++) {
        if ($content[$i] -match '^\s+party_id:') { $hasPartyId = $true }
        if ($content[$i] -match '^\s+is_primary:') { $hasIsPrimary = $true }
    }
    Add-Line ('- `party_id` column: ' + $(if ($hasPartyId) { 'YES' } else { 'NO' }))
    Add-Line ('- `is_primary` column: ' + $(if ($hasIsPrimary) { 'YES' } else { 'NO' }))
}
Add-Line ''

# =============================================================================
# 2. Canonical organization_id extraction pattern
# =============================================================================
Add-Line '## 2. How other files obtain `organization_id`'
Add-Line ''
Add-Line 'Search across src/lib/actions and src/lib/queries for any pattern that'
Add-Line 'reads or derives organization_id. The most common idiom there is the'
Add-Line 'canonical replacement for the removed `org_members` lookup.'
Add-Line ''

# 2a. JWT claim access patterns
Add-Line '### 2a. JWT / session-based access'
Add-Line ''
Add-Line '```'
$jwtHits = Get-ChildItem -Path 'src\lib' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Select-String -Pattern '(auth\.jwt|app_metadata|getSession|getUser|raw_app_meta|user_metadata|organization_id)' -Context 1,1

$jwtRelevant = $jwtHits | Where-Object {
    $_.Line -match '(organization_id|app_metadata)'
}
$jwtRelevant | Select-Object -First 30 | ForEach-Object {
    $rel = $_.Path -replace [regex]::Escape((Get-Location).Path + '\'), ''
    Add-Line ('--- ' + $rel + ' L' + $_.LineNumber)
    foreach ($pre in $_.Context.PreContext) { Add-Line ('  ' + $pre) }
    Add-Line ('> ' + $_.Line)
    foreach ($post in $_.Context.PostContext) { Add-Line ('  ' + $post) }
    Add-Line ''
}
Add-Line '```'
Add-Line ''
Add-Line ('Total matches: ' + (@($jwtRelevant).Count))
Add-Line ''

# 2b. Server helper modules
Add-Line '### 2b. Server / supabase helper modules'
Add-Line ''
Add-Line '```'
$helperFiles = Get-ChildItem -Path 'src\lib\supabase' -Recurse -Include '*.ts' -ErrorAction SilentlyContinue
foreach ($f in $helperFiles) {
    $rel = $f.FullName -replace [regex]::Escape((Get-Location).Path + '\'), ''
    Add-Line ('--- ' + $rel)
    Get-Content -LiteralPath $f.FullName | Select-Object -First 60 | ForEach-Object -Begin { $n = 1 } -Process {
        Add-Line ('L' + $n + ': ' + $_)
        $n++
    }
    Add-Line ''
}
Add-Line '```'
Add-Line ''

# 2c. RPC functions that may return current org
Add-Line '### 2c. RPC calls that look like "current org" helpers'
Add-Line ''
$orgRpcHits = Get-ChildItem -Path 'src' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Select-String -Pattern "\.rpc\(['""]([^'""]*?(current_org|my_org|active_org|org_id|user_org)[^'""]*?)['""]" -AllMatches

if ($orgRpcHits) {
    Add-Line '```'
    foreach ($h in $orgRpcHits) {
        foreach ($m in $h.Matches) {
            $rel = $h.Path -replace [regex]::Escape((Get-Location).Path + '\'), ''
            Add-Line ('- ' + $rel + ' L' + $h.LineNumber + ': rpc("' + $m.Groups[1].Value + '")')
        }
    }
    Add-Line '```'
} else {
    Add-Line '(no current-org RPC helpers found)'
}
Add-Line ''

# =============================================================================
# 3. Distribution of stale references to org_members and party_contacts
# =============================================================================
Add-Line '## 3. Files still referencing removed tables'
Add-Line ''

foreach ($staleTable in @('org_members', 'party_contacts')) {
    Add-Line ('### `' + $staleTable + '`')
    Add-Line ''
    $hits = Get-ChildItem -Path 'src' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
        Select-String -Pattern ('\b' + $staleTable + '\b') -Context 1,1
    if ($hits) {
        Add-Line ('Total: ' + $hits.Count + ' matches')
        Add-Line ''
        Add-Line '```ts'
        foreach ($h in $hits) {
            $rel = $h.Path -replace [regex]::Escape((Get-Location).Path + '\'), ''
            Add-Line ('--- ' + $rel + ' L' + $h.LineNumber)
            foreach ($pre in $h.Context.PreContext) { Add-Line ('  ' + $pre) }
            Add-Line ('> ' + $h.Line)
            foreach ($post in $h.Context.PostContext) { Add-Line ('  ' + $post) }
            Add-Line ''
        }
        Add-Line '```'
    } else {
        Add-Line '(no matches --- already clean)'
    }
    Add-Line ''
}

# =============================================================================
# Write
# =============================================================================
$text = ($lines -join "`r`n")
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host ('Done. Output: ' + $out) -ForegroundColor Green
Write-Host ('Lines: ' + $lines.Count) -ForegroundColor Cyan
