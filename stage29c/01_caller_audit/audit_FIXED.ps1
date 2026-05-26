# Stage 29-c Caller Code Audit Script (PowerShell) — FIXED
# 사용법:
#   .\audit_FIXED.ps1                              # 현재 디렉토리 audit, 기본 출력
#   .\audit_FIXED.ps1 -ProjectRoot . -OutFile .\report.md
#
# 산출: Markdown 보고서 (매치 site list, count, 컨텍스트 라인 포함)
# 의존: PowerShell 5.0+ (기본 Windows 10/11 탑재)

param(
    [string]$ProjectRoot = ".",
    [string]$OutFile = ".\stage29c_audit_report.md",
    [string[]]$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")
)

$ErrorActionPreference = "Stop"
$projectRootFull = (Resolve-Path $ProjectRoot).Path

Write-Host "=== Stage 29-c Caller Audit ===" -ForegroundColor Cyan
Write-Host "Project root: $projectRootFull"
Write-Host "Output: $OutFile"
Write-Host ""

# --- helper: PowerShell Select-String 으로 패턴 검색
function Find-Pattern {
    param(
        [string]$Pattern,
        [string]$Root,
        [string[]]$IncludeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts")
    )
    $excludeRegex = ($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"
    Get-ChildItem -Path $Root -Recurse -Include $IncludeExts -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch "[\\/]($excludeRegex)[\\/]" -and
            $_.FullName -notmatch "[\\/]($excludeRegex)$"
        } |
        Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
}

# --- Audit categories (모든 regex 패턴 single-quoted 으로 안전 처리)
$audits = @(
    @{
        Name        = 'A1. SbClient factory 정의'
        Description = "SupabaseClient<Database, 'app'> generic schema 정의 site"
        Patterns    = @(
            'SupabaseClient<Database',
            'createClient<Database',
            'createServerClient<Database',
            'createBrowserClient<Database'
        )
        Critical    = $true
    },
    @{
        Name        = 'A2. schema-prefixed .from() 호출'
        Description = '.from("app.*") 또는 .from("urm.*") 패턴'
        Patterns    = @(
            '\.from\([''"]app\.',
            '\.from\([''"]urm\.',
            '\.schema\([''"](app|urm)[''"]\)'
        )
        Critical    = $true
    },
    @{
        Name        = 'A3. 잘못된 컬럼 reference (V1 bug)'
        Description = 'DB 에 실재하지 않는 컬럼 이름. caller 의 hard-coded bug'
        Patterns    = @(
            '\borg_id\b',
            '\bbody_text\b',
            '[''"]country[''"]',
            '\.country\s*[=,)]',
            'stage_position'
        )
        Critical    = $true
    },
    @{
        Name        = 'A4. party_type 직접 enum 비교'
        Description = 'urm 에서 party_type_id (FK) 로 바뀐 패턴. JOIN 패턴 필요'
        Patterns    = @(
            '\.eq\([''"]party_type[''"]',
            'party_type\s*===',
            'party_type:\s*[''"]',
            'PartyType\.',
            'party_type\s*[=:]\s*[''"]'
        )
        Critical    = $true
    },
    @{
        Name        = 'A5. RPC 호출'
        Description = 'Supabase RPC 호출. V1→V2 함수 매핑 검토'
        Patterns    = @(
            '\.rpc\([''"][a-zA-Z_]+',
            'supabase\.rpc'
        )
        Critical    = $false
    },
    @{
        Name        = 'A6. 9 deprecated profile 테이블 reference'
        Description = 'Stage 29-b δ 에서 DROP 된 테이블. 남아있으면 빌드 fail'
        Patterns    = @(
            'buyer_profile',
            'buyer_partner_profile',
            'customer_profile',
            'govt_grant_profile',
            'govt_grant_contact_profile',
            'partner_profile',
            'partner_audits',
            'partner_capabilities',
            'filler_supplier_contact_profile'
        )
        Critical    = $true
    },
    @{
        Name        = 'A7. portfolio_companies (V1) reference'
        Description = 'Stage 29-b δ Port-1 에서 DROP. urm.investor_portfolio_companies 로 이전'
        Patterns    = @(
            '\bportfolio_companies\b',
            'v_portfolio_with_investors'
        )
        Critical    = $true
    },
    @{
        Name        = 'A8. parent_party_id / party_level reference'
        Description = '3-tier hierarchy DROP 결정 (handoff §8). carry 안 함'
        Patterns    = @(
            'parent_party_id',
            '\bparty_level\b'
        )
        Critical    = $false
    },
    @{
        Name        = 'A9. urm 신규 테이블 references'
        Description = '이미 urm 으로 일부 이전된 코드'
        Patterns    = @(
            'contacts_history',
            'party_supply_links',
            'plant_supply_links',
            'deal_checklists',
            'deal_stage_history',
            'engagement_attendees',
            'engagement_documents',
            'party_types'
        )
        Critical    = $false
    },
    @{
        Name        = 'A10. fund / organization party_type 사용'
        Description = 'Stage 29-b ε 에서 hard-delete. caller 가 참조 시 0 row'
        Patterns    = @(
            '[''"]fund[''"]',
            '[''"]organization[''"]'
        )
        Critical    = $false
    }
)

# --- 실행
$report = New-Object System.Collections.Generic.List[string]
$report.Add('# Stage 29-c Caller Audit Report')
$report.Add('')
$report.Add(('**Project root**: `' + $projectRootFull + '`'))
$report.Add(('**Generated**: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
$report.Add('')
$report.Add('---')
$report.Add('')

$summaryRows = New-Object System.Collections.Generic.List[string]
$detailReport = New-Object System.Collections.Generic.List[string]

foreach ($audit in $audits) {
    Write-Host ('[' + $audit.Name + '] ' + $audit.Description) -ForegroundColor Yellow

    $allMatches = @()
    foreach ($pat in $audit.Patterns) {
        $foundMatches = Find-Pattern -Pattern $pat -Root $projectRootFull
        if ($foundMatches) { $allMatches += $foundMatches }
    }

    $count = $allMatches.Count
    $criticalMark = if ($audit.Critical) { '[!]' } else { '[i]' }
    $summaryRows.Add(('| ' + $criticalMark + ' | ' + $audit.Name + ' | ' + $count + ' |'))

    $detailReport.Add(('## ' + $audit.Name))
    $detailReport.Add('')
    $detailReport.Add(('**Description**: ' + $audit.Description))
    $detailReport.Add(('**Patterns**: `' + ($audit.Patterns -join '`, `') + '`'))
    $detailReport.Add(('**Match count**: **' + $count + '**'))
    $detailReport.Add('')

    if ($count -eq 0) {
        $detailReport.Add('(매치 없음)')
        $detailReport.Add('')
        Write-Host '  -> 0 matches' -ForegroundColor Green
    }
    else {
        Write-Host ('  -> ' + $count + ' matches') -ForegroundColor Red
        $detailReport.Add('| File | Line | Content |')
        $detailReport.Add('|---|---:|---|')
        foreach ($m in ($allMatches | Sort-Object Filename, LineNumber)) {
            $relPath = $m.Path.Replace($projectRootFull, '').TrimStart('\', '/')
            $content = $m.Line.Trim() -replace '\|', '\|'
            if ($content.Length -gt 120) { $content = $content.Substring(0, 117) + '...' }
            $detailReport.Add(('| `' + $relPath + '` | ' + $m.LineNumber + ' | `' + $content + '` |'))
        }
        $detailReport.Add('')
    }
}

# --- 최종 보고서 조립
$report.Add('## §0. Summary (critical first)')
$report.Add('')
$report.Add('| Crit | Audit | Matches |')
$report.Add('|---|---|---:|')
foreach ($r in $summaryRows) { $report.Add($r) }
$report.Add('')
$report.Add('---')
$report.Add('')
foreach ($r in $detailReport) { $report.Add($r) }

$report | Out-File -FilePath $OutFile -Encoding UTF8

Write-Host ''
Write-Host '=== Done ===' -ForegroundColor Cyan
Write-Host ('Report written: ' + $OutFile)
Write-Host ''
Write-Host 'Summary:' -ForegroundColor Yellow
foreach ($r in $summaryRows) { Write-Host ('  ' + $r) }
