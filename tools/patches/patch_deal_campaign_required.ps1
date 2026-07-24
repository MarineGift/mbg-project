# patch_deal_campaign_required.ps1   (2026-07-24, v2)
# v2 fix: Test-Path -LiteralPath. Plain Test-Path treats [code] in the repo
# path as a wildcard character class, so the target files were reported
# MISSING even though they exist.
# Campaign-first deal creation:
#   1) new-deal-modal.tsx : remove Standalone/Campaign toggle, campaign select
#      always visible and REQUIRED (client validation).
#   2) pipelines/[code]/actions.ts : createDeal rejects a missing campaign_id
#      (server validation; DB fallback trigger stays as a safety net for seeds).
# Idempotent: each replacement is guarded (skips if already applied, warns if
# the anchor moved). Normalizes CRLF -> LF before matching, writes LF.
# ASCII-only console output (PS 5.x CP949 safety).

$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'

function Apply-Patch {
  param([string]$Path, [System.Collections.IEnumerable]$Pairs)
  if (-not (Test-Path -LiteralPath $Path)) { Write-Host ('MISSING FILE: ' + $Path); return }
  $raw = [System.IO.File]::ReadAllText($Path)
  $txt = $raw.Replace("`r`n", "`n")
  $changed = $false
  foreach ($p in $Pairs) {
    if ($txt.Contains($p.New)) { Write-Host ('SKIP already applied: ' + $p.Tag); continue }
    if (-not $txt.Contains($p.Old)) { Write-Host ('WARN anchor not found: ' + $p.Tag); continue }
    $txt = $txt.Replace($p.Old, $p.New)
    $changed = $true
    Write-Host ('APPLIED: ' + $p.Tag)
  }
  if ($changed) {
    [System.IO.File]::WriteAllText($Path, $txt)
    Write-Host ('WROTE: ' + $Path)
  } else {
    Write-Host ('NO CHANGES: ' + $Path)
  }
}

# ------------------------------------------------------------
# 1) new-deal-modal.tsx
# ------------------------------------------------------------
$modal = Join-Path $repo 'src\app\(app)\pipelines\[code]\new-deal-modal.tsx'

$mp = @()

$mp += @{ Tag = 'modal: drop dealMode state';
Old = @"
  // Campaign vs standalone (all pipelines)
  const [dealMode, setDealMode] = useState<'standalone' | 'campaign'>('standalone');
  const [campaignId, setCampaignId] = useState('');
"@.Replace("`r`n","`n");
New = @"
  // Campaign (required - every deal is created under a campaign)
  const [campaignId, setCampaignId] = useState('');
"@.Replace("`r`n","`n") }

$mp += @{ Tag = 'modal: reset effect';
Old = "      setDealMode('standalone');`n      setCampaignId('');";
New = "      setCampaignId('');" }

$mp += @{ Tag = 'modal: require campaign in validation';
Old = @"
    if (dealMode === 'campaign' && !campaignId) {
      setError('Select a campaign, or choose Standalone deal');
      return;
    }
"@.Replace("`r`n","`n");
New = @"
    if (!campaignId) {
      setError('Campaign is required - every deal is created under a campaign');
      return;
    }
"@.Replace("`r`n","`n") }

$mp += @{ Tag = 'modal: payload always sends campaign_id';
Old = "        campaign_id: dealMode === 'campaign' ? (campaignId || null) : null,";
New = "        campaign_id: campaignId," }

$mp += @{ Tag = 'modal: replace toggle UI with required select';
Old = @"
          {/* Standalone vs Campaign (all pipelines) */}
          <div>
            <label className="mb-1 block text-sm font-medium text-foreground">
              Deal type
            </label>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setDealMode('standalone')}
                disabled={isPending}
                className={'flex-1 rounded-md border px-3 py-2 text-sm ' + (dealMode === 'standalone' ? 'border-foreground bg-foreground text-background' : 'text-muted-foreground hover:text-foreground')}
              >
                Standalone deal
              </button>
              <button
                type="button"
                onClick={() => setDealMode('campaign')}
                disabled={isPending}
                className={'flex-1 rounded-md border px-3 py-2 text-sm ' + (dealMode === 'campaign' ? 'border-foreground bg-foreground text-background' : 'text-muted-foreground hover:text-foreground')}
              >
                Part of a campaign
              </button>
            </div>

            {dealMode === 'campaign' && (
              <select
"@.Replace("`r`n","`n");
New = @"
          {/* Campaign (required - every deal is created under a campaign) */}
          <div>
            <label className="mb-1 block text-sm font-medium text-foreground">
              Campaign
              <span className="ml-1 text-xs font-normal text-muted-foreground">
                required
              </span>
            </label>
            {(
              <select
"@.Replace("`r`n","`n") }

Apply-Patch -Path $modal -Pairs $mp

# ------------------------------------------------------------
# 2) pipelines/[code]/actions.ts  (server-side createDeal)
# ------------------------------------------------------------
$actions = Join-Path $repo 'src\app\(app)\pipelines\[code]\actions.ts'

$ap = @()

$ap += @{ Tag = 'actions: createDeal requires campaign_id';
Old = "  if (!input.current_stage_id) return { ok: false, error: 'Stage is required' };";
New = "  if (!input.current_stage_id) return { ok: false, error: 'Stage is required' };`n  if (!input.campaign_id) return { ok: false, error: 'Campaign is required' };" }

Apply-Patch -Path $actions -Pairs $ap

Write-Host 'DONE. Next: npx tsc --noEmit (baseline 15 errors, expect no increase).'
