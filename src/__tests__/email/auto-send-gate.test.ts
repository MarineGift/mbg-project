/**
 * __tests__/email/auto-send-gate.test.ts
 *
 * Verifies the auto-send-gate's 10-step evaluation step by step.
 *
 * Scenarios:
 *   - global flag disabled -> global_disabled
 *   - no rule -> no_rule_defined
 *   - is_blocked → rule_blocked
 *   - module mismatch -> module_not_allowed
 *   - confidence below threshold -> confidence_below_threshold
 *   - human forced -> requires_human_approval / drafter_requires_human
 *   - risk_flags present -> risk_flags_present
 *   - blocked keyword match -> blocked_keyword:xxx
 *   - daily limit exceeded -> daily_limit_reached
 *   - all pass -> allowed=true
 *
 * since env.AI_AUTO_SEND_ENABLED is injected as false in setupFiles,
 * the "pass" cases work around it via vi.stubEnv or directly mocking the env module.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { evaluateAutoSend, matchBlockedKeyword } from '../../lib/email/auto-send-gate';
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
import type { ClassificationOutput } from '../../types/classification';

// a classification result that can pass by default
const baseClassification: ClassificationOutput = {
  category: 'simple_acknowledgment',
  urgency: 'low',
  sentiment: 'positive',
  requiresHuman: false,
  confidence: 0.97,
  rationale: 'simple ack',
  riskFlags: [],
  detectedLanguage: 'ko',
};

const baseRule = {
  id: 'rule-1',
  organization_id: 'org-1',
  classification_category: 'simple_acknowledgment',
  is_blocked: false,
  block_reason: null,
  min_confidence: 0.95,
  requires_human_approval: false,
  allowed_modules: ['investor', 'paper_mill'],
  blocked_keywords_in_body: [],
  daily_limit: 0,
  hourly_limit: 0,
  per_party_daily_limit: 0,
  requires_calendar_data: false,
  is_active: true,
};

describe('matchBlockedKeyword', () => {
  it('returns matched keyword (regex)', () => {
    expect(matchBlockedKeyword('we offer 5% discount', ['discount'])).toBe('discount');
    expect(matchBlockedKeyword('payment due today', ['\\bpayment\\b', 'invoice'])).toBe('\\bpayment\\b');
  });

  it('returns null when no match', () => {
    expect(matchBlockedKeyword('hello there', ['discount', 'invoice'])).toBeNull();
  });

  it('falls back to substring on invalid regex', () => {
    // ( alone is an invalid regex -> fall back to substring matching
    expect(matchBlockedKeyword('special (discount) inside', ['('])).toBe('(');
  });

  it('case-insensitive', () => {
    expect(matchBlockedKeyword('Hello DISCOUNT here', ['discount'])).toBe('discount');
  });
});

/* --------------------------------------------------------------------
 * the next describe mocks the env module to verify each step in isolation under
 * an AI_AUTO_SEND_ENABLED=true environment.
 * the "global_disabled" path is a simple condition on evaluateAutoSend's first line, so
 * it's skipped here without a separate unit test - verified in integration tests.
 * ------------------------------------------------------------------ */

vi.mock('../../lib/env', async () => {
  const real = await vi.importActual<typeof import('../../lib/env')>(
    '../../lib/env',
  );
  return {
    ...real,
    env: { ...real.env, AI_AUTO_SEND_ENABLED: true },
  };
});

describe('evaluateAutoSend (with AI_AUTO_SEND_ENABLED=true)', () => {
  let supabase: MockSupabase;

  beforeEach(() => {
    supabase = buildSupabaseMock();
  });

  it('blocks when no rule defined for category', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': { selectMaybeSingle: { data: null } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('no_rule_defined');
  });

  it('blocks when rule.is_blocked=true', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: {
          data: { ...baseRule, is_blocked: true, block_reason: 'policy' },
        },
      },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('rule_blocked');
    expect(result.ruleId).toBe('rule-1');
  });

  it('blocks when module not in allowed_modules', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'partner', // not in ['investor','paper_mill']
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('module_not_allowed');
  });

  it('blocks when confidence below min_confidence', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: { data: { ...baseRule, min_confidence: 0.95 } },
      },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: { ...baseClassification, confidence: 0.85 },
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('confidence_below_threshold');
  });

  it('blocks when classification.requiresHuman=true', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: { ...baseClassification, requiresHuman: true },
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('requires_human_approval');
  });

  it('blocks when drafterRequiresHuman=true', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: baseClassification,
      draftBody: 'thanks',
      drafterRequiresHuman: true,
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('drafter_requires_human');
  });

  it('blocks when riskFlags is non-empty', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: { ...baseClassification, riskFlags: ['valuation_topic'] },
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('risk_flags_present');
  });

  it('blocks when blocked keyword found in body', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: {
          data: { ...baseRule, blocked_keywords_in_body: ['valuation', 'NDA'] },
        },
      },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: baseClassification,
      draftBody: 'Our valuation is around $5M.',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons.some((r) => r.startsWith('blocked_keyword:'))).toBe(true);
  });

  it('blocks when daily limit reached', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: { data: { ...baseRule, daily_limit: 50 } },
      },
      'app.communications': { selectCount: { count: 50 } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('daily_limit_reached');
  });

  it('blocks when hourly limit reached', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: { data: { ...baseRule, hourly_limit: 5 } },
      },
      'app.communications': { selectCount: { count: 5 } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('hourly_limit_reached');
  });

  it('blocks when per-party daily limit reached', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: { data: { ...baseRule, per_party_daily_limit: 3 } },
      },
      'app.communications': { selectCount: { count: 3 } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      partyId: 'party-x',
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('per_party_daily_limit_reached');
  });

  it('blocks meeting_scheduling when calendar not connected', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: {
          data: {
            ...baseRule,
            classification_category: 'meeting_scheduling',
            requires_calendar_data: true,
          },
        },
      },
      'app.organizations': {
        selectMaybeSingle: { data: { settings: { calendar_connected: false } } },
      },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: { ...baseClassification, category: 'meeting_scheduling' },
      draftBody: 'I can meet on Tuesday at 14:00 KST',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('calendar_data_required');
  });

  it('allows when all checks pass', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': { selectMaybeSingle: { data: baseRule } },
      'app.communications': { selectCount: { count: 0 } },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      partyType: 'investor',
      classification: baseClassification,
      draftBody: 'thanks for the info',
    });
    expect(result.allowed).toBe(true);
    expect(result.reasons).toEqual([]);
    expect(result.ruleId).toBe('rule-1');
  });

  it('returns rule_lookup_error when DB fails', async () => {
    supabase = buildSupabaseMock({
      'ai.auto_send_rules': {
        selectMaybeSingle: { data: null, error: { message: 'connection lost' } },
      },
    });
    const result = await evaluateAutoSend(supabase as never, {
      organizationId: 'org-1',
      classification: baseClassification,
      draftBody: 'thanks',
    });
    expect(result.allowed).toBe(false);
    expect(result.reasons).toContain('rule_lookup_error');
  });
});
