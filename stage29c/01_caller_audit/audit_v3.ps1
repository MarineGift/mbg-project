# Stage 29-c Caller Code Audit (PowerShell, robust v3)
# All regex patterns single-quoted; quotes use \x27 / \x22 hex escapes.

param(
    [string]$ProjectRoot = ".",
    [string]$OutFile = ".\stage29c_audit_report.md"
)

$ErrorActionPreference = "Stop"
$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")

$projectRootFull = (Resolve-Path $ProjectRoot).Path
Write-Host "=== Stage 29-c Caller Audit v3 ===" -ForegroundColor Cyan
Write-Host ("Project root: " + $projectRootFull)
Write-Host ("Output: " + $OutFile)
Write-Host ""

function Find-Pattern {
    param([string]$Pattern, [string]$Root)
    $exts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts")
    $excludeRegex = "node_modules|\.next|dist|build|\.git|coverage|outputs|stage29c"
    Get-ChildItem -Path $Root -Recurse -Include $exts -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludeRegex } |
        Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
}

# Audit categories. ALL patterns are single-quoted regex.
# Quote chars in regex use \x27 (apostrophe) and \x22 (double-quote) — no quote nesting needed.
$audits = @(
    @{ Name = 'A1. SbClient factory'; Critical = $true; Patterns = @(
        'SupabaseClient<Database',
        'createClient<Database',
        'createServerClient<Database',
        'createBrowserClient<Database'
    )},
    @{ Name = 'A2. schema-prefixed .from()'; Critical = $true; Patterns = @(
        '\.from\([\x27\x22]app\.',
        '\.from\([\x27\x22]urm\.',
        '\.schema\([\x27\x22](app|urm)[\x27\x22]\)'
    )},
    @{ Name = 'A3. wrong column refs (V1 bug)'; Critical = $true; Patterns = @(
        '\borg_id\b',
        '\bbody_text\b',
        '[\x27\x22]country[\x27\x22]',
        '\.country\s*[=,)]',
        'stage_position'
    )},
    @{ Name = 'A4. party_type direct enum'; Critical = $true; Patterns = @(
        '\.eq\([\x27\x22]party_type[\x27\x22]',
        'party_type\s*===',
        'party_type:\s*[\x27\x22]',
        'PartyType\.',
        'party_type\s*[=:]\s*[\x27\x22]'
    )},
    @{ Name = 'A5. RPC calls'; Critical = $false; Patterns = @(
        '\.rpc\([\x27\x22][a-zA-Z_]+',
        'supabase\.rpc'
    )},
    @{ Name = 'A6. 9 deprecated profile refs'; Critical = $true; Patterns = @(
        'buyer_profile',
        'buyer_partner_profile',
        'customer_profile',
        'govt_grant_profile',
        'govt_grant_contact_profile',
        'partner_profile',
        'partner_audits',
        'partner_capabilities',
        'filler_supplier_contact_profile'
    )},
    @{ Name = 'A7. portfolio_companies V1 refs'; Critical = $true; Patterns = @(
        '\bportfolio_companies\b',
        'v_portfolio_with_investors'
    )},
    @{ Name = 'A8. parent_party_id / party_level'; Critical = $false; Patterns = @(
        'parent_party_id',
        '\bparty_level\b'
    )},
    @{ Name = 'A9. urm new table refs'; Critical = $false; Patterns = @(
        'contacts_history',
        'party_supply_links',
        'plant_supply_links',
        'deal_checklists',
        'deal_stage_history',
        'engagement_attendees',
        'engagement_documents',
        'party_types'
    )},
    @{ Name = 'A10. fund / organization literals'; Critical = $false; Patterns = @(
        '[\x27\x22]fund[\x27\x22]',
        '[\x27\x22]organization[\x27\x22]'
    )}
)

$report = New-Object System.Collections.Generic.List[string]
$report.Add('# Stage 29-c Caller Audit Report')
$report.Add('')
$report.Add('**Project root**: `' + $projectRootFull + '`')
$report.Add('**Generated**: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$report.Add('')
$report.Add('---')
$report.Add('')

$summaryRows = New-Object System.Collections.Generic.List[string]
$detail = New-Object System.Collections.Generic.List[string]

foreach ($audit in $audits) {
    Write-Host ('[' + $audit.Name + ']') -ForegroundColor Yellow
    $allMatches = @()
    foreach ($pat in $audit.Patterns) {
        $found = Find-Pattern -Pattern $pat -Root $projectRootFull
        if ($found) { $allMatches += $found }
    }
    $count = $allMatches.Count
    $mark = if ($audit.Critical) { '[!]' } else { '[i]' }
    $summaryRows.Add('| ' + $mark + ' | ' + $audit.Name + ' | ' + $count + ' |')

    $detail.Add('## ' + $audit.Name)
    $detail.Add('')
    $detail.Add('**Patterns**: `' + ($audit.Patterns -join '`, `') + '`')
    $detail.Add('**Match count**: **' + $count + '**')
    $detail.Add('')

    if ($count -eq 0) {
        $detail.Add('(no matches)')
        $detail.Add('')
        Write-Host '  -> 0 matches' -ForegroundColor Green
    } else {
        Write-Host ('  -> ' + $count + ' matches') -ForegroundColor Red
        $detail.Add('| File | Line | Content |')
        $detail.Add('|---|---:|---|')
        foreach ($m in ($allMatches | Sort-Object Filename, LineNumber)) {
            $relPath = $m.Path.Replace($projectRootFull, '').TrimStart('\', '/')
            $content = $m.Line.Trim() -replace '\|', '\|'
            if ($content.Length -gt 120) { $content = $content.Substring(0, 117) + '...' }
            $detail.Add('| `' + $relPath + '` | ' + $m.LineNumber + ' | `' + $content + '` |')
        }
        $detail.Add('')
    }
}

$report.Add('## Summary')
$report.Add('')
$report.Add('| Crit | Audit | Matches |')
$report.Add('|---|---|---:|')
foreach ($r in $summaryRows) { $report.Add($r) }
$report.Add('')
$report.Add('---')
$report.Add('')
foreach ($d in $detail) { $report.Add($d) }

# Write file as UTF-8 with BOM (Windows PowerShell 5.x friendly), CRLF line endings
$content = ($report -join "`r`n")
$utf8BomEnc = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path $OutFile -Parent)).Path + '\' + (Split-Path $OutFile -Leaf), $content, $utf8BomEnc)

Write-Host ''
Write-Host '=== Done ===' -ForegroundColor Cyan
Write-Host ('Report: ' + $OutFile)
Write-Host ''
Write-Host 'Summary:' -ForegroundColor Yellow
foreach ($r in $summaryRows) { Write-Host ('  ' + $r) }
