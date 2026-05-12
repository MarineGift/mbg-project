/**
 * lib/email/tabs-mailer.mock.ts
 *
 * TABS Mailer 4의 운영 정보 미수령 동안 사용하는 mock 어댑터.
 *
 * - sendOne(): 콘솔 출력 + `mock-{uuid}@local` 메시지 ID 반환
 * - createCampaign(): 가짜 campaign_id 생성
 * - getCampaignStats(): 메모리 카운터(테스트에서 setMockStats로 주입 가능)
 * - syncCampaignToMergeJob(): 실 클라이언트와 동일하게 progress 갱신
 *
 * env.TABS_MAILER_HOST === 'mock' 또는 TABS_MAILER_USE_MOCK=true 시
 * createTabsMailer()가 자동으로 본 클래스를 반환한다.
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
 * 1. 메모리 상태 (테스트 검증·재현용)
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
    // mock은 항상 verify 통과
    return Promise.resolve();
  }

  async sendOne(input: SendOneInput): Promise<SendOneOutput> {
    // quiet hours 검증 (mock도 동일 동작)
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
   * 테스트 헬퍼 — 검증·주입용 (실 클라이언트에는 없음)
   * ---------------------------------------------------------- */

  /** 발송 기록 조회. 테스트에서 sendOne 호출 검증. */
  getSentLog(): readonly MockSentRecord[] {
    return this.sentLog;
  }

  /** 발송 기록 초기화. 테스트 setUp/tearDown에서 사용. */
  clearSentLog(): void {
    this.sentLog.length = 0;
  }

  /** 캠페인 통계 강제 주입. syncCampaignToMergeJob 검증. */
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

  /** 모든 캠페인 초기화. */
  clearCampaigns(): void {
    this.campaigns.clear();
  }
}
