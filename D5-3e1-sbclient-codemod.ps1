# D5-3e1 codemod: .schema('xxx') -> sbXxx() helpers (PS 5.x safe, ASCII)
#
# Converts inline schema-scoped calls (audit Section 2's 10 sites) to use the
# new schema-helpers introduced in D5-3d. Adds import statement automatically
# (only for helpers actually used in each file).
#
# Whitelist: 6 files from D5-1 audit Section 2.
# Each `.schema('app')` -> `sbApp(<var>)`, `.schema('ai')` -> `sbAi(<var>)`.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   .\D5-3e1-sbclient-codemod.ps1            # dry-run (default)
#   .\D5-3e1-sbclient-codemod.ps1 -Apply     # write changes + .bak files

param([switch]$Apply)

$ErrorActionPreference = 'Continue'

$projectRoot = 'C:\dev\mbg-project'
$bakSuffix   = '.D5-3e1-' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak'
$helperPath  = "'@/lib/supabase/schema-helpers'"

# Whitelist (audit Section 2)
$targets = @(
    'src\app\actions\calendar-sync.ts',
    'src\app\actions\delete-communication.ts',
    'src\app\actions\delete-task.ts',
    'src\components\providers\realtime-provider.tsx',
    'src\lib\calendar\sync-engine.ts',
    'src\lib\calendar\token-crypto.ts'
)

# Pattern: (varname).schema('schemaName')
# \x27 = apostrophe, \x22 = double-quote
$patSchema = '([\w$]+)\.schema\(\s*[\x27\x22](\w+)[\x27\x22]\s*\)'

# Header
Write-Host '=== D5-3e1 sbclient codemod ===' -ForegroundColor Cyan
if ($Apply) {
    Write-Host 'Mode: APPLY' -ForegroundColor Yellow
    Write-Host "Backup suffix: $bakSuffix"
} else {
    Write-Host 'Mode: DRY-RUN (no files modified). Re-run with -Apply to commit.' -ForegroundColor DarkGreen
}
Write-Host ''

$totalPlanned = 0
$totalApplied = 0
$totalImports = 0

foreach ($rel in $targets) {
    $full = Join-Path $projectRoot $rel
    Write-Host ('--- ' + $rel + ' ---') -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $full)) {
        Write-Host '  [MISS] file not found' -ForegroundColor DarkGray
        continue
    }

    $content = [System.IO.File]::ReadAllText($full)
    $matches = [regex]::Matches($content, $patSchema)

    if ($matches.Count -eq 0) {
        Write-Host '  [SKIP] 0 .schema(...) calls' -ForegroundColor DarkGray
        continue
    }

    # Plan replacements + collect helpers used
    $usedHelpers = New-Object System.Collections.Generic.HashSet[string]
    $replacements = New-Object System.Collections.ArrayList

    foreach ($m in $matches) {
        $orig    = $m.Value
        $varName = $m.Groups[1].Value
        $schName = $m.Groups[2].Value

        # Map schema name -> helper name (sbApp / sbUrm / sbAi / sbIndustry)
        if ($schName -eq 'app')      { $helper = 'sbApp' }
        elseif ($schName -eq 'urm')  { $helper = 'sbUrm' }
        elseif ($schName -eq 'ai')   { $helper = 'sbAi' }
        elseif ($schName -eq 'industry') { $helper = 'sbIndustry' }
        else {
            Write-Host ("  [WARN] unknown schema '" + $schName + "', skipping match") -ForegroundColor DarkYellow
            continue
        }

        $newCall = $helper + '(' + $varName + ')'
        $lineNum = ($content.Substring(0, $m.Index) -split "`n").Count
        [void]$replacements.Add([pscustomobject]@{
            line = $lineNum; orig = $orig; new = $newCall; helper = $helper
        })
        [void]$usedHelpers.Add($helper)
    }

    if ($replacements.Count -eq 0) {
        Write-Host '  [SKIP] no actionable replacements' -ForegroundColor DarkGray
        continue
    }

    Write-Host ('  [PLAN] ' + $replacements.Count + ' replacements, helpers needed: ' + (($usedHelpers | Sort-Object) -join ', '))
    foreach ($r in $replacements) {
        Write-Host ('    line ' + $r.line + ' : ' + $r.orig + '   ->   ' + $r.new)
    }

    # Build new content via String.Replace (safe, since each match is unique)
    $newContent = $content
    foreach ($r in $replacements) {
        # Only replace first occurrence per pass (in case same .schema() string repeats)
        $idx = $newContent.IndexOf($r.orig)
        if ($idx -ge 0) {
            $newContent = $newContent.Substring(0, $idx) + $r.new + $newContent.Substring($idx + $r.orig.Length)
        }
    }

    # Add import if missing
    $importNeeded = $false
    if ($newContent -notmatch [regex]::Escape('schema-helpers')) {
        $importHelpers = ($usedHelpers | Sort-Object) -join ', '
        $importLine = 'import { ' + $importHelpers + ' } from ' + $helperPath + ';'

        # Find first import line and insert before it
        $firstImport = [regex]::Match($newContent, '(?m)^import\s')
        if ($firstImport.Success) {
            $newContent = $newContent.Substring(0, $firstImport.Index) + $importLine + "`r`n" + $newContent.Substring($firstImport.Index)
        } else {
            # No imports at all (unusual) -- prepend at top
            $newContent = $importLine + "`r`n" + $newContent
        }
        $importNeeded = $true
        Write-Host ('  [IMPORT] adding: ' + $importLine) -ForegroundColor Green
    } else {
        Write-Host '  [IMPORT] already present, skipping add' -ForegroundColor DarkGray
    }

    $totalPlanned += $replacements.Count
    if ($importNeeded) { $totalImports++ }

    if ($Apply) {
        # Backup
        $bak = $full + $bakSuffix
        Copy-Item -LiteralPath $full -Destination $bak -Force

        # Write UTF-8 without BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($full, $newContent, $utf8NoBom)
        $totalApplied += $replacements.Count
        Write-Host ('  [APPLIED] backup: ' + (Split-Path $bak -Leaf)) -ForegroundColor Green
    }
    Write-Host ''
}

# Summary
Write-Host '=== Summary ===' -ForegroundColor Cyan
Write-Host ('Files processed         : ' + $targets.Count)
Write-Host ('Planned replacements    : ' + $totalPlanned)
Write-Host ('Files needing import    : ' + $totalImports)
if ($Apply) {
    Write-Host ('Applied replacements    : ' + $totalApplied) -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next steps:'
    Write-Host '  1. git diff src\'
    Write-Host '  2. npx tsc --noEmit 2>&1 | Select-String "error TS" | Measure-Object'
    Write-Host '  3. If clean, commit. If broken, restore from .bak files.'
    Write-Host ''
    Write-Host 'Rollback (single file):'
    Write-Host ('  Copy-Item <file>' + $bakSuffix + ' <file> -Force')
} else {
    Write-Host ''
    Write-Host 'To commit changes: rerun with -Apply' -ForegroundColor Yellow
    Write-Host '  .\D5-3e1-sbclient-codemod.ps1 -Apply'
}
