/**
 * lib/queries/engagements.ts
 *
 * Read API for Engagement Kanban + detail + party-scoped list.
 *
 * URM cutover (Stage 29-c, 2026-05-25):
 *   - app.engagements → urm.deals (atomic cutover)
 *   - the parties join also targets urm.parties (FK target)
 *   - module info is looked up from urm.party_types.code (urm.parties.party_type_id)
 *
 * Absorbs URM schema differences:
 *   - app.engagements.name → urm.deals.deal_name
 *   - app.engagements.pipeline_definition_id → urm.deals.pipeline_id
 *   - app.engagements.partyType removed -> inferred from urm.parties.party_type_id
 *   - app.engagements.weighted_amount removed -> computed on the client
 *     (value_amount * probability_pct / 100)
 *   - organization_id filter removed (assumes RLS)
 *
 * Domain types (KanbanCard, EngagementDetail) are kept as-is.
 * The mapping layer handles column renames and derived fields.
 *
 * Responsibilities:
 *   1. fetchKanbanBoard      <- Kanban board per module
 *   2. fetchEngagementDetail <- one engagement + pipeline + stages + history
 *   3. fetchPartyEngagements <- all engagements of a party (for the selector)
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
  party_name: string;
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
 * SELECT clause for Kanban / list.
 *
 * Written with urm.deals column names. The parties join brings in name + party_type_id.
 * party_type_id is converted to PartyTypeCode in the mapping step.
 */
const DEAL_LIST_SELECT = `
  id, deal_name, status, current_stage_id, pipeline_id, party_id,
  value_amount, value_currency, probability_pct,
  expected_close_date, owner_user_id, updated_at,
  parties:party_id ( party_name, party_type_id )
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
 * urm.parties.party_type_id (smallint) -> PartyTypeCode conversion.
 *
 * Steps:
 *   1. id → PartyTypeCode (PARTY_TYPE_CODE_BY_ID)
 *   2. PartyTypeCode → PartyTypeCode (partyTypeToModule)
 *   3. fallback: 'investor' (default safe value)
 *
 * NOTE: when PartyTypeCode is 'buyer' or 'government_grant', partyTypeToModule
 *       returns null -> 'investor' fallback. Later, when the domain type is
 *       renamed to PartyTypeCode, remove the fallback.
 */
function partyTypeIdToModule(
  partyTypeId: number | null | undefined,
): PartyTypeCode {
  if (partyTypeId == null) return 'investor';
  const code: PartyTypeCode | undefined = PARTY_TYPE_CODE_BY_ID[partyTypeId];
  if (!code) return 'investor';
  return (code ?? 'investor') as PartyTypeCode;
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
    partyName: party?.party_name ?? '(unknown party)',
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
 * 1. fetchKanbanBoard - Kanban board per module
 *
 * NOTE: urm has no module separation, so the module argument is only used for fetchPipelineForModule
 *       and board metadata display. Every module sees the same default
 *       pipeline + same stages + same cards.
 *
 *       If per-module card separation is needed, a party_type_id-based filter
 *       must be added at the SELECT step (P2b/c territory).
 * ============================================================ */

export async function fetchKanbanBoard(
  partyType: PartyTypeCode,
): Promise<KanbanBoard> {
  const pipeline = await fetchPipelineForModule(partyType);

  if (!pipeline) {
    return {
      partyType: partyType as never,
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
      .schema('app')
      .from('deals' as never)
      .select(DEAL_LIST_SELECT, { count: 'exact' })
      .neq('status', 'archived')
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(500),
  ]);

  const rawCards = (cardsRes.data ?? []) as unknown as RawEngagementListRow[];
  const cards = rawCards.map(mapCard);

  // group by stage_id
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
    partyType: partyType as never,
    pipelineDefinitionId: pipeline.id,
    pipelineName: pipeline.name,
    stages,
    cardsByStage,
    uncategorizedCards,
    totalCount: cardsRes.count ?? cards.length,
  };
}

/* ============================================================
 * 2. fetchEngagementDetail - one engagement + pipeline + stages + history
 * ============================================================ */

export async function fetchEngagementDetail(
  engagementId: string,
): Promise<EngagementDetail | null> {
  const supabase = await createSupabaseServerClient();

  const { data: rawDetail, error } = await supabase
    .schema('app')
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

  // fetch party + contact + pipeline + stages + history in parallel
  const [partyRes, contactRes, pipeline, availableStages, stageHistory] =
    await Promise.all([
      supabase
        .schema('app')
        .from('parties' as never)
        .select('id, party_name, party_type_id')
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

      e.pipeline_id
        ? fetchPipelineById(e.pipeline_id)
        : Promise.resolve(null),

      e.pipeline_id
        ? fetchStages(e.pipeline_id)
        : Promise.resolve([] as never[]),

      fetchStageHistory(engagementId, e.pipeline_id, 50),
    ]);

  const party = partyRes?.data as
    | { id: string; party_name: string; party_type_id: number | null }
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
    // organization_id is absent in urm.deals -> empty string (domain type compatibility)
    organizationId: '',
    partyId: e.party_id,
    partyName: party?.party_name ?? '(unknown party)',
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
 * 3. fetchPartyEngagements - all engagements of a party
 *    For the meeting-create-modal engagement selector since Stage 26.
 *    Excludes soft-deleted / archived, updated_at desc.
 * ============================================================ */

export async function fetchPartyEngagements(
  partyId: string,
): Promise<KanbanCard[]> {
  const supabase = await createSupabaseServerClient();

  const { data } = await supabase
    .schema('app')
    .from('deals' as never)
    .select(DEAL_LIST_SELECT)
    .eq('party_id', partyId)
    .neq('status', 'archived')
    .is('deleted_at', null)
    .order('updated_at', { ascending: false });

  const rows = (data ?? []) as unknown as RawEngagementListRow[];
  return rows.map(mapCard);
}
