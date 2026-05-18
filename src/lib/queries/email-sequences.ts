// src/lib/queries/email-sequences.ts
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type {
  EmailSequence,
  EmailSequenceWithSteps,
  PartyEnrollmentSummary,
} from '@/types/phase21b';

/** Settings 페이지: 조직의 시퀀스 목록 */
export async function fetchSequences(orgId: string): Promise<EmailSequence[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc('list_sequences', {
    p_org_id: orgId,
  });
  if (error) throw new Error(`fetchSequences: ${error.message}`);
  return (data ?? []) as EmailSequence[];
}

/** 시퀀스 단건 + steps 전체 */
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

/** Party 상세 페이지: 해당 파티의 등록 목록 */
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
