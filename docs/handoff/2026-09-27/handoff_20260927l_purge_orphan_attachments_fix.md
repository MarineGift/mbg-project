# handoff_20260927l_purge_orphan_attachments_fix

Supersedes the script in handoff_20260927k (do not run that one).

## Fixes
1. "Forbidden use of secret API key in browser": PS 5.1 default User-Agent starts with Mozilla/5.0.
   Fixed with -UserAgent mbg-purge/1.0. sb_ keys are sent in the apikey header only.
2. "communications in DB: 1": PS 5.1 Invoke-RestMethod returns a JSON array as ONE object.
   Invoke-Json now unrolls the result. The under-100 guard stopped the run, nothing was deleted.

## Result (2026-09-27)
- communications in DB 4353, mail folders kept 744, orphan folders 756
- 1666 orphan files deleted (about 1.03 GB), no errors

## Rerun later
1. SQL editor: sql/repair_20260927f_delete_mail_older_12m.sql until remaining = 0
2. PowerShell: paste the script below (dry run first, type DELETE to proceed)

## Script
```powershell
& {
$ErrorActionPreference = 'Stop'
$Repo   = 'C:\dev\mbg-project'
$Bucket = 'communications-attachments'
function Get-EnvVal([string]$name) {
  foreach ($f in @('.env.local', '.env')) {
    $p = Join-Path $Repo $f
    if (Test-Path -LiteralPath $p) {
      $line = Get-Content -LiteralPath $p | Where-Object { $_ -match ('^\s*' + $name + '\s*=') } | Select-Object -First 1
      if ($line) { return (($line -split '=', 2)[1]).Trim().Trim('"').Trim("'") }
    }
  }
  return $null
}
$Url = Get-EnvVal 'NEXT_PUBLIC_SUPABASE_URL'
$Key = Get-EnvVal 'SUPABASE_SERVICE_ROLE_KEY'
$b = Get-EnvVal 'SUPABASE_STORAGE_BUCKET_ATTACHMENTS'; if ($b) { $Bucket = $b }
if (-not $Url) { $Url = Read-Host 'Supabase URL (https://xxxx.supabase.co)' }
if (-not $Key) { $Key = Read-Host 'Service role key' }
$Url = $Url.TrimEnd('/')
$H = @{ apikey = $Key }
if (-not $Key.StartsWith('sb_')) { $H['Authorization'] = ('Bearer ' + $Key) }
$UA = 'mbg-purge/1.0'
function Invoke-Json([string]$method, [string]$uri, $bodyObj, $extra) {
  $hdr = @{}; $H.Keys | ForEach-Object { $hdr[$_] = $H[$_] }
  if ($extra) { $extra.Keys | ForEach-Object { $hdr[$_] = $extra[$_] } }
  if ($null -ne $bodyObj) {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($bodyObj | ConvertTo-Json -Depth 5 -Compress))
    $res = Invoke-RestMethod -Method $method -Uri $uri -Headers $hdr -ContentType 'application/json' -Body $bytes -UserAgent $UA
  } else {
    $res = Invoke-RestMethod -Method $method -Uri $uri -Headers $hdr -UserAgent $UA
  }
  foreach ($x in $res) { $x }
}
function Get-List([string]$prefix) {
  $all = @(); $off = 0
  while ($true) {
    $page = @(Invoke-Json 'Post' ($Url + '/storage/v1/object/list/' + $Bucket) @{ prefix = $prefix; limit = 1000; offset = $off } $null)
    $all += $page
    if ($page.Count -lt 1000) { break }
    $off += 1000
  }
  return $all
}
Write-Output 'Loading communication ids...'
$ids = New-Object 'System.Collections.Generic.HashSet[string]'
$off = 0
while ($true) {
  $rows = @(Invoke-Json 'Get' ($Url + '/rest/v1/communications?select=id&order=id&limit=1000&offset=' + $off) $null @{ 'Accept-Profile' = 'app' })
  foreach ($r in $rows) { [void]$ids.Add([string]$r.id) }
  if ($rows.Count -lt 1000) { break }
  $off += 1000
}
Write-Output ('communications in DB: ' + $ids.Count)
if ($ids.Count -lt 100) { Write-Output 'ABORT: too few ids loaded - check key/URL.'; return }
$orphanDirs = @()
$keptDirs = 0
foreach ($org in (Get-List '')) {
  if ($null -ne $org.id) { continue }
  foreach ($c in (Get-List ($org.name + '/'))) {
    if ($null -ne $c.id) { continue }
    if ($c.name -notmatch '^[0-9a-fA-F-]{36}$') { continue }
    if ($ids.Contains($c.name)) { $keptDirs++ } else { $orphanDirs += ($org.name + '/' + $c.name) }
  }
}
Write-Output ('mail folders kept: ' + $keptDirs + '   orphan folders: ' + $orphanDirs.Count)
$files = @(); $bytes = [int64]0
foreach ($d in $orphanDirs) {
  foreach ($f in (Get-List ($d + '/'))) {
    if ($null -eq $f.id) { continue }
    $files += ($d + '/' + $f.name)
    if ($f.metadata -and $f.metadata.size) { $bytes += [int64]$f.metadata.size }
  }
}
Write-Output ('orphan files: ' + $files.Count + '   size MB: ' + [math]::Round($bytes / 1MB, 1))
if ($files.Count -eq 0) { Write-Output 'Nothing to delete.'; return }
$ans = Read-Host 'Type DELETE to remove these files'
if ($ans -ne 'DELETE') { Write-Output 'Cancelled. Nothing deleted.'; return }
$done = 0
for ($i = 0; $i -lt $files.Count; $i += 100) {
  $batch = @($files[$i..([math]::Min($i + 99, $files.Count - 1))])
  try {
    $res = @(Invoke-Json 'Delete' ($Url + '/storage/v1/object/' + $Bucket) @{ prefixes = $batch } $null)
    $done += $res.Count
    Write-Output ('deleted ' + $done + ' / ' + $files.Count)
  } catch {
    Write-Output ('ERROR batch at ' + $i + ': ' + $_.Exception.Message)
  }
}
Write-Output ('DONE. deleted files: ' + $done)
}
```