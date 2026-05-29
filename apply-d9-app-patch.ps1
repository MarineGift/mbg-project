# ============================================================================
#  apply-d9-app-patch.ps1
#  Run from repo root:  powershell -ExecutionPolicy Bypass -File .\apply-d9-app-patch.ps1
#  (1) database.ts type alignment via python  (2) fix the 15 pre-existing tsc errors
#  Each changed file backed up to *.bak . ASCII-only console output.
# ============================================================================
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding $false   # UTF-8 no BOM

function PatchFile([string]$rel, [hashtable[]]$edits) {
  $full = (Resolve-Path -LiteralPath $rel).Path
  $t = [System.IO.File]::ReadAllText($full)
  $orig = $t
  foreach ($e in $edits) {
    $oldLF = $e.old -replace "`r`n", "`n"
    $newLF = $e.new -replace "`r`n", "`n"
    $oldCRLF = $oldLF -replace "`n", "`r`n"
    $newCRLF = $newLF -replace "`n", "`r`n"
    if     ($t.Contains($oldLF))   { $t = $t.Replace($oldLF,   $newLF) }
    elseif ($t.Contains($oldCRLF)) { $t = $t.Replace($oldCRLF, $newCRLF) }
    else { Write-Host ("  MISS in {0}: anchor not found -> {1}" -f $rel, $e.tag) -ForegroundColor Yellow }
  }
  if ($t -ne $orig) {
    [System.IO.File]::WriteAllText($full + '.bak', $orig, $enc)
    [System.IO.File]::WriteAllText($full, $t, $enc)
    Write-Host ("  patched: {0}" -f $rel) -ForegroundColor Green
  } else {
    Write-Host ("  no change: {0}" -f $rel) -ForegroundColor Yellow
  }
}

Write-Host "== 1) database.ts (python, BOM/encoding-safe) ==" -ForegroundColor Cyan
python patch_database_ts.py "src\types\database.ts"
if ($LASTEXITCODE -ne 0) { throw "patch_database_ts.py failed - aborting code patches." }

Write-Host "== 2) contacts-table.tsx (strict-null initials) =="
PatchFile "src\app\(app)\contacts\contacts-table.tsx" @(
  @{ tag='initials-1'; old='return (c.given_name[0] + c.family_name[0]).toUpperCase();';
                        new='return (c.given_name[0]! + c.family_name[0]!).toUpperCase();' },
  @{ tag='initials-2'; old='if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();';
                        new='if (parts.length >= 2) return (parts[0]![0]! + parts[parts.length - 1]![0]!).toUpperCase();' }
)

Write-Host "== 3) audit-client.tsx (meta guard) =="
PatchFile "src\app\(app)\settings\audit\audit-client.tsx" @(
  @{ tag='meta-icon'; old='<meta.Icon className={`h-3.5 w-3.5 shrink-0 ${meta.cls}`} />';
                       new='<meta!.Icon className={`h-3.5 w-3.5 shrink-0 ${meta!.cls}`} />' },
  @{ tag='meta-span'; old='<span className={`font-medium ${meta.cls}`}>{meta.label}</span>';
                       new='<span className={`font-medium ${meta!.cls}`}>{meta!.label}</span>' }
)

Write-Host "== 4) sidebar.tsx (deals optional) =="
PatchFile "src\components\layout\sidebar.tsx" @(
  @{ tag='dealcount'; old='dealCount: p.deals && p.deals.length > 0 ? p.deals[0].count : 0,';
                       new='dealCount: p.deals && p.deals.length > 0 ? p.deals[0]!.count : 0,' }
)

Write-Host "== 5) as any -> as never (strict update, Gotcha #45) =="
PatchFile "src\app\(app)\tasks\actions.ts" @(
  @{ tag='tasks-update'; old="completed_at: newStatus === 'completed' ? new Date().toISOString() : null,`n    } as any)";
                          new="completed_at: newStatus === 'completed' ? new Date().toISOString() : null,`n    } as never)" }
)
PatchFile "src\lib\google\client.ts" @(
  @{ tag='google-update'; old="updated_at: new Date().toISOString(),`n      } as any)";
                           new="updated_at: new Date().toISOString(),`n      } as never)" }
)
PatchFile "src\app\(app)\settings\assignments\actions.ts" @(
  @{ tag='assign-update'; old=".update({ owner_user_id: ownerUserId } as any, { count: 'exact' })";
                           new=".update({ owner_user_id: ownerUserId } as never, { count: 'exact' })" }
)

Write-Host "== 6) communication-detail-v2.ts (partyType assert) =="
PatchFile "src\lib\queries\communication-detail-v2.ts" @(
  @{ tag='partytype'; old=": (party.party_types as { code: string } | null)?.code) as CommunicationDetail['party']['partyType'],";
                       new=": (party.party_types as { code: string } | null)?.code) as unknown as CommunicationDetail['party']['partyType']," }
)

Write-Host ""
Write-Host "DONE. Now run:  npx tsc --noEmit   (expect 0 errors)" -ForegroundColor Cyan
