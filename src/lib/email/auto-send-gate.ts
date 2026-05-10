import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import {
  STANDARD_CATEGORIES,
  AUTO_SEND_CANDIDATE_CATEGORIES,
  type ClassificationOutput,
  type StandardCategory,
} from '@/types/classification';
import type { ModuleType } from '@/types/email';

// ───────────────────────────────────────────────────────────────────
// 입출력
// ───────────────────────────────────────────────────────────────────

export interface GateInput {
  organizationId: string;
  partyId?: string;
  module?: ModuleType;
  classification: ClassificationOutput;
  draftBody: string;
  draftRequiresHuman: boolean;
  draftRiskFlags: string[];
}

export interface GateResult {
  allowed: boolean;
  reasons: string[];
  blockedRules: string[];
  evaluationLog: Record<string, unknown>;
}

export interface AutoSendRule {
  id: string;
  organizationId: string;
  classificationCategory: StandardCategory;
  isBlocked: boolean;
  blockReason?: string;
  allowedModules: string[];
  minConfidence: number;
  blockedKeywordsInBody: string[];
  dailyLimit?: number;
  hourlyLimit?: number;
  perPartyDailyLimit?: number;
  requiresCalendarData: boolean;
  requiresHumanApproval: boolean;
}

// ───────────────────────────────────────────────────────────────────
// 메인 평가 함수
// ───────────────────────────────────────────────────────────────────

export async function evaluateAutoSend(
  supabase: SupabaseClient,
  input: GateInput,
): Promise<GateResult> {
  const reasons: string[] = [];
  const blockedRules: string[] = [];
  const log: Record<string, unknown> = {};

  // [1] 글로벌 플래그
  if (!env.AI_AUTO_SEND_ENABLED) {
    return {
      allowed: false,
      reasons: ['global_disabled'],
      blockedRules: [],
      evaluationLog: { step: 'global_flag', value: false },
    };
  }

  // [2] 카테고리 후보 화이트리스트
  if (!STANDARD_CATEGORIES.includes(input.classification.category)) {
    return {
      allowed: false,
      reasons: ['non_standard_category'],
      blockedRules: [],
      evaluationLog: { step: 'category_check', value: input.classification.category },
    };
  }
  if (!AUTO_SEND_CANDIDATE_CATEGORIES.has(input.classification.category)) {
    reasons.push('category_not_eligible');
    log.category_eligibility = {
      category: input.classification.category,
      eligible: false,
    };
  }

  // [3] auto_send_rules 조회
  const rule = await loadRule(
    supabase,
    input.organizationId,
    input.classification.category,
  );
  log.rule_lookup = rule
    ? { rule_id: rule.id, found: true }
    : { found: false };

  if (!rule) {
    reasons.push('no_rule_defined');
    return {
      allowed: false,
      reasons,
      blockedRules,
      evaluationLog: log,
    };
  }

  // [4-1] is_blocked
  if (rule.isBlocked) {
    reasons.push('rule_blocked');
    blockedRules.push(rule.id);
    log.is_blocked = { reason: rule.blockReason ?? null };
  }

  // [4-2] 룰이 사람 검토 강제
  if (rule.requiresHumanApproval) {
    reasons.push('rule_requires_human');
    blockedRules.push(rule.id);
    log.rule_requires_human = true;
  }

  // [4-3] 분류기 self-flag
  if (input.classification.requiresHuman) {
    reasons.push('classifier_requires_human');
    log.classifier_requires_human = true;
  }

  // [4-4] Reply Drafter self-flag
  if (input.draftRequiresHuman) {
    reasons.push('draft_requires_human');
    log.draft_requires_human = true;
  }

  // [5-1] applicable_modules
  if (rule.allowedModules.length === 0) {
    reasons.push('no_module_whitelisted');
    log.module_check = { allowedModules: [], requestedModule: input.module ?? null };
  } else if (!input.module || !rule.allowedModules.includes(input.module)) {
    reasons.push('module_not_allowed');
    log.module_check = {
      allowedModules: rule.allowedModules,
      requestedModule: input.module ?? null,
    };
  }

  // [5-2] min_confidence
  if (input.classification.confidence < rule.minConfidence) {
    reasons.push('confidence_below_threshold');
    log.confidence_check = {
      observed: input.classification.confidence,
      required: rule.minConfidence,
    };
  }

  // [5-3] blocked_keywords
  const matchedKeywords = matchBlockedKeywords(
    input.draftBody,
    rule.blockedKeywordsInBody,
  );
  if (matchedKeywords.length > 0) {
    reasons.push('blocked_keyword_in_body');
    log.blocked_keywords = { matched: matchedKeywords };
  }

  // [5-4] risk_flags
  const sensitiveRiskFlags = filterSensitiveRiskFlags(input.draftRiskFlags);
  if (sensitiveRiskFlags.length > 0) {
    reasons.push('sensitive_risk_flag');
    log.sensitive_risk_flags = sensitiveRiskFlags;
  }

  // [6] 한도 체크
  const limitChecks = await checkLimits(
    supabase,
    input.organizationId,
    input.classification.category,
    input.partyId,
    rule,
  );
  if (limitChecks.dailyExceeded) {
    reasons.push('daily_limit_exceeded');
    log.daily_limit = { used: limitChecks.dailyCount, limit: rule.dailyLimit };
  }
  if (limitChecks.hourlyExceeded) {
    reasons.push('hourly_limit_exceeded');
    log.hourly_limit = { used: limitChecks.hourlyCount, limit: rule.hourlyLimit };
  }
  if (limitChecks.perPartyExceeded) {
    reasons.push('per_party_daily_limit_exceeded');
    log.per_party_limit = {
      used: limitChecks.perPartyCount,
      limit: rule.perPartyDailyLimit,
    };
  }

  // [7] requires_calendar_data
  if (rule.requiresCalendarData && input.classification.category === 'meeting_scheduling') {
    const hasCalendar = await checkCalendarAvailability(
      supabase,
      input.organizationId,
      input.partyId,
    );
    log.calendar_check = { hasCalendar };
    if (!hasCalendar) {
      reasons.push('calendar_data_unavailable');
    }
  }

  return {
    allowed: reasons.length === 0,
    reasons,
    blockedRules,
    evaluationLog: log,
  };
}

// ───────────────────────────────────────────────────────────────────
// 내부 — 룰 조회
// ───────────────────────────────────────────────────────────────────

async function loadRule(
  supabase: SupabaseClient,
  organizationId: string,
  category: StandardCategory,
): Promise<AutoSendRule | null> {
  const { data, error } = await supabase
    .schema('ai')
    .from('auto_send_rules')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('classification_category', category)
    .maybeSingle();

  if (error || !data) return null;
  return toAutoSendRule(data as Record<string, unknown>);
}

function toAutoSendRule(r: Record<string, unknown>): AutoSendRule {
  const cat = r.classification_category;
  if (!STANDARD_CATEGORIES.includes(cat as StandardCategory)) {
    throw new Error(
      `auto_send_rules contains non-standard category: ${String(cat)} (id=${String(r.id)})`,
    );
  }
  return {
    id: String(r.id),
    organizationId: String(r.organization_id),
    classificationCategory: cat as StandardCategory,
    isBlocked: r.is_blocked === true,
    blockReason: typeof r.block_reason === 'string' ? r.block_reason : undefined,
    allowedModules: Array.isArray(r.allowed_modules) ? (r.allowed_modules as string[]) : [],
    minConfidence: Number(r.min_confidence ?? 0.95),
    blockedKeywordsInBody: Array.isArray(r.blocked_keywords_in_body)
      ? (r.blocked_keywords_in_body as string[])
      : [],
    dailyLimit:
      r.daily_limit === null || r.daily_limit === undefined
        ? undefined
        : Number(r.daily_limit),
    hourlyLimit:
      r.hourly_limit === null || r.hourly_limit === undefined
        ? undefined
        : Number(r.hourly_limit),
    perPartyDailyLimit:
      r.per_party_daily_limit === null || r.per_party_daily_limit === undefined
        ? undefined
        : Number(r.per_party_daily_limit),
    requiresCalendarData: r.requires_calendar_data === true,
    requiresHumanApproval: r.requires_human_approval === true,
  };
}

// ───────────────────────────────────────────────────────────────────
// 내부 — 키워드 / risk_flag
// ───────────────────────────────────────────────────────────────────

export function matchBlockedKeywords(body: string, keywords: string[]): string[] {
  if (!body || keywords.length === 0) return [];
  const lower = body.toLowerCase();
  const matched: string[] = [];
  for (const kw of keywords) {
    const k = kw.trim();
    if (k.length === 0) continue;
    if (lower.includes(k.toLowerCase())) {
      matched.push(kw);
    }
  }
  return matched;
}

const SENSITIVE_RISK_FLAGS: ReadonlySet<string> = new Set([
  'price_commitment_required',
  'legal_terms_present',
  'contract_amendment_requested',
  'sensitive_personal_info',
  'regulated_industry_topic',
  'compliance_flag',
  'jurisdiction_uncertainty',
]);

export function filterSensitiveRiskFlags(flags: string[]): string[] {
  return flags.filter((f) => SENSITIVE_RISK_FLAGS.has(f));
}

// ───────────────────────────────────────────────────────────────────
// 내부 — 한도 체크
// ───────────────────────────────────────────────────────────────────

interface LimitCheckResult {
  dailyCount: number;
  hourlyCount: number;
  perPartyCount: number;
  dailyExceeded: boolean;
  hourlyExceeded: boolean;
  perPartyExceeded: boolean;
}

async function checkLimits(
  supabase: SupabaseClient,
  organizationId: string,
  category: StandardCategory,
  partyId: string | undefined,
  rule: AutoSendRule,
): Promise<LimitCheckResult> {
  const now = Date.now();
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const oneHourAgo = new Date(now - 60 * 60 * 1000);

  let dailyCount = 0;
  if (rule.dailyLimit !== undefined) {
    const { count } = await supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('direction', 'outbound')
      .eq('ai_generated', true)
      .filter('external_data->>auto_sent', 'eq', 'true')
      .filter('ai_classification->>category', 'eq', category)
      .gte('sent_at', startOfDay.toISOString());
    dailyCount = count ?? 0;
  }

  let hourlyCount = 0;
  if (rule.hourlyLimit !== undefined) {
    const { count } = await supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('direction', 'outbound')
      .eq('ai_generated', true)
      .filter('external_data->>auto_sent', 'eq', 'true')
      .filter('ai_classification->>category', 'eq', category)
      .gte('sent_at', oneHourAgo.toISOString());
    hourlyCount = count ?? 0;
  }

  let perPartyCount = 0;
  if (rule.perPartyDailyLimit !== undefined && partyId) {
    const { count } = await supabase
      .schema('app')
      .from('communications')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('party_id', partyId)
      .eq('direction', 'outbound')
      .eq('ai_generated', true)
      .filter('external_data->>auto_sent', 'eq', 'true')
      .gte('sent_at', startOfDay.toISOString());
    perPartyCount = count ?? 0;
  }

  return {
    dailyCount,
    hourlyCount,
    perPartyCount,
    dailyExceeded:
      rule.dailyLimit !== undefined && dailyCount >= rule.dailyLimit,
    hourlyExceeded:
      rule.hourlyLimit !== undefined && hourlyCount >= rule.hourlyLimit,
    perPartyExceeded:
      rule.perPartyDailyLimit !== undefined
      && partyId !== undefined
      && perPartyCount >= rule.perPartyDailyLimit,
  };
}

// ───────────────────────────────────────────────────────────────────
// 내부 — 캘린더 가용성
// ───────────────────────────────────────────────────────────────────

async function checkCalendarAvailability(
  supabase: SupabaseClient,
  organizationId: string,
  _partyId: string | undefined,
): Promise<boolean> {
  void _partyId;
  const now = new Date();
  const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  const { count, error } = await supabase
    .schema('app')
    .from('meetings')
    .select('id', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .gte('scheduled_at', now.toISOString())
    .lte('scheduled_at', sevenDaysLater.toISOString())
    .in('status', ['scheduled', 'rescheduled']);

  if (error) {
    return false;
  }
  return (count ?? 0) < 20;
}
