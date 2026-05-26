'use server'
// src/lib/actions/meeting-form.ts
//
// Stage 26 (2026-05-21):
// meeting-create-modal 의 cascading selector (party → engagement → stage)
// 가 client component 의 useEffect 안에서 호출하는 server-only read API
// 를 안전하게 marshalling 하기 위한 server action wrapper.
//
// queries/engagements.ts 와 queries/pipelines.ts 의 함수는 내부적으로
// createSupabaseServerClient() (cookies() 의존) 를 호출하므로 client 에서
// 직접 import 하면 RSC boundary 위반. 본 file 의 'use server' 함수는
// Next.js 의 server action protocol 로 client → server marshalling 을 처리.
//
// Stage 25 의 queries/* 단일 source 원칙 유지 — 본 file 은 그 함수들의
// 진입점 (entry shim) 만 제공하고 logic 은 위임.

import { fetchPartyEngagements } from '@/lib/queries/engagements'
import { fetchStages } from '@/lib/queries/pipelines'
import type { KanbanCard, KanbanStage } from '@/types/engagement'

/**
 * party 선택 시 호출 — 해당 party 의 active engagement 후보 로드.
 *
 * fetchPartyEngagements 는 archived 만 제외하므로 won/lost 도 포함됨.
 * Client (modal) 에서 status 로 filter (active = open/in_progress/on_hold).
 */
export async function loadPartyEngagementsForForm(
  partyId: string,
): Promise<KanbanCard[]> {
  return fetchPartyEngagements(partyId)
}

/**
 * engagement 선택 시 호출 — engagement 의 pipeline 의 모든 stage 로드.
 *
 * pipelineDefinitionId 는 KanbanCard 의 신규 필드 (Stage 26 에서 추가).
 * engagement 가 pipeline 미지정인 경우 (legacy) 빈 배열 반환은 caller 가 처리.
 */
export async function loadStagesForForm(
  pipelineDefinitionId: string,
): Promise<KanbanStage[]> {
  return fetchStages(pipelineDefinitionId)
}
