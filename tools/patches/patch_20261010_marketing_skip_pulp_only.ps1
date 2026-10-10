# patch_20261010_marketing_skip_pulp_only.ps1
# In-place patch of src/lib/queries/marketing-segment.ts:
#   /marketing segments skip archived parties and parties tagged 'MBG Pulp Only'.
# Idempotent. ASCII output only.
$f = 'C:\dev\mbg-project\src\lib\queries\marketing-segment.ts'
$s = [System.IO.File]::ReadAllText($f).Replace("`r`n", "`n")
if ($s.Contains("MBG Pulp Only")) { Write-Output 'SKIP  already patched'; return }
$a1 = "const parties = await fetchAll<{ id: string; party_name: string | null; country_code: string | null }>("
$b1 = "const parties = await fetchAll<{ id: string; party_name: string | null; country_code: string | null; status: string | null; interest_tags: unknown }>("
$a2 = ".select('id, party_name, country_code')"
$b2 = ".select('id, party_name, country_code, status, interest_tags')"
$a3 = "  let ids = parties.map((p) => p.id);`n"
$b3 = "  // Never mail archived parties, nor mills tagged 'MBG Pulp Only' (market-pulp`n" +
      "  // producers make no paper and use no filler - not FCC targets). The tag lives`n" +
      "  // in the legacy interest_tags jsonb array; the directory shows it as a chip.`n" +
      "  const isPulpOnly = (t: unknown) => Array.isArray(t) && t.some((x) => x === 'MBG Pulp Only');`n" +
      "  let ids = parties`n" +
      "    .filter((p) => (p.status ?? 'active') !== 'archived' && !isPulpOnly(p.interest_tags))`n" +
      "    .map((p) => p.id);`n"
foreach ($a in @($a1, $a2, $a3)) { if (-not $s.Contains($a)) { Write-Output ('ERROR anchor not found: ' + $a.Substring(0, [Math]::Min(60, $a.Length))); return } }
$i = $s.IndexOf($a2)
$s = $s.Replace($a1, $b1).Substring(0)
$i = $s.IndexOf($a2); $s = $s.Substring(0, $i) + $b2 + $s.Substring($i + $a2.Length)
$s = $s.Replace($a3, $b3)
[System.IO.File]::WriteAllText($f, $s, (New-Object System.Text.UTF8Encoding($false)))
Write-Output 'PATCHED marketing-segment.ts'
