/**
 * lib/queries/engagements.ts
 *
 * Engagement Kanban + 상세 + party-scoped list 의 read API.
 *
 * URM (Stage 25):
 *   - pipeline / stage / stage-history read 는 모두 ./pipelines 위임.
 *   - 본 파일은 engagements (+ parties join) 의 read API 만 책임.
 *
 * Kanban 조립:
 *   1. fetchPipelineForModule  (default pipeline)
 *   2. fetchStages              (sort_order 순)
 *   3. engagements fetch        (parties join, current_stage_id 기준 그룹화)
 *
 * Stage 25 변경:
 *   - RawPipelineDef / RawPipelineStage / RawStageHistoryRow / mapStage 제거
 *     (pipelines.ts 가 단일 source)
 *   - fetchKanbanBoard / fetchEngagementDetail 의 inline pipeline lookup 제거
 *   - fetchPartyEngagements 신규 (modal engagement selector 용)
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { ModuleType } from '@/types/ai';
import type {
  EngagementDetail,
  EngagementStatus,
  KanbanBoard,
  KanbanCard,
} from '@/types/engagement';
import {
  fetchPipelineById,
  fetchPipelineForModule,
  fetchStageHistory,
  fetchStages,
} from './pipelines';

/* ============================================================
 * Raw row types — engagements + parties join (kanban / list 공용)
 * ============================================================ */

interface RawEngagementListRow {
  id: string;
  name: string;
  module: ModuleType;
  status: EngagementStatus;
  current_stage_id: string | null;
  pipeline_definition_id: string | null;
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

const ENGAGEMENT_LIST_SELECT = `
  id, name, module, status, current_stage_id, pipeline_definition_id, party_id,
  value_amount, value_currency, probability_pct, weighted_amount,
  expected_close_date, owner_user_id, updated_at,
  parties:party_id ( name )
` as const;

/* ============================================================
 * Mapper — engagement raw row → KanbanCard
 * ============================================================ */

function mapCard(r: RawEngagementListRow): KanbanCard {
  const party = Array.isArray(r.parties) ? r.parties[0] : r.parties;
  return {
    id: r.id,
    name: r.name,
    module: r.module,
    status: r.status,
    currentStageId: r.current_stage_id,
    pipelineDefinitionId: r.pipeline_definition_id ?? null,
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
 * 1. fetchKanbanBoard — module 별 Kanban 보드 조립
 * ============================================================ */

export async function fetchKanbanBoard(
  module: ModuleType,
): Promise<KanbanBoard> {
  // [1] default pipeline 찾기 (없으면 빈 보드)
  const pipeline = await fetchPipelineForModule(module);

  if (!pipeline) {
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

  // [2] stages + [3] engagements (cards) 병렬 fetch
  const supabase = await createSupabaseServerClient();
  const [stages, cardsRes] = await Promise.all([
    fetchStages(pipeline.id),
    supabase
      .schema('app')
      .from('engagements' as never)
      .select(ENGAGEMENT_LIST_SELECT, { count: 'exact' })
      .eq('module', module)
      .neq('status', 'archived')
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(500),
  ]);

  const rawCards = (cardsRes.data ?? []) as unknown as RawEngagementListRow[];
  const cards = rawCards.map(mapCard);

  // [4] stage_id 로 그룹화
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
    pipelineDefinitionId: pipeline.id,
    pipelineName: pipeline.name,
    stages,
    cardsByStage,
    uncategorizedCards,
    totalCount: cardsRes.count ?? cards.length,
  };
}

/* ============================================================
 * 2. fetchEngagementDetail — engagement 1 개 + pipeline + stages + history
 * ============================================================ */

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

  // party + contact + pipeline + stages + history 병렬 fetch
  const [partyRes, contactRes, pipeline, availableStages, stageHistory] =
    await Promise.all([
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
        : Promise.resolve({ data: null }),

      e.pipeline_definition_id
        ? fetchPipelineById(e.pipeline_definition_id)
        : Promise.resolve(null),

      e.pipeline_definition_id
        ? fetchStages(e.pipeline_definition_id)
        : Promise.resolve([]),

      fetchStageHistory(engagementId, e.pipeline_definition_id, 50),
    ]);

  const party = partyRes?.data as
    | { id: string; name: string; module: ModuleType }
    | null;
  const contact = contactRes?.data as
    | { id: string; full_name: string | null }
    | null;

  const currentStage =
    availableStages.find((s) => s.id === e.current_stage_id) ?? null;

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

/* ============================================================
 * 3. fetchPartyEngagements — 한 party 의 모든 engagement list
 *    Stage 26 의 meeting-create-modal engagement selector 용.
 *    Soft-deleted / archived 제외, updated_at desc.
 * ============================================================ */

export async function fetchPartyEngagements(
  partyId: string,
): Promise<KanbanCard[]> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('engagements' as never)
    .select(ENGAGEMENT_LIST_SELECT)
    .eq('party_id', partyId)
    .neq('status', 'archived')
    .is('deleted_at', null)
    .order('updated_at', { ascending: false });

  const rows = (data ?? []) as unknown as RawEngagementListRow[];
  return rows.map(mapCard);
}
