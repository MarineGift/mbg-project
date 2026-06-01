/**
 * lib/email/tabs-mailer.mock.ts
 *
 * Mock adapter used while TABS Mailer 4 operational details have not been received.
 *
 * - sendOne(): console output + returns a `mock-{uuid}@local` message ID
 * - createCampaign(): generates a fake campaign_id
 * - getCampaignStats(): in-memory counters (injectable in tests via setMockStats)
 * - syncCampaignToMergeJob(): updates progress just like the real client
 *
 * when env.TABS_MAILER_HOST === 'mock' or TABS_MAILER_USE_MOCK=true,
 * createTabsMailer() automatically returns this class.
 */

import { randomUUID } from 'node:crypto';
import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  CampaignParams,
  CampaignCreateResult,
  SendOneInput,
  SendOneOutput,
  TabsCampaignStats,
} from '../../types/email';
import {
  TabsMailerError,
  TabsMailerQuietHoursError,
  type ITabsMailerClient,
} from './tabs-mailer';
import { evaluateQuietHours } from './quiet-hours';

/* ============================================================
 * 1. In-memory state (for test verification/reproduction)
 * ============================================================ */

interface MockSentRecord {
  messageId: string;
  to: string;
  subject: string;
  urmCommunicationId: string;
  urmEngagementId?: string;
  autoSend: boolean;
  sentAt: string;
}

interface MockCampaign {
  tabsCampaignId: string;
  name: string;
  recipientCount: number;
  createdAt: Date;
  scheduledAt?: Date;
  stats: TabsCampaignStats;
}

/* ============================================================
 * 2. TabsMailerMockClient
 * ============================================================ */

export class TabsMailerMockClient implements ITabsMailerClient {
  private readonly sentLog: MockSentRecord[] = [];
  private readonly campaigns: Map<string, MockCampaign> = new Map();
  private readonly nowProvider: () => Date;

  constructor(options: { nowProvider?: () => Date } = {}) {
    this.nowProvider = options.nowProvider ?? (() => new Date());
  }

  async verify(): Promise<void> {
    // mock always passes verify
    return Promise.resolve();
  }

  async sendOne(input: SendOneInput): Promise<SendOneOutput> {
    // quiet hours validation (mock behaves the same)
    if (!input.bypassQuietHours && input.quietHours) {
      const verdict = evaluateQuietHours(input.quietHours, this.nowProvider());
      if (verdict.blocked) {
        throw new TabsMailerQuietHoursError(
          `Send blocked by quiet hours: ${verdict.reason ?? 'unknown'}`,
          verdict.reason ?? 'unknown',
          verdict.nextAllowedAt,
        );
      }
    }

    const messageId = `<mock-${randomUUID()}@local>`;
    const sentAt = this.nowProvider().toISOString();

    this.sentLog.push({
      messageId,
      to: input.to.address,
      subject: input.subject,
      urmCommunicationId: input.urmHeaders.communicationId,
      urmEngagementId: input.urmHeaders.engagementId,
      autoSend: input.urmHeaders.autoSend,
      sentAt,
    });

    // eslint-disable-next-line no-console
    console.log(
      `[tabs-mailer:mock] sendOne to=${input.to.address} subject="${input.subject.slice(0, 60)}" message_id=${messageId} auto_send=${input.urmHeaders.autoSend}`,
    );

    return {
      messageId,
      acceptedRecipients: [input.to.address],
      rejectedRecipients: [],
      rawResponse: `250 2.0.0 Mock OK ${messageId}`,
      sentAt,
    };
  }

  async createCampaign(
    params: CampaignParams,
  ): Promise<CampaignCreateResult> {
    const tabsCampaignId = `mock-campaign-${randomUUID()}`;
    const stats: TabsCampaignStats = {
      tabsCampaignId,
      totalSent: 0,
      totalDelivered: 0,
      totalOpened: 0,
      totalClicked: 0,
      totalBounced: 0,
      totalUnsubscribed: 0,
      totalFailed: 0,
      totalReplied: 0,
      lastUpdatedAt: this.nowProvider(),
    };
    const campaign: MockCampaign = {
      tabsCampaignId,
      name: params.name,
      recipientCount: params.recipientCount,
      createdAt: this.nowProvider(),
      scheduledAt: params.scheduledAt,
      stats,
    };
    this.campaigns.set(tabsCampaignId, campaign);

    // eslint-disable-next-line no-console
    console.log(
      `[tabs-mailer:mock] createCampaign id=${tabsCampaignId} name="${params.name}" recipients=${params.recipientCount}`,
    );

    return { tabsCampaignId, status: 'queued' };
  }

  async getCampaignStats(tabsCampaignId: string): Promise<TabsCampaignStats> {
    const campaign = this.campaigns.get(tabsCampaignId);
    if (!campaign) {
      throw new TabsMailerError(
        `Mock campaign not found: ${tabsCampaignId}`,
      );
    }
    return campaign.stats;
  }

  async syncCampaignToMergeJob(
    supabase: SupabaseClient,
    organizationId: string,
    jobId: string,
  ): Promise<void> {
    const { data: job } = await supabase
      .schema('app')
      .from('mail_merge_jobs')
      .select('id, tabs_campaign_id')
      .eq('id', jobId)
      .eq('organization_id', organizationId)
      .maybeSingle();

    if (!job?.tabs_campaign_id) return;

    const stats = await this.getCampaignStats(job.tabs_campaign_id);
    await supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update({
        progress: {
          sent: stats.totalSent,
          failed: stats.totalFailed,
          opened: stats.totalOpened,
          clicked: stats.totalClicked,
          replied: stats.totalReplied,
          bounced: stats.totalBounced,
          unsubscribed: stats.totalUnsubscribed,
        },
        tabs_campaign_status: 'synced',
        tabs_campaign_synced_at: stats.lastUpdatedAt.toISOString(),
      })
      .eq('id', jobId)
      .eq('organization_id', organizationId);
  }

  async close(): Promise<void> {
    return Promise.resolve();
  }

  /* ----------------------------------------------------------
   * Test helpers - for verification/injection (not present on the real client)
   * ---------------------------------------------------------- */

  /** Get the send log. Verifies sendOne calls in tests. */
  getSentLog(): readonly MockSentRecord[] {
    return this.sentLog;
  }

  /** Reset the send log. Used in test setUp/tearDown. */
  clearSentLog(): void {
    this.sentLog.length = 0;
  }

  /** Force-inject campaign stats. Verifies syncCampaignToMergeJob. */
  setMockStats(
    tabsCampaignId: string,
    patch: Partial<Omit<TabsCampaignStats, 'tabsCampaignId'>>,
  ): void {
    const c = this.campaigns.get(tabsCampaignId);
    if (!c) {
      throw new Error(`setMockStats: campaign not found: ${tabsCampaignId}`);
    }
    c.stats = {
      ...c.stats,
      ...patch,
      tabsCampaignId,
      lastUpdatedAt: patch.lastUpdatedAt ?? this.nowProvider(),
    };
  }

  /** Reset all campaigns. */
  clearCampaigns(): void {
    this.campaigns.clear();
  }
}
