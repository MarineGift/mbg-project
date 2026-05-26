# phase-d2r-investigate.ps1
# Investigate why engagements.ts still has 2 errors after D2r-fixup [OK x1]
# Read-only diagnostic.

$ErrorActionPreference = 'Stop'
Set-Location 'C:\dev\mbg-project'

$file = "src\lib\queries\engagements.ts"

Write-Host "`n=== Phase D2r-investigate ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. Verify the file write actually persisted
# ============================================================
$lines = Get-Content -LiteralPath $file

Write-Host "--- Current L190-195 (should show 'partyType: module,' at L193 if fix applied) ---" -ForegroundColor Cyan
for ($i = 189; $i -le 194; $i++) {
    if ($i -lt $lines.Count) {
        $marker = if ($i -eq 192) { ">>" } else { "  " }
        Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $lines[$i]) -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "--- Current L233-240 (should show 'partyType: module,' at L236 if fix applied) ---" -ForegroundColor Cyan
for ($i = 232; $i -le 239; $i++) {
    if ($i -lt $lines.Count) {
        $marker = if ($i -eq 235) { ">>" } else { "  " }
        Write-Host ("    " + $marker + " " + ($i+1).ToString().PadLeft(4) + " | " + $lines[$i]) -ForegroundColor DarkGray
    }
}

# ============================================================
# 2. Current tsc errors in engagements.ts
# ============================================================
Write-Host ""
Write-Host "--- Current tsc errors in engagements.ts ---" -ForegroundColor Cyan
$tscOut = npx tsc --noEmit 2>&1
$tscOut | Select-String 'engagements.ts' | ForEach-Object {
    Write-Host ("  " + $_.Line) -ForegroundColor DarkGray
}

# ============================================================
# 3. Find KanbanBoard type definition
# ============================================================
Write-Host ""
Write-Host "--- KanbanBoard type definition (search all .ts files) ---" -ForegroundColor Cyan
$kanbanFiles = Get-ChildItem -Recurse -Filter "*.ts" -Path "src" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules' } |
    Select-String -Pattern "interface KanbanBoard|type KanbanBoard" -List

foreach ($f in $kanbanFiles) {
    Write-Host ("  Found in: " + $f.Path) -ForegroundColor White
    $relPath = $f.Path.Replace((Get-Location).Path + "\", "")
    $kLines = Get-Content -LiteralPath $relPath
    # Find the interface/type line + show 15 lines after
    for ($i = 0; $i -lt $kLines.Count; $i++) {
        if ($kLines[$i] -match "(interface|type)\s+KanbanBoard") {
            $start = $i
            $end = [Math]::Min($kLines.Count - 1, $i + 20)
            for ($j = $start; $j -le $end; $j++) {
                Write-Host ("    " + ($j+1).ToString().PadLeft(4) + " | " + $kLines[$j]) -ForegroundColor DarkGray
            }
            break
        }
    }
}

# ============================================================
# 4. File line ending re-check + git status
# ============================================================
Write-Host ""
Write-Host "--- File state check ---" -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes($file)
$hasCRLF = $false
for ($i = 0; $i -lt [Math]::Min($bytes.Length, 5000); $i++) {
    if ($bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i+1] -eq 10) { $hasCRLF = $true; break }
}
Write-Host ("  Line ending: " + $(if ($hasCRLF) { "CRLF" } else { "LF" })) -ForegroundColor White
Write-Host ("  File size: " + $bytes.Length + " bytes") -ForegroundColor White

Write-Host ""
Write-Host "  git status for this file:" -ForegroundColor White
git status --short -- $file
Write-Host ""

Write-Host "Diagnostic complete." -ForegroundColor Green
Write-Host ""
