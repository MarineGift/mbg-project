# patch_sector_focus_normalized.ps1
# Make the Party form's "Sector focus" a normalized picker identical to
# Interest Tags: checkbox multi-select from app.sectors catalogue + Add-new.
# Files: party-form.tsx (Input -> TagMultiSelect + prop), new/edit pages (load
# fetchSectorOptions + pass sectorSuggestions), actions/parties.ts (call
# sync_party_sector_focus on create+update). Idempotent.
# PREREQ: sql/fix_sync_sector_focus_rpc.sql applied; lib/queries/sector-focus.ts present.
$ErrorActionPreference='Stop'
$repo='C:\dev\mbg-project'
$utf8=New-Object System.Text.UTF8Encoding($false)
$warn=$false


$path = Join-Path $repo 'src\components\parties\party-form.tsx'
$f = [System.IO.File]::ReadAllText($path); $f = $f.Replace("`r`n","`n")

$old_PF_P1_f = @'
  /** canonical tag options for the Interest Tags multi-select */
  interestTagSuggestions?: TagOption[];
}
'@
$new_PF_P1_f = @'
  /** canonical tag options for the Interest Tags multi-select */
  interestTagSuggestions?: TagOption[];
  /** canonical sector options for the Sector focus multi-select */
  sectorSuggestions?: TagOption[];
}
'@
if ($f.Contains($new_PF_P1_f)) { Write-Output 'SKIP PF_P1_f' }
elseif ($f.Contains($old_PF_P1_f)) { $f = $f.Replace($old_PF_P1_f, $new_PF_P1_f); Write-Output 'OK   PF_P1_f' }
else { Write-Output 'WARN PF_P1_f: anchor not found'; $warn=$true }

$old_PF_P2_f = @'
  interestTagSuggestions = [],
'@
$new_PF_P2_f = @'
  interestTagSuggestions = [],
  sectorSuggestions = [],
'@
if ($f.Contains($new_PF_P2_f)) { Write-Output 'SKIP PF_P2_f' }
elseif ($f.Contains($old_PF_P2_f)) { $f = $f.Replace($old_PF_P2_f, $new_PF_P2_f); Write-Output 'OK   PF_P2_f' }
else { Write-Output 'WARN PF_P2_f: anchor not found'; $warn=$true }

$old_PF_P3_f = @'
              {isInvestor && (
                <div className="space-y-2">
                  <Label htmlFor="party-sector-focus">Sector focus</Label>
                  <Input
                    id="party-sector-focus"
                    {...register('sectorFocus')}
                    disabled={isPending}
                    placeholder="materials, industrial, healthcare, sustainability"
                  />
                  <p className="text-xs text-muted-foreground">Comma-separated.</p>
                </div>
              )}
'@
$new_PF_P3_f = @'
              {isInvestor && (
                <div className="space-y-2">
                  <Label htmlFor="party-sector-focus">Sector focus</Label>
                  <TagMultiSelect
                    inputId="party-sector-focus"
                    value={watch('sectorFocus') ?? ''}
                    onChange={(v) => setValue('sectorFocus', v, { shouldDirty: true })}
                    suggestions={sectorSuggestions}
                    disabled={isPending}
                    placeholder="Select or add sectors..."
                  />
                  <p className="text-xs text-muted-foreground">
                    Normalized sectors only. Pick from the list, or type to add a new one.
                  </p>
                </div>
              )}
'@
if ($f.Contains($new_PF_P3_f)) { Write-Output 'SKIP PF_P3_f' }
elseif ($f.Contains($old_PF_P3_f)) { $f = $f.Replace($old_PF_P3_f, $new_PF_P3_f); Write-Output 'OK   PF_P3_f' }
else { Write-Output 'WARN PF_P3_f: anchor not found'; $warn=$true }

[System.IO.File]::WriteAllText($path, $f, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\app\(app)\[partyType]\parties\new\page.tsx'
$n = [System.IO.File]::ReadAllText($path); $n = $n.Replace("`r`n","`n")

$old_NEW_1_n = @'
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
'@
$new_NEW_1_n = @'
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
import { fetchSectorOptions } from '@/lib/queries/sector-focus';
'@
if ($n.Contains($new_NEW_1_n)) { Write-Output 'SKIP NEW_1_n' }
elseif ($n.Contains($old_NEW_1_n)) { $n = $n.Replace($old_NEW_1_n, $new_NEW_1_n); Write-Output 'OK   NEW_1_n' }
else { Write-Output 'WARN NEW_1_n: anchor not found'; $warn=$true }

$old_NEW_2_n = @'
  const interestTagSuggestions = await fetchInterestTagOptions();
'@
$new_NEW_2_n = @'
  const interestTagSuggestions = await fetchInterestTagOptions();
  const sectorSuggestions = await fetchSectorOptions();
'@
if ($n.Contains($new_NEW_2_n)) { Write-Output 'SKIP NEW_2_n' }
elseif ($n.Contains($old_NEW_2_n)) { $n = $n.Replace($old_NEW_2_n, $new_NEW_2_n); Write-Output 'OK   NEW_2_n' }
else { Write-Output 'WARN NEW_2_n: anchor not found'; $warn=$true }

$old_NEW_3_n = @'
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
      />
'@
$new_NEW_3_n = @'
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
        sectorSuggestions={sectorSuggestions}
      />
'@
if ($n.Contains($new_NEW_3_n)) { Write-Output 'SKIP NEW_3_n' }
elseif ($n.Contains($old_NEW_3_n)) { $n = $n.Replace($old_NEW_3_n, $new_NEW_3_n); Write-Output 'OK   NEW_3_n' }
else { Write-Output 'WARN NEW_3_n: anchor not found'; $warn=$true }

[System.IO.File]::WriteAllText($path, $n, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\app\(app)\[partyType]\parties\[id]\edit\page.tsx'
$e = [System.IO.File]::ReadAllText($path); $e = $e.Replace("`r`n","`n")

$old_NEW_1_e = @'
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
'@
$new_NEW_1_e = @'
import { fetchInterestTagOptions } from '@/lib/queries/interest-tags';
import { fetchSectorOptions } from '@/lib/queries/sector-focus';
'@
if ($e.Contains($new_NEW_1_e)) { Write-Output 'SKIP NEW_1_e' }
elseif ($e.Contains($old_NEW_1_e)) { $e = $e.Replace($old_NEW_1_e, $new_NEW_1_e); Write-Output 'OK   NEW_1_e' }
else { Write-Output 'WARN NEW_1_e: anchor not found'; $warn=$true }

$old_NEW_2_e = @'
  const interestTagSuggestions = await fetchInterestTagOptions();
'@
$new_NEW_2_e = @'
  const interestTagSuggestions = await fetchInterestTagOptions();
  const sectorSuggestions = await fetchSectorOptions();
'@
if ($e.Contains($new_NEW_2_e)) { Write-Output 'SKIP NEW_2_e' }
elseif ($e.Contains($old_NEW_2_e)) { $e = $e.Replace($old_NEW_2_e, $new_NEW_2_e); Write-Output 'OK   NEW_2_e' }
else { Write-Output 'WARN NEW_2_e: anchor not found'; $warn=$true }

$old_NEW_3_e = @'
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
      />
'@
$new_NEW_3_e = @'
        industryTagSuggestions={interestTagSuggestions}
        interestTagSuggestions={interestTagSuggestions}
        sectorSuggestions={sectorSuggestions}
      />
'@
if ($e.Contains($new_NEW_3_e)) { Write-Output 'SKIP NEW_3_e' }
elseif ($e.Contains($old_NEW_3_e)) { $e = $e.Replace($old_NEW_3_e, $new_NEW_3_e); Write-Output 'OK   NEW_3_e' }
else { Write-Output 'WARN NEW_3_e: anchor not found'; $warn=$true }

[System.IO.File]::WriteAllText($path, $e, $utf8); Write-Output ('WROTE ' + $path)


$path = Join-Path $repo 'src\lib\actions\parties.ts'
$a = [System.IO.File]::ReadAllText($path); $a = $a.Replace("`r`n","`n")

$old_AC_1_a = @'
    const { error: syncErr } = await supabase
      .schema('app')
      .rpc('sync_party_interest_tags' as never, { p_party_id: parsed.data.partyId } as never);
    if (syncErr) console.error('[parties.updateParty] tag sync error:', syncErr);
  }
'@
$new_AC_1_a = @'
    const { error: syncErr } = await supabase
      .schema('app')
      .rpc('sync_party_interest_tags' as never, { p_party_id: parsed.data.partyId } as never);
    if (syncErr) console.error('[parties.updateParty] tag sync error:', syncErr);
  }

  // Real-time SECTOR focus sync (REPLACE; app.sync_party_sector_focus).
  {
    const { error: secErr } = await supabase
      .schema('app')
      .rpc('sync_party_sector_focus' as never,
           { p_party_id: parsed.data.partyId, p_codes: parsed.data.sectorFocus } as never);
    if (secErr) console.error('[parties.updateParty] sector sync error:', secErr);
  }
'@
if ($a.Contains($new_AC_1_a)) { Write-Output 'SKIP AC_1_a' }
elseif ($a.Contains($old_AC_1_a)) { $a = $a.Replace($old_AC_1_a, $new_AC_1_a); Write-Output 'OK   AC_1_a' }
else { Write-Output 'WARN AC_1_a: anchor not found'; $warn=$true }

$old_AC_2_a = @'
      .rpc('sync_party_interest_tags' as never, { p_party_id: partyId } as never);
'@
$new_AC_2_a = @'
      .rpc('sync_party_interest_tags' as never, { p_party_id: partyId } as never);
    await supabase
      .schema('app')
      .rpc('sync_party_sector_focus' as never,
           { p_party_id: partyId, p_codes: parsed.data.sectorFocus } as never);
'@
if ($a.Contains($new_AC_2_a)) { Write-Output 'SKIP AC_2_a' }
elseif ($a.Contains($old_AC_2_a)) { $a = $a.Replace($old_AC_2_a, $new_AC_2_a); Write-Output 'OK   AC_2_a' }
else { Write-Output 'WARN AC_2_a: anchor not found'; $warn=$true }

[System.IO.File]::WriteAllText($path, $a, $utf8); Write-Output ('WROTE ' + $path)


if ($warn) { Write-Output 'Some anchors missing - review before build.' }
Write-Output 'Next: npm run build -> commit/push. Then run backfill (optional) in fix_sync_sector_focus_rpc.sql comment.'
