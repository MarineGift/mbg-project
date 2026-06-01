/**
 * __tests__/email/tabs-mailer.test.ts
 *
 * Verifies both TabsMailerClient (real SMTP) + TabsMailerMockClient (mock).
 * The SMTP transporter is replaced with a nodemailer.createTransport stub.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  TabsMailerClient,
  TabsMailerNotImplementedError,
  TabsMailerQuietHoursError,
} from '../../lib/email/tabs-mailer';
import { TabsMailerMockClient } from '../../lib/email/tabs-mailer.mock';
import { URM_HEADER_NAMES, type SendOneInput } from '../../types/email';
import { buildSupabaseMock } from '../setup/supabase-mock';

function makeFakeTransporter(
  sendMailImpl?: (opts: unknown) => Promise<unknown>,
): {
  sendMail: ReturnType<typeof vi.fn>;
  verify: ReturnType<typeof vi.fn>;
  close: ReturnType<typeof vi.fn>;
} {
  return {
    sendMail: vi.fn(
      sendMailImpl ??
        ((opts: unknown) => {
          // mimic the nodemailer response shape
          void opts;
          return Promise.resolve({
            messageId: '<smtp-msg-id@local>',
            accepted: ['to@x.com'],
            rejected: [],
            response: '250 OK',
          });
        }),
    ),
    verify: vi.fn(() => Promise.resolve(true)),
    close: vi.fn(),
  };
}

const baseSendInput: SendOneInput = {
  to: { name: 'Bob', address: 'to@x.com' },
  fromName: 'Sender',
  fromAddress: 'sender@org.com',
  subject: 'Hello',
  bodyText: 'Plain body',
  bodyHtml: '<p>Hello</p>',
  urmHeaders: {
    communicationId: 'comm-123',
    autoSend: false,
    engagementId: 'eng-456',
    brandVoiceId: 'bv-789',
  },
};

describe('TabsMailerClient.sendOne', () => {
  let transporter: ReturnType<typeof makeFakeTransporter>;
  let client: TabsMailerClient;

  beforeEach(() => {
    transporter = makeFakeTransporter();
    client = new TabsMailerClient({ transporter: transporter as never });
  });

  it('attaches X-URM-* headers correctly', async () => {
    const out = await client.sendOne(baseSendInput);

    expect(out.messageId).toBe('<smtp-msg-id@local>');
    expect(out.acceptedRecipients).toEqual(['to@x.com']);

    const callArgs = transporter.sendMail.mock.calls[0]?.[0] as Record<string, unknown>;
    const headers = callArgs.headers as Record<string, string>;
    expect(headers[URM_HEADER_NAMES.communicationId]).toBe('comm-123');
    expect(headers[URM_HEADER_NAMES.engagementId]).toBe('eng-456');
    expect(headers[URM_HEADER_NAMES.brandVoiceId]).toBe('bv-789');
    expect(headers[URM_HEADER_NAMES.autoSend]).toBe('false');
  });

  it('appends invisible footer to HTML body', async () => {
    await client.sendOne(baseSendInput);
    const callArgs = transporter.sendMail.mock.calls[0]?.[0] as Record<string, unknown>;
    const html = callArgs.html as string;
    expect(html).toContain('<!-- urm:c=comm-123;auto=0;e=eng-456 -->');
  });

  it('autoSend=true encodes as auto=1 in footer', async () => {
    await client.sendOne({
      ...baseSendInput,
      urmHeaders: { ...baseSendInput.urmHeaders, autoSend: true },
    });
    const callArgs = transporter.sendMail.mock.calls[0]?.[0] as Record<string, unknown>;
    const headers = callArgs.headers as Record<string, string>;
    expect(headers[URM_HEADER_NAMES.autoSend]).toBe('true');
    expect((callArgs.html as string)).toContain('auto=1');
  });

  it('blocks when within quiet hours', async () => {
    await expect(
      client.sendOne({
        ...baseSendInput,
        quietHours: {
          timezone: 'UTC',
          start: '00:00',
          end: '23:59',
          weekends_blocked: false,
        },
      }),
    ).rejects.toBeInstanceOf(TabsMailerQuietHoursError);
  });

  it('bypassQuietHours overrides the check', async () => {
    await expect(
      client.sendOne({
        ...baseSendInput,
        bypassQuietHours: true,
        quietHours: {
          timezone: 'UTC',
          start: '00:00',
          end: '23:59',
          weekends_blocked: false,
        },
      }),
    ).resolves.toMatchObject({ messageId: expect.any(String) });
  });

  it('wraps SMTP errors in TabsMailerError', async () => {
    const failing = makeFakeTransporter(() =>
      Promise.reject(new Error('554 message rejected')),
    );
    const c = new TabsMailerClient({ transporter: failing as never });
    await expect(c.sendOne(baseSendInput)).rejects.toThrow(/sendOne failed/);
  });
});

describe('TabsMailerClient.createCampaign / getCampaignStats', () => {
  it('throws NotImplementedError until TABS Lab spec is received', async () => {
    const client = new TabsMailerClient({
      transporter: makeFakeTransporter() as never,
    });
    await expect(
      client.createCampaign({
        name: 'Test',
        templateId: 't-1',
        recipientCount: 100,
        fromAddress: 'a@b.com',
      }),
    ).rejects.toBeInstanceOf(TabsMailerNotImplementedError);

    await expect(client.getCampaignStats('campaign-1')).rejects.toBeInstanceOf(
      TabsMailerNotImplementedError,
    );
  });
});

describe('TabsMailerMockClient', () => {
  it('records sent emails and returns mock messageId', async () => {
    const mock = new TabsMailerMockClient();
    const out = await mock.sendOne(baseSendInput);
    expect(out.messageId).toMatch(/^<mock-[a-f0-9-]+@local>$/);

    const log = mock.getSentLog();
    expect(log).toHaveLength(1);
    expect(log[0]?.to).toBe('to@x.com');
    expect(log[0]?.urmCommunicationId).toBe('comm-123');
  });

  it('createCampaign returns a deterministic shape', async () => {
    const mock = new TabsMailerMockClient();
    const r = await mock.createCampaign({
      name: 'Q1',
      templateId: 't-1',
      recipientCount: 50,
      fromAddress: 'a@b.com',
    });
    expect(r.tabsCampaignId).toMatch(/^mock-campaign-/);
    expect(r.status).toBe('queued');
  });

  it('setMockStats + syncCampaignToMergeJob updates mail_merge_jobs.progress', async () => {
    const mock = new TabsMailerMockClient();
    const created = await mock.createCampaign({
      name: 'Q1',
      templateId: 't-1',
      recipientCount: 50,
      fromAddress: 'a@b.com',
    });
    mock.setMockStats(created.tabsCampaignId, {
      totalSent: 30,
      totalOpened: 20,
      totalClicked: 5,
    });

    const sb = buildSupabaseMock({
      'app.mail_merge_jobs': {
        selectMaybeSingle: {
          data: { id: 'job-1', tabs_campaign_id: created.tabsCampaignId },
        },
        updateResult: { error: null },
      },
    });

    await mock.syncCampaignToMergeJob(sb as never, 'org-1', 'job-1');

    // whether the UPDATE call updated progress
    const updates = sb.__calls.update.filter(
      (c) => c.schema === 'app' && c.table === 'mail_merge_jobs',
    );
    expect(updates).toHaveLength(1);
    const payload = updates[0]?.payload as Record<string, unknown>;
    const progress = payload.progress as Record<string, number>;
    expect(progress.sent).toBe(30);
    expect(progress.opened).toBe(20);
    expect(progress.clicked).toBe(5);
  });

  it('blocks send when within quiet hours (parity with real client)', async () => {
    const mock = new TabsMailerMockClient();
    await expect(
      mock.sendOne({
        ...baseSendInput,
        quietHours: {
          timezone: 'UTC',
          start: '00:00',
          end: '23:59',
          weekends_blocked: false,
        },
      }),
    ).rejects.toBeInstanceOf(TabsMailerQuietHoursError);
  });
});
