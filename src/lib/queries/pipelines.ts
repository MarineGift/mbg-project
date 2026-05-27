/**
 * lib/queries/pipelines.ts
 *
 * Pipeline / stage / stage-history 의 모든 read API.
 * URM: pipeline_definitions / pipeline_stages / engagement_stage_history 의 단일 source.
 *
 * 책임:
 *   - fetchPipelineForModule:    module 별 default pipeline (1 개 보장 — Stage 25 cleanup 후)
 *   - fetchStages:               pipeline 의 모든 stage (sort_order)
 *   - fetchFirstStage:           pipeline 의 첫 stage (createEngagement 용)
 *   - fetchStageHistory:         engagement 의 stage 변경 이력 (stage 이름 lookup 포함)
 *   - fetchAllPipelinesForModule: admin/select 용 (default + non-default 모두)
 *
 * Mutations 는 actions/engagements.ts (moveEngagementStage / createEngagement) +
 *                actions/pipeline-stages.ts (stage CRUD) 가 담당.
 *
 * Stage 25 (2026-05-21): queries/engagements.ts 와 actions/engagements.ts 의
 *                        inline pipeline/stage/history query 를 본 파일로 통합.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { PartyTypeCode } from '@/types/ai';
import type {
  EngagementStageHistoryItem,
  KanbanStage,
  PipelineStageType,
} from '@/types/engagement';

/* ============================================================
 * Raw row types (snake_case as DB)
 * ============================================================ */

export interface RawPipelineDef {
  id: string;
  name: string;
}

interface RawPipelineDefDetail {
  id: string;
  name: string;
  is_default: boolean;
  is_active: boolean;
}

export interface RawPipelineStage {
  id: string;
  pipeline_definition_id: string;
  code: string;
  name: string;
  stage_type: PipelineStageType;
  sort_order: number;
  default_probability_pct: number;
  is_terminal: boolean;
  is_won: boolean;
  is_lost: boolean;
  color_hex: string | null;
}

interface RawFirstStage {
  id: string;
}

interface RawStageHistoryRow {
  id: string;
  from_stage_id: string | null;
  to_stage_id: string | null;
  moved_at: string;
  moved_by_user_id: string | null;
  duration_in_previous_stage_seconds: number | null;
  reason: string | null;
}

/* ============================================================
 * Mapper — raw → camelCase
 * ============================================================ */

export function mapStage(r: RawPipelineStage): KanbanStage {
  return {
    id: r.id,
    pipelineDefinitionId: r.pipeline_definition_id,
    code: r.code,
    name: r.name,
    stageType: r.stage_type,
    sortOrder: r.sort_order,
    defaultProbabilityPct: r.default_probability_pct,
    isTerminal: r.is_terminal,
    isWon: r.is_won,
    isLost: r.is_lost,
    colorHex: r.color_hex,
  };
}

/* ============================================================
 * 1. fetchPipelineForModule
 *    Module 의 default pipeline (Stage 25 cleanup 후 정확히 1 개 보장).
 * ============================================================ */

export async function fetchPipelineForModule(
  module: PartyTypeCode,
): Promise<{ id: string; name: string } | null> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipeline_definitions' as never)
    .select('id, name')
    .eq('party_type', module)
    .eq('is_default', true)
    .eq('is_active', true)
    .is('deleted_at', null)
    .maybeSingle();

  return (data as RawPipelineDef | null) ?? null;
}

/* ============================================================
 * 2. fetchStages — pipeline 의 모든 stage (sort_order 순)
 * ============================================================ */

export async function fetchStages(
  pipelineDefinitionId: string,
): Promise<KanbanStage[]> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipeline_stages' as never)
    .select(
      'id, pipeline_definition_id, code, name, stage_type, sort_order, default_probability_pct, is_terminal, is_won, is_lost, color_hex',
    )
    .eq('pipeline_definition_id', pipelineDefinitionId)
    .is('deleted_at', null)
    .order('sort_order', { ascending: true });

  return ((data ?? []) as unknown as RawPipelineStage[]).map(mapStage);
}

/* ============================================================
 * 3. fetchFirstStage — pipeline 의 첫 stage (createEngagement 용)
 * ============================================================ */

export async function fetchFirstStage(
  pipelineDefinitionId: string,
): Promise<{ id: string } | null> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipeline_stages' as never)
    .select('id')
    .eq('pipeline_definition_id', pipelineDefinitionId)
    .is('deleted_at', null)
    .order('sort_order', { ascending: true })
    .limit(1)
    .maybeSingle();

  return (data as RawFirstStage | null) ?? null;
}

/* ============================================================
 * 4. fetchStageHistory — engagement 의 stage 변경 이력.
 *    Stage 이름 lookup 포함 (현재 pipeline 의 stages 만 — 다른 pipeline 이력은
 *    이름 미해석 '(unknown stage)').
 * ============================================================ */

export async function fetchStageHistory(
  engagementId: string,
  pipelineDefinitionId: string | null,
  limit = 50,
): Promise<EngagementStageHistoryItem[]> {
  const supabase = await createSupabaseServerClient();

  // history + 현재 pipeline 의 stages 병렬 fetch
  const [historyRes, stagesRes] = await Promise.all([
    supabase
      .schema('app')
      .from('engagement_stage_history' as never)
      .select(
        'id, from_stage_id, to_stage_id, moved_at, moved_by_user_id, duration_in_previous_stage_seconds, reason',
      )
      .eq('engagement_id', engagementId)
      .order('moved_at', { ascending: false })
      .limit(limit),

    pipelineDefinitionId
      ? supabase
          .schema('app')
          .from('pipeline_stages' as never)
          .select('id, name')
          .eq('pipeline_definition_id', pipelineDefinitionId)
          .is('deleted_at', null)
      : Promise.resolve({ data: [] as { id: string; name: string }[] }),
  ]);

  const stageNameById = new Map<string, string>();
  for (const s of (stagesRes.data ?? []) as unknown as {
    id: string;
    name: string;
  }[]) {
    stageNameById.set(s.id, s.name);
  }

  return ((historyRes.data ?? []) as unknown as RawStageHistoryRow[]).map((h) => ({
    id: h.id,
    fromStageId: h.from_stage_id,
    fromStageName: h.from_stage_id
      ? (stageNameById.get(h.from_stage_id) ?? null)
      : null,
    toStageId: h.to_stage_id,
    toStageName: h.to_stage_id
      ? (stageNameById.get(h.to_stage_id) ?? '(unknown stage)')
      : '(unknown stage)',
    movedAt: h.moved_at,
    movedByUserId: h.moved_by_user_id,
    durationSeconds: h.duration_in_previous_stage_seconds,
    reason: h.reason,
  }));
}

/* ============================================================
 * 5. fetchAllPipelinesForModule
 *    Admin/select 용. Default + non-default 모두.
 *    Stage 25 cleanup 후엔 module 당 1 개만 활성이지만,
 *    미래 multi-pipeline (예: 'Enterprise' vs 'SMB' funnel) 대비.
 * ============================================================ */

export async function fetchAllPipelinesForModule(
  module: PartyTypeCode,
): Promise<
  { id: string; name: string; isDefault: boolean; isActive: boolean }[]
> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipeline_definitions' as never)
    .select('id, name, is_default, is_active')
    .eq('party_type', module)
    .is('deleted_at', null)
    .order('is_default', { ascending: false })
    .order('created_at', { ascending: true });

  return ((data ?? []) as unknown as RawPipelineDefDetail[]).map((r) => ({
    id: r.id,
    name: r.name,
    isDefault: r.is_default,
    isActive: r.is_active,
  }));
}

/* ============================================================
 * fetchPipelineById -- single lookup by id (fix-round 1)
 * ============================================================ */

export async function fetchPipelineById(
  pipelineId: string,
): Promise<{ id: string; name: string } | null> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, name')
    .eq('id', pipelineId)
    .eq('is_active', true)
    .maybeSingle();

  return (data as RawPipelineDef | null) ?? null;
}
