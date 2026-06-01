/**
 * __tests__/email/header-parser.test.ts
 *
 * Tests focused on pure functions:
 *   - parseInboundMessage: header extraction, URM header, fallback footer
 *   - findThreadId: 3-level priority (urm_header -> in_reply_to -> references)
 *   - matchSenderToContactAndParty: exact match, domain match, generic domain exclusion
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import type { ParsedMail } from 'mailparser';
import {
  parseInboundMessage,
  extractUrmHeadersFromHtmlFooter,
  hasAnyUrmHeader,
  findThreadId,
  matchSenderToContactAndParty,
} from '../../lib/email/header-parser';
import { URM_HEADER_NAMES } from '../../types/email';
import { buildSupabaseMock } from '../setup/supabase-mock';

// ParsedMail helper - mailparser internally uses Map-based headers + value arrays
function makeParsedMail(
  overrides: Partial<ParsedMail> & { headerEntries?: Array<[string, unknown]> } = {},
): ParsedMail {
  const headers = new Map<string, unknown>(overrides.headerEntries ?? []);
  return {
    headers,
    headerLines: [],
    attachments: [],
    text: overrides.text ?? '',
    html: overrides.html ?? false,
    subject: overrides.subject,
    messageId: overrides.messageId,
    inReplyTo: overrides.inReplyTo,
    references: overrides.references,
    from: overrides.from,
    to: overrides.to,
    cc: overrides.cc,
    replyTo: overrides.replyTo,
    date: overrides.date,
  } as ParsedMail;
}

describe('parseInboundMessage', () => {
  it('extracts message-id, subject, from, to, references', () => {
    const parsed = makeParsedMail({
      messageId: '<abc@ex.com>',
      subject: 'Hello',
      from: {
        text: 'A B <a@b.com>',
        html: '',
        value: [{ name: 'A B', address: 'a@b.com' }],
      },
      to: {
        text: 'c@d.com',
        html: '',
        value: [{ name: '', address: 'c@d.com' }],
      },
      inReplyTo: '<prev@ex.com>',
      references: ['<r1@ex.com>', '<r2@ex.com>'],
      date: new Date('2026-01-15T10:00:00Z'),
    });

    const result = parseInboundMessage(parsed);

    expect(result.messageId).toBe('<abc@ex.com>');
    expect(result.subject).toBe('Hello');
    expect(result.from).toEqual({ name: 'A B', address: 'a@b.com' });
    expect(result.to).toEqual([{ name: '', address: 'c@d.com' }]);
    expect(result.inReplyTo).toBe('<prev@ex.com>');
    expect(result.references).toEqual(['<r1@ex.com>', '<r2@ex.com>']);
    expect(result.date.toISOString()).toBe('2026-01-15T10:00:00.000Z');
  });

  it('parses references string format ("<r1> <r2>")', () => {
    const parsed = makeParsedMail({
      messageId: '<x@x>',
      references: '<r1@a> <r2@a>  <r3@a>',
    } as Partial<ParsedMail>);
    const result = parseInboundMessage(parsed);
    expect(result.references).toEqual(['<r1@a>', '<r2@a>', '<r3@a>']);
  });

  it('falls back gracefully when fields are missing', () => {
    const parsed = makeParsedMail({});
    const result = parseInboundMessage(parsed);

    expect(result.messageId).toMatch(/^<unknown-\d+@local>$/);
    expect(result.subject).toBe('(no subject)');
    expect(result.from.address).toBe('unknown@unknown');
    expect(result.to).toEqual([]);
    expect(result.references).toEqual([]);
    expect(result.date).toBeInstanceOf(Date);
  });

  it('extracts X-URM-* headers from headers Map', () => {
    const parsed = makeParsedMail({
      messageId: '<x>',
      headerEntries: [
        [URM_HEADER_NAMES.engagementId, 'eng-123'],
        [URM_HEADER_NAMES.communicationId, 'comm-456'],
        [URM_HEADER_NAMES.autoSend, 'true'],
        [URM_HEADER_NAMES.brandVoiceId, 'bv-789'],
      ],
    });
    const result = parseInboundMessage(parsed);
    expect(result.urmHeaders).toEqual({
      engagementId: 'eng-123',
      communicationId: 'comm-456',
      autoSend: true,
      brandVoiceId: 'bv-789',
    });
  });

  it('parses X-URM-Auto-Send=false correctly', () => {
    const parsed = makeParsedMail({
      messageId: '<x>',
      headerEntries: [[URM_HEADER_NAMES.autoSend, 'false']],
    });
    const result = parseInboundMessage(parsed);
    expect(result.urmHeaders.autoSend).toBe(false);
  });

  it('falls back to invisible HTML footer when headers are absent', () => {
    const parsed = makeParsedMail({
      messageId: '<x>',
      html: '<div>body</div><!-- urm:c=comm-aaa;auto=1;e=eng-bbb;bv=bv-ccc -->',
    });
    const result = parseInboundMessage(parsed);
    expect(result.urmHeaders).toEqual({
      communicationId: 'comm-aaa',
      autoSend: true,
      engagementId: 'eng-bbb',
      brandVoiceId: 'bv-ccc',
    });
  });

  it('header takes precedence over HTML footer', () => {
    const parsed = makeParsedMail({
      messageId: '<x>',
      headerEntries: [[URM_HEADER_NAMES.communicationId, 'comm-from-header']],
      html: '<!-- urm:c=comm-from-footer -->',
    });
    const result = parseInboundMessage(parsed);
    expect(result.urmHeaders.communicationId).toBe('comm-from-header');
  });
});

describe('extractUrmHeadersFromHtmlFooter', () => {
  it('parses footer with all fields', () => {
    const r = extractUrmHeadersFromHtmlFooter(
      '<!-- urm:c=cc;auto=1;e=ee;bv=bb -->',
    );
    expect(r).toEqual({
      communicationId: 'cc',
      autoSend: true,
      engagementId: 'ee',
      brandVoiceId: 'bb',
    });
  });

  it('handles auto=0 as false', () => {
    const r = extractUrmHeadersFromHtmlFooter('<!-- urm:c=x;auto=0 -->');
    expect(r.autoSend).toBe(false);
  });

  it('returns empty object when footer is absent', () => {
    expect(extractUrmHeadersFromHtmlFooter('<div>no footer</div>')).toEqual({});
  });
});

describe('hasAnyUrmHeader', () => {
  it('returns true if any field is set', () => {
    expect(hasAnyUrmHeader({ communicationId: 'x' })).toBe(true);
    expect(hasAnyUrmHeader({ autoSend: false })).toBe(true);
  });
  it('returns false for empty object', () => {
    expect(hasAnyUrmHeader({})).toBe(false);
  });
});

describe('findThreadId — priority order', () => {
  const orgId = 'org-1';

  it('[1] matches by X-URM-Communication-Id first', async () => {
    const sb = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: { data: { thread_id: 'thread-from-urm', engagement_id: 'eng-1' } },
      },
    });
    const result = await findThreadId(sb as never, orgId, {
      messageId: '<x>',
      references: [],
      from: { address: 'a@b' },
      to: [],
      subject: '',
      date: new Date(),
      urmHeaders: { communicationId: 'comm-99' },
    });
    expect(result.threadId).toBe('thread-from-urm');
    expect(result.matchedBy).toBe('urm_header');
    expect(result.matchedEngagementId).toBe('eng-1');
  });

  it('[2] falls back to In-Reply-To when URM header is missing', async () => {
    const sb = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: { data: { id: 'c-1', thread_id: 'thread-irt', engagement_id: null } },
      },
    });
    const result = await findThreadId(sb as never, orgId, {
      messageId: '<x>',
      inReplyTo: '<prev@ex>',
      references: [],
      from: { address: 'a@b' },
      to: [],
      subject: '',
      date: new Date(),
      urmHeaders: {},
    });
    expect(result.threadId).toBe('thread-irt');
    expect(result.matchedBy).toBe('in_reply_to');
  });

  it('[3] falls back to References (reverse) when In-Reply-To misses', async () => {
    let calls = 0;
    const sb = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: { data: null },
      },
    });
    // overwrite maybeSingle to return null first, then matched
    const originalSchema = sb.schema;
    sb.schema = vi.fn((schemaName: string) => ({
      from: (table: string) => {
        const orig = originalSchema(schemaName).from(table) as Record<string, unknown>;
        const builder: Record<string, unknown> = { ...orig };
        builder.maybeSingle = vi.fn(() => {
          calls += 1;
          // the first two (In-Reply-To is attempted first but absent in this case;
          // references in reverse, r2 -> assume match success)
          if (calls === 1) {
            return Promise.resolve({
              data: { id: 'c-2', thread_id: 'thread-ref', engagement_id: 'eng-2' },
              error: null,
            });
          }
          return Promise.resolve({ data: null, error: null });
        });
        // all chain methods also return the builder
        for (const m of ['select', 'eq', 'is', 'order', 'limit']) {
          builder[m] = vi.fn(() => builder);
        }
        return builder;
      },
    })) as unknown as typeof sb.schema;

    const result = await findThreadId(sb as never, orgId, {
      messageId: '<x>',
      references: ['<r1@a>', '<r2@a>'],
      from: { address: 'a@b' },
      to: [],
      subject: '',
      date: new Date(),
      urmHeaders: {},
    });
    expect(result.threadId).toBe('thread-ref');
    expect(result.matchedBy).toBe('references');
  });

  it('returns null when nothing matches', async () => {
    const sb = buildSupabaseMock({
      'app.communications': { selectMaybeSingle: { data: null } },
    });
    const result = await findThreadId(sb as never, orgId, {
      messageId: '<x>',
      references: [],
      from: { address: 'a@b' },
      to: [],
      subject: '',
      date: new Date(),
      urmHeaders: {},
    });
    expect(result.threadId).toBeNull();
    expect(result.matchedBy).toBe('none');
  });
});

describe('matchSenderToContactAndParty', () => {
  const orgId = 'org-1';

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns "none" for empty/unknown address', async () => {
    const sb = buildSupabaseMock();
    const r1 = await matchSenderToContactAndParty(sb as never, orgId, '');
    expect(r1.matchedBy).toBe('none');
    const r2 = await matchSenderToContactAndParty(
      sb as never,
      orgId,
      'unknown@unknown',
    );
    expect(r2.matchedBy).toBe('none');
  });

  it('matches by exact contact email', async () => {
    const sb = buildSupabaseMock({
      'app.contacts': {
        selectMaybeSingle: { data: { id: 'contact-1', party_id: 'party-1' } },
      },
    });
    const r = await matchSenderToContactAndParty(
      sb as never,
      orgId,
      'CEO@AcmeCorp.com',
    );
    expect(r.matchedBy).toBe('contact_email');
    expect(r.contactId).toBe('contact-1');
    expect(r.partyId).toBe('party-1');
  });

  it('returns "none" for generic email domains (gmail, naver)', async () => {
    const sb = buildSupabaseMock({
      'app.contacts': { selectMaybeSingle: { data: null } },
    });
    const r1 = await matchSenderToContactAndParty(
      sb as never,
      orgId,
      'random@gmail.com',
    );
    expect(r1.matchedBy).toBe('none');
    const r2 = await matchSenderToContactAndParty(
      sb as never,
      orgId,
      'random@naver.com',
    );
    expect(r2.matchedBy).toBe('none');
  });

  it('falls back to party email domain match for non-generic domains', async () => {
    let callCount = 0;
    const sb = buildSupabaseMock();
    sb.schema = vi.fn((schemaName: string) => ({
      from: (_table: string) => {
        const builder: Record<string, unknown> = {};
        for (const m of ['select', 'eq', 'is', 'like', 'order', 'limit']) {
          builder[m] = vi.fn(() => builder);
        }
        builder.maybeSingle = vi.fn(() => {
          callCount += 1;
          if (callCount === 1) {
            // first call (exact match) - null
            return Promise.resolve({ data: null, error: null });
          }
          // second call (domain match) - matched
          return Promise.resolve({
            data: { id: 'contact-x', party_id: 'party-x' },
            error: null,
          });
        });
        return builder;
      },
    })) as unknown as typeof sb.schema;

    const r = await matchSenderToContactAndParty(
      sb as never,
      orgId,
      'someone@acmecorp.com',
    );
    expect(r.matchedBy).toBe('party_email_domain');
    expect(r.partyId).toBe('party-x');
  });
});
