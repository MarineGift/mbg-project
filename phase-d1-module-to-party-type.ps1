# =============================================================================
# Phase D1: Code-side module -> party_type cleanup
# Fixes runtime "column parties.module does not exist" errors
# DryRun by default. Set $Apply = $true and re-run to apply.
# =============================================================================

$ErrorActionPreference = 'Stop'
$Apply = $true   # set $true to apply

function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path $Path)) {
        Write-Host ("  [MISS] file not found: " + $Path) -ForegroundColor DarkGray
        return
    }
    $c = [System.IO.File]::ReadAllText($Path)
    $count = ([regex]::Matches($c, [regex]::Escape($A))).Count
    if ($count -eq 0) {
        Write-Host ("  [SKIP] " + $Desc) -ForegroundColor DarkYellow
        return
    }
    Write-Host ("  [OK x" + $count + "] " + $Desc) -ForegroundColor Green
    if ($Apply) {
        $new = $c.Replace($A, $R)
        [System.IO.File]::WriteAllText(
            $Path, $new,
            (New-Object System.Text.UTF8Encoding($false))
        )
    }
}

Write-Host '== GROUP 1: Joined parties queries (fixes inbox/tasks runtime) ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\inbox.ts'                  'parties:party_id ( name, module )'             'parties:party_id ( name, party_type )'             'inbox: joined parties select'
Set-PatchAll 'src\lib\queries\tasks.ts'                  'parties:party_id ( name, module )'             'parties:party_id ( name, party_type )'             'tasks: joined parties select (template)'
Set-PatchAll 'src\lib\queries\tasks.ts'                  "'parties:party_id ( name, module ), '"         "'parties:party_id ( name, party_type ), '"         'tasks: joined parties select (string)'
Set-PatchAll 'src\lib\queries\communications.ts'         'party:parties(id, name, module)'               'party:parties(id, name, party_type)'               'communications: joined parties'
Set-PatchAll 'src\lib\queries\communication-detail-v2.ts' 'parties:party_id ( id, name, module )'        'parties:party_id ( id, name, party_type )'        'comm-detail-v2: joined parties'

Write-Host ''
Write-Host '== GROUP 2: Direct .eq("module", ...) on parties/pipelines tables ==' -ForegroundColor Cyan
Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' ".eq('module', module)"                         ".eq('party_type', module)"                         'parties/page: .eq module'
Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' ".eq('module' as never, module)"                ".eq('party_type' as never, module)"                'parties/page: .eq module as never'
Set-PatchAll 'src\app\(app)\page.tsx'                     ".eq('module' as never, m)"                     ".eq('party_type' as never, m)"                     'app/page: .eq module by partyType iter'
Set-PatchAll 'src\app\api\parties\search\route.ts'        ".eq('module' as never, module)"                ".eq('party_type' as never, module)"                'search: .eq module'
Set-PatchAll 'src\components\parties\country-peers-panel.tsx' ".eq('module' as never, 'paper_mill')"     ".eq('party_type' as never, 'paper_mill')"          'peers-panel: paper_mill'
Set-PatchAll 'src\components\parties\country-peers-panel.tsx' ".eq('module' as never, 'filler_supplier')" ".eq('party_type' as never, 'filler_supplier')"     'peers-panel: filler_supplier'
Set-PatchAll 'src\lib\queries\country-peers.ts'           ".eq('module' as never, module)"                ".eq('party_type' as never, module)"                'country-peers: .eq'
Set-PatchAll 'src\lib\queries\saved-views.ts'             ".eq('module' as never, module)"                ".eq('party_type' as never, module)"                'saved-views: .eq'
Set-PatchAll 'src\lib\ai\prompt-renderer.ts'              ".eq('module', module)"                         ".eq('party_type', module)"                         'prompt-renderer: .eq'
Set-PatchAll 'src\lib\queries\pipelines.ts'               ".eq('module', module)"                         ".eq('party_type', module)"                         'pipelines: .eq (both occurrences)'
Set-PatchAll 'src\app\(app)\settings\pipelines\page.tsx' ".order('module', { ascending: true })"          ".order('party_type', { ascending: true })"         'pipelines/page: .order'

Write-Host ''
Write-Host '== GROUP 3: Select strings with module column ==' -ForegroundColor Cyan
Set-PatchAll 'src\app\(app)\settings\pipelines\page.tsx' "'id, organization_id, module, name, description, is_default, is_active'" "'id, organization_id, party_type, name, description, is_default, is_active'" 'pipelines/page: select'
Set-PatchAll 'src\app\actions\party.ts'                   "'id, name, tier, party_level, module, country_code, status'" "'id, name, tier, party_level, party_type, country_code, status'" 'actions/party: select'
Set-PatchAll 'src\app\api\parties\search\route.ts'        "'id, name, module, country_code, tier'"        "'id, name, party_type, country_code, tier'"        'search: select'
Set-PatchAll 'src\lib\queries\country-peers.ts'           "'id, name, module, country_code, status, tier, industry_tags, notes'" "'id, name, party_type, country_code, status, tier, industry_tags, notes'" 'country-peers: select'
Set-PatchAll 'src\lib\ai\prompt-renderer.ts'              "'id, name, module, tier, country_code, industry_tags, module_data'" "'id, name, party_type, tier, country_code, industry_tags, module_data'" 'prompt-renderer: select'
Set-PatchAll 'src\lib\queries\draft-detail.ts'            "'id, name, module, tier, country_code, website'" "'id, name, party_type, tier, country_code, website'" 'draft-detail: select'
Set-PatchAll 'src\lib\queries\tasks.ts'                   ', reminder_at, module,'                        ', reminder_at, party_type,'                        'tasks queries: own column (template)'
Set-PatchAll 'src\lib\queries\tasks.ts'                   "'id, title, description, status, priority, due_at, reminder_at, module, '" "'id, title, description, status, priority, due_at, reminder_at, party_type, '" 'tasks queries: own column (string)'

Write-Host ''
Write-Host '== GROUP 4: tasks actions ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\actions\tasks.ts'                   ".select('id, party_id, module')"               ".select('id, party_id, party_type')"               'tasks actions: select (5x)'
Set-PatchAll 'src\lib\actions\tasks.ts'                   'updated.party_id && updated.module'            'updated.party_id && updated.party_type'            'tasks actions: updated check'
Set-PatchAll 'src\lib\actions\tasks.ts'                   '`/${updated.module}/parties/${updated.party_id}`' '`/${updated.party_type}/parties/${updated.party_id}`' 'tasks actions: revalidatePath updated'

Write-Host ''
Write-Host '== GROUP 5: Row access fixes (module -> party_type on returned DB rows) ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\inbox.ts'                   'party?.module ?? null'                         'party?.party_type ?? null'                         'inbox: row access'
Set-PatchAll 'src\lib\queries\tasks.ts'                   'party?.partyType ?? null'                      'party?.party_type ?? null'                         'tasks: row access (was already partly migrated)'
Set-PatchAll 'src\lib\queries\communication-detail-v2.ts' 'partyType: party.module }'                     'partyType: party.party_type }'                     'comm-detail-v2: row access'
Set-PatchAll 'src\lib\queries\country-peers.ts'           'module: row.module,'                           'module: row.party_type,'                           'country-peers: row access (keeps return key)'

Write-Host ''
Write-Host '== GROUP 6: TS interface declarations (DB-shape interfaces) ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\inbox.ts'                   'parties: { name: string; module: PartyTypeCode } | null;' 'parties: { name: string; party_type: PartyTypeCode } | null;' 'inbox: interface'
Set-PatchAll 'src\lib\queries\tasks.ts'                   'parties: { name: string; module: PartyTypeCode } | null;' 'parties: { name: string; party_type: PartyTypeCode } | null;' 'tasks: interface'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
