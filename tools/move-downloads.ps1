# move-downloads.ps1  (mbg-project universal mover)
# Moves every recognized deliverable from Downloads into the repo by filename
# rule. Safe to run anytime (idempotent). PS 5.x compatible. ASCII output only.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
#   powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1 -Watch
#
# Rules (first match wins):
#   seed_/migration_/repair_/enrich_/backfill_/fix_ *.sql -> sql\
#   handoff_*.md                                          -> docs\handoff\<today>\
#   patch_*.ps1                                           -> tools\patches\
#   any other *.sql                                       -> sql\

param(
  [switch]$Watch,
  [int]$IntervalSec = 3
)

$Repo      = 'C:\dev\mbg-project'
$Downloads = Join-Path $env:USERPROFILE 'Downloads'
$PersonalRoot = 'C:\dev\mbg-personal'

function Get-CanonicalName([string]$name) {
  return ($name -replace ' \(\d+\)(\.[^.]+)$', '$1')
}

function Get-DestSubdir([string]$canon) {
  if ($canon -match '^personal_') { return ('PERSONAL:handoff\' + (Get-Date -Format 'yyyy-MM-dd')) }
  if ($canon -match '(^|[_\-\. ])(I-?485|I-?140|I-?765|I-?131|I-?693|G-?1145|EAD|AOS|greencard|green-card|visa|passport|uscis|tax)([_\-\. ]|$)') { return ('PERSONAL:handoff\' + (Get-Date -Format 'yyyy-MM-dd')) }
  if ($canon -match '^(seed|migration|repair|enrich|backfill|fix)_.*\.sql$') { return 'sql' }
  if ($canon -match '^handoff_.*\.md$') { return ('docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd')) }
  if ($canon -match '^patch_.*\.ps1$') { return 'tools\patches' }
  if ($canon -match '\.sql$') { return 'sql' }
  return $null
}

function Test-FileStable($f) {
  if ($f.Extension -in @('.crdownload', '.tmp', '.partial', '.download')) { return $false }
  $len1 = $f.Length
  Start-Sleep -Milliseconds 400
  $f.Refresh()
  return ($f.Length -eq $len1)
}

function Invoke-MoveScan {
  $moved = 0
  $files = Get-ChildItem -Path $Downloads -File -ErrorAction SilentlyContinue
  if (-not $files) { return 0 }
  $groups = $files | Group-Object { Get-CanonicalName $_.Name }
  foreach ($g in $groups) {
    $canon = $g.Name
    $sub = Get-DestSubdir $canon
    if (-not $sub) { continue }
    $ordered = $g.Group | Sort-Object LastWriteTime -Descending
    $src = $ordered[0]
    if (-not (Test-FileStable $src)) { Write-Output ('WAIT  ' + $src.Name + ' (still downloading)'); continue }
    if ($sub.StartsWith('PERSONAL:')) { $destDir = Join-Path $PersonalRoot $sub.Substring(9) } else { $destDir = Join-Path $Repo $sub }
    [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
    $dest = Join-Path $destDir $canon
    Unblock-File -Path $src.FullName -ErrorAction SilentlyContinue
    [System.IO.File]::Copy($src.FullName, $dest, $true)
    Remove-Item -LiteralPath $src.FullName -Force
    Write-Output ('MOVED ' + $src.Name + ' -> ' + $dest)
    $moved++
    if ($ordered.Count -gt 1) {
      $ordered | Select-Object -Skip 1 | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force
        Write-Output ('CLEAN ' + $_.Name + ' (older duplicate)')
      }
    }
  }
  return $moved
}

if (-not (Test-Path -LiteralPath $Repo)) { Write-Output ('ERROR: repo not found at ' + $Repo); return }

if ($Watch) {
  Write-Output ('WATCHING ' + $Downloads + ' every ' + $IntervalSec + 's. Ctrl+C to stop.')
  while ($true) {
    $n = Invoke-MoveScan
    if ($n -gt 0) { Write-Output ('--- ' + $n + ' file(s) moved. git status: ---'); Set-Location $Repo; git status -sb }
    Start-Sleep -Seconds $IntervalSec
  }
} else {
  $n = Invoke-MoveScan
  Write-Output ('DONE: ' + $n + ' file(s) moved.')
  if ($n -gt 0) { Set-Location $Repo; git status -sb }
}