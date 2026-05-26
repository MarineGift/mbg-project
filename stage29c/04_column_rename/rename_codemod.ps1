# Stage 29-c Column Rename Codemod (PowerShell)
#
# 사용법:
#   .\rename_codemod.ps1 -ProjectRoot . -DryRun         # 미리보기만
#   .\rename_codemod.ps1 -ProjectRoot . -Apply          # 실제 적용
#   .\rename_codemod.ps1 -ProjectRoot . -Apply -Confirm # 각 매치 별로 y/n 물음
#
# 주의:
#   1. -DryRun 으로 먼저 검토 필수
#   2. git working tree clean 상태에서 실행 (revert 용이)
#   3. party_type → party_type_id 는 단순 rename 안 됨. 별도 처리 (party_type_join_pattern.ts)

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot,
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$Confirm,
    [string[]]$IncludeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts"),
    [string[]]$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")
)

if (-not $DryRun -and -not $Apply) {
    Write-Host "ERROR: -DryRun 또는 -Apply 중 하나 필수" -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Stop"
$projectRootFull = (Resolve-Path $ProjectRoot).Path

Write-Host "=== Stage 29-c Column Rename Codemod ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
Write-Host "Project root: $projectRootFull"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────
# 매핑 정의
# 각 entry: { Pattern, Replacement, Description, Scope }
#   Scope: "app" | "urm" | "both" | "code" — caller 호출 컨텍스트 힌트
# ─────────────────────────────────────────────────────────────────────────

$renames = @(
    # === A3 의 V1 caller bug (실재 컬럼명 불일치) ===
    @{
        Pattern     = '(?<![a-zA-Z0-9_])org_id(?![a-zA-Z0-9_])'
        Replacement = 'organization_id'
        Description = 'org_id → organization_id (app.* 모든 테이블)'
        Scope       = "both"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])body_text(?![a-zA-Z0-9_])'
        Replacement = 'body_plain'
        Description = 'body_text → body_plain (app.communications)'
        Scope       = "app"
    },
    @{
        Pattern     = "(?<![a-zA-Z0-9_])'country'(?![a-zA-Z0-9_])"
        Replacement = "'country_code'"
        Description = "'country' literal → 'country_code' (app.parties)"
        Scope       = "app"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])"country"(?![a-zA-Z0-9_])'
        Replacement = '"country_code"'
        Description = '"country" literal → "country_code" (app.parties)'
        Scope       = "app"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])\.country(?![a-zA-Z0-9_])'
        Replacement = '.country_code'
        Description = '.country accessor → .country_code'
        Scope       = "both"
    },

    # === A3 의 stage_position (urm.stages 의 실재 컬럼은 sort_order) ===
    @{
        Pattern     = '(?<![a-zA-Z0-9_])stage_position(?![a-zA-Z0-9_])'
        Replacement = 'sort_order'
        Description = 'stage_position → sort_order (urm.stages)'
        Scope       = "urm"
    },

    # === Stage 29-b δ 의 9 deprecated profile 테이블 reference (caller 가 .from() 에 쓰면 실패) ===
    # 이건 단순 rename 이 아니라 "코드 제거 또는 다른 logic 으로 대체" 가 정답.
    # 여기선 검색만 (실제 적용 안 함). audit script 의 A6 와 중복되므로 skip.

    # === handoff §A5 의 module_data 이전 패턴 ===
    # caller 가 .module_data._app_* 접근하는 경우 그대로 두기 (V2 jsonb 보존 logic)
    # 이건 자동 변환 대상 아님.

    # === V1 의 portfolio_company_id (FK) 를 V2 의 module_data._app_portfolio_company_id 로 ===
    # 이것도 단순 rename 어려움 — caller 측 query 패턴 자체가 달라짐.
    # 별도 manual review 후보.
)

# ─────────────────────────────────────────────────────────────────────────
# 파일 list
# ─────────────────────────────────────────────────────────────────────────

$excludeRegex = ($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"

$allFiles = Get-ChildItem -Path $projectRootFull -Recurse -Include $IncludeExts -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "[\\/]($excludeRegex)[\\/]" -and
        $_.FullName -notmatch "[\\/]($excludeRegex)$"
    }

Write-Host "Scanning $($allFiles.Count) files" -ForegroundColor Gray
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────
# 실행
# ─────────────────────────────────────────────────────────────────────────

$grandTotalMatches = 0
$grandTotalFilesChanged = 0
$logEntries = @()

foreach ($rename in $renames) {
    Write-Host "[$($rename.Description)] (scope: $($rename.Scope))" -ForegroundColor Yellow
    Write-Host "  Pattern: $($rename.Pattern)" -ForegroundColor Gray
    Write-Host "  Replace: $($rename.Replacement)" -ForegroundColor Gray

    $patternMatchCount = 0
    $patternFilesChangedCount = 0

    foreach ($file in $allFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        } catch {
            continue
        }
        if (-not $content) { continue }

        $matches = [regex]::Matches($content, $rename.Pattern)
        if ($matches.Count -eq 0) { continue }

        $patternMatchCount += $matches.Count
        $patternFilesChangedCount += 1

        $relPath = $file.FullName.Replace($projectRootFull, "").TrimStart("\", "/")

        Write-Host "  -> $relPath ($($matches.Count) matches)" -ForegroundColor Cyan
        # 매치 라인 sample (앞 3개)
        $lines = $content -split "`n"
        $matchedLineNumbers = @()
        $cursor = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineStart = $cursor
            $lineEnd = $cursor + $lines[$i].Length
            foreach ($m in $matches) {
                if ($m.Index -ge $lineStart -and $m.Index -lt $lineEnd) {
                    $matchedLineNumbers += $i + 1
                }
            }
            $cursor = $lineEnd + 1  # +1 for newline
        }
        $matchedLineNumbers = $matchedLineNumbers | Select-Object -Unique | Sort-Object
        $sampleLines = $matchedLineNumbers | Select-Object -First 3
        foreach ($ln in $sampleLines) {
            $lineContent = $lines[$ln - 1].Trim()
            if ($lineContent.Length -gt 100) { $lineContent = $lineContent.Substring(0, 97) + "..." }
            Write-Host "     L$ln`: $lineContent" -ForegroundColor DarkGray
        }
        if ($matchedLineNumbers.Count -gt 3) {
            Write-Host "     ... ($($matchedLineNumbers.Count - 3) more)" -ForegroundColor DarkGray
        }

        $logEntries += [PSCustomObject]@{
            File         = $relPath
            Pattern      = $rename.Description
            Matches      = $matches.Count
            LineNumbers  = ($matchedLineNumbers -join ", ")
        }

        # 적용
        if ($Apply) {
            $proceed = $true
            if ($Confirm) {
                $answer = Read-Host "  Apply to $relPath? (y/N)"
                if ($answer -notmatch '^[Yy]') { $proceed = $false }
            }
            if ($proceed) {
                $newContent = [regex]::Replace($content, $rename.Pattern, $rename.Replacement)
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                Write-Host "     ✓ Applied" -ForegroundColor Green
            } else {
                Write-Host "     - Skipped" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "  ## Sub-total: $patternMatchCount matches in $patternFilesChangedCount files" -ForegroundColor White
    Write-Host ""

    $grandTotalMatches += $patternMatchCount
    $grandTotalFilesChanged += $patternFilesChangedCount
}

# ─────────────────────────────────────────────────────────────────────────
# 결과
# ─────────────────────────────────────────────────────────────────────────

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total matches  : $grandTotalMatches"
Write-Host "Files affected : $grandTotalFilesChanged"
Write-Host ""

# 로그 저장
$logFile = Join-Path -Path $projectRootFull -ChildPath "stage29c_rename_log.csv"
$logEntries | Export-Csv -Path $logFile -NoTypeInformation -Encoding UTF8
Write-Host "Log: $logFile"
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN — 실제 변경 없음. -Apply 로 재실행 시 적용." -ForegroundColor Yellow
}
if ($Apply) {
    Write-Host "APPLIED — git diff 로 변경 검토 + 빌드 확인 후 commit." -ForegroundColor Green
    Write-Host "  git diff > stage29c_rename.patch"
    Write-Host "  npm run build"
    Write-Host "  npx tsc --noEmit"
}

# party_type 특수 케이스 안내
Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "특수 케이스: party_type → party_type_id" -ForegroundColor DarkYellow
Write-Host "──────────────────────────────────────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "이 codemod 는 party_type 자동 변경 안 함 (단순 rename 으로 해결 안 되는 FK 매핑)."
Write-Host "별도 manual review: party_type_join_pattern.ts 참조."
Write-Host "audit script 의 A4 결과 사용해서 호출 사이트 list 만들고 case-by-case 처리."
