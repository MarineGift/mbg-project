/**
 * lib/queries/engagements.ts
 *
 * Read API for the party-scoped engagement selector.
 *
 * 2026-06-02 (Engagements feature retirement):
 *   The Engagement Kanban board + detail screens were removed. fetchKanbanBoard
 *   and fetchEngagementDetail are gone. Only fetchPartyEngagements remains -- it
 *   backs the meeting-create-modal's party -> deal selector (via
 *   lib/actions/meeting-form.ts). It reads app.deals scoped to a party.
 *
 *   value_amount / value_currency are still selected here (the column lives on
 *   app.deals and is consumed elsewhere); weightedAmount is still derived for
 *   KanbanCard shape compatibility with the meeting selector.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { EngagementStatus, KanbanCard } from '@/types/engagement';
import { type PartyTypeCode } from '@/types/party-type';
import { fetchPartyTypeMaps } from '@/lib/party-type-maps';

/* ============================================================
 * Raw row types - app.deals + parties join
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

function partyTypeIdToModule(
  partyTypeId: number | null | undefined,
  idToCode: Record<number, string>,
): PartyTypeCode {
  if (partyTypeId == null) return 'investor';
  const code = idToCode[partyTypeId];
  if (!code) return 'investor';
  return code as PartyTypeCode;
}

function computeWeightedAmount(
  valueAmount: number | null,
  probabilityPct: number | null,
): number | null {
  if (valueAmount == null || probabilityPct == null) return null;
  return (valueAmount * probabilityPct) / 100;
}

function mapCard(r: RawEngagementListRow, idToCode: Record<number, string>): KanbanCard {
  const party = Array.isArray(r.parties) ? r.parties[0] : r.parties;
  const valueAmount = toNumberOrNull(r.value_amount);
  const probabilityPct = r.probability_pct ?? 0;
  return {
    id: r.id,
    name: r.deal_name,
    partyType: partyTypeIdToModule(party?.party_type_id ?? null, idToCode),
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
 * fetchPartyEngagements - all (non-archived) deals of a party.
 *   Used by meeting-create-modal's engagement selector (Stage 26).
 * ============================================================ */

export async function fetchPartyEngagements(
  partyId: string,
): Promise<KanbanCard[]> {
  const supabase = await createSupabaseServerClient();
  const { idToCode } = await fetchPartyTypeMaps(supabase);

  const { data } = await supabase
    .schema('app')
    .from('deals' as never)
    .select(DEAL_LIST_SELECT)
    .eq('party_id', partyId)
    .neq('status', 'archived')
    .is('deleted_at', null)
    .order('updated_at', { ascending: false });

  const rows = (data ?? []) as unknown as RawEngagementListRow[];
  return rows.map((r) => mapCard(r, idToCode));
}
