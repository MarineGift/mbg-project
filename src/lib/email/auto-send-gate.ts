/**
 * lib/email/auto-send-gate.ts
 *
 * AI가 생성한 회신 초안의 자동발송 가능 여부를 평가한다.
 * 어느 단계든 통과하지 못하면 reasons[]에 사유를 누적하고 allowed=false.
 *
 * 평가 순서 (마스터 §4.4 + 가이드 §7.3):
 *   [1] 글로벌 플래그(env.AI_AUTO_SEND_ENABLED)
 *   [2] auto_send_rules 행 조회 (carrier×category)
 *   [3] rule.is_blocked
 *   [4] rule.allowed_modules에 module 포함 여부
 *   [5] classification.confidence ≥ rule.min_confidence
 *   [6] rule.requires_human_approval 또는 classification.requiresHuman
 *   [7] classification.riskFlags 비어있음
 *   [8] blocked_keywords_in_body 정규식 매칭 없음
 *   [9] daily_limit / hourly_limit / per_party_daily_limit 미달성
 *  [10] rule.requires_calendar_data 시 미팅 가용성 확인 (meeting_scheduling)
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import type { AutoSendRuleRow, ModuleType } from '../../types/ai';
import type { ClassificationOutput } from '../../types/classification';

/* ============================================================
 * 1. 입출력 타입
 * ============================================================ */

export interface GateInput {
  organizationId: string;
  module?: ModuleType;
  partyId?: string;
  classification: ClassificationOutput;
  draftBody: string;
  /** 회신가가 자체 판단한 사람 검토 필요 플래그(별도 강제). */
  drafterRequiresHuman?: boolean;
}

export type GateBlockReason =
  | 'global_disabled'
  | 'rule_lookup_error'
  | 'no_rule_defined'
  | 'rule_blocked'
  | 'module_not_allowed'
  | 'confidence_below_threshold'
  | 'requires_human_approval'
  | 'drafter_requires_human'
  | 'risk_flags_present'
  | `blocked_keyword:${string}`
  | 'daily_limit_reached'
  | 'hourly_limit_reached'
  | 'per_party_daily_limit_reached'
  | 'calendar_data_required';

export interface GateResult {
  allowed: boolean;
  reasons: GateBlockReason[];
  /** 차단을 트리거한 룰 ID(있으면). */
  ruleId?: string;
  /** 디버깅·감사용 평가 로그. */
  evaluationLog: Record<string, unknown>;
}

/* ============================================================
 * 2. 메인 진입점
 * ============================================================ */

export async function evaluateAutoSend(
  supabase: SupabaseClient,
  input: GateInput,
): Promise<GateResult> {
  const reasons: GateBlockReason[] = [];
  const log: Record<string, unknown> = {};

  // [1] 글로벌 플래그
  if (!env.AI_AUTO_SEND_ENABLED) {
    return {
      allowed: false,
      reasons: ['global_disabled'],
      evaluationLog: { step: 'global_flag', value: false },
    };
  }

  // [2] 룰 조회
  const rule = await loadAutoSendRule(
    supabase,
    input.organizationId,
    input.classification.category,
  );

  if (rule === 'error') {
    return {
      allowed: false,
      reasons: ['rule_lookup_error'],
      evaluationLog: { step: 'rule_lookup', value: 'error' },
    };
  }
  if (!rule) {
    return {
      allowed: false,
      reasons: ['no_rule_defined'],
      evaluationLog: {
        step: 'rule_lookup',
        category: input.classification.category,
      },
    };
  }
  log.rule_id = rule.id;

  // [3] is_blocked
  if (rule.isBlocked) {
    reasons.push('rule_blocked');
    log.is_blocked = true;
  }

  // [4] applicable_modules
  if (input.module) {
    const allowed = rule.allowedModules ?? [];
    if (allowed.length === 0 || !allowed.includes(input.module)) {
      reasons.push('module_not_allowed');
      log.module_check = {
        allowedModules: allowed,
        requestedModule: input.module,
      };
    }
  }

  // [5] min_confidence
  if (input.classification.confidence < rule.minConfidence) {
    reasons.push('confidence_below_threshold');
    log.confidence_check = {
      observed: input.classification.confidence,
      required: rule.minConfidence,
    };
  }

  // [6] human approval
  if (rule.requiresHumanApproval || input.classification.requiresHuman) {
    reasons.push('requires_human_approval');
    log.human_required = {
      from_rule: rule.requiresHumanApproval,
      from_classification: input.classification.requiresHuman,
    };
  }
  if (input.drafterRequiresHuman) {
    reasons.push('drafter_requires_human');
    log.drafter_requires_human = true;
  }

  // [7] risk_flags
  if (input.classification.riskFlags.length > 0) {
    reasons.push('risk_flags_present');
    log.risk_flags = input.classification.riskFlags;
  }

  // [8] blocked_keywords_in_body
  const matchedKw = matchBlockedKeyword(
    input.draftBody,
    rule.blockedKeywordsInBody ?? [],
  );
  if (matchedKw) {
    reasons.push(`blocked_keyword:${matchedKw}`);
    log.blocked_keyword_matched = matchedKw;
  }

  // [9] limits
  const limitVerdict = await checkSendingLimits(
    supabase,
    input.organizationId,
    input.partyId,
    rule,
  );
  if (limitVerdict.reasons.length > 0) {
    reasons.push(...limitVerdict.reasons);
    Object.assign(log, limitVerdict.log);
  }

  // [10] calendar (meeting_scheduling 카테고리만 의미 있음)
  if (
    rule.requiresCalendarData &&
    input.classification.category === 'meeting_scheduling'
  ) {
    const hasCalendar = await hasCalendarAvailability(
      supabase,
      input.organizationId,
    );
    if (!hasCalendar) {
      reasons.push('calendar_data_required');
      log.calendar_check = { available: false };
    }
  }

  return {
    allowed: reasons.length === 0,
    reasons,
    ruleId: rule.id,
    evaluationLog: log,
  };
}

/* ============================================================
 * 3. 룰 조회
 * ============================================================ */

async function loadAutoSendRule(
  supabase: SupabaseClient,
  organizationId: string,
  category: ClassificationOutput['category'],
): Promise<AutoSendRuleRow | null | 'error'> {
  const { data, error } = await supabase
    .schema('ai')
    .from('auto_send_rules')
    .select(
      'id, organization_id, classification_category, is_blocked, block_reason, min_confidence, requires_human_approval, allowed_modules, blocked_keywords_in_body, daily_limit, hourly_limit, per_party_daily_limit, requires_calendar_data, is_active',
    )
    .eq('organization_id', organizationId)
    .eq('classification_category', category)
    .eq('is_active', true)
    .maybeSingle();

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[auto-send-gate] rule lookup error:', error);
    return 'error';
  }
  if (!data) return null;

  return {
    id: data.id as string,
    organizationId: data.organization_id as string,
    classificationCategory: data.classification_category as AutoSendRuleRow['classificationCategory'],
    isBlocked: Boolean(data.is_blocked),
    blockReason: (data.block_reason as string | null) ?? undefined,
    minConfidence: Number(data.min_confidence ?? 0.95),
    requiresHumanApproval: Boolean(data.requires_human_approval),
    allowedModules: (data.allowed_modules as ModuleType[] | null) ?? [],
    blockedKeywordsInBody:
      (data.blocked_keywords_in_body as string[] | null) ?? [],
    dailyLimit: Number(data.daily_limit ?? 0),
    hourlyLimit: Number(data.hourly_limit ?? 0),
    perPartyDailyLimit: Number(data.per_party_daily_limit ?? 0),
    requiresCalendarData: Boolean(data.requires_calendar_data),
    isActive: Boolean(data.is_active),
  };
}

/* ============================================================
 * 4. 키워드 매칭
 * ============================================================ */

/**
 * 차단 키워드 배열 중 회신 본문에 매칭되는 첫 항목을 반환.
 * 각 키워드는 정규식으로 시도 (잘못된 정규식은 단순 substring으로 fallback).
 */
export function matchBlockedKeyword(
  body: string,
  keywords: string[],
): string | null {
  for (const kw of keywords) {
    if (!kw) continue;
    let matched = false;
    try {
      const regex = new RegExp(kw, 'i');
      matched = regex.test(body);
    } catch {
      // 잘못된 정규식 → 대소문자 무시 substring
      matched = body.toLowerCase().includes(kw.toLowerCase());
    }
    if (matched) return kw;
  }
  return null;
}

/* ============================================================
 * 5. Sending limit 검증
 * ============================================================ */

interface LimitVerdict {
  reasons: GateBlockReason[];
  log: Record<string, unknown>;
}

async function checkSendingLimits(
  supabase: SupabaseClient,
  organizationId: string,
  partyId: string | undefined,
  rule: AutoSendRuleRow,
): Promise<LimitVerdict> {
  const reasons: GateBlockReason[] = [];
  const log: Record<string, unknown> = {};

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const oneHourAgo = new Date(Date.now() - 3_600_000);

  // 일일 한도 — 자동발송된 communications 카운트
  if (rule.dailyLimit > 0) {
    const dailyCount = await countAutoSent(
      supabase,
      organizationId,
      startOfDay.toISOString(),
    );
    log.daily = { observed: dailyCount, limit: rule.dailyLimit };
    if (dailyCount >= rule.dailyLimit) {
      reasons.push('daily_limit_reached');
    }
  }

  // 시간당 한도
  if (rule.hourlyLimit > 0) {
    const hourCount = await countAutoSent(
      supabase,
      organizationId,
      oneHourAgo.toISOString(),
    );
    log.hourly = { observed: hourCount, limit: rule.hourlyLimit };
    if (hourCount >= rule.hourlyLimit) {
      reasons.push('hourly_limit_reached');
    }
  }

  // 거래처별 24시간 한도
  if (rule.perPartyDailyLimit > 0 && partyId) {
    const partyCount = await countAutoSentForParty(
      supabase,
      organizationId,
      partyId,
      new Date(Date.now() - 24 * 3_600_000).toISOString(),
    );
    log.per_party_daily = {
      observed: partyCount,
      limit: rule.perPartyDailyLimit,
    };
    if (partyCount >= rule.perPartyDailyLimit) {
      reasons.push('per_party_daily_limit_reached');
    }
  }

  return { reasons, log };
}

async function countAutoSent(
  supabase: SupabaseClient,
  organizationId: string,
  sinceIso: string,
): Promise<number> {
  // ai_generated=true 이고 자동발송된(external_data.auto_send=true) 메일만 카운트
  const { count, error } = await supabase
    .schema('app')
    .from('communications')
    .select('id', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .eq('direction', 'outbound')
    .eq('channel', 'email')
    .eq('ai_generated', true)
    .contains('external_data', { auto_send: true })
    .gte('sent_at', sinceIso);

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[auto-send-gate.countAutoSent]', error);
    return Number.MAX_SAFE_INTEGER; // 보수적: 실패 시 한도 초과로 간주
  }
  return count ?? 0;
}

async function countAutoSentForParty(
  supabase: SupabaseClient,
  organizationId: string,
  partyId: string,
  sinceIso: string,
): Promise<number> {
  const { count, error } = await supabase
    .schema('app')
    .from('communications')
    .select('id', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .eq('party_id', partyId)
    .eq('direction', 'outbound')
    .eq('channel', 'email')
    .eq('ai_generated', true)
    .contains('external_data', { auto_send: true })
    .gte('sent_at', sinceIso);

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[auto-send-gate.countAutoSentForParty]', error);
    return Number.MAX_SAFE_INTEGER;
  }
  return count ?? 0;
}

/* ============================================================
 * 6. Calendar 가용성
 * ----------------------------------------------------------
 * 운영 시점에 google calendar / outlook 통합 후 정확한 가용성 평가.
 * 본 STEP 3에서는 organization_settings.calendar_connected 플래그만 확인.
 * 미연결이면 미팅 자동 회신 차단.
 * ============================================================ */
async function hasCalendarAvailability(
  supabase: SupabaseClient,
  organizationId: string,
): Promise<boolean> {
  const { data } = await supabase
    .schema('app')
    .from('organizations')
    .select('settings')
    .eq('id', organizationId)
    .maybeSingle();

  if (!data) return false;
  const settings = (data.settings ?? {}) as Record<string, unknown>;
  return Boolean(settings.calendar_connected);
}
