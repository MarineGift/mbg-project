\xef\xbb\xbf# handoff_20260927k_purge_orphan_mail_attachments

## 목적
삭제한 메일(2025-09-28 이전)의 첨부 **파일**을 Supabase Storage 에서 삭제.
DB `app.attachments` 행은 이미 삭제됨 (orphan rows = 0). SQL로는 Storage 파일 삭제 불가 → Storage API 사용.

## 근거 (리포 확인)
- 버킷: `communications-attachments` (env `SUPABASE_STORAGE_BUCKET_ATTACHMENTS` 기본값)
- 경로: `<org>/<communication_id>/<uuid>-<file>` (`src/lib/email/mailcarrier.ts` persistAttachment)
- 수동 업로드 첨부는 Google Drive (`api/attachments/upload`) → 이 버킷과 무관
- 판정: `communication_id` 폴더가 `app.communications` 에 없으면 orphan (소프트삭제 행은 보존)

## 동작
1. `.env.local` 에서 URL / service role key 읽음 (없으면 입력 요청, 키는 저장·출력 안 함)
2. communications id 전체 로드 (100건 미만이면 중단 — 안전장치)
3. 버킷 폴더 순회 → orphan 폴더/파일 수, 용량 표시
4. `DELETE` 입력 시에만 100개씩 삭제

## 스크립트 (PowerShell 에 통째로 붙여넣기)
```powershell
& {
# purge orphan mail attachment files (Supabase Storage)
# Bucket communications-attachments, path = <org>/<communication_id>/<file>
# Deletes only folders whose communication_id no longer exists in app.communications.
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
$H = @{ apikey = $Key; Authorization = ('Bearer ' + $Key) }

function Invoke-Json([string]$method, [string]$uri, $bodyObj, $extra) {
  $hdr = @{}; $H.Keys | ForEach-Object { $hdr[$_] = $H[$_] }
  if ($extra) { $extra.Keys | ForEach-Object { $hdr[$_] = $extra[$_] } }
  if ($null -ne $bodyObj) {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($bodyObj | ConvertTo-Json -Depth 5 -Compress))
    return Invoke-RestMethod -Method $method -Uri $uri -Headers $hdr -ContentType 'application/json' -Body $bytes
  }
  return Invoke-RestMethod -Method $method -Uri $uri -Headers $hdr
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

# 1) live communication ids (incl. soft-deleted rows)
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

# 2) walk bucket: org folders -> communication folders
$orphanDirs = @()
$keptDirs = 0
foreach ($org in (Get-List '')) {
  if ($null -ne $org.id) { continue }            # a file at root, skip
  foreach ($c in (Get-List ($org.name + '/'))) {
    if ($null -ne $c.id) { continue }
    if ($c.name -notmatch '^[0-9a-fA-F-]{36}$') { continue }
    if ($ids.Contains($c.name)) { $keptDirs++ } else { $orphanDirs += ($org.name + '/' + $c.name) }
  }
}
Write-Output ('mail folders kept: ' + $keptDirs + '   orphan folders: ' + $orphanDirs.Count)

# 3) files inside orphan folders
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

# 4) delete in batches of 100
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

## Push (문서만)
```powershell
cd C:\dev\mbg-project
git status -sb
git add docs/handoff
git commit -m "docs: purge orphan mail attachment files"
git push origin marinebiogroup
```
