# =============================================================
# D6-5c-3-urm-to-app.ps1
#
# Mechanical replace: all .schema('urm' ...) calls -> .schema('app')
# Plus deletion of obsolete factories-urm.ts.
#
# Rationale: D6-2/3/4 absorbed all urm.* tables into app.* schema.
# urm code calls are now compilation errors after dropping 'urm' from
# the types generation. The data is at app schema now, so the rewrite
# is semantically equivalent.
#
# Workflow:
#   1. Run without flag (DRY RUN) to preview changes
#   2. Re-run with -Apply to execute (no interactive prompt this time —
#      changes are reversible via git checkout)
#   3. Run tsc afterward to verify
#
# Target files (8) + 1 deletion:
#   src/app/(app)/page.tsx                       (1 hit)
#   src/lib/actions/engagements.ts               (7 hits)
#   src/lib/queries/draft-detail.ts              (1 hit)
#   src/lib/queries/drafts.ts                    (1 hit)
#   src/lib/queries/engagements.ts               (5 hits)
#   src/lib/queries/party-detail.ts              (1 hit)
#   src/lib/queries/pipelines.ts                 (1 hit)
#   src/lib/supabase/schema-helpers.ts           (1 hit) -- sbUrm function body
#   src/lib/supabase/factories-urm.ts            DELETE
# =============================================================

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$DryRun = -not $Apply

if (-not (Test-Path 'src' -PathType Container)) {
    Write-Host 'ERROR: src/ directory not found. Run from C:\dev\mbg-project.'
    exit 1
}

# Target files (use -LiteralPath for paths with brackets)
$targets = @(
    'src/app/(app)/page.tsx',
    'src/lib/actions/engagements.ts',
    'src/lib/queries/draft-detail.ts',
    'src/lib/queries/drafts.ts',
    'src/lib/queries/engagements.ts',
    'src/lib/queries/party-detail.ts',
    'src/lib/queries/pipelines.ts',
    'src/lib/supabase/schema-helpers.ts'
)

$toDelete = 'src/lib/supabase/factories-urm.ts'

# Patterns to replace:
#   .schema('urm' as never)  ->  .schema('app')
#   .schema('urm')           ->  .schema('app')
# Note: order matters — try the longer pattern first
$replacements = @(
    @{ from = ".schema('urm' as never)";  to = ".schema('app')" },
    @{ from = ".schema('urm' as any)";    to = ".schema('app')" },
    @{ from = ".schema(""urm"" as never)"; to = ".schema('app')" },
    @{ from = ".schema(""urm"" as any)";   to = ".schema('app')" },
    @{ from = ".schema('urm')";            to = ".schema('app')" },
    @{ from = ".schema(""urm"")";          to = ".schema('app')" }
)

Write-Host ''
Write-Host '======================================'
if ($DryRun) {
    Write-Host 'D6-5c-3 urm -> app (DRY RUN)'
} else {
    Write-Host 'D6-5c-3 urm -> app (APPLY MODE)'
}
Write-Host '======================================'
Write-Host ''

# ---- Phase 1: scan targets for hits ----
$totalReplacements = 0
$fileStats = @()

foreach ($file in $targets) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Write-Host ('  SKIP (not found): {0}' -f $file)
        continue
    }
    
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    $original = $content
    $hitCount = 0
    
    foreach ($r in $replacements) {
        $beforeLen = $content.Length
        # Escape pattern for literal match
        $escaped = [regex]::Escape($r.from)
        $matches = [regex]::Matches($content, $escaped)
        if ($matches.Count -gt 0) {
            $content = $content -replace $escaped, $r.to
            $hitCount += $matches.Count
        }
    }
    
    if ($hitCount -gt 0) {
        $fileStats += [pscustomobject]@{
            file = $file
            hits = $hitCount
            originalContent = $original
            newContent = $content
        }
        Write-Host ('  REPLACE: {0,-50} {1} hits' -f $file, $hitCount)
        $totalReplacements += $hitCount
    } else {
        Write-Host ('  SKIP (no hits): {0}' -f $file)
    }
}

Write-Host ''
Write-Host ('--- Total: {0} replacements across {1} files ---' -f $totalReplacements, $fileStats.Count)

# ---- Phase 2: deletion target ----
Write-Host ''
Write-Host '--- Files to delete ---'
if (Test-Path -LiteralPath $toDelete -PathType Leaf) {
    $deleteSize = (Get-Item -LiteralPath $toDelete).Length
    Write-Host ('  DELETE: {0} ({1:N0} bytes)' -f $toDelete, $deleteSize)
} else {
    Write-Host ('  SKIP (not found): {0}' -f $toDelete)
}

# ---- Stop if dry run ----
if ($DryRun) {
    Write-Host ''
    Write-Host '======================================'
    Write-Host 'DRY RUN COMPLETE - no changes applied.'
    Write-Host ''
    Write-Host 'To apply:'
    Write-Host '  .\D6-5c-3-urm-to-app.ps1 -Apply'
    Write-Host '======================================'
    exit 0
}

# ---- Apply mode ----
Write-Host ''
Write-Host '--- Applying changes ---'

foreach ($stat in $fileStats) {
    # Write with UTF-8 (no BOM) - matches TypeScript file convention
    [System.IO.File]::WriteAllText(
        (Resolve-Path -LiteralPath $stat.file).Path,
        $stat.newContent,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host ('  WROTE: {0} ({1} replacements)' -f $stat.file, $stat.hits)
}

if (Test-Path -LiteralPath $toDelete -PathType Leaf) {
    Remove-Item -LiteralPath $toDelete -Force
    Write-Host ('  DELETED: {0}' -f $toDelete)
}

Write-Host ''
Write-Host '--- Post-change git status ---'
git status --short

Write-Host ''
Write-Host '======================================'
Write-Host 'D6-5c-3 applied'
Write-Host '======================================'
Write-Host ''
Write-Host 'NEXT STEPS:'
Write-Host '  1. tsc verification:'
Write-Host '       npx tsc --noEmit 2>&1 | Out-File -Encoding utf8 D6-5c-3-post-tsc.txt'
Write-Host ''
Write-Host '  2. Count remaining errors:'
Write-Host '       (Get-Content D6-5c-3-post-tsc.txt | Select-String -Pattern "error TS" | Measure-Object).Count'
Write-Host '       Expected: ~28 errors (was 46, urm batch removes ~18)'
Write-Host ''
Write-Host '  3. Confirm no urm remnants:'
Write-Host '       Get-Content D6-5c-3-post-tsc.txt | Select-String -Pattern "''urm''" | Select-Object -First 5'
Write-Host '       Expected: empty'
Write-Host ''
Write-Host '  4. Rollback if needed:'
Write-Host '       git checkout -- src/'
