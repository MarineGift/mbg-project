# patch_ipo_sidebar_nav.ps1
# Adds the /ipo nav item to src/components/layout/sidebar.tsx (idempotent).
#   1) imports Landmark from lucide-react
#   2) inserts { href: '/ipo', ... } after the Reports item
# Normalizes CRLF -> LF before matching, writes back LF.

$repo = "C:\dev\mbg-project"
$path = Join-Path $repo "src\components\layout\sidebar.tsx"
if (-not (Test-Path $path)) { Write-Host "MISS  $path"; exit 1 }

$s = [System.IO.File]::ReadAllText($path)
$s = $s.Replace("`r`n", "`n")
$orig = $s

if ($s -notmatch "Landmark,") {
  $s = $s.Replace("  BarChart3,`n} from 'lucide-react';", "  BarChart3,`n  Landmark,`n} from 'lucide-react';")
}
$reportsLine = "  { href: '/reports',  labelKey: 'reports',   icon: BarChart3, label: 'Reports' },"
$ipoLine     = "  { href: '/ipo',      labelKey: 'ipo',       icon: Landmark,  label: 'IPO' },"
if ($s -notmatch "href: '/ipo'") {
  $s = $s.Replace($reportsLine, $reportsLine + "`n" + $ipoLine)
}

if ($s -eq $orig) { Write-Host "SKIP  sidebar.tsx already patched"; exit 0 }
if ($s -notmatch "Landmark," -or $s -notmatch "href: '/ipo'") {
  Write-Host "FAIL  anchors not found; inspect sidebar.tsx manually"; exit 1
}
[System.IO.File]::WriteAllText($path, $s)
Write-Host "OK    sidebar.tsx patched (Landmark import + /ipo nav item)"
