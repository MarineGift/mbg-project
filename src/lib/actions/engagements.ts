/**
 * lib/actions/engagements.ts
 *
 * Engagement Server Actions.
 *
 * 핵심:
 *   - moveEngagementStage: kanban drag-drop으로 stage 변경.
 *     트리거 trg_engagements_stage_history가 engagement_stage_history에 자동 기록.
 *     terminal stage (is_won/is_lost) 이동 시 status도 함께 갱신.
 *
 *   - updateEngagementStatus: 상태 변경 (open/in_progress/on_hold/won/lost/archived).
 *     일반 상태 토글용.
 *
 *   - createEngagement: 단순 1-step INSERT.
 *     FK constraint fk_engagement_stage_history_engagement_id가
 *     DEFERRABLE INITIALLY DEFERRED로 설정되어 있어 BEFORE INSERT 트리거가
 *     stage_history에 INSERT해도 commit 시점에 FK 검증되어 정상 작동.
 *
 *   - deleteEngagement: soft delete (deleted_at = now()).
 *     audit log 트리거가 actor (auth.uid()) 자동 기록.
 *
 * 권한: organization 멤버이면 모두 가능 (Q11 결정).
 *
 * 변경 이력:
 *   - 2026-05-12: createEngagement를 2-step INSERT로 변경 (FK 위반 우회)
 *   - 2026-05-12: deleteEngagement에서 존재하지 않는 deleted_by 컬럼 참조 제거.
 *   - 2026-05-12: FK constraint를 DEFERRABLE로 변경한 SQL migration 후
 *                 createEngagement를 다시 1-step INSERT로 단순화.
 *                 stage_history도 INSERT 시점부터 정확히 기록됨.
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
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

  // [1] engagement과 target stage를 검증 — 같은 pipeline에 속해야 함
  const [engRes, stageRes] = await Promise.all([
    supabase
      .schema('app')
      .from('engagements' as never)
      .select('id, pipeline_definition_id, current_stage_id, module, status')
      .eq('id', parsed.data.engagementId)
      .eq('organization_id', auth.organizationId)
      .is('deleted_at', null)
      .maybeSingle(),

    supabase
      .schema('app')
      .from('pipeline_stages' as never)
      .select(
        'id, pipeline_definition_id, is_won, is_lost, default_probability_pct',
      )
      .eq('id', parsed.data.toStageId)
      .eq('organization_id', auth.organizationId)
      .is('deleted_at', null)
      .maybeSingle(),
  ]);

  if (engRes.error || !engRes.data) {
    return { ok: false, errorCode: 'not_found' };
  }
  if (stageRes.error || !stageRes.data) {
    return { ok: false, errorCode: 'invalid_stage', errorMessage: 'Target stage not found' };
  }

  const eng = engRes.data as {
    id: string;
    pipeline_definition_id: string | null;
    current_stage_id: string | null;
    module: string;
    status: EngagementStatus;
  };
  const stage = stageRes.data as {
    id: string;
    pipeline_definition_id: string;
    is_won: boolean;
    is_lost: boolean;
    default_probability_pct: number;
  };

  if (
    eng.pipeline_definition_id != null &&
    eng.pipeline_definition_id !== stage.pipeline_definition_id
  ) {
    return {
      ok: false,
      errorCode: 'invalid_stage',
      errorMessage: 'Target stage belongs to a different pipeline',
    };
  }

  if (eng.current_stage_id === stage.id) {
    // No-op — 같은 stage로 drop
    return { ok: true };
  }

  // [2] UPDATE — 트리거가 stage_history 자동 기록
  const updates: Record<string, unknown> = {
    current_stage_id: stage.id,
    probability_pct: stage.default_probability_pct,
  };

  // terminal stage이면 status도 함께 갱신
  if (stage.is_won) {
    updates.status = 'won';
    updates.actual_close_date = new Date().toISOString().slice(0, 10);
  } else if (stage.is_lost) {
    updates.status = 'lost';
    updates.actual_close_date = new Date().toISOString().slice(0, 10);
  } else if (eng.status === 'open') {
    // open → 이동 시 in_progress로 자동 전이
    updates.status = 'in_progress';
  }

  // pipeline_definition_id가 null이었으면 채워주기
  if (eng.pipeline_definition_id == null) {
    updates.pipeline_definition_id = stage.pipeline_definition_id;
  }

  const { error: updateErr } = await supabase
    .schema('app')
    .from('engagements' as never)
    .update(updates as never)
    .eq('id', parsed.data.engagementId)
    .eq('organization_id', auth.organizationId);

  if (updateErr) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: updateErr.message,
    };
  }

  revalidatePath(`/${eng.module}/engagements`);
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
  };
  if (parsed.data.status === 'won' || parsed.data.status === 'lost') {
    updates.actual_close_date = new Date().toISOString().slice(0, 10);
    if (parsed.data.wonLostReason) {
      updates.won_lost_reason = parsed.data.wonLostReason;
    }
  }

  const { error, data } = await supabase
    .schema('app')
    .from('engagements' as never)
    .update(updates as never)
    .eq('id', parsed.data.engagementId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, module')
    .maybeSingle();

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }
  if (!data) {
    return { ok: false, errorCode: 'not_found' };
  }
  const updated = data as { id: string; module: string };

  revalidatePath(`/${updated.module}/engagements`);
  revalidatePath(`/engagements/${parsed.data.engagementId}`);
  return { ok: true };
}

/* ============================================================
 * 3. createEngagement / updateEngagement / deleteEngagement
 * ============================================================ */

const engagementBaseSchema = z.object({
  partyId: z.string().uuid(),
  module: z.enum([
    'investor',
    'buyer',
    'partner',
    'customer',
    'crowdfunding',
    'product_launch',
    'sales',
  ]),
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

  // pipelineDefinitionId가 없으면 모듈의 default pipeline을 자동 할당
  let pipelineDefinitionId = parsed.data.pipelineDefinitionId ?? null;
  let currentStageId = parsed.data.currentStageId ?? null;

  if (!pipelineDefinitionId) {
    const { data: pipeRaw } = await supabase
      .schema('app')
      .from('pipeline_definitions' as never)
      .select('id')
      .eq('module', parsed.data.module)
      .eq('is_default', true)
      .is('deleted_at', null)
      .maybeSingle();
    pipelineDefinitionId = (pipeRaw as { id: string } | null)?.id ?? null;
  }

  if (pipelineDefinitionId && !currentStageId) {
    // 첫 stage 자동 할당
    const { data: firstStageRaw } = await supabase
      .schema('app')
      .from('pipeline_stages' as never)
      .select('id')
      .eq('pipeline_definition_id', pipelineDefinitionId)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true })
      .limit(1)
      .maybeSingle();
    currentStageId = (firstStageRaw as { id: string } | null)?.id ?? null;
  }

  // 1-step INSERT — current_stage_id 포함.
  // BEFORE INSERT 트리거 trg_engagements_stage_history가 stage_history에
  // 자동 기록함. FK가 DEFERRABLE INITIALLY DEFERRED로 설정되어 있어 commit
  // 시점에 검증되므로 안전.
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    party_id: parsed.data.partyId,
    module: parsed.data.module,
    name: parsed.data.name.trim(),
    description: parsed.data.description?.trim() || null,
    pipeline_definition_id: pipelineDefinitionId,
    current_stage_id: currentStageId,
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
    .from('engagements' as never)
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

  revalidatePath(`/${parsed.data.module}/engagements`);
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
    name: parsed.data.name.trim(),
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
    .from('engagements' as never)
    .update(updates as never)
    .eq('id', parsed.data.engagementId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('id, module')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };

  revalidatePath(`/engagements/${parsed.data.engagementId}`);
  revalidatePath(`/${parsed.data.module}/engagements`);
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
  // soft delete — audit log 트리거가 actor (auth.uid()) 자동 기록.
  // deleted_by 컬럼은 app.engagements 스키마에 존재하지 않음 (parties와 동일).
  const { error, data } = await supabase
    .schema('app')
    .from('engagements' as never)
    .update({
      deleted_at: new Date().toISOString(),
    } as never)
    .eq('id', parsed.data.engagementId)
    .eq('organization_id', auth.organizationId)
    .is('deleted_at', null)
    .select('module')
    .maybeSingle();

  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found' };
  const module = (data as { module: string }).module;

  revalidatePath(`/${module}/engagements`);
  return { ok: true };
}
