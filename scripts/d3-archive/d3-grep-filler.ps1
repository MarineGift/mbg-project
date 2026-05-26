# =============================================================================
# d3-grep-filler.ps1
# 목적: 코드베이스에서 'filler' string literal 사용처 식별
#       (마이그레이션 후 'filler_supplier' 로 변경할 대상 목록)
# 범위: src/ 하위 .ts, .tsx 파일만
# 제외: 'filler_supplier' 는 이미 올바른 값 (변경 대상 아님)
# 출력: d3-filler-grep-report.md
# =============================================================================

$scriptName = 'd3-grep-filler.ps1'

# Downloads → 작업 디렉토리
$downloadsPath = Join-Path $env:USERPROFILE "Downloads\$scriptName"
if (Test-Path -LiteralPath $downloadsPath) {
    Move-Item -LiteralPath $downloadsPath -Destination . -Force
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Unblock-File -LiteralPath ".\$scriptName" -ErrorAction SilentlyContinue
Set-Location -LiteralPath 'C:\dev\mbg-project'

# ---------------------------------------------------------------------------
# 검색 패턴: 'filler' 또는 "filler" 또는 `filler` (quote 로 둘러싸인 정확히 'filler')
# filler_supplier, fillerData, fillerCount 등 식별자는 제외됨 (quote 가 없으므로)
# ---------------------------------------------------------------------------

$srcDir = 'src'
if (-not (Test-Path -LiteralPath $srcDir)) {
    Write-Host "[ERROR] $srcDir 디렉토리 없음" -ForegroundColor Red
    exit 1
}

Write-Host "스캔 중: $srcDir/**/*.{ts,tsx}" -ForegroundColor Cyan

$files = Get-ChildItem -Path $srcDir -Recurse -Include *.ts, *.tsx -File
Write-Host "파일 수: $($files.Count)" -ForegroundColor DarkGray

$matchList = New-Object System.Collections.Generic.List[psobject]
$fileMatchCount = @{}

# 정확히 'filler' / "filler" / `filler` (단어 경계 + quote)
# (?<![A-Za-z0-9_]) = 앞이 식별자 문자 아님
# (?![A-Za-z0-9_])  = 뒤가 식별자 문자 아님
# 사실 quote 로 둘러싸여 있으므로 _supplier 가 뒤에 못 옴

foreach ($file in $files) {
    $rel = $file.FullName.Replace((Get-Location).Path + '\', '')
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        # 세 가지 quote 스타일 모두 검사
        $isMatch = $false
        if     ($line -match "'filler'")  { $isMatch = $true }
        elseif ($line -match '"filler"')  { $isMatch = $true }
        elseif ($line -match '`filler`')  { $isMatch = $true }
        if ($isMatch) {
            $matchList.Add([pscustomobject]@{
                File = $rel
                Line = $i + 1
                Text = $line.TrimEnd()
            })
            $fileMatchCount[$rel] = ($fileMatchCount[$rel] + 1)
        }
    }
}

# ---------------------------------------------------------------------------
# 보고서 작성
# ---------------------------------------------------------------------------
$report = New-Object System.Collections.Generic.List[string]
$report.Add("# 'filler' string literal grep 결과")
$report.Add("")
$report.Add("- **생성 시각**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$report.Add("- **검색 범위**: ``src/**/*.{ts,tsx}``")
$report.Add("- **검색 패턴**: ``'filler'``, ``""filler""``, ```filler` `` (quote 로 둘러싸인 정확한 매치)")
$report.Add("- **제외**: 식별자 (``fillerData``, ``FillerSupplier`` 등), 'filler_supplier'")
$report.Add("- **총 파일**: $($files.Count)")
$report.Add("- **매치 파일**: $($fileMatchCount.Count)")
$report.Add("- **매치 라인 총합**: $($matchList.Count)")
$report.Add("")
$report.Add("## 파일별 매치 분포")
$report.Add("")
$report.Add("| Count | File |")
$report.Add("|---:|---|")
$fileMatchCount.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    $report.Add("| $($_.Value) | ``$($_.Key)`` |")
}
$report.Add("")
$report.Add("## 라인별 상세")
$report.Add("")

$currentFile = ''
foreach ($m in $matchList) {
    if ($m.File -ne $currentFile) {
        $currentFile = $m.File
        $report.Add("### ``$currentFile``")
        $report.Add("")
    }
    $report.Add("**L$($m.Line)**")
    $report.Add('```typescript')
    $report.Add($m.Text)
    $report.Add('```')
    $report.Add("")
}

# ---------------------------------------------------------------------------
# 출력
# ---------------------------------------------------------------------------
$outputFile = 'd3-filler-grep-report.md'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines((Join-Path (Get-Location) $outputFile), $report, $utf8NoBom)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  grep 완료" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  출력 파일      : $outputFile"               -ForegroundColor Cyan
Write-Host "  매치 파일 수   : $($fileMatchCount.Count)"   -ForegroundColor Cyan
Write-Host "  매치 라인 합계 : $($matchList.Count)"        -ForegroundColor Cyan
Write-Host ""
