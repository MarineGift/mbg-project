/**
 * lib/email/auto-send-gate.ts
 *
 * AI       .
 *     reasons[]   allowed=false.
 *
 *   ( 4.4 +  7.3):
 *   [1]  (env.AI_AUTO_SEND_ENABLED)
 *   [2] auto_send_rules   (carriercategory)
 *   [3] rule.is_blocked
 *   [4] rule.allowed_modules module  
 *   [5] classification.confidence  rule.min_confidence
 *   [6] rule.requires_human_approval  classification.requiresHuman
 *   [7] classification.riskFlags 
 *   [8] blocked_keywords_in_body   
 *   [9] daily_limit / hourly_limit / per_party_daily_limit 
 *  [10] rule.requires_calendar_data     (meeting_scheduling)
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import type { AutoSendRuleRow, PartyTypeCode } from '../../types/ai';
import type { ClassificationOutput } from '../../types/classification';

/* ============================================================
 * 1.  
 * ============================================================ */

export interface GateInput {
  organizationId: string;
  partyType?: PartyTypeCode;
  partyId?: string;
  classification: ClassificationOutput;
  draftBody: string;
  /**       ( ). */
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
  /**    ID(). */
  ruleId?: string;
  /**   . */
  evaluationLog: Record<string, unknown>;
}

/* ============================================================
 * 2.  
 * ============================================================ */

export async function evaluateAutoSend(
  supabase: SupabaseClient,
  input: GateInput,
): Promise<GateResult> {
  const reasons: GateBlockReason[] = [];
  const log: Record<string, unknown> = {};

  // [1]  
  if (!env.AI_AUTO_SEND_ENABLED) {
    return {
      allowed: false,
      reasons: ['global_disabled'],
      evaluationLog: { step: 'global_flag', value: false },
    };
  }

  // [2]  
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
  if (input.partyType) {
    const allowed = rule.allowedModules ?? [];
    if (allowed.length === 0 || !allowed.includes(input.partyType)) {
      reasons.push('module_not_allowed');
      log.module_check = {
        allowedModules: allowed,
        requestedModule: input.partyType,
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

  // [10] calendar (meeting_scheduling   )
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
 * 3.  
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
    allowedModules: (data.allowed_modules as PartyTypeCode[] | null) ?? [],
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
 * 4.  
 * ============================================================ */

/**
 *          .
 *     (   substring fallback).
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
      //      substring
      matched = body.toLowerCase().includes(kw.toLowerCase());
    }
    if (matched) return kw;
  }
  return null;
}

/* ============================================================
 * 5. Sending limit 
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

  //     communications 
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

  //  
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

  //  24 
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
  // ai_generated=true  (external_data.auto_send=true)  
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
    return Number.MAX_SAFE_INTEGER; // :     
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
 * 6. Calendar 
 * ----------------------------------------------------------
 *   google calendar / outlook     .
 *  STEP 3 organization_settings.calendar_connected  .
 *     .
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
