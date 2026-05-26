# D5-0 stage29c audit script
# Reads stage29c artifacts and packages them into a single .md report
# for review and decision-making.
#
# Output: D5-0-audit-report.md in project root (UTF-8 with BOM)
#
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   .\D5-0-audit.ps1

$ErrorActionPreference = 'Continue'

$projectRoot = 'C:\dev\mbg-project'
$stage29c    = Join-Path $projectRoot 'stage29c'
$outputFile  = Join-Path $projectRoot 'D5-0-audit-report.md'

Write-Host "=== D5-0 stage29c audit ===" -ForegroundColor Cyan
Write-Host "Project root: $projectRoot"
Write-Host "stage29c dir: $stage29c"
Write-Host ""

if (-not (Test-Path -LiteralPath $stage29c)) {
    Write-Host "[ERROR] stage29c directory not found: $stage29c" -ForegroundColor Red
    Write-Host "Adjust `$projectRoot in this script if your repo is elsewhere." -ForegroundColor DarkYellow
    exit 1
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# D5-0 stage29c audit report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("**Project root**: ``$projectRoot``")
[void]$sb.AppendLine("**Script**: D5-0-audit.ps1")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")

# ==========================================================================
# Section 1: Directory tree
# ==========================================================================
Write-Host "[1/4] Building directory tree" -ForegroundColor Yellow

[void]$sb.AppendLine("## 1. stage29c directory tree")
[void]$sb.AppendLine("")
[void]$sb.AppendLine('```')

$tree = Get-ChildItem -LiteralPath $stage29c -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName

foreach ($item in $tree) {
    $rel = $item.FullName.Substring($stage29c.Length + 1)
    if ($item.PSIsContainer) {
        [void]$sb.AppendLine("[DIR]  $rel")
    } else {
        $sz = "{0,8}" -f $item.Length
        [void]$sb.AppendLine("       $sz  $rel")
    }
}
[void]$sb.AppendLine('```')
[void]$sb.AppendLine("")

# ==========================================================================
# Section 2: Key documents inline
# ==========================================================================
Write-Host "[2/4] Reading key documents" -ForegroundColor Yellow

$keyFiles = @(
    'INDEX.md',
    'STAGE_29C_PLAYBOOK.md',
    '07_completion\completion_criteria.md',
    '02_type_regeneration\REGEN_TYPES.md'
)

[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 2. Key documents (full text)")
[void]$sb.AppendLine("")

foreach ($f in $keyFiles) {
    $full = Join-Path $stage29c $f
    [void]$sb.AppendLine("### File: ``$f``")
    [void]$sb.AppendLine("")
    if (Test-Path -LiteralPath $full) {
        $content = [System.IO.File]::ReadAllText($full)
        [void]$sb.AppendLine('```markdown')
        [void]$sb.AppendLine($content.TrimEnd())
        [void]$sb.AppendLine('```')
        Write-Host "  [OK]   $f" -ForegroundColor Green
    } else {
        [void]$sb.AppendLine("**(file not found)**")
        Write-Host "  [MISS] $f" -ForegroundColor DarkYellow
    }
    [void]$sb.AppendLine("")
}

# ==========================================================================
# Section 3: Per-subdirectory contents
# ==========================================================================
Write-Host "[3/4] Cataloging subdirectories" -ForegroundColor Yellow

[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 3. Subdirectory contents (small text files inlined)")
[void]$sb.AppendLine("")

$inlineExts = @('.md', '.sql', '.ts', '.tsx', '.txt', '.json', '.yml', '.yaml', '.ps1', '.sh')
$maxInlineSize = 30000

$subdirs = Get-ChildItem -LiteralPath $stage29c -Directory | Sort-Object Name
foreach ($sd in $subdirs) {
    [void]$sb.AppendLine("### Subdir: ``$($sd.Name)``")
    [void]$sb.AppendLine("")

    $files = Get-ChildItem -LiteralPath $sd.FullName -File -Recurse | Sort-Object FullName
    if ($files.Count -eq 0) {
        [void]$sb.AppendLine("(empty)")
        [void]$sb.AppendLine("")
        continue
    }

    foreach ($f in $files) {
        $rel = $f.FullName.Substring($sd.FullName.Length + 1)
        [void]$sb.AppendLine("#### ``$rel`` ($($f.Length) bytes)")
        [void]$sb.AppendLine("")

        if ($f.Length -lt $maxInlineSize -and $inlineExts -contains $f.Extension) {
            $content = [System.IO.File]::ReadAllText($f.FullName)
            $lang = switch ($f.Extension) {
                '.md'   { 'markdown' }
                '.sql'  { 'sql' }
                '.ts'   { 'typescript' }
                '.tsx'  { 'typescript' }
                '.json' { 'json' }
                '.yml'  { 'yaml' }
                '.yaml' { 'yaml' }
                '.ps1'  { 'powershell' }
                '.sh'   { 'bash' }
                default { '' }
            }
            [void]$sb.AppendLine('```' + $lang)
            [void]$sb.AppendLine($content.TrimEnd())
            [void]$sb.AppendLine('```')
        } else {
            [void]$sb.AppendLine("*(skipped: too large or binary — open manually)*")
        }
        [void]$sb.AppendLine("")
    }
}

# ==========================================================================
# Section 4: Quick stats
# ==========================================================================
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 4. Stats")
[void]$sb.AppendLine("")

$allFiles = $tree | Where-Object { -not $_.PSIsContainer }
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
$byExt = $allFiles | Group-Object Extension | Sort-Object Count -Descending

[void]$sb.AppendLine("- Total files: $($allFiles.Count)")
[void]$sb.AppendLine("- Total size: $totalSize bytes")
[void]$sb.AppendLine("- By extension:")
foreach ($g in $byExt) {
    $ext = if ($g.Name) { $g.Name } else { '(no ext)' }
    [void]$sb.AppendLine("  - $ext : $($g.Count) files")
}
[void]$sb.AppendLine("")

# ==========================================================================
# Write file (UTF-8 with BOM, per project convention)
# ==========================================================================
Write-Host "[4/4] Writing report" -ForegroundColor Yellow

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), $utf8Bom)

$fi = Get-Item $outputFile
Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Report: $outputFile"
Write-Host "Size  : $($fi.Length) bytes"
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Open the report in your editor"
Write-Host "  2. Run D5-0-urm-diagnostic.sql in Supabase SQL Editor"
Write-Host "  3. Share both outputs to plan D5-1"
