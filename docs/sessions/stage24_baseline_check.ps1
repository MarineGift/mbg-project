# =====================================================================
# stage24_baseline_check.ps1
# =====================================================================
# Session 7 시작 시 첫 명령. 환경 동일성 + Stage 24 출발점 측정.
# 결과를 Claude 에게 붙여넣고 작업 plan 받기.
# =====================================================================

$ErrorActionPreference = 'Continue'
Set-Location C:\dev\mbg-project

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Stage 24 BASELINE CHECK" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# ─────────────────────────────────────────────
# §1. Git 환경
# ─────────────────────────────────────────────
Write-Host "`n[§1] Git 환경" -ForegroundColor Yellow

Write-Host "`n  현재 branch:"
$branch = git branch --show-current
Write-Host "    $branch"
$branchOk = $branch -in @('feature/stage23-urm-cleanup', 'main', 'dev')
if (-not $branchOk) {
    Write-Host "    ! 예상 branch (feature/stage23-urm-cleanup or main/dev) 와 다름" -ForegroundColor Yellow
}

Write-Host "`n  최근 3 commits (58e5642 가 HEAD 또는 직전이어야 함):"
git --no-pager log --oneline -3

Write-Host "`n  stash (empty 여야 함):"
$stashList = git stash list
if ($stashList) { 
    Write-Host "    ! stash 존재:" -ForegroundColor Yellow
    $stashList 
} else { 
    Write-Host "    OK empty" -ForegroundColor Green 
}

Write-Host "`n  working tree 상태:"
$status = git status --short
if ($status) {
    Write-Host "    ! 변경/untracked 파일:"
    $status
} else {
    Write-Host "    OK clean" -ForegroundColor Green
}

# ─────────────────────────────────────────────
# §2. .bak 보존 확인 (Stage 24 비교용)
# ─────────────────────────────────────────────
Write-Host "`n[§2] .bak 보존 (Stage 23 backup, 비교용)" -ForegroundColor Yellow
$baks = Get-ChildItem -Path src -Recurse -Filter '*.bak'
Write-Host "`n  발견 .bak 파일: $($baks.Count) 개 (7 예상)"
$baks | Select-Object @{N='Path';E={$_.FullName.Replace((Get-Location).Path + '\', '')}}, Length |
  Format-Table -AutoSize

# ─────────────────────────────────────────────
# §3. tsc baseline
# ─────────────────────────────────────────────
Write-Host "`n[§3] tsc baseline (141 예상 — Stage 23 종료 시점)" -ForegroundColor Yellow
$tscOutput = npx tsc --noEmit 2>&1 | Out-String
$tscLines  = $tscOutput -split "`r?`n" | Where-Object { $_ -match 'error TS' }
$tscCount  = $tscLines.Count
Write-Host "`n  현재 tsc errors: $tscCount"
if ($tscCount -eq 141) {
    Write-Host "    OK Stage 23 종료 시점과 일치" -ForegroundColor Green
} else {
    Write-Host "    ! 141 과 다름 (delta $($tscCount - 141))" -ForegroundColor Yellow
}

Write-Host "`n  파일별 상위 8 (Stage 24 hotspot 식별):"
$tscLines | ForEach-Object {
    if ($_ -match '^([^(]+)\(') { $matches[1] }
} | Group-Object | Sort-Object Count -Descending | Select-Object -First 8 |
   Format-Table Count, Name -AutoSize

# ─────────────────────────────────────────────
# §4. Stage 24 작업 범위 — meetings 도메인
# ─────────────────────────────────────────────
Write-Host "`n[§4] Stage 24 작업 범위 (meetings 도메인)" -ForegroundColor Yellow

Write-Host "`n  [a] meetings.ts 옛 API export 위치:"
$oldApi = @(
    'fetchMeetings', 'fetchMeetingDetail', 'createMeeting',
    'updateMeeting', 'fetchUpcomingMeetings',
    'MeetingRow', 'MeetingAttendeeRow', 'CreateMeetingInput',
    'MeetingType', 'MeetingMode'
)
foreach ($sym in $oldApi) {
    $hit = Select-String -Path 'src\lib\queries\meetings.ts' -Pattern "^export\s+(async\s+function\s+|function\s+|type\s+|interface\s+|const\s+)$sym\b" |
           Select-Object -First 1
    if ($hit) {
        Write-Host "    OK $sym (line $($hit.LineNumber))" -ForegroundColor Cyan
    } else {
        Write-Host "    ?  $sym 미발견" -ForegroundColor Gray
    }
}

Write-Host "`n  [b] meetings.ts 옛 API import 사용처 (Stage 24 의 migration 대상):"
Get-ChildItem -Path src -Recurse -Include *.ts,*.tsx |
  Where-Object { $_.FullName -notmatch '\\meetings\.ts$' -and $_.FullName -notmatch '\.bak$' } |
  Select-String -Pattern "from\s+['""]@/lib/queries/meetings['""]" |
  Select-Object Path, LineNumber, Line | Format-Table -AutoSize -Wrap

Write-Host "`n  [c] meeting_mode / MeetingMode 사용처 (방향 Y 정리 대상):"
Get-ChildItem -Path src -Recurse -Include *.ts,*.tsx |
  Where-Object { $_.FullName -notmatch '\.bak$' } |
  Select-String -Pattern 'meeting_mode|meetingMode|MeetingMode' |
  Where-Object { $_.Line -notmatch '^//|^\s*\*' } |   # 코멘트 제외
  Select-Object Path, LineNumber, Line | Format-Table -AutoSize -Wrap

Write-Host "`n  [d] never 추론 hotspot 파일 (Stage 24 #3 작업 범위):"
$tscLines | ForEach-Object {
    if ($_ -match '^([^(]+)\(' -and $_ -match "'never'|never\[\]") { $matches[1] }
} | Group-Object | Sort-Object Count -Descending |
   Format-Table Count, Name -AutoSize

# ─────────────────────────────────────────────
# §5. 변경 후보 파일의 현재 라인 수 (Stage 24 작업량 추정)
# ─────────────────────────────────────────────
Write-Host "`n[§5] Stage 24 변경 후보 파일 — 현재 라인 수" -ForegroundColor Yellow
$candidates = @(
    'src\lib\queries\meetings.ts',
    'src\lib\queries\party-detail.ts',
    'src\lib\queries\calendar.ts',
    'src\components\meetings\meeting-create-modal.tsx',
    'src\lib\actions\email-sequences.ts',
    'src\lib\actions\email-compose.ts'
)
foreach ($file in $candidates) {
    if (Test-Path $file) {
        $lines = (Get-Content $file | Measure-Object -Line).Lines
        $bakPath = "$file.bak"
        if (Test-Path $bakPath) {
            $bakLines = (Get-Content $bakPath | Measure-Object -Line).Lines
            Write-Host "  $file : $lines lines (.bak: $bakLines)"
        } else {
            Write-Host "  $file : $lines lines (.bak 없음 — Stage 23 미수정)"
        }
    } else {
        Write-Host "  $file : NOT FOUND" -ForegroundColor Red
    }
}

# ─────────────────────────────────────────────
# 요약
# ─────────────────────────────────────────────
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  BASELINE CHECK 완료" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  이 출력 전체를 Claude 에게 붙여넣어 주세요." -ForegroundColor Yellow
Write-Host "  Claude 가 Stage 24 작업 plan 을 확정합니다." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
