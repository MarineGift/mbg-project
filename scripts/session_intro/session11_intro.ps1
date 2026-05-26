# =====================================================================
# session11_intro.ps1   (ASCII-only, PS 5.1 safe)
# =====================================================================
# Purpose:
#   Generate environment snapshot + ready-to-paste message template for
#   starting a new Claude session.
#
# Output:
#   - Console: snapshot of git/tsc/env state
#   - Files:
#       session11_intro_out.txt      console output (full)
#       session11_message.md         message template to paste into new
#                                    Claude session (with snapshot embedded)
#
# Usage:
#   .\session11_intro.ps1
#   Then paste session11_message.md content into the new Claude session
#   along with the handoff file (docs/handoffs/SESSION_HANDOFF_*.md)
#
# Notes:
#   - All Write-Host strings are ASCII (Gotcha #44 compliance)
#   - Korean only in single-line comments
#   - Output also Tee-Object'd to file for convenient paste
# =====================================================================

$ErrorActionPreference = 'Continue'
Set-Location C:\dev\mbg-project

# ---------------------------------------------------------------------
# Output collection (we'll write to both console and file at the end)
# ---------------------------------------------------------------------
$lines = @()

function Add-Line {
  param([string]$text = '', [string]$color = 'White')
  $script:lines += $text
  if ($color -eq 'Cyan')        { Write-Host $text -ForegroundColor Cyan }
  elseif ($color -eq 'Yellow')  { Write-Host $text -ForegroundColor Yellow }
  elseif ($color -eq 'Green')   { Write-Host $text -ForegroundColor Green }
  elseif ($color -eq 'Red')     { Write-Host $text -ForegroundColor Red }
  else                          { Write-Host $text }
}

# ---------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------
Add-Line '===== Session 11 intro snapshot =====' 'Cyan'
Add-Line ('  generated at: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ''

# ---------------------------------------------------------------------
# A. Git state
# ---------------------------------------------------------------------
Add-Line '===== A. git =====' 'Cyan'

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
$head = (git rev-parse --short HEAD).Trim()
Add-Line "  branch: $branch"
Add-Line "  HEAD:   $head"

Add-Line ''
Add-Line '  recent commits:'
$logOutput = git --no-pager log --oneline -5 2>&1 | Out-String
$logOutput.Trim() -split "`r?`n" | ForEach-Object { Add-Line "    $_" }

# tracked changes (exclude untracked)
$status = git status --porcelain 2>&1
$tracked = @($status | Where-Object { $_ -notmatch '^\?\?' })
$untracked = @($status | Where-Object { $_ -match '^\?\?' })

Add-Line ''
if ($tracked.Count -eq 0) {
  Add-Line '  working tree: clean (no tracked changes)' 'Green'
} else {
  Add-Line "  working tree: $($tracked.Count) tracked changes" 'Yellow'
  $tracked | Select-Object -First 5 | ForEach-Object { Add-Line "    $_" }
}
Add-Line "  untracked: $($untracked.Count) items (.bak / stage scripts / build artifacts, gitignored)"

# origin sync check
$aheadBehind = git rev-list --left-right --count "origin/$branch...HEAD" 2>&1
if ($LASTEXITCODE -eq 0) {
  $parts = $aheadBehind.Trim() -split '\s+'
  if ($parts.Count -ge 2 -and $parts[0] -eq '0' -and $parts[1] -eq '0') {
    Add-Line '  origin: in sync' 'Green'
  } else {
    Add-Line ("  origin: behind=$($parts[0]) ahead=$($parts[1])") 'Yellow'
  }
}

# ---------------------------------------------------------------------
# B. tsc baseline + hotspots
# ---------------------------------------------------------------------
Add-Line ''
Add-Line '===== B. tsc =====' 'Cyan'

$tscOutput = npx tsc --noEmit 2>&1 | Out-String
$tscLines = $tscOutput -split "`r?`n" | Where-Object { $_ -match 'error TS' }
$tscCount = $tscLines.Count
Add-Line "  total errors: $tscCount"

Add-Line ''
Add-Line '  file-level hotspots:'
$hotspots = @(
  'email-compose.ts',
  'email-sequences.ts',
  'email-tracking.ts',
  'sequence-processor.ts',
  'party-communications-timeline',
  'email-whitelist.ts',
  'communications.ts'
)
foreach ($h in $hotspots) {
  $cnt = ($tscLines | Where-Object { $_ -like "*$h*" }).Count
  if ($cnt -gt 0) {
    Add-Line ("    {0,-40} : {1}" -f $h, $cnt)
  }
}

# Sum of hotspots vs total
$hotspotSum = 0
foreach ($h in $hotspots) {
  $hotspotSum += ($tscLines | Where-Object { $_ -like "*$h*" }).Count
}
$otherCount = $tscCount - $hotspotSum
Add-Line ("    {0,-40} : {1}" -f '(others, scattered)', $otherCount)

# ---------------------------------------------------------------------
# C. Node / package scripts
# ---------------------------------------------------------------------
Add-Line ''
Add-Line '===== C. node / package scripts =====' 'Cyan'

$nodeVer = (node --version) 2>&1
$npmVer = (npm --version) 2>&1
Add-Line "  node: $nodeVer"
Add-Line "  npm:  $npmVer"

Add-Line ''
Add-Line '  package.json scripts:'
$scripts = node -e "const p=require('./package.json'); console.log(Object.keys(p.scripts).join(' '))" 2>&1
Add-Line "    $scripts"

# ---------------------------------------------------------------------
# D. src structure
# ---------------------------------------------------------------------
Add-Line ''
Add-Line '===== D. src structure =====' 'Cyan'

$srcDirs = Get-ChildItem src -Directory | Select-Object -ExpandProperty Name
Add-Line ("  src/: " + ($srcDirs -join ', '))

$nextExists = Test-Path .next
Add-Line "  .next build cache: $nextExists"

# ---------------------------------------------------------------------
# E. Handoff files
# ---------------------------------------------------------------------
Add-Line ''
Add-Line '===== E. handoff files =====' 'Cyan'

$handoffPath = 'docs\handoffs'
if (Test-Path $handoffPath) {
  $handoffs = Get-ChildItem $handoffPath -Filter '*.md' | Sort-Object Name -Descending
  if ($handoffs.Count -gt 0) {
    Add-Line "  found $($handoffs.Count) handoff file(s):"
    $handoffs | Select-Object -First 3 | ForEach-Object {
      Add-Line ("    " + $_.Name + "  (" + [math]::Round($_.Length / 1024, 1) + " KB)")
    }
    $latestHandoff = $handoffs[0].FullName
    Add-Line ''
    Add-Line "  latest: $($handoffs[0].Name)" 'Green'
  } else {
    Add-Line '  [WARN] docs\handoffs exists but no .md files' 'Yellow'
    $latestHandoff = $null
  }
} else {
  Add-Line '  [WARN] docs\handoffs not found' 'Yellow'
  $latestHandoff = $null
}

# ---------------------------------------------------------------------
# F. Write snapshot file
# ---------------------------------------------------------------------
$snapshotPath = 'session11_intro_out.txt'
$lines | Out-File -FilePath $snapshotPath -Encoding utf8
Add-Line ''
Add-Line "===== output saved =====" 'Cyan'
Add-Line "  snapshot:        $snapshotPath"

# ---------------------------------------------------------------------
# G. Generate new-session message template
# ---------------------------------------------------------------------
$msgPath = 'session11_message.md'

$msg = @"
# Session 11 start

**Attached**: ``docs/handoffs/$(if ($latestHandoff) { (Split-Path -Leaf $latestHandoff) } else { '<handoff file>' })``

## Current environment (just measured)

- **branch**: $branch
- **HEAD**: $head
- **working tree**: $(if ($tracked.Count -eq 0) { 'clean' } else { "$($tracked.Count) tracked changes" })
- **origin**: $(if ($parts.Count -ge 2 -and $parts[0] -eq '0' -and $parts[1] -eq '0') { 'in sync' } else { 'see snapshot' })
- **tsc**: $tscCount errors
- **tsc hotspots**:
"@

foreach ($h in $hotspots) {
  $cnt = ($tscLines | Where-Object { $_ -like "*$h*" }).Count
  if ($cnt -gt 0) {
    $msg += "`n  - ``$h``: $cnt"
  }
}

$msg += @"

  - others, scattered: $otherCount

- **node**: $nodeVer, **npm**: $npmVer
- **src/**: $($srcDirs -join ', ')
- **.next build cache**: $nextExists

## Intent

Session 10 까지 DB 구조 / URM 백본 작업 종료 (Stage 22-27 atomic, tsc 137 -> 121).
이번 session 부터 **프로그램 연결** 작업 시작.
DB 변경 (URM 통합) 으로 인해 frontend/backend 의 일부 재작업 필요.

### Priority decision

- **A**: tsc 121 errors 일소 우선 (Stage 28 email-compose schema-generic fix 부터)
- **B**: 운영 flow 정상화 우선 (어느 module UI 부터 정상화하고 싶은지 물어주세요)
- **C**: 병렬 — email feature 는 tsc 일소, 다른 module 은 UI 검증

email 관련 errors 가 약 70% 차지 (compose 20 + sequences 14 + tracking 13 + processor 11 + whitelist 6 + communications 5 = 69). A 와 C 가 자연스럽게 겹침.

사용자 선택 부탁.
"@

$msg | Out-File -FilePath $msgPath -Encoding utf8
Add-Line "  message:         $msgPath"

Add-Line ''
Add-Line '===== next step =====' 'Yellow'
Add-Line '  1. open session11_message.md and copy its content'
Add-Line '  2. start new Claude session'
Add-Line '  3. paste the message + attach the handoff .md file'
Add-Line '  4. wait for priority decision response'
