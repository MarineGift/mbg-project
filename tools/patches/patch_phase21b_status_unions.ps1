# patch_phase21b_status_unions.ps1
# Fix pending item 5: add 'draft' to SequenceStatus, 'failed' to EnrollmentStatus
# Target: C:\dev\mbg-project\src\types\phase21b.ts
# Idempotent: safe to run twice. ASCII-only output.

$ErrorActionPreference = 'Stop'
$p = 'C:\dev\mbg-project\src\types\phase21b.ts'

if (-not (Test-Path $p)) { Write-Host "ABORT: file not found: $p"; exit 1 }

$t = [System.IO.File]::ReadAllText($p)
$t = $t.Replace("`r`n", "`n")   # normalize CRLF -> LF

$fail = $false

# --- 1. SequenceStatus: add 'draft' ---
$o1 = "export type SequenceStatus    = 'active' | 'paused' | 'archived';"
$n1 = "export type SequenceStatus    = 'draft' | 'active' | 'paused' | 'archived';"
if ($t.Contains($n1)) {
    Write-Host "[1] SequenceStatus  : ALREADY PATCHED"
} elseif ($t.Contains($o1)) {
    $t = $t.Replace($o1, $n1)
    Write-Host "[1] SequenceStatus  : PATCHED (+'draft')"
} else {
    Write-Host "[1] SequenceStatus  : TARGET NOT FOUND - ABORTING"
    $fail = $true
}

# --- 2. EnrollmentStatus: add 'failed' ---
$o2 = "export type EnrollmentStatus  = 'active' | 'paused' | 'completed' | 'cancelled';"
$n2 = "export type EnrollmentStatus  = 'active' | 'paused' | 'completed' | 'cancelled' | 'failed';"
if ($t.Contains($n2)) {
    Write-Host "[2] EnrollmentStatus: ALREADY PATCHED"
} elseif ($t.Contains($o2)) {
    $t = $t.Replace($o2, $n2)
    Write-Host "[2] EnrollmentStatus: PATCHED (+'failed')"
} else {
    Write-Host "[2] EnrollmentStatus: TARGET NOT FOUND - ABORTING"
    $fail = $true
}

if ($fail) { Write-Host "NO CHANGES WRITTEN."; exit 1 }

[System.IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "DONE: $p written (UTF-8 no BOM, LF)."
Write-Host "Verify: npx tsc --noEmit  (phase21b-related errors should drop; pre-existing 15 errors in 5 files remain)"
