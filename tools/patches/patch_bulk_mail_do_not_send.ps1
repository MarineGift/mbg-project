# =====================================================================
# patch_bulk_mail_do_not_send.ps1
# Purpose: wire app.v_email_do_not_send into the bulk-mail (/mailing UI)
#          candidate resolver. Until now that path only consulted
#          email_blocklist + the derived bounce set, so a party that had
#          already submitted an application form or replied/rejected
#          could still be cold-mailed from the bulk screen.
#          The sequence worker path already guards on this view.
#
# Facts (confirmed 2026-07-14 via information_schema):
#   app.v_email_do_not_send(email_lower text, party_id uuid,
#                           last_event_at timestamptz, outcomes text,
#                           is_follow_up boolean)
#   -> NO organization_id column, so NO .eq('organization_id', ...) here.
#
# Idempotent: exits early if the file already mentions do_not_send.
# =====================================================================

$ErrorActionPreference = 'Stop'
$path = 'C:\dev\mbg-project\src\lib\queries\bulk-mail.ts'

if (-not (Test-Path $path)) {
  Write-Output "ERROR: file not found - $path"
  return
}

$t = [System.IO.File]::ReadAllText($path)
$t = $t -replace "`r`n", "`n"

if ($t -match 'do_not_send') {
  Write-Output 'SKIP: bulk-mail.ts already patched (do_not_send present)'
  return
}

$n = 0

# --- 1) exclude reason union ------------------------------------------
$old1 = @'
  | 'bounced'
  | 'blocklisted';
'@
$new1 = @'
  | 'bounced'
  | 'blocklisted'
  | 'do_not_send';
'@
if ($t.Contains($old1)) { $t = $t.Replace($old1, $new1); $n++ } else { Write-Output 'MISS 1: exclude reason union' }

# --- 2) counts interface ----------------------------------------------
$old2 = @'
    blocklisted: number;
    /** subset of toSend whose recipient is NOT whitelisted
'@
$new2 = @'
    blocklisted: number;
    /** recipients/parties excluded by app.v_email_do_not_send: the address
     *  or party already submitted an application form, replied, rejected,
     *  or unsubscribed. */
    doNotSend: number;
    /** subset of toSend whose recipient is NOT whitelisted
'@
if ($t.Contains($old2)) { $t = $t.Replace($old2, $new2); $n++ } else { Write-Output 'MISS 2: counts interface' }

# --- 3) EMPTY_PREVIEW counts ------------------------------------------
$old3 = @'
  counts: { parties: 0, toSend: 0, alreadySent: 0, recentlyContacted: 0, noEmail: 0, bounced: 0, blocklisted: 0, notWhitelisted: 0 },
'@
$new3 = @'
  counts: { parties: 0, toSend: 0, alreadySent: 0, recentlyContacted: 0, noEmail: 0, bounced: 0, blocklisted: 0, doNotSend: 0, notWhitelisted: 0 },
'@
if ($t.Contains($old3)) { $t = $t.Replace($old3, $new3); $n++ } else { Write-Output 'MISS 3: EMPTY_PREVIEW' }

# --- 4) new 5d section: load the view ---------------------------------
$old4 = @'
  const isBlocklisted = (email: string): boolean =>
    blocklistRows.length > 0 && emailMatchesBlock(email, blocklistRows);
'@
$new4 = @'
  const isBlocklisted = (email: string): boolean =>
    blocklistRows.length > 0 && emailMatchesBlock(email, blocklistRows);

  // -- 5d) do-not-send view: form submissions + replies/rejections ----------
  // app.v_email_do_not_send aggregates outcome events (reply_*, rejected_*,
  // unsubscribe, bounce) AND application_forms rows in status
  // submitted/decided. The sequence worker guards on this view already; the
  // bulk path did not, so a party that submitted a web form or already
  // replied could still be cold-mailed from /mailing.
  // The view has NO organization_id column. It is keyed by email_lower and
  // party_id, and we only ever intersect it against this org's own candidate
  // set (partyIds / contact emails already org-filtered above), so there is
  // no cross-org leakage. party_id matters because a form submission may
  // carry no email address at all -- that party must still be excluded.
  const { data: dnsRaw } = await supabase
    .schema('app')
    .from('v_email_do_not_send' as never)
    .select('email_lower, party_id');
  const dnsEmails = new Set<string>();
  const dnsParties = new Set<string>();
  for (const r of (dnsRaw ?? []) as Array<{ email_lower: string | null; party_id: string | null }>) {
    if (r.email_lower) dnsEmails.add(r.email_lower.toLowerCase());
    if (r.party_id) dnsParties.add(r.party_id);
  }
  const isDoNotSend = (email: string): boolean => dnsEmails.has(email.toLowerCase());
'@
if ($t.Contains($old4)) { $t = $t.Replace($old4, $new4); $n++ } else { Write-Output 'MISS 4: 5d section anchor' }

# --- 5) counters -------------------------------------------------------
$old5 = @'
  let bouncedRecipients = 0;
  let blocklistedRecipients = 0;
'@
$new5 = @'
  let bouncedRecipients = 0;
  let blocklistedRecipients = 0;
  let doNotSendCount = 0;
'@
if ($t.Contains($old5)) { $t = $t.Replace($old5, $new5); $n++ } else { Write-Output 'MISS 5: counters' }

# --- 6) party-level do-not-send check ---------------------------------
$old6 = @'
    if (recentlyContacted.has(pid)) {
      recentlyContactedParties += 1;
      candidates.push({ key: `${pid}:excluded`, partyId: pid, partyName, contactId: null, email: null, dealId, whitelisted: false, excludeReason: 'recently_contacted' });
      continue;
    }
'@
$new6 = @'
    if (recentlyContacted.has(pid)) {
      recentlyContactedParties += 1;
      candidates.push({ key: `${pid}:excluded`, partyId: pid, partyName, contactId: null, email: null, dealId, whitelisted: false, excludeReason: 'recently_contacted' });
      continue;
    }
    // party-level: form submitted / replied / rejected with no usable email.
    if (dnsParties.has(pid)) {
      doNotSendCount += 1;
      candidates.push({ key: `${pid}:excluded`, partyId: pid, partyName, contactId: null, email: null, dealId, whitelisted: false, excludeReason: 'do_not_send' });
      continue;
    }
'@
if ($t.Contains($old6)) { $t = $t.Replace($old6, $new6); $n++ } else { Write-Output 'MISS 6: party-level check' }

# --- 7) per-recipient precedence --------------------------------------
$old7 = @'
      const blocked = isBlocklisted(c.email);
      const suppressed = !blocked && isSuppressed(c.email);
      if (blocked) blocklistedRecipients += 1;
      else if (suppressed) bouncedRecipients += 1;
'@
$new7 = @'
      // precedence: explicit blocklist > do-not-send view > derived bounce.
      const blocked = isBlocklisted(c.email);
      const doNotSend = !blocked && isDoNotSend(c.email);
      const suppressed = !blocked && !doNotSend && isSuppressed(c.email);
      if (blocked) blocklistedRecipients += 1;
      else if (doNotSend) doNotSendCount += 1;
      else if (suppressed) bouncedRecipients += 1;
'@
if ($t.Contains($old7)) { $t = $t.Replace($old7, $new7); $n++ } else { Write-Output 'MISS 7: per-recipient precedence' }

# --- 8) excludeReason ternary -----------------------------------------
$old8 = @'
        excludeReason: blocked ? 'blocklisted' : suppressed ? 'bounced' : null,
'@
$new8 = @'
        excludeReason: blocked ? 'blocklisted' : doNotSend ? 'do_not_send' : suppressed ? 'bounced' : null,
'@
if ($t.Contains($old8)) { $t = $t.Replace($old8, $new8); $n++ } else { Write-Output 'MISS 8: excludeReason ternary' }

# --- 9) returned counts ------------------------------------------------
$old9 = @'
      blocklisted: blocklistedRecipients,
      notWhitelisted:
'@
$new9 = @'
      blocklisted: blocklistedRecipients,
      doNotSend: doNotSendCount,
      notWhitelisted:
'@
if ($t.Contains($old9)) { $t = $t.Replace($old9, $new9); $n++ } else { Write-Output 'MISS 9: returned counts' }

if ($n -eq 9) {
  [System.IO.File]::WriteAllText($path, $t)
  Write-Output "OK: bulk-mail.ts patched ($n/9 replacements)"
  Write-Output 'NEXT: npx tsc --noEmit   (then commit + push)'
} else {
  Write-Output "ABORT: only $n/9 anchors matched - file NOT written. Review MISS lines above."
}
