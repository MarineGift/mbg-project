/**
 * lib/email/mailcarrier.ts
 *
 * 자체 IMAP 메일서버에서 메일을 수신해 communications에 저장하고
 * processor.ts(Part 4)로 전달한다.
 *
 * Phase 2 변경:
 *   - 생성자에 kind? 옵션 추가 (personal/role/shared 자격증명 자동 매핑)
 *   - kind 미지정 시 기존 MAILCARRIER_USERNAME/PASSWORD 단일 fallback
 *   - 화이트리스트 진입점 체크 유지
 *
 * Phase 2-b 변경 (안정성):
 *   - runPollingLoop tick 가시성 로그 + consecutive error 가드
 *   - ImapFlow socketTimeout 60초 (기본 5분에서 단축)
 *   - Connection-level 에러 시 자동 재연결
 *
 * Phase 2-c 변경 (UID 추적):
 *   - app.mailcarrier_state 테이블 기반 last_processed_uid 추적
 *   - \Seen flag 의존성 완전 제거 (messageFlagsAdd 호출 안 함)
 *   - fetch range를 UNSEEN search → UID range로 변경
 *
 * 책임:
 *   - IMAP 연결·인증 (TLS)
 *   - IDLE 또는 폴링 기반 신규 메일 감지
 *   - mailparser로 raw → ParsedMail 변환
 *   - header-parser로 thread/sender 매칭
 *   - 화이트리스트 필터링
 *   - 첨부 → Supabase Storage 업로드
 *   - communications + attachments INSERT
 *   - 멱등성 (Message-ID UNIQUE + UID 추적)
 *   - PII 사전 마스킹 (저장 전 body)
 *   - 재연결 (exponential backoff + polling loop auto-reconnect)
 *
 * 비책임:
 *   - 메일 분류·회신 초안 생성 (processor.ts)
 *   - 폴더 정리 (운영 정책)
 */

import { ImapFlow, type FetchMessageObject } from 'imapflow';
import { simpleParser, type Attachment, type ParsedMail } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';
import { randomUUID, createHash } from 'node:crypto';
import { env } from '../env';
import { maskPii } from '../ai/pii-masker';
import {
  parseInboundMessage,
  findThreadId,
  matchSenderToContactAndParty,
} from './header-parser';
import { isFromAllowedSender } from './whitelist';
import type { InboundMessageEvent, SendingAddressKind } from '../../types/email';

/* ============================================================
 * 1. 에러 클래스
 * ============================================================ */

export class MailCarrierError extends Error {
  public override readonly cause?: unknown;
  constructor(message: string, cause?: unknown) {
    super(message);
    this.name = 'MailCarrierError';
    this.cause = cause;
  }
}

export class MailCarrierConnectionError extends MailCarrierError {
  constructor(message: string, cause?: unknown) {
    super(message, cause);
    this.name = 'MailCarrierConnectionError';
  }
}

export class MailCarrierMaxReconnectError extends MailCarrierError {
  constructor(attempts: number) {
    super(`MailCarrier reconnect failed after ${attempts} attempts`);
    this.name = 'MailCarrierMaxReconnectError';
  }
}

/* ============================================================
 * 2. 인터페이스 (테스트 친화)
 * ============================================================ */

/** ImapFlow를 추상화 — 테스트에서 fake로 교체 가능. */
export interface IImapClient {
  connect(): Promise<void>;
  logout(): Promise<void>;
  mailboxOpen(folder: string): Promise<unknown>;
  getMailboxLock(folder: string): Promise<{ release(): void | Promise<void> }>;
  fetch(
    range: { seen?: boolean } | string,
    options: { source: boolean; envelope?: boolean; uid?: boolean },
    queryOptions?: { uid?: boolean },
  ): AsyncIterable<FetchMessageObject>;
  messageFlagsAdd(uid: string | number, flags: string[]): Promise<unknown>;
  idle(): Promise<unknown>;
}

/** mailparser의 simpleParser를 추상화. */
export type ParserFn = (source: Buffer | string) => Promise<ParsedMail>;

export interface MailCarrierClientOptions {
  imapClient?: IImapClient;
  parser?: ParserFn;
  nowProvider?: () => Date;
  /** 단위 테스트에서 idle 무한 루프 차단용. */
  maxIterations?: number;
  /**
   * Phase 2: 어떤 발신 계정 자격증명을 IMAP 인증에 사용할지.
   * 미지정 시 기존 MAILCARRIER_USERNAME/PASSWORD 사용 (Phase 1 하위호환).
   */
  kind?: SendingAddressKind;
  /**
   * Phase 3: DB(app.inbound_mailboxes) 기반 임의 수신 계정.
   * 지정 시 kind/env를 무시하고 이 계정의 host/port/username + 복호한 비밀번호로 접속.
   * 비밀번호는 bytea(암호화)로 받아 connect() 시점에 RPC로 복호한다
   * (생성자 동기성 유지 — kind/env 경로는 기존 그대로 동기 생성).
   */
  account?: {
    id: string;
    address: string;
    host: string;
    port: number;
    /** app.inbound_mailboxes.password_encrypted (PostgREST bytea -> "\\x..." 문자열). */
    passwordEncrypted: string;
  };
}

export type InboundHandler = (event: InboundMessageEvent) => Promise<void>;

/* ============================================================
 * 3. MailCarrierClient
 * ============================================================ */

const MAX_RECONNECT_ATTEMPTS = 5;
const ATTACHMENT_MAX_BYTES = 25 * 1024 * 1024; // 25MB

export class MailCarrierClient {
  private client!: IImapClient;
  /** account 경로는 client를 connect() 시점에 lazy 생성. 생성 완료 여부 추적. */
  private clientBuilt = false;
  /** Phase 3: DB 기반 수신 계정 (지정 시 kind/env 무시). */
  private readonly account?: MailCarrierClientOptions['account'];
  private isRunning = false;
  private reconnectAttempts = 0;
  private readonly parser: ParserFn;
  private readonly nowProvider: () => Date;
  private readonly maxIterations: number | undefined;
  /** kind 식별자 (로그·external_data 메타데이터용). */
  public readonly kind: SendingAddressKind | 'default' | 'account';
  /** 현재 IMAP 인증에 사용 중인 username (로깅용). */
  public readonly username: string;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
    options: MailCarrierClientOptions = {},
  ) {
    this.parser = options.parser ?? ((src) => simpleParser(src));
    this.nowProvider = options.nowProvider ?? (() => new Date());
    this.maxIterations = options.maxIterations;
    this.account = options.account;

    if (options.imapClient) {
      // 테스트 주입 클라이언트 — kind/account 무관하게 그대로 사용.
      this.kind = options.account ? 'account' : (options.kind ?? 'default');
      this.username =
        options.account?.address ??
        this.resolveCredentials(options.kind).username;
      this.client = options.imapClient;
      this.clientBuilt = true;
    } else if (options.account) {
      // Phase 3: DB 계정 — 비번 복호가 async라 client는 connect()에서 lazy 생성.
      this.kind = 'account';
      this.username = options.account.address;
      // this.client 는 ensureClient()에서 세팅 (clientBuilt=false 유지)
    } else {
      // Phase 1/2: env(kind/default) 기반 — 기존 동작 그대로 동기 생성.
      this.kind = options.kind ?? 'default';
      const creds = this.resolveCredentials(options.kind);
      this.username = creds.username;
      this.client = this.buildClient(creds);
      this.clientBuilt = true;
    }
  }

  /**
   * kind 기반으로 IMAP 자격증명 결정.
   * - kind 지정: MAIL_<KIND>_USERNAME/PASSWORD 사용
   * - 미지정: MAILCARRIER_USERNAME/PASSWORD 사용 (Phase 1 하위호환)
   */
  private resolveCredentials(
    kind?: SendingAddressKind,
  ): { username: string; password: string } {
    if (!kind) {
      // Phase 1 하위호환
      return {
        username: env.MAILCARRIER_USERNAME,
        password: env.MAILCARRIER_PASSWORD,
      };
    }
    switch (kind) {
      case 'personal':
        if (!env.MAIL_PERSONAL_USERNAME || !env.MAIL_PERSONAL_PASSWORD) {
          throw new MailCarrierError(
            `IMAP credentials missing for kind=personal. Set MAIL_PERSONAL_USERNAME / MAIL_PERSONAL_PASSWORD.`,
          );
        }
        return {
          username: env.MAIL_PERSONAL_USERNAME,
          password: env.MAIL_PERSONAL_PASSWORD,
        };
      case 'role':
        if (!env.MAIL_ROLE_USERNAME || !env.MAIL_ROLE_PASSWORD) {
          throw new MailCarrierError(
            `IMAP credentials missing for kind=role. Set MAIL_ROLE_USERNAME / MAIL_ROLE_PASSWORD.`,
          );
        }
        return {
          username: env.MAIL_ROLE_USERNAME,
          password: env.MAIL_ROLE_PASSWORD,
        };
      case 'shared':
        if (!env.MAIL_SHARED_USERNAME || !env.MAIL_SHARED_PASSWORD) {
          throw new MailCarrierError(
            `IMAP credentials missing for kind=shared. Set MAIL_SHARED_USERNAME / MAIL_SHARED_PASSWORD.`,
          );
        }
        return {
          username: env.MAIL_SHARED_USERNAME,
          password: env.MAIL_SHARED_PASSWORD,
        };
    }
  }

  private buildClient(creds: {
    username: string;
    password: string;
    host?: string;
    port?: number;
  }): IImapClient {
    // account 경로는 계정별 host/port 사용, 그 외는 기존 env 단일값 (하위호환).
    const host = creds.host ?? env.MAILCARRIER_HOST;
    const port = creds.port ?? env.MAILCARRIER_PORT;
    // 993: implicit TLS, 143: STARTTLS (ImapFlow가 자동 협상)
    const isImplicitTls = port === 993;
    // 자체 서명 인증서 허용 옵션 (검증 환경 전용)
    const rejectUnauthorized = env.MAILCARRIER_TLS_REJECT_UNAUTHORIZED ?? true;

    return new ImapFlow({
      host,
      port,
      secure: isImplicitTls,
      auth: {
        user: creds.username,
        pass: creds.password,
      },
      tls: { rejectUnauthorized },
      logger: false,
      // 기본 5분 → 60초로 단축. 메일서버가 명령에 응답 안 하면 즉시 fail-fast.
      socketTimeout: 60_000,
    }) as unknown as IImapClient;
  }

  /* --------------------------------------------------------
   * 클라이언트 lazy 생성 (Phase 3)
   *
   * account 경로는 비밀번호 복호가 async라 생성자에서 못 만든다.
   * connect()/handleReconnect()에서 이 메서드들로 실제 client를 만든다.
   * env(kind/default) 경로는 생성자에서 이미 만들어 clientBuilt=true이므로 no-op.
   * -------------------------------------------------------- */

  private async ensureClient(): Promise<void> {
    if (this.clientBuilt) return;
    await this.rebuildClient();
  }

  /** account면 복호한 비번 + 계정 host/port로, 아니면 kind/env creds로 client 재생성. */
  private async rebuildClient(): Promise<void> {
    if (this.account) {
      const password = await this.decryptAccountPassword(
        this.account.passwordEncrypted,
      );
      this.client = this.buildClient({
        username: this.account.address,
        password,
        host: this.account.host,
        port: this.account.port,
      });
    } else {
      const creds = this.resolveCredentials(
        this.kind === 'default' ? undefined : (this.kind as SendingAddressKind),
      );
      this.client = this.buildClient(creds);
    }
    this.clientBuilt = true;
  }

  /**
   * app.inbound_mailboxes.password_encrypted(bytea)를 복호.
   * calendar token-crypto와 동일하게 pgcrypto RPC + CALENDAR_TOKEN_ENCRYPTION_KEY 사용.
   */
  private async decryptAccountPassword(encrypted: string): Promise<string> {
    const encKey = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY;
    if (!encKey) {
      throw new MailCarrierError(
        'CALENDAR_TOKEN_ENCRYPTION_KEY not set (required to decrypt inbound mailbox password)',
      );
    }
    const { data, error } = await this.supabase
      .schema('app')
      .rpc('decrypt_inbound_mailbox_password', { encrypted, enc_key: encKey });
    if (error || typeof data !== 'string') {
      throw new MailCarrierError(
        `Mailbox password decrypt failed (mailbox=${this.account?.id ?? '?'}): ${
          error?.message ?? 'no data'
        }`,
      );
    }
    return data;
  }

  /* --------------------------------------------------------
   * connect / stop
   * -------------------------------------------------------- */

  async connect(): Promise<void> {
    await this.ensureClient();
    try {
      await this.client.connect();
      await this.client.mailboxOpen(env.MAILCARRIER_INBOX_FOLDER);
      this.reconnectAttempts = 0;
    } catch (err) {
      throw new MailCarrierConnectionError(
        `IMAP connection failed (kind=${this.kind}, user=${this.username}): ${(err as Error).message}`,
        err,
      );
    }
  }

  async stop(): Promise<void> {
    this.isRunning = false;
    if (!this.clientBuilt) return;
    try {
      await this.client.logout();
    } catch {
      // graceful — 무시
    }
  }

  /* --------------------------------------------------------
   * startListening — IDLE 또는 폴링
   * -------------------------------------------------------- */

  async startListening(onMessage: InboundHandler): Promise<void> {
    if (this.isRunning) {
      throw new MailCarrierError('Listener is already running');
    }
    this.isRunning = true;

    if (env.MAILCARRIER_USE_IDLE) {
      await this.runIdleLoop(onMessage);
    } else {
      await this.runPollingLoop(onMessage);
    }
  }

  private async runIdleLoop(onMessage: InboundHandler): Promise<void> {
    let iterations = 0;
    while (this.isRunning) {
      try {
        await this.fetchAndProcessNew(onMessage);
        // IDLE 대기 — 일부 IMAP 서버는 30분 후 끊으므로 imapflow는 자동 재시작
        await this.client.idle();
      } catch (err) {
        if (!this.isRunning) break;
        // eslint-disable-next-line no-console
        console.error(`[mailcarrier:${this.kind}] idle loop error:`, err);
        await this.handleReconnect();
      }
      iterations += 1;
      if (
        this.maxIterations !== undefined &&
        iterations >= this.maxIterations
      ) {
        break;
      }
    }
  }

  /* --------------------------------------------------------
   * runPollingLoop (Phase 2-b)
   *
   * - iteration tick 가시성 로그
   * - 단건 에러는 break하지 않고 다음 tick 시도
   * - 연속 10회 에러 시 abort (영구적 인증/네트워크 에러 가드)
   * - connection-level 에러(NoConnection/ETIMEOUT/ECONNRESET/ECONNREFUSED) 시 자동 재연결
   * -------------------------------------------------------- */

  private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
    let iterations = 0;
    let consecutiveErrors = 0;

    // eslint-disable-next-line no-console
    console.log(
      `[mailcarrier:${this.kind}] polling loop start ` +
        `(interval=${env.MAILCARRIER_POLL_INTERVAL_SECONDS}s, isRunning=${this.isRunning})`,
    );

    while (this.isRunning) {
      iterations += 1;
      const tickStart = Date.now();
      // eslint-disable-next-line no-console
      console.log(
        `[mailcarrier:${this.kind}] polling tick #${iterations} — searching new messages`,
      );

      try {
        await this.fetchAndProcessNew(onMessage);
        const elapsed = Date.now() - tickStart;
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] polling tick #${iterations} done (${elapsed}ms)`,
        );
        consecutiveErrors = 0;
      } catch (err) {
        consecutiveErrors += 1;
        const elapsed = Date.now() - tickStart;
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier:${this.kind}] polling iteration #${iterations} error ` +
            `after ${elapsed}ms (consecutive=${consecutiveErrors}):`,
          err,
        );

        // Connection-level 에러 시 자동 재연결 시도
        const errCode = (err as { code?: string }).code;
        if (
          errCode === 'NoConnection' ||
          errCode === 'ETIMEOUT' ||
          errCode === 'ECONNRESET' ||
          errCode === 'ECONNREFUSED'
        ) {
          // eslint-disable-next-line no-console
          console.warn(
            `[mailcarrier:${this.kind}] connection-level error detected (${errCode}) — attempting reconnect`,
          );
          try {
            await this.handleReconnect();
            // eslint-disable-next-line no-console
            console.log(`[mailcarrier:${this.kind}] reconnect succeeded`);
            consecutiveErrors = 0; // 재연결 성공 시 카운터 리셋
          } catch (reconnectErr) {
            // eslint-disable-next-line no-console
            console.error(
              `[mailcarrier:${this.kind}] reconnect failed:`,
              reconnectErr,
            );
          }
        }

        if (consecutiveErrors >= 10) {
          // eslint-disable-next-line no-console
          console.error(
            `[mailcarrier:${this.kind}] aborting polling loop after ${consecutiveErrors} consecutive errors`,
          );
          break;
        }
      }

      await new Promise((r) =>
        setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
      );
    }

    // eslint-disable-next-line no-console
    console.log(
      `[mailcarrier:${this.kind}] polling loop exited ` +
        `(isRunning=${this.isRunning}, iterations=${iterations})`,
    );
  }

  /* --------------------------------------------------------
   * withCommandTimeout — IMAP 명령 timeout 래퍼
   *
   * 일부 IMAP 서버가 특정 명령에 응답하지 않고 hang시키는 경우 대비.
   * Phase 2-c에서 messageFlagsAdd 호출이 제거되어 현재 미사용,
   * 향후 다른 IMAP 명령에 timeout이 필요할 때 활용.
   * -------------------------------------------------------- */

  private async withCommandTimeout<T>(
    op: () => Promise<T>,
    timeoutMs: number,
    opName: string,
  ): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(
          new Error(
            `IMAP command "${opName}" timed out after ${timeoutMs}ms`,
          ),
        );
      }, timeoutMs);

      op()
        .then((result) => {
          clearTimeout(timer);
          resolve(result);
        })
        .catch((err) => {
          clearTimeout(timer);
          reject(err);
        });
    });
  }

  /* --------------------------------------------------------
   * UID 기반 추적 — load / save (Phase 2-c)
   *
   * app.mailcarrier_state 테이블에 (org, kind, username)별로
   * 마지막 처리한 UID 저장. \Seen flag 의존성 제거.
   * -------------------------------------------------------- */

  /**
   * DB에서 마지막 처리한 UID 조회. 레코드 없으면 0 반환 (모든 메시지를 새 것으로 간주).
   */
  private async loadLastProcessedUid(): Promise<number> {
    const { data, error } = await this.supabase
      .schema('app')
      .from('mailcarrier_state')
      .select('last_processed_uid')
      .eq('organization_id', this.organizationId)
      .eq('kind', this.kind)
      .eq('username', this.username)
      .maybeSingle();

    if (error) {
      // eslint-disable-next-line no-console
      console.warn(
        `[mailcarrier:${this.kind}] loadLastProcessedUid failed, defaulting to 0:`,
        error.message,
      );
      return 0;
    }
    return data?.last_processed_uid ?? 0;
  }

  /**
   * 마지막 처리한 UID를 DB에 UPSERT.
   */
  private async saveLastProcessedUid(uid: number): Promise<void> {
    const { error } = await this.supabase
      .schema('app')
      .from('mailcarrier_state')
      .upsert(
        {
          organization_id: this.organizationId,
          kind: this.kind,
          username: this.username,
          last_processed_uid: uid,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'organization_id,kind,username' },
      );

    if (error) {
      // eslint-disable-next-line no-console
      console.error(
        `[mailcarrier:${this.kind}] saveLastProcessedUid failed for uid=${uid}:`,
        error.message,
      );
      // throw 안 함 — 다음 tick에서 재시도. 최악의 경우 같은 메시지 다시 처리되지만
      // message_id UNIQUE로 중복 INSERT 차단됨.
    }
  }

  /* --------------------------------------------------------
   * fetchAndProcessNew — UID 기반 새 메시지 처리 (Phase 2-c)
   *
   * \Seen 플래그 의존성 제거. DB에 저장된 last_processed_uid 기반으로
   * 새 메시지만 fetch. messageFlagsAdd 호출 없음.
   * -------------------------------------------------------- */

  async fetchAndProcessNew(onMessage: InboundHandler): Promise<void> {
    const t0 = Date.now();
    // eslint-disable-next-line no-console
    console.log(`[mailcarrier:${this.kind}] fetch: acquiring lock`);

    const lock = await this.client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);

    // eslint-disable-next-line no-console
    console.log(
      `[mailcarrier:${this.kind}] fetch: lock acquired (+${Date.now() - t0}ms)`,
    );

    let msgCount = 0;
    let lastUidProcessed: number | undefined;

    try {
      // 1. DB에서 last UID 조회
      const lastUid = await this.loadLastProcessedUid();
      const range = `${lastUid + 1}:*`;
      // eslint-disable-next-line no-console
      console.log(
        `[mailcarrier:${this.kind}] fetch: range=${range} (last_uid=${lastUid})`,
      );

      // 2. UID 기반 fetch (imapflow의 세 번째 인자 { uid: true })
      for await (const message of this.client.fetch(
        range,
        { source: true, envelope: true, uid: true },
        { uid: true },
      )) {
        const uid = Number((message as unknown as { uid?: number | string }).uid);

        // 안전 가드: 이미 처리한 UID는 skip (IMAP 서버가 inclusive로 반환할 수 있음)
        if (!Number.isFinite(uid) || uid <= lastUid) {
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.kind}] fetch: skipping uid=${uid} (<= last_uid=${lastUid})`,
          );
          continue;
        }

        msgCount += 1;
        const msgT0 = Date.now();
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] fetch: msg #${msgCount} received uid=${uid} (+${Date.now() - t0}ms)`,
        );

        try {
          if (!message.source) {
            // eslint-disable-next-line no-console
            console.log(
              `[mailcarrier:${this.kind}] fetch: msg #${msgCount} no source, marking as processed`,
            );
            lastUidProcessed = uid;
            continue;
          }

          const parsed = await this.parser(message.source);
          const event = await this.persistInbound(parsed);
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.kind}] fetch: msg #${msgCount} persistInbound done ` +
              `(event=${event ? 'yes' : 'null'}) (+${Date.now() - msgT0}ms)`,
          );

          if (event) {
            try {
              await onMessage(event);
              // eslint-disable-next-line no-console
              console.log(
                `[mailcarrier:${this.kind}] fetch: msg #${msgCount} onMessage done (+${Date.now() - msgT0}ms)`,
              );
            } catch (handlerErr) {
              // eslint-disable-next-line no-console
              console.error(
                `[mailcarrier:${this.kind}] fetch: msg #${msgCount} onMessage failed:`,
                handlerErr,
              );
              // onMessage 실패해도 메일 자체는 persist 완료 — UID 갱신 진행
            }
          }

          // 처리 완료 (persist 성공 또는 화이트리스트 skip 모두 포함) → UID 갱신
          lastUidProcessed = uid;
        } catch (err) {
          // eslint-disable-next-line no-console
          console.error(
            `[mailcarrier:${this.kind}] fetch: msg #${msgCount} uid=${uid} processing failed:`,
            err,
          );
          // 단건 실패 시 lastUidProcessed 갱신 안 함 → 다음 tick에서 재시도.
          // 그러나 그 후의 메시지들도 이번 tick에서는 처리 안 함 (sequential 보장).
          break;
        }
      }

      // 3. 처리한 마지막 UID를 DB에 저장
      if (lastUidProcessed !== undefined) {
        await this.saveLastProcessedUid(lastUidProcessed);
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] fetch: saved last_uid=${lastUidProcessed} ` +
            `(${msgCount} msgs in this tick, total +${Date.now() - t0}ms)`,
        );
      } else {
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.kind}] fetch: no new messages (+${Date.now() - t0}ms)`,
        );
      }
    } finally {
      // eslint-disable-next-line no-console
      console.log(`[mailcarrier:${this.kind}] fetch: releasing lock`);
      try {
        await lock.release();
        // eslint-disable-next-line no-console
        console.log(`[mailcarrier:${this.kind}] fetch: lock released`);
      } catch (releaseErr) {
        // eslint-disable-next-line no-console
        console.warn(
          `[mailcarrier:${this.kind}] fetch: lock release failed:`,
          releaseErr,
        );
      }
    }
  }

  /* --------------------------------------------------------
   * persistInbound — communications + attachments INSERT
   *
   * Phase 2: 진입 시 화이트리스트 체크.
   * -------------------------------------------------------- */

  async persistInbound(
    parsed: ParsedMail,
  ): Promise<InboundMessageEvent | null> {
    const headers = parseInboundMessage(parsed);

    // ── 화이트리스트 체크 (Phase 2) ──
    const fromAddress = headers.from.address;
    const isAllowed = await isFromAllowedSender(
      this.supabase,
      this.organizationId,
      fromAddress,
    );
    if (!isAllowed) {
      // eslint-disable-next-line no-console
      console.log(`[mailcarrier:${this.kind}] skip — not in whitelist: ${fromAddress}`);
      return null;
    }

    // 멱등성 — Message-ID UNIQUE
    const { data: existing, error: existingError } = await this.supabase
      .schema('app')
      .from('communications')
      .select('id, organization_id, thread_id')
      .eq('message_id', headers.messageId)
      .eq('organization_id', this.organizationId)
      .maybeSingle();

    if (existingError) {
      throw new MailCarrierError(
        `Duplicate check failed: ${existingError.message}`,
        existingError,
      );
    }
    if (existing) {
      // 이미 처리된 메시지 — 무시
      return null;
    }

    // 스레드 매칭
    const threadMatch = await findThreadId(
      this.supabase,
      this.organizationId,
      headers,
    );
    const threadId = threadMatch.threadId ?? randomUUID();

    // 발신자 → contact·party 매칭
    const senderMatch = await matchSenderToContactAndParty(
      this.supabase,
      this.organizationId,
      headers.from.address,
    );

    // PII 사전 마스킹
    const bodyPlainRaw = parsed.text ?? '';
    const { masked: maskedPlain, categories } = maskPii(bodyPlainRaw);

    const channel = 'email';
    const direction = 'inbound';

    const { data: inserted, error: insertError } = await this.supabase
      .schema('app')
      .from('communications')
      .insert({
        organization_id: this.organizationId,
        party_id: senderMatch.partyId ?? null,
        contact_id: senderMatch.contactId ?? null,
        engagement_id: threadMatch.matchedEngagementId ?? null,
        channel,
        direction,
        message_id: headers.messageId,
        in_reply_to: headers.inReplyTo ?? null,
        thread_id: threadId,
        from_address: headers.from.address,
        from_name: headers.from.name ?? null,
        to_addresses: headers.to.map((t) => t.address),
        cc_addresses: (headers.cc ?? []).map((c) => c.address),
        reply_to_address: headers.replyTo ?? null,
        subject: headers.subject,
        body_html: parsed.html || null,
        body_plain: maskedPlain,
        status: 'received',
        occurred_at: headers.date.toISOString(),
        received_at: this.nowProvider().toISOString(),
        ai_generated: false,
        external_data: {
          urm_headers: headers.urmHeaders,
          references: headers.references,
          raw_selected_headers: headers.rawSelectedHeaders ?? {},
          mailcarrier_received_at: this.nowProvider().toISOString(),
          mailcarrier_account_kind: this.kind,
          mailcarrier_account_username: this.username,
          pii_masked: true,
          pii_categories_detected: categories,
          thread_match: {
            matched_by: threadMatch.matchedBy,
            matched_comm_id: threadMatch.matchedCommId ?? null,
          },
          sender_match: {
            matched_by: senderMatch.matchedBy,
          },
        },
      })
      .select('id')
      .single();

    if (insertError || !inserted) {
      throw new MailCarrierError(
        `communications INSERT failed: ${insertError?.message ?? 'unknown'}`,
        insertError,
      );
    }

    const communicationId = inserted.id as string;

    // 첨부 처리
    for (const att of parsed.attachments ?? []) {
      try {
        await this.persistAttachment(communicationId, att);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier:${this.kind}] attachment persist failed for comm=${communicationId}:`,
          err,
        );
      }
    }

    return {
      communicationId,
      organizationId: this.organizationId,
      threadId,
      messageId: headers.messageId,
      bodyText: maskedPlain,
      piiCategories: categories,
      fromAddress: headers.from.address,
    };
  }

  /* --------------------------------------------------------
   * persistAttachment
   * -------------------------------------------------------- */

  private async persistAttachment(
    communicationId: string,
    att: Attachment,
  ): Promise<void> {
    if (!att.content || att.content.length === 0) return;
    if (att.content.length > ATTACHMENT_MAX_BYTES) {
      // eslint-disable-next-line no-console
      console.warn(
        `[mailcarrier:${this.kind}] attachment too large, skipping: ${att.filename ?? '(unknown)'} size=${att.content.length}`,
      );
      return;
    }

    const rawName = att.filename ?? `attachment-${Date.now()}`;
    const displayName = sanitizeFilename(rawName);
    const keyName = toStorageKeySegment(rawName);
    const path = `${this.organizationId}/${communicationId}/${randomUUID()}-${keyName}`;
    const contentHash = createHash('sha256').update(att.content).digest('hex');

    const { error: uploadError } = await this.supabase.storage
      .from(env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS)
      .upload(path, att.content, {
        contentType: att.contentType ?? 'application/octet-stream',
        upsert: false,
      });

    if (uploadError) {
      throw new MailCarrierError(
        `Storage upload failed: ${uploadError.message}`,
        uploadError,
      );
    }

    const { error: insertError } = await this.supabase
      .schema('app')
      .from('attachments')
      .insert({
        organization_id: this.organizationId,
        entity_type: 'communication',
        entity_id: communicationId,
        file_name: displayName,
        file_size_bytes: att.content.length,
        mime_type: att.contentType ?? 'application/octet-stream',
        storage_provider: 'supabase',
        storage_bucket: env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS,
        storage_path: path,
        content_hash_sha256: contentHash,
        is_inline: Boolean(
          (att as unknown as { contentDisposition?: string }).contentDisposition?.toLowerCase() ===
            'inline',
        ),
        is_quarantined: false,
      });

    if (insertError) {
      // eslint-disable-next-line no-console
      console.error(
        `[mailcarrier:${this.kind}] attachments INSERT failed, attempting Storage cleanup:`,
        insertError,
      );
      try {
        await this.supabase.storage
          .from(env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS)
          .remove([path]);
      } catch {
        /* 정리 실패도 무시 */
      }
      throw new MailCarrierError(
        `attachments INSERT failed: ${insertError.message}`,
        insertError,
      );
    }
  }

  /* --------------------------------------------------------
   * handleReconnect — exponential backoff
   * -------------------------------------------------------- */

  private async handleReconnect(): Promise<void> {
    if (this.reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      this.isRunning = false;
      throw new MailCarrierMaxReconnectError(MAX_RECONNECT_ATTEMPTS);
    }
    this.reconnectAttempts += 1;
    const delayMs = Math.min(Math.pow(2, this.reconnectAttempts) * 1000, 60_000);
    // eslint-disable-next-line no-console
    console.warn(
      `[mailcarrier:${this.kind}] reconnect attempt ${this.reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS} after ${delayMs}ms`,
    );
    await new Promise((r) => setTimeout(r, delayMs));
    try {
      await this.client.logout();
    } catch {
      // 이미 끊어진 세션 — 무시
    }
    await this.rebuildClient();
    await this.connect();
  }
}

/* ============================================================
 * 4. 보조 함수
 * ============================================================ */

/**
 * 파일명 정규화 — Storage 경로에 안전한 문자만 허용.
 */
export function sanitizeFilename(name: string): string {
  let sanitized = name.replace(/[/\\\u0000-\u001f]/g, '_');
  sanitized = sanitized.replace(/^[\s.]+|[\s.]+$/g, '');
  if (sanitized.length === 0) sanitized = `attachment-${Date.now()}`;
  if (sanitized.length > 180) {
    const dotIdx = sanitized.lastIndexOf('.');
    const ext = dotIdx > 0 ? sanitized.slice(dotIdx) : '';
    sanitized = sanitized.slice(0, 180 - ext.length) + ext;
  }
  return sanitized;
}

/**
 * Storage object key segment sanitizer.
 * Supabase Storage rejects keys containing spaces, brackets, and most
 * non-ASCII / punctuation chars (HTTP 400 "Invalid key"). This keeps only
 * [A-Za-z0-9._-], collapses runs to a single underscore, preserves the
 * extension, and falls back to a timestamp name if the base becomes empty.
 * The human-readable original name is stored separately in attachments.file_name.
 */
export function toStorageKeySegment(name: string): string {
  const dotIdx = name.lastIndexOf('.');
  const rawExt = dotIdx > 0 ? name.slice(dotIdx + 1) : '';
  const rawBase = dotIdx > 0 ? name.slice(0, dotIdx) : name;

  const cleanExt = rawExt.replace(/[^A-Za-z0-9]/g, '').slice(0, 16);
  let base = rawBase
    .replace(/[^A-Za-z0-9._-]/g, '_')
    .replace(/_{2,}/g, '_')
    .replace(/^[._-]+|[._-]+$/g, '');

  if (base.length === 0) base = `attachment-${Date.now()}`;
  if (base.length > 160) base = base.slice(0, 160);

  return cleanExt ? `${base}.${cleanExt}` : base;
}