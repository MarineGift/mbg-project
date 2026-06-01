/**
 * lib/actions/engagements.ts
 *
 * Engagement Server Actions.
 *
 * URM cutover (Stage 29-c, 2026-05-25):
 *   - all mutations target urm.deals.
 *   - app.engagements + app.pipeline_stages → urm.deals + urm.stages.
 *   - organization_id filter removed (assumes RLS).
 *   - module column removed (absent in urm.deals). The module arg in the zod schema is
 *     still accepted for legacy compatibility but ignored on INSERT.
 *
 * Core:
 *   - moveEngagementStage: change stage via kanban drag-drop.
 *     (verify whether the trg_deals_stage_history trigger auto-records into urm.deal_stage_history
 *      - if not, consider adding a separate INSERT.)
 *
 *   - updateEngagementStatus: change status only (open/in_progress/on_hold/won/lost/archived).
 *
 *   - createEngagement: 1-step INSERT.
 *
 *   - updateEngagement: update general fields.
 *
 *   - deleteEngagement: soft delete (deleted_at = now()).
 *
 * revalidatePath:
 *   urm.deals has no module column, so precise module-path invalidation is not possible.
 *   - option (a): infer via a separate party_type query -> higher cost
 *   - option (b): invalidate all known module paths at once -> simple, slight over-invalidation
 *   - option (c): revalidatePath('/') -> simplest, lower cache efficiency
 *   Here we adopt (b) - invalidate the 5 known module paths at once.
 *   After the routing rename in build round 3, consolidate to a single path.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { fetchFirstStage, fetchPipelineForModule } from '@/lib/queries/pipelines';
import type { EngagementStatus } from '@/types/engagement';

export interface EngagementActionResult {
  ok: boolean;
  errorCode?:
    | 'unauthorized'
    | 'not_found'
    | 'invalid_stage'
    | 'invalid_status'
    | 'validation'
    | 'database'
    | 'unknown';
  errorMessage?: string;
}

const ENGAGEMENT_STATUSES: readonly EngagementStatus[] = [
  'open',
  'in_progress',
  'on_hold',
  'won',
  'lost',
  'archived',
] as const;

// Legacy PartyTypeCode 8 values - replaced by the 7 values of PARTY_TYPE_CODES in build round 3.
// For now kept for caller (UI) compatibility. It does not go into the INSERT anyway.
const LEGACY_MODULE_VALUES = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

/** List of module paths to revalidate (consolidated to a single path in build round 3). */
const REVALIDATE_MODULES = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

function revalidateAllModulePaths(pathSuffix: string): void {
  for (const m of REVALIDATE_MODULES) {
    revalidatePath(`/${m}${pathSuffix}`);
  }
}

/* ============================================================
 * 1. moveEngagementStage — Kanban drag-drop
 * ============================================================ */

const moveStageSchema = z.object({
  engagementId: z.string().uuid(),
  toStageId: z.string().uuid(),
  reason: z.string().max(500).optional(),
});

export async function moveEngagementStage(input: {
  engagementId: string;
  toStageId: string;
  reason?: string;
}): Promise<EngagementActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = moveStageSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // [1] validate deal + target stage in parallel
  const [dealRes, stageRes] = await Promise.all([
    supabase
      .schema('app')
      .from('deals' as never)
      .select('id, pipeline_id, current_stage_id, status')
      .eq('id', parsed.data.engagementId)
      .is('deleted_at', null)
      .maybeSingle(),

    supabase
      .schema('app')
      .from('stages' as never)
      .select('id, pipeline_id, is_won, is_lost, default_probability_pct')
      .eq('id', parsed.data.toStageId)
      .eq('is_active', true)
      .maybeSingle(),
  ]);

  if (dealRes.error || !dealRes.data) {
    return { ok: false, errorCode: 'not_found' };
  }
  if (stageRes.error || !stageRes.data) {
    return {
      ok: false,
      errorCode: 'invalid_stage',
      errorMessage: 'Target stage not found',
    };
  }

  const deal = dealRes.data as {
    id: string;
    pipeline_id: string | null;
    current_stage_id: string | null;
    status: EngagementStatus;
  };
  const stage = stageRes.data as {
    id: string;
    pipeline_id: string;
    is_won: boolean;
    is_lost: boolean;
    default_probability_pct: number;
  };

  if (
    deal.pipeline_id != null &&
    deal.pipeline_id !== stage.pipeline_id
  ) {
    return {
      ok: false,
      errorCode: 'invalid_stage',
      errorMessage: 'Target stage belongs to a different pipeline',
    };
  }

  if (deal.current_stage_id === stage.id) {
    return { ok: true };
  }

  // [2] UPDATE
  const updates: Record<string, unknown> = {
    current_stage_id: stage.id,
    probability_pct: stage.default_probability_pct,
  };

  if (stage.is_won) {
    updates.status = 'won';
    updates.actual_close_date = new Date().toISOString().slice(0, 10);
  } else if (stage.is_lost) {
    updates.status = 'lost';
    updates.actual_close_date = new Date().toISOString().slice(0, 10);
  } else if (deal.status === 'open') {
    updates.status = 'in_progress';
  }

  if (deal.pipeline_id == null) {
    updates.pipeline_id = stage.pipeline_id;
  }

  updates.updated_by = auth.userId;

  const { error: updateErr } = await supabase
    .schema('app')
    .from('deals' as never)
    .update(updates as never)
    .eq('id', parsed.data.engagementId);

  if (updateErr) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: updateErr.message,
    };
  }

  revalidateAllModulePaths('/engagements');
  revalidatePath(`/engagements/${parsed.data.engagementId}`);
  return { ok: true };
}

/* ============================================================
 * 2. updateEngagementStatus - change status only
 * ============================================================ */

const statusSchema = z.object({
  engagementId: z.string().uuid(),
  status: z.enum(['open', 'in_progress', 'on_hold', 'won', 'lost', 'archived']),
  wonLostReason: z.string().max(500).optional(),
});

export async function updateEngagementStatus(input: {
  engagementId: string;
  status: EngagementStatus;
  wonLostReason?: string;
}): Promise<EngagementActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = statusSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  if (!ENGAGEMENT_STATUSES.includes(parsed.data.status)) {
    return { ok: false, errorCode: 'invalid_status' };
  }

  const supabase = await createSupabaseServerClient();

  const updates: Record<string, unknown> = {
    status: parsed.data.status,
    updated_by: auth.userId,
  };
  if (parsed.data.status === 'won' || parsed.data.status === 'lost') {
    updates.actual_close_date = new Date().toISOString().slice(0, 10);
    if (parsed.data.wonLostReason) {
      updates.won_lost_reason = parsed.data.wonLostReason;
    }
  }

  const { error, data } = await supabase
    .schema('app')
    .from('deals' as never)
    .update(updates as never)
    .eq('id', parsed.data.engagementId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) {
    return { ok: false, errorCode: 'not_found' };
  }

  revalidateAllModulePaths('/engagements');
  revalidatePath(`/engagements/${parsed.data.engagementId}`);
  return { ok: true };
}

/* ============================================================
 * 3. createEngagement / updateEngagement / deleteEngagement
 * ============================================================ */

const engagementBaseSchema = z.object({
  partyId: z.string().uuid(),
  // module argument - legacy compatibility, not included in the INSERT.
  // Replaced by the 7 PartyTypeCode values in build round 3.
  module: z.enum(LEGACY_MODULE_VALUES),
  name: z.string().min(1, 'Required').max(200),
  description: z.string().max(5000).optional().nullable(),
  pipelineDefinitionId: z.string().uuid().optional().nullable(),
  currentStageId: z.string().uuid().optional().nullable(),
  valueAmount: z.number().min(0).max(1e15).optional().nullable(),
  valueCurrency: z.string().length(3).default('USD'),
  probabilityPct: z.number().int().min(0).max(100).default(0),
  expectedCloseDate: z.string().optional().nullable(),
  source: z.string().max(120).optional().nullable(),
});

export async function createEngagement(
  input: z.input<typeof engagementBaseSchema>,
): Promise<EngagementActionResult & { engagementId?: string }> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = engagementBaseSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // If pipelineId is absent, auto-assign the default pipeline.
  // URM has no module separation, so every module uses the same default pipeline.
  let pipelineId = parsed.data.pipelineDefinitionId ?? null;
  let currentStageId = parsed.data.currentStageId ?? null;

  if (!pipelineId) {
    const pipeline = await fetchPipelineForModule(parsed.data.module);
    pipelineId = pipeline?.id ?? null;
  }

  if (pipelineId && !currentStageId) {
    const firstStage = await fetchFirstStage(pipelineId);
    currentStageId = firstStage?.id ?? null;
  }

  if (!pipelineId || !currentStageId) {
    return {
      ok: false,
      errorCode: 'invalid_stage',
      errorMessage: 'No default pipeline / first stage available',
    };
  }

  // urm.deals INSERT - NOT NULL required: party_id, pipeline_id, current_stage_id, deal_name.
  // Columns with defaults (status, priority, module_data, value_currency) may be omitted
  //   but are set explicitly (e.g. 'open') to preserve domain meaning.
  const insertRow: Record<string, unknown> = {
    party_id: parsed.data.partyId,
    pipeline_id: pipelineId,
    current_stage_id: currentStageId,
    deal_name: parsed.data.name.trim(),
    description: parsed.data.description?.trim() || null,
    status: 'open',
    value_amount: parsed.data.valueAmount ?? null,
    value_currency: parsed.data.valueCurrency,
    probability_pct: parsed.data.probabilityPct,
    expected_close_date: parsed.data.expectedCloseDate || null,
    source: parsed.data.source?.trim() || null,
    owner_user_id: auth.userId,
    created_by: auth.userId,
  };

  const { data, error } = await supabase
    .schema('app')
    .from('deals' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (error || !data) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error?.message ?? 'Insert failed',
    };
  }
  const engagementId = (data as { id: string }).id;

  revalidateAllModulePaths('/engagements');
  return { ok: true, engagementId };
}

const updateEngagementSchema = engagementBaseSchema.extend({
  engagementId: z.string().uuid(),
});

export async function updateEngagement(
  input: z.input<typeof updateEngagementSchema>,
): Promise<EngagementActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = updateEngagementSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const updates: Record<string, unknown> = {
    deal_name: parsed.data.name.trim(),
    description: parsed.data.description?.trim() || null,
    value_amount: parsed.data.valueAmount ?? null,
    value_currency: parsed.data.valueCurrency,
    probability_pct: parsed.data.probabilityPct,
    expected_close_date: parsed.data.expectedCloseDate || null,
    source: parsed.data.source?.trim() || null,
    updated_by: auth.userId,
  };

  const { error, data } = await supabase
    .schema('app')
    .from('deals' as never)
    .update(updates as never)
    .eq('id', parsed.data.engagementId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error)
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  revalidatePath(`/engagements/${parsed.data.engagementId}`);
  revalidateAllModulePaths('/engagements');
  return { ok: true };
}

export async function deleteEngagement(input: {
  engagementId: string;
}): Promise<EngagementActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const parsed = z
    .object({ engagementId: z.string().uuid() })
    .safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation' };
  }

  const supabase = await createSupabaseServerClient();
  const { error, data } = await supabase
    .schema('app')
    .from('deals' as never)
    .update({
      deleted_at: new Date().toISOString(),
      updated_by: auth.userId,
    } as never)
    .eq('id', parsed.data.engagementId)
    .is('deleted_at', null)
    .select('id')
    .maybeSingle();

  if (error)
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  revalidateAllModulePaths('/engagements');
  return { ok: true };
}
