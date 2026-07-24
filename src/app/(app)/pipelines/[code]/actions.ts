// src/app/(app)/pipelines/[code]/actions.ts
//
// Server Actions for the pipeline kanban:
//   moveDealStage  -- drag-and-drop stage updates
//   createDeal     -- "+ New deal" modal (deal + its companies)
//   searchParties  -- debounced counterparty lookup in the modal
//
// All actions use the RLS-scoped supabase server client; revalidatePath
// refreshes the kanban for the calling pipeline.
//
// Round dimension (2026-06-02): createDeal accepts optional round_id
//   (deals.round_id FK -> app.rounds). Investor modal only.
//
// Multi-company / Stage 1-C (2026-06-02): a deal has many companies via
//   app.deal_parties (M:N), each with role + commitment_amount. createDeal now
//   takes a `parties` array, inserts the deal, then bulk-inserts deal_parties.
//   If the deal_parties insert fails, the just-created deal is deleted so no
//   orphan deal is left behind (best-effort transaction without an RPC).

'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';

// ============================================================
// moveDealStage  (drag-and-drop)
// ============================================================

export async function moveDealStage(
  dealId: string,
  newStageId: string,
  pipelineCode: string
): Promise<{ ok: true } | { ok: false; error: string }> {
  if (!dealId || !newStageId || !pipelineCode) {
    return { ok: false, error: 'Missing required argument' };
  }

  const supabase = await createSupabaseServerClient();
  const nowIso = new Date().toISOString();

  const { error } = await supabase
    .schema('app')
    .from('deals' as never)
    .update({
      current_stage_id: newStageId,
      last_activity_at: nowIso,
    } as never)
    .eq('id', dealId);

  if (error) return { ok: false, error: error.message };

  revalidatePath('/pipelines/' + pipelineCode);
  return { ok: true };
}

// ============================================================
// createDeal  (New deal modal)
// ============================================================

const VALID_ROLES = ['lead', 'co_investor', 'participant', 'advisor', 'primary'] as const;
type DealPartyRole = (typeof VALID_ROLES)[number];

interface CreateDealPartyInput {
  partyId: string;
  role: DealPartyRole;
  commitmentAmount?: number | null;
  currency?: string;
}

interface CreateDealInput {
  pipelineCode: string;
  deal_name: string;
  current_stage_id: string;
  // The companies on this deal (M:N). At least one required.
  parties: CreateDealPartyInput[];
  // Optional fundraising round (Investor pipeline only). FK -> app.rounds.
  round_id?: string | null;
  // Optional campaign grouping (any pipeline). FK -> app.campaigns.
  campaign_id?: string | null;
}

export async function createDeal(
  input: CreateDealInput
): Promise<{ ok: true; dealId: string } | { ok: false; error: string }> {
  // Server-side validation (the modal mirrors this).
  const name = (input.deal_name ?? '').trim();
  if (!name) return { ok: false, error: 'Deal name is required' };
  if (!input.current_stage_id) return { ok: false, error: 'Stage is required' };
  if (!input.campaign_id) return { ok: false, error: 'Campaign is required' };
  if (!input.pipelineCode) return { ok: false, error: 'Pipeline is required' };

  const parties = (input.parties ?? []).filter((p) => p.partyId);
  if (parties.length === 0) {
    return { ok: false, error: 'At least one company is required' };
  }
  // de-dup by partyId (the unique index would reject dupes anyway)
  const seen = new Set<string>();
  for (const p of parties) {
    if (seen.has(p.partyId)) {
      return { ok: false, error: 'The same company is listed more than once' };
    }
    seen.add(p.partyId);
    if (!VALID_ROLES.includes(p.role)) {
      return { ok: false, error: 'Invalid role: ' + String(p.role) };
    }
    if (p.commitmentAmount != null && (!Number.isFinite(p.commitmentAmount) || p.commitmentAmount < 0)) {
      return { ok: false, error: 'Commitment must be a non-negative number' };
    }
  }

  const supabase = await createSupabaseServerClient();

  // Resolve pipeline -> id + organization_id (RLS scopes to the user's org).
  const { data: pipelineRow, error: pErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, organization_id')
    .eq('code', input.pipelineCode)
    .eq('is_active', true)
    .maybeSingle();

  if (pErr || !pipelineRow) {
    return { ok: false, error: 'Pipeline not found or inactive' };
  }
  const pipeline = pipelineRow as unknown as { id: string; organization_id: string };

  const nowIso = new Date().toISOString();

  // deals.party_id (legacy, NOT NULL) must hold exactly ONE company id, but all
  // companies on a deal are equal level (no hierarchy). The full set lives in
  // app.deal_parties (M:N). This single column just satisfies the NOT NULL
  // constraint, so we use the first listed company -- it carries no special
  // status; 'role' on each deal_parties row is just an attribute/condition value.
  const anchorPartyId = parties[0]!.partyId;

  // 1) insert the deal
  // round_id is Investor-only. Omit the key entirely when there's no round so
  // non-investor pipelines never reference deals.round_id (which may be absent
  // from the live table -> PostgREST "schema cache" 42703).
  const dealPayload: Record<string, unknown> = {
    organization_id: pipeline.organization_id,
    pipeline_id: pipeline.id,
    current_stage_id: input.current_stage_id,
    deal_name: name,
    party_id: anchorPartyId,
    last_activity_at: nowIso,
    source: 'manual',
    // status/priority/module_data fall back to their column defaults
  };
  if (input.round_id) {
    dealPayload.round_id = input.round_id;
  }
  if (input.campaign_id) {
    dealPayload.campaign_id = input.campaign_id;
  }

  const { data: dealRow, error: dealErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .insert(dealPayload as never)
    .select('id')
    .single();

  if (dealErr || !dealRow) {
    return { ok: false, error: dealErr?.message ?? 'Deal insert failed' };
  }
  const dealId = (dealRow as { id: string }).id;

  // 2) bulk-insert the companies (deal_parties)
  const rows = parties.map((p) => ({
    organization_id: pipeline.organization_id,
    deal_id: dealId,
    party_id: p.partyId,
    role: p.role,
    commitment_amount: p.commitmentAmount ?? null,
    currency: p.currency ?? 'USD',
  }));

  const { error: dpErr } = await supabase
    .schema('app')
    .from('deal_parties' as never)
    .insert(rows as never);

  if (dpErr) {
    // best-effort rollback: remove the orphan deal we just created
    await supabase.schema('app').from('deals' as never).delete().eq('id', dealId);
    return { ok: false, error: dpErr.message };
  }

  revalidatePath('/pipelines/' + input.pipelineCode);
  return { ok: true, dealId };
}

// ============================================================
// searchParties  (counterparty lookup in modal)
// ============================================================

export async function searchParties(query: string): Promise<
  Array<{ id: string; party_name: string; country_code: string | null }>
> {
  const supabase = await createSupabaseServerClient();
  const q = (query ?? '').trim();

  let req = supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name, country_code')
    .is('deleted_at', null)
    .order('party_name', { ascending: true })
    .limit(20);

  if (q) {
    req = req.ilike('party_name', '%' + q + '%');
  }

  const { data } = await req;
  return (data ?? []) as Array<{ id: string; party_name: string; country_code: string | null }>;
}
