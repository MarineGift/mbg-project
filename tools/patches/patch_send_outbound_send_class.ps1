# =====================================================================
# patch_send_outbound_send_class.ps1
#
# Structural do-not-send guard: move the check into sendOutboundEmail so a
# NEW send path is guarded by default instead of silently unguarded.
#
# Design
#   SendOutboundInput.sendClass?: 'cold' | 'direct'   (default 'cold')
#     cold   -> app.v_email_do_not_send blocks by resolved address OR partyId
#     direct -> only rows with blocks_direct = true block (unsubscribe /
#               suppress). A human replying to a firm that submitted a form,
#               replied or declined is NOT blocked.
#
#   Default 'cold' is deliberate and fail-closed: an unlabelled new path gets
#   guarded. A wrongly blocked send surfaces as a visible UI error, a wrongly
#   sent cold mail silently kills a lead.
#
# Files patched (6)
#   src/lib/email/send-outbound.ts        core: type + field + errorCode + guard
#   src/lib/utils/sequence-processor.ts   cold
#   src/lib/actions/bulk-mail.ts          cold
#   src/lib/actions/email-compose.ts      direct
#   src/lib/actions/communications.ts     direct
#   src/lib/actions/drafts.ts             direct  (AI reply to inbound)
#
# ORDER: apply sql/migration_20260715000100_v_email_do_not_send_blocks_direct.sql
#        BEFORE pushing. The code tolerates the old view (42703 -> re-select
#        without blocks_direct, direct guard degrades to today behaviour, cold
#        guard still works), so the order is a preference, not a hazard.
#
# Idempotent: every edit is guarded on a marker string. ASCII output only.
# =====================================================================

$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'

function Read-Norm($p) {
  $t = [System.IO.File]::ReadAllText($p)
  return $t.Replace("`r`n", "`n")
}
function Write-Lf($p, $t) {
  [System.IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))
}

# ---------------------------------------------------------------- core
$core = Join-Path $repo 'src\lib\email\send-outbound.ts'
$t = Read-Norm $core

if ($t -match 'export type SendClass') {
  Write-Output 'SKIP: send-outbound.ts already patched'
} else {

  # [A] SendClass type
  $oldA = 'export interface SendOutboundInput {'
  $newA = @'
/** What kind of send this is. Decides how app.v_email_do_not_send applies.
 *
 *  cold   -- automated/campaign outbound (sequence worker, bulk mail). EVERY
 *            do-not-send row blocks: form submitted, replied, declined,
 *            unsubscribed, hard bounced, or inside a resend_later cooldown.
 *  direct -- a human (or an approved AI reply) writing to a specific person.
 *            Only rows with blocks_direct = true block, i.e. unsubscribe
 *            requests and explicit suppression. Replying to a firm that
 *            submitted our form or answered us must never be blocked.
 *
 *  DEFAULT IS 'cold'. A new send path that forgets to declare itself gets
 *  guarded rather than silently bypassing the list. This is the whole point:
 *  on 2026-07-14 the sequence path was found sending unguarded for exactly
 *  that reason -- the guard lived in the callers, not here.
 */
export type SendClass = 'cold' | 'direct';

export interface SendOutboundInput {
'@
  if ($t -notlike "*$oldA*") { throw 'ANCHOR A not found in send-outbound.ts' }
  $t = $t.Replace($oldA, $newA.Replace("`r`n", "`n").TrimEnd("`n"))

  # [B] input field
  $oldB = @'
  // safety (decision a) - core enforces whitelist unless explicitly skipped
  skipWhitelist?: boolean;
'@
  $newB = @'
  // safety (decision a) - core enforces whitelist unless explicitly skipped
  skipWhitelist?: boolean;

  /** cold (default) | direct -- see SendClass. NOT bypassable by skipWhitelist:
   *  the do-not-send list is a separate concern from the whitelist. */
  sendClass?: SendClass;
'@
  $oldB = $oldB.Replace("`r`n", "`n"); $newB = $newB.Replace("`r`n", "`n")
  if ($t -notlike "*$oldB*") { throw 'ANCHOR B not found in send-outbound.ts' }
  $t = $t.Replace($oldB, $newB)

  # [C] errorCode union
  $oldC = "errorCode?: 'not_whitelisted' | 'blocklisted' | 'database' | 'send_failed' | 'pii_tokens_present';"
  $newC = "errorCode?: 'not_whitelisted' | 'blocklisted' | 'do_not_send' | 'database' | 'send_failed' | 'pii_tokens_present';"
  if ($t -notlike "*$oldC*") { throw 'ANCHOR C not found in send-outbound.ts' }
  $t = $t.Replace($oldC, $newC)

  # [D] the guard, inserted between the blocklist block and the whitelist block
  $oldD = '  if (!input.skipWhitelist) {'
  $newD = @'
  // [0a] do-not-send guard (app.v_email_do_not_send). Structural fix for the
  //      2026-07-14 finding: public.get_due_enrollments() had no guard and the
  //      worker sent whatever it returned, because the guard lived per-caller.
  //      Putting it here means a new send path is covered on day one.
  //
  //      Matching mirrors the SQL guard so the two cannot drift:
  //        - by resolved recipient address (email_lower), AND
  //        - by party_id -- deliberately broad. Verified 2026-07-14: 3 of 5
  //          blocks would have been missed by address alone, because the human
  //          who declined wrote from a personal address while the sequence
  //          sends to the intake address (craig@ vs info@, jo@ vs inbound@,
  //          collin@ vs info@).
  //
  //      Not bypassable by skipWhitelist -- different concern.
  //      The view has NO organization_id (see docs/schema/app_schema_reference.md).
  {
    const sendClass: SendClass = input.sendClass ?? 'cold';

    type DnsRow = {
      email_lower: string | null;
      party_id: string | null;
      outcomes: string | null;
      blocks_direct?: boolean | null;
    };

    const isMissingRelation = (e: { code?: string; message?: string }): boolean => {
      const code = e.code ?? '';
      return (
        code === '42P01' ||
        code === 'PGRST205' ||
        /does not exist|could not find the table|schema cache/i.test(e.message ?? '')
      );
    };
    const isMissingColumn = (e: { code?: string; message?: string }): boolean =>
      (e.code ?? '') === '42703' || /column .* does not exist/i.test(e.message ?? '');

    const loadDns = async (withBlocksDirect: boolean) =>
      supabase
        .schema('app')
        .from('v_email_do_not_send' as never)
        .select(
          withBlocksDirect
            ? 'email_lower, party_id, outcomes, blocks_direct'
            : 'email_lower, party_id, outcomes',
        );

    let dnsRows: DnsRow[] = [];
    let dnsUnavailable = false;

    let { data: dnsRaw, error: dnsErr } = await loadDns(true);
    if (dnsErr && isMissingColumn(dnsErr as { code?: string; message?: string })) {
      // The blocks_direct migration has not been applied yet. Fall back: the
      // cold guard still works; direct sends keep today behaviour (unguarded).
      console.warn(
        '[sendOutbound] v_email_do_not_send.blocks_direct missing; run migration_20260715000100. Direct sends are unguarded until then.',
      );
      ({ data: dnsRaw, error: dnsErr } = await loadDns(false));
    }
    if (dnsErr) {
      if (!isMissingRelation(dnsErr as { code?: string; message?: string })) {
        // Real lookup error -> fail closed.
        return {
          ok: false,
          status: 'blocked',
          errorCode: 'database',
          errorMessage: `Do-not-send lookup failed: ${dnsErr.message}`,
        };
      }
      console.warn(
        '[sendOutbound] v_email_do_not_send not found; skipping do-not-send check. Run the email-send-outcomes migration.',
      );
      dnsUnavailable = true;
    }
    if (!dnsUnavailable) dnsRows = (dnsRaw ?? []) as DnsRow[];

    const recipientsLower = toRecipients.map((a) => a.toLowerCase());
    const matched = dnsRows.filter((r) => {
      const emailHit = r.email_lower ? recipientsLower.includes(r.email_lower.toLowerCase()) : false;
      const partyHit = input.partyId ? r.party_id === input.partyId : false;
      return emailHit || partyHit;
    });

    const blocking =
      sendClass === 'cold' ? matched : matched.filter((r) => r.blocks_direct === true);

    if (blocking.length > 0) {
      const reasons = Array.from(
        new Set(blocking.map((r) => r.outcomes ?? '').filter((s) => s !== '')),
      ).join(', ');
      return {
        ok: false,
        status: 'blocked',
        errorCode: 'do_not_send',
        errorMessage: `Recipient is on the do-not-send list (${sendClass}): ${reasons}`,
      };
    }
  }

  if (!input.skipWhitelist) {
'@
  $newD = $newD.Replace("`r`n", "`n")
  if ($t -notlike "*$oldD*") { throw 'ANCHOR D not found in send-outbound.ts' }
  $t = $t.Replace($oldD, $newD)

  Write-Lf $core $t
  Write-Output 'PATCHED: src\lib\email\send-outbound.ts'
}

# ---------------------------------------------------------- call sites
$sites = @(
  @{ path = 'src\lib\utils\sequence-processor.ts'; class = 'cold' },
  @{ path = 'src\lib\actions\bulk-mail.ts';        class = 'cold' },
  @{ path = 'src\lib\actions\email-compose.ts';    class = 'direct' },
  @{ path = 'src\lib\actions\communications.ts';   class = 'direct' },
  @{ path = 'src\lib\actions\drafts.ts';           class = 'direct' }
)

foreach ($s in $sites) {
  $f = Join-Path $repo $s.path
  if (-not (Test-Path $f)) { Write-Output ("MISSING: " + $s.path); continue }
  $x = Read-Norm $f
  if ($x -match 'sendClass:') {
    Write-Output ("SKIP: " + $s.path + " already declares sendClass")
    continue
  }
  $old = 'await sendOutboundEmail({'
  if ($x -notlike "*$old*") { Write-Output ("ANCHOR MISS: " + $s.path); continue }
  $new = "await sendOutboundEmail({ sendClass: '" + $s.class + "',"
  $x = $x.Replace($old, $new)
  Write-Lf $f $x
  Write-Output ("PATCHED: " + $s.path + " -> sendClass '" + $s.class + "'")
}

Write-Output ''
Write-Output 'NEXT: npx tsc --noEmit   (run it on its own, NOT chained into git)'
