# =============================================================================
# Phase 7-b Step 1: schema usage extraction from email/sequence/communications
# =============================================================================
# Output: phase7b-step1-output.md (read-only on source, idempotent on output)
# All messages in English so this .ps1 does NOT require BOM.
# =============================================================================

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'C:\dev\mbg-project'

$files = @(
    'src\lib\actions\email-compose.ts',
    'src\lib\actions\email-sequences.ts',
    'src\lib\actions\email-whitelist.ts',
    'src\lib\queries\email-signatures.ts',
    'src\lib\queries\email-tracking.ts',
    'src\lib\queries\communications.ts',
    'src\lib\utils\sequence-processor.ts'
)

# --- Sanity check ---
$missing = $files | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missing) {
    Write-Host 'Missing files:' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

$out = 'phase7b-step1-output.md'
$lines = New-Object System.Collections.Generic.List[string]

function Add-Line { param([string]$s = '') $script:lines.Add($s) }

Add-Line "# Phase 7-b Step 1 output"
Add-Line ('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ''
Add-Line ('Files scanned: ' + $files.Count)
foreach ($f in $files) { Add-Line ('- ' + $f) }
Add-Line ''

# =============================================================================
# Section 1: .from('table') --- which tables each file touches
# =============================================================================
Add-Line '## 1. Tables referenced (.from)'
Add-Line ''

$allTables = New-Object System.Collections.Generic.HashSet[string]

foreach ($f in $files) {
    $hits = Select-String -LiteralPath $f -Pattern "\.from\(['""]([^'""]+)['""]\)" -AllMatches
    if ($hits) {
        $tables = @()
        foreach ($h in $hits) {
            foreach ($m in $h.Matches) {
                $t = $m.Groups[1].Value
                $tables += $t
                [void]$allTables.Add($t)
            }
        }
        $tables = $tables | Sort-Object -Unique
        Add-Line ('### ' + $f)
        foreach ($t in $tables) { Add-Line ('- `' + $t + '`') }
        Add-Line ''
    }
}

Add-Line '### Union of all tables touched'
foreach ($t in ($allTables | Sort-Object)) { Add-Line ('- `' + $t + '`') }
Add-Line ''

# =============================================================================
# Section 2: .insert / .update / .upsert --- payload context
# (capture the call line + 12 trailing lines so the object literal is visible)
# =============================================================================
Add-Line '## 2. Insert / Update / Upsert payloads (with context)'
Add-Line ''

foreach ($f in $files) {
    $hits = Select-String -LiteralPath $f -Pattern "\.(insert|update|upsert)\(" -Context 0,12
    if ($hits) {
        Add-Line ('### ' + $f)
        Add-Line '```ts'
        foreach ($h in $hits) {
            Add-Line ('// L' + $h.LineNumber + '  (' + ($h.Line.Trim()) + ')')
            foreach ($post in $h.Context.PostContext) {
                Add-Line $post
                if ($post -match '^\s*\}\s*\)' -or $post -match '^\s*\)\s*$') { break }
            }
            Add-Line ''
        }
        Add-Line '```'
        Add-Line ''
    }
}

# =============================================================================
# Section 3: filter columns --- .eq / .neq / .in / .match / .gt / .lt / etc.
# These are the strongest signal for FK targets and likely indexes.
# =============================================================================
Add-Line '## 3. Filter columns (FK / index candidates)'
Add-Line ''

$filterMethods = 'eq|neq|in|match|gt|lt|gte|lte|like|ilike|is|contains|containedBy'

foreach ($f in $files) {
    $hits = Select-String -LiteralPath $f -Pattern ("\.(" + $filterMethods + ")\(['""]([^'""]+)['""]") -AllMatches
    if ($hits) {
        $pairs = New-Object System.Collections.Generic.List[string]
        foreach ($h in $hits) {
            foreach ($m in $h.Matches) {
                $pairs.Add(($m.Groups[1].Value + "('" + $m.Groups[2].Value + "')"))
            }
        }
        $pairs = $pairs | Sort-Object -Unique
        Add-Line ('### ' + $f)
        foreach ($p in $pairs) { Add-Line ('- `' + $p + '`') }
        Add-Line ''
    }
}

# =============================================================================
# Section 4: explicit .select('col1, col2, ...') and .order('col')
# Single-arg .select() lists the exact read columns --- gold for column spec.
# =============================================================================
Add-Line '## 4. Explicit select / order'
Add-Line ''

foreach ($f in $files) {
    $selHits = Select-String -LiteralPath $f -Pattern "\.select\(\s*[`"'``]([^`"'``]+)[`"'``]" -AllMatches
    $ordHits = Select-String -LiteralPath $f -Pattern "\.order\(['""]([^'""]+)['""]" -AllMatches

    if ($selHits -or $ordHits) {
        Add-Line ('### ' + $f)

        if ($selHits) {
            Add-Line '**select:**'
            Add-Line '```ts'
            foreach ($h in $selHits) {
                foreach ($m in $h.Matches) {
                    Add-Line ('L' + $h.LineNumber + ': ' + $m.Groups[1].Value)
                }
            }
            Add-Line '```'
        }

        if ($ordHits) {
            Add-Line '**order:**'
            $ords = @()
            foreach ($h in $ordHits) {
                foreach ($m in $h.Matches) { $ords += $m.Groups[1].Value }
            }
            $ords = $ords | Sort-Object -Unique
            foreach ($c in $ords) { Add-Line ('- `' + $c + '`') }
        }
        Add-Line ''
    }
}

# =============================================================================
# Section 5: type references --- Tables<'x'>, TablesInsert<'x'>, etc.
# Helps confirm the schema-side name that code thinks the table has.
# =============================================================================
Add-Line '## 5. Type references (Tables<...>, TablesInsert<...>, etc.)'
Add-Line ''

$typePattern = "(Tables(Insert|Update)?<['""]([^'""]+)['""]>|Database\[['""]app['""]\]\[['""]Tables['""]\]\[['""]([^'""]+)['""]\])"

foreach ($f in $files) {
    $hits = Select-String -LiteralPath $f -Pattern $typePattern -AllMatches
    if ($hits) {
        Add-Line ('### ' + $f)
        Add-Line '```ts'
        foreach ($h in $hits) {
            Add-Line ('L' + $h.LineNumber + ': ' + $h.Line.Trim())
        }
        Add-Line '```'
        Add-Line ''
    }
}

# =============================================================================
# Section 6: rpc() calls --- captures any RPC the code expects to exist
# (these need to survive schema rebuild)
# =============================================================================
Add-Line '## 6. rpc() calls'
Add-Line ''

foreach ($f in $files) {
    $hits = Select-String -LiteralPath $f -Pattern "\.rpc\(['""]([^'""]+)['""]" -AllMatches
    if ($hits) {
        Add-Line ('### ' + $f)
        foreach ($h in $hits) {
            foreach ($m in $h.Matches) {
                Add-Line ('- L' + $h.LineNumber + ': `' + $m.Groups[1].Value + '`')
            }
        }
        Add-Line ''
    }
}

# =============================================================================
# Write output (UTF-8 no BOM --- markdown does not need it)
# =============================================================================
$text = ($lines -join "`r`n")
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host ('Done. Output: ' + $out) -ForegroundColor Green
Write-Host ('Line count: ' + $lines.Count) -ForegroundColor Cyan
Write-Host ''
Write-Host 'Next: open the file and consolidate into the Step 2 schema spec.' -ForegroundColor Yellow
