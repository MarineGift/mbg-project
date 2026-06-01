/**
 * lib/email/whitelist.ts
 *
 * Check whether a sender's email address is registered in the organization's whitelist.
 *
 * Match priority:
 *   1. address - exact match
 *   2. domain - match the domain after @
 *   3. regex - regular-expression match
 *
 * Only entries with is_active = true are checked.
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
        if (domain === pattern || normalized.endsWith(`@${pattern}`)) return true;
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

  return false;
}
