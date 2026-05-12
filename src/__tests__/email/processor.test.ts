/**
 * __tests__/email/processor.test.ts
 *
 * processor.ts의 5단계 파이프라인 검증.
 * ClaudeClient는 인터페이스로 추상화되지 않았지만 fake instance를 주입할 수 있도록
 * options.claudeClient를 받는다. 본 테스트에서는 ClaudeClient의 complete()만
 * stub해서 분류기·회신가 응답을 통제한다.
 *
 * 시나리오:
 *   1. 정상 흐름 — 표준 카테고리, 정상 회신, ai.drafts INSERT
 *   2. 비표준 카테고리 → 'other'로 강제 + requires_human=true
 *   3. 회신가 출력 검증 실패 → fallback reply + requires_human=true
 *   4. 회신 본문에 미복원 PII 토큰 → requires_human=true
 *   5. communications에 이미 ai_draft_id 있음 + force=false → 에러
 *   6. ClaudeBudgetExceededError → ai_processing_status='failed'
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { processInbound, ProcessorError } from '../../lib/email/processor';
import { ClaudeBudgetExceededError } from '../../lib/ai/claude-client';
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';
import type {
  ClaudeCompleteInput,
  ClaudeCompleteOutput,
} from '../../types/ai';

// auto-send-gate가 env.AI_AUTO_SEND_ENABLED=false에서 항상 차단하므로
// processor 테스트에서는 차단되더라도 ai.drafts가 정상 생성되는지만 확인.

const orgId = 'org-1';
const commId = 'comm-1';

interface MockClaudeOptions {
  classifierResponse?: object | null;
  drafterResponse?: object | null;
  classifierThrows?: Error;
  drafterThrows?: Error;
}

function buildMockClaude(opts: MockClaudeOptions): {
  complete: ReturnType<typeof vi.fn>;
} {
  const complete = vi.fn(async (input: ClaudeCompleteInput): Promise<ClaudeCompleteOutput> => {
    const isClassifier = input.agentRole === 'classifier';
    if (isClassifier && opts.classifierThrows) throw opts.classifierThrows;
    if (!isClassifier && opts.drafterThrows) throw opts.drafterThrows;

    const parsed = isClassifier ? opts.classifierResponse : opts.drafterResponse;
    return {
      content: parsed === null ? '' : JSON.stringify(parsed),
      parsedJson: parsed ?? undefined,
      runId: isClassifier ? 'run-classifier-1' : 'run-drafter-1',
      agentId: isClassifier ? 'agent-classifier-1' : 'agent-drafter-1',
      model: isClassifier
        ? 'claude-haiku-4-5-20251001'
        : 'claude-opus-4-7',
      latencyMs: 1234,
      tokensIn: 500,
      tokensOut: 200,
      costUsd: 0.001,
    };
  });
  return { complete };
}

const validClassification = {
  category: 'information_request',
  urgency: 'medium',
  sentiment: 'neutral',
  requiresHuman: false,
  confidence: 0.92,
  rationale: 'asking about pricing',
  riskFlags: [],
  detectedLanguage: 'ko',
};

const validReply = {
  subject: 'Re: 가격 문의',
  bodyPlain: '가격은 KG당 50달러입니다.',
  bodyHtml: '<p>가격은 KG당 50달러입니다.</p>',
  rationale: 'Direct pricing answer',
  riskFlags: [],
  requiresHumanApproval: false,
  language: 'ko',
};

function buildBaseSupabase(): MockSupabase {
  return buildSupabaseMock({
    'app.communications': {
      selectMaybeSingle: {
        data: {
          id: commId,
          organization_id: orgId,
          party_id: 'party-1',
          contact_id: 'contact-1',
          engagement_id: 'eng-1',
          module: 'buyer',
          from_address: 'buyer@acme.com',
          body_plain: '가격이 어떻게 되나요?',
          subject: '가격 문의',
          language_detected: 'ko',
          ai_draft_id: null,
          ai_processing_status: 'pending',
        },
      },
      updateResult: { error: null },
    },
    'app.contacts': {
      selectMaybeSingle: { data: { preferred_language: 'ko' } },
    },
    'app.parties': {
      selectMaybeSingle: { data: { country_code: 'KR' } },
    },
    'ai.drafts': {
      insertSingle: { data: { id: 'draft-1' } },
    },
    'ai.auto_send_rules': {
      selectMaybeSingle: { data: null }, // no_rule_defined → blocked
    },
    'app.organizations': {
      selectMaybeSingle: { data: { settings: {} } },
    },
  });
}

describe('processInbound — happy path', () => {
  let supabase: MockSupabase;

  beforeEach(() => {
    supabase = buildBaseSupabase();
  });

  it('runs classifier, drafter, gate, draft INSERT, communications update', async () => {
    const claude = buildMockClaude({
      classifierResponse: validClassification,
      drafterResponse: validReply,
    });

    const result = await processInbound(supabase as never, orgId, commId, {
      claudeClient: claude as never,
    });

    expect(result.communicationId).toBe(commId);
    expect(result.draftId).toBe('draft-1');
    expect(result.classifierRunId).toBe('run-classifier-1');
    expect(result.drafterRunId).toBe('run-drafter-1');
    expect(result.classification.category).toBe('information_request');
    expect(result.reply.subject).toBe('Re: 가격 문의');
    // env.AI_AUTO_SEND_ENABLED=false (test setup) → 차단
    expect(result.autoSendAllowed).toBe(false);
    expect(result.autoSendBlockedReasons).toContain('global_disabled');

    // claude는 정확히 2번 호출 (classifier + drafter)
    expect(claude.complete).toHaveBeenCalledTimes(2);
    expect(claude.complete.mock.calls[0]?.[0]?.agentRole).toBe('classifier');
    expect(claude.complete.mock.calls[1]?.[0]?.agentRole).toBe('reply_drafter');

    // ai.drafts INSERT 검증
    const draftInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'drafts',
    );
    expect(draftInserts).toHaveLength(1);
    const payload = draftInserts[0]?.payload as Record<string, unknown>;
    expect(payload.inbound_communication_id).toBe(commId);
    expect(payload.agent_id).toBe('agent-drafter-1');
    expect(payload.classification_category).toBe('information_request');
    expect(payload.confidence_score).toBe(0.92);
    expect(payload.subject).toBe('Re: 가격 문의');
    expect(payload.classifier_run_id).toBe('run-classifier-1');
    expect(payload.drafter_run_id).toBe('run-drafter-1');
    expect(payload.ai_generated).toBe(true);
    expect(payload.status).toBe('pending_review');
    expect(payload.requires_human_approval).toBe(true); // 게이트 차단되었으므로
    expect(payload.auto_send_eligible).toBe(false);
    expect(payload.language).toBe('ko');
    expect(typeof payload.expires_at).toBe('string');

    // communications UPDATE 검증 (마지막 호출은 ai_draft_id 갱신)
    const updates = supabase.__calls.update.filter(
      (c) => c.schema === 'app' && c.table === 'communications',
    );
    expect(updates.length).toBeGreaterThanOrEqual(2); // processing → completed
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
    expect(lastUpdate.ai_draft_id).toBe('draft-1');
    expect((lastUpdate.ai_classification as Record<string, unknown>).category).toBe(
      'information_request',
    );
  });
});

describe('processInbound — non-standard category enforcement', () => {
  it('forces invalid category to "other" with requires_human=true', async () => {
    const supabase = buildBaseSupabase();
    const claude = buildMockClaude({
      classifierResponse: {
        ...validClassification,
        category: 'material_request', // 비표준!
      },
      drafterResponse: validReply,
    });

    const result = await processInbound(supabase as never, orgId, commId, {
      claudeClient: claude as never,
    });

    expect(result.classification.category).toBe('other');
    expect(result.classification.requiresHuman).toBe(true);
    expect(result.classification.confidence).toBeLessThanOrEqual(0.5);

    const draftInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'drafts',
    );
    const payload = draftInserts[0]?.payload as Record<string, unknown>;
    expect(payload.classification_category).toBe('other');
    expect(payload.requires_human_approval).toBe(true);
  });

  it('handles classifier returning malformed JSON', async () => {
    const supabase = buildBaseSupabase();
    const claude = buildMockClaude({
      classifierResponse: null, // parsedJson undefined
      drafterResponse: validReply,
    });

    const result = await processInbound(supabase as never, orgId, commId, {
      claudeClient: claude as never,
    });

    expect(result.classification.category).toBe('other');
    expect(result.classification.requiresHuman).toBe(true);
    expect(result.classification.rationale).toContain('validation failed');
  });
});

describe('processInbound — drafter validation failure', () => {
  it('uses fallback reply with requires_human=true', async () => {
    const supabase = buildBaseSupabase();
    const claude = buildMockClaude({
      classifierResponse: validClassification,
      drafterResponse: { subject: '', bodyPlain: '' }, // invalid
    });

    const result = await processInbound(supabase as never, orgId, commId, {
      claudeClient: claude as never,
    });

    // fallback reply는 ko 언어
    expect(result.reply.language).toBe('ko');
    expect(result.reply.requiresHumanApproval).toBe(true);
    expect(result.reply.bodyPlain).toContain('검토');
    expect(result.reply.rationale).toContain('Fallback');
  });
});

describe('processInbound — unrestored PII tokens', () => {
  it('forces requires_human=true when reply still contains {{PII_xxx}}', async () => {
    const supabase = buildBaseSupabase();
    const claude = buildMockClaude({
      classifierResponse: validClassification,
      drafterResponse: {
        ...validReply,
        bodyPlain: '안녕하세요, {{PII_001}}로 연락드리겠습니다.', // 미복원!
      },
    });

    const result = await processInbound(supabase as never, orgId, commId, {
      claudeClient: claude as never,
    });

    expect(result.reply.requiresHumanApproval).toBe(true);
    expect(result.reply.rationale).toContain('unrestored PII');

    const draftInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'ai' && c.table === 'drafts',
    );
    const payload = draftInserts[0]?.payload as Record<string, unknown>;
    expect(payload.requires_human_approval).toBe(true);
  });
});

describe('processInbound — already processed', () => {
  it('throws when communication already has ai_draft_id and force=false', async () => {
    const supabase = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: {
          data: {
            id: commId,
            organization_id: orgId,
            ai_draft_id: 'existing-draft',
            body_plain: 'x',
            subject: 'y',
          },
        },
      },
    });
    const claude = buildMockClaude({
      classifierResponse: validClassification,
      drafterResponse: validReply,
    });

    await expect(
      processInbound(supabase as never, orgId, commId, {
        claudeClient: claude as never,
      }),
    ).rejects.toThrow(/already has draft/);
  });

  it('processes again when force=true', async () => {
    const supabase = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: {
          data: {
            id: commId,
            organization_id: orgId,
            party_id: null,
            engagement_id: null,
            ai_draft_id: 'existing-draft',
            body_plain: 'hello',
            subject: 'sub',
            module: 'buyer',
          },
        },
        updateResult: { error: null },
      },
      'ai.drafts': { insertSingle: { data: { id: 'draft-2' } } },
      'ai.auto_send_rules': { selectMaybeSingle: { data: null } },
    });
    const claude = buildMockClaude({
      classifierResponse: validClassification,
      drafterResponse: validReply,
    });

    const result = await processInbound(supabase as never, orgId, commId, {
      claudeClient: claude as never,
      force: true,
    });
    expect(result.draftId).toBe('draft-2');
  });
});

describe('processInbound — error handling', () => {
  it('marks failed when ClaudeBudgetExceededError thrown', async () => {
    const supabase = buildBaseSupabase();
    const claude = buildMockClaude({
      classifierThrows: new ClaudeBudgetExceededError(60, 50, 'daily'),
    });

    await expect(
      processInbound(supabase as never, orgId, commId, {
        claudeClient: claude as never,
      }),
    ).rejects.toBeInstanceOf(ClaudeBudgetExceededError);

    // communications가 failed 상태로 갱신되었는지
    const updates = supabase.__calls.update.filter(
      (c) => c.schema === 'app' && c.table === 'communications',
    );
    const lastUpdate = updates[updates.length - 1]?.payload as Record<string, unknown>;
    const ed = lastUpdate.external_data as Record<string, unknown>;
    expect(ed.ai_processing_status).toBe('failed');
    expect(ed.ai_processing_error_class).toBe('ClaudeBudgetExceededError');
    expect(ed.ai_processing_retryable).toBe(false);
  });

  it('throws ProcessorCommunicationNotFoundError for missing comm', async () => {
    const supabase = buildSupabaseMock({
      'app.communications': { selectMaybeSingle: { data: null } },
    });
    await expect(
      processInbound(supabase as never, orgId, 'missing'),
    ).rejects.toThrow(/Communication not found/);
  });

  it('wraps generic DB errors in ProcessorError', async () => {
    const supabase = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: { data: null, error: { message: 'pg connection lost' } },
      },
    });
    await expect(
      processInbound(supabase as never, orgId, commId),
    ).rejects.toBeInstanceOf(ProcessorError);
  });
});
