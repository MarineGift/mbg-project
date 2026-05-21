// src/lib/queries/email-sequences.ts
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type {
  EmailSequence,
  EmailSequenceWithSteps,
  PartyEnrollmentSummary,
} from '@/types/phase21b';

/** Settings ?˜ì´ì§€: ì¡°ì§???œí€€??ëª©ë¡ */
export async function fetchSequences(orgId: string): Promise<EmailSequence[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc('list_sequences', {
    p_organization_id: orgId,
  });
  if (error) throw new Error(`fetchSequences: ${error.message}`);
  return (data ?? []) as EmailSequence[];
}

/** ?œí€€???¨ê±´ + steps ?„ì²´ */
export async function fetchSequenceWithSteps(
  sequenceId: string,
): Promise<EmailSequenceWithSteps | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc('get_sequence_with_steps', {
    p_sequence_id: sequenceId,
  });
  if (error) throw new Error(`fetchSequenceWithSteps: ${error.message}`);
  return (data as EmailSequenceWithSteps) ?? null;
}

/** Party ?ì„¸ ?˜ì´ì§€: ?´ë‹¹ ?Œí‹°???±ë¡ ëª©ë¡ */
export async function fetchPartyEnrollments(
  partyId: string,
): Promise<PartyEnrollmentSummary[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc('get_party_enrollments', {
    p_party_id: partyId,
  });
  if (error) throw new Error(`fetchPartyEnrollments: ${error.message}`);
  return (data ?? []) as PartyEnrollmentSummary[];
}
