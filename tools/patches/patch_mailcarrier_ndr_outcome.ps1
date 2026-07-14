# patch_mailcarrier_ndr_outcome.ps1
# Adds NDR outcome recording (app.email_send_outcomes, hard AND soft bounces)
# to MailCarrierClient.autoSuppress in src/lib/email/mailcarrier.ts.
# Idempotent: skips when the file already contains 'recordNdrOutcomes'.
# ASCII-only output. Run from anywhere:
#   powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_mailcarrier_ndr_outcome.ps1

$path = 'C:\dev\mbg-project\src\lib\email\mailcarrier.ts'
if (-not (Test-Path -LiteralPath $path)) { Write-Host "FAIL: not found $path"; exit 1 }

$t = [System.IO.File]::ReadAllText($path)
$t = $t.Replace("`r`n", "`n")

if ($t.Contains('recordNdrOutcomes')) {
  Write-Host 'SKIP: mailcarrier.ts already patched (recordNdrOutcomes present)'
  exit 0
}

# --- 1. imports -------------------------------------------------------------
$importAnchor = "import { registerSuppressions } from './blocklist';"
if (-not $t.Contains($importAnchor)) { Write-Host 'FAIL: import anchor not found'; exit 1 }

$importAdd = $importAnchor + "`n" +
  "import { detectNdrOutcome } from './ndr-outcome';" + "`n" +
  "import { recordNdrOutcomes } from './outcome-recorder';"
$t = $t.Replace($importAnchor, $importAdd)

# --- 2. hook inside autoSuppress, BEFORE detectSuppressions -----------------
# (soft 4xx bounces produce no suppression signal, so the hook must run before
#  the "signals.length === 0 -> return" early exit.)
$callAnchor = '    const signals = detectSuppressions({'
if (-not $t.Contains($callAnchor)) { Write-Host 'FAIL: call anchor not found'; exit 1 }

$block = @'
    // -- NDR outcome logging into app.email_send_outcomes (hard AND soft) --
    // Independent of the blocklist suppression below: soft (4xx) bounces are
    // recorded for /mailing/outcomes but never blocklisted. Best-effort;
    // hard bounces also fail the address's active enrollments (recorder).
    try {
      const ndr = detectNdrOutcome({
        fromAddress: headers.from.address,
        fromName: headers.from.name ?? null,
        subject: headers.subject,
        text: parsed.text ?? '',
        html: parsed.html || null,
        contentType,
        ownAddresses: own,
      });
      if (ndr) {
        const evidenceRef = (
          headers.messageId || `${headers.from.address}|${headers.subject}`
        ).slice(0, 200);
        const recorded = await recordNdrOutcomes(
          this.supabase,
          this.organizationId,
          ndr,
          evidenceRef,
        );
        if (recorded > 0) {
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.logTag}] outcome recorded: ${recorded} ${ndr.severity} bounce(s)`,
          );
        }
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(`[mailcarrier:${this.logTag}] ndr-outcome error:`, err);
    }

'@

$block = $block.Replace("`r`n", "`n")
$t = $t.Replace($callAnchor, $block + $callAnchor)

[System.IO.File]::WriteAllText($path, $t)
Write-Host 'PATCHED: src/lib/email/mailcarrier.ts (+NDR outcome recording in autoSuppress)'
Write-Host 'NEXT: ensure src/lib/email/ndr-outcome.ts and outcome-recorder.ts exist, then npm test'
exit 0
