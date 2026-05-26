// src/lib/queries/email-history.ts
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { rpc } from '@/lib/rpc/typed-rpc';

export interface EmailHistoryRow {
  send_id:            string;
  sent_at:            string | null;
  sequence_id:        string;
  sequence_name:      string;
  step_order:         number;
  enrollment_id:      string;
  party_id:           string | null;
  party_name:         string | null;
  contact_email:      string | null;
  contact_full_name:  string | null;
  send_status:        string;
  open_count:         number;
  first_opened_at:    string | null;
  click_count:        number;
  communication_id:   string | null;
}

export async function fetchEmailHistory(
  orgId:  string,
  limit:  number = 100,
  offset: number = 0,
): Promise<EmailHistoryRow[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await rpc(supabase, 'get_email_history', {
    p_organization_id: orgId,
    p_limit:  limit,
    p_offset: offset,
  });
  if (error) throw new Error(error.message);
  return (data ?? []) as unknown as EmailHistoryRow[];
}

export async function countEmailHistory(orgId: string): Promise<number> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await rpc(supabase, 'count_email_history', {
    p_organization_id: orgId,
  });
  if (error) throw new Error(error.message);
  return Number(data ?? 0);
}
