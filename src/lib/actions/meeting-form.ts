'use server'
// src/lib/actions/meeting-form.ts
//
// Stage 26 (2026-05-21):
// The cascading selector in meeting-create-modal (party -> engagement -> stage)
// calls server-only read APIs inside the client component's useEffect;
// this is a server action wrapper to marshal them safely.
//
// Functions in queries/engagements.ts and queries/pipelines.ts internally
// call createSupabaseServerClient() (depends on cookies()), so importing them
// directly from the client violates the RSC boundary. The 'use server' functions in this file
// handle client -> server marshalling via Next.js's server action protocol.
//
// Preserves Stage 25's queries/* single-source principle - this file provides only
// the entry point (entry shim) for those functions and delegates the logic.

import { fetchPartyEngagements } from '@/lib/queries/engagements'
import { fetchStages } from '@/lib/queries/pipelines'
import type { KanbanCard, KanbanStage } from '@/types/engagement'

/**
 * Called when a party is selected - loads active engagement candidates for that party.
 *
 * fetchPartyEngagements excludes only archived, so won/lost are included too.
 * The client (modal) filters by status (active = open/in_progress/on_hold).
 */
export async function loadPartyEngagementsForForm(
  partyId: string,
): Promise<KanbanCard[]> {
  return fetchPartyEngagements(partyId)
}

/**
 * Called when an engagement is selected - loads all stages of the engagement's pipeline.
 *
 * pipelineDefinitionId is a new field on KanbanCard (added in Stage 26).
 * If an engagement has no pipeline assigned (legacy), the caller handles the empty-array return.
 */
export async function loadStagesForForm(
  pipelineDefinitionId: string,
): Promise<KanbanStage[]> {
  return fetchStages(pipelineDefinitionId)
}
