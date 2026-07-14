'use server';
/**
 * lib/actions/email-outcomes.ts
 *
 * Send-outcome log (/mailing/outcomes) read + manual entry.
 *
 * Table: app.email_send_outcomes (migration_20260714090000). Log table:
 * no created_by, organization_id copied from the party side. RLS policies
 * pol_email_send_outcomes_* scope rows to app.current_organization_id()
 * (added by migration_20260714120000_email_send_outcomes_page_access.sql).
 *
 * Enrollment sync on manual entry (2026-07-14 handoff rule):
 *   bounce_hard / send_failure / next_action=suppress -> active -> 'failed'
 *   rejected_* / unsubscribe_request                  -> active -> 'cancelled'
 */
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';

const PATH = '/mailing/outcomes';

import {
  NEXT_ACTIONS,
  OUTCOME_CODES,
  type AddOutcomeInput,
  type OutcomeRow,
} from '@/types/email-outcome';

type RawOutcome = Omit<OutcomeRow, 'party_name' | 'party_type'>;

/** Recent outcomes (max 500) with party name/type joined for links. */
export async function listOutcomes(): Promise<OutcomeRow[]> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return [];
  }
  const sb = await createSupabaseServerClient();

  const { data, error } = await sb
    .schema('app')
    .from('email_send_outcomes' as never)
    .select(
      'id, recipient_email, outcome, reason, next_action, resend_not_before, source, evidence_ref, created_at, party_id',
    )
    .eq('organization_id', auth.organizationId)
    .order('created_at', { ascending: false })
    .limit(500);
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[email-outcomes] list failed:', error.message);
    return [];
  }
  const rows = (data ?? []) as unknown as RawOutcome[];

  // second-step party join (robust even without FK metadata)
  const partyIds = [...new Set(rows.map((r) => r.party_id).filter(Boolean))] as string[];
  const partyMap = new Map<string, { party_name: string; party_type: string }>();
  if (partyIds.length > 0) {
    const { data: parties } = await sb
      .schema('app')
      .from('parties' as never)
      .select('id, party_name, party_type')
      .in('id', partyIds);
    for (const p of (parties ?? []) as unknown as Array<{
      id: string;
      party_name: string;
      party_type: string;
    }>) {
      partyMap.set(p.id, { party_name: p.party_name, party_type: p.party_type });
    }
  }

  return rows.map((r) => ({
    ...r,
    party_name: r.party_id ? partyMap.get(r.party_id)?.party_name ?? null : null,
    party_type: r.party_id ? partyMap.get(r.party_id)?.party_type ?? null : null,
  }));
}

export async function addOutcomeEntry(
  input: AddOutcomeInput,
): Promise<{ ok: boolean; error?: string }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }

  const email = (input.recipientEmail ?? '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { ok: false, error: 'Invalid email address' };
  }
  if (!OUTCOME_CODES.includes(input.outcome)) {
    return { ok: false, error: 'Invalid outcome' };
  }
  if (!NEXT_ACTIONS.includes(input.nextAction)) {
    return { ok: false, error: 'Invalid next action' };
  }
  let resendNotBefore: string | null = null;
  if (input.nextAction === 'resend_later') {
    if (!input.resendNotBefore) {
      return { ok: false, error: 'resend_later requires a resend-not-before date' };
    }
    const d = new Date(input.resendNotBefore);
    if (Number.isNaN(d.getTime())) return { ok: false, error: 'Invalid date' };
    resendNotBefore = d.toISOString();
  }

  const sb = await createSupabaseServerClient();

  // party lookup via contacts (primary or secondary email)
  const { data: contactsRaw } = await sb
    .schema('app')
    .from('contacts' as never)
    .select('id, party_id')
    .eq('organization_id', auth.organizationId)
    .or(`email.ilike."${email}",email_secondary.ilike."${email}"`);
  const contacts = (contactsRaw ?? []) as unknown as Array<{
    id: string;
    party_id: string | null;
  }>;
  const partyId = contacts.find((c) => c.party_id)?.party_id ?? null;

  const { error } = await sb
    .schema('app')
    .from('email_send_outcomes' as never)
    .insert({
      organization_id: auth.organizationId,
      party_id: partyId,
      recipient_email: email,
      outcome: input.outcome,
      reason: (input.reason ?? '').trim().slice(0, 300) || null,
      next_action: input.nextAction,
      resend_not_before: resendNotBefore,
      source: 'manual',
      evidence_ref: null,
    } as never);
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[email-outcomes] insert failed:', error.message);
    return { ok: false, error: error.message };
  }

  // enrollment sync (handoff rule)
  const toFailed =
    input.outcome === 'bounce_hard' ||
    input.outcome === 'send_failure' ||
    input.nextAction === 'suppress';
  const toCancelled =
    input.outcome.startsWith('rejected_') || input.outcome === 'unsubscribe_request';

  if ((toFailed || toCancelled) && contacts.length > 0) {
    const nowIso = new Date().toISOString();
    const patch = toFailed
      ? { status: 'failed', updated_at: nowIso }
      : { status: 'cancelled', cancelled_at: nowIso, updated_at: nowIso };
    const { error: enrErr } = await sb
      .schema('app')
      .from('email_sequence_enrollments' as never)
      .update(patch as never)
      .eq('organization_id', auth.organizationId)
      .eq('status', 'active')
      .in(
        'contact_id',
        contacts.map((c) => c.id),
      );
    if (enrErr) {
      // outcome row is already saved -> report but do not fail the action
      // eslint-disable-next-line no-console
      console.error('[email-outcomes] enrollment sync failed:', enrErr.message);
    }
  }

  revalidatePath(PATH);
  return { ok: true };
}
