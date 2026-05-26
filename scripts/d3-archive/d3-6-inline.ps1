# d3-6-inline.ps1 - inline label patch
# Usage: .\d3-6-inline.ps1           (dry-run)
#        .\d3-6-inline.ps1 -Apply    (real change + .bak + tsc)
param([switch]$Apply)

$scriptName = 'd3-6-inline.ps1'
$downloadsCandidates = @(
    (Join-Path $env:USERPROFILE "Downloads\$scriptName"),
    (Join-Path $env:USERPROFILE "다운로드\$scriptName")
)
foreach ($cand in $downloadsCandidates) {
    if (Test-Path -LiteralPath $cand) {
        Move-Item -LiteralPath $cand -Destination . -Force
        Write-Host "Moved from: $cand" -ForegroundColor DarkGray
        break
    }
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Unblock-File -LiteralPath ".\$scriptName" -ErrorAction SilentlyContinue
Set-Location -LiteralPath 'C:\dev\mbg-project'

$replacements = @(
    @{ Pattern = "'All modules'"; Replace = "'All'";        Label = "single-quoted 'All modules'" }
    @{ Pattern = '"All modules"'; Replace = '"All"';        Label = 'double-quoted "All modules"' }
    @{ Pattern = '>All modules<'; Replace = '>All<';        Label = "JSX text >All modules<" }
    @{ Pattern = "'Module'";      Replace = "'Party type'"; Label = "single-quoted 'Module'" }
    @{ Pattern = '"Module"';      Replace = '"Party type"'; Label = 'double-quoted "Module"' }
    @{ Pattern = '>Module<';      Replace = '>Party type<'; Label = "JSX text >Module<" }
)

$files = Get-ChildItem -Path 'src' -Recurse -Include *.ts, *.tsx -File |
    Where-Object {
        $_.FullName -notmatch '\\__tests__\\' -and
        $_.FullName -notmatch '\\database\.ts$' -and
        $_.FullName -notmatch '\\\.next\\'
    }

Write-Host ""
if ($Apply) {
    Write-Host "Mode  : APPLY (real changes)" -ForegroundColor Cyan
} else {
    Write-Host "Mode  : DRY-RUN (no changes)" -ForegroundColor Cyan
}
Write-Host "Files : $($files.Count)" -ForegroundColor DarkGray
Write-Host ""

$totalMatches = 0
$changedFiles = 0

foreach ($file in $files) {
    $rel        = $file.FullName.Replace((Get-Location).Path + '\', '')
    $content    = [System.IO.File]::ReadAllText($file.FullName)
    $newContent = $content
    $fileCount  = 0

    foreach ($rep in $replacements) {
        $cnt = ([regex]::Matches($newContent, [regex]::Escape($rep.Pattern))).Count
        if ($cnt -gt 0) {
            $fileCount += $cnt
            if ($Apply) {
                $newContent = $newContent.Replace($rep.Pattern, $rep.Replace)
            }
        }
    }

    if ($fileCount -gt 0) {
        $totalMatches += $fileCount
        Write-Host ("  [{0,3}] {1}" -f $fileCount, $rel) -ForegroundColor Yellow
    }

    if ($Apply -and $fileCount -gt 0) {
        $bakPath = $file.FullName + '.bak-d3-6'
        Copy-Item -LiteralPath $file.FullName -Destination $bakPath -Force
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8Bom)
        $changedFiles++
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
if ($Apply) { Write-Host "  APPLY done" -ForegroundColor Green }
else        { Write-Host "  DRY-RUN done (no changes)" -ForegroundColor Yellow }
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Total matches  : $totalMatches" -ForegroundColor Cyan
Write-Host "  Changed files  : $changedFiles" -ForegroundColor Cyan

if ($Apply -and $changedFiles -gt 0) {
    Write-Host ""
    Write-Host "Running tsc..." -ForegroundColor Cyan
    $errCount = (npx tsc --noEmit 2>&1 | Select-String 'error TS').Count
    if ($errCount -eq 0) {
        Write-Host "  tsc: 0 errors  [OK]" -ForegroundColor Green
    } else {
        Write-Host "  tsc: $errCount errors  [REGRESSION]" -ForegroundColor Red
    }
}

Write-Host ""
if ($Apply) {
    Write-Host "Next: hard-refresh http://localhost:3001/drafts" -ForegroundColor White
} else {
    Write-Host "Next: .\$scriptName -Apply" -ForegroundColor White
}
Write-Host ""
