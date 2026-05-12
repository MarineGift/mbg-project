/**
 * lib/queries/engagements.ts
 *
 * Engagement Kanban 보드 데이터 + 상세 fetch.
 *
 * Kanban 조립:
 *   1. 모듈의 default pipeline_definition 찾기
 *   2. 그 pipeline의 stages를 sort_order로 정렬
 *   3. 해당 모듈의 engagements (deleted=false, status!='archived') fetch
 *   4. parties 조인 (이름 표시용)
 *   5. cardsByStage 매핑
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { ModuleType } from '@/types/ai';
import type {
  EngagementDetail,
  EngagementStageHistoryItem,
  EngagementStatus,
  KanbanBoard,
  KanbanCard,
  KanbanStage,
  PipelineStageType,
} from '@/types/engagement';

/* ============================================================
 * Kanban 보드 fetch
 * ============================================================ */

interface RawPipelineDef {
  id: string;
  name: string;
}

interface RawPipelineStage {
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

interface RawEngagementListRow {
  id: string;
  name: string;
  module: ModuleType;
  status: EngagementStatus;
  current_stage_id: string | null;
  party_id: string;
  value_amount: number | string | null;
  value_currency: string;
  probability_pct: number;
  weighted_amount: number | string | null;
  expected_close_date: string | null;
  owner_user_id: string | null;
  updated_at: string;
  parties: { name: string } | null;
}

export async function fetchKanbanBoard(
  module: ModuleType,
): Promise<KanbanBoard> {
  const supabase = await createSupabaseServerClient();

  // [1] 모듈의 default pipeline_definition (없으면 가장 최근 활성 pipeline)
  const { data: pipelineRaw } = await supabase
    .schema('app')
    .from('pipeline_definitions' as never)
    .select('id, name, is_default')
    .eq('module', module)
    .eq('is_active', true)
    .is('deleted_at', null)
    .order('is_default', { ascending: false })
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();

  const pipelineRow = pipelineRaw as unknown as RawPipelineDef | null;

  if (!pipelineRow) {
    // 파이프라인 미설정 — 빈 보드 반환
    return {
      module,
      pipelineDefinitionId: null,
      pipelineName: null,
      stages: [],
      cardsByStage: {},
      uncategorizedCards: [],
      totalCount: 0,
    };
  }

  // [2] stages fetch (sort_order 순) + [3] engagements fetch 병렬
  const [stagesRes, cardsRes] = await Promise.all([
    supabase
      .schema('app')
      .from('pipeline_stages' as never)
      .select(
        'id, pipeline_definition_id, code, name, stage_type, sort_order, default_probability_pct, is_terminal, is_won, is_lost, color_hex',
      )
      .eq('pipeline_definition_id', pipelineRow.id)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true }),

    supabase
      .schema('app')
      .from('engagements' as never)
      .select(
        `id, name, module, status, current_stage_id, party_id,
         value_amount, value_currency, probability_pct, weighted_amount,
         expected_close_date, owner_user_id, updated_at,
         parties:party_id ( name )`,
        { count: 'exact' },
      )
      .eq('module', module)
      .neq('status', 'archived')
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(500),
  ]);

  const stages: KanbanStage[] = (
    (stagesRes.data ?? []) as unknown as RawPipelineStage[]
  ).map(mapStage);

  const rawCards = (cardsRes.data ?? []) as unknown as RawEngagementListRow[];
  const cards = rawCards.map(mapCard);

  // [4] stage_id로 그룹화
  const cardsByStage: Record<string, KanbanCard[]> = {};
  for (const stage of stages) {
    cardsByStage[stage.id] = [];
  }
  const uncategorizedCards: KanbanCard[] = [];
  const stageIdSet = new Set(stages.map((s) => s.id));

  for (const card of cards) {
    if (card.currentStageId && stageIdSet.has(card.currentStageId)) {
      cardsByStage[card.currentStageId]!.push(card);
    } else {
      uncategorizedCards.push(card);
    }
  }

  return {
    module,
    pipelineDefinitionId: pipelineRow.id,
    pipelineName: pipelineRow.name,
    stages,
    cardsByStage,
    uncategorizedCards,
    totalCount: cardsRes.count ?? cards.length,
  };
}

function mapStage(r: RawPipelineStage): KanbanStage {
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

function mapCard(r: RawEngagementListRow): KanbanCard {
  const party = Array.isArray(r.parties) ? r.parties[0] : r.parties;
  return {
    id: r.id,
    name: r.name,
    module: r.module,
    status: r.status,
    currentStageId: r.current_stage_id,
    partyId: r.party_id,
    partyName: party?.name ?? '(unknown party)',
    valueAmount:
      typeof r.value_amount === 'number'
        ? r.value_amount
        : r.value_amount != null
          ? Number(r.value_amount)
          : null,
    valueCurrency: r.value_currency,
    probabilityPct: r.probability_pct,
    weightedAmount:
      typeof r.weighted_amount === 'number'
        ? r.weighted_amount
        : r.weighted_amount != null
          ? Number(r.weighted_amount)
          : null,
    expectedCloseDate: r.expected_close_date,
    ownerUserId: r.owner_user_id,
    updatedAt: r.updated_at,
  };
}

/* ============================================================
 * Engagement Detail fetch
 * ============================================================ */

interface RawEngagementDetailRow {
  id: string;
  organization_id: string;
  party_id: string;
  primary_contact_id: string | null;
  module: ModuleType;
  name: string;
  description: string | null;
  pipeline_definition_id: string | null;
  current_stage_id: string | null;
  status: EngagementStatus;
  value_amount: number | string | null;
  value_currency: string;
  probability_pct: number;
  weighted_amount: number | string | null;
  expected_close_date: string | null;
  actual_close_date: string | null;
  owner_user_id: string | null;
  won_lost_reason: string | null;
  source: string | null;
  created_at: string;
  updated_at: string;
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

export async function fetchEngagementDetail(
  engagementId: string,
): Promise<EngagementDetail | null> {
  const supabase = await createSupabaseServerClient();

  const { data: rawDetail, error } = await supabase
    .schema('app')
    .from('engagements' as never)
    .select('*')
    .eq('id', engagementId)
    .is('deleted_at', null)
    .maybeSingle();

  if (error || !rawDetail) return null;
  const e = rawDetail as unknown as RawEngagementDetailRow;

  // 병렬 fetch: party + primary_contact + pipeline + current_stage + available_stages + history
  const [
    partyRes,
    contactRes,
    pipelineRes,
    stagesRes,
    historyRes,
  ] = await Promise.all([
    supabase
      .schema('app')
      .from('parties' as never)
      .select('id, name, module')
      .eq('id', e.party_id)
      .maybeSingle(),

    e.primary_contact_id
      ? supabase
          .schema('app')
          .from('contacts' as never)
          .select('id, full_name')
          .eq('id', e.primary_contact_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    e.pipeline_definition_id
      ? supabase
          .schema('app')
          .from('pipeline_definitions' as never)
          .select('id, name')
          .eq('id', e.pipeline_definition_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    e.pipeline_definition_id
      ? supabase
          .schema('app')
          .from('pipeline_stages' as never)
          .select(
            'id, pipeline_definition_id, code, name, stage_type, sort_order, default_probability_pct, is_terminal, is_won, is_lost, color_hex',
          )
          .eq('pipeline_definition_id', e.pipeline_definition_id)
          .is('deleted_at', null)
          .order('sort_order', { ascending: true })
      : Promise.resolve({ data: [], error: null }),

    supabase
      .schema('app')
      .from('engagement_stage_history' as never)
      .select(
        'id, from_stage_id, to_stage_id, moved_at, moved_by_user_id, duration_in_previous_stage_seconds, reason',
      )
      .eq('engagement_id', engagementId)
      .order('moved_at', { ascending: false })
      .limit(50),
  ]);

  const party = partyRes?.data as { id: string; name: string; module: ModuleType } | null;
  const contact = contactRes?.data as { id: string; full_name: string | null } | null;
  const pipeline = pipelineRes?.data as { id: string; name: string } | null;
  const availableStages = ((stagesRes?.data ?? []) as unknown as RawPipelineStage[]).map(mapStage);

  const currentStage = availableStages.find((s) => s.id === e.current_stage_id) ?? null;

  // stage history — stage 이름·색 조회용 stage 매핑 (current + history의 stage들)
  const stageNameById = new Map<string, string>();
  for (const s of availableStages) stageNameById.set(s.id, s.name);
  // history의 다른 stage_id들도 필요할 수 있지만 이 모듈/파이프라인의 stage 외 stage_id는 무시
  // (다른 파이프라인으로 이동한 적이 있다면 stage 이름 미해석 — '(unknown stage)')

  const rawHistory = (historyRes?.data ?? []) as unknown as RawStageHistoryRow[];
  const stageHistory: EngagementStageHistoryItem[] = rawHistory.map((h) => ({
    id: h.id,
    fromStageId: h.from_stage_id,
    fromStageName: h.from_stage_id ? (stageNameById.get(h.from_stage_id) ?? null) : null,
    toStageId: h.to_stage_id,
    toStageName: h.to_stage_id
      ? (stageNameById.get(h.to_stage_id) ?? '(unknown stage)')
      : '(unknown stage)',
    movedAt: h.moved_at,
    movedByUserId: h.moved_by_user_id,
    durationSeconds: h.duration_in_previous_stage_seconds,
    reason: h.reason,
  }));

  return {
    id: e.id,
    organizationId: e.organization_id,
    partyId: e.party_id,
    partyName: party?.name ?? '(unknown party)',
    partyModule: party?.module ?? e.module,
    primaryContactId: e.primary_contact_id,
    primaryContactName: contact?.full_name ?? null,
    module: e.module,
    name: e.name,
    description: e.description,
    pipelineDefinitionId: e.pipeline_definition_id,
    pipelineName: pipeline?.name ?? null,
    currentStageId: e.current_stage_id,
    currentStageName: currentStage?.name ?? null,
    currentStageColor: currentStage?.colorHex ?? null,
    status: e.status,
    valueAmount:
      typeof e.value_amount === 'number'
        ? e.value_amount
        : e.value_amount != null
          ? Number(e.value_amount)
          : null,
    valueCurrency: e.value_currency,
    probabilityPct: e.probability_pct,
    weightedAmount:
      typeof e.weighted_amount === 'number'
        ? e.weighted_amount
        : e.weighted_amount != null
          ? Number(e.weighted_amount)
          : null,
    expectedCloseDate: e.expected_close_date,
    actualCloseDate: e.actual_close_date,
    ownerUserId: e.owner_user_id,
    wonLostReason: e.won_lost_reason,
    source: e.source,
    createdAt: e.created_at,
    updatedAt: e.updated_at,
    availableStages,
    stageHistory,
  };
}
