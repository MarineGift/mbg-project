# =============================================================
# D6-5b-code-audit.ps1
# Comprehensive code audit for D6-5 cutover.
#
# Detects:
#   1. .schema('xxx') method-chain pattern uses
#   2. .from('table') uses (with/without 'as never' cast)
#   3. sbApp/sbUrm/sbAi/sbIndustry helper uses
#   4. References to columns renamed in D5/D6
#   5. Top files by combined reference count
#
# Output:
#   - Console summary (ASCII English only, PS 5.x CP949 safe)
#   - D6-5b-audit-report.md (UTF-8 BOM, in current directory)
#
# Usage (from repo root C:\dev\mbg-project):
#   .\D6-5b-code-audit.ps1
# =============================================================

$ErrorActionPreference = 'Stop'

# Sanity: must be at repo root with src/ directory
if (-not (Test-Path 'src' -PathType Container)) {
    Write-Host 'ERROR: src/ directory not found. Run this from the repo root.'
    exit 1
}

$repoRoot = (Resolve-Path .).Path
$reportPath = Join-Path $repoRoot 'D6-5b-audit-report.md'

# Common file collection (cached)
$srcFiles = Get-ChildItem -Recurse -Path src -Include *.ts, *.tsx -File

Write-Host ''
Write-Host '======================================'
Write-Host 'D6-5b Code Audit'
Write-Host ('Repo root: {0}' -f $repoRoot)
Write-Host ('Files scanned: {0} (.ts, .tsx under src/)' -f $srcFiles.Count)
Write-Host '======================================'
Write-Host ''

function To-RelPath {
    param([string]$AbsPath)
    return ($AbsPath.Substring($repoRoot.Length + 1) -replace '\\', '/')
}

# ---- 1. .schema() method-chain pattern ----
Write-Host '[1/5] Scanning .schema() method-chain pattern...'

$schemaCalls = $srcFiles | ForEach-Object {
    $file = $_
    Select-String -Path $file.FullName -Pattern "\.schema\(['""](\w+)['""]\)" -AllMatches |
        ForEach-Object {
            $line = $_
            foreach ($m in $line.Matches) {
                [pscustomobject]@{
                    file   = To-RelPath $file.FullName
                    line   = $line.LineNumber
                    schema = $m.Groups[1].Value
                    text   = $line.Line.Trim()
                }
            }
        }
}

$schemaByName = $schemaCalls | Group-Object schema | Sort-Object Count -Descending

Write-Host ('  Total: {0} calls' -f $schemaCalls.Count)
foreach ($g in $schemaByName) {
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    Write-Host ('    {0,-12} {1,5} calls in {2,3} files' -f $g.Name, $g.Count, $files)
}

# ---- 2. .from('table') pattern ----
Write-Host ''
Write-Host '[2/5] Scanning .from() table references...'

$fromCalls = $srcFiles | ForEach-Object {
    $file = $_
    Select-String -Path $file.FullName -Pattern "\.from\(['""](\w+)['""]" -AllMatches |
        ForEach-Object {
            $line = $_
            foreach ($m in $line.Matches) {
                $hasAsNever = $line.Line -match 'as\s+never'
                [pscustomobject]@{
                    file    = To-RelPath $file.FullName
                    line    = $line.LineNumber
                    table   = $m.Groups[1].Value
                    asNever = $hasAsNever
                    text    = $line.Line.Trim()
                }
            }
        }
}

$fromByTable = $fromCalls | Group-Object table | Sort-Object Count -Descending
$asNeverCount = ($fromCalls | Where-Object { $_.asNever }).Count

Write-Host ('  Total: {0} calls ({1} with "as never")' -f $fromCalls.Count, $asNeverCount)
Write-Host '  Top 10 tables:'
$fromByTable | Select-Object -First 10 | ForEach-Object {
    $asNever = ($_.Group | Where-Object { $_.asNever }).Count
    Write-Host ('    {0,-30} {1,5} calls ({2} as never)' -f $_.Name, $_.Count, $asNever)
}

# ---- 3. sb* helper uses ----
Write-Host ''
Write-Host '[3/5] Scanning sb* helper uses...'

$helperPattern = '\b(sbApp|sbUrm|sbAi|sbIndustry)\b'
$helperCalls = $srcFiles | ForEach-Object {
    $file = $_
    Select-String -Path $file.FullName -Pattern $helperPattern -AllMatches |
        ForEach-Object {
            $line = $_
            foreach ($m in $line.Matches) {
                [pscustomobject]@{
                    file   = To-RelPath $file.FullName
                    line   = $line.LineNumber
                    helper = $m.Value
                }
            }
        }
}

$helperByName = $helperCalls | Group-Object helper | Sort-Object Count -Descending

Write-Host ('  Total: {0} uses' -f $helperCalls.Count)
foreach ($g in $helperByName) {
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    Write-Host ('    {0,-12} {1,5} uses in {2,3} files' -f $g.Name, $g.Count, $files)
}

# ---- 4. Renamed column references ----
Write-Host ''
Write-Host '[4/5] Scanning references to D6-renamed columns...'

# Patterns specific enough to grep reliably:
$renamedPatterns = @(
    @{ pat = '\bbody_text\b';        renamedTo = 'body_plain';    phase = 'D5-2' },
    @{ pat = '\borg_id\b';           renamedTo = 'organization_id'; phase = 'D5-2' },
    @{ pat = '\bsupply_type\b';      renamedTo = 'link_type';     phase = 'D5-2' },
    @{ pat = '\bvolume_tpy\b';       renamedTo = 'volume_estimate'; phase = 'D5-2' }
)

$renamedHits = @()
foreach ($entry in $renamedPatterns) {
    $hits = $srcFiles | ForEach-Object {
        $file = $_
        Select-String -Path $file.FullName -Pattern $entry.pat |
            ForEach-Object {
                [pscustomobject]@{
                    pattern   = $entry.pat
                    renamedTo = $entry.renamedTo
                    phase     = $entry.phase
                    file      = To-RelPath $file.FullName
                    line      = $_.LineNumber
                    text      = $_.Line.Trim()
                }
            }
    }
    $renamedHits += $hits
}

$renamedByPattern = $renamedHits | Group-Object pattern | Sort-Object Count -Descending

Write-Host ('  Total: {0} hits across {1} patterns' -f $renamedHits.Count, $renamedPatterns.Count)
foreach ($g in $renamedByPattern) {
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    $renamedTo = ($g.Group | Select-Object -ExpandProperty renamedTo -First 1)
    Write-Host ('    {0,-20} -> {1,-20} : {2,4} hits in {3,3} files' -f $g.Name, $renamedTo, $g.Count, $files)
}

# ---- 5. Top files by total reference count ----
Write-Host ''
Write-Host '[5/5] Calculating top files by combined reference count...'

$allRefs = @()
$allRefs += $schemaCalls | Select-Object file
$allRefs += $fromCalls | Select-Object file
$allRefs += $helperCalls | Select-Object file
$allRefs += $renamedHits | Select-Object file

$topFiles = $allRefs | Group-Object file | Sort-Object Count -Descending | Select-Object -First 20

Write-Host '  Top 20 files (highest = highest cutover priority):'
foreach ($f in $topFiles) {
    Write-Host ('    {0,5}  {1}' -f $f.Count, $f.Name)
}

# ---- Write detailed .md report ----
Write-Host ''
Write-Host 'Writing detailed report to D6-5b-audit-report.md...'

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine('# D6-5b Code Audit Report')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$null = $sb.AppendLine('Files scanned: ' + $srcFiles.Count + ' (.ts, .tsx under src/)')
$null = $sb.AppendLine('')

# Section 1
$null = $sb.AppendLine('## 1. `.schema()` method-chain pattern')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Pattern: `.schema(''xxx'')` — method-chain style. D5-1 audit missed these.')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| schema | call count | unique files |')
$null = $sb.AppendLine('|---|---:|---:|')
foreach ($g in $schemaByName) {
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    $null = $sb.AppendLine(('| `{0}` | {1} | {2} |' -f $g.Name, $g.Count, $files))
}
$null = $sb.AppendLine('')
$null = $sb.AppendLine('### Detail rows')
$null = $sb.AppendLine('')
foreach ($g in $schemaByName) {
    $null = $sb.AppendLine(('#### schema=`{0}`' -f $g.Name))
    $null = $sb.AppendLine('')
    foreach ($r in ($g.Group | Sort-Object file, line)) {
        $null = $sb.AppendLine(('- `{0}:{1}`' -f $r.file, $r.line))
    }
    $null = $sb.AppendLine('')
}

# Section 2
$null = $sb.AppendLine('## 2. `.from()` table references')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(('Total: {0} calls ({1} with `as never` cast)' -f $fromCalls.Count, $asNeverCount))
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Note: only matches `.from(''xxx'')` with string literal. Calls like `.from(tableVar)` are not captured.')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| table | total | as_never | unique files |')
$null = $sb.AppendLine('|---|---:|---:|---:|')
foreach ($g in $fromByTable) {
    $asNever = ($g.Group | Where-Object { $_.asNever }).Count
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    $null = $sb.AppendLine(('| `{0}` | {1} | {2} | {3} |' -f $g.Name, $g.Count, $asNever, $files))
}
$null = $sb.AppendLine('')

# Section 3
$null = $sb.AppendLine('## 3. `sb*()` helper uses')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Helpers from `src/lib/supabase/schema-helpers.ts` (D5-3d).')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| helper | call count | unique files |')
$null = $sb.AppendLine('|---|---:|---:|')
foreach ($g in $helperByName) {
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    $null = $sb.AppendLine(('| `{0}` | {1} | {2} |' -f $g.Name, $g.Count, $files))
}
$null = $sb.AppendLine('')

# Section 4
$null = $sb.AppendLine('## 4. References to renamed columns')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Columns renamed during D5-2. Non-zero hits indicate incomplete migration.')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| pattern | renamed to | phase | hits | unique files |')
$null = $sb.AppendLine('|---|---|---|---:|---:|')
foreach ($g in $renamedByPattern) {
    $files = ($g.Group | Select-Object -ExpandProperty file -Unique | Measure-Object).Count
    $renamedTo = ($g.Group | Select-Object -ExpandProperty renamedTo -First 1)
    $phase = ($g.Group | Select-Object -ExpandProperty phase -First 1)
    $null = $sb.AppendLine(('| `{0}` | `{1}` | {2} | {3} | {4} |' -f $g.Name, $renamedTo, $phase, $g.Count, $files))
}
$null = $sb.AppendLine('')

if ($renamedHits.Count -gt 0) {
    $null = $sb.AppendLine('### Detail rows')
    $null = $sb.AppendLine('')
    foreach ($g in $renamedByPattern) {
        $null = $sb.AppendLine(('#### pattern=`{0}`' -f $g.Name))
        $null = $sb.AppendLine('')
        foreach ($r in ($g.Group | Sort-Object file, line)) {
            $null = $sb.AppendLine(('- `{0}:{1}`' -f $r.file, $r.line))
        }
        $null = $sb.AppendLine('')
    }
}

$null = $sb.AppendLine('Notes:')
$null = $sb.AppendLine('- `name` (parties.name -> party_name) and `party_type` (enum -> party_type_id smallint FK) are too generic to grep safely. Review parties-related files manually.')
$null = $sb.AppendLine('- D6-5a added `tier_id`, `interest_tags`, and `industry_tags` (via relation table) — code must be updated to use these instead of legacy `tier`, `interest_tags` (text[]), `industry_tags` (text[]).')
$null = $sb.AppendLine('')

# Section 5
$null = $sb.AppendLine('## 5. Top 30 files by combined reference count')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('Combined = `.schema()` + `.from()` + `sb*()` + renamed-column hits. Use this ranking to choose cutover order (highest first = biggest impact).')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| refs | file |')
$null = $sb.AppendLine('|---:|---|')
$topFiles30 = $allRefs | Group-Object file | Sort-Object Count -Descending | Select-Object -First 30
foreach ($f in $topFiles30) {
    $null = $sb.AppendLine(('| {0} | `{1}` |' -f $f.Count, $f.Name))
}
$null = $sb.AppendLine('')

$null = $sb.AppendLine('---')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Summary')
$null = $sb.AppendLine('')
$null = $sb.AppendLine(('- `.schema()` calls: **{0}**' -f $schemaCalls.Count))
$null = $sb.AppendLine(('- `.from()` calls: **{0}** ({1} with `as never`)' -f $fromCalls.Count, $asNeverCount))
$null = $sb.AppendLine(('- `sb*()` helper uses: **{0}**' -f $helperCalls.Count))
$null = $sb.AppendLine(('- Renamed column hits: **{0}**' -f $renamedHits.Count))

# Write UTF-8 with BOM
$utf8WithBom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllText($reportPath, $sb.ToString(), $utf8WithBom)

Write-Host ''
Write-Host '======================================'
Write-Host ('Report written: {0}' -f $reportPath)
Write-Host '======================================'
Write-Host ''
Write-Host 'Quick stats:'
Write-Host ('  .schema()       : {0} calls' -f $schemaCalls.Count)
Write-Host ('  .from()         : {0} calls ({1} as never)' -f $fromCalls.Count, $asNeverCount)
Write-Host ('  sb*() helpers   : {0} uses' -f $helperCalls.Count)
Write-Host ('  renamed columns : {0} hits' -f $renamedHits.Count)
Write-Host ''
Write-Host 'Share the report file contents back to plan D6-5c onwards.'
