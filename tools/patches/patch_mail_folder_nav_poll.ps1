# patch_mail_folder_nav_poll.ps1
# Sidebar mail-folder counts: 30s poll -> 120s, and skip while the tab is hidden.
# Focus / visibility / mail-arrived refreshes stay as they are.
# Idempotent. PS 5.x compatible. ASCII output only.

$Repo = 'C:\dev\mbg-project'
$f = Join-Path $Repo 'src\components\layout\mail-folder-nav.tsx'
if (-not (Test-Path -LiteralPath $f)) { Write-Output ('ERROR: not found ' + $f); return }

$enc = New-Object System.Text.UTF8Encoding($false)
$s = [System.IO.File]::ReadAllText($f, $enc) -replace "`r`n", "`n"

$old1 = '    const timer = setInterval(load, 30_000)'
$new1 = '    const timer = setInterval(() => { if (document.visibilityState === ''visible'') load() }, 120_000)'
$old2 = '// Refresh on navigation, on a 30s timer,'
$new2 = '// Refresh on navigation, on a 120s timer (visible tab only),'

if ($s.Contains($new1)) {
  Write-Output 'SKIP  already patched'
} elseif ($s.Contains($old1)) {
  $s = $s.Replace($old1, $new1).Replace($old2, $new2)
  [System.IO.File]::WriteAllText($f, $s, $enc)
  Write-Output 'OK    mail-folder-nav.tsx patched (120s, visible only)'
} else {
  Write-Output 'ERROR anchor not found - file changed, nothing written'
}
