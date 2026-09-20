<#
  patch_20260914_move_meeting_edit_files.ps1
  ------------------------------------------
  Moves the 2026-09-14 "meeting edit/delete" deliverables from the Downloads
  folder into their canonical paths in the mbg-project repo.

  - Tolerates browser suffixes: "calendar_page (1).tsx", "... (2).tsx" etc.
    (newest match by LastWriteTime wins)
  - Unblock-File on every source (removes the MOTW / "downloaded from internet"
    stream so Next.js/Windows Defender do not complain)
  - Destination paths contain "(app)" and "[id]"; all file IO uses .NET methods
    so PowerShell wildcard parsing never touches them
  - Default behaviour is MOVE (copy, verify size, then delete the download).
    Use -KeepDownloads to copy only.
  - ASCII-only console output.

  Usage (PowerShell 5.1 or 7.x):
      cd $env:USERPROFILE\Downloads
      powershell -ExecutionPolicy Bypass -File .\patch_20260914_move_meeting_edit_files.ps1

  If running with -File silently does nothing (known PS 5.x quirk), paste the
  inline block from docs/handoff/2026-09-14/handoff_2026-09-14_meeting_edit_delete.md
  directly into the console instead.
#>

[CmdletBinding()]
param(
  [string] $Repo      = 'C:\dev\mbg-project',
  [string] $Downloads = (Join-Path $env:USERPROFILE 'Downloads'),
  [switch] $KeepDownloads,
  [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Download name  ->  repo-relative destination
# ---------------------------------------------------------------------------
$map = @(
  # new files
  @{ src = 'actions_meetings.ts';        dst = 'src\app\actions\meetings.ts' },
  @{ src = 'meeting-edit-modal.tsx';     dst = 'src\components\meetings\meeting-edit-modal.tsx' },
  @{ src = 'meeting-detail-actions.tsx'; dst = 'src\components\meetings\meeting-detail-actions.tsx' },
  # modified files
  @{ src = 'calendar_page.tsx';          dst = 'src\app\(app)\calendar\page.tsx' },
  @{ src = 'meetings_id_page.tsx';       dst = 'src\app\(app)\meetings\[id]\page.tsx' },
  @{ src = 'edit-event-modal.tsx';       dst = 'src\components\calendar\edit-event-modal.tsx' },
  @{ src = 'queries_calendar.ts';        dst = 'src\lib\queries\calendar.ts' },
  @{ src = 'queries_today.ts';           dst = 'src\lib\queries\today.ts' },
  @{ src = 'queries_party-detail.ts';    dst = 'src\lib\queries\party-detail.ts' },
  # documentation
  @{ src = 'handoff_2026-09-14_meeting_edit_delete.md';
     dst = 'docs\handoff\2026-09-14\handoff_2026-09-14_meeting_edit_delete.md' }
)

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== mbg-project :: 2026-09-14 meeting edit/delete mover ==='
Write-Host ("repo      : " + $Repo)
Write-Host ("downloads : " + $Downloads)
if ($DryRun)        { Write-Host 'mode      : DRY RUN (nothing is written)' }
elseif ($KeepDownloads) { Write-Host 'mode      : COPY (downloads kept)' }
else                { Write-Host 'mode      : MOVE (downloads removed after copy)' }
Write-Host ''

if (-not (Test-Path -LiteralPath $Repo)) {
  Write-Host ("ERROR  repo folder not found: " + $Repo)
  Write-Host '       re-run with:  -Repo <path-to-mbg-project>'
  exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $Repo 'package.json'))) {
  Write-Host ("ERROR  no package.json in " + $Repo + " - is that really the repo root?")
  exit 1
}
if (-not (Test-Path -LiteralPath $Downloads)) {
  Write-Host ("ERROR  downloads folder not found: " + $Downloads)
  exit 1
}

$moved   = 0
$missing = @()

# ---------------------------------------------------------------------------
# Move
# ---------------------------------------------------------------------------
foreach ($m in $map) {

  $base = [System.IO.Path]::GetFileNameWithoutExtension($m.src)
  $ext  = [System.IO.Path]::GetExtension($m.src)

  # newest "<base>*<ext>" in Downloads  ->  handles "(1)" / "(2)" duplicates
  $hit = Get-ChildItem -LiteralPath $Downloads -File |
         Where-Object { $_.Name -like ($base + '*' + $ext) } |
         Sort-Object LastWriteTime -Descending |
         Select-Object -First 1

  if (-not $hit) {
    Write-Host ("MISS   " + $m.src)
    $missing += $m.src
    continue
  }

  $dest    = Join-Path $Repo $m.dst
  $destDir = [System.IO.Path]::GetDirectoryName($dest)

  if ($DryRun) {
    Write-Host ("DRY    " + $hit.Name + "  ->  " + $m.dst)
    $moved++
    continue
  }

  try { Unblock-File -LiteralPath $hit.FullName } catch { }

  [void][System.IO.Directory]::CreateDirectory($destDir)
  [System.IO.File]::Copy($hit.FullName, $dest, $true)

  # verify before deleting the source
  $srcLen = (Get-Item -LiteralPath $hit.FullName).Length
  $dstLen = (Get-Item -LiteralPath $dest).Length
  if ($srcLen -ne $dstLen) {
    Write-Host ("ERROR  size mismatch after copy: " + $m.dst + " (" + $srcLen + " vs " + $dstLen + ")")
    exit 1
  }

  if (-not $KeepDownloads) {
    Remove-Item -LiteralPath $hit.FullName -Force
    Write-Host ("MOVED  " + $hit.Name + "  ->  " + $m.dst)
  } else {
    Write-Host ("COPIED " + $hit.Name + "  ->  " + $m.dst)
  }
  $moved++
}

# ---------------------------------------------------------------------------
# Summary + next steps
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host ("placed " + $moved + " of " + $map.Count + " file(s)")

if ($missing.Count -gt 0) {
  Write-Host ''
  Write-Host 'NOT FOUND in Downloads (download them, then re-run this script):'
  foreach ($x in $missing) { Write-Host ("  - " + $x) }
}

if ($moved -eq $map.Count -and -not $DryRun) {
  Write-Host ''
  Write-Host 'next:'
  Write-Host '  cd C:\dev\mbg-project'
  Write-Host '  git status -sb'
  Write-Host '  git add -A'
  Write-Host '  git commit -m "fix(calendar): edit/delete for meetings + refresh client feed after mutations"'
  Write-Host '  git push origin marinebiogroup      # push = auto-deploy (repo is PUBLIC)'
}
Write-Host ''
