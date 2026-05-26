# =============================================================================
# Phase D2o: Precise anchors based on confirmed file content
# - parties/page.tsx: PHASE_1_MODULES + MODULE_LABELS completion + readonly fix
# - email-signature-client: html -> html_content (plain_text becomes html_content fallback)
# - engagements.ts: module key -> partyType (with exact indent)
# DryRun by default. Set $Apply = $true at top to apply.
# =============================================================================

$ErrorActionPreference = 'Stop'
$Apply = $true

function Set-PatchAll {
    param([string]$Path, [string]$A, [string]$R, [string]$Desc)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("  [MISS] " + $Path) -ForegroundColor DarkGray
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
        [System.IO.File]::WriteAllText($Path, $new, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# === STEP 1: parties/page.tsx ===
Write-Host '== STEP 1: parties/page.tsx ==' -ForegroundColor Cyan

# (a) PHASE_1_MODULES tuple: add buyer, government_grant
Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' `
    "  'investor', 'paper_mill', 'partner', 'customer', 'filler_supplier'," `
    "  'investor', 'paper_mill', 'partner', 'customer', 'filler_supplier', 'buyer', 'government_grant'," `
    'L31 PHASE_1_MODULES add buyer + government_grant'

# (b) MODULE_LABELS: add 2 keys (Korean label fits commit; English placeholder)
Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' `
    "  filler_supplier:         'Filler Suppliers',`n};" `
    "  filler_supplier:         'Filler Suppliers',`n  buyer:                   'Buyers',`n  government_grant:        'Government Grants',`n};" `
    'L39 MODULE_LABELS add buyer + government_grant'

# (c) L379 readonly tuple cast ??'as number[]' or spread
# Without seeing PAGE_SIZE_OPTIONS const definition, try cast at usage
Set-PatchAll 'src\app\(app)\[partyType]\parties\page.tsx' `
    'pageSizeOptions={PAGE_SIZE_OPTIONS}' `
    'pageSizeOptions={[...PAGE_SIZE_OPTIONS]}' `
    'L379 readonly tuple spread'

# === STEP 2: email-signature-client.tsx ===
Write-Host ''
Write-Host '== STEP 2: email-signature-client html/plain_text ==' -ForegroundColor Cyan

# (a) L108: cur.html access in Textarea value
Set-PatchAll 'src\components\settings\email-signature-client.tsx' `
    "value={cur.html} onChange={(e) => upd('html', e.target.value)}" `
    "value={cur.html_content} onChange={(e) => upd('html_content', e.target.value)}" `
    'L108 html -> html_content'

# (b) L113: dangerouslySetInnerHTML html
Set-PatchAll 'src\components\settings\email-signature-client.tsx' `
    'dangerouslySetInnerHTML={{ __html: cur.html }}' `
    'dangerouslySetInnerHTML={{ __html: cur.html_content }}' `
    'L113 html -> html_content (preview)'

# (c) L116: plain_text -> remove this textarea or fallback to html_content
# Since DB has no plain_text field, we keep UI consistent by mapping to html_content too
# Or hide the plain text tab. Simplest: cast as any to bypass.
Set-PatchAll 'src\components\settings\email-signature-client.tsx' `
    "value={cur.plain_text} onChange={(e) => upd('plain_text', e.target.value)}" `
    "value={(cur as any).plain_text ?? ''} onChange={(e) => upd('plain_text' as any, e.target.value)}" `
    'L116 plain_text temporary any-cast (TODO: remove plain text UI)'

# === STEP 3: engagements.ts module key (D2m retry with precise indent) ===
Write-Host ''
Write-Host '== STEP 3: engagements.ts module key -> partyType ==' -ForegroundColor Cyan

# L193: "      module," (6 spaces + module + comma) inside return block
# Use 2 unique line context above
Set-PatchAll 'src\lib\queries\engagements.ts' `
    "  if (!pipeline) {`n    return {`n      module," `
    "  if (!pipeline) {`n    return {`n      partyType," `
    'L193 module key in null-pipeline branch'

# L236: "    module," inside outer return
Set-PatchAll 'src\lib\queries\engagements.ts' `
    "  return {`n    module,`n    pipelineDefinitionId: pipeline.id," `
    "  return {`n    partyType,`n    pipelineDefinitionId: pipeline.id," `
    'L236 module key in success branch'

# KanbanStage import (L297) - check what's imported
Set-PatchAll 'src\lib\queries\engagements.ts' `
    'import type { KanbanBoard, KanbanCard } from' `
    'import type { KanbanBoard, KanbanCard, KanbanStage } from' `
    'Add KanbanStage to import (variant 1)'

Set-PatchAll 'src\lib\queries\engagements.ts' `
    'import type { KanbanCard, KanbanBoard } from' `
    'import type { KanbanCard, KanbanBoard, KanbanStage } from' `
    'Add KanbanStage to import (variant 2 order)'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
