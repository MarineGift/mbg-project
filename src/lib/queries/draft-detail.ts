/**
 * lib/queries/draft-detail.ts
 *
 * 단일 ai.drafts 행과 모든 관련 데이터를 fetch.
 *
 * 조인 대상:
 *   - inbound communications (원본 메일)
 *   - parties / engagements
 *   - classifier_run + drafter_run (ai.runs 두 행)
 *   - auto_send_rule (적용된 규칙)
 *
 * RLS가 자동 격리. 다른 조직 draft 요청 시 null 반환 (404 처리는 호출자).
 */

import 'server-only';
import { PARTY_TYPE_CODE_BY_ID, partyTypeToModule } from '@/types/party-type';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type {
  ClassificationCategory,
  DraftStatus,
  Language,
  PartyTypeCode,
} from '@/types/ai';
import type {
  DraftAutoSendInfo,
  DraftDetail,
  DraftEngagementSummary,
  DraftInboundSummary,
  DraftPartySummary,
  DraftRunSummary,
} from '@/types/draft-detail';

interface RawDraftRow {
  id: string;
  organization_id: string;
  status: DraftStatus;
  module: PartyTypeCode | null;
  language: Language;
  classification_category: ClassificationCategory | null;
  confidence_score: number | null;
  risk_flags: string[] | null;
  requires_human_approval: boolean;
  rationale: string | null;
  subject: string | null;
  body_plain: string;
  body_html: string | null;
  final_subject: string | null;
  final_body_plain: string | null;
  edit_distance: number | null;
  reviewed_by_user_id: string | null;
  reviewed_at: string | null;
  review_notes: string | null;
  expires_at: string;
  expired_handled: boolean;
  sent_communication_id: string | null;
  ai_generated: boolean;
  created_at: string;
  updated_at: string;
  party_id: string | null;
  engagement_id: string | null;
  inbound_communication_id: string | null;
  classifier_run_id: string | null;
  drafter_run_id: string | null;
  auto_send_eligible: boolean;
  auto_send_blocked_reasons: string[] | null;
  auto_send_rule_id: string | null;
  auto_send_evaluation_log: Record<string, unknown> | null;
}

export async function fetchDraftDetail(
  draftId: string,
): Promise<DraftDetail | null> {
  const supabase = await createSupabaseServerClient();

  // [1] draft 본체 — stub 캐스트로 컬럼 직접 select
  const { data: draftRaw, error: draftErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .select('*')
    .eq('id', draftId)
    .maybeSingle();

  if (draftErr || !draftRaw) {
    // RLS 차단 또는 미존재
    return null;
  }
  const d = draftRaw as unknown as RawDraftRow;

  // [2] 관련 객체들 — 병렬 fetch
  const [
    inboundData,
    partyData,
    engagementData,
    classifierRunData,
    drafterRunData,
    autoSendRuleData,
  ] = await Promise.all([
    d.inbound_communication_id
      ? supabase
          .schema('app')
          .from('communications' as never)
          .select(
            'id, from_address, from_name, to_addresses, cc_addresses, subject, body_plain, body_html, occurred_at, message_id, thread_id, in_reply_to, channel',
          )
          .eq('id', d.inbound_communication_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    d.party_id
      ? supabase
          .schema('app')
          .from('parties' as never)
          .select('id, name, module, tier, country_code, website')
          .eq('id', d.party_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    d.engagement_id
      ? supabase
          .schema('urm')
          .from('deals' as never)
          .select(
            'id, deal_name, status, value_amount, value_currency, parties:party_id ( party_type_id )',
          )
          .eq('id', d.engagement_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    d.classifier_run_id
      ? supabase
          .schema('ai')
          .from('runs' as never)
          .select(
            'id, model_used, input_tokens, output_tokens, cost_usd, latency_ms, status, started_at, completed_at, metadata',
          )
          .eq('id', d.classifier_run_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    d.drafter_run_id
      ? supabase
          .schema('ai')
          .from('runs' as never)
          .select(
            'id, model_used, input_tokens, output_tokens, cost_usd, latency_ms, status, started_at, completed_at, metadata',
          )
          .eq('id', d.drafter_run_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),

    d.auto_send_rule_id
      ? supabase
          .schema('ai')
          .from('auto_send_rules' as never)
          .select(
            'classification_category, min_confidence, requires_human_approval, is_blocked, block_reason, is_active',
          )
          .eq('id', d.auto_send_rule_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
  ]);

  const inbound = mapInbound(inboundData?.data as unknown);
  const party = mapParty(partyData?.data as unknown);
  const engagement = mapEngagement(engagementData?.data as unknown);
  const classifierRun = mapRun(classifierRunData?.data as unknown);
  const drafterRun = mapRun(drafterRunData?.data as unknown);

  const autoSend: DraftAutoSendInfo = {
    eligible: d.auto_send_eligible,
    blockedReasons: d.auto_send_blocked_reasons ?? [],
    ruleId: d.auto_send_rule_id,
    evaluationLog: d.auto_send_evaluation_log ?? {},
    rule: mapAutoSendRule(autoSendRuleData?.data as unknown),
  };

  return {
    id: d.id,
    organizationId: d.organization_id,
    status: d.status,
    module: d.module,
    language: d.language,
    classificationCategory: d.classification_category,
    confidenceScore: d.confidence_score,
    riskFlags: d.risk_flags ?? [],
    requiresHumanApproval: d.requires_human_approval,
    rationale: d.rationale,
    subject: d.subject,
    bodyPlain: d.body_plain,
    bodyHtml: d.body_html,
    finalSubject: d.final_subject,
    finalBodyPlain: d.final_body_plain,
    editDistance: d.edit_distance,
    reviewedByUserId: d.reviewed_by_user_id,
    reviewedAt: d.reviewed_at,
    reviewNotes: d.review_notes,
    expiresAt: d.expires_at,
    expiredHandled: d.expired_handled,
    sentCommunicationId: d.sent_communication_id,
    aiGenerated: d.ai_generated,
    createdAt: d.created_at,
    updatedAt: d.updated_at,
    inbound,
    party,
    engagement,
    classifierRun,
    drafterRun,
    autoSend,
  };
}

/* ============================================================
 * 매퍼들 — raw row를 도메인 타입으로 변환
 * ============================================================ */

function mapInbound(raw: unknown): DraftInboundSummary | null {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    fromAddress: (r.from_address as string | null) ?? null,
    fromName: (r.from_name as string | null) ?? null,
    toAddresses: (r.to_addresses as string[] | null) ?? [],
    ccAddresses: (r.cc_addresses as string[] | null) ?? [],
    subject: (r.subject as string | null) ?? null,
    bodyPlain: (r.body_plain as string | null) ?? null,
    bodyHtml: (r.body_html as string | null) ?? null,
    occurredAt: r.occurred_at as string,
    messageId: (r.message_id as string | null) ?? null,
    threadId: (r.thread_id as string | null) ?? null,
    inReplyTo: (r.in_reply_to as string | null) ?? null,
    channel: (r.channel as string) ?? 'email',
  };
}

function mapParty(raw: unknown): DraftPartySummary | null {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    name: (r.name as string) ?? '',
    module: r.module as PartyTypeCode,
    tier: (r.tier as string | null) ?? null,
    countryCode: (r.country_code as string | null) ?? null,
    website: (r.website as string | null) ?? null,
  };
}

function mapEngagement(raw: unknown): DraftEngagementSummary | null {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  // urm.deals ??module ?놁쓬 - parties join ??party_type_id 濡?derive.
  const partyJoin = r.parties as
    | { party_type_id?: number | null }
    | Array<{ party_type_id?: number | null }>
    | null
    | undefined;
  const party = Array.isArray(partyJoin) ? partyJoin[0] : partyJoin;
  const partyTypeId = party?.party_type_id ?? null;
  const code = partyTypeId != null ? PARTY_TYPE_CODE_BY_ID[partyTypeId] : null;
  const moduleValue: PartyTypeCode =
    (code ? (partyTypeToModule(code) ?? 'investor') : 'investor') as PartyTypeCode;
  return {
    id: r.id as string,
    name: (r.deal_name as string) ?? '',
    module: moduleValue,
    status: (r.status as string) ?? 'open',
    valueAmount:
      typeof r.value_amount === 'number'
        ? r.value_amount
        : r.value_amount != null
          ? Number(r.value_amount)
          : null,
    valueCurrency: (r.value_currency as string) ?? 'USD',
  };
}

function mapRun(raw: unknown): DraftRunSummary | null {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    modelUsed: (r.model_used as string) ?? '',
    inputTokens: (r.input_tokens as number | null) ?? null,
    outputTokens: (r.output_tokens as number | null) ?? null,
    costUsd:
      typeof r.cost_usd === 'number'
        ? r.cost_usd
        : Number(r.cost_usd ?? 0),
    latencyMs: (r.latency_ms as number | null) ?? null,
    status: (r.status as string) ?? '',
    startedAt: r.started_at as string,
    completedAt: (r.completed_at as string | null) ?? null,
    metadata: (r.metadata as Record<string, unknown>) ?? {},
  };
}

function mapAutoSendRule(
  raw: unknown,
): DraftAutoSendInfo['rule'] {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  return {
    classificationCategory: (r.classification_category as string) ?? '',
    minConfidence: Number(r.min_confidence ?? 0),
    requiresHumanApproval:
      (r.requires_human_approval as boolean | null) ?? true,
    isBlocked: (r.is_blocked as boolean | null) ?? false,
    blockReason: (r.block_reason as string | null) ?? null,
    isActive: (r.is_active as boolean | null) ?? false,
  };
}
