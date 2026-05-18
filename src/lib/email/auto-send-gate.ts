/**
 * lib/email/auto-send-gate.ts
 *
 * AI媛 ?앹꽦???뚯떊 珥덉븞???먮룞諛쒖넚 媛???щ?瑜??됯??쒕떎.
 * ?대뒓 ?④퀎???듦낵?섏? 紐삵븯硫?reasons[]???ъ쑀瑜??꾩쟻?섍퀬 allowed=false.
 *
 * ?됯? ?쒖꽌 (留덉뒪??짠4.4 + 媛?대뱶 짠7.3):
 *   [1] 湲濡쒕쾶 ?뚮옒洹?env.AI_AUTO_SEND_ENABLED)
 *   [2] auto_send_rules ??議고쉶 (carrier횞category)
 *   [3] rule.is_blocked
 *   [4] rule.allowed_modules??module ?ы븿 ?щ?
 *   [5] classification.confidence ??rule.min_confidence
 *   [6] rule.requires_human_approval ?먮뒗 classification.requiresHuman
 *   [7] classification.riskFlags 鍮꾩뼱?덉쓬
 *   [8] blocked_keywords_in_body ?뺢퇋??留ㅼ묶 ?놁쓬
 *   [9] daily_limit / hourly_limit / per_party_daily_limit 誘몃떖?? *  [10] rule.requires_calendar_data ??誘명똿 媛?⑹꽦 ?뺤씤 (meeting_scheduling)
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '../env';
import type { AutoSendRuleRow, ModuleType } from '../../types/ai';
import type { ClassificationOutput } from '../../types/classification';

/* ============================================================
 * 1. ?낆텧????? * ============================================================ */

export interface GateInput {
  organizationId: string;
  module?: ModuleType;
  partyId?: string;
  classification: ClassificationOutput;
  draftBody: string;
  /** ?뚯떊媛媛 ?먯껜 ?먮떒???щ엺 寃???꾩슂 ?뚮옒洹?蹂꾨룄 媛뺤젣). */
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
  /** 李⑤떒???몃━嫄고븳 猷?ID(?덉쑝硫?. */
  ruleId?: string;
  /** ?붾쾭源끒룰컧?ъ슜 ?됯? 濡쒓렇. */
  evaluationLog: Record<string, unknown>;
}

/* ============================================================
 * 2. 硫붿씤 吏꾩엯?? * ============================================================ */

export async function evaluateAutoSend(
  supabase: SupabaseClient,
  input: GateInput,
): Promise<GateResult> {
  const reasons: GateBlockReason[] = [];
  const log: Record<string, unknown> = {};

  // [1] 湲濡쒕쾶 ?뚮옒洹?  if (!env.AI_AUTO_SEND_ENABLED) {
    return {
      allowed: false,
      reasons: ['global_disabled'],
      evaluationLog: { step: 'global_flag', value: false },
    };
  }

  // [2] 猷?議고쉶
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

  // [10] calendar (meeting_scheduling 移댄뀒怨좊━留??섎? ?덉쓬)
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
 * 3. 猷?議고쉶
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
 * 4. ?ㅼ썙??留ㅼ묶
 * ============================================================ */

/**
 * 李⑤떒 ?ㅼ썙??諛곗뿴 以??뚯떊 蹂몃Ц??留ㅼ묶?섎뒗 泥???ぉ??諛섑솚.
 * 媛??ㅼ썙?쒕뒗 ?뺢퇋?앹쑝濡??쒕룄 (?섎せ???뺢퇋?앹? ?⑥닚 substring?쇰줈 fallback).
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
      // ?섎せ???뺢퇋??????뚮Ц??臾댁떆 substring
      matched = body.toLowerCase().includes(kw.toLowerCase());
    }
    if (matched) return kw;
  }
  return null;
}

/* ============================================================
 * 5. Sending limit 寃利? * ============================================================ */

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

  // ?쇱씪 ?쒕룄 ???먮룞諛쒖넚??communications 移댁슫??  if (rule.dailyLimit > 0) {
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

  // ?쒓컙???쒕룄
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

  // 嫄곕옒泥섎퀎 24?쒓컙 ?쒕룄
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
  // ai_generated=true ?닿퀬 ?먮룞諛쒖넚??external_data.auto_send=true) 硫붿씪留?移댁슫??  const { count, error } = await supabase
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
    return Number.MAX_SAFE_INTEGER; // 蹂댁닔?? ?ㅽ뙣 ???쒕룄 珥덇낵濡?媛꾩＜
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
 * 6. Calendar 媛?⑹꽦
 * ----------------------------------------------------------
 * ?댁쁺 ?쒖젏??google calendar / outlook ?듯빀 ???뺥솗??媛?⑹꽦 ?됯?.
 * 蹂?STEP 3?먯꽌??organization_settings.calendar_connected ?뚮옒洹몃쭔 ?뺤씤.
 * 誘몄뿰寃곗씠硫?誘명똿 ?먮룞 ?뚯떊 李⑤떒.
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
