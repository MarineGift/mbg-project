/**
 * lib/queries/bulk-mail.ts
 *
 * Read-side candidate resolution for the bulk mailing system (Fork A:
 * batch loop over sendOutboundEmail -> TabsMailer.sendOne).
 *
 * Resolves recipients at the (party, contact) level so a party can expand to
 * one recipient (primary contact) or many (all contacts with an email).
 * Applies dedup + reports per-recipient whitelist status for the preview.
 *
 * Conventions (matches compose-recipients.ts):
 *   - flat selects + in-memory joins; NO PostgREST multi-FK embeds (42703).
 *   - explicit organization_id filter on every table that has the column.
 *
 * Dedup (party-level, excludes the whole party):
 *   - already_sent:        communications.template_id + party_id, status in
 *                          (sending|sent|delivered) -> permanent per-template.
 *   - recently_contacted:  ANY outbound email to the party in the last N days
 *                          (template-agnostic safety guard; opt-in).
 *
 * Suppression (per-recipient, by email address):
 *   - bounced:             the address previously bounced or was rejected for a
 *                          bad-recipient reason. Permanently dropped so invalid
 *                          addresses are not retried on every run. Transient
 *                          failures are NOT suppressed (stay retryable).
 */

import 'server-only';
import type { SbClient } from '@/lib/supabase/server';
import { loadActiveBlocklist, emailMatchesBlock } from '@/lib/email/blocklist';

export type BulkMailSource =
  | { mode: 'pipeline_stage'; stageId: string }
  | { mode: 'parties'; partyIds: string[] };

/** How many recipients each eligible party expands to. */
export type RecipientMode = 'primary' | 'all_contacts';

export interface BulkDedupOptions {
  /** Also exclude parties with ANY outbound email in the last N days.
   *  undefined / 0 => disabled. */
  recentDays?: number;
}

export type BulkExcludeReason =
  | 'already_sent'
  | 'no_contact_email'
  | 'recently_contacted'
  | 'bounced'
  | 'blocklisted';

export interface BulkMailCandidate {
  /** stable per-recipient key: `${partyId}:${contactId}` (or a party-level
   *  placeholder for excluded / no-email parties). Used for selection. */
  key: string;
  partyId: string;
  partyName: string;
  contactId: string | null;
  email: string | null;
  /** linkage so the send records communications.deal_id (engagement auto-log). */
  dealId: string | null;
  whitelisted: boolean;
  /** null => eligible to send; otherwise the reason it is excluded. */
  excludeReason: BulkExcludeReason | null;
}

export interface BulkMailPreview {
  templateId: string;
  recipientMode: RecipientMode;
  candidates: BulkMailCandidate[];
  toSend: BulkMailCandidate[];
  excluded: BulkMailCandidate[];
  counts: {
    /** distinct parties in the audience. */
    parties: number;
    /** eligible recipients (rows that will send). */
    toSend: number;
    /** parties excluded because they already received this template. */
    alreadySent: number;
    /** parties excluded by the recency guard. */
    recentlyContacted: number;
    /** parties excluded because no contact has an email. */
    noEmail: number;
    /** recipients excluded because the address previously bounced /
     *  was rejected for a bad-recipient reason (per-recipient, not per-party). */
    bounced: number;
    /** recipients excluded because the address is on the do-not-send
     *  (blocklist / unsubscribe) list. */
    blocklisted: number;
    /** subset of toSend whose recipient is NOT whitelisted (blocked unless
     *  the operator chooses bypassWhitelist). */
    notWhitelisted: number;
  };
}

/** Outbound rows in these states count as "contacted". failed/blocked are
 *  excluded so a failed attempt can be retried. */
const DEDUP_STATUSES = ['sending', 'sent', 'delivered'] as const;

const EMPTY_PREVIEW = (templateId: string, recipientMode: RecipientMode): BulkMailPreview => ({
  templateId,
  recipientMode,
  candidates: [],
  toSend: [],
  excluded: [],
  counts: { parties: 0, toSend: 0, alreadySent: 0, recentlyContacted: 0, noEmail: 0, bounced: 0, blocklisted: 0, notWhitelisted: 0 },
});

export async function resolveBulkCandidates(
  supabase: SbClient,
  orgId: string,
  templateId: string,
  source: BulkMailSource,
  recipientMode: RecipientMode = 'primary',
  dedup: BulkDedupOptions = {},
): Promise<BulkMailPreview> {
  // -- 1) resolve the party set (+ best-effort deal linkage) ----------------
  const dealIdByParty = new Map<string, string>();
  let partyIds: string[] = [];

  if (source.mode === 'pipeline_stage') {
    const { data: dealsRaw } = await supabase
      .schema('app')
      .from('deals' as never)
      .select('id, party_id')
      .eq('organization_id', orgId)
      .eq('current_stage_id', source.stageId)
      .is('deleted_at', null);
    const deals = (dealsRaw ?? []) as Array<{ id: string; party_id: string | null }>;
    for (const d of deals) {
      if (d.party_id && !dealIdByParty.has(d.party_id)) dealIdByParty.set(d.party_id, d.id);
    }
    const dealIds = deals.map((d) => d.id);
    if (dealIds.length > 0) {
      const { data: linksRaw } = await supabase
        .schema('app')
        .from('deal_parties' as never)
        .select('deal_id, party_id')
        .eq('organization_id', orgId)
        .in('deal_id', dealIds);
      for (const l of (linksRaw ?? []) as Array<{ deal_id: string; party_id: string }>) {
        if (l.party_id && !dealIdByParty.has(l.party_id)) dealIdByParty.set(l.party_id, l.deal_id);
      }
    }
    partyIds = Array.from(dealIdByParty.keys());
  } else {
    partyIds = Array.from(new Set(source.partyIds));
  }

  if (partyIds.length === 0) return EMPTY_PREVIEW(templateId, recipientMode);

  // -- 2) party names (drops deleted / out-of-org parties) ------------------
  const { data: partyRaw } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name')
    .eq('organization_id', orgId)
    .in('id', partyIds)
    .is('deleted_at', null);
  const nameById = new Map<string, string>();
  for (const p of (partyRaw ?? []) as Array<{ id: string; party_name: string | null }>) {
    nameById.set(p.id, p.party_name ?? '');
  }
  partyIds = partyIds.filter((id) => nameById.has(id));
  if (partyIds.length === 0) return EMPTY_PREVIEW(templateId, recipientMode);

  // -- 3) contacts with an email, grouped by party -------------------------
  const { data: contactRaw } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select('id, party_id, full_name, email, is_primary')
    .eq('organization_id', orgId)
    .in('party_id', partyIds)
    .is('deleted_at', null)
    .not('email', 'is', null);
  type Contact = { contactId: string; email: string; name: string; isPrimary: boolean };
  const contactsByParty = new Map<string, Contact[]>();
  for (const c of (contactRaw ?? []) as Array<{
    id: string; party_id: string; full_name: string | null; email: string | null; is_primary: boolean;
  }>) {
    if (!c.email) continue;
    const list = contactsByParty.get(c.party_id) ?? [];
    list.push({ contactId: c.id, email: c.email, name: c.full_name ?? c.email, isPrimary: c.is_primary });
    contactsByParty.set(c.party_id, list);
  }

  // -- 4) party-level dedup sets -------------------------------------------
  const { data: sentRaw } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('party_id')
    .eq('organization_id', orgId)
    .eq('channel', 'email')
    .eq('direction', 'outbound')
    .eq('template_id', templateId)
    .in('party_id', partyIds)
    .in('status', DEDUP_STATUSES as unknown as string[]);
  const alreadySent = new Set<string>();
  for (const r of (sentRaw ?? []) as Array<{ party_id: string | null }>) {
    if (r.party_id) alreadySent.add(r.party_id);
  }

  const recentlyContacted = new Set<string>();
  if (dedup.recentDays && dedup.recentDays > 0) {
    const cutoff = new Date(Date.now() - dedup.recentDays * 86_400_000).toISOString();
    const { data: recentRaw } = await supabase
      .schema('app')
      .from('communications' as never)
      .select('party_id')
      .eq('organization_id', orgId)
      .eq('channel', 'email')
      .eq('direction', 'outbound')
      .in('party_id', partyIds)
      .in('status', DEDUP_STATUSES as unknown as string[])
      .gte('sent_at', cutoff);
    for (const r of (recentRaw ?? []) as Array<{ party_id: string | null }>) {
      if (r.party_id) recentlyContacted.add(r.party_id);
    }
  }

  // -- 5) whitelist patterns (preview status only) --------------------------
  const { data: wlRaw } = await supabase
    .schema('app')
    .from('email_whitelist' as never)
    .select('pattern')
    .eq('organization_id', orgId)
    .eq('is_active', true);
  const wlPatterns = new Set<string>(
    ((wlRaw ?? []) as Array<{ pattern: string | null }>)
      .map((w) => (w.pattern ?? '').toLowerCase())
      .filter(Boolean),
  );
  const isWhitelisted = (email: string): boolean => {
    const e = email.toLowerCase();
    const domain = e.split('@')[1] ?? '';
    return wlPatterns.has(e) || (domain.length > 0 && wlPatterns.has(domain));
  };

  // -- 5b) suppressed addresses: previously bounced / rejected recipients ----
  // The operator was receiving repeated bounce-backs because failed addresses
  // were retried on every run. We now permanently drop any address that:
  //   - has a non-null bounced_at, OR
  //   - was recorded with status='bounced', OR
  //   - failed with an error_message/bounce_reason matching a bad-recipient
  //     signature (550/551/553, 5.1.x, 5.4.4, "no such user", "mailbox
  //     unavailable", "address rejected", etc.).
  // Transient failures (timeouts, connection errors, quiet-hours, greylisting)
  // do NOT match, so those recipients stay retryable. Keyed by email address
  // (lowercased) since a bad address is bad regardless of which contact/party
  // it is attached to. Org-scoped, outbound email only.
  const INVALID_RECIPIENT_RE =
    /(\b55[013]\b|\b5\.1\.[0-9]\b|\b5\.4\.4\b|no such (?:user|recipient|mailbox)|user unknown|unknown user|recipient (?:address )?(?:rejected|not found)|mailbox (?:unavailable|not found|is unavailable)|(?:address|recipient) rejected|does ?n(?:o|')t exist|invalid (?:recipient|mailbox|address)|account (?:does not exist|disabled|unavailable)|domain not found|host (?:or domain )?name not found|no mailbox here)/i;

  const { data: failRaw } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('to_addresses, status, error_message, bounce_reason, bounced_at')
    .eq('organization_id', orgId)
    .eq('channel', 'email')
    .eq('direction', 'outbound')
    .or('status.in.(failed,bounced),bounced_at.not.is.null');

  const suppressedEmails = new Set<string>();
  for (const r of (failRaw ?? []) as Array<{
    to_addresses: string[] | null;
    status: string | null;
    error_message: string | null;
    bounce_reason: string | null;
    bounced_at: string | null;
  }>) {
    const hardBounce =
      r.status === 'bounced' ||
      !!r.bounced_at ||
      (r.status === 'failed' &&
        INVALID_RECIPIENT_RE.test(`${r.error_message ?? ''} ${r.bounce_reason ?? ''}`));
    if (!hardBounce) continue;
    for (const addr of r.to_addresses ?? []) {
      if (addr) suppressedEmails.add(addr.toLowerCase());
    }
  }
  const isSuppressed = (email: string): boolean => suppressedEmails.has(email.toLowerCase());

  // -- 5c) do-not-send (blocklist / unsubscribe) patterns --------------------
  // Explicit operator/recipient-driven suppression. Takes priority over the
  // derived bounce set. Authoritative enforcement is in send-outbound (every
  // path); this is so the bulk preview reflects who will actually be dropped.
  const blocklistRows = await loadActiveBlocklist(supabase as unknown as Parameters<typeof loadActiveBlocklist>[0], orgId);
  const isBlocklisted = (email: string): boolean =>
    blocklistRows.length > 0 && emailMatchesBlock(email, blocklistRows);

  // -- 6) assemble per-recipient candidates ---------------------------------
  const candidates: BulkMailCandidate[] = [];
  let alreadySentParties = 0;
  let recentlyContactedParties = 0;
  let noEmailParties = 0;
  let bouncedRecipients = 0;
  let blocklistedRecipients = 0;

  for (const pid of partyIds) {
    const partyName = nameById.get(pid) ?? '';
    const dealId = dealIdByParty.get(pid) ?? null;

    // party-level exclusions collapse to a single summary row.
    if (alreadySent.has(pid)) {
      alreadySentParties += 1;
      candidates.push({ key: `${pid}:excluded`, partyId: pid, partyName, contactId: null, email: null, dealId, whitelisted: false, excludeReason: 'already_sent' });
      continue;
    }
    if (recentlyContacted.has(pid)) {
      recentlyContactedParties += 1;
      candidates.push({ key: `${pid}:excluded`, partyId: pid, partyName, contactId: null, email: null, dealId, whitelisted: false, excludeReason: 'recently_contacted' });
      continue;
    }

    const contacts = contactsByParty.get(pid) ?? [];
    if (contacts.length === 0) {
      noEmailParties += 1;
      candidates.push({ key: `${pid}:noemail`, partyId: pid, partyName, contactId: null, email: null, dealId, whitelisted: false, excludeReason: 'no_contact_email' });
      continue;
    }

    const chosen: Contact[] =
      recipientMode === 'all_contacts'
        ? contacts
        : [contacts.find((c) => c.isPrimary) ?? (contacts[0] as Contact)];

    for (const c of chosen) {
      const blocked = isBlocklisted(c.email);
      const suppressed = !blocked && isSuppressed(c.email);
      if (blocked) blocklistedRecipients += 1;
      else if (suppressed) bouncedRecipients += 1;
      candidates.push({
        key: `${pid}:${c.contactId}`,
        partyId: pid,
        partyName,
        contactId: c.contactId,
        email: c.email,
        dealId,
        whitelisted: isWhitelisted(c.email),
        excludeReason: blocked ? 'blocklisted' : suppressed ? 'bounced' : null,
      });
    }
  }

  const toSend = candidates.filter((c) => c.excludeReason === null);
  const excluded = candidates.filter((c) => c.excludeReason !== null);

  return {
    templateId,
    recipientMode,
    candidates,
    toSend,
    excluded,
    counts: {
      parties: partyIds.length,
      toSend: toSend.length,
      alreadySent: alreadySentParties,
      recentlyContacted: recentlyContactedParties,
      noEmail: noEmailParties,
      bounced: bouncedRecipients,
      blocklisted: blocklistedRecipients,
      notWhitelisted: toSend.filter((c) => !c.whitelisted).length,
    },
  };
}
