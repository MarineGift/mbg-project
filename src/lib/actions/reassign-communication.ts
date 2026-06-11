// src/lib/actions/reassign-communication.ts
//
// Inbox: reassign a communication to a deal.
//
// Used when the auto-log trigger could not pick a deal (party had 0 or
// 2+ open deals), so the message landed on the company only. From the
// inbox detail header the user picks the right deal; this action:
//   1) validates the deal belongs to the communication's party
//      (via app.deal_parties), unless clearing (dealId = null).
//   2) updates communications.deal_id.
//   3) re-points the linked engagement's deal_id to match (the trigger
//      created exactly one engagement per message).
//   4) bumps deals.last_activity_at on the newly linked deal.
//
// Flat selects + in-memory checks (no multi-FK embeds).

'use server';

import { revalidatePath } from 'next/cache';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface ReassignResult {
  ok: boolean;
  error?: string;
}

export async function reassignCommunicationDeal(
  communicationId: string,
  dealId: string | null,
): Promise<ReassignResult> {
  if (!communicationId) return { ok: false, error: 'Missing communication' };

  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, error: 'Unauthorized' };
  }

  const supabase = await createSupabaseServerClient();

  // load the communication (party + current engagement link)
  const { data: commRaw, error: commErr } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('id, organization_id, party_id, engagement_id, occurred_at')
    .eq('id', communicationId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .maybeSingle();

  if (commErr) return { ok: false, error: commErr.message };
  if (!commRaw) return { ok: false, error: 'Communication not found' };
  const comm = commRaw as {
    id: string;
    organization_id: string;
    party_id: string | null;
    engagement_id: string | null;
    occurred_at: string;
  };

  // if assigning (not clearing), verify the deal is linked to this party
  if (dealId) {
    const { data: link, error: linkErr } = await supabase
      .schema('app')
      .from('deal_parties' as never)
      .select('deal_id')
      .eq('organization_id', auth.organizationId)
      .eq('deal_id', dealId)
      .eq('party_id', comm.party_id ?? '')
      .maybeSingle();

    if (linkErr) return { ok: false, error: linkErr.message };
    if (!link) {
      return { ok: false, error: 'That deal is not linked to this company.' };
    }
  }

  // 1) communication.deal_id
  const { error: upCommErr } = await supabase
    .schema('app')
    .from('communications' as never)
    .update({ deal_id: dealId } as never)
    .eq('id', comm.id)
    .eq('organization_id', auth.organizationId);
  if (upCommErr) return { ok: false, error: upCommErr.message };

  // 2) re-point the linked engagement (one per message)
  if (comm.engagement_id) {
    const { error: upEngErr } = await supabase
      .schema('app')
      .from('engagements' as never)
      .update({ deal_id: dealId } as never)
      .eq('id', comm.engagement_id)
      .eq('organization_id', auth.organizationId);
    if (upEngErr) return { ok: false, error: upEngErr.message };
  }

  // 3) deal activity heartbeat on the newly linked deal
  if (dealId) {
    await supabase
      .schema('app')
      .from('deals' as never)
      .update({ last_activity_at: comm.occurred_at } as never)
      .eq('id', dealId)
      .eq('organization_id', auth.organizationId);
  }

  revalidatePath(`/inbox/${communicationId}`);
  revalidatePath('/inbox');
  return { ok: true };
}
