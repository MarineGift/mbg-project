/**
 * lib/queries/engagements.ts
 *
 * Engagement Kanban + 상세 + party-scoped list 의 read API.
 *
 * URM cutover (Stage 29-c, 2026-05-25):
 *   - app.engagements → urm.deals (atomic cutover)
 *   - parties join 도 urm.parties (FK target)
 *   - module 정보는 urm.party_types.code 에서 lookup (urm.parties.party_type_id)
 *
 * URM schema 차이점 흡수:
 *   - app.engagements.name → urm.deals.deal_name
 *   - app.engagements.pipeline_definition_id → urm.deals.pipeline_id
 *   - app.engagements.partyType 제거 → urm.parties.party_type_id 기반 추론
 *   - app.engagements.weighted_amount 제거 → 클라이언트 계산
 *     (value_amount * probability_pct / 100)
 *   - organization_id filter 제거 (RLS 가정)
 *
 * 도메인 type (KanbanCard, EngagementDetail) 은 그대로 유지.
 * mapping layer 에서 column rename 및 derived field 처리.
 *
 * 책임:
 *   1. fetchKanbanBoard      ← module 별 Kanban 보드
 *   2. fetchEngagementDetail ← engagement 1개 + pipeline + stages + history
 *   3. fetchPartyEngagements ← party 의 모든 engagement (selector 용)
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type {
  EngagementDetail,
  EngagementStatus,
  KanbanBoard,
  KanbanCard,
} from '@/types/engagement';
import {
  PARTY_TYPE_CODE_BY_ID,
  partyTypeToModule,
  type PartyTypeCode,
} from '@/types/party-type';
import {
  fetchPipelineById,
  fetchPipelineForModule,
  fetchStageHistory,
  fetchStages,
} from './pipelines';

/* ============================================================
 * Raw row types — urm.deals + urm.parties join
 * ============================================================ */

interface RawPartyJoin {
  name: string;
  party_type_id: number | null;
}

interface RawEngagementListRow {
  id: string;
  deal_name: string;
  status: EngagementStatus;
  current_stage_id: string | null;
  pipeline_id: string | null;
  party_id: string;
  value_amount: number | string | null;
  value_currency: string;
  probability_pct: number | null;
  expected_close_date: string | null;
  owner_user_id: string | null;
  updated_at: string;
  parties: RawPartyJoin | RawPartyJoin[] | null;
}

interface RawEngagementDetailRow {
  id: string;
  party_id: string;
  primary_contact_id: string | null;
  deal_name: string;
  description: string | null;
  pipeline_id: string | null;
  current_stage_id: string | null;
  status: EngagementStatus;
  value_amount: number | string | null;
  value_currency: string;
  probability_pct: number | null;
  expected_close_date: string | null;
  actual_close_date: string | null;
  owner_user_id: string | null;
  won_lost_reason: string | null;
  source: string | null;
  created_at: string;
  updated_at: string;
}

/**
 * Kanban / list 용 SELECT clause.
 *
 * urm.deals 의 column 명으로 작성. parties join 으로 name + party_type_id 가져옴.
 * party_type_id 가 mapping 단계에서 PartyTypeCode 으로 변환됨.
 */
const DEAL_LIST_SELECT = `
  id, deal_name, status, current_stage_id, pipeline_id, party_id,
  value_amount, value_currency, probability_pct,
  expected_close_date, owner_user_id, updated_at,
  parties:party_id ( name, party_type_id )
` as const;

/* ============================================================
 * Helpers
 * ============================================================ */

function toNumberOrNull(v: number | string | null | undefined): number | null {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

/**
 * urm.parties.party_type_id (smallint) → PartyTypeCode 변환.
 *
 * Steps:
 *   1. id → PartyTypeCode (PARTY_TYPE_CODE_BY_ID)
 *   2. PartyTypeCode → PartyTypeCode (partyTypeToModule)
 *   3. fallback: 'investor' (default safe value)
 *
 * NOTE: PartyTypeCode 가 'buyer' 또는 'government_grant' 면 partyTypeToModule
 *       는 null 반환 → 'investor' fallback. 추후 도메인 type 이
 *       PartyTypeCode 로 rename 되면 fallback 제거.
 */
function partyTypeIdToModule(
  partyTypeId: number | null | undefined,
): PartyTypeCode {
  if (partyTypeId == null) return 'investor';
  const code: PartyTypeCode | undefined = PARTY_TYPE_CODE_BY_ID[partyTypeId];
  if (!code) return 'investor';
  const legacy = partyTypeToModule(code);
  return (legacy ?? 'investor') as PartyTypeCode;
}

function computeWeightedAmount(
  valueAmount: number | null,
  probabilityPct: number | null,
): number | null {
  if (valueAmount == null || probabilityPct == null) return null;
  return (valueAmount * probabilityPct) / 100;
}

/* ============================================================
 * Mapper — engagement raw row → KanbanCard
 * ============================================================ */

function mapCard(r: RawEngagementListRow): KanbanCard {
  const party = Array.isArray(r.parties) ? r.parties[0] : r.parties;
  const valueAmount = toNumberOrNull(r.value_amount);
  const probabilityPct = r.probability_pct ?? 0;
  return {
    id: r.id,
    name: r.deal_name,
    partyType: partyTypeIdToModule(party?.party_type_id ?? null),
    status: r.status,
    currentStageId: r.current_stage_id,
    pipelineDefinitionId: r.pipeline_id ?? null,
    partyId: r.party_id,
    partyName: party?.name ?? '(unknown party)',
    valueAmount,
    valueCurrency: r.value_currency,
    probabilityPct,
    weightedAmount: computeWeightedAmount(valueAmount, probabilityPct),
    expectedCloseDate: r.expected_close_date,
    ownerUserId: r.owner_user_id,
    updatedAt: r.updated_at,
  };
}

/* ============================================================
 * 1. fetchKanbanBoard — module 별 Kanban 보드
 *
 * NOTE: urm 에 모듈 분리 없으므로 module argument 는 fetchPipelineForModule
 *       및 board metadata 표시용으로만 사용. 모든 module 이 동일 default
 *       pipeline + 동일 stages + 동일 cards 를 봄.
 *
 *       module 별 카드 분리가 필요하면, party_type_id 기반 filter 를
 *       SELECT 단계에서 추가해야 함 (P2b/c 의 영역).
 * ============================================================ */

export async function fetchKanbanBoard(
  partyType: PartyTypeCode,
): Promise<KanbanBoard> {
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

  const supabase = await createSupabaseServerClient();
  const [stages, cardsRes] = await Promise.all([
    fetchStages(pipeline.id),
    supabase
      .schema('urm')
      .from('deals' as never)
      .select(DEAL_LIST_SELECT, { count: 'exact' })
      .neq('status', 'archived')
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(500),
  ]);

  const rawCards = (cardsRes.data ?? []) as unknown as RawEngagementListRow[];
  const cards = rawCards.map(mapCard);

  // stage_id 로 그룹핑
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
 * 2. fetchEngagementDetail — engagement 1개 + pipeline + stages + history
 * ============================================================ */

export async function fetchEngagementDetail(
  engagementId: string,
): Promise<EngagementDetail | null> {
  const supabase = await createSupabaseServerClient();

  const { data: rawDetail, error } = await supabase
    .schema('urm')
    .from('deals' as never)
    .select(
      `id, party_id, primary_contact_id,
       deal_name, description, pipeline_id, current_stage_id, status,
       value_amount, value_currency, probability_pct,
       expected_close_date, actual_close_date, owner_user_id,
       won_lost_reason, source, created_at, updated_at`,
    )
    .eq('id', engagementId)
    .is('deleted_at', null)
    .maybeSingle();

  if (error || !rawDetail) return null;
  const e = rawDetail as unknown as RawEngagementDetailRow;

  // party + contact + pipeline + stages + history 병렬 fetch
  const [partyRes, contactRes, pipeline, availableStages, stageHistory] =
    await Promise.all([
      supabase
        .schema('urm')
        .from('parties' as never)
        .select('id, name, party_type_id')
        .eq('id', e.party_id)
        .maybeSingle(),

      e.primary_contact_id
        ? supabase
            .schema('urm')
            .from('contacts' as never)
            .select('id, full_name')
            .eq('id', e.primary_contact_id)
            .maybeSingle()
        : Promise.resolve({ data: null }),

      e.pipeline_id
        ? fetchPipelineById(e.pipeline_id)
        : Promise.resolve(null),

      e.pipeline_id
        ? fetchStages(e.pipeline_id)
        : Promise.resolve([] as KanbanStage[]),

      fetchStageHistory(engagementId, e.pipeline_id, 50),
    ]);

  const party = partyRes?.data as
    | { id: string; name: string; party_type_id: number | null }
    | null;
  const contact = contactRes?.data as
    | { id: string; full_name: string | null }
    | null;

  const currentStage =
    availableStages.find((s) => s.id === e.current_stage_id) ?? null;

  const valueAmount = toNumberOrNull(e.value_amount);
  const probabilityPct = e.probability_pct ?? 0;
  const moduleValue = partyTypeIdToModule(party?.party_type_id ?? null);

  return {
    id: e.id,
    // organization_id 는 urm.deals 에 없음 → 빈 string (도메인 type 호환)
    organizationId: '',
    partyId: e.party_id,
    partyName: party?.name ?? '(unknown party)',
    primaryContactId: e.primary_contact_id,
    primaryContactName: contact?.full_name ?? null,
    partyType: moduleValue,
    name: e.deal_name,
    description: e.description,
    pipelineDefinitionId: e.pipeline_id,
    pipelineName: pipeline?.name ?? null,
    currentStageId: e.current_stage_id,
    currentStageName: currentStage?.name ?? null,
    currentStageColor: currentStage?.colorHex ?? null,
    status: e.status,
    valueAmount,
    valueCurrency: e.value_currency,
    probabilityPct,
    weightedAmount: computeWeightedAmount(valueAmount, probabilityPct),
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
 * 3. fetchPartyEngagements — 한 party 의 모든 engagement
 *    Stage 26 이후 meeting-create-modal engagement selector 용.
 *    Soft-deleted / archived 제외, updated_at desc.
 * ============================================================ */

export async function fetchPartyEngagements(
  partyId: string,
): Promise<KanbanCard[]> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('urm')
    .from('deals' as never)
    .select(DEAL_LIST_SELECT)
    .eq('party_id', partyId)
    .neq('status', 'archived')
    .is('deleted_at', null)
    .order('updated_at', { ascending: false });

  const rows = (data ?? []) as unknown as RawEngagementListRow[];
  return rows.map(mapCard);
}
