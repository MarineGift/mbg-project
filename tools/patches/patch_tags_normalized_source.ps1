# patch_tags_normalized_source.ps1
# TAGS column now reads NORMALIZED canonical tags (investor_interest_tags x
# interest_tags, catalogue order); legacy jsonb only as fallback. Also makes
# the tags sort key use the normalized first chip -> Sector filter and TAGS
# column stay consistent. Requires the earlier tags-sorting patch (applied).
$ErrorActionPreference = 'Stop'
$path = 'C:\dev\mbg-project\src\app\(app)\[partyType]\parties\page.tsx'
if (-not (Test-Path -LiteralPath $path)) { Write-Output ('ERROR: not found ' + $path); return }
$c = [System.IO.File]::ReadAllText($path)
$c = $c.Replace("`r`n", "`n")
$warn = $false

$old_P1 = @'
  // Powers the Priority column, the Priority sort, and the Priority filter.
  const investorPriorityAll: Record<string, 'high' | 'medium' | 'low'> = {};
  if (isInvestor) {
    const { data: prRows } = await supabase
      .schema('app')
      .from('investor_profile' as never)
      .select('party_id, priority');
    for (const r of ((prRows ?? []) as any[])) {
      if (r.party_id && (r.priority === 'high' || r.priority === 'medium' || r.priority === 'low')) {
        investorPriorityAll[r.party_id] = r.priority;
      }
    }
  }
'@
$new_P1 = @'
  // Powers the Priority column, the Priority sort, and the Priority filter.
  const investorPriorityAll: Record<string, 'high' | 'medium' | 'low'> = {};
  // Normalized canonical interest tags per party, ordered by catalogue
  // sort_order (source of truth for the TAGS column; legacy jsonb is only a
  // fallback for parties not yet backfilled).
  const investorTagsAll: Record<string, string[]> = {};
  if (isInvestor) {
    const [{ data: prRows }, { data: linkRows }, { data: tagRows }] = await Promise.all([
      supabase
        .schema('app')
        .from('investor_profile' as never)
        .select('id, party_id, priority'),
      supabase
        .schema('app')
        .from('investor_interest_tags' as never)
        .select('investor_profile_id, interest_tag_id'),
      supabase
        .schema('app')
        .from('interest_tags' as never)
        .select('id, code, sort_order'),
    ]);
    const profileToParty = new Map<string, string>();
    for (const r of ((prRows ?? []) as any[])) {
      if (r.id && r.party_id) profileToParty.set(r.id, r.party_id);
      if (r.party_id && (r.priority === 'high' || r.priority === 'medium' || r.priority === 'low')) {
        investorPriorityAll[r.party_id] = r.priority;
      }
    }
    const tagById = new Map<number, { code: string; sort: number }>();
    for (const t of ((tagRows ?? []) as any[])) {
      tagById.set(t.id, { code: t.code, sort: t.sort_order ?? 9999 });
    }
    const acc: Record<string, { code: string; sort: number }[]> = {};
    for (const l of ((linkRows ?? []) as any[])) {
      const pid = profileToParty.get(l.investor_profile_id);
      const tg = tagById.get(l.interest_tag_id);
      if (!pid || !tg) continue;
      (acc[pid] = acc[pid] ?? []).push(tg);
    }
    for (const pid of Object.keys(acc)) {
      investorTagsAll[pid] = acc[pid]!
        .sort((x, y) => x.sort - y.sort || x.code.localeCompare(y.code))
        .map((x) => x.code);
    }
  }
'@
if ($c.Contains($new_P1)) {
  Write-Output ('SKIP P1: already applied')
} elseif ($c.Contains($old_P1)) {
  $c = $c.Replace($old_P1, $new_P1)
  Write-Output ('OK   P1: applied')
} else {
  Write-Output ('WARN P1: anchor not found - manual check needed')
  $warn = $true
}

$old_P2 = @'
                  const tags      = (Array.isArray(p.interest_tags) ? p.interest_tags : [])
                    .filter((t): t is string => typeof t === 'string' && t.trim() !== '')
                    .slice()
                    .sort((a, b) => a.localeCompare(b)); // display ascending
'@
$new_P2 = @'
                  // Prefer normalized canonical tags (catalogue order);
                  // fall back to legacy jsonb for parties not yet backfilled.
                  const legacyTags = (Array.isArray(p.interest_tags) ? p.interest_tags : [])
                    .filter((t): t is string => typeof t === 'string' && t.trim() !== '')
                    .slice()
                    .sort((a, b) => a.localeCompare(b));
                  const normTags  = investorTagsAll[p.id] ?? [];
                  const tags      = normTags.length > 0 ? normTags : legacyTags;
'@
if ($c.Contains($new_P2)) {
  Write-Output ('SKIP P2: already applied')
} elseif ($c.Contains($old_P2)) {
  $c = $c.Replace($old_P2, $new_P2)
  Write-Output ('OK   P2: applied')
} else {
  Write-Output ('WARN P2: anchor not found - manual check needed')
  $warn = $true
}

$old_P3 = @'
      const tagKey = (p: PartyRow) => {
        const arr = Array.isArray(p.interest_tags) ? p.interest_tags : [];
        const norm = arr
          .map((t) => String(t ?? '').trim().toLowerCase())
          .filter(Boolean)
          .sort();
        return norm[0] ?? '';
      };
'@
$new_P3 = @'
      const tagKey = (p: PartyRow) => {
        const canonical = investorTagsAll[p.id];
        if (canonical && canonical.length > 0) return canonical[0]!.toLowerCase();
        const arr = Array.isArray(p.interest_tags) ? p.interest_tags : [];
        const norm = arr
          .map((t) => String(t ?? '').trim().toLowerCase())
          .filter(Boolean)
          .sort();
        return norm[0] ?? '';
      };
'@
if ($c.Contains($new_P3)) {
  Write-Output ('SKIP P3: already applied')
} elseif ($c.Contains($old_P3)) {
  $c = $c.Replace($old_P3, $new_P3)
  Write-Output ('OK   P3: applied')
} else {
  Write-Output ('WARN P3: anchor not found - manual check needed')
  $warn = $true
}

if ($warn) { Write-Output 'One or more anchors missing - file NOT fully patched.' }
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $c, $utf8)
Write-Output ('WROTE ' + $path)
Write-Output 'Next: npm run build, then commit + push.'
