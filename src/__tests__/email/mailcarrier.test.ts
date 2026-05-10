import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import type { ParsedMail } from 'mailparser';
import {
  MailCarrierClient,
  MailCarrierError,
  MailCarrierConnectionError,
} from '@/lib/email/mailcarrier';

vi.mock('@/lib/env', () => ({
  env: {
    MAILCARRIER_HOST: 'imap.example.com',
    MAILCARRIER_PORT: 993,
    MAILCARRIER_USERNAME: 'user@example.com',
    MAILCARRIER_PASSWORD: 'pass',
    MAILCARRIER_USE_IDLE: false,
    MAILCARRIER_INBOX_FOLDER: 'INBOX',
    MAILCARRIER_POLL_INTERVAL_SECONDS: 30,
    SUPABASE_STORAGE_BUCKET_ATTACHMENTS: 'communications-attachments',
  },
}));

const simpleParserMock = vi.fn();
vi.mock('mailparser', () => ({
  simpleParser: (src: unknown) => simpleParserMock(src),
}));

function makeParsedMail(p: Partial<ParsedMail>): ParsedMail {
  return {
    headers: new Map(),
    headerLines: [],
    text: '',
    html: false,
    textAsHtml: '',
    subject: '(no subject)',
    date: new Date('2026-05-09T00:00:00Z'),
    attachments: [],
    ...p,
  } as unknown as ParsedMail;
}

interface SupabaseStubOptions {
  existing?: { id: string } | null;
  threadResults?: Array<{ thread_id?: string } | null>;
  contactResult?: { id: string; party_id?: string | null } | null;
  insertResult?: { id: string } | null;
  insertError?: { code?: string; message: string } | null;
}

function makeSupabaseStub(opts: SupabaseStubOptions) {
  const calls = {
    selects: [] as Array<{ table: string; filters: Array<[string, unknown]> }>,
    inserts: [] as Array<{ table: string; payload: Record<string, unknown> }>,
    storageUploads: [] as Array<{ bucket: string; path: string }>,
  };

  let threadIdx = 0;

  const buildSelectChain = (table: string) => {
    const filters: Array<[string, unknown]> = [];
    const chain: Record<string, unknown> = {};
    chain.select = vi.fn(() => chain);
    chain.eq = vi.fn((col: string, val: unknown) => {
      filters.push([col, val]);
      return chain;
    });
    chain.is = vi.fn(() => chain);
    chain.limit = vi.fn(() => chain);
    chain.maybeSingle = vi.fn(async () => {
      calls.selects.push({ table, filters: [...filters] });
      const isMessageIdCheck = filters.some(([k]) => k === 'message_id');
      const isContactCheck = table === 'contacts';
      if (isMessageIdCheck && filters.length === 2) {
        return { data: opts.existing ?? null, error: null };
      }
      if (isContactCheck) {
        return { data: opts.contactResult ?? null, error: null };
      }
      const next = (opts.threadResults ?? [])[threadIdx];
      threadIdx += 1;
      return { data: next ?? null, error: null };
    });
    return chain;
  };

  const buildInsertChain = (table: string) => {
    return {
      insert: vi.fn((p: Record<string, unknown>) => {
        // 동기적으로 calls.inserts에 push (bare await 경로 포함 모든 호출 추적)
        calls.inserts.push({ table, payload: p });
        const result = opts.insertError
          ? { data: null, error: opts.insertError }
          : { data: opts.insertResult ?? { id: 'comm-new' }, error: null };
        // 반환 객체는 select/single 체이닝과 bare await 모두 지원해야 함
        const chained: {
          select: ReturnType<typeof vi.fn>;
          single: ReturnType<typeof vi.fn>;
          then: (
            resolve: (v: typeof result) => unknown,
            reject?: (e: unknown) => unknown,
          ) => unknown;
        } = {
          select: vi.fn(() => ({
            single: vi.fn(async () => result),
          })),
          single: vi.fn(async () => result),
          // thenable: bare `await supabase.from('x').insert(...)` 경로 처리
          then: (resolve) => Promise.resolve(result).then(resolve),
        };
        return chained;
      }),
    };
  };

  const fromBuilder = (table: string) => {
    const chain = buildSelectChain(table);
    const insert = buildInsertChain(table).insert;
    return Object.assign(chain, { insert });
  };

  const supa = {
    schema: vi.fn(() => ({
      from: vi.fn((table: string) => fromBuilder(table)),
    })),
    storage: {
      from: vi.fn((bucket: string) => ({
        upload: vi.fn(async (path: string) => {
          calls.storageUploads.push({ bucket, path });
          return { error: null };
        }),
      })),
    },
  };

  return { supa, calls };
}

type FakeImapClient = {
  connect: ReturnType<typeof vi.fn>;
  logout: ReturnType<typeof vi.fn>;
  idle: ReturnType<typeof vi.fn>;
  mailboxOpen: ReturnType<typeof vi.fn>;
  getMailboxLock: ReturnType<typeof vi.fn>;
  messageFlagsAdd: ReturnType<typeof vi.fn>;
  fetch: ReturnType<typeof vi.fn>;
};

function makeFakeImap(messages: Array<{ uid: number; source: Buffer }>): {
  client: FakeImapClient;
  calls: {
    connect: number;
    logout: number;
    flagsAdded: Array<{ uid: number; flags: string[] }>;
  };
} {
  const calls = {
    connect: 0,
    logout: 0,
    flagsAdded: [] as Array<{ uid: number; flags: string[] }>,
  };
  const lock = { release: vi.fn() };

  const client: FakeImapClient = {
    connect: vi.fn(async () => {
      calls.connect += 1;
    }),
    logout: vi.fn(async () => {
      calls.logout += 1;
    }),
    idle: vi.fn(async () => {}),
    mailboxOpen: vi.fn(async () => {}),
    getMailboxLock: vi.fn(async () => lock),
    messageFlagsAdd: vi.fn(async (uid: number, flags: string[]) => {
      calls.flagsAdded.push({ uid, flags });
    }),
    fetch: vi.fn(() => {
      return (async function* () {
        for (const m of messages) {
          yield { uid: m.uid, source: m.source };
        }
      })();
    }),
  };

  return { client, calls };
}

describe('MailCarrierClient', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    simpleParserMock.mockReset();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('connect() succeeds', async () => {
    const { supa } = makeSupabaseStub({});
    const fake = makeFakeImap([]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);
    await expect(mc.connect()).resolves.not.toThrow();
    expect(fake.calls.connect).toBe(1);
  });

  it('connect() wraps errors in MailCarrierConnectionError', async () => {
    const { supa } = makeSupabaseStub({});
    const fake = makeFakeImap([]);
    fake.client.connect = vi.fn(async () => {
      throw new Error('ECONNREFUSED');
    });
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);
    await expect(mc.connect()).rejects.toBeInstanceOf(MailCarrierConnectionError);
  });

  it('persists a fresh inbound message and inserts communications + attachment', async () => {
    const parsed = makeParsedMail({
      messageId: '<new@x.com>',
      subject: 'Hi',
      from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
      to: { value: [{ address: 'us@us.com', name: '' }], text: '', html: '' },
      text: 'Hello world. My phone: 010-1234-5678',
      attachments: [
        {
          filename: 'order.pdf',
          contentType: 'application/pdf',
          content: Buffer.from('PDF-fake-content'),
          size: 16,
        } as never,
      ],
    });
    simpleParserMock.mockResolvedValueOnce(parsed);

    const { supa, calls } = makeSupabaseStub({
      existing: null,
      threadResults: [],
      contactResult: null,
      insertResult: { id: 'comm-1' },
    });

    const fake = makeFakeImap([{ uid: 1, source: Buffer.from('raw') }]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);

    const handler = vi.fn<(m: import('@/lib/email/mailcarrier').InboundMessageNotification) => Promise<void>>(
      async () => {},
    );
    (mc as unknown as { isRunning: boolean }).isRunning = true;
    await (mc as unknown as {
      fetchAndProcessNew: (h: typeof handler) => Promise<void>;
    }).fetchAndProcessNew(handler);

    expect(calls.inserts.find((i) => i.table === 'communications')).toBeTruthy();
    const commInsert = calls.inserts.find((i) => i.table === 'communications')!;
    expect(commInsert.payload.organization_id).toBe('org-1');
    expect(commInsert.payload.direction).toBe('inbound');
    expect(commInsert.payload.channel).toBe('email');
    expect(commInsert.payload.message_id).toBe('<new@x.com>');
    expect(commInsert.payload.pii_masked).toBe(true);
    expect(String(commInsert.payload.body_plain)).not.toContain('010-1234-5678');
    expect(String(commInsert.payload.body_plain)).toContain('{{PII_');

    const attInsert = calls.inserts.find((i) => i.table === 'attachments');
    expect(attInsert).toBeTruthy();
    expect(attInsert!.payload.file_name).toBe('order.pdf');

    expect(calls.storageUploads).toHaveLength(1);
    expect(calls.storageUploads[0]?.path).toMatch(/^org-1\/comm-1\/order\.pdf$/);

    expect(fake.calls.flagsAdded).toEqual([{ uid: 1, flags: ['\\Seen'] }]);

    expect(handler).toHaveBeenCalledTimes(1);
    expect(handler.mock.calls[0]?.[0]).toMatchObject({
      communicationId: 'comm-1',
      messageId: '<new@x.com>',
      organizationId: 'org-1',
    });
  });

  it('skips duplicate message-id (idempotency)', async () => {
    const parsed = makeParsedMail({
      messageId: '<dup@x>',
      from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
    });
    simpleParserMock.mockResolvedValueOnce(parsed);

    const { supa, calls } = makeSupabaseStub({
      existing: { id: 'already-inserted' },
    });

    const fake = makeFakeImap([{ uid: 7, source: Buffer.from('raw') }]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);

    const handler = vi.fn();
    (mc as unknown as { isRunning: boolean }).isRunning = true;
    await (mc as unknown as {
      fetchAndProcessNew: (h: typeof handler) => Promise<void>;
    }).fetchAndProcessNew(handler);

    expect(calls.inserts).toHaveLength(0);
    expect(fake.calls.flagsAdded).toEqual([{ uid: 7, flags: ['\\Seen'] }]);
    expect(handler).not.toHaveBeenCalled();
  });

  it('does not mark Seen when INSERT fails (non-23505)', async () => {
    simpleParserMock.mockResolvedValueOnce(
      makeParsedMail({
        messageId: '<err@x>',
        from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
      }),
    );

    const { supa } = makeSupabaseStub({
      existing: null,
      insertError: { message: 'connection lost', code: 'XX000' },
    });

    const fake = makeFakeImap([{ uid: 9, source: Buffer.from('raw') }]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);

    const handler = vi.fn();
    (mc as unknown as { isRunning: boolean }).isRunning = true;
    await (mc as unknown as {
      fetchAndProcessNew: (h: typeof handler) => Promise<void>;
    }).fetchAndProcessNew(handler);

    expect(fake.calls.flagsAdded).toEqual([]);
    expect(handler).not.toHaveBeenCalled();
  });

  it('treats UNIQUE violation (23505) as duplicate', async () => {
    simpleParserMock.mockResolvedValueOnce(
      makeParsedMail({
        messageId: '<race@x>',
        from: { value: [{ address: 'a@b.com', name: '' }], text: '', html: '' },
      }),
    );

    const { supa } = makeSupabaseStub({
      existing: null,
      insertError: { message: 'duplicate key', code: '23505' },
    });

    const fake = makeFakeImap([{ uid: 11, source: Buffer.from('raw') }]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);

    const handler = vi.fn();
    (mc as unknown as { isRunning: boolean }).isRunning = true;
    await (mc as unknown as {
      fetchAndProcessNew: (h: typeof handler) => Promise<void>;
    }).fetchAndProcessNew(handler);

    expect(fake.calls.flagsAdded).toEqual([{ uid: 11, flags: ['\\Seen'] }]);
    expect(handler).not.toHaveBeenCalled();
  });

  it('startListening throws if already running', async () => {
    const { supa } = makeSupabaseStub({});
    const fake = makeFakeImap([]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);

    (mc as unknown as { isRunning: boolean }).isRunning = true;
    await expect(mc.startListening(async () => {})).rejects.toBeInstanceOf(MailCarrierError);
  });

  it('stop() clears running state and calls logout', async () => {
    const { supa } = makeSupabaseStub({});
    const fake = makeFakeImap([]);
    const mc = new MailCarrierClient(supa as never, 'org-1', fake.client as unknown as import('imapflow').ImapFlow);
    (mc as unknown as { isRunning: boolean }).isRunning = true;

    await mc.stop();
    expect((mc as unknown as { isRunning: boolean }).isRunning).toBe(false);
    expect(fake.calls.logout).toBe(1);
  });
});
