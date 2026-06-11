// src/lib/actions/compose-recipients.ts
//
// Server actions backing the compose recipient picker:
//   searchRecipientContacts -- type-ahead over app.contacts (name/email),
//                              with the company (party) name attached.
//   listOpenDealsForParty   -- open deals linked to a party via
//                              app.deal_parties (for the "Link to deal"
//                              selector; auto-selected when exactly one).
//
// Both follow the established flat-select + in-memory join pattern
// (no PostgREST multi-FK embeds; see the 42703 pipeline board fix).

'use server';

import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface RecipientContact {
  contactId: string;
  partyId: string;
  fullName: string;
  email: string;
  title: string | null;
  partyName: string;
}

export interface OpenDealOption {
  dealId: string;
  dealName: string;
  status: string;
}

const TERMINAL_DEAL_STATUSES = ['won', 'lost', 'archived'];

/**
 * Type-ahead contact search for the compose recipient picker.
 * Matches full_name OR email (ilike), only contacts that have an email.
 */
export async function searchRecipientContacts(
  query: string,
): Promise<{ ok: true; results: RecipientContact[] } | { ok: false; error: string }> {
  const q = (query ?? '').trim();
  if (q.length < 2) return { ok: true, results: [] };

  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }

  const supabase = await createSupabaseServerClient();
  const like = '%' + q.replace(/[%_]/g, '') + '%';

  const { data, error } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select('id, party_id, full_name, email, title_text')
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .not('email', 'is', null)
    .or(`full_name.ilike.${like},email.ilike.${like}`)
    .order('updated_at', { ascending: false })
    .limit(10);

  if (error) return { ok: false, error: error.message };

  const rows = (data ?? []) as Array<{
    id: string;
    party_id: string;
    full_name: string | null;
    email: string | null;
    title_text: string | null;
  }>;

  // in-memory join: party names
  const partyIds = Array.from(new Set(rows.map((r) => r.party_id).filter(Boolean)));
  const partyNameById = new Map<string, string>();
  if (partyIds.length > 0) {
    const { data: parties } = await supabase
      .schema('app')
      .from('parties' as never)
      .select('id, party_name')
      .in('id', partyIds);
    for (const p of (parties ?? []) as Array<{ id: string; party_name: string | null }>) {
      partyNameById.set(p.id, p.party_name ?? '');
    }
  }

  const results: RecipientContact[] = rows
    .filter((r) => !!r.email)
    .map((r) => ({
      contactId: r.id,
      partyId: r.party_id,
      fullName: r.full_name ?? r.email ?? '(no name)',
      email: r.email as string,
      title: r.title_text,
      partyName: partyNameById.get(r.party_id) ?? '',
    }));

  return { ok: true, results };
}

/**
 * Open (non-terminal, non-deleted) deals linked to a party via deal_parties.
 * Flat selects + in-memory join.
 */
export async function listOpenDealsForParty(
  partyId: string,
): Promise<{ ok: true; deals: OpenDealOption[] } | { ok: false; error: string }> {
  if (!partyId) return { ok: true, deals: [] };

  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }

  const supabase = await createSupabaseServerClient();

  const { data: links, error: linkErr } = await supabase
    .schema('app')
    .from('deal_parties' as never)
    .select('deal_id')
    .eq('organization_id', auth.organizationId)
    .eq('party_id', partyId);

  if (linkErr) return { ok: false, error: linkErr.message };

  const dealIds = Array.from(
    new Set(((links ?? []) as Array<{ deal_id: string }>).map((l) => l.deal_id)),
  );
  if (dealIds.length === 0) return { ok: true, deals: [] };

  const { data: deals, error: dealErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, deal_name, status')
    .in('id', dealIds)
    .is('deleted_at', null)
    .order('updated_at', { ascending: false });

  if (dealErr) return { ok: false, error: dealErr.message };

  const open = ((deals ?? []) as Array<{ id: string; deal_name: string; status: string }>)
    .filter((d) => !TERMINAL_DEAL_STATUSES.includes(d.status))
    .map((d) => ({ dealId: d.id, dealName: d.deal_name, status: d.status }));

  return { ok: true, deals: open };
}
