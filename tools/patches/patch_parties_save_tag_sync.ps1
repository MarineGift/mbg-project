# patch_parties_save_tag_sync.ps1
# Real-time tag sync on save: createParty/updateParty call
# app.sync_party_interest_tags (run fix_sync_on_save_rpc.sql FIRST), and
# party-detail loads interestTags from the normalized layer so the edit form
# round-trips research tags safely. Idempotent.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$warn = $false

$path = 'C:\dev\mbg-project\src\lib\actions\parties.ts'
$a = [System.IO.File]::ReadAllText($path); $a = $a.Replace("`r`n", "`n")

$old_A1 = @'
  const partyId = (data as { id: string }).id;
'@
$new_A1 = @'
  const partyId = (data as { id: string }).id;

  // Real-time normalized tag sync (app.investor_interest_tags) so the
  // directory TAGS column reflects the saved form immediately. Non-fatal.
  {
    const { error: syncErr } = await supabase
      .schema('app')
      .rpc('sync_party_interest_tags' as never, { p_party_id: partyId } as never);
    if (syncErr) console.error('[parties.createParty] tag sync error:', syncErr);
  }
'@
if ($a.Contains($new_A1)) { Write-Output ('SKIP A1') }
elseif ($a.Contains($old_A1)) { $a = $a.Replace($old_A1, $new_A1); Write-Output ('OK   A1') }
else { Write-Output ('WARN A1: anchor not found'); $warn = $true }

$old_A2 = @'
  if (!data) {
    return { ok: false, errorCode: 'not_found' };
  }

  // 2026-06-12: keep the whitelist in sync when a website is added/changed later.
'@
$new_A2 = @'
  if (!data) {
    return { ok: false, errorCode: 'not_found' };
  }

  // Real-time normalized tag sync (REPLACE semantics; see
  // app.sync_party_interest_tags). Non-fatal on failure.
  {
    const { error: syncErr } = await supabase
      .schema('app')
      .rpc('sync_party_interest_tags' as never, { p_party_id: parsed.data.partyId } as never);
    if (syncErr) console.error('[parties.updateParty] tag sync error:', syncErr);
  }

  // 2026-06-12: keep the whitelist in sync when a website is added/changed later.
'@
if ($a.Contains($new_A2)) { Write-Output ('SKIP A2') }
elseif ($a.Contains($old_A2)) { $a = $a.Replace($old_A2, $new_A2); Write-Output ('OK   A2') }
else { Write-Output ('WARN A2: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $a, $utf8); Write-Output ('WROTE ' + $path)

$path = 'C:\dev\mbg-project\src\lib\queries\party-detail.ts'
$d = [System.IO.File]::ReadAllText($path); $d = $d.Replace("`r`n", "`n")

$old_B1 = @'
  const p = partyRaw as unknown as RawPartyRow;
'@
$new_B1 = @'
  const p = partyRaw as unknown as RawPartyRow;

  // Normalized canonical tags are the source of truth for interestTags so the
  // edit form round-trips the same set the directory shows (legacy jsonb is
  // the fallback for parties not yet backfilled / non-investors).
  let normalizedInterestTags: string[] = [];
  {
    const { data: prof } = await supabase
      .schema('app')
      .from('investor_profile' as never)
      .select('id')
      .eq('party_id', partyId)
      .maybeSingle();
    const profileId = (prof as { id: string } | null)?.id;
    if (profileId) {
      const [{ data: linkRows }, { data: tagRows }] = await Promise.all([
        supabase
          .schema('app')
          .from('investor_interest_tags' as never)
          .select('interest_tag_id')
          .eq('investor_profile_id', profileId),
        supabase
          .schema('app')
          .from('interest_tags' as never)
          .select('id, code, sort_order'),
      ]);
      const byId = new Map<number, { code: string; sort: number }>();
      for (const t of ((tagRows ?? []) as any[])) {
        byId.set(t.id, { code: t.code, sort: t.sort_order ?? 9999 });
      }
      normalizedInterestTags = ((linkRows ?? []) as any[])
        .map((l) => byId.get(l.interest_tag_id))
        .filter((x): x is { code: string; sort: number } => !!x)
        .sort((a, b) => a.sort - b.sort || a.code.localeCompare(b.code))
        .map((x) => x.code);
    }
  }
'@
if ($d.Contains($new_B1)) { Write-Output ('SKIP B1') }
elseif ($d.Contains($old_B1)) { $d = $d.Replace($old_B1, $new_B1); Write-Output ('OK   B1') }
else { Write-Output ('WARN B1: anchor not found'); $warn = $true }

$old_B2 = @'
    interestTags: p.interest_tags,
'@
$new_B2 = @'
    interestTags: normalizedInterestTags.length > 0 ? normalizedInterestTags : p.interest_tags,
'@
if ($d.Contains($new_B2)) { Write-Output ('SKIP B2') }
elseif ($d.Contains($old_B2)) { $d = $d.Replace($old_B2, $new_B2); Write-Output ('OK   B2') }
else { Write-Output ('WARN B2: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $d, $utf8); Write-Output ('WROTE ' + $path)

if ($warn) { Write-Output 'Anchor missing - review WARN lines.' }
Write-Output 'Next: npm run build, then commit + push.'
