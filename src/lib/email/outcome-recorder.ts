/**
 * lib/email/outcome-recorder.ts
 *
 * Writes NDR results (from lib/email/ndr-outcome.ts) into
 * app.email_send_outcomes and syncs sequence enrollments.
 *
 * Rules (2026-07-14 handoff):
 *   - hard bounce -> outcome 'bounce_hard', next_action 'suppress' (default),
 *     and every ACTIVE enrollment of that address is set to 'failed'.
 *   - soft bounce -> outcome 'bounce_soft', next_action 'resend_later' with
 *     resend_not_before = now + 3 days. Enrollments stay untouched
 *     (the sequence worker may retry after the cooldown).
 *   - duplicate guard: same lower(recipient_email) + evidence_ref -> skip.
 *
 * No 'server-only' guard on purpose: called by the MailCarrier worker with a
 * service-role client (bypasses RLS). Best-effort: any single failure logs
 * and moves on, so inbound ingestion is never broken.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import type { NdrOutcome } from './ndr-outcome';

const SOFT_COOLDOWN_DAYS = 3;

interface ContactHit {
  id: string;
  party_id: string | null;
}

/** contacts lookup by email (primary OR secondary, case-insensitive). */
async function findContactsByEmail(
  supabase: SupabaseClient,
  organizationId: string,
  email: string,
): Promise<ContactHit[]> {
  const { data, error } = await supabase
    .schema('app')
    .from('contacts' as never)
    .select('id, party_id')
    .eq('organization_id', organizationId)
    .or(`email.ilike."${email}",email_secondary.ilike."${email}"`);
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[outcome-recorder] contacts lookup failed:', error.message);
    return [];
  }
  return (data ?? []) as unknown as ContactHit[];
}

/** true when (recipient_email, evidence_ref) already logged. */
async function alreadyRecorded(
  supabase: SupabaseClient,
  organizationId: string,
  email: string,
  evidenceRef: string,
): Promise<boolean> {
  const { data, error } = await supabase
    .schema('app')
    .from('email_send_outcomes' as never)
    .select('id')
    .eq('organization_id', organizationId)
    .eq('evidence_ref', evidenceRef)
    .ilike('recipient_email', email)
    .limit(1);
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[outcome-recorder] dedup check failed:', error.message);
    return false; // fail-open: worst case is one duplicate log row
  }
  return (data ?? []).length > 0;
}

/** set every ACTIVE enrollment of the given contacts to 'failed'. */
async function failActiveEnrollments(
  supabase: SupabaseClient,
  organizationId: string,
  contactIds: string[],
): Promise<number> {
  if (contactIds.length === 0) return 0;
  const { data, error } = await supabase
    .schema('app')
    .from('email_sequence_enrollments' as never)
    .update({
      status: 'failed',
      updated_at: new Date().toISOString(),
    } as never)
    .eq('organization_id', organizationId)
    .eq('status', 'active')
    .in('contact_id', contactIds)
    .select('id');
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[outcome-recorder] enrollment fail-sync error:', error.message);
    return 0;
  }
  return (data ?? []).length;
}

/**
 * Record one NdrOutcome (possibly multiple recipients) into
 * app.email_send_outcomes. Returns the number of rows inserted.
 */
export async function recordNdrOutcomes(
  supabase: SupabaseClient,
  organizationId: string,
  ndr: NdrOutcome,
  evidenceRef: string,
): Promise<number> {
  let inserted = 0;
  const isHard = ndr.severity === 'hard';
  const outcome = isHard ? 'bounce_hard' : 'bounce_soft';
  const resendNotBefore = isHard
    ? null
    : new Date(Date.now() + SOFT_COOLDOWN_DAYS * 86_400_000).toISOString();

  for (const raw of ndr.recipients) {
    const email = raw.trim().toLowerCase();
    if (!email.includes('@')) continue;

    try {
      if (await alreadyRecorded(supabase, organizationId, email, evidenceRef)) {
        continue;
      }

      const contacts = await findContactsByEmail(supabase, organizationId, email);
      const partyId = contacts.find((c) => c.party_id)?.party_id ?? null;

      const reason = [
        `SMTP ${ndr.smtpCode ?? 'n/a'}`,
        ndr.evidence ? `- ${ndr.evidence}` : '',
      ]
        .join(' ')
        .trim()
        .slice(0, 300);

      const { error } = await supabase
        .schema('app')
        .from('email_send_outcomes' as never)
        .insert({
          organization_id: organizationId,
          party_id: partyId,
          recipient_email: email,
          outcome,
          reason,
          next_action: isHard ? 'suppress' : 'resend_later',
          resend_not_before: resendNotBefore,
          source: 'mailcarrier',
          evidence_ref: evidenceRef,
        } as never);
      if (error) {
        // unique-violation = concurrent duplicate -> fine; otherwise log
        if (!/duplicate|unique|23505/i.test(error.message)) {
          // eslint-disable-next-line no-console
          console.error('[outcome-recorder] insert failed:', error.message);
        }
        continue;
      }
      inserted += 1;

      // hard bounce -> enrollment sync (same as batch1 Part 3 logic)
      if (isHard) {
        const failed = await failActiveEnrollments(
          supabase,
          organizationId,
          contacts.map((c) => c.id),
        );
        if (failed > 0) {
          // eslint-disable-next-line no-console
          console.log(
            `[outcome-recorder] ${email}: ${failed} active enrollment(s) -> failed`,
          );
        }
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('[outcome-recorder] unexpected error for', email, err);
    }
  }
  return inserted;
}
