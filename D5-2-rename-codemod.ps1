# D5-2 column rename codemod (PS 5.x safe, ASCII only)
# Stage 29-c handoff column renames, applied to specific files only
# (whitelisted from D5-1 audit Section 5)
#
# Renames:
#   body_text    -> body_plain         (communications)
#   org_id       -> organization_id    (email_whitelist/communications)
#   supply_type  -> link_type          (party_supply_links)
#   volume_tpy   -> volume_estimate    (party_supply_links)
#
# Skipped (handled elsewhere):
#   joined_at, left_at      -> contacts_history (database.ts only, type regen)
#   stage_position          -> stages (0 hits found)
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   .\D5-2-rename-codemod.ps1            # dry-run (default)
#   .\D5-2-rename-codemod.ps1 -Apply     # write changes + create .bak files

param(
    [switch]$Apply
)

$ErrorActionPreference = 'Continue'

$projectRoot = 'C:\dev\mbg-project'
$bakSuffix   = '.D5-2-' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak'

# ==========================================================================
# Rename specification (from D5-1 audit Section 5)
#   Each row: V1 column, V2 column, files where it appears
# ==========================================================================
$renames = @(
    @{
        v1 = 'body_text'
        v2 = 'body_plain'
        tbl = 'communications'
        files = @(
            'src\components\settings\sequence-form-dialog.tsx',
            'src\lib\actions\email-sequences.ts',
            'src\types\database.ts',
            'src\types\phase21b.ts'
        )
    },
    @{
        v1 = 'org_id'
        v2 = 'organization_id'
        tbl = 'email_whitelist/communications'
        files = @(
            'src\app\(app)\[partyType]\parties\[id]\page.tsx',
            'src\lib\actions\email-compose.ts',
            'src\types\database.ts',
            'src\types\phase21.ts'
        )
    },
    @{
        v1 = 'supply_type'
        v2 = 'link_type'
        tbl = 'party_supply_links'
        files = @(
            'src\app\api\supply-links\route.ts',
            'src\components\parties\party-supply-links-panel.tsx',
            'src\types\database.ts'
        )
    },
    @{
        v1 = 'volume_tpy'
        v2 = 'volume_estimate'
        tbl = 'party_supply_links'
        files = @(
            'src\app\api\supply-links\route.ts',
            'src\components\parties\party-supply-links-panel.tsx',
            'src\types\database.ts'
        )
    }
)

# ==========================================================================
# Header
# ==========================================================================
Write-Host '=== D5-2 column rename codemod ===' -ForegroundColor Cyan
if ($Apply) {
    Write-Host 'Mode: APPLY (files will be modified)' -ForegroundColor Yellow
    Write-Host "Backup suffix: $bakSuffix"
} else {
    Write-Host 'Mode: DRY-RUN (no files modified). Re-run with -Apply to commit.' -ForegroundColor DarkGreen
}
Write-Host ''

# ==========================================================================
# Process each rename
# ==========================================================================
$totalPlanned = 0
$totalApplied = 0
$totalSkipped = 0
$skipReasons  = New-Object System.Collections.ArrayList

foreach ($r in $renames) {
    $v1   = $r.v1
    $v2   = $r.v2
    $tbl  = $r.tbl
    Write-Host ('--- ' + $v1 + ' -> ' + $v2 + '  (' + $tbl + ') ---') -ForegroundColor Cyan

    foreach ($rel in $r.files) {
        $full = Join-Path $projectRoot $rel
        if (-not (Test-Path -LiteralPath $full)) {
            Write-Host ('  [MISS] ' + $rel) -ForegroundColor DarkGray
            [void]$skipReasons.Add("$v1 -> $v2 | $rel | file not found")
            continue
        }

        $content = [System.IO.File]::ReadAllText($full)

        # Word-boundary match: \b is fine since v1 values are all snake_case
        $pat = '\b' + [regex]::Escape($v1) + '\b'
        $matches = [regex]::Matches($content, $pat)
        $matchCount = $matches.Count

        if ($matchCount -eq 0) {
            Write-Host ('  [SKIP] 0 matches in ' + $rel) -ForegroundColor DarkGray
            [void]$skipReasons.Add("$v1 -> $v2 | $rel | 0 matches")
            continue
        }

        $totalPlanned += $matchCount
        Write-Host ('  [PLAN x' + $matchCount + '] ' + $rel) -ForegroundColor Green

        # Show context for first 3 matches (sanity check)
        $showCount = [Math]::Min(3, $matchCount)
        for ($i = 0; $i -lt $showCount; $i++) {
            $m = $matches[$i]
            $start = [Math]::Max(0, $m.Index - 30)
            $endX  = [Math]::Min($content.Length, $m.Index + $v1.Length + 30)
            $ctx = $content.Substring($start, $endX - $start) -replace "`r?`n", ' / '
            Write-Host ('         ... ' + $ctx)
        }
        if ($matchCount -gt 3) {
            Write-Host ('         ... (' + ($matchCount - 3) + ' more)')
        }

        if ($Apply) {
            # Backup
            $bak = $full + $bakSuffix
            Copy-Item -LiteralPath $full -Destination $bak -Force

            # Replace using regex with word boundary
            $newContent = [regex]::Replace($content, $pat, $v2)

            # Write UTF-8 without BOM (code file convention)
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($full, $newContent, $utf8NoBom)
            $totalApplied += $matchCount
            Write-Host ('         [APPLIED] backup: ' + (Split-Path $bak -Leaf)) -ForegroundColor Green
        }
    }
    Write-Host ''
}

# ==========================================================================
# Summary
# ==========================================================================
Write-Host '=== Summary ===' -ForegroundColor Cyan
Write-Host ('Planned replacements: ' + $totalPlanned)
if ($Apply) {
    Write-Host ('Applied replacements: ' + $totalApplied) -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next steps:'
    Write-Host '  1. Verify: git diff src\'
    Write-Host '  2. Build:  npm run build  (or)  npx tsc --noEmit'
    Write-Host '  3. If clean, commit. If broken, restore from .bak files.'
    Write-Host ''
    Write-Host 'Rollback (any single file):'
    Write-Host ('  Copy-Item <file>' + $bakSuffix + ' <file> -Force')
} else {
    Write-Host ''
    Write-Host 'To commit changes: rerun with -Apply' -ForegroundColor Yellow
    Write-Host '  .\D5-2-rename-codemod.ps1 -Apply'
}
Write-Host ''

if ($skipReasons.Count -gt 0) {
    Write-Host ('Skipped (' + $skipReasons.Count + '):') -ForegroundColor DarkGray
    foreach ($s in $skipReasons) {
        Write-Host ('  ' + $s) -ForegroundColor DarkGray
    }
}
