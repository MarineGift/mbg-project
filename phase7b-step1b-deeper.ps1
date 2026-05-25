# =============================================================================
# Phase 7-b Step 1-b: targeted follow-up grep
# =============================================================================
# Closes 4 gaps surfaced by Step 1:
#   1. Find email_sequences / enrollments / steps tables (parents of
#      email_sequence_sends) anywhere in src/
#   2. Show context around .from("email-attachments") to verify the hyphen
#   3. Dump the CURRENT `communications` Row block from database.ts so we can
#      diff against the code's expected columns
#   4. Confirm whether `industry` schema appears in database.ts at all
#
# Read-only. English-only messages (no BOM required).
# =============================================================================

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\dev\mbg-project'

$out = 'phase7b-step1b-output.md'
$lines = New-Object System.Collections.Generic.List[string]
function Add-Line { param([string]$s = '') $script:lines.Add($s) }

Add-Line '# Phase 7-b Step 1-b output'
Add-Line ('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ''

# =============================================================================
# 1. Find references to sequence parent tables across src/
# =============================================================================
Add-Line '## 1. Sequence parent tables (email_sequences / enrollments / steps)'
Add-Line ''
Add-Line 'Looking for any `.from("name")` or `Tables<"name">` references whose'
Add-Line 'name matches the sequence family across the whole src/ tree.'
Add-Line ''

$seqPattern = '(\.from\(|Tables(Insert|Update)?<)["'']' +
              '(email_sequences?|sequences?|enrollments?|sequence_steps?|email_sequence_steps?|email_enrollments?|sequence_enrollments?)' +
              '["'']'

$seqHits = Get-ChildItem -Path 'src' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Select-String -Pattern $seqPattern -AllMatches

if ($seqHits) {
    $byFile = $seqHits | Group-Object Path
    foreach ($g in $byFile) {
        Add-Line ('### ' + ($g.Name -replace [regex]::Escape((Get-Location).Path + '\'), ''))
        Add-Line '```ts'
        foreach ($h in $g.Group) {
            Add-Line ('L' + $h.LineNumber + ': ' + $h.Line.Trim())
        }
        Add-Line '```'
        Add-Line ''
    }
} else {
    Add-Line '(no references found --- sequence enrollment/step lookups may live elsewhere)'
    Add-Line ''
}

# =============================================================================
# 2. Context around .from("email-attachments")
# =============================================================================
Add-Line '## 2. email-attachments (verify hyphen vs underscore)'
Add-Line ''

$attachHits = Get-ChildItem -Path 'src' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Select-String -Pattern '(email-attachments|email_attachments)' -Context 2,2

if ($attachHits) {
    foreach ($h in $attachHits) {
        Add-Line ('### ' + ($h.Path -replace [regex]::Escape((Get-Location).Path + '\'), '') + ' (L' + $h.LineNumber + ')')
        Add-Line '```ts'
        foreach ($pre in $h.Context.PreContext) { Add-Line $pre }
        Add-Line ('> ' + $h.Line)
        foreach ($post in $h.Context.PostContext) { Add-Line $post }
        Add-Line '```'
        Add-Line ''
    }
} else {
    Add-Line '(no matches)'
    Add-Line ''
}

# =============================================================================
# 3. Dump current `communications` Row block from database.ts
# =============================================================================
Add-Line '## 3. Current `app.communications` Row type (from database.ts)'
Add-Line ''

$dbPath = 'src\types\database.ts'

# Find the start: a line containing `communications: {` after the `app:` schema header (L609)
# We will scan from L609 onward and locate `communications: {`, then grab the next ~80 lines.
$content = Get-Content -LiteralPath $dbPath
$appStart = 609 - 1  # zero-indexed
$commLine = $null

for ($i = $appStart; $i -lt [Math]::Min($appStart + 1500, $content.Length); $i++) {
    if ($content[$i] -match '^\s+communications:\s*\{') {
        $commLine = $i
        break
    }
}

if ($null -ne $commLine) {
    Add-Line ('Found `communications: {` at L' + ($commLine + 1) + '. Dumping the Row block:')
    Add-Line ''
    Add-Line '```ts'

    # Walk forward until we find "Row: {" then dump until matching close
    $rowStart = $null
    for ($i = $commLine; $i -lt $commLine + 200; $i++) {
        if ($content[$i] -match '^\s+Row:\s*\{') {
            $rowStart = $i
            break
        }
    }

    if ($null -ne $rowStart) {
        $depth = 0
        for ($i = $rowStart; $i -lt $rowStart + 200; $i++) {
            $line = $content[$i]
            Add-Line ('L' + ($i + 1) + ': ' + $line)
            # Track braces to find end of Row block
            $opens = ([regex]::Matches($line, '\{')).Count
            $closes = ([regex]::Matches($line, '\}')).Count
            $depth += $opens - $closes
            if ($i -gt $rowStart -and $depth -le 0) { break }
        }
    } else {
        Add-Line '(Row block not found within 200 lines of communications: { --- inspect manually)'
    }

    Add-Line '```'
} else {
    Add-Line '(`communications: {` not found in app schema --- table absent from database.ts)'
}
Add-Line ''

# =============================================================================
# 4. Confirm whether `industry` schema appears in database.ts
# =============================================================================
Add-Line '## 4. `industry` schema in database.ts'
Add-Line ''

$industryHits = Select-String -LiteralPath $dbPath -Pattern '\bindustry\b'
if ($industryHits) {
    Add-Line ('Matches: ' + $industryHits.Count)
    Add-Line ''
    Add-Line '```'
    foreach ($h in $industryHits) {
        Add-Line ('L' + $h.LineNumber + ': ' + $h.Line.Trim())
    }
    Add-Line '```'
} else {
    Add-Line '(zero matches --- `industry` schema is completely absent from database.ts)'
    Add-Line ''
    Add-Line 'This is almost certainly the source of the 560-line augmentation gap:'
    Add-Line 'the live DB has an `industry` schema (~3,200 rows of paper-filler data)'
    Add-Line 'but the regen flags omitted it.'
    Add-Line ''
    Add-Line 'Fix at Step 3 regen by using:'
    Add-Line "    supabase gen types typescript --linked --schema 'public,app,urm,industry'"
}
Add-Line ''

# =============================================================================
# 5. Bonus: Look for any other table name patterns we may have missed
# =============================================================================
Add-Line '## 5. All `.from("...")` calls in src/lib (broader scan)'
Add-Line ''
Add-Line 'Union of every table touched anywhere under src/lib/.'
Add-Line ''

$allFromHits = Get-ChildItem -Path 'src\lib' -Recurse -Include '*.ts','*.tsx' -ErrorAction SilentlyContinue |
    Select-String -Pattern "\.from\(['""]([^'""]+)['""]\)" -AllMatches

$allTables = New-Object System.Collections.Generic.HashSet[string]
foreach ($h in $allFromHits) {
    foreach ($m in $h.Matches) { [void]$allTables.Add($m.Groups[1].Value) }
}

Add-Line ('Distinct tables: ' + $allTables.Count)
Add-Line ''
Add-Line '```'
foreach ($t in ($allTables | Sort-Object)) { Add-Line ('- ' + $t) }
Add-Line '```'

# =============================================================================
# Write output
# =============================================================================
$text = ($lines -join "`r`n")
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host ('Done. Output: ' + $out) -ForegroundColor Green
Write-Host ('Lines: ' + $lines.Count) -ForegroundColor Cyan
