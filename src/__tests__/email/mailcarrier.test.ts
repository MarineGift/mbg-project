/**
 * __tests__/email/mailcarrier.test.ts
 *
 * Unit tests - IMAP I/O is abstracted via the IImapClient / ParserFn interfaces, so
 * all replaced with fakes. Supabase responses are injected via buildSupabaseMock.
 *
 * Test scenarios:
 *   1. persistInbound - normal INSERT of a new message
 *   2. persistInbound - returns null on duplicate Message-ID (idempotency)
 *   3. persistInbound - attachment Storage upload + attachments INSERT
 *   4. persistInbound - saved with a PII-masked body
 *   5. sanitizeFilename - removes path separators / control characters
 *   6. fetchAndProcessNew - calls onMessage + Seen flag
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { Buffer } from 'node:buffer';
import type { ParsedMail } from 'mailparser';
import {
  MailCarrierClient,
  sanitizeFilename,
  type IImapClient,
  type ParserFn,
} from '../../lib/email/mailcarrier';
import type { InboundMessageEvent } from '../../types/email';
import { buildSupabaseMock, type MockSupabase } from '../setup/supabase-mock';

// ParsedMail helper
function makeParsedMail(
  overrides: Partial<ParsedMail> & { headerEntries?: Array<[string, unknown]> } = {},
): ParsedMail {
  return {
    headers: new Map<string, unknown>(overrides.headerEntries ?? []),
    headerLines: [],
    attachments: overrides.attachments ?? [],
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

function makeFakeImap(): IImapClient {
  return {
    connect: vi.fn(() => Promise.resolve()),
    logout: vi.fn(() => Promise.resolve()),
    mailboxOpen: vi.fn(() => Promise.resolve(null)),
    getMailboxLock: vi.fn(() =>
      Promise.resolve({ release: () => undefined }),
    ),
    fetch: vi.fn(() => emptyAsyncIterable()),
    messageFlagsAdd: vi.fn(() => Promise.resolve(null)),
    idle: vi.fn(() => Promise.resolve(null)),
  } as IImapClient;
}

function emptyAsyncIterable(): AsyncIterable<never> {
  return {
    [Symbol.asyncIterator]() {
      return {
        next: () => Promise.resolve({ done: true, value: undefined } as IteratorResult<never>),
      };
    },
  };
}

function asyncIterableFrom<T>(items: T[]): AsyncIterable<T> {
  return {
    [Symbol.asyncIterator]() {
      let i = 0;
      return {
        next: (): Promise<IteratorResult<T>> => {
          if (i >= items.length) return Promise.resolve({ done: true, value: undefined as never });
          const value = items[i++] as T;
          return Promise.resolve({ done: false, value });
        },
      };
    },
  };
}

const orgId = 'org-1';

describe('MailCarrierClient.persistInbound', () => {
  let supabase: MockSupabase;
  let client: MailCarrierClient;
  let parser: ParserFn;

  beforeEach(() => {
    parser = vi.fn();
    supabase = buildSupabaseMock({
      // 1st: communications duplicate check -> null (new)
      'app.communications': {
        selectMaybeSingle: { data: null },
        insertSingle: { data: { id: 'comm-new-1' } },
      },
      'app.contacts': {
        selectMaybeSingle: { data: null },
      },
      'app.attachments': {
        insertSingle: { data: { id: 'att-1' } },
      },
    });
    client = new MailCarrierClient(supabase as never, orgId, {
      imapClient: makeFakeImap(),
      parser,
    });
  });

  it('inserts a new communication with masked body', async () => {
    const parsed = makeParsedMail({
      messageId: '<new@ex.com>',
      subject: 'My phone is 010-1234-5678',
      from: {
        text: '',
        html: '',
        value: [{ name: 'Alice', address: 'alice@acmecorp.com' }],
      },
      to: { text: '', html: '', value: [{ name: '', address: 'me@org.com' }] },
      text: '내 번호는 010-1234-5678 입니다.',
      date: new Date('2026-02-01T09:00:00Z'),
    });

    const event = await client.persistInbound(parsed);

    expect(event).not.toBeNull();
    expect(event?.communicationId).toBe('comm-new-1');
    expect(event?.messageId).toBe('<new@ex.com>');
    expect(event?.bodyText).toContain('{{PII_001}}'); // phone number masked
    expect(event?.bodyText).not.toContain('010-1234-5678');
    expect(event?.piiCategories).toContain('phone_kr');

    // verify the INSERT call
    const insertCalls = supabase.__calls.insert.filter(
      (c) => c.schema === 'app' && c.table === 'communications',
    );
    expect(insertCalls).toHaveLength(1);
    const payload = insertCalls[0]?.payload as Record<string, unknown>;
    expect(payload.message_id).toBe('<new@ex.com>');
    expect(payload.direction).toBe('inbound');
    expect(payload.channel).toBe('email');
    expect(payload.from_address).toBe('alice@acmecorp.com');
    expect((payload.body_plain as string)).not.toContain('010-1234-5678');
    expect((payload.external_data as Record<string, unknown>).pii_masked).toBe(true);
  });

  it('returns null when Message-ID already exists (idempotency)', async () => {
    const sbDup = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: {
          data: { id: 'existing-comm', organization_id: orgId, thread_id: 'thread-1' },
        },
      },
    });
    const dupClient = new MailCarrierClient(sbDup as never, orgId, {
      imapClient: makeFakeImap(),
      parser: vi.fn(),
    });
    const parsed = makeParsedMail({
      messageId: '<dup@ex.com>',
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
      to: { text: '', html: '', value: [{ name: '', address: 'me@org.com' }] },
    });

    const event = await dupClient.persistInbound(parsed);

    expect(event).toBeNull();
    // INSERT should not have been called
    const inserts = sbDup.__calls.insert.filter(
      (c) => c.table === 'communications',
    );
    expect(inserts).toHaveLength(0);
  });

  it('uses thread match engagement_id when found', async () => {
    const sb = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: {
          data: { thread_id: 'matched-thread', engagement_id: 'matched-eng' },
        },
        insertSingle: { data: { id: 'comm-thread-1' } },
      },
    });
    // since the duplicate check must return null on the first call,
    // keep the chain simple: first maybeSingle is null, the next is the thread match.
    let mbCalls = 0;
    const origSchema = sb.schema;
    sb.schema = vi.fn((schemaName: string) => ({
      from: (table: string) => {
        const orig = origSchema(schemaName).from(table) as Record<string, unknown>;
        const b: Record<string, unknown> = { ...orig };
        b.maybeSingle = vi.fn(() => {
          mbCalls += 1;
          if (table === 'communications' && mbCalls === 1) {
            return Promise.resolve({ data: null, error: null });
          }
          if (table === 'communications' && mbCalls === 2) {
            return Promise.resolve({
              data: { thread_id: 'matched-thread', engagement_id: 'matched-eng' },
              error: null,
            });
          }
          // contacts match - null
          return Promise.resolve({ data: null, error: null });
        });
        b.single = vi.fn(() => Promise.resolve({ data: { id: 'comm-thread-1' }, error: null }));
        for (const m of ['select', 'eq', 'is', 'like', 'order', 'limit', 'insert']) {
          b[m] = vi.fn(() => b);
        }
        b.update = vi.fn(() => Promise.resolve({ error: null }));
        return b;
      },
    })) as unknown as typeof sb.schema;

    const c = new MailCarrierClient(sb as never, orgId, {
      imapClient: makeFakeImap(),
      parser: vi.fn(),
    });
    const parsed = makeParsedMail({
      messageId: '<reply-to-thread@ex.com>',
      from: { text: '', html: '', value: [{ name: '', address: 'x@x.com' }] },
      to: { text: '', html: '', value: [] },
      headerEntries: [['x-urm-communication-id', 'prev-comm']],
    });

    const event = await c.persistInbound(parsed);
    expect(event?.threadId).toBe('matched-thread');
  });

  it('persists attachments to Storage and attachments table', async () => {
    const parsed = makeParsedMail({
      messageId: '<att@ex.com>',
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
      to: { text: '', html: '', value: [] },
      attachments: [
        {
          filename: 'invoice.pdf',
          contentType: 'application/pdf',
          content: Buffer.from('fake pdf bytes'),
          contentDisposition: 'attachment',
          size: 14,
        } as never,
      ],
    });

    await client.persistInbound(parsed);

    // verify the Storage upload call
    const storageFromCalls = (supabase.storage.from as ReturnType<typeof vi.fn>).mock.calls;
    expect(storageFromCalls.length).toBeGreaterThan(0);

    // verify the attachments INSERT
    const attInserts = supabase.__calls.insert.filter(
      (c) => c.schema === 'app' && c.table === 'attachments',
    );
    expect(attInserts).toHaveLength(1);
    const payload = attInserts[0]?.payload as Record<string, unknown>;
    expect(payload.entity_type).toBe('communication');
    expect(payload.entity_id).toBe('comm-new-1');
    expect(payload.file_name).toBe('invoice.pdf');
    expect(payload.mime_type).toBe('application/pdf');
    expect(payload.file_size_bytes).toBe(14);
    expect(payload.content_hash_sha256).toMatch(/^[a-f0-9]{64}$/);
  });

  it('skips attachments larger than 25MB', async () => {
    const huge = Buffer.alloc(30 * 1024 * 1024);
    const parsed = makeParsedMail({
      messageId: '<huge@ex.com>',
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
      to: { text: '', html: '', value: [] },
      attachments: [
        {
          filename: 'huge.bin',
          contentType: 'application/octet-stream',
          content: huge,
          size: huge.length,
        } as never,
      ],
    });
    await client.persistInbound(parsed);
    // attachments INSERT should not occur
    const attInserts = supabase.__calls.insert.filter(
      (c) => c.table === 'attachments',
    );
    expect(attInserts).toHaveLength(0);
  });
});

describe('MailCarrierClient.fetchAndProcessNew', () => {
  it('invokes onMessage callback and marks Seen', async () => {
    const supabase = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: { data: null },
        insertSingle: { data: { id: 'comm-fetch-1' } },
      },
      'app.contacts': { selectMaybeSingle: { data: null } },
    });

    const fakeRaw = Buffer.from('raw rfc822');
    const parsed = makeParsedMail({
      messageId: '<fetch@ex.com>',
      from: { text: '', html: '', value: [{ name: '', address: 'a@b.com' }] },
      to: { text: '', html: '', value: [] },
      text: 'hello',
    });

    const imap = makeFakeImap();
    (imap.fetch as ReturnType<typeof vi.fn>).mockReturnValue(
      asyncIterableFrom([
        { source: fakeRaw, uid: 42, envelope: {} } as never,
      ]),
    );

    const parser: ParserFn = vi.fn(() => Promise.resolve(parsed));
    const onMessage = vi.fn<(event: InboundMessageEvent) => Promise<void>>(() => Promise.resolve());

    const client = new MailCarrierClient(supabase as never, orgId, {
      imapClient: imap,
      parser,
    });

    await client.fetchAndProcessNew(onMessage);

    expect(parser).toHaveBeenCalledWith(fakeRaw);
    expect(onMessage).toHaveBeenCalledTimes(1);
    const passed = onMessage.mock.calls[0]?.[0] as unknown as { messageId: string };
    expect(passed?.messageId).toBe('<fetch@ex.com>');
    expect(imap.messageFlagsAdd).toHaveBeenCalledWith(42, ['\\Seen']);
  });

  it('continues processing remaining messages when one fails', async () => {
    const supabase = buildSupabaseMock({
      'app.communications': {
        selectMaybeSingle: { data: null },
        insertSingle: { data: { id: 'comm-second' } },
      },
      'app.contacts': { selectMaybeSingle: { data: null } },
    });

    const imap = makeFakeImap();
    (imap.fetch as ReturnType<typeof vi.fn>).mockReturnValue(
      asyncIterableFrom([
        { source: Buffer.from('msg1'), uid: 1 } as never,
        { source: Buffer.from('msg2'), uid: 2 } as never,
      ]),
    );
    const parser: ParserFn = vi
      .fn()
      .mockRejectedValueOnce(new Error('parse fail'))
      .mockResolvedValueOnce(
        makeParsedMail({
          messageId: '<ok@x>',
          from: { text: '', html: '', value: [{ name: '', address: 'a@b' }] },
          to: { text: '', html: '', value: [] },
        }),
      );
    const onMessage = vi.fn<(event: InboundMessageEvent) => Promise<void>>(() => Promise.resolve());

    const client = new MailCarrierClient(supabase as never, orgId, {
      imapClient: imap,
      parser,
    });

    await client.fetchAndProcessNew(onMessage);

    // the second message is processed normally
    expect(onMessage).toHaveBeenCalledTimes(1);
    expect(imap.messageFlagsAdd).toHaveBeenCalledWith(2, ['\\Seen']);
  });
});

describe('sanitizeFilename', () => {
  it('replaces path separators with underscore', () => {
    expect(sanitizeFilename('a/b/c.pdf')).toBe('a_b_c.pdf');
    expect(sanitizeFilename('a\\b\\c.pdf')).toBe('a_b_c.pdf');
  });
  it('strips leading/trailing whitespace and dots', () => {
    expect(sanitizeFilename('  ..invoice.pdf..  ')).toBe('invoice.pdf');
  });
  it('preserves Korean and Japanese characters', () => {
    expect(sanitizeFilename('계약서.pdf')).toBe('계약서.pdf');
    expect(sanitizeFilename('請求書.pdf')).toBe('請求書.pdf');
  });
  it('truncates very long names while preserving extension', () => {
    const long = 'x'.repeat(300) + '.pdf';
    const out = sanitizeFilename(long);
    expect(out.length).toBeLessThanOrEqual(180);
    expect(out.endsWith('.pdf')).toBe(true);
  });
  it('falls back when name is empty after sanitization', () => {
    const out = sanitizeFilename('   ...   ');
    expect(out).toMatch(/^attachment-\d+$/);
  });
});
