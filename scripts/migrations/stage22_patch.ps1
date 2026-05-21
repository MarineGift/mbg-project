# ============================================================================
# Stage 22 patch — frontend code 정정 (mbg-project)
# Date: 2026-05-21
#
# Stage 21 (DB URM β+δ) 적용 후 frontend 동기화.
# 변경: RPC 인자명 p_org_id → p_organization_id (8 hits)
#       sequence-processor.ts:113 의 컬럼명 e.org_id → e.organization_id
#
# 안전: 각 파일 백업 (.bak) 생성 + idempotent
# ============================================================================

$ErrorActionPreference = 'Stop'
$root = Get-Location

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Stage 22 patch — mbg-project frontend 정정" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Working dir: $root" -ForegroundColor Gray
Write-Host ""

# 작업 대상 파일 + 변경 사양
$patches = @(
  @{
    File = 'src\lib\actions\email-sequences.ts'
    Changes = @(
      @{ Find = 'p_org_id:      orgId,';     Replace = 'p_organization_id: orgId,' },
      @{ Find = 'p_org_id:        orgId,';   Replace = 'p_organization_id: orgId,' }
    )
  },
  @{
    File = 'src\lib\queries\email-history.ts'
    Changes = @(
      @{ Find = 'p_org_id: orgId,';          Replace = 'p_organization_id: orgId,' }
    )
  },
  @{
    File = 'src\lib\queries\email-sequences.ts'
    Changes = @(
      @{ Find = 'p_org_id: orgId,';          Replace = 'p_organization_id: orgId,' }
    )
  },
  @{
    File = 'src\lib\utils\sequence-processor.ts'
    Changes = @(
      @{ Find = 'organization_id: e.org_id,';  Replace = 'organization_id: e.organization_id,' }
    )
  }
)

$totalChanges = 0
$totalFiles   = 0

foreach ($patch in $patches) {
  $filepath = Join-Path $root $patch.File

  if (-not (Test-Path $filepath)) {
    Write-Host "[SKIP] $($patch.File) — 파일 없음" -ForegroundColor Yellow
    continue
  }

  $content = Get-Content $filepath -Raw
  $original = $content
  $fileChanges = 0

  foreach ($change in $patch.Changes) {
    # 변경 전 count
    $beforeCount = ([regex]::Matches($content, [regex]::Escape($change.Find))).Count
    if ($beforeCount -gt 0) {
      $content = $content -replace [regex]::Escape($change.Find), $change.Replace
      $fileChanges += $beforeCount
      Write-Host "  - '$($change.Find)' x $beforeCount" -ForegroundColor Gray
    }
  }

  if ($fileChanges -gt 0) {
    # 백업 생성 (.bak)
    Copy-Item $filepath "$filepath.bak" -Force
    Set-Content $filepath -Value $content -NoNewline

    Write-Host "[OK]   $($patch.File) — $fileChanges 곳 변경" -ForegroundColor Green
    $totalChanges += $fileChanges
    $totalFiles++
  } else {
    Write-Host "[NOOP] $($patch.File) — 이미 적용됨 또는 패턴 없음" -ForegroundColor DarkGray
  }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Patch 완료: $totalFiles 파일, $totalChanges 곳" -ForegroundColor Green
Write-Host "백업: 각 파일에 .bak 으로 저장됨" -ForegroundColor Gray
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 step:" -ForegroundColor Yellow
Write-Host "  1. npx tsc --noEmit  (남은 type error 식별)" -ForegroundColor Yellow
Write-Host "  2. error 결과 그대로 전달 → 추가 patch 작성" -ForegroundColor Yellow
