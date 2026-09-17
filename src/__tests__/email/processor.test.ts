/**
 * __tests__/email/processor.test.ts
 *
 * processInbound is rules-only (no AI): it classifies and saves
 * communications.ai_classification, merging external_data.
 */

import { describe, it, expect } from 'vitest';
import {
  processInbound,
  ProcessorCommunicationNotFoundError,
} from '../../lib/email/processor';
import { buildSupabaseMock } from '../setup/supabase-mock';

const orgId = 'org-1';
const commId = 'comm-1';

function build(row: Record<string, unknown> | null) {
  return buildSupabaseMock({
    'app.communications': {
      selectMaybeSingle: { data: row },
      updateResult: { error: null },
    },
  });
}

function lastUpdate(supabase: ReturnType<typeof build>): Record<string, unknown> {
  const updates = supabase.__calls.update.filter(
    (c) => c.schema === 'app' && c.table === 'communications',
  );
  return updates[updates.length - 1]?.payload as Record<string, unknown>;
}

describe('processInbound (rules only)', () => {
  it('classifies a normal message and keeps existing external_data', async () => {
    const supabase = build({
      id: commId,
      subject: '가격 문의',
      body_plain: '견적 단가를 알려주실 수 있을까요?',
      from_address: 'buyer@acme.com',
      language_detected: null,
      external_data: { urm_headers: { keep: 'me' } },
    });

    const result = await processInbound(supabase as never, orgId, commId);

    expect(result.classification.category).toBe('price_negotiation');
    expect(result.isAutomated).toBe(false);
    const u = lastUpdate(supabase);
    expect((u.ai_classification as Record<string, unknown>).category).toBe('price_negotiation');
    expect(u.language_detected).toBe('ko');
    const ext = u.external_data as Record<string, unknown>;
    expect(ext.urm_headers).toEqual({ keep: 'me' });
    expect(ext.classified_by).toBe('rules');
    expect(u).not.toHaveProperty('ai_draft_id');
  });

  it('marks automated mail', async () => {
    const supabase = build({
      id: commId,
      subject: 'September update',
      body_plain: 'Our monthly newsletter',
      from_address: 'news@vendor.example',
      language_detected: 'en',
      external_data: {
        raw_selected_headers: { 'list-unsubscribe': '<mailto:u@vendor.example>' },
      },
    });

    const result = await processInbound(supabase as never, orgId, commId);

    expect(result.isAutomated).toBe(true);
    const u = lastUpdate(supabase);
    expect(u).not.toHaveProperty('language_detected');
    expect((u.external_data as Record<string, unknown>).automated_mail).toContain('list-unsubscribe');
  });

  it('throws when the row is missing', async () => {
    const supabase = build(null);
    await expect(processInbound(supabase as never, orgId, commId)).rejects.toBeInstanceOf(
      ProcessorCommunicationNotFoundError,
    );
  });
});
