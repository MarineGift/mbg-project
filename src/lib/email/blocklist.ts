/**
 * lib/email/blocklist.ts
 *
 * Do-not-send (suppression / unsubscribe) matching. Mirrors the whitelist
 * match logic (address / domain / regex) but with DENY semantics: if a
 * recipient matches an active blocklist entry, the send is blocked.
 *
 * Reuses app.email_blocklist, which shares the email_whitelist shape
 * (pattern + kind + is_active). Unlike the whitelist (an allow-gate that
 * skipWhitelist can bypass), the blocklist is enforced unconditionally in
 * send-outbound, before the whitelist.
 *
 * No 'server-only' guard on purpose: send-outbound is imported by both
 * server actions (request context) and the background workers (service-role
 * context), so this helper must be importable from both.
 */

import type { SupabaseClient } from '@supabase/supabase-js';

export interface BlocklistRow {
  pattern: string;
  kind: 'domain' | 'address' | 'regex';
}

/**
 * Pure matcher: true if `email` matches ANY of the given active rows.
 * Address = exact (case-insensitive); domain = part after @; regex = /pattern/i.
 */
export function emailMatchesBlock(email: string, rows: BlocklistRow[]): boolean {
  const normalized = (email ?? '').trim().toLowerCase();
  if (!normalized) return false;
  const domain = normalized.includes('@') ? (normalized.split('@').pop() ?? '') : '';

  for (const row of rows) {
    const pattern = (row.pattern ?? '').trim().toLowerCase();
    if (!pattern) continue;
    switch (row.kind) {
      case 'address':
        if (normalized === pattern) return true;
        break;
      case 'domain':
        if (domain === pattern || normalized.endsWith(`@${pattern}`)) return true;
        break;
      case 'regex':
        try {
          if (new RegExp(row.pattern, 'i').test(email)) return true;
        } catch {
          // invalid regex -> ignore this row
        }
        break;
    }
  }
  return false;
}

/** Load the org's active blocklist rows. Returns [] on error (caller decides
 *  fail-open vs fail-closed). */
export async function loadActiveBlocklist(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<BlocklistRow[]> {
  const { data, error } = await supabase
    .schema('app')
    .from('email_blocklist' as never)
    .select('pattern, kind')
    .eq('organization_id', organizationId)
    .eq('is_active', true);
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[blocklist] lookup failed:', error);
    return [];
  }
  return (data ?? []) as BlocklistRow[];
}
