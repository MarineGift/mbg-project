import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { ParsedMail } from 'mailparser';
import {
  parseInboundMessage,
  normalizeMessageId,
  parseReferences,
  findThreadId,
  findContactByEmail,
  type ParsedHeaders,
} from '@/lib/email/header-parser';

type HeaderMap = Map<string, string | string[]>;

function makeParsedMail(overrides: Partial<ParsedMail> & {
  customHeaders?: Record<string, string>;
}): ParsedMail {
  const headers: HeaderMap = new Map();
  if (overrides.customHeaders) {
    for (const [k, v] of Object.entries(overrides.customHeaders)) {
      headers.set(k.toLowerCase(), v);
    }
  }

  return {
    headers: headers as unknown as ParsedMail['headers'],
    headerLines: [],
    text: '',
    html: false,
    textAsHtml: '',
    subject: '(no subject)',
    date: new Date('2026-05-09T00:00:00Z'),
    to: undefined,
    cc: undefined,
    bcc: undefined,
    from: undefined,
    replyTo: undefined,
    messageId: undefined,
    inReplyTo: undefined,
    references: undefined,
    attachments: [],
    ...overrides,
  } as unknown as ParsedMail;
}

describe('parseInboundMessage', () => {
  it('extracts basic fields from a minimal ParsedMail', () => {
    const pm = makeParsedMail({
      messageId: '<abc-123@sender.example.com>',
      subject: 'Hello',
      from: {
        value: [{ name: 'Alice', address: 'alice@example.com' }],
        text: 'Alice <alice@example.com>',
        html: '',
      },
      to: {
        value: [{ name: 'Bob', address: 'bob@example.com' }],
        text: 'Bob <bob@example.com>',
        html: '',
      },
      date: new Date('2026-05-08T12:00:00Z'),
    });
    const headers = parseInboundMessage(pm);

    expect(headers.messageId).toBe('<abc-123@sender.example.com>');
    expect(headers.subject).toBe('Hello');
    expect(headers.from).toEqual({ name: 'Alice', address: 'alice@example.com' });
    expect(headers.to).toEqual([{ name: 'Bob', address: 'bob@example.com' }]);
    expect(headers.cc).toEqual([]);
    expect(headers.references).toEqual([]);
    expect(headers.urmHeaders).toEqual({});
  });

  it('extracts X-URM-* custom headers', () => {
    const pm = makeParsedMail({
      messageId: '<m1@x.com>',
      from: {
        value: [{ address: 'a@b.com', name: '' }],
        text: 'a@b.com',
        html: '',
      },
      customHeaders: {
        'X-URM-Communication-Id': 'comm-123',
        'X-URM-Engagement-Id': 'eng-456',
        'X-URM-Auto-Send': 'true',
        'X-URM-Brand-Voice-Id': 'bv-7',
        'X-URM-Thread-Id': 'thread-9',
        'X-URM-Party-Id': 'party-77',
      },
    });
    const headers = parseInboundMessage(pm);

    expect(headers.urmHeaders).toEqual({
      communicationId: 'comm-123',
      engagementId: 'eng-456',
      autoSend: true,
      brandVoiceId: 'bv-7',
      threadId: 'thread-9',
      partyId: 'party-77',
    });
  });

  it('treats X-URM-Auto-Send as case-insensitive boolean', () => {
    const pm = makeParsedMail({
      messageId: '<m@x>',
      from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
      customHeaders: { 'X-URM-Auto-Send': 'TRUE' },
    });
    expect(parseInboundMessage(pm).urmHeaders.autoSend).toBe(true);

    const pm2 = makeParsedMail({
      messageId: '<m2@x>',
      from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
      customHeaders: { 'X-URM-Auto-Send': 'false' },
    });
    expect(parseInboundMessage(pm2).urmHeaders.autoSend).toBe(false);
  });

  it('falls back to (no subject) and unknown@unknown for missing fields', () => {
    const pm = makeParsedMail({ messageId: undefined, subject: undefined, from: undefined });
    const headers = parseInboundMessage(pm);

    expect(headers.messageId).toMatch(/^<missing-/);
    expect(headers.subject).toBe('(no subject)');
    expect(headers.from.address).toBe('unknown@unknown');
  });

  it('parses content-language header', () => {
    const pm = makeParsedMail({
      messageId: '<m@x>',
      from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
      customHeaders: { 'Content-Language': 'ja-JP' },
    });
    expect(parseInboundMessage(pm).contentLanguage).toBe('ja-JP');
  });
});

describe('normalizeMessageId', () => {
  it('returns the trimmed value when present', () => {
    expect(normalizeMessageId('  <abc@x>  ')).toBe('<abc@x>');
  });
  it('generates a fallback when undefined', () => {
    const v = normalizeMessageId(undefined);
    expect(v).toMatch(/^<missing-\d+-[a-z0-9]+@local\.urm>$/);
  });
  it('generates a fallback when empty', () => {
    expect(normalizeMessageId('')).toMatch(/^<missing-/);
    expect(normalizeMessageId('   ')).toMatch(/^<missing-/);
  });
});

describe('parseReferences', () => {
  it('returns empty for undefined', () => {
    expect(parseReferences(undefined)).toEqual([]);
  });
  it('handles array input', () => {
    expect(parseReferences(['<a@x>', '<b@x>'])).toEqual(['<a@x>', '<b@x>']);
  });
  it('splits whitespace-separated string', () => {
    expect(parseReferences('<a@x> <b@x>\n<c@x>')).toEqual(['<a@x>', '<b@x>', '<c@x>']);
  });
  it('trims and drops empty tokens', () => {
    expect(parseReferences('  <a@x>   <b@x>  ')).toEqual(['<a@x>', '<b@x>']);
  });
});

interface MaybeSingleResult<T> { data: T | null; error: null | { message: string } }

function makeSupabaseMock(
  responses: ReadonlyArray<MaybeSingleResult<{ thread_id?: string }>>,
) {
  let callIdx = 0;
  const maybeSingle = vi.fn(async () => {
    const res = responses[callIdx];
    callIdx += 1;
    return res ?? { data: null, error: null };
  });
  const chain = {
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    is: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
    maybeSingle,
  };
  const from = vi.fn(() => chain);
  return {
    schema: vi.fn(() => ({ from })),
    from,
    _chain: chain,
    _maybeSingle: maybeSingle,
  } as unknown as {
    schema: ReturnType<typeof vi.fn>;
    from: ReturnType<typeof vi.fn>;
    _maybeSingle: typeof maybeSingle;
  };
}

const baseHeaders: ParsedHeaders = {
  messageId: '<incoming@x>',
  references: [],
  from: { address: 'sender@x' },
  to: [],
  cc: [],
  bcc: [],
  subject: 's',
  date: new Date(),
  urmHeaders: {},
};

describe('findThreadId', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('priority 1: returns urmHeaders.threadId without DB hit', async () => {
    const supa = makeSupabaseMock([]);
    const tid = await findThreadId(supa as never, 'org-1', {
      ...baseHeaders,
      urmHeaders: { threadId: 'thread-aaa' },
    });
    expect(tid).toBe('thread-aaa');
    expect(supa._maybeSingle).not.toHaveBeenCalled();
  });

  it('priority 2: looks up thread by communicationId', async () => {
    const supa = makeSupabaseMock([
      { data: { thread_id: 'thread-from-comm' }, error: null },
    ]);
    const tid = await findThreadId(supa as never, 'org-1', {
      ...baseHeaders,
      urmHeaders: { communicationId: 'comm-1' },
    });
    expect(tid).toBe('thread-from-comm');
    expect(supa._maybeSingle).toHaveBeenCalledTimes(1);
  });

  it('priority 3: looks up thread by inReplyTo when comm-id missing', async () => {
    const supa = makeSupabaseMock([
      { data: { thread_id: 'thread-from-irt' }, error: null },
    ]);
    const tid = await findThreadId(supa as never, 'org-1', {
      ...baseHeaders,
      inReplyTo: '<earlier@x>',
    });
    expect(tid).toBe('thread-from-irt');
  });

  it('priority 4: looks up references in reverse order', async () => {
    const supa = makeSupabaseMock([
      { data: null, error: null },
      { data: { thread_id: 'thread-from-ref-2' }, error: null },
    ]);
    const tid = await findThreadId(supa as never, 'org-1', {
      ...baseHeaders,
      references: ['<ref-2@x>', '<ref-1@x>'],
    });
    expect(tid).toBe('thread-from-ref-2');
    expect(supa._maybeSingle).toHaveBeenCalledTimes(2);
  });

  it('returns null when nothing matches', async () => {
    const supa = makeSupabaseMock([
      { data: null, error: null },
      { data: null, error: null },
    ]);
    const tid = await findThreadId(supa as never, 'org-1', {
      ...baseHeaders,
      inReplyTo: '<missing@x>',
      references: ['<also-missing@x>'],
    });
    expect(tid).toBeNull();
  });
});

describe('findContactByEmail', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns null for empty email', async () => {
    const supa = makeSupabaseMock([]);
    const r = await findContactByEmail(supa as never, 'org-1', '');
    expect(r).toBeNull();
  });

  it('returns contact and party when matched', async () => {
    const maybeSingle = vi
      .fn()
      .mockResolvedValueOnce({ data: { id: 'c-1', party_id: 'p-1' }, error: null });
    const chain = {
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      is: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      maybeSingle,
    };
    const supa = {
      schema: vi.fn(() => ({ from: vi.fn(() => chain) })),
    };

    const r = await findContactByEmail(supa as never, 'org-1', 'a@b.com');
    expect(r).toEqual({ contactId: 'c-1', partyId: 'p-1' });
  });

  it('returns null when no contact found', async () => {
    const maybeSingle = vi.fn().mockResolvedValueOnce({ data: null, error: null });
    const chain = {
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      is: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      maybeSingle,
    };
    const supa = { schema: vi.fn(() => ({ from: vi.fn(() => chain) })) };
    const r = await findContactByEmail(supa as never, 'org-1', 'a@b.com');
    expect(r).toBeNull();
  });
});
