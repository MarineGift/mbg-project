# =============================================================
# D6-5c-2a-industry-deletions.ps1
#
# Phase 1 of industry/* cleanup: pure deletions, no file edits.
#
# DB has no 'industry' schema (verified empty), so all 27 files
# below are dead code — they call non-existent tables at runtime.
#
# Workflow:
#   1. Run without flag (DRY RUN) to preview what will be deleted
#   2. Re-run with -Apply to actually delete (requires 'yes' confirm)
#   3. After: run 'npx tsc --noEmit' and share errors for phase 2 edits
#
# Safety:
#   - Defaults to DRY RUN (no changes)
#   - Requires interactive 'yes' confirmation in -Apply mode
#   - Git is the recovery net (last commit was a27d40c)
#   - To roll back if needed: git checkout -- src/
# =============================================================

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$DryRun = -not $Apply

# Pre-flight: must be at repo root
if (-not (Test-Path 'src' -PathType Container)) {
    Write-Host 'ERROR: src/ directory not found. Run from C:\dev\mbg-project.'
    exit 1
}

# Targets
$dirsToDelete = @(
    'src/app/(app)/industry',
    'src/components/industry'
)

$filesToDelete = @(
    'src/lib/queries/industry-link.ts',
    'src/lib/queries/industry-link-extensions.ts',
    'src/types/industry-link.ts',
    'src/components/parties/industry-paper-section.tsx',
    'src/components/parties/industry-filler-section.tsx',
    'src/components/parties/industry-shared.tsx'
)

# ---- Banner ----
Write-Host ''
Write-Host '======================================'
if ($DryRun) {
    Write-Host 'D6-5c-2a Industry Cleanup (DRY RUN)'
    Write-Host '(no files will be deleted)'
} else {
    Write-Host 'D6-5c-2a Industry Cleanup (APPLY MODE)'
}
Write-Host '======================================'
Write-Host ''

# ---- Preview directories ----
Write-Host '--- Directories ---'
$totalFiles = 0
$totalBytes = 0
foreach ($d in $dirsToDelete) {
    if (Test-Path $d -PathType Container) {
        $items = Get-ChildItem -Recurse -Path $d -File
        $count = ($items | Measure-Object).Count
        $bytes = ($items | Measure-Object -Sum Length).Sum
        if ($null -eq $bytes) { $bytes = 0 }
        Write-Host ('  DELETE: {0,-40} ({1,3} files, {2,8:N0} bytes)' -f $d, $count, $bytes)
        $totalFiles += $count
        $totalBytes += $bytes
    } else {
        Write-Host ('  SKIP (not found): {0}' -f $d)
    }
}

# ---- Preview individual files ----
Write-Host ''
Write-Host '--- Individual files ---'
foreach ($f in $filesToDelete) {
    if (Test-Path $f -PathType Leaf) {
        $bytes = (Get-Item $f).Length
        Write-Host ('  DELETE: {0,-60} ({1,7:N0} bytes)' -f $f, $bytes)
        $totalFiles += 1
        $totalBytes += $bytes
    } else {
        Write-Host ('  SKIP (not found): {0}' -f $f)
    }
}

Write-Host ''
Write-Host ('Total: {0} files, {1:N0} bytes ({2:N1} KB)' -f $totalFiles, $totalBytes, ($totalBytes / 1024))

# ---- Stop here if dry run ----
if ($DryRun) {
    Write-Host ''
    Write-Host '======================================'
    Write-Host 'DRY RUN COMPLETE - no changes applied.'
    Write-Host ''
    Write-Host 'To apply:'
    Write-Host '  .\D6-5c-2a-industry-deletions.ps1 -Apply'
    Write-Host '======================================'
    exit 0
}

# ---- Apply mode ----
Write-Host ''
Write-Host '--- Pre-deletion git status ---'
git status --short
Write-Host ''

$confirmation = Read-Host 'Type yes to proceed with deletion'
if ($confirmation -ne 'yes') {
    Write-Host 'Aborted. No changes made.'
    exit 1
}

Write-Host ''
Write-Host '--- Deleting ---'
foreach ($d in $dirsToDelete) {
    if (Test-Path $d -PathType Container) {
        Remove-Item -Recurse -Force -Path $d
        Write-Host ('  DELETED: {0}' -f $d)
    }
}
foreach ($f in $filesToDelete) {
    if (Test-Path $f -PathType Leaf) {
        Remove-Item -Force -Path $f
        Write-Host ('  DELETED: {0}' -f $f)
    }
}

Write-Host ''
Write-Host '--- Post-deletion git status ---'
git status --short

Write-Host ''
Write-Host '======================================'
Write-Host 'D6-5c-2a deletions complete'
Write-Host '======================================'
Write-Host ''
Write-Host 'NEXT STEPS:'
Write-Host '  1. Compile-check to discover broken imports:'
Write-Host '       npx tsc --noEmit 2>&1 | Select-Object -First 50'
Write-Host ''
Write-Host '  2. Share the tsc error output for D6-5c-2b edit patches'
Write-Host ''
Write-Host '  3. If anything looks wrong, rollback:'
Write-Host '       git checkout -- src/'
