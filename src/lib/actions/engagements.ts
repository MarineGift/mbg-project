/**
 * lib/actions/engagements.ts
 *
 * Engagement Server Actions.
 *
 * URM cutover (Stage 29-c, 2026-05-25):
 *   - 모든 mutation 이 urm.deals 대상.
 *   - app.engagements + app.pipeline_stages → urm.deals + urm.stages.
 *   - organization_id filter 제거 (RLS 가정).
 *   - module column 제거 (urm.deals 에 없음). zod schema 의 module 인자는
 *     legacy 호환 위해 그대로 받지만 INSERT 에서 무시.
 *
 * 핵심:
 *   - moveEngagementStage: kanban drag-drop 으로 stage 변경.
 *     (트리거 trg_deals_stage_history 가 urm.deal_stage_history 에 자동 기록
 *      되는지 확인 필요 — 없으면 별도 INSERT 추가 검토.)
 *
 *   - updateEngagementStatus: 상태만 변경 (open/in_progress/on_hold/won/lost/archived).
 *
 *   - createEngagement: 1-step INSERT.
 *
 *   - updateEngagement: 일반 필드 업데이트.
 *
 *   - deleteEngagement: soft delete (deleted_at = now()).
 *
 * revalidatePath:
 *   urm.deals 에 module column 이 없어서 정확한 module path 무효화 불가.
 *   - 옵션 (a): party_type 별도 query 로 추론 → 비용 ↑
 *   - 옵션 (b): 모든 알려진 module path 일괄 무효화 → 단순, 약간 over-invalidation
 *   - 옵션 (c): revalidatePath('/') → 가장 단순, cache 효율 ↓
 *   여기서는 (b) 채택 — 알려진 5 module path 일괄 무효화.
 *   build round 3 에서 routing rename 이후 단일 path 로 정리.
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

// Legacy PartyTypeCode 8 값 — build round 3 에서 PARTY_TYPE_CODES 의 7 값으로 교체.
// 지금은 caller (UI) 호환 위해 그대로 유지. 어차피 INSERT 에는 안 들어감.
const LEGACY_MODULE_VALUES = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

/** revalidate 대상 module path 목록 (build round 3 에서 단일 path 로 정리). */
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

  // [1] deal + target stage 병렬 검증
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
 * 2. updateEngagementStatus — 상태만 변경
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
  // module argument — legacy 호환, INSERT 에는 안 들어감.
  // build round 3 에서 PartyTypeCode 7 값으로 교체.
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

  // pipelineId 없으면 default pipeline 자동 할당.
  // URM 에 모듈 분리 없어서 모든 module 이 동일 default pipeline 사용.
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

  // urm.deals INSERT — NOT NULL 필수: party_id, pipeline_id, current_stage_id, deal_name.
  // Default 있는 column (status, priority, module_data, value_currency) 은 omit 가능
  //   하지만 명시적으로 'open' 등 세팅해서 도메인 의미 유지.
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
