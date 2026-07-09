# patch_package_json_apply_scripts.ps1
# Adds two npm scripts to C:\dev\mbg-project\package.json (in-place, idempotent).
#   apply:inspect -> selector collection helper
#   apply:fill    -> Playwright semi-auto form filler
# ASCII-only output. Safe to run twice.

$path = "C:\dev\mbg-project\package.json"
if (-not (Test-Path $path)) { Write-Host "NOT FOUND: $path"; exit 1 }

$text = [System.IO.File]::ReadAllText($path)
$text = $text -replace "`r`n", "`n"   # normalize CRLF to LF first

if ($text.Contains('"apply:fill"')) {
  Write-Host "SKIP: apply:fill already present (idempotent guard)"
  exit 0
}

$anchor = '"verify:smtp": "tsx --env-file=.env.local src/scripts/verify-smtp.ts"'
if (-not $text.Contains($anchor)) {
  Write-Host "ANCHOR NOT FOUND - patch package.json manually:"
  Write-Host '  "apply:inspect": "tsx --env-file=.env.local src/scripts/inspect-form.ts",'
  Write-Host '  "apply:fill": "tsx --env-file=.env.local src/scripts/fill-application.ts"'
  exit 1
}

$replacement = $anchor + ",`n" +
  '    "apply:inspect": "tsx --env-file=.env.local src/scripts/inspect-form.ts",' + "`n" +
  '    "apply:fill": "tsx --env-file=.env.local src/scripts/fill-application.ts"'

$text = $text.Replace($anchor, $replacement)
[System.IO.File]::WriteAllText($path, $text)
Write-Host "OK: apply:inspect and apply:fill added to package.json"
