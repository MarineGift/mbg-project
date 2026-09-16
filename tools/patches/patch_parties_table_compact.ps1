# patch_parties_table_compact.ps1
# Investors directory table: widen Sector Focus (fewer chip rows), shrink State/Country/Location/Priority/Stage/Type/Web.
# Idempotent. ASCII only. Repo = C:\dev\mbg-project
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$rel  = 'src\app\(app)\[partyType]\parties\page.tsx'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$p = [System.IO.Path]::Combine($repo, $rel)
if (-not [System.IO.File]::Exists($p)) { Write-Host "[MISS] $rel not found"; return }
$s = [System.IO.File]::ReadAllText($p, $utf8) -replace "`r`n", "`n"
$script:changed = 0
function Edit([string]$label, [string]$old, [string]$new) {
  $o = $old -replace "`r`n", "`n"; $n = $new -replace "`r`n", "`n"
  if ($script:s.Contains($n)) { Write-Host "[SKIP] $label (already applied)"; return }
  $i = $script:s.IndexOf($o)
  if ($i -lt 0) { Write-Host "[SKIP] $label (anchor not found)"; return }
  if ($script:s.IndexOf($o, $i + 1) -ge 0) { Write-Host "[WARN] $label anchor not unique - skipped"; return }
  $script:s = $script:s.Substring(0, $i) + $n + $script:s.Substring($i + $o.Length)
  $script:changed++
  Write-Host "[OK]   $label"
}
$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell">
                      <Link href={hTags.href}
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden md:table-cell">
                      <Link href={hTags.href}
'@
Edit 'th tags' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap">
                      <Link href={hPriority.href}
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap">
                      <Link href={hPriority.href}
'@
Edit 'th priority' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Stage</th>
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Stage</th>
'@
Edit 'th stage' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Investment Type</th>
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Investment Type</th>
'@
Edit 'th investment' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">Sector Focus</th>
'@
$n = @'
<th className="px-3 py-3 font-medium whitespace-nowrap hidden lg:table-cell min-w-[400px]">Sector Focus</th>
'@
Edit 'th sector' $o $n

$o = @'
<th className="px-3 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                      <Link href={hCountry.href}
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                      <Link href={hCountry.href}
'@
Edit 'th country' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                      <Link href={hLocation.href}
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden sm:table-cell">
                      <Link href={hLocation.href}
'@
Edit 'th location' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden md:table-cell">
                      <Link href={hState.href}
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden md:table-cell">
                      <Link href={hState.href}
'@
Edit 'th state' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell">
                      <Link href={hType.href}
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden lg:table-cell">
                      <Link href={hType.href}
'@
Edit 'th type' $o $n

$o = @'
<th className="px-4 py-3 font-medium whitespace-nowrap hidden lg:table-cell w-16 text-center">Web</th>
'@
$n = @'
<th className="px-2 py-3 font-medium whitespace-nowrap hidden lg:table-cell w-10 text-center">Web</th>
'@
Edit 'th web' $o $n

$o = @'
<td className="px-4 py-3">
                        <Link href={`/${module}/parties/${p.id}`} className="font-medium hover:underline line-clamp-1">
'@
$n = @'
<td className="px-4 py-3 min-w-[150px]">
                        <Link href={`/${module}/parties/${p.id}`} title={p.party_name} className="font-medium hover:underline line-clamp-2 leading-snug">
'@
Edit 'td name' $o $n

$o = @'
{!showLinks && (
                        <td className="px-4 py-3 hidden md:table-cell">
'@
$n = @'
{!showLinks && (
                        <td className="px-2 py-3 hidden md:table-cell">
'@
Edit 'td tags' $o $n

$o = @'
<td className="px-4 py-3">
                          {(() => {
                            const pr = investorPriorityAll
'@
$n = @'
<td className="px-2 py-3">
                          {(() => {
                            const pr = investorPriorityAll
'@
Edit 'td priority' $o $n

$o = @'
<td className="px-4 py-3 hidden lg:table-cell">
                          {(investorStageAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1">
'@
$n = @'
<td className="px-2 py-3 hidden lg:table-cell">
                          {(investorStageAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1 max-w-[130px]">
'@
Edit 'td stage' $o $n

$o = @'
<td className="px-4 py-3 hidden lg:table-cell">
                          {(investorInvestmentAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1 max-w-[240px]">
'@
$n = @'
<td className="px-2 py-3 hidden lg:table-cell">
                          {(investorInvestmentAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1 max-w-[170px]">
'@
Edit 'td investment' $o $n

$o = @'
<td className="px-4 py-3 hidden lg:table-cell">
                          {(investorSectorTextAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1 max-w-[240px]">
'@
$n = @'
<td className="px-3 py-3 hidden lg:table-cell">
                          {(investorSectorTextAll[p.id] ?? []).length > 0 ? (
                            <div className="flex flex-wrap gap-1 min-w-[400px] max-w-[520px]">
'@
Edit 'td sector' $o $n

$o = @'
<td className="px-3 py-3 text-sm hidden sm:table-cell whitespace-nowrap text-muted-foreground">
                          {p.country_code ?
'@
$n = @'
<td className="px-2 py-3 text-sm hidden sm:table-cell leading-tight min-w-[80px] text-muted-foreground">
                          {p.country_code ?
'@
Edit 'td country' $o $n

$o = @'
<td className="px-4 py-3 text-sm hidden sm:table-cell whitespace-nowrap">
                          {location || '-'}
'@
$n = @'
<td className="px-2 py-3 text-sm hidden sm:table-cell leading-tight min-w-[80px]">
                          {location || '-'}
'@
Edit 'td location' $o $n

$o = @'
<td className="px-4 py-3 text-sm hidden md:table-cell whitespace-nowrap">
                          {p.region ?
'@
$n = @'
<td className="px-2 py-3 text-sm hidden md:table-cell leading-tight min-w-[70px]">
                          {p.region ?
'@
Edit 'td state' $o $n

$o = @'
<td className="px-4 py-3 hidden lg:table-cell">
                          {investorCatAll[p.id]?.type_name
'@
$n = @'
<td className="px-2 py-3 hidden lg:table-cell">
                          {investorCatAll[p.id]?.type_name
'@
Edit 'td type' $o $n

$o = @'
<td className="px-4 py-3 hidden lg:table-cell text-center">
                        {p.website
'@
$n = @'
<td className="px-2 py-3 hidden lg:table-cell text-center">
                        {p.website
'@
Edit 'td web' $o $n
if ($script:changed -gt 0) { [System.IO.File]::WriteAllText($p, $s, $utf8) }
Write-Host ("DONE: parties table compact (" + $script:changed + " edits)")
