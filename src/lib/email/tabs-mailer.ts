import nodemailer, { type Transporter } from 'nodemailer';
import type SMTPTransport from 'nodemailer/lib/smtp-transport';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { applyLiquidVariables } from '@/lib/ai/prompt-renderer';
import type {
  SendOneInput,
  SendOneOutput,
  CreateCampaignInput,
  CreateCampaignOutput,
  CampaignProgress,
  CampaignStats,
  QuietHours,
  EmailAddress,
} from '@/types/email';

// ───────────────────────────────────────────────────────────────────
// 에러
// ───────────────────────────────────────────────────────────────────

export class TabsMailerError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'TabsMailerError';
  }
}

export class TabsMailerAuthError extends TabsMailerError {
  constructor(message: string, cause?: unknown) {
    super(message, cause);
    this.name = 'TabsMailerAuthError';
  }
}

export class TabsMailerQuietHoursError extends TabsMailerError {
  constructor(
    message: string,
    public readonly nextSendAfter: Date,
    public readonly quietHours: QuietHours,
  ) {
    super(message);
    this.name = 'TabsMailerQuietHoursError';
  }
}

export class TabsMailerCampaignNotFoundError extends TabsMailerError {
  constructor(public readonly tabsCampaignId: string) {
    super(`TABS campaign not found: ${tabsCampaignId}`);
    this.name = 'TabsMailerCampaignNotFoundError';
  }
}

// ───────────────────────────────────────────────────────────────────
// 모드 식별
// ───────────────────────────────────────────────────────────────────

function detectMockMode(): boolean {
  if (env.NODE_ENV === 'test') return true;
  const host = env.TABS_MAILER_HOST.toLowerCase();
  return host === 'mock' || host.startsWith('mock.') || host === 'localhost' || host === '127.0.0.1';
}

// ───────────────────────────────────────────────────────────────────
// Quiet Hours 평가
// ───────────────────────────────────────────────────────────────────

export function evaluateQuietHours(
  now: Date,
  quietHours: QuietHours,
): { isQuiet: boolean; nextSendAfter: Date } {
  const { timezone, start, end, daysOfWeek } = quietHours;

  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    hour: '2-digit',
    minute: '2-digit',
    weekday: 'short',
    hour12: false,
  });
  const parts = fmt.formatToParts(now);
  const hour = Number(parts.find((p) => p.type === 'hour')?.value ?? '0');
  const minute = Number(parts.find((p) => p.type === 'minute')?.value ?? '0');
  const weekdayStr = parts.find((p) => p.type === 'weekday')?.value ?? '';
  const weekdayMap: Record<string, number> = {
    Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6,
  };
  const dow = weekdayMap[weekdayStr] ?? -1;

  if (daysOfWeek && daysOfWeek.length > 0 && !daysOfWeek.includes(dow)) {
    return { isQuiet: false, nextSendAfter: now };
  }

  const nowMin = hour * 60 + minute;
  const startMin = parseHHMM(start);
  const endMin = parseHHMM(end);

  let isQuiet = false;
  if (startMin <= endMin) {
    isQuiet = nowMin >= startMin && nowMin < endMin;
  } else {
    isQuiet = nowMin >= startMin || nowMin < endMin;
  }

  if (!isQuiet) {
    return { isQuiet: false, nextSendAfter: now };
  }

  let deltaMin = endMin - nowMin;
  if (deltaMin <= 0) deltaMin += 24 * 60;
  const nextSendAfter = new Date(now.getTime() + deltaMin * 60 * 1000);
  return { isQuiet: true, nextSendAfter };
}

function parseHHMM(s: string): number {
  const parts = s.split(':');
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (!Number.isFinite(h) || !Number.isFinite(m)) {
    throw new TabsMailerError(`Invalid HH:MM format: ${s}`);
  }
  return h * 60 + m;
}

// ───────────────────────────────────────────────────────────────────
// TabsMailerClient
// ───────────────────────────────────────────────────────────────────

export class TabsMailerClient {
  private readonly mock: boolean;
  private transporter: Transporter | null;

  constructor(
    private readonly supabase: SupabaseClient,
    transporter?: Transporter,
  ) {
    this.mock = detectMockMode();

    if (transporter) {
      this.transporter = transporter;
      return;
    }
    if (this.mock) {
      this.transporter = null;
      return;
    }

    const config = this.buildTransportConfig();
    this.transporter = nodemailer.createTransport(config);
  }

  private buildTransportConfig(): SMTPTransport.Options {
    const config: SMTPTransport.Options = {
      host: env.TABS_MAILER_HOST,
      port: env.TABS_MAILER_PORT,
      secure: env.TABS_MAILER_USE_TLS && env.TABS_MAILER_PORT === 465,
      requireTLS: env.TABS_MAILER_USE_TLS && env.TABS_MAILER_PORT !== 465,
    };

    switch (env.TABS_MAILER_AUTH_METHOD) {
      case 'plain':
      case 'login': {
        const user = env.TABS_MAILER_USERNAME;
        const pass = env.TABS_MAILER_PASSWORD;
        if (!user || !pass) {
          throw new TabsMailerAuthError(
            `TABS_MAILER_USERNAME/PASSWORD required for auth method '${env.TABS_MAILER_AUTH_METHOD}'`,
          );
        }
        config.auth = { type: 'login', user, pass };
        break;
      }
      case 'ip_whitelist':
        break;
    }
    return config;
  }

  async verify(): Promise<void> {
    if (this.mock || !this.transporter) {
      return;
    }
    try {
      await this.transporter.verify();
    } catch (err) {
      throw new TabsMailerAuthError(
        `TABS Mailer connection/auth failed: ${(err as Error).message}`,
        err,
      );
    }
  }

  close(): void {
    if (this.transporter && !this.mock) {
      this.transporter.close();
    }
    this.transporter = null;
  }

  async sendOne(input: SendOneInput): Promise<SendOneOutput> {
    if (input.quietHours) {
      const { isQuiet, nextSendAfter } = evaluateQuietHours(new Date(), input.quietHours);
      if (isQuiet && (input.enforceQuietHours ?? true)) {
        throw new TabsMailerQuietHoursError(
          `Quiet hours active until ${nextSendAfter.toISOString()}`,
          nextSendAfter,
          input.quietHours,
        );
      }
    }

    const urmHeaderRecord = this.buildUrmHeaders(input.urmHeaders);

    const text = input.text;
    const html = input.html;
    if (!text && !html) {
      throw new TabsMailerError('sendOne requires at least one of text/html');
    }

    const fromAddr = input.from
      ? formatAddress(input.from)
      : env.TABS_MAILER_FROM_DEFAULT
        ? env.TABS_MAILER_FROM_DEFAULT
        : `noreply@${env.TABS_MAILER_FROM_DOMAIN}`;

    const toList = Array.isArray(input.to)
      ? input.to.map(formatAddress)
      : [formatAddress(input.to)];

    const message = {
      from: fromAddr,
      to: toList,
      cc: input.cc?.map(formatAddress),
      bcc: input.bcc?.map(formatAddress),
      replyTo: input.replyTo ? formatAddress(input.replyTo) : undefined,
      subject: input.subject,
      text,
      html,
      messageId: input.messageId,
      inReplyTo: input.inReplyTo,
      references: input.references,
      headers: urmHeaderRecord,
      attachments: input.attachments?.map((a) => ({
        filename: a.filename,
        content: a.content,
        contentType: a.contentType,
        cid: a.cid,
      })),
    };

    if (this.mock || !this.transporter) {
      const generatedMessageId =
        input.messageId ?? `<mock-${Date.now()}-${randomSuffix()}@${env.TABS_MAILER_FROM_DOMAIN}>`;
      // eslint-disable-next-line no-console
      console.log(
        `[tabs-mailer:mock] sendOne to=${toList.join(',')} subject=${input.subject} headers=${JSON.stringify(urmHeaderRecord)}`,
      );
      return {
        messageId: generatedMessageId,
        accepted: toList,
        rejected: [],
        response: '250 Mock OK',
        mocked: true,
      };
    }

    try {
      const info = await this.transporter.sendMail(message);
      return {
        messageId: info.messageId,
        accepted: (info.accepted ?? []).map(addressToString),
        rejected: (info.rejected ?? []).map(addressToString),
        response: info.response ?? '',
        mocked: false,
      };
    } catch (err) {
      throw new TabsMailerError(
        `SMTP send failed: ${(err as Error).message}`,
        err,
      );
    }
  }

  async createCampaign(input: CreateCampaignInput): Promise<CreateCampaignOutput> {
    const tabsCampaignId = this.mock
      ? `mock-camp-${Date.now()}-${randomSuffix()}`
      : `merge-${input.mergeJobId}`;

    let accepted = 0;
    let rejected = 0;

    for (const recipient of input.recipients) {
      if (input.quietHours) {
        const { isQuiet } = evaluateQuietHours(new Date(), input.quietHours);
        if (isQuiet) {
          continue;
        }
      }

      const subject = applyLiquidVariables(input.subjectTemplate, recipient.variables);
      const text = input.bodyPlainTemplate
        ? applyLiquidVariables(input.bodyPlainTemplate, recipient.variables)
        : undefined;
      const html = input.bodyHtmlTemplate
        ? applyLiquidVariables(input.bodyHtmlTemplate, recipient.variables)
        : undefined;

      try {
        await this.sendOne({
          to: recipient.to,
          from: { name: input.fromName, address: input.fromAddress },
          replyTo: input.replyToAddress
            ? { address: input.replyToAddress }
            : undefined,
          subject,
          text,
          html,
          urmHeaders: {
            ...input.urmCampaignHeaders,
            communicationId: recipient.communicationId,
            partyId: recipient.partyId,
          },
          enforceQuietHours: false,
        });
        accepted += 1;
      } catch (err) {
        rejected += 1;
        // eslint-disable-next-line no-console
        console.error(
          `[tabs-mailer] campaign send failed for ${recipient.to.address}: ${(err as Error).message}`,
        );
      }
    }

    await this.supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update({
        tabs_campaign_id: tabsCampaignId,
        progress: {
          totalRecipients: input.recipients.length,
          totalSent: accepted,
          totalDelivered: 0,
          totalOpened: 0,
          totalClicked: 0,
          totalBounced: 0,
          totalFailed: rejected,
          upstreamStatus: rejected === input.recipients.length ? 'failed' : 'running',
          syncedAt: new Date().toISOString(),
        },
      })
      .eq('id', input.mergeJobId);

    return {
      tabsCampaignId,
      acceptedCount: accepted,
      rejectedCount: rejected,
      mocked: this.mock,
    };
  }

  async getCampaignStats(tabsCampaignId: string): Promise<CampaignStats> {
    if (this.mock || !env.TABS_MAILER_DB_CONN) {
      return await this.computeStatsFromCommunications(tabsCampaignId);
    }

    // mssql은 선택적 의존성. 미설치 시 자체 집계 폴백.
    interface MssqlLike {
      connect(connStr: string): Promise<MssqlPool>;
      NVarChar(length: number): unknown;
    }
    interface MssqlPool {
      request(): MssqlRequest;
      close(): Promise<void>;
    }
    interface MssqlRequest {
      input(name: string, type: unknown, value: string): MssqlRequest;
      query<T>(sql: string): Promise<{ recordset: T[] }>;
    }

    let mssql: MssqlLike;
    try {
      // dynamic import — 타입은 unknown으로 받아서 우리 인터페이스로 단언
      const mod = (await import('mssql' as string).catch(() => null)) as unknown;
      if (!mod) {
        return await this.computeStatsFromCommunications(tabsCampaignId);
      }
      mssql = mod as MssqlLike;
    } catch {
      return await this.computeStatsFromCommunications(tabsCampaignId);
    }

    let pool: MssqlPool | null = null;
    try {
      pool = await mssql.connect(env.TABS_MAILER_DB_CONN);
      const request = pool.request();
      request.input('cid', mssql.NVarChar(64), tabsCampaignId);
      const result = await request.query<{
        total_recipients: number;
        total_sent: number;
        total_delivered: number;
        total_opened: number;
        total_clicked: number;
        total_bounced: number;
        total_failed: number;
        upstream_status: string | null;
        started_at: Date | null;
        completed_at: Date | null;
      }>(`
        SELECT
          total_recipients, total_sent, total_delivered,
          total_opened, total_clicked, total_bounced, total_failed,
          upstream_status, started_at, completed_at
        FROM tabs_campaign_stats
        WHERE campaign_id = @cid
      `);

      const row = result.recordset[0];
      if (!row) {
        throw new TabsMailerCampaignNotFoundError(tabsCampaignId);
      }

      return {
        tabsCampaignId,
        totalRecipients: Number(row.total_recipients ?? 0),
        totalSent: Number(row.total_sent ?? 0),
        totalDelivered: Number(row.total_delivered ?? 0),
        totalOpened: Number(row.total_opened ?? 0),
        totalClicked: Number(row.total_clicked ?? 0),
        totalBounced: Number(row.total_bounced ?? 0),
        totalFailed: Number(row.total_failed ?? 0),
        upstreamStatus: normalizeUpstreamStatus(row.upstream_status),
        startedAt: row.started_at?.toISOString(),
        completedAt: row.completed_at?.toISOString(),
        syncedAt: new Date().toISOString(),
      };
    } catch (err) {
      if (err instanceof TabsMailerCampaignNotFoundError) throw err;
      throw new TabsMailerError(
        `Stats DB query failed: ${(err as Error).message}`,
        err,
      );
    } finally {
      if (pool) {
        try {
          await pool.close();
        } catch {
          // ignore
        }
      }
    }
  }

  async syncCampaignToMergeJob(jobId: string): Promise<CampaignProgress> {
    const { data: job, error: jobErr } = await this.supabase
      .schema('app')
      .from('mail_merge_jobs')
      .select('id, tabs_campaign_id, organization_id')
      .eq('id', jobId)
      .single();

    if (jobErr || !job) {
      throw new TabsMailerError(
        `mail_merge_jobs not found: jobId=${jobId} ${jobErr?.message ?? ''}`,
      );
    }
    const tabsCampaignId = (job as { tabs_campaign_id?: string }).tabs_campaign_id;
    if (!tabsCampaignId) {
      throw new TabsMailerError(
        `mail_merge_jobs.tabs_campaign_id not set for job ${jobId}`,
      );
    }

    const stats = await this.getCampaignStats(tabsCampaignId);

    const progress: CampaignProgress = {
      totalRecipients: stats.totalRecipients,
      totalSent: stats.totalSent,
      totalDelivered: stats.totalDelivered,
      totalOpened: stats.totalOpened,
      totalClicked: stats.totalClicked,
      totalBounced: stats.totalBounced,
      totalFailed: stats.totalFailed,
      upstreamStatus: stats.upstreamStatus,
      syncedAt: stats.syncedAt,
    };

    const updatePayload: Record<string, unknown> = { progress };
    if (stats.upstreamStatus === 'completed') {
      updatePayload.status = 'completed';
      updatePayload.completed_at = stats.completedAt ?? stats.syncedAt;
    } else if (stats.upstreamStatus === 'failed') {
      updatePayload.status = 'failed';
    }

    const { error: updateErr } = await this.supabase
      .schema('app')
      .from('mail_merge_jobs')
      .update(updatePayload)
      .eq('id', jobId);

    if (updateErr) {
      throw new TabsMailerError(
        `mail_merge_jobs progress update failed: ${updateErr.message}`,
      );
    }
    return progress;
  }

  private async computeStatsFromCommunications(
    tabsCampaignId: string,
  ): Promise<CampaignStats> {
    const { data, error } = await this.supabase
      .schema('app')
      .from('communications')
      .select('id, status, sent_at, delivered_at, opened_at, clicked_at, bounced_at')
      .eq('direction', 'outbound')
      .filter('external_data->>tabs_campaign_id', 'eq', tabsCampaignId);

    if (error) {
      throw new TabsMailerError(
        `fallback stats query failed: ${error.message}`,
      );
    }

    type Row = {
      status: string;
      sent_at: string | null;
      delivered_at: string | null;
      opened_at: string | null;
      clicked_at: string | null;
      bounced_at: string | null;
    };
    const rows: Row[] = (data ?? []) as Row[];

    let sent = 0, delivered = 0, opened = 0, clicked = 0, bounced = 0, failed = 0;
    let earliest: string | null = null;
    let latest: string | null = null;

    for (const row of rows) {
      if (row.sent_at) sent += 1;
      if (row.delivered_at) delivered += 1;
      if (row.opened_at) opened += 1;
      if (row.clicked_at) clicked += 1;
      if (row.bounced_at) bounced += 1;
      if (row.status === 'failed') failed += 1;
      if (row.sent_at && (!earliest || row.sent_at < earliest)) earliest = row.sent_at;
      if (row.sent_at && (!latest || row.sent_at > latest)) latest = row.sent_at;
    }

    const totalRecipients = rows.length;
    const upstreamStatus: CampaignProgress['upstreamStatus'] =
      totalRecipients === 0
        ? 'unknown'
        : sent === totalRecipients && bounced + failed === 0
          ? 'completed'
          : 'running';

    return {
      tabsCampaignId,
      totalRecipients,
      totalSent: sent,
      totalDelivered: delivered,
      totalOpened: opened,
      totalClicked: clicked,
      totalBounced: bounced,
      totalFailed: failed,
      upstreamStatus,
      startedAt: earliest ?? undefined,
      completedAt: upstreamStatus === 'completed' ? (latest ?? undefined) : undefined,
      syncedAt: new Date().toISOString(),
    };
  }

  private buildUrmHeaders(urm: SendOneInput['urmHeaders']): Record<string, string> {
    const h: Record<string, string> = {
      'X-URM-Communication-Id': urm.communicationId,
      'X-URM-Auto-Send': urm.autoSend ? 'true' : 'false',
    };
    if (urm.engagementId) h['X-URM-Engagement-Id'] = urm.engagementId;
    if (urm.partyId) h['X-URM-Party-Id'] = urm.partyId;
    if (urm.brandVoiceId) h['X-URM-Brand-Voice-Id'] = urm.brandVoiceId;
    if (urm.threadId) h['X-URM-Thread-Id'] = urm.threadId;
    return h;
  }
}

// ───────────────────────────────────────────────────────────────────
// 헬퍼
// ───────────────────────────────────────────────────────────────────

function formatAddress(addr: EmailAddress): string {
  if (!addr.address) {
    throw new TabsMailerError('Email address is required');
  }
  return addr.name ? `"${addr.name.replace(/"/g, '\\"')}" <${addr.address}>` : addr.address;
}

function addressToString(value: string | { address: string }): string {
  return typeof value === 'string' ? value : value.address;
}

function normalizeUpstreamStatus(raw: string | null): CampaignProgress['upstreamStatus'] {
  switch ((raw ?? '').toLowerCase()) {
    case 'pending':
    case 'queued':
      return 'pending';
    case 'running':
    case 'in_progress':
    case 'sending':
      return 'running';
    case 'completed':
    case 'done':
    case 'finished':
      return 'completed';
    case 'failed':
    case 'error':
      return 'failed';
    default:
      return 'unknown';
  }
}

function randomSuffix(): string {
  return Math.random().toString(36).slice(2, 10);
}
