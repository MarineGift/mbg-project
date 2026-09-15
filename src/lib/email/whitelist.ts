/**
 * lib/email/whitelist.ts
 *
 * Check whether a sender's email address is registered in the organization's whitelist.
 *
 * Match priority:
 *   1. address - exact match
 *   2. domain - match the domain after @.
 *      A pattern starting with a dot is a SUFFIX match, so '.gov' accepts
 *      uscis.dhs.gov, nist.gov, mail.house.gov - every subdomain of the TLD.
 *      Without the dot the pattern still has to equal the domain exactly.
 *   3. regex - regular-expression match
 *
 * Only entries with is_active = true are checked.
 *
 * 2026-09-15: after the table, we also accept anyone already in the CRM - a
 * registered contact, a party's own address, or the domain of a party's
 * website. A cold reply from an investor we are actively courting was being
 * dropped at the gate (BASF Venture Capital), which is the opposite of what
 * the gate is for: it exists to keep strangers out, not counterparties.
 *
 * Used by:
 *   - on entry to persistInbound() in mailcarrier.ts
 *   - senders that are not allowed skip the communications INSERT
 */

import type { SupabaseClient } from '@supabase/supabase-js';

interface WhitelistRow {
  pattern: string;
  kind: 'domain' | 'address' | 'regex';
}

/**
 * Returns true if the sender address is registered in the whitelist.
 * Returns false even when the whitelist is empty (explicit-allow policy).
 */
export async function isFromAllowedSender(
  supabase: SupabaseClient,
  organizationId: string,
  fromAddress: string,
): Promise<boolean> {
  if (!fromAddress) return false;
  const normalized = fromAddress.trim().toLowerCase();
  const domain = normalized.includes('@')
    ? normalized.split('@').pop() ?? ''
    : '';

  const { data, error } = await supabase
    .schema('app')
    .from('email_whitelist')
    .select('pattern, kind')
    .eq('organization_id', organizationId)
    .eq('is_active', true);

  if (error) {
    // whitelist lookup failed - block conservatively
    // eslint-disable-next-line no-console
    console.error('[whitelist] lookup failed:', error);
    return false;
  }

  const rows = (data ?? []) as WhitelistRow[];

  for (const row of rows) {
    const pattern = row.pattern.trim().toLowerCase();
    switch (row.kind) {
      case 'address':
        if (normalized === pattern) return true;
        break;
      case 'domain':
        if (pattern.startsWith('.')) {
          // suffix rule: '.gov' -> any *.gov, and bare 'gov' itself
          if (domain === pattern.slice(1) || domain.endsWith(pattern)) return true;
        } else if (domain === pattern || normalized.endsWith(`@${pattern}`)) {
          return true;
        }
        break;
      case 'regex':
        try {
          const re = new RegExp(row.pattern, 'i');
          if (re.test(fromAddress)) return true;
        } catch {
          // invalid regex - ignore
        }
        break;
    }
  }

  // Nothing in the table matched. Fall back to the directory: mail from a
  // company or person we already track is never spam.
  return isKnownCounterpartSender(supabase, organizationId, normalized, domain);
}

/**
 * True when the sender is already in the CRM:
 *   1. contacts.email exact
 *   2. parties.email exact
 *   3. the domain of any contact's email
 *   4. the domain of a party's website (catches basf.com from BASF's record
 *      even when no BASF contact has been entered yet)
 *
 * Subdomains are handled by also testing the registrable domain, so
 * joshua@us.basf.com still matches a party whose website is basf.com.
 */
async function isKnownCounterpartSender(
  supabase: SupabaseClient,
  organizationId: string,
  normalized: string,
  domain: string,
): Promise<boolean> {
  if (!domain) return false;

  // public mailbox providers are never evidence of a relationship
  const PUBLIC_DOMAINS = new Set([
    'gmail.com', 'googlemail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
    'live.com', 'msn.com', 'icloud.com', 'me.com', 'aol.com', 'proton.me',
    'protonmail.com', 'naver.com', 'daum.net', 'hanmail.net', 'kakao.com',
    'qq.com', '163.com', '126.com',
  ]);

  const parts = domain.split('.');
  const registrable = parts.length > 2 ? parts.slice(-2).join('.') : domain;

  try {
    // [1] a contact we already know, by address or by their company domain
    const { data: contact } = await supabase
      .schema('app')
      .from('contacts')
      .select('id')
      .eq('organization_id', organizationId)
      .or(`email.eq.${normalized},email.ilike.*@${domain}`)
      .limit(1)
      .maybeSingle();
    if (contact) return true;

    if (PUBLIC_DOMAINS.has(domain) || PUBLIC_DOMAINS.has(registrable)) return false;

    // [2] the party's own address, or its website domain
    const { data: party } = await supabase
      .schema('app')
      .from('parties')
      .select('id')
      .eq('organization_id', organizationId)
      .is('deleted_at', null)
      .or(
        [
          `email.eq.${normalized}`,
          `email.ilike.*@${domain}`,
          `website.ilike.*${registrable}*`,
        ].join(','),
      )
      .limit(1)
      .maybeSingle();
    if (party) return true;
  } catch (e) {
    // a lookup failure must not silently open the gate
    // eslint-disable-next-line no-console
    console.error('[whitelist] counterpart lookup failed:', e);
    return false;
  }

  return false;
}
