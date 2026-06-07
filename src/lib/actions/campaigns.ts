/**
 * lib/actions/campaigns.ts
 *
 * Server Actions for campaigns (app.campaigns). organization_id on the campaign
 * row is filled by the column default app.current_organization_id() (see 03
 * migration), so it is intentionally NOT set on the campaign INSERT.
 *
 * Campaign create now optionally seeds DEALS: given a pipelineCode + partyIds,
 * each selected company becomes a deal placed at the pipeline's FIRST stage
 * (min sort_order, is_active), tagged to the new campaign, with a deal_parties
 * row. Deals/deal_parties DO set organization_id (from the pipeline) to match
 * createDeal in pipelines/[code]/actions.ts.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface CampaignActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'not_found' | 'database' | 'unknown';
  errorMessage?: string;
}

const createSchema = z.object({
  name: z.string().min(1, 'Required').max(120),
  campaignType: z.string().max(60).optional().nullable(),
  description: z.string().max(5000).optional().nullable(),
  status: z.enum(['active', 'closed', 'archived']).default('active'),
  startDate: z.string().optional().nullable(),
  endDate: z.string().optional().nullable(),
  color: z.string().max(20).optional().nullable(),
  // NEW: optional seeding of deals from selected companies.
  pipelineCode: z.string().max(60).optional().nullable(),
  partyIds: z.array(z.string().uuid()).optional().default([]),
});

export async function createCampaign(
  input: z.input<typeof createSchema>,
): Promise<CampaignActionResult & { campaignId?: string; dealsCreated?: number }> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = createSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }

  const supabase = await createSupabaseServerClient();

  // 1) create the campaign (organization_id via column default)
  const { data, error } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .insert({
      name: parsed.data.name.trim(),
      campaign_type: parsed.data.campaignType?.trim() || null,
      description: parsed.data.description?.trim() || null,
      status: parsed.data.status,
      start_date: parsed.data.startDate || null,
      end_date: parsed.data.endDate || null,
      color: parsed.data.color || null,
    } as never)
    .select('id')
    .single();

  if (error || !data) {
    return { ok: false, errorCode: 'database', errorMessage: error?.message ?? 'Insert failed' };
  }
  const campaignId = (data as { id: string }).id;

  // 2) optionally seed deals at the pipeline's FIRST stage
  let dealsCreated = 0;
  const partyIds = Array.from(new Set(parsed.data.partyIds ?? []));
  if (parsed.data.pipelineCode && partyIds.length > 0) {
    const seedRes = await seedCampaignDeals({
      supabase,
      campaignId,
      campaignName: parsed.data.name.trim(),
      pipelineCode: parsed.data.pipelineCode,
      partyIds,
    });
    if (!seedRes.ok) {
      // Campaign exists; surface the deal-seeding problem without failing the campaign.
      revalidatePath('/campaigns');
      return { ok: true, campaignId, dealsCreated: 0, errorCode: 'database', errorMessage: seedRes.error };
    }
    dealsCreated = seedRes.created;
  }

  revalidatePath('/campaigns');
  return { ok: true, campaignId, dealsCreated };
}

// Shared helper: create one deal per party at the pipeline's first stage,
// tagged to the campaign, plus the deal_parties row. Skips parties that
// already have a (non-deleted) deal in this campaign.
async function seedCampaignDeals(args: {
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>;
  campaignId: string;
  campaignName: string;
  pipelineCode: string;
  partyIds: string[];
}): Promise<{ ok: true; created: number } | { ok: false; error: string }> {
  const { supabase, campaignId, campaignName, pipelineCode, partyIds } = args;

  // pipeline -> id + organization_id (RLS scopes to org)
  const { data: pipeRow, error: pipeErr } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, organization_id')
    .eq('code', pipelineCode)
    .eq('is_active', true)
    .maybeSingle();
  if (pipeErr || !pipeRow) return { ok: false, error: 'Pipeline not found' };
  const pipeline = pipeRow as unknown as { id: string; organization_id: string };

  // first stage = lowest sort_order active stage
  const { data: stageRow, error: stageErr } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id')
    .eq('pipeline_id', pipeline.id)
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .limit(1)
    .maybeSingle();
  if (stageErr || !stageRow) return { ok: false, error: 'Pipeline has no stages' };
  const firstStageId = (stageRow as { id: string }).id;

  // party names for deal_name
  const { data: partyRows } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name')
    .in('id', partyIds);
  const nameById = new Map(
    ((partyRows ?? []) as Array<{ id: string; party_name: string }>).map((p) => [p.id, p.party_name]),
  );

  // skip parties already in this campaign (idempotent)
  const { data: existingRows } = await supabase
    .schema('app')
    .from('deals' as never)
    .select('party_id')
    .eq('campaign_id', campaignId)
    .is('deleted_at', null);
  const existing = new Set(
    ((existingRows ?? []) as Array<{ party_id: string }>).map((d) => d.party_id),
  );

  const nowIso = new Date().toISOString();
  const toCreate = partyIds.filter((pid) => !existing.has(pid));
  if (toCreate.length === 0) return { ok: true, created: 0 };

  const dealRows = toCreate.map((pid) => ({
    organization_id: pipeline.organization_id,
    pipeline_id: pipeline.id,
    current_stage_id: firstStageId,
    deal_name: `${nameById.get(pid) ?? 'Deal'} - ${campaignName}`,
    party_id: pid,
    last_activity_at: nowIso,
    source: 'manual',
    campaign_id: campaignId,
  }));

  const { data: inserted, error: dealErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .insert(dealRows as never)
    .select('id, party_id');
  if (dealErr || !inserted) return { ok: false, error: dealErr?.message ?? 'Deal insert failed' };

  const dpRows = (inserted as Array<{ id: string; party_id: string }>).map((d) => ({
    organization_id: pipeline.organization_id,
    deal_id: d.id,
    party_id: d.party_id,
    role: 'primary',
    currency: 'USD',
  }));
  const { error: dpErr } = await supabase
    .schema('app')
    .from('deal_parties' as never)
    .insert(dpRows as never);
  if (dpErr) {
    // roll back the just-created deals so we don't leave deals without companies
    await supabase.schema('app').from('deals' as never).delete()
      .in('id', (inserted as Array<{ id: string }>).map((d) => d.id));
    return { ok: false, error: dpErr.message };
  }

  return { ok: true, created: (inserted as unknown[]).length };
}

const updateSchema = z.object({
  campaignId: z.string().uuid(),
  name: z.string().min(1).max(120),
  campaignType: z.string().max(60).optional().nullable(),
  description: z.string().max(5000).optional().nullable(),
  status: z.enum(['active', 'closed', 'archived']),
  startDate: z.string().optional().nullable(),
  endDate: z.string().optional().nullable(),
  color: z.string().max(20).optional().nullable(),
});

export async function updateCampaign(
  input: z.input<typeof updateSchema>,
): Promise<CampaignActionResult> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = updateSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .update({
      name: parsed.data.name.trim(),
      campaign_type: parsed.data.campaignType?.trim() || null,
      description: parsed.data.description?.trim() || null,
      status: parsed.data.status,
      start_date: parsed.data.startDate || null,
      end_date: parsed.data.endDate || null,
      color: parsed.data.color || null,
    } as never)
    .eq('id', parsed.data.campaignId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };
  revalidatePath('/campaigns');
  return { ok: true };
}

export async function deleteCampaign(input: { campaignId: string }): Promise<CampaignActionResult> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = z.object({ campaignId: z.string().uuid() }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .delete()
    .eq('id', parsed.data.campaignId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };
  revalidatePath('/campaigns');
  return { ok: true };
}

// Company picker search for the campaign create dialog. Returns up to `limit`
// non-deleted parties matching the query (any party type). Avoids loading the
// full parties table (which can exceed the PostgREST row cap).
export async function searchPartiesForCampaign(
  input: { query?: string; limit?: number },
): Promise<{ ok: boolean; parties: Array<{ id: string; party_name: string; country_code: string | null; party_type_id: number | null }> }> {
  try { await requireAuth(); } catch { return { ok: false, parties: [] }; }

  const supabase = await createSupabaseServerClient();
  const q = (input.query ?? '').trim();
  let builder = supabase
    .schema('app')
    .from('parties' as never)
    .select('id, party_name, country_code, party_type_id')
    .is('deleted_at', null);
  if (q) builder = builder.ilike('party_name', `%${q}%`);

  const { data, error } = await builder
    .order('party_name', { ascending: true })
    .limit(input.limit ?? 50);

  if (error) return { ok: false, parties: [] };
  return {
    ok: true,
    parties: (data ?? []) as Array<{ id: string; party_name: string; country_code: string | null; party_type_id: number | null }>,
  };
}

// ---------------------------------------------------------------------------
// Campaign-screen Deal Party CRUD
// ---------------------------------------------------------------------------

// Add companies to an existing campaign as deals at the pipeline's first stage.
export async function addCampaignDeals(
  input: { campaignId: string; pipelineCode: string; partyIds: string[] },
): Promise<CampaignActionResult & { created?: number }> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = z.object({
    campaignId: z.string().uuid(),
    pipelineCode: z.string().min(1),
    partyIds: z.array(z.string().uuid()).min(1),
  }).safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }

  const supabase = await createSupabaseServerClient();

  const { data: campRow, error: campErr } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .select('id, name')
    .eq('id', parsed.data.campaignId)
    .maybeSingle();
  if (campErr || !campRow) return { ok: false, errorCode: 'not_found' };
  const camp = campRow as unknown as { id: string; name: string };

  const seed = await seedCampaignDeals({
    supabase,
    campaignId: camp.id,
    campaignName: camp.name,
    pipelineCode: parsed.data.pipelineCode,
    partyIds: Array.from(new Set(parsed.data.partyIds)),
  });
  if (!seed.ok) return { ok: false, errorCode: 'database', errorMessage: seed.error };

  revalidatePath('/campaigns');
  revalidatePath(`/campaigns/${camp.id}`);
  return { ok: true, created: seed.created };
}

// Remove a deal from a campaign by deleting the deal (deal_parties cascade).
export async function removeCampaignDeal(
  input: { dealId: string },
): Promise<CampaignActionResult> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = z.object({ dealId: z.string().uuid() }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .delete()
    .eq('id', parsed.data.dealId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };
  revalidatePath('/campaigns');
  return { ok: true };
}

// Move a deal to another stage (within its pipeline) from the campaign screen.
export async function setDealStage(
  input: { dealId: string; stageId: string },
): Promise<CampaignActionResult> {
  try { await requireAuth(); } catch { return { ok: false, errorCode: 'unauthorized' }; }

  const parsed = z.object({
    dealId: z.string().uuid(),
    stageId: z.string().uuid(),
  }).safeParse(input);
  if (!parsed.success) return { ok: false, errorCode: 'validation' };

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .update({ current_stage_id: parsed.data.stageId, last_activity_at: new Date().toISOString() } as never)
    .eq('id', parsed.data.dealId)
    .select('id')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };
  revalidatePath('/campaigns');
  return { ok: true };
}
