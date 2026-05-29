# fix-audit-client.ps1  -- add a single narrowing guard after the OP_META lookup.
# After 'if (!meta) return null', TS narrows meta for all JSX below; original
# <meta.Icon> / ${meta.cls} / {meta.label} then type-check with no '!' needed.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File .\fix-audit-client.ps1
$ErrorActionPreference = 'Stop'
$enc  = New-Object System.Text.UTF8Encoding $false
$rel  = "src\app\(app)\settings\audit\audit-client.tsx"
$full = (Resolve-Path -LiteralPath $rel).Path
$t = [System.IO.File]::ReadAllText($full); $orig = $t

$oLF = "            const meta = OP_META[r.operation]`n            const open = expanded.has(r.id)"
$nLF = "            const meta = OP_META[r.operation]`n            if (!meta) return null`n            const open = expanded.has(r.id)"
$oCR = $oLF -replace "`n","`r`n"; $nCR = $nLF -replace "`n","`r`n"

if     ($t.Contains($oLF)) { $t = $t.Replace($oLF,$nLF); $hit='LF' }
elseif ($t.Contains($oCR)) { $t = $t.Replace($oCR,$nCR); $hit='CRLF' }
else   { Write-Host "MISS: lookup anchor not found - paste lines 103-107 to verify." -ForegroundColor Yellow; return }

if ($t.Contains('<meta!.Icon') -or $t.Contains('${meta!.cls}')) {
  Write-Host "WARN: file still has '!'-patched JSX (bak restore not done?). Restore .bak first." -ForegroundColor Yellow; return
}
[System.IO.File]::WriteAllText($full + '.bak2', $orig, $enc)
[System.IO.File]::WriteAllText($full, $t, $enc)
Write-Host ("patched audit-client.tsx via {0} anchor (backup: .bak2)" -f $hit) -ForegroundColor Green
