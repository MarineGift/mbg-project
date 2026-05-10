import { describe, it, expect, vi, beforeEach } from 'vitest';

const envMock = vi.hoisted(() => ({ AI_AUTO_SEND_ENABLED: true }));

vi.mock('@/lib/env', () => ({
  env: new Proxy(envMock, {
    get(target, key) {
      return (target as Record<string, unknown>)[String(key)];
    },
  }),
}));

import {
  evaluateAutoSend,
  matchBlockedKeywords,
  filterSensitiveRiskFlags,
} from '@/lib/email/auto-send-gate';
import type { ClassificationOutput } from '@/types/classification';

interface RuleRow {
  id: string;
  organization_id: string;
  classification_category: string;
  is_blocked?: boolean;
  block_reason?: string | null;
  allowed_modules?: string[];
  min_confidence?: number;
  blocked_keywords_in_body?: string[];
  daily_limit?: number | null;
  hourly_limit?: number | null;
  per_party_daily_limit?: number | null;
  requires_calendar_data?: boolean;
  requires_human_approval?: boolean;
}

interface SupabaseStubOptions {
  rule?: RuleRow | null;
  dailyCount?: number;
  hourlyCount?: number;
  perPartyCount?: number;
  meetingCount?: number;
}

function makeSupabaseStub(opts: SupabaseStubOptions) {
  const counts = {
    daily: opts.dailyCount ?? 0,
    hourly: opts.hourlyCount ?? 0,
    perParty: opts.perPartyCount ?? 0,
    meetings: opts.meetingCount ?? 0,
  };

  const buildAutoSendRulesChain = () => {
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn(() => chain);
    chain.maybeSingle = vi.fn(async () => ({
      data: opts.rule ?? null,
      error: null,
    }));
    return chain;
  };

  const buildCommunicationsCountChain = () => {
    let mode: 'daily' | 'hourly' | 'perParty' = 'daily';
    let hasPartyId = false;
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn((col: string, val: unknown) => {
      if (col === 'party_id') {
        hasPartyId = true;
        mode = 'perParty';
      }
      void val;
      return chain;
    });
    chain.filter = vi.fn(() => chain);
    chain.gte = vi.fn((_col: string, val: string) => {
      const ts = new Date(val).getTime();
      const now = Date.now();
      if (now - ts <= 65 * 60 * 1000 && !hasPartyId) {
        mode = 'hourly';
      }
      return chain;
    });
    chain.lte = vi.fn(() => chain);
    chain.in = vi.fn(() => chain);

    chain.then = (resolve: (v: { count: number; error: null }) => unknown) => {
      let count = 0;
      if (mode === 'daily') count = counts.daily;
      else if (mode === 'hourly') count = counts.hourly;
      else if (mode === 'perParty') count = counts.perParty;
      return resolve({ count, error: null });
    };
    return chain;
  };

  const buildMeetingsCountChain = () => {
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn(() => chain);
    chain.gte = vi.fn(() => chain);
    chain.lte = vi.fn(() => chain);
    chain.in = vi.fn(() => chain);
    chain.then = (resolve: (v: { count: number; error: null }) => unknown) => {
      return resolve({ count: counts.meetings, error: null });
    };
    return chain;
  };

  const aiSchema = {
    from: vi.fn((table: string) => {
      if (table === 'auto_send_rules') return buildAutoSendRulesChain();
      throw new Error(`unexpected ai.${table}`);
    }),
  };
  const appSchema = {
    from: vi.fn((table: string) => {
      if (table === 'communications') return buildCommunicationsCountChain();
      if (table === 'meetings') return buildMeetingsCountChain();
      throw new Error(`unexpected app.${table}`);
    }),
  };

  return {
    schema: vi.fn((s: string) => (s === 'ai' ? aiSchema : appSchema)),
  };
}

function makeClassification(
  overrides: Partial<ClassificationOutput> = {},
): ClassificationOutput {
  return {
    category: 'information_request',
    urgency: 'low',
    sentiment: 'neutral',
    requiresHuman: false,
    confidence: 0.97,
    rationale: 'test',
    riskFlags: [],
    detectedLanguage: 'en',
    ...overrides,
  };
}

const ALLOW_ALL_RULE: RuleRow = {
  id: 'rule-1',
  organization_id: 'org-1',
  classification_category: 'information_request',
  is_blocked: false,
  allowed_modules: ['investor', 'buyer'],
  min_confidence: 0.95,
  blocked_keywords_in_body: [],
  daily_limit: 100,
  hourly_limit: 30,
  per_party_daily_limit: 5,
  requires_calendar_data: false,
  requires_human_approval: false,
};

describe('evaluateAutoSend — global flag', () => {
  beforeEach(() => {
    envMock.AI_AUTO_SEND_ENABLED = true;
  });

  it('blocks immediately when AI_AUTO_SEND_ENABLED=false', async () => {
    envMock.AI_AUTO_SEND_ENABLED = false;
    const supa = makeSupabaseStub({ rule: ALLOW_ALL_RULE });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'hi',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('global_disabled');
  });
});

describe('evaluateAutoSend — rule lookup', () => {
  beforeEach(() => {
    envMock.AI_AUTO_SEND_ENABLED = true;
  });

  it('blocks when no rule defined for category', async () => {
    const supa = makeSupabaseStub({ rule: null });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'hi',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('no_rule_defined');
  });

  it('allows when rule passes all checks', async () => {
    const supa = makeSupabaseStub({ rule: ALLOW_ALL_RULE });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      partyId: 'p-1',
      classification: makeClassification(),
      draftBody: 'Thanks for reaching out.',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(true);
    expect(r.reasons).toEqual([]);
  });
});

describe('evaluateAutoSend — confidence and module', () => {
  beforeEach(() => {
    envMock.AI_AUTO_SEND_ENABLED = true;
  });

  it('blocks when confidence below min_confidence', async () => {
    const supa = makeSupabaseStub({ rule: ALLOW_ALL_RULE });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification({ confidence: 0.8 }),
      draftBody: 'x',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('confidence_below_threshold');
  });

  it('blocks when module not whitelisted', async () => {
    const supa = makeSupabaseStub({ rule: ALLOW_ALL_RULE });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'partner',
      classification: makeClassification(),
      draftBody: 'x',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('module_not_allowed');
  });
});

describe('evaluateAutoSend — keywords and risk flags', () => {
  beforeEach(() => {
    envMock.AI_AUTO_SEND_ENABLED = true;
  });

  it('blocks on blocked keyword (case-insensitive)', async () => {
    const supa = makeSupabaseStub({
      rule: { ...ALLOW_ALL_RULE, blocked_keywords_in_body: ['Confidential'] },
    });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'This is CONFIDENTIAL information.',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('blocked_keyword_in_body');
  });

  it('blocks on sensitive risk flag', async () => {
    const supa = makeSupabaseStub({ rule: ALLOW_ALL_RULE });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'x',
      draftRequiresHuman: false,
      draftRiskFlags: ['legal_terms_present'],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('sensitive_risk_flag');
  });

  it('blocks when draft self-flags requires_human', async () => {
    const supa = makeSupabaseStub({ rule: ALLOW_ALL_RULE });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'x',
      draftRequiresHuman: true,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('draft_requires_human');
  });
});

describe('evaluateAutoSend — limits', () => {
  beforeEach(() => {
    envMock.AI_AUTO_SEND_ENABLED = true;
  });

  it('blocks when daily limit reached', async () => {
    const supa = makeSupabaseStub({
      rule: { ...ALLOW_ALL_RULE, daily_limit: 5 },
      dailyCount: 5,
    });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'x',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('daily_limit_exceeded');
  });

  it('blocks when per-party daily limit reached', async () => {
    const supa = makeSupabaseStub({
      rule: { ...ALLOW_ALL_RULE, per_party_daily_limit: 1 },
      perPartyCount: 1,
    });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      partyId: 'p-1',
      module: 'investor',
      classification: makeClassification(),
      draftBody: 'x',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('per_party_daily_limit_exceeded');
  });
});

describe('evaluateAutoSend — calendar data for meetings', () => {
  beforeEach(() => {
    envMock.AI_AUTO_SEND_ENABLED = true;
  });

  it('blocks when requires_calendar_data and no slots available', async () => {
    const supa = makeSupabaseStub({
      rule: {
        ...ALLOW_ALL_RULE,
        classification_category: 'meeting_scheduling',
        requires_calendar_data: true,
      },
      meetingCount: 100,
    });
    const r = await evaluateAutoSend(supa as never, {
      organizationId: 'org-1',
      module: 'investor',
      classification: makeClassification({ category: 'meeting_scheduling' }),
      draftBody: 'x',
      draftRequiresHuman: false,
      draftRiskFlags: [],
    });
    expect(r.allowed).toBe(false);
    expect(r.reasons).toContain('calendar_data_unavailable');
  });
});

describe('utility: matchBlockedKeywords', () => {
  it('matches case-insensitively', () => {
    expect(matchBlockedKeywords('Hello WORLD', ['world'])).toEqual(['world']);
  });
  it('returns empty when no body or no keywords', () => {
    expect(matchBlockedKeywords('', ['x'])).toEqual([]);
    expect(matchBlockedKeywords('x', [])).toEqual([]);
  });
  it('skips empty keyword strings', () => {
    expect(matchBlockedKeywords('hello', ['', '  '])).toEqual([]);
  });
});

describe('utility: filterSensitiveRiskFlags', () => {
  it('keeps only sensitive flags', () => {
    expect(
      filterSensitiveRiskFlags([
        'legal_terms_present',
        'urgent_response_required',
        'price_commitment_required',
      ]),
    ).toEqual(['legal_terms_present', 'price_commitment_required']);
  });
});
