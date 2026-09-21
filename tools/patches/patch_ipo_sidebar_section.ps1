# patch_ipo_sidebar_section.ps1
# Moves the IPO link out of the top nav into its own "Nasdaq IPO" section
# placed right below PIPELINES (where the Nasdaq Listing Advisors entry is).
# Idempotent. Exact-string anchors; says FAIL if they are missing.

$path = "C:\dev\mbg-project\src\components\layout\sidebar.tsx"
if (-not (Test-Path $path)) { Write-Host "MISS  $path"; exit 1 }
$s = [System.IO.File]::ReadAllText($path).Replace("`r`n", "`n"); $orig = $s

$topLine = "  { href: '/ipo',      labelKey: 'ipo',       icon: Landmark,  label: 'IPO' },`n"
$navEnd  = "          </ul>`n        </nav>`n"
$section = @"
          </ul>

          <Separator className="my-3" />

          {!isCollapsed && (
            <p className="px-2 mb-1 text-[10px] uppercase tracking-wider text-muted-foreground font-medium">
              Nasdaq IPO
            </p>
          )}
          <ul className="space-y-0.5">
            <NavLink
              href="/ipo"
              icon={<Landmark className="h-4 w-4 shrink-0" />}
              label="IPO Readiness"
              active={isActive(pathname, '/ipo')}
              collapsed={isCollapsed}
              onNavigate={onNavigate}
            />
          </ul>
        </nav>

"@
$section = $section.Replace("`r`n", "`n")

if ($s.Contains('label="IPO Readiness"')) { Write-Host "SKIP  section already present"; exit 0 }
if (-not $s.Contains("Landmark,"))          { Write-Host "FAIL  Landmark import missing (run patch_ipo_sidebar_nav.ps1 first)"; exit 1 }
if (-not $s.Contains($navEnd))              { Write-Host "FAIL  </ul></nav> anchor not found"; exit 1 }

$s = $s.Replace($topLine, "")
$s = $s.Replace($navEnd, $section)
[System.IO.File]::WriteAllText($path, $s)
Write-Host "OK    sidebar: IPO moved to its own section under Pipelines"
