# =============================================================================
# Phase 7-b: database.ts manual augmentation trace
# =============================================================================
# Goal: identify the ~570 lines that exist in database.ts beyond what
# `supabase gen types` would produce, so Step 3 regen does not lose them.
#
# Read-only on source. Writes one report file. English messages only.
# =============================================================================

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\dev\mbg-project'

$target = 'src\types\database.ts'
$out    = 'database-ts-augmentation-trace.md'

if (-not (Test-Path -LiteralPath $target)) {
    Write-Host ('Missing: ' + $target) -ForegroundColor Red
    exit 1
}

$lines = New-Object System.Collections.Generic.List[string]
function Add-Line { param([string]$s = '') $script:lines.Add($s) }

Add-Line '# database.ts manual augmentation trace'
Add-Line ('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ''

# --- 1. Size baseline ---------------------------------------------------------
$total = (Get-Content -LiteralPath $target | Measure-Object -Line).Lines
Add-Line '## 1. Current size'
Add-Line ''
Add-Line ('- file: `' + $target + '`')
Add-Line ('- lines: ' + $total)
Add-Line ('- expected from `supabase gen types`: ~12,072')
Add-Line ('- gap to explain: ~' + ($total - 12072))
Add-Line ''

# --- 2. Schema sections (top-level Database['<schema>']) ---------------------
Add-Line '## 2. Schema sections present'
Add-Line ''
Add-Line 'Top-level schema keys appearing in the Database type tree.'
Add-Line ''
Add-Line '```'
# Match lines like `  public: {` `  app: {` `  urm: {` `  industry: {` at modest indent
$schemaHits = Select-String -LiteralPath $target -Pattern "^\s{2,4}(public|app|urm|industry|auth|storage|graphql_public|realtime|extensions|net|pgsodium|vault)\s*:\s*\{"
foreach ($h in $schemaHits) {
    Add-Line ('L' + $h.LineNumber + ': ' + $h.Line.Trim())
}
Add-Line '```'
Add-Line ''

# --- 3. Suspicious markers that often flag manual edits ----------------------
Add-Line '## 3. Manual-edit markers'
Add-Line ''
Add-Line '```'
$markerHits = Select-String -LiteralPath $target -Pattern '(?i)(manual|augment|hack|todo|fixme|hand-?written|hand-?added|patched|workaround|do not regen)' -AllMatches
if ($markerHits) {
    foreach ($h in $markerHits) {
        Add-Line ('L' + $h.LineNumber + ': ' + $h.Line.Trim())
    }
} else {
    Add-Line '(none found --- augmentation is undocumented)'
}
Add-Line '```'
Add-Line ''

# --- 4. Top-level exports beyond the Database type ---------------------------
Add-Line '## 4. Top-level exports'
Add-Line ''
Add-Line '`supabase gen types` produces ONE top-level export (`Database`) plus a fixed set'
Add-Line 'of helper aliases (`Tables`, `TablesInsert`, etc.). Anything else here is manual.'
Add-Line ''
Add-Line '```'
$exportHits = Select-String -LiteralPath $target -Pattern '^\s*export\s+(type|interface|const|function|class|enum)\s+\w+'
foreach ($h in $exportHits) {
    Add-Line ('L' + $h.LineNumber + ': ' + $h.Line.Trim())
}
Add-Line '```'
Add-Line ''

# --- 5. RPC functions surface (the Functions block per schema) ---------------
Add-Line '## 5. Functions / RPC blocks'
Add-Line ''
Add-Line '`Functions: { ... }` keys per schema are a common manual-augmentation target'
Add-Line 'when the regen output omits or under-types an RPC.'
Add-Line ''
Add-Line '```'
$fnHits = Select-String -LiteralPath $target -Pattern '^\s+Functions:\s*\{'
foreach ($h in $fnHits) {
    Add-Line ('L' + $h.LineNumber + ': (Functions block start)')
}
Add-Line '```'
Add-Line ''

# --- 6. Recent commits touching the file -------------------------------------
Add-Line '## 6. Recent commits touching database.ts (last 30)'
Add-Line ''
Add-Line '```'
$log = git log --oneline -30 -- src/types/database.ts 2>$null
if ($log) {
    foreach ($l in $log) { Add-Line $l }
} else {
    Add-Line '(git log returned empty --- run in a working git repo)'
}
Add-Line '```'
Add-Line ''

# --- 7. Diff stats on those commits ------------------------------------------
Add-Line '## 7. Diff stats per commit (last 30)'
Add-Line ''
Add-Line 'Big +line counts on isolated commits often indicate manual augmentation events.'
Add-Line ''
Add-Line '```'
$shortStats = git log --pretty=format:'%h %s' --shortstat -30 -- src/types/database.ts 2>$null
if ($shortStats) {
    foreach ($l in $shortStats) { Add-Line $l }
} else {
    Add-Line '(no diff stats available)'
}
Add-Line '```'
Add-Line ''

# --- 8. Suggested next step --------------------------------------------------
Add-Line '## 8. Suggested triage'
Add-Line ''
Add-Line '1. Run a clean regen into a side file (do NOT overwrite):'
Add-Line '   ```powershell'
Add-Line '   supabase gen types typescript --linked --schema ''public,app,urm,industry'' > src\types\database.regen.ts'
Add-Line '   ```'
Add-Line '2. Diff:'
Add-Line '   ```powershell'
Add-Line '   git --no-pager diff --no-index --stat src\types\database.regen.ts src\types\database.ts'
Add-Line '   ```'
Add-Line '3. For every block present in `database.ts` but absent in `database.regen.ts`,'
Add-Line '   decide:'
Add-Line '   - Is it a missing schema in the regen flags? --- fix the `--schema` arg.'
Add-Line '   - Is it a hand-typed RPC? --- preserve it (port into a sibling file or comment).'
Add-Line '   - Is it dead? --- drop it.'
Add-Line ''
Add-Line '4. Only after the augmentation surface is catalogued should Step 3 regen run.'
Add-Line ''

# --- write -------------------------------------------------------------------
$text = ($lines -join "`r`n")
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host ('Done. Output: ' + $out) -ForegroundColor Green
Write-Host ('Lines: ' + $lines.Count) -ForegroundColor Cyan
