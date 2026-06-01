===== C:\dev\mbg-project\src\lib\email\tabs-mailer.ts =====
```ts
/**
 * lib/email/tabs-mailer.ts
 *
 * TABS Mailer 4 외부 시스템과의 단일 통합점.
 *
 * 책임:
 *   - SMTP 인증 분기 (PLAIN / LOGIN / IP whitelist)
 *   - 단건 발송 (sendOne) — X-URM-* 헤더 부착
 *   - kind별 SMTP transporter 캐시 (personal / role / shared)
 *   - 캠페인 등록 (createCampaign)
 *   - 통계 조회 (getCampaignStats)
 *   - mail_merge_jobs.progress 동기화 (syncCampaignToMergeJob)
 *   - quiet hours·rate limit 클라이언트 측 검증
 *
 * 비책임:
 *   - 수신자 명단 해석 (mail-merge-worker)
 *   - bounces·complaints 후처리 (운영 시 별도 모듈)
 *   - unsubscribe 관리 (별도)
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
} from '../../types/email';
import { evaluateQuietHours } from './quiet-hours';

/* ============================================================
 * 1. 에러 클래스
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
      `${method}: pending TABS Mailer 4 specification from 탭스랩 — use mock adapter for now`,
    );
    this.name = 'TabsMailerNotImplementedError';
  }
}

/* ============================================================
 * 2. ITabsMailerClient 인터페이스
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
 * 3. TabsMailerClient (실 SMTP 어댑터)
 * ============================================================ */

export interface TabsMailerOptions {
  /** 단위 테스트에서 nodemailer transporter를 주입할 때 사용. */
  transporter?: Transporter;
  /** 단위 테스트에서 시각을 고정할 때 사용. */
  nowProvider?: () => Date;
}

export class TabsMailerClient implements ITabsMailerClient {
  /** kind별 transporter 캐시. 'default'는 하위호환용 fallback. */
  private transporters: Map<SendingAddressKind | 'default', Transporter> = new Map();
  private readonly nowProvider: () => Date;

  constructor(options: TabsMailerOptions = {}) {
    this.nowProvider = options.nowProvider ?? (() => new Date());
    if (options.transporter) {
      this.transporters.set('default', options.transporter);
    }
  }

  /**
   * kind를 받아 SMTP 자격증명을 반환. 미설정 시 null.
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

  /** 공통 SMTP 옵션 (auth 제외). */
  private baseSmtpOptions(): Omit<SMTPTransport.Options, 'auth'> {
    const rejectUnauthorized = env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? true;
    return {
      host: env.TABS_MAILER_HOST,
      port: env.TABS_MAILER_PORT,
      secure: env.TABS_MAILER_USE_TLS && env.TABS_MAILER_PORT === 465,
      requireTLS: env.TABS_MAILER_USE_TLS && env.TABS_MAILER_PORT !== 465,
      ignoreTLS: !env.TABS_MAILER_USE_TLS,
      tls: { rejectUnauthorized },
    };
  }

  /**
   * kind별 transporter 생성/캐시.
   * kind 미지정 시 기존 TABS_MAILER_USERNAME/PASSWORD fallback.
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
      // 하위호환: 단일 TABS_MAILER_USERNAME/PASSWORD
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
      // ip_whitelist는 auth 미지정 → TABS 측이 IP로 검증
    }

    const transporter = nodemailer.createTransport(config);
    this.transporters.set(cacheKey, transporter);
    return transporter;
  }

  /**
   * SMTP 연결·인증 확인.
   * @param kind 특정 kind만 검증하려면 지정. 미지정 시 default fallback 검증.
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
   * 모든 configured kind를 일괄 검증. 보고용 결과 반환(throw 안 함).
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
   * 단건 발송.
   * 1. quiet hours 검증
   * 2. kind 기반 transporter + From 결정
   * 3. URM 헤더 부착
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

    // [2] kind 기반 transporter + From 결정
    const kind = input.sendingAddressKind;
    const transporter = this.getTransporterFor(kind);

    // From: kind 지정 시 자격증명 username으로 강제 (SPF/DKIM 일관성)
    //       kind 미지정 시 input.fromAddress/fromName 그대로 (하위호환)
    let effectiveFromAddress = input.fromAddress;
    let effectiveFromName = input.fromName;
    if (kind) {
      const creds = this.resolveCredentials(kind);
      if (creds) {
        effectiveFromAddress = creds.username;
        effectiveFromName = creds.displayName;
      }
    }

    // [3] URM 헤더 + 보조 헤더
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
    // 헤더 통과 여부 미확인 시 invisible footer fallback (HTML body에만)
    let bodyHtml = input.bodyHtml;
    if (bodyHtml) {
      const footer = `<!-- urm:c=${input.urmHeaders.communicationId};auto=${
        input.urmHeaders.autoSend ? '1' : '0'
      }${input.urmHeaders.engagementId ? `;e=${input.urmHeaders.engagementId}` : ''} -->`;
      bodyHtml = `${bodyHtml}\n${footer}`;
    }

    // [4] 발송
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
        `sendOne failed (kind=${kind ?? 'default'}): ${(err as Error).message}`,
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
   * createCampaign — TABS Mailer 4 캠페인 등록
   * TABS API 명세 미수령 → throw. 운영 시 mock fallback.
   * -------------------------------------------------------- */
  async createCampaign(_params: CampaignParams): Promise<CampaignCreateResult> {
    throw new TabsMailerNotImplementedError('createCampaign');
  }

  /* --------------------------------------------------------
   * getCampaignStats — MS SQL Server 통계 DB 조회
   * 운영 정보 미수령 → throw.
   * -------------------------------------------------------- */
  async getCampaignStats(_tabsCampaignId: string): Promise<TabsCampaignStats> {
    throw new TabsMailerNotImplementedError('getCampaignStats');
  }

  /* --------------------------------------------------------
   * syncCampaignToMergeJob
   * mail_merge_jobs.progress + tabs_campaign_status 갱신.
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

  /** 모든 transporter 연결 종료 (cleanup). 워커 graceful shutdown에서 호출. */
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
 * 4. Rate limit 검증 (mail-merge-worker에서 호출)
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
  /** 다음 발송 가능 시각의 ISO 문자열. */
  nextAllowedAt?: string;
}

/**
 * 최근 1분·1시간 내 communications 발송 카운트를 집계해 한도 비교.
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
 * 5. 팩토리 — env에 따라 mock vs 실제 어댑터 선택
 * ============================================================ */

let cachedClient: ITabsMailerClient | null = null;

/**
 * TabsMailerClient 인스턴스 획득.
 * - TABS_MAILER_USE_MOCK=true 또는 HOST='mock' → mock 어댑터
 * - 그 외 → 실 SMTP 어댑터 (singleton)
 */
export async function createTabsMailer(): Promise<ITabsMailerClient> {
  if (cachedClient) return cachedClient;

  if (isUsingMockMailer()) {
    // 동적 import로 mock 어댑터 로드 (운영 번들에서 제외 가능)
    const { TabsMailerMockClient } = await import('./tabs-mailer.mock');
    cachedClient = new TabsMailerMockClient();
  } else {
    cachedClient = new TabsMailerClient();
  }
  return cachedClient;
}

/** 테스트·재초기화용 — 캐시 초기화. */
export function resetTabsMailerCache(): void {
  cachedClient = null;
}

```