/**
 * lib/email/tabs-mailer.ts
 *
 * Single integration point with the external TABS Mailer 4 system.
 *
 * Responsibilities:
 *   - SMTP auth branching (PLAIN / LOGIN / IP whitelist)
 *   - single send (sendOne) - attaches X-URM-* headers
 *   - per-kind SMTP transporter cache (personal / role / shared)
 *   - campaign registration (createCampaign)
 *   - stats lookup (getCampaignStats)
 *   - mail_merge_jobs.progress sync (syncCampaignToMergeJob)
 *   - client-side quiet hours / rate limit validation
 *
 * Not responsible for:
 *   - recipient-list resolution (mail-merge-worker)
 *   - bounces/complaints post-processing (a separate module in production)
 *   - unsubscribe management (separate)
 */

import nodemailer, { type Transporter, type SentMessageInfo } from 'nodemailer';
import type SMTPTransport from 'nodemailer/lib/smtp-transport';
import type { SupabaseClient } from '@supabase/supabase-js';
import { env, isUsingMockMailer } from '../env';
import {
  URM_HEADER_NAMES,
  type SendOneInput,
  type SendOneOutput,
  type CampaignParams,
  type CampaignCreateResult,
  type TabsCampaignStats,
  type SendingAddressKind,
  type SmtpAccountConfig,
} from '../../types/email';
import { evaluateQuietHours } from './quiet-hours';

/* ============================================================
 * 1. Error classes
 * ============================================================ */

export class TabsMailerError extends Error {
  public override readonly cause?: unknown;
  constructor(message: string, cause?: unknown) {
    super(message);
    this.name = 'TabsMailerError';
    this.cause = cause;
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
    public readonly reason: string,
    public readonly nextAllowedAt?: string,
  ) {
    super(message);
    this.name = 'TabsMailerQuietHoursError';
  }
}

export class TabsMailerRateLimitError extends TabsMailerError {
  constructor(
    message: string,
    public readonly observed: number,
    public readonly limit: number,
    public readonly window: 'minute' | 'hour',
  ) {
    super(message);
    this.name = 'TabsMailerRateLimitError';
  }
}

export class TabsMailerNotImplementedError extends TabsMailerError {
  constructor(method: string) {
    super(
      `${method}: pending TABS Mailer 4 specification from TABS Lab — use mock adapter for now`,
    );
    this.name = 'TabsMailerNotImplementedError';
  }
}

/* ============================================================
 * 2. ITabsMailerClient interface
 * ============================================================ */
export interface ITabsMailerClient {
  verify(kind?: SendingAddressKind): Promise<void>;
  sendOne(input: SendOneInput): Promise<SendOneOutput>;
  createCampaign(params: CampaignParams): Promise<CampaignCreateResult>;
  getCampaignStats(tabsCampaignId: string): Promise<TabsCampaignStats>;
  syncCampaignToMergeJob(
    supabase: SupabaseClient,
    organizationId: string,
    jobId: string,
  ): Promise<void>;
  close(): Promise<void>;
}

/* ============================================================
 * 3. TabsMailerClient (real SMTP adapter)
 * ============================================================ */

export interface TabsMailerOptions {
  /** Used to inject a nodemailer transporter in unit tests. */
  transporter?: Transporter;
  /** Used to freeze the clock in unit tests. */
  nowProvider?: () => Date;
}

export class TabsMailerClient implements ITabsMailerClient {
  /** Transporter cache. Keys: kind ('personal'|'role'|'shared'), 'default'
   *  (backward-compat fallback), or `account:<inbound_mailboxes.id>` (Step 3). */
  private transporters: Map<string, Transporter> = new Map();
  private readonly nowProvider: () => Date;

  constructor(options: TabsMailerOptions = {}) {
    this.nowProvider = options.nowProvider ?? (() => new Date());
    if (options.transporter) {
      this.transporters.set('default', options.transporter);
    }
  }

  /**
   * Takes a kind and returns SMTP credentials. null if not configured.
   */
  private resolveCredentials(
    kind: SendingAddressKind,
  ): { username: string; password: string; displayName: string } | null {
    switch (kind) {
      case 'personal':
        if (!env.MAIL_PERSONAL_USERNAME || !env.MAIL_PERSONAL_PASSWORD) return null;
        return {
          username: env.MAIL_PERSONAL_USERNAME,
          password: env.MAIL_PERSONAL_PASSWORD,
          displayName: env.MAIL_PERSONAL_DISPLAY_NAME,
        };
      case 'role':
        if (!env.MAIL_ROLE_USERNAME || !env.MAIL_ROLE_PASSWORD) return null;
        return {
          username: env.MAIL_ROLE_USERNAME,
          password: env.MAIL_ROLE_PASSWORD,
          displayName: env.MAIL_ROLE_DISPLAY_NAME,
        };
      case 'shared':
        if (!env.MAIL_SHARED_USERNAME || !env.MAIL_SHARED_PASSWORD) return null;
        return {
          username: env.MAIL_SHARED_USERNAME,
          password: env.MAIL_SHARED_PASSWORD,
          displayName: env.MAIL_SHARED_DISPLAY_NAME,
        };
    }
  }

  /** Common SMTP options (excluding auth). */
  private baseSmtpOptions(): Omit<SMTPTransport.Options, 'auth'> {
    const rejectUnauthorized = env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? true;
    return {
      host: env.TABS_MAILER_HOST,
      port: env.TABS_MAILER_PORT,
      secure: env.TABS_MAILER_USE_TLS && env.TABS_MAILER_PORT === 465,
      requireTLS: env.TABS_MAILER_USE_TLS && env.TABS_MAILER_PORT !== 465,
      ignoreTLS: !env.TABS_MAILER_USE_TLS,
      tls: { rejectUnauthorized },
      // Fail fast on dead host/port: ~10s instead of OS default (~40s).
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 30000,
    };
  }

  /**
   * Create/cache a transporter per kind.
   * When kind is unset, falls back to the existing TABS_MAILER_USERNAME/PASSWORD.
   */
  private getTransporterFor(kind?: SendingAddressKind): Transporter {
    const cacheKey: SendingAddressKind | 'default' = kind ?? 'default';
    const cached = this.transporters.get(cacheKey);
    if (cached) return cached;

    const config: SMTPTransport.Options = this.baseSmtpOptions();

    if (kind) {
      const creds = this.resolveCredentials(kind);
      if (!creds) {
        throw new TabsMailerError(
          `SMTP credentials not configured for kind="${kind}". ` +
            `Set MAIL_${kind.toUpperCase()}_USERNAME and MAIL_${kind.toUpperCase()}_PASSWORD in .env.local.`,
        );
      }
      config.auth = {
        type: 'login',
        user: creds.username,
        pass: creds.password,
      };
    } else {
      // backward compat: single TABS_MAILER_USERNAME/PASSWORD
      if (
        env.TABS_MAILER_AUTH_METHOD === 'plain' ||
        env.TABS_MAILER_AUTH_METHOD === 'login'
      ) {
        config.auth = {
          type: 'login',
          user: env.TABS_MAILER_USERNAME ?? '',
          pass: env.TABS_MAILER_PASSWORD ?? '',
        };
      }
      // ip_whitelist leaves auth unset -> the TABS side verifies by IP
    }

    const transporter = nodemailer.createTransport(config);
    this.transporters.set(cacheKey, transporter);
    return transporter;
  }

  /**
   * Multi-Account Step 3: create/cache a transporter for a DB mail account
   * (app.inbound_mailboxes smtp_* columns, password already decrypted by the caller).
   *
   * TLS mapping mirrors baseSmtpOptions():
   *   - useTls && port 465  -> implicit TLS (SMTPS)
   *   - useTls && port !=465 -> STARTTLS required
   *   - !useTls             -> plain (ignoreTLS) - current domain-mail infra
   *
   * NOTE: createTabsMailer() is a process-wide singleton, so this cache lives
   * until restart. Credential changes (Step 5 UI) must call resetTabsMailerCache().
   */
  private getTransporterForAccount(acct: SmtpAccountConfig): Transporter {
    const cacheKey = `account:${acct.accountId}`;
    const cached = this.transporters.get(cacheKey);
    if (cached) return cached;

    const rejectUnauthorized = env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? true;
    const config: SMTPTransport.Options = {
      host: acct.host,
      port: acct.port,
      secure: acct.useTls && acct.port === 465,
      requireTLS: acct.useTls && acct.port !== 465,
      ignoreTLS: !acct.useTls,
      tls: { rejectUnauthorized },
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 30000,
      // type:'login' = user/pass credentials (vs oauth2), same as the kind path.
      auth: { type: 'login', user: acct.username, pass: acct.password },
    };
    // SASL mechanism preference (smtp_auth_method): 'login' (default) lets
    // nodemailer negotiate as before; 'plain' forces AUTH PLAIN.
    if (acct.authMethod === 'plain') {
      config.authMethod = 'PLAIN';
    }

    const transporter = nodemailer.createTransport(config);
    this.transporters.set(cacheKey, transporter);
    return transporter;
  }

  /**
   * Verify SMTP connection/auth.
   * @param kind specify to verify only a particular kind. If omitted, verifies the default fallback.
   */
  async verify(kind?: SendingAddressKind): Promise<void> {
    const target = kind ? `kind=${kind}` : 'default';
    try {
      const t = this.getTransporterFor(kind);
      await t.verify();
    } catch (err) {
      throw new TabsMailerAuthError(
        `TABS Mailer connection/auth failed (${target}): ${(err as Error).message}`,
        err,
      );
    }
  }

  /**
   * Verify all configured kinds in a batch. Returns a report-style result (does not throw).
   */
  async verifyAll(): Promise<
    Array<{ kind: SendingAddressKind | 'default'; ok: boolean; error?: string }>
  > {
    const results: Array<{
      kind: SendingAddressKind | 'default';
      ok: boolean;
      error?: string;
    }> = [];
    const candidates: Array<SendingAddressKind | 'default'> = [
      'personal',
      'role',
      'shared',
      'default',
    ];
    for (const k of candidates) {
      try {
        if (k === 'default') {
          if (!env.TABS_MAILER_USERNAME || !env.TABS_MAILER_PASSWORD) continue;
        } else if (!this.resolveCredentials(k)) {
          continue;
        }
        await this.verify(k === 'default' ? undefined : k);
        results.push({ kind: k, ok: true });
      } catch (err) {
        results.push({ kind: k, ok: false, error: (err as Error).message });
      }
    }
    return results;
  }

  /**
   * Single send.
   * 1. quiet hours validation
   * 2. kind-based transporter + From determination
   * 3. attach URM headers
   * 4. nodemailer.sendMail
   */
  async sendOne(input: SendOneInput): Promise<SendOneOutput> {
    // [1] quiet hours
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

    // [2] account/kind-based transporter + From determination
    //     Multi-Account Step 3: smtpAccount (DB) wins over kind (env).
    const account = input.smtpAccount;
    const kind = input.sendingAddressKind;
    const transporter = account
      ? this.getTransporterForAccount(account)
      : this.getTransporterFor(kind);

    // From: account set  -> force the account address/display name (SPF/DKIM consistency)
    //       kind set     -> force the credentials' username (existing behavior)
    //       neither      -> use input.fromAddress/fromName as-is (backward compat)
    let effectiveFromAddress = input.fromAddress;
    let effectiveFromName = input.fromName;
    if (account) {
      effectiveFromAddress = account.address;
      if (account.displayName) effectiveFromName = account.displayName;
    } else if (kind) {
      const creds = this.resolveCredentials(kind);
      if (creds) {
        effectiveFromAddress = creds.username;
        effectiveFromName = creds.displayName;
      }
    }

    // [3] URM headers + auxiliary headers
    const headers: Record<string, string> = {
      [URM_HEADER_NAMES.communicationId]: input.urmHeaders.communicationId,
      [URM_HEADER_NAMES.autoSend]: input.urmHeaders.autoSend ? 'true' : 'false',
    };
    if (input.urmHeaders.engagementId) {
      headers[URM_HEADER_NAMES.engagementId] = input.urmHeaders.engagementId;
    }
    if (input.urmHeaders.brandVoiceId) {
      headers[URM_HEADER_NAMES.brandVoiceId] = input.urmHeaders.brandVoiceId;
    }
    // when header pass-through is unconfirmed, fall back to the invisible footer (HTML body only)
    let bodyHtml = input.bodyHtml;
    if (bodyHtml) {
      const footer = `<!-- urm:c=${input.urmHeaders.communicationId};auto=${
        input.urmHeaders.autoSend ? '1' : '0'
      }${input.urmHeaders.engagementId ? `;e=${input.urmHeaders.engagementId}` : ''} -->`;
      bodyHtml = `${bodyHtml}\n${footer}`;
    }

    // [4] send
    let info: SentMessageInfo;
    try {
      info = await transporter.sendMail({
        from: { name: effectiveFromName, address: effectiveFromAddress },
        to: input.to.name
          ? { name: input.to.name, address: input.to.address }
          : input.to.address,
        cc: input.cc?.map((r) =>
          r.name ? { name: r.name, address: r.address } : r.address,
        ),
        bcc: input.bcc?.map((r) =>
          r.name ? { name: r.name, address: r.address } : r.address,
        ),
        replyTo: input.replyTo,
        inReplyTo: input.inReplyTo,
        references: input.references,
        subject: input.subject,
        text: input.bodyText,
        html: bodyHtml,
        attachments: input.attachments,
        headers,
      });
    } catch (err) {
      throw new TabsMailerError(
        `sendOne failed (${account ? `account=${account.address}` : `kind=${kind ?? 'default'}`}): ${(err as Error).message}`,
        err,
      );
    }

    return {
      messageId: info.messageId,
      acceptedRecipients: (info.accepted ?? []).map((a: unknown) =>
        typeof a === 'string' ? a : ((a as { address: string }).address ?? ''),
      ),
      rejectedRecipients: (info.rejected ?? []).map((a: unknown) =>
        typeof a === 'string' ? a : ((a as { address: string }).address ?? ''),
      ),
      rawResponse: info.response ?? '',
      sentAt: this.nowProvider().toISOString(),
    };
  }

  /* --------------------------------------------------------
   * createCampaign - register a TABS Mailer 4 campaign
   * TABS API spec not yet received -> throw. Falls back to mock in production.
   * -------------------------------------------------------- */
  async createCampaign(_params: CampaignParams): Promise<CampaignCreateResult> {
    throw new TabsMailerNotImplementedError('createCampaign');
  }

  /* --------------------------------------------------------
   * getCampaignStats - query the MS SQL Server stats DB
   * operational details not yet received -> throw.
   * -------------------------------------------------------- */
  async getCampaignStats(_tabsCampaignId: string): Promise<TabsCampaignStats> {
    throw new TabsMailerNotImplementedError('getCampaignStats');
  }

  /* --------------------------------------------------------
   * syncCampaignToMergeJob
   * Update mail_merge_jobs.progress + tabs_campaign_status.
   * -------------------------------------------------------- */
  async syncCampaignToMergeJob(
    supabase: SupabaseClient,
    organizationId: string,
    jobId: string,
  ): Promise<void> {
    const { data: job, error: jobError } = await supabase
      .schema('app')
      .from('mail_merge_jobs')
      .select('id, tabs_campaign_id, status')
      .eq('id', jobId)
      .eq('organization_id', organizationId)
      .maybeSingle();

    if (jobError) {
      throw new TabsMailerError(
        `Cannot sync: job lookup failed: ${jobError.message}`,
        jobError,
      );
    }
    if (!job) {
      throw new TabsMailerError(
        `Cannot sync: job ${jobId} not found in organization ${organizationId}`,
      );
    }
    if (!job.tabs_campaign_id) {
      throw new TabsMailerError(
        `Cannot sync: job ${jobId} has no tabs_campaign_id`,
      );
    }

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

  /** Close all transporter connections (cleanup). Called on worker graceful shutdown. */
  async close(): Promise<void> {
    for (const [, t] of this.transporters) {
      try {
        t.close();
      } catch (err) {
        // eslint-disable-next-line no-console
        console.warn('[tabs-mailer] close failed:', err);
      }
    }
    this.transporters.clear();
  }
}

/* ============================================================
 * 4. Rate limit validation (called from mail-merge-worker)
 * ============================================================ */

export interface RateLimitCheckInput {
  jobId: string;
  perMinute: number;
  perHour: number;
}

export interface RateLimitVerdict {
  allowed: boolean;
  reason?: 'minute_limit' | 'hour_limit';
  observedMinute?: number;
  observedHour?: number;
  /** ISO string of the next allowed send time. */
  nextAllowedAt?: string;
}

/**
 * Aggregate the count of communications sent in the last 1 min / 1 hour and compare against the limits.
 */
export async function checkRateLimit(
  supabase: SupabaseClient,
  organizationId: string,
  jobId: string,
  perMinute: number,
  perHour: number,
  now: Date = new Date(),
): Promise<RateLimitVerdict> {
  const oneMinuteAgo = new Date(now.getTime() - 60_000).toISOString();
  const oneHourAgo = new Date(now.getTime() - 3_600_000).toISOString();

  const filter = { mail_merge_job_id: jobId };

  const { count: minuteCount, error: e1 } = await supabase
    .schema('app')
    .from('communications')
    .select('id', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .eq('direction', 'outbound')
    .eq('channel', 'email')
    .contains('external_data', filter)
    .gte('sent_at', oneMinuteAgo);

  const { count: hourCount, error: e2 } = await supabase
    .schema('app')
    .from('communications')
    .select('id', { count: 'exact', head: true })
    .eq('organization_id', organizationId)
    .eq('direction', 'outbound')
    .eq('channel', 'email')
    .contains('external_data', filter)
    .gte('sent_at', oneHourAgo);

  if (e1 || e2) {
    return {
      allowed: false,
      reason: 'minute_limit',
      observedMinute: -1,
      observedHour: -1,
    };
  }

  const m = minuteCount ?? 0;
  const h = hourCount ?? 0;

  if (m >= perMinute) {
    return {
      allowed: false,
      reason: 'minute_limit',
      observedMinute: m,
      observedHour: h,
      nextAllowedAt: new Date(now.getTime() + 60_000).toISOString(),
    };
  }
  if (h >= perHour) {
    return {
      allowed: false,
      reason: 'hour_limit',
      observedMinute: m,
      observedHour: h,
      nextAllowedAt: new Date(now.getTime() + 3_600_000).toISOString(),
    };
  }

  return { allowed: true, observedMinute: m, observedHour: h };
}

/* ============================================================
 * 5. Factory - selects the mock vs real adapter based on env
 * ============================================================ */

let cachedClient: ITabsMailerClient | null = null;

/**
 * Obtain a TabsMailerClient instance.
 * - TABS_MAILER_USE_MOCK=true or HOST='mock' -> mock adapter
 * - otherwise -> real SMTP adapter (singleton)
 */
export async function createTabsMailer(): Promise<ITabsMailerClient> {
  if (cachedClient) return cachedClient;

  if (isUsingMockMailer()) {
    // load the mock adapter via dynamic import (can be excluded from the production bundle)
    const { TabsMailerMockClient } = await import('./tabs-mailer.mock');
    cachedClient = new TabsMailerMockClient();
  } else {
    cachedClient = new TabsMailerClient();
  }
  return cachedClient;
}

/** For tests/re-init - clears the cache. */
export function resetTabsMailerCache(): void {
  cachedClient = null;
}
