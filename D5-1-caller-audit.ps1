# D5-1 caller audit (PowerShell 5.x safe, ASCII only)
# Purpose: identify caller sites that need cutover for Stage 29-c
# Output: D5-1-caller-audit.md in project root (UTF-8 BOM)
#
# Replaces stage29c\01_caller_audit\audit.ps1 which fails on PS 5.x due
# to UTF-8 no-BOM encoding mis-parsed as CP949.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   .\D5-1-caller-audit.ps1

$ErrorActionPreference = 'Continue'

$projectRoot = 'C:\dev\mbg-project'
$srcDir      = Join-Path $projectRoot 'src'
$outputFile  = Join-Path $projectRoot 'D5-1-caller-audit.md'

Write-Host '=== D5-1 caller audit (PS5.x-safe) ===' -ForegroundColor Cyan
Write-Host "Project root: $projectRoot"
Write-Host ''

if (-not (Test-Path -LiteralPath $srcDir)) {
    Write-Host "[ERROR] src dir not found: $srcDir" -ForegroundColor Red
    exit 1
}

# ==========================================================================
# Patterns -- single-quoted with hex escapes for quotes (PS5.x safe)
#   \x27 = apostrophe
#   \x22 = double quote
# ==========================================================================
$patFrom   = '\.from\(\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]'
$patRpc    = '\.rpc\(\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]'
$patSchema = 'schema\s*:\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]'

# ==========================================================================
# [1/6] Locate database.ts
# ==========================================================================
Write-Host '[1/6] Locating database.ts' -ForegroundColor Yellow
$dbCandidates = @(
    'src\types\database.ts',
    'src\lib\supabase\database.ts',
    'src\lib\database.ts',
    'src\db\database.ts',
    'src\database.ts'
)
$dbPath = $null
foreach ($c in $dbCandidates) {
    $full = Join-Path $projectRoot $c
    if (Test-Path -LiteralPath $full) {
        $dbPath = $full
        $sz = (Get-Item $full).Length
        Write-Host "  [FOUND] $c ($sz bytes)" -ForegroundColor Green
        break
    }
}
if (-not $dbPath) {
    Write-Host '  [SEARCH] Probing src/ for database.ts' -ForegroundColor DarkYellow
    $found = Get-ChildItem -Path $srcDir -Recurse -Filter 'database.ts' -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -notmatch 'node_modules' } |
             Select-Object -First 5
    foreach ($f in $found) {
        Write-Host "  [CANDIDATE] $($f.FullName)" -ForegroundColor DarkYellow
    }
    if ($found.Count -gt 0) { $dbPath = $found[0].FullName }
}

# ==========================================================================
# [2/6] Check urm presence in database.ts
# ==========================================================================
Write-Host '[2/6] Checking urm in database.ts' -ForegroundColor Yellow

$urmSchemaCount = 0
$urmTableNames  = @()
if ($dbPath) {
    $dbContent = [System.IO.File]::ReadAllText($dbPath)
    $urmSchemaCount = ([regex]::Matches($dbContent, '(?m)^  urm: \{')).Count
    Write-Host "  urm schema header count: $urmSchemaCount" -ForegroundColor $(if ($urmSchemaCount -gt 0) { 'Green' } else { 'Red' })

    if ($urmSchemaCount -gt 0) {
        # Slice from "  urm: {" to next top-level schema header
        $urmHead = '(?m)^  urm: \{'
        $allHeads = [regex]::Matches($dbContent, '(?m)^  [a-z_]+: \{')
        $urmIdx = -1
        $nextIdx = $dbContent.Length
        for ($i = 0; $i -lt $allHeads.Count; $i++) {
            $line = $allHeads[$i].Value
            if ($line -match '^\s+urm:') { $urmIdx = $i; break }
        }
        if ($urmIdx -ge 0) {
            $start = $allHeads[$urmIdx].Index
            if ($urmIdx + 1 -lt $allHeads.Count) {
                $nextIdx = $allHeads[$urmIdx + 1].Index
            }
            $urmSection = $dbContent.Substring($start, $nextIdx - $start)
            # Match "      tablename: {" (6 leading spaces, name, colon, brace)
            $tMatches = [regex]::Matches($urmSection, '(?m)^      ([a-z_][a-z0-9_]*): \{')
            $urmTableNames = $tMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
            Write-Host "  urm tables in database.ts: $($urmTableNames.Count)" -ForegroundColor Green
            foreach ($t in ($urmTableNames | Select-Object -First 25)) {
                Write-Host "    - $t" -ForegroundColor DarkGreen
            }
            if ($urmTableNames.Count -gt 25) {
                Write-Host "    ... ($($urmTableNames.Count - 25) more)" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host '  [SKIP] database.ts not found' -ForegroundColor Red
}

# ==========================================================================
# [3/6] Scan src for .from() and .rpc() calls
# ==========================================================================
Write-Host '[3/6] Scanning .from() / .rpc() calls in src' -ForegroundColor Yellow

$tsFiles = Get-ChildItem -LiteralPath $srcDir -Recurse -Include *.ts,*.tsx -ErrorAction SilentlyContinue |
           Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch '\\\.next\\' }
Write-Host "  TS/TSX files: $($tsFiles.Count)"

$fromCalls = New-Object System.Collections.ArrayList
$rpcCalls  = New-Object System.Collections.ArrayList

foreach ($f in $tsFiles) {
    $rel = $f.FullName.Substring($projectRoot.Length + 1)
    $content = [System.IO.File]::ReadAllText($f.FullName)

    foreach ($m in [regex]::Matches($content, $patFrom)) {
        $lineNum = ($content.Substring(0, $m.Index) -split "`n").Count
        [void]$fromCalls.Add([pscustomobject]@{
            file = $rel; line = $lineNum; arg = $m.Groups[1].Value
        })
    }
    foreach ($m in [regex]::Matches($content, $patRpc)) {
        $lineNum = ($content.Substring(0, $m.Index) -split "`n").Count
        [void]$rpcCalls.Add([pscustomobject]@{
            file = $rel; line = $lineNum; arg = $m.Groups[1].Value
        })
    }
}
Write-Host "  .from() calls: $($fromCalls.Count)" -ForegroundColor Green
Write-Host "  .rpc()  calls: $($rpcCalls.Count)" -ForegroundColor Green

# Group .from() by table arg
$fromByArg = $fromCalls | Group-Object arg | Sort-Object Count -Descending
$rpcByArg  = $rpcCalls  | Group-Object arg | Sort-Object Count -Descending

# ==========================================================================
# [4/6] Schema config detection (createClient with db: schema: ...)
# ==========================================================================
Write-Host '[4/6] Detecting schema config in supabase clients' -ForegroundColor Yellow

$schemaConfigs = New-Object System.Collections.ArrayList
foreach ($f in $tsFiles) {
    $rel = $f.FullName.Substring($projectRoot.Length + 1)
    $content = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($m in [regex]::Matches($content, $patSchema)) {
        $lineNum = ($content.Substring(0, $m.Index) -split "`n").Count
        [void]$schemaConfigs.Add([pscustomobject]@{
            file = $rel; line = $lineNum; schema = $m.Groups[1].Value
        })
    }
}
Write-Host "  schema configs: $($schemaConfigs.Count)" -ForegroundColor Green

# ==========================================================================
# [5/6] Column rename targets (from stage29c handoff)
# ==========================================================================
Write-Host '[5/6] Searching column rename targets' -ForegroundColor Yellow

$renameTargets = @(
    @{ v1='org_id';         v2='organization_id'; tbl='email_whitelist/communications' },
    @{ v1='body_text';      v2='body_plain';      tbl='communications' },
    @{ v1='joined_at';      v2='started_at';      tbl='contacts_history' },
    @{ v1='left_at';        v2='ended_at';        tbl='contacts_history' },
    @{ v1='supply_type';    v2='link_type';       tbl='party_supply_links' },
    @{ v1='volume_tpy';     v2='volume_estimate'; tbl='party_supply_links' },
    @{ v1='stage_position'; v2='sort_order';      tbl='stages' }
)
$renameHits = New-Object System.Collections.ArrayList
foreach ($t in $renameTargets) {
    $pat = '\b' + [regex]::Escape($t.v1) + '\b'
    $totalHits = 0
    foreach ($f in $tsFiles) {
        $content = [System.IO.File]::ReadAllText($f.FullName)
        $mc = [regex]::Matches($content, $pat).Count
        if ($mc -gt 0) {
            $totalHits += $mc
            $rel = $f.FullName.Substring($projectRoot.Length + 1)
            [void]$renameHits.Add([pscustomobject]@{
                v1 = $t.v1; v2 = $t.v2; tbl = $t.tbl; file = $rel; count = $mc
            })
        }
    }
    $col = if ($totalHits -gt 0) { 'Yellow' } else { 'DarkGray' }
    Write-Host ("  {0,-15} -> {1,-20} : {2,3} mentions" -f $t.v1, $t.v2, $totalHits) -ForegroundColor $col
}

# Also check for direct 'party_type' field reads (the manual P1-P7 work)
$partyTypeHits = New-Object System.Collections.ArrayList
$ptPat = '\.party_type\b|[\x27\x22]party_type[\x27\x22]'
foreach ($f in $tsFiles) {
    $rel = $f.FullName.Substring($projectRoot.Length + 1)
    $content = [System.IO.File]::ReadAllText($f.FullName)
    $matches = [regex]::Matches($content, $ptPat)
    if ($matches.Count -gt 0) {
        [void]$partyTypeHits.Add([pscustomobject]@{
            file = $rel; count = $matches.Count
        })
    }
}
Write-Host "  party_type direct refs: $(($partyTypeHits | Measure-Object -Property count -Sum).Sum) in $($partyTypeHits.Count) files" -ForegroundColor Yellow

# ==========================================================================
# [6/6] Write report (UTF-8 BOM)
# ==========================================================================
Write-Host '[6/6] Writing report' -ForegroundColor Yellow

$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine('# D5-1 caller audit report')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("**Project root**: ``$projectRoot``")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')

# Section 1: database.ts
[void]$sb.AppendLine('## 1. database.ts location and urm presence')
[void]$sb.AppendLine('')
if ($dbPath) {
    $relDb = $dbPath.Substring($projectRoot.Length + 1)
    [void]$sb.AppendLine("- Path: ``$relDb``")
    [void]$sb.AppendLine("- Size: $((Get-Item $dbPath).Length) bytes")
    [void]$sb.AppendLine("- urm schema header count: $urmSchemaCount")
    [void]$sb.AppendLine("- urm tables in database.ts: $($urmTableNames.Count)")
    if ($urmTableNames.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('### urm tables')
        [void]$sb.AppendLine('')
        foreach ($t in $urmTableNames) {
            [void]$sb.AppendLine("- $t")
        }
    }
} else {
    [void]$sb.AppendLine('**database.ts NOT FOUND** -- type regen required before cutover.')
}
[void]$sb.AppendLine('')

# Section 2: schema config in clients
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## 2. Supabase client schema configs')
[void]$sb.AppendLine('')
if ($schemaConfigs.Count -eq 0) {
    [void]$sb.AppendLine('No `schema: ''...''` configs found -- clients use default `public` schema.')
} else {
    [void]$sb.AppendLine('| File | Line | Schema |')
    [void]$sb.AppendLine('|---|---:|---|')
    foreach ($s in $schemaConfigs) {
        [void]$sb.AppendLine(('| `{0}` | {1} | `{2}` |' -f $s.file, $s.line, $s.schema))
    }
}
[void]$sb.AppendLine('')

# Section 3: .from() argument distribution
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## 3. `.from()` call argument distribution')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Total: $($fromCalls.Count) calls across $($tsFiles.Count) files")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Arg | Count |')
[void]$sb.AppendLine('|---|---:|')
foreach ($g in $fromByArg) {
    [void]$sb.AppendLine(('| `{0}` | {1} |' -f $g.Name, $g.Count))
}
[void]$sb.AppendLine('')

# Section 4: .rpc() argument distribution
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## 4. `.rpc()` call argument distribution')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Total: $($rpcCalls.Count) calls")
[void]$sb.AppendLine('')
if ($rpcCalls.Count -gt 0) {
    [void]$sb.AppendLine('| Arg | Count |')
    [void]$sb.AppendLine('|---|---:|')
    foreach ($g in $rpcByArg) {
        [void]$sb.AppendLine(('| `{0}` | {1} |' -f $g.Name, $g.Count))
    }
} else {
    [void]$sb.AppendLine('(no calls)')
}
[void]$sb.AppendLine('')

# Section 5: column rename target hits
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## 5. Column rename target hits (stage29c handoff)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| V1 | V2 | Table | File | Count |')
[void]$sb.AppendLine('|---|---|---|---|---:|')
foreach ($h in ($renameHits | Sort-Object v1, file)) {
    [void]$sb.AppendLine(('| `{0}` | `{1}` | {2} | `{3}` | {4} |' -f $h.v1, $h.v2, $h.tbl, $h.file, $h.count))
}
if ($renameHits.Count -eq 0) {
    [void]$sb.AppendLine('| (none) | | | | |')
}
[void]$sb.AppendLine('')

# Section 6: party_type direct refs
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## 6. `party_type` direct references')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Stage 29-c handoff: `parties.party_type` (enum) -> `party_type_id` (FK) requires manual P1-P7 JOIN pattern.')
[void]$sb.AppendLine("Total: $(($partyTypeHits | Measure-Object -Property count -Sum).Sum) refs in $($partyTypeHits.Count) files")
[void]$sb.AppendLine('')
if ($partyTypeHits.Count -gt 0) {
    [void]$sb.AppendLine('| File | Count |')
    [void]$sb.AppendLine('|---|---:|')
    foreach ($h in ($partyTypeHits | Sort-Object count -Descending)) {
        [void]$sb.AppendLine(('| `{0}` | {1} |' -f $h.file, $h.count))
    }
}
[void]$sb.AppendLine('')

# Section 7: detailed .from()/.rpc() sites (sample, first 50 each)
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## 7. `.from()` call sites (first 50)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| File | Line | Arg |')
[void]$sb.AppendLine('|---|---:|---|')
foreach ($c in ($fromCalls | Select-Object -First 50)) {
    [void]$sb.AppendLine(('| `{0}` | {1} | `{2}` |' -f $c.file, $c.line, $c.arg))
}
[void]$sb.AppendLine('')

if ($rpcCalls.Count -gt 0) {
    [void]$sb.AppendLine('## 8. `.rpc()` call sites (first 30)')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| File | Line | Arg |')
    [void]$sb.AppendLine('|---|---:|---|')
    foreach ($c in ($rpcCalls | Select-Object -First 30)) {
        [void]$sb.AppendLine(('| `{0}` | {1} | `{2}` |' -f $c.file, $c.line, $c.arg))
    }
    [void]$sb.AppendLine('')
}

# Save UTF-8 BOM
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), $utf8Bom)

$fi = Get-Item $outputFile
Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host "Report: $outputFile"
Write-Host "Size  : $($fi.Length) bytes"
Write-Host ''
Write-Host 'Summary:'
Write-Host ('  database.ts urm tables : {0}' -f $urmTableNames.Count)
Write-Host ('  .from() calls          : {0}' -f $fromCalls.Count)
Write-Host ('  .rpc() calls           : {0}' -f $rpcCalls.Count)
Write-Host ('  schema configs         : {0}' -f $schemaConfigs.Count)
Write-Host ('  rename target hits     : {0}' -f $renameHits.Count)
Write-Host ('  party_type direct refs : {0} files' -f $partyTypeHits.Count)
