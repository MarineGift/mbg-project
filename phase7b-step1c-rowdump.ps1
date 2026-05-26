# =============================================================================
# Phase 7-b Step 1-c: candidate table existence + column dump
# =============================================================================
# Tests the "table already exists, only column drift" hypothesis that surfaced
# after Step 1-b showed communications was already complete.
#
# For each of the 6 candidate tables, dump the Row block from database.ts.
# If absent --- DROP+RECREATE truly needed.
# If present --- compare columns to code usage (Step 1 results) for ALTER or no-op.
#
# Plus: probe sequence-processor for its function signature (the missing
# enrollment/step parent context from Step 1-b).
#
# Read-only. English-only (no BOM).
# =============================================================================

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\dev\mbg-project'

$dbPath = 'src\types\database.ts'
$content = Get-Content -LiteralPath $dbPath

$out = 'phase7b-step1c-output.md'
$lines = New-Object System.Collections.Generic.List[string]
function Add-Line { param([string]$s = '') $script:lines.Add($s) }

Add-Line '# Phase 7-b Step 1-c output'
Add-Line ('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ''
Add-Line 'Goal: confirm whether each candidate table EXISTS in database.ts.'
Add-Line 'If yes --- show its Row block so we can decide ALTER vs no-op.'
Add-Line 'If no --- DROP+RECREATE is truly needed.'
Add-Line ''

# Candidate tables --- 6 from handoff spec minus communications/email-attachments
$candidates = @(
    'org_members',
    'party_contacts',
    'email_signatures',
    'email_whitelist',
    'email_templates',
    'email_tracking',
    'email_tracking_events',
    'email_sequence_sends',
    'organizations',
    'drafts',
    'attachments'
)

function Find-RowBlock {
    param([string]$tableName)

    # Find any line matching `  <tableName>: {` at table-definition indent
    # (4-6 spaces typical inside Tables: { ... })
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match ('^\s{4,8}' + [regex]::Escape($tableName) + ':\s*\{\s*$')) {
            # Verify this is a table block (next nonblank line should be `Row: {`)
            for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $content.Length); $j++) {
                if ($content[$j] -match '^\s+Row:\s*\{') {
                    return @{ TableLine = $i; RowLine = $j }
                }
            }
        }
    }
    return $null
}

function Dump-RowColumns {
    param([int]$rowLineIdx)

    $cols = New-Object System.Collections.Generic.List[string]
    $depth = 0
    for ($i = $rowLineIdx; $i -lt $rowLineIdx + 200; $i++) {
        $line = $content[$i]
        $cols.Add(('L' + ($i + 1) + ': ' + $line))
        $opens = ([regex]::Matches($line, '\{')).Count
        $closes = ([regex]::Matches($line, '\}')).Count
        $depth += $opens - $closes
        if ($i -gt $rowLineIdx -and $depth -le 0) { break }
    }
    return $cols
}

# =============================================================================
# 1. Per-table existence check + Row dump
# =============================================================================
Add-Line '## 1. Candidate tables --- existence and columns'
Add-Line ''

$summary = New-Object System.Collections.Generic.List[string]
$summary.Add('| Table | Status | DB location | Action |')
$summary.Add('|---|---|---|---|')

foreach ($t in $candidates) {
    Add-Line ('### `' + $t + '`')
    Add-Line ''

    $found = Find-RowBlock -tableName $t
    if ($null -eq $found) {
        Add-Line '**Status: NOT FOUND in database.ts**'
        Add-Line ''
        Add-Line 'Action: DROP+CREATE (or first-time CREATE) is required.'
        Add-Line ''
        $summary.Add(('| `' + $t + '` | absent | --- | CREATE |'))
    } else {
        $tableLine = $found.TableLine + 1
        $rowLine = $found.RowLine + 1
        Add-Line ('**Status: FOUND at L' + $tableLine + ' (Row at L' + $rowLine + ')**')
        Add-Line ''
        Add-Line '```ts'
        $dump = Dump-RowColumns -rowLineIdx $found.RowLine
        foreach ($d in $dump) { Add-Line $d }
        Add-Line '```'
        Add-Line ''
        $summary.Add(('| `' + $t + '` | present | L' + $tableLine + ' | ALTER or no-op |'))
    }
}

Add-Line ''
Add-Line '## 2. Summary'
Add-Line ''
foreach ($s in $summary) { Add-Line $s }
Add-Line ''

# =============================================================================
# 3. sequence-processor.ts function signature
# =============================================================================
Add-Line '## 3. sequence-processor.ts function signature'
Add-Line ''
Add-Line 'Where does the `e` (enrollment-like) object come from? Probe the file head.'
Add-Line ''

$spPath = 'src\lib\utils\sequence-processor.ts'
if (Test-Path -LiteralPath $spPath) {
    Add-Line '### Imports and exported function signatures'
    Add-Line '```ts'
    $spContent = Get-Content -LiteralPath $spPath
    # Show first 120 lines (covers imports + types + main fn signature usually)
    for ($i = 0; $i -lt [Math]::Min(120, $spContent.Length); $i++) {
        Add-Line ('L' + ($i + 1) + ': ' + $spContent[$i])
    }
    Add-Line '```'
} else {
    Add-Line '(sequence-processor.ts not found)'
}
Add-Line ''

# =============================================================================
# 4. RPC functions that may return sequence/enrollment data
# =============================================================================
Add-Line '## 4. RPC calls anywhere mentioning sequence/enrollment'
Add-Line ''

$rpcHits = Get-ChildItem -Path 'src' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Select-String -Pattern "\.rpc\(['""]([^'""]*?(sequence|enrollment|send|due)[^'""]*?)['""]" -AllMatches

if ($rpcHits) {
    Add-Line '```'
    foreach ($h in $rpcHits) {
        foreach ($m in $h.Matches) {
            $rel = $h.Path -replace [regex]::Escape((Get-Location).Path + '\'), ''
            Add-Line ('- ' + $rel + ' L' + $h.LineNumber + ': rpc("' + $m.Groups[1].Value + '")')
        }
    }
    Add-Line '```'
} else {
    Add-Line '(none --- sequence runner is likely external worker or dead path)'
}
Add-Line ''

# =============================================================================
# Write output
# =============================================================================
$text = ($lines -join "`r`n")
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host ('Done. Output: ' + $out) -ForegroundColor Green
Write-Host ('Lines: ' + $lines.Count) -ForegroundColor Cyan
