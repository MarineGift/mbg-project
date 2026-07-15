# =====================================================================
# patch_20260715_tsc_baseline_to_zero.ps1
#
# Clears the long-standing tsc baseline: 15 errors / 5 files -> 0 / 0.
# Verified in a clean checkout of origin/marinebiogroup:
#   before: 15 errors, 5 files  (matches tsc_baseline.txt exactly)
#   after :  0 errors, exit 0
#
# In-place edits: ReadAllText -> normalize CRLF to LF -> .Replace ->
# WriteAllText (UTF-8, no BOM). Every edit is guarded and idempotent:
# re-running this script is a no-op.
#
# ASCII-only output (PS 5.x / CP949 safe).
# =====================================================================

$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$enc  = New-Object System.Text.UTF8Encoding($false)
$applied = 0
$skipped = 0
$failed  = 0

function Edit-File {
    param(
        [string]$RelPath,
        [string]$Old,
        [string]$New,
        [string]$Guard,   # if found, the edit is already applied
        [string]$Label
    )
    $full = Join-Path $repo $RelPath
    if (-not (Test-Path $full)) {
        Write-Host ("  FAIL  {0}`n        file not found: {1}" -f $Label, $full)
        $script:failed++
        return
    }
    $text = [System.IO.File]::ReadAllText($full)
    $text = $text.Replace("`r`n", "`n")

    if ($text.Contains($Guard)) {
        Write-Host ("  SKIP  {0}  (already applied)" -f $Label)
        $script:skipped++
        return
    }
    if (-not $text.Contains($Old)) {
        Write-Host ("  FAIL  {0}`n        anchor not found - file drifted, patch by hand" -f $Label)
        $script:failed++
        return
    }
    # .Replace() hits EVERY occurrence. Refuse to run on a non-unique anchor.
    $hits = ([regex]::Matches($text, [regex]::Escape($Old))).Count
    if ($hits -ne 1) {
        Write-Host ("  FAIL  {0}`n        anchor matches {1}x, expected 1 - refusing" -f $Label, $hits)
        $script:failed++
        return
    }
    $text = $text.Replace($Old, $New)
    [System.IO.File]::WriteAllText($full, $text, $enc)
    Write-Host ("  OK    {0}" -f $Label)
    $script:applied++
}

Write-Host ''
Write-Host '=== patch_20260715_tsc_baseline_to_zero ==='
Write-Host ''

# ---------------------------------------------------------------------
# 1) applications-list-client.tsx  (2x TS18048 'badge' possibly undefined)
#
# noUncheckedIndexedAccess makes Record<string,T> lookups `T | undefined`
# even for a literal fallback key, so METHOD_BADGE.web_form does not
# satisfy the compiler. Inline the same value instead.
# Fallback is byte-identical to METHOD_BADGE.web_form -> behavior unchanged.
# ---------------------------------------------------------------------
$old1 = @'
          const badge = METHOD_BADGE[f.submissionMethod] ?? METHOD_BADGE.web_form
'@
$new1 = @'
          // noUncheckedIndexedAccess: Record lookup is `| undefined` even for
          // the literal fallback key, so fall back to an inline default.
          const badge =
            METHOD_BADGE[f.submissionMethod] ?? { icon: '\u{1F310}', label: 'form' }
'@
Edit-File -RelPath 'src\app\(app)\applications\applications-list-client.tsx' `
          -Old $old1 -New $new1 `
          -Guard 'noUncheckedIndexedAccess: Record lookup' `
          -Label 'applications-list-client.tsx  (TS18048 badge x2)'

# ---------------------------------------------------------------------
# 2a) parties.ts createParty  (TS2339 'sectorFocus' not on partySchema)
#
# ROOT CAUSE, not a cast: partySchema/updateSchema have no sectorFocus.
# The RPC was being sent p_codes: undefined -> the key is dropped from the
# JSON body -> PostgREST answers PGRST202 (no function matches). The call
# has never worked. sectorFocus lives on investorProfileSchema only, so
# the sync belongs in updateInvestorProfile (see 2c).
# party-form.tsx calls updateInvestorProfile immediately after both
# createParty and updateParty, so coverage is identical.
# ---------------------------------------------------------------------
$old2a = @'
    await supabase
      .schema('app')
      .rpc('sync_party_sector_focus' as never,
           { p_party_id: partyId, p_codes: parsed.data.sectorFocus } as never);
    if (syncErr) console.error('[parties.createParty] tag sync error:', syncErr);
  }
'@
$new2a = @'
    if (syncErr) console.error('[parties.createParty] tag sync error:', syncErr);
  }
  // NOTE: sector focus sync moved to updateInvestorProfile (2026-07-15).
  // partySchema has no sectorFocus field; the old call here sent p_codes as
  // undefined, which JSON-drops the key and 404s at PostgREST (PGRST202).
'@
Edit-File -RelPath 'src\lib\actions\parties.ts' `
          -Old $old2a -New $new2a `
          -Guard 'sector focus sync moved to updateInvestorProfile (2026-07-15).' `
          -Label 'parties.ts createParty        (TS2339 sectorFocus)'

# ---------------------------------------------------------------------
# 2b) parties.ts updateParty  (TS2339 'sectorFocus' not on updateSchema)
# ---------------------------------------------------------------------
$old2b = @'
  // Real-time SECTOR focus sync (REPLACE; app.sync_party_sector_focus).
  {
    const { error: secErr } = await supabase
      .schema('app')
      .rpc('sync_party_sector_focus' as never,
           { p_party_id: parsed.data.partyId, p_codes: parsed.data.sectorFocus } as never);
    if (secErr) console.error('[parties.updateParty] sector sync error:', secErr);
  }
'@
$new2b = @'
  // NOTE: sector focus sync moved to updateInvestorProfile (2026-07-15).
  // partySchema/updateSchema carry no sectorFocus; the old call here always
  // failed silently (p_codes undefined -> key dropped -> PGRST202).
'@
Edit-File -RelPath 'src\lib\actions\parties.ts' `
          -Old $old2b -New $new2b `
          -Guard 'partySchema/updateSchema carry no sectorFocus' `
          -Label 'parties.ts updateParty        (TS2339 sectorFocus)'

# ---------------------------------------------------------------------
# 2c) parties.ts updateInvestorProfile  (re-home the sync so it actually runs)
# ---------------------------------------------------------------------
$old2c = @'
      console.error('[parties.updateInvestorProfile] insert error:', insErr);
      return { ok: false, errorCode: 'database', errorMessage: insErr.message };
    }
  }

  revalidatePath(`/${parsed.data.partyType}/parties/${parsed.data.partyId}`);
  return { ok: true, partyId: parsed.data.partyId };
}
'@
$new2c = @'
      console.error('[parties.updateInvestorProfile] insert error:', insErr);
      return { ok: false, errorCode: 'database', errorMessage: insErr.message };
    }
  }

  // Real-time normalized SECTOR sync (app.investor_sector_focus REPLACE).
  // Lives here because sectorFocus exists on investorProfileSchema only --
  // the previous calls in create/updateParty never fired (PGRST202). Non-fatal.
  {
    const { error: secErr } = await supabase
      .schema('app')
      .rpc('sync_party_sector_focus' as never,
           { p_party_id: parsed.data.partyId, p_codes: parsed.data.sectorFocus } as never);
    if (secErr) console.error('[parties.updateInvestorProfile] sector sync error:', secErr);
  }

  revalidatePath(`/${parsed.data.partyType}/parties/${parsed.data.partyId}`);
  return { ok: true, partyId: parsed.data.partyId };
}
'@
Edit-File -RelPath 'src\lib\actions\parties.ts' `
          -Old $old2c -New $new2c `
          -Guard '[parties.updateInvestorProfile] sector sync error:' `
          -Label 'parties.ts updateInvestorProfile (re-home sync)'

# ---------------------------------------------------------------------
# 3) decompose-actions.ts  (TS2345 SbClient 'app' vs 'public')
#
# SbClient is pinned to the 'app' schema generic; ClaudeClient's ctor takes
# the default-generic SupabaseClient. Same object at runtime. Uses the
# repo's established `as never` cast pattern (see send-outbound.ts).
# ---------------------------------------------------------------------
$old3 = @'
    const client = new ClaudeClient(supabase, auth.organizationId);
'@
$new3 = @'
    // SbClient is pinned to the 'app' schema; ClaudeClient's ctor takes the
    // default-generic SupabaseClient. Same-runtime object -- cast (repo pattern).
    const client = new ClaudeClient(supabase as never, auth.organizationId);
'@
Edit-File -RelPath 'src\lib\tasks\decompose-actions.ts' `
          -Old $old3 -New $new3 `
          -Guard 'new ClaudeClient(supabase as never, auth.organizationId)' `
          -Label 'decompose-actions.ts          (TS2345 SbClient)'

# ---------------------------------------------------------------------
# 4a) fill-application.ts parseArg  (TS2322 string|undefined)
# 4b) fill-application.ts head      (8x TS18048 'head' possibly undefined)
#
# process.exit() is typed `never`, so guarding on rows[0] directly narrows
# `head` to FieldRow for the rest of main(). Same runtime behavior as the
# old rows.length === 0 guard.
# ---------------------------------------------------------------------
$oldArg = @'
function parseArg(flag: string): string | null {
  const i = process.argv.indexOf(flag);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : null;
}
'@
$newArg = @'
function parseArg(flag: string): string | null {
  const i = process.argv.indexOf(flag);
  // noUncheckedIndexedAccess: bind the indexed value once so it narrows.
  const v = i >= 0 ? process.argv[i + 1] : undefined;
  return v ?? null;
}
'@
Edit-File -RelPath 'src\scripts\fill-application.ts' `
          -Old $oldArg -New $newArg `
          -Guard 'bind the indexed value once so it narrows' `
          -Label 'fill-application.ts parseArg  (TS2322)'

$old4b = @'
  if (rows.length === 0) {
    console.error('No form found for that id in this org.');
    process.exit(1);
  }

  const head = rows[0];
'@
$new4b = @'
  // noUncheckedIndexedAccess: guard on rows[0] directly (process.exit is
  // typed `never`, so `head` narrows to FieldRow for the rest of main()).
  const head = rows[0];
  if (!head) {
    console.error('No form found for that id in this org.');
    process.exit(1);
  }
'@
Edit-File -RelPath 'src\scripts\fill-application.ts' `
          -Old $old4b -New $new4b `
          -Guard 'guard on rows[0] directly' `
          -Label 'fill-application.ts head      (TS18048 x8)'

# ---------------------------------------------------------------------
# 5) inspect-form.ts parseArg  (TS2322 string|undefined)
# ---------------------------------------------------------------------
Edit-File -RelPath 'src\scripts\inspect-form.ts' `
          -Old $oldArg -New $newArg `
          -Guard 'bind the indexed value once so it narrows' `
          -Label 'inspect-form.ts parseArg      (TS2322)'

# ---------------------------------------------------------------------
Write-Host ''
Write-Host ('  applied={0}  skipped={1}  failed={2}' -f $applied, $skipped, $failed)
Write-Host ''

if ($failed -gt 0) {
    Write-Host 'One or more anchors did not match. NOT running tsc. Fix by hand.'
    exit 1
}

Write-Host 'Verifying with tsc --noEmit (this takes a minute) ...'
Push-Location $repo
try {
    npx tsc --noEmit
    $code = $LASTEXITCODE
} finally {
    Pop-Location
}

Write-Host ''
if ($code -eq 0) {
    Write-Host 'RESULT: tsc clean. Baseline is now 0 errors / 0 files.'
    Write-Host 'Update any doc that still claims "tsc 15 / 5 files = baseline".'
} else {
    Write-Host ('RESULT: tsc still reports errors (exit {0}). See output above.' -f $code)
}
Write-Host ''
