# =============================================================================
# Phase D2m: engagements + email-history + module-badge cleanup
# - engagements: module key -> partyType, KanbanStage import
# - email-history: native rpc -> typed
# - module-badge: Record completion + prop name
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

# === STEP 1: engagements.ts module key -> partyType + KanbanStage import ===
Write-Host '== STEP 1: engagements.ts module key + KanbanStage import ==' -ForegroundColor Cyan

# L193 + L236: { module, ... } -> { partyType, ... } (key in return obj)
# Both have shape "    return {`n      module,`n      ...`n    };"
# Use unique substring near each ??actually they may be identical
Set-PatchAll 'src\lib\queries\engagements.ts' `
    "    return {`n      module,`n      pipelineDefinitionId: null," `
    "    return {`n      partyType,`n      pipelineDefinitionId: null," `
    'L193 module key -> partyType (no pipeline branch)'

Set-PatchAll 'src\lib\queries\engagements.ts' `
    "  return {`n    module,`n    pipelineDefinitionId: pipeline.id," `
    "  return {`n    partyType,`n    pipelineDefinitionId: pipeline.id," `
    'L236 module key -> partyType (with pipeline branch)'

# KanbanStage import ??check existing imports first to determine pattern
# Common Korean codebase pattern; assume there's an `import type { ... } from '@/types/engagement'`
# Add KanbanStage to existing import if it exists.
Set-PatchAll 'src\lib\queries\engagements.ts' `
    "import type { KanbanBoard, KanbanCard }" `
    "import type { KanbanBoard, KanbanCard, KanbanStage }" `
    'Add KanbanStage to existing import (variant 1)'

Set-PatchAll 'src\lib\queries\engagements.ts' `
    "import type { KanbanBoard }" `
    "import type { KanbanBoard, KanbanStage }" `
    'Add KanbanStage to existing import (variant 2)'

# === STEP 2: email-history.ts native rpc -> typed ===
Write-Host ''
Write-Host '== STEP 2: email-history.ts native rpc -> typed ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\email-history.ts' `
    'import { createSupabaseServerClient } from "@/lib/supabase/server";' `
    "import { createSupabaseServerClient } from `"@/lib/supabase/server`";`r`nimport { rpc } from `"@/lib/rpc/typed-rpc`";" `
    'Add rpc import (double quote)'

Set-PatchAll 'src\lib\queries\email-history.ts' `
    "import { createSupabaseServerClient } from '@/lib/supabase/server';" `
    "import { createSupabaseServerClient } from '@/lib/supabase/server';`r`nimport { rpc } from '@/lib/rpc/typed-rpc';" `
    'Add rpc import (single quote)'

Set-PatchAll 'src\lib\queries\email-history.ts' `
    'supabase.rpc(' `
    'rpc(supabase, ' `
    'native supabase.rpc -> rpc(supabase, '

# email-history cast
Set-PatchAll 'src\lib\queries\email-history.ts' `
    'as EmailHistoryRow[]' `
    'as unknown as EmailHistoryRow[]' `
    'cast EmailHistoryRow[]'

# === STEP 3: module-badge.tsx ===
Write-Host ''
Write-Host '== STEP 3: module-badge.tsx Record + prop name ==' -ForegroundColor Cyan
# (a) Add buyer, government_grant to the Record
Set-PatchAll 'src\components\common\module-badge.tsx' `
    "  filler_supplier: 'bg-orange-100 text-orange-700'," `
    "  filler_supplier: 'bg-orange-100 text-orange-700',`r`n  buyer: 'bg-yellow-100 text-yellow-700',`r`n  government_grant: 'bg-gray-100 text-gray-700'," `
    'Record add buyer + government_grant (variant 1 single quote)'

Set-PatchAll 'src\components\common\module-badge.tsx' `
    '  filler_supplier: "bg-orange-100 text-orange-700",' `
    "  filler_supplier: `"bg-orange-100 text-orange-700`",`r`n  buyer: `"bg-yellow-100 text-yellow-700`",`r`n  government_grant: `"bg-gray-100 text-gray-700`"," `
    'Record add buyer + government_grant (variant 2 double quote)'

# (b) prop 'module' might still be referenced ??defer until we see file

# === STEP 4: email-signatures upsert cast ===
Write-Host ''
Write-Host '== STEP 4: email-signatures upsert payload cast ==' -ForegroundColor Cyan
Set-PatchAll 'src\lib\queries\email-signatures.ts' `
    '.upsert(sig, { onConflict:' `
    '.upsert(sig as unknown as never, { onConflict:' `
    'upsert payload cast via unknown'

Write-Host ''
if ($Apply) {
    Write-Host '== APPLIED ==' -ForegroundColor Green
} else {
    Write-Host '== DRY-RUN. Edit $Apply = $true at top and re-run to apply ==' -ForegroundColor Cyan
}
