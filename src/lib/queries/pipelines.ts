/**
 * lib/queries/pipelines.ts
 *
 * All read APIs for pipeline / stage / stage-history.
 *
 * Rewritten 2026-06-10 for the normalized schema (D9 cleanup):
 *   - app.pipelines  (id, code, name, is_default, is_active, sort_order)
 *   - app.stages     (pipeline_id FK -> pipelines.id, is_active soft delete,
 *                     NO deleted_at, NO stage_type column)
 *   - app.deal_stage_history (deal_id, from/to_stage_id, changed_at,
 *                     changed_by, notes -- NOT moved_at/engagement_id)
 *
 * The old implementation queried app.pipeline_definitions /
 * stages.pipeline_definition_id / deleted_at, none of which exist anymore;
 * every function here silently returned empty results at runtime.
 *
 * Type-compat note: KanbanStage.pipelineDefinitionId is kept as the field
 * name (mapped from stages.pipeline_id) and stageType is now DERIVED from
 * is_won / is_lost flags, so no consumer-side type changes are needed.
 *
 * Responsibilities:
 *   - fetchPipelineByCode:        pipeline lookup by code (sidebar/kanban key)
 *   - fetchStages:                all active stages of a pipeline (sort_order)
 *   - fetchFirstStage:            the first stage of a pipeline (for createEngagement)
 *   - fetchStageHistory:          a deal's stage-change history (with stage name lookup)
 *   - fetchAllPipelines:          for admin/select (both default + non-default)
 *   - fetchPipelineById:          single lookup by id
 *
 * Mutations are handled by actions/engagements.ts + actions/pipeline-stages.ts.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
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

interface RawPipelineDetail {
  id: string;
  code: string;
  name: string;
  is_default: boolean;
  is_active: boolean;
}

export interface RawPipelineStage {
  id: string;
  pipeline_id: string;
  code: string;
  name: string;
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
  changed_at: string;
  changed_by: string | null;
  notes: string | null;
}

const STAGE_SELECT =
  'id, pipeline_id, code, name, sort_order, default_probability_pct, is_terminal, is_won, is_lost, color_hex';

/* ============================================================
 * Mapper — raw → camelCase
 * ============================================================ */

/** stages has no stage_type column anymore — derive it from the flags. */
function deriveStageType(r: RawPipelineStage): PipelineStageType {
  if (r.is_won) return 'closed_won';
  if (r.is_lost) return 'closed_lost';
  return 'other';
}

export function mapStage(r: RawPipelineStage): KanbanStage {
  return {
    id: r.id,
    pipelineDefinitionId: r.pipeline_id,
    code: r.code,
    name: r.name,
    stageType: deriveStageType(r),
    sortOrder: r.sort_order,
    defaultProbabilityPct: r.default_probability_pct,
    isTerminal: r.is_terminal,
    isWon: r.is_won,
    isLost: r.is_lost,
    colorHex: r.color_hex,
  };
}

/* ============================================================
 * 1. fetchPipelineByCode
 *    Pipeline lookup by its code (the key used by the sidebar
 *    and /pipelines/[code] routes).
 * ============================================================ */

export async function fetchPipelineByCode(
  code: string,
): Promise<{ id: string; name: string } | null> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, name')
    .eq('code', code)
    .eq('is_active', true)
    .maybeSingle();

  return (data as RawPipelineDef | null) ?? null;
}

/* ============================================================
 * 2. fetchStages - all active stages of a pipeline (in sort_order)
 * ============================================================ */

export async function fetchStages(pipelineId: string): Promise<KanbanStage[]> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('stages' as never)
    .select(STAGE_SELECT)
    .eq('pipeline_id', pipelineId)
    .eq('is_active', true)
    .order('sort_order', { ascending: true });

  return ((data ?? []) as unknown as RawPipelineStage[]).map(mapStage);
}

/* ============================================================
 * 3. fetchFirstStage - the first stage of a pipeline (for createEngagement)
 * ============================================================ */

export async function fetchFirstStage(
  pipelineId: string,
): Promise<{ id: string } | null> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id')
    .eq('pipeline_id', pipelineId)
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .limit(1)
    .maybeSingle();

  return (data as RawFirstStage | null) ?? null;
}

/* ============================================================
 * 4. fetchStageHistory - a deal's stage-change history.
 *    Reads app.deal_stage_history (deal_id / changed_at / changed_by /
 *    notes). duration is not stored in the new schema -> null.
 *    Stage names are resolved against the current pipeline's stages;
 *    history rows pointing at other pipelines resolve to '(unknown stage)'.
 * ============================================================ */

export async function fetchStageHistory(
  dealId: string,
  pipelineId: string | null,
  limit = 50,
): Promise<EngagementStageHistoryItem[]> {
  const supabase = await createSupabaseServerClient();

  // fetch history + the current pipeline's stages in parallel
  const [historyRes, stagesRes] = await Promise.all([
    supabase
      .schema('app')
      .from('deal_stage_history' as never)
      .select('id, from_stage_id, to_stage_id, changed_at, changed_by, notes')
      .eq('deal_id', dealId)
      .order('changed_at', { ascending: false })
      .limit(limit),

    pipelineId
      ? supabase
          .schema('app')
          .from('stages' as never)
          .select('id, name')
          .eq('pipeline_id', pipelineId)
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
    movedAt: h.changed_at,
    movedByUserId: h.changed_by,
    durationSeconds: null,
    reason: h.notes,
  }));
}

/* ============================================================
 * 5. fetchAllPipelines
 *    For admin/select. Both default + non-default, active first.
 * ============================================================ */

export async function fetchAllPipelines(): Promise<
  { id: string; code: string; name: string; isDefault: boolean; isActive: boolean }[]
> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name, is_default, is_active')
    .order('sort_order', { ascending: true })
    .order('name', { ascending: true });

  return ((data ?? []) as unknown as RawPipelineDetail[]).map((r) => ({
    id: r.id,
    code: r.code,
    name: r.name,
    isDefault: r.is_default,
    isActive: r.is_active,
  }));
}

/* ============================================================
 * fetchPipelineById -- single lookup by id
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
