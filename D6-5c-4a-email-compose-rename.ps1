# =============================================================
# D6-5c-4a-email-compose-rename.ps1
#
# Targeted column rename in src/lib/actions/email-compose.ts.
# Resolves 12 tsc errors via 6 str_replace operations:
#   1. parties select: "name" -> "party_name"
#   2. parties property access: party.name -> party.party_name
#   3. contacts select: "party_id" -> "firm_party_id"
#   4. contacts select: "title, department, phone" -> "title_text, department, phone_e164"
#   5. contact property access: contact.title -> contact.title_text
#   6. contact property access: contact.phone -> contact.phone_e164
#
# Template variable names ({{party.name}}, {{contact.title}}, etc.)
# are PRESERVED — these are user-facing template tokens, not column refs.
#
# DRY RUN by default. -Apply to execute.
# =============================================================

[CmdletBinding()]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$DryRun = -not $Apply

$file = 'src/lib/actions/email-compose.ts'

if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    Write-Host "ERROR: $file not found"
    exit 1
}

# Each replacement: from -> to. Order matters when patterns nest.
$replacements = @(
    @{ 
        label = '[1] parties select column'
        from  = '.select("name, country_code, website")'
        to    = '.select("party_name, country_code, website")'
    },
    @{ 
        label = '[2] party.name property access'
        from  = '.replace(/{{party\.name}}/g, party.name ?? "")'
        to    = '.replace(/{{party\.name}}/g, party.party_name ?? "")'
    },
    @{ 
        label = '[3] contacts FK column'
        from  = '.eq("party_id", partyId)'
        to    = '.eq("firm_party_id", partyId)'
    },
    @{ 
        label = '[4] contacts select columns'
        from  = '.select("given_name, family_name, email, title, department, phone")'
        to    = '.select("given_name, family_name, email, title_text, department, phone_e164")'
    },
    @{ 
        label = '[5] contact.title property'
        from  = '.replace(/{{contact\.title}}/g, contact.title ?? "")'
        to    = '.replace(/{{contact\.title}}/g, contact.title_text ?? "")'
    },
    @{ 
        label = '[6] contact.phone property'
        from  = '.replace(/{{contact\.phone}}/g, contact.phone ?? "")'
        to    = '.replace(/{{contact\.phone}}/g, contact.phone_e164 ?? "")'
    }
)

Write-Host ''
Write-Host '======================================'
if ($DryRun) {
    Write-Host 'D6-5c-4a email-compose rename (DRY RUN)'
} else {
    Write-Host 'D6-5c-4a email-compose rename (APPLY MODE)'
}
Write-Host '======================================'
Write-Host ''

$content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
$originalContent = $content
$applied = 0
$missed = 0

foreach ($r in $replacements) {
    if ($content.Contains($r.from)) {
        if (-not $DryRun) {
            $content = $content.Replace($r.from, $r.to)
        }
        Write-Host ('  OK  {0}' -f $r.label)
        $applied++
    } else {
        Write-Host ('  MISS {0} (pattern not found)' -f $r.label)
        $missed++
    }
}

Write-Host ''
Write-Host ('--- Summary: {0} applied, {1} missed ---' -f $applied, $missed)

if ($missed -gt 0) {
    Write-Host ''
    Write-Host 'WARNING: Some patterns did not match. File may have been edited'
    Write-Host '         already, or formatting differs. Review before -Apply.'
}

if ($DryRun) {
    Write-Host ''
    Write-Host 'To apply:'
    Write-Host '  .\D6-5c-4a-email-compose-rename.ps1 -Apply'
    exit 0
}

if ($applied -gt 0 -and $missed -eq 0) {
    # Write with UTF-8 (no BOM)
    [System.IO.File]::WriteAllText(
        (Resolve-Path -LiteralPath $file).Path,
        $content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Host ''
    Write-Host ('WROTE: {0}' -f $file)
} elseif ($missed -gt 0) {
    Write-Host ''
    Write-Host 'Not writing — at least one pattern missed. Review manually.'
    exit 1
}

Write-Host ''
Write-Host '======================================'
Write-Host 'D6-5c-4a applied'
Write-Host '======================================'
Write-Host ''
Write-Host 'NEXT: verify with tsc'
Write-Host '  npx tsc --noEmit 2>&1 | Out-File -Encoding utf8 D6-5c-4a-post-tsc.txt'
Write-Host '  (Get-Content D6-5c-4a-post-tsc.txt | Select-String -Pattern "error TS" | Measure-Object).Count'
Write-Host '  Expected: ~8 errors (was 20)'
