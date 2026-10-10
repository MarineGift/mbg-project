# mill_email_crawl.ps1  (PowerShell 5.1)
# Reads the mill worklist CSV (Supabase export of scan_20261010_mill_email_worklist.sql),
# visits each company website (home page + contact/imprint pages on the same site),
# and writes every e-mail address actually printed on those pages, with the page URL.
# READ-ONLY toward the DB. Output: Downloads\mill_email_candidates_<date>.csv
# Usage:
#   powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\mill_email_crawl.ps1
#   (optional) -CsvPath <file>  -MaxPagesPerSite 8
param(
  [string]$CsvPath = '',
  [int]$MaxPagesPerSite = 8,
  [int]$TimeoutSec = 20
)
$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11
$Dl = Join-Path $env:USERPROFILE 'Downloads'
if (-not $CsvPath) {
  $c = Get-ChildItem -LiteralPath $Dl -File -Filter 'Supabase_Snippet*.csv' | Sort-Object LastWriteTime -Descending |
       Where-Object { (Get-Content -LiteralPath $_.FullName -TotalCount 1) -match 'company_key' } | Select-Object -First 1
  if (-not $c) { Write-Output 'ERROR no worklist CSV (company_key header) in Downloads'; exit 1 }
  $CsvPath = $c.FullName
}
Write-Output ('INPUT ' + $CsvPath)
$rows = Import-Csv -LiteralPath $CsvPath
$sites = $rows | Where-Object { $_.company_key -and $_.website } | Group-Object company_key | ForEach-Object {
  [pscustomobject]@{ key = $_.Name; site = ($_.Group | Select-Object -First 1).website; rows = $_.Count }
}
Write-Output ('SITES ' + @($sites).Count)

$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
$linkWords = 'contact|kontakt|contacto|contato|contatti|iletisim|yhteys|kapcsolat|impressum|imprint|legal|mentions|about|company|offices|locations|sales|enquir|inquir|lien-he|lianxi'
$badTail = '\.(png|jpe?g|gif|webp|svg|css|js|pdf)$'
$badDom  = 'example\.|sentry|wixpress|domain\.com|email\.com|yourcompany|godaddy|cloudflare'

function Get-Page([string]$u) {
  try {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing -UserAgent $UA -TimeoutSec $TimeoutSec -MaximumRedirection 5
    return [pscustomobject]@{ url = $r.BaseResponse.ResponseUri.AbsoluteUri; html = [string]$r.Content }
  } catch { return $null }
}
function Decode-Cf([string]$hex) {
  try {
    $k = [Convert]::ToInt32($hex.Substring(0,2),16); $s = ''
    for ($i = 2; $i -lt $hex.Length; $i += 2) { $s += [char]([Convert]::ToInt32($hex.Substring($i,2),16) -bxor $k) }
    return $s
  } catch { return '' }
}
function Get-Emails([string]$html) {
  $out = New-Object System.Collections.Generic.List[string]
  $h = $html -replace '&#0*64;','@' -replace '&#x0*40;','@' -replace '%40','@'
  foreach ($m in [regex]::Matches($h, 'data-cfemail="([0-9a-fA-F]+)"')) { $out.Add((Decode-Cf $m.Groups[1].Value)) }
  foreach ($m in [regex]::Matches($h, 'email-protection#([0-9a-fA-F]+)')) { $out.Add((Decode-Cf $m.Groups[1].Value)) }
  foreach ($m in [regex]::Matches($h, '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}')) { $out.Add($m.Value) }
  $out | ForEach-Object { $_.Trim().Trim('.').ToLower() } |
    Where-Object { $_ -match '^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$' -and $_ -notmatch $badTail -and $_ -notmatch $badDom } |
    Select-Object -Unique
}
function Get-Links([string]$html, [string]$baseUrl) {
  $base = [Uri]$baseUrl; $list = @()
  foreach ($m in [regex]::Matches($html, '<a\b[^>]*href\s*=\s*["'']([^"''#]+)["''][^>]*>(.*?)</a>', 'IgnoreCase,Singleline')) {
    $href = $m.Groups[1].Value; $txt = ($m.Groups[2].Value -replace '<[^>]+>',' ')
    if ($href -match '^(mailto|tel|javascript):') { continue }
    if (($href + ' ' + $txt) -notmatch $linkWords) { continue }
    try { $u = New-Object Uri($base, $href) } catch { continue }
    $hb = $base.Host -replace '^www\.',''; $hu = $u.Host -replace '^www\.',''
    if ($hu -ne $hb -and -not $hu.EndsWith('.' + $hb)) { continue }
    if ($u.AbsoluteUri -match $badTail) { continue }
    $list += $u.AbsoluteUri
  }
  $list | Select-Object -Unique
}

$result = New-Object System.Collections.Generic.List[object]
$n = 0
foreach ($s in $sites) {
  $n++
  $start = $s.site.Trim()
  if ($start -notmatch '^https?://') { $start = 'https://' + $start }
  $hp = Get-Page $start
  if (-not $hp -and $start -match '^https://') { $hp = Get-Page ($start -replace '^https://','http://') }
  if (-not $hp) {
    Write-Output ('[' + $n + '] FAIL  ' + $s.key)
    $result.Add([pscustomobject]@{ company_key=$s.key; rows_in_key=$s.rows; email=''; on_domain=''; found_on='UNREACHABLE ' + $start })
    continue
  }
  $pages = @($hp.url) + @(Get-Links $hp.html $hp.url)
  $root = ([Uri]$hp.url).GetLeftPart('Authority')
  foreach ($p in @('/contact','/contact-us','/en/contact','/en/contact-us','/impressum')) { $pages += ($root + $p) }
  $pages = $pages | Select-Object -Unique | Select-Object -First ($MaxPagesPerSite + 1)
  $found = @{}
  foreach ($pu in $pages) {
    $pg = if ($pu -eq $hp.url) { $hp } else { Get-Page $pu }
    if (-not $pg) { continue }
    foreach ($e in (Get-Emails $pg.html)) { if (-not $found.ContainsKey($e)) { $found[$e] = $pg.url } }
  }
  $dom = ($s.key -replace '^www\.','').ToLower()
  if ($found.Count -eq 0) {
    $result.Add([pscustomobject]@{ company_key=$s.key; rows_in_key=$s.rows; email=''; on_domain=''; found_on='NO EMAIL ON ' + @($pages).Count + ' PAGES' })
  }
  foreach ($e in $found.Keys) {
    $ed = $e.Split('@')[1]
    $result.Add([pscustomobject]@{ company_key=$s.key; rows_in_key=$s.rows; email=$e; on_domain=($ed -eq $dom -or $ed.EndsWith('.' + $dom)); found_on=$found[$e] })
  }
  Write-Output ('[' + $n + '] ' + $found.Count + ' email(s)  ' + $s.key)
}
$outFile = Join-Path $Dl ('mill_email_candidates_' + (Get-Date -Format 'yyyyMMdd_HHmm') + '.csv')
$result | Export-Csv -LiteralPath $outFile -NoTypeInformation -Encoding UTF8
Write-Output ('DONE  ' + $outFile)
