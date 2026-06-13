/**
 * lib/email/mailcarrier.ts
 *
 * Receives mail from our own IMAP mail server, stores it in communications, and
 * hands it off to processor.ts (Part 4).
 *
 * Phase 2 changes:
 *   - added an optional kind? to the constructor (auto-maps personal/role/shared credentials)
 *   - when kind is unset, falls back to the single MAILCARRIER_USERNAME/PASSWORD
 *   - keeps the whitelist entry-point check
 *
 * Phase 2-b changes (stability):
 *   - runPollingLoop tick visibility logs + consecutive-error guard
 *   - ImapFlow socketTimeout 60s (shortened from the 5-minute default)
 *   - auto-reconnect on connection-level errors
 *
 * Phase 2-c changes (UID tracking):
 *   - tracks last_processed_uid via the app.mailcarrier_state table
 *   - fully removes the \Seen flag dependency (never calls messageFlagsAdd)
 *   - changes the fetch range from UNSEEN search -> UID range
 *
 * Multi-Account Mail Hub Step 2 (2026-06-12):
 *   - persistInbound records communications.mail_account_id (= inbound_mailboxes.id)
 *     for the DB-account polling path; data basis for reply From auto-selection.
 *
 * Responsibilities:
 *   - IMAP connection/auth (TLS)
 *   - detect new mail via IDLE or polling
 *   - convert raw -> ParsedMail with mailparser
 *   - thread/sender matching via header-parser
 *   - whitelist filtering
 *   - upload attachments -> Supabase Storage
 *   - communications + attachments INSERT
 *   - idempotency (Message-ID UNIQUE + UID tracking)
 *   - PII pre-masking (body before storage)
 *   - reconnect (exponential backoff + polling-loop auto-reconnect)
 *
 * Not responsible for:
 *   - mail classification / reply-draft generation (processor.ts)
 *   - folder housekeeping (operational policy)
 */

import { ImapFlow, type FetchMessageObject } from 'imapflow';
import { simpleParser, type Attachment, type ParsedMail } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';
import { randomUUID, createHash } from 'node:crypto';
import { env, requireMailcarrierEnv } from '../env';
import { maskPii } from '../ai/pii-masker';
import {
  parseInboundMessage,
  findThreadId,
  matchSenderToContactAndParty,
} from './header-parser';
import { isFromAllowedSender } from './whitelist';
import type { InboundMessageEvent, SendingAddressKind } from '../../types/email';

/* ============================================================
 * 1. Error classes
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
 * 2. Interfaces (test-friendly)
 * ============================================================ */

/** Abstracts ImapFlow - can be swapped with a fake in tests. */
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

/** Abstracts mailparser's simpleParser. */
export type ParserFn = (source: Buffer | string) => Promise<ParsedMail>;

export interface MailCarrierClientOptions {
  imapClient?: IImapClient;
  parser?: ParserFn;
  nowProvider?: () => Date;
  /** Used to break the infinite idle loop in unit tests. */
  maxIterations?: number;
  /**
   * Phase 2: which sending-account credentials to use for IMAP auth.
   * When unset, uses the existing MAILCARRIER_USERNAME/PASSWORD (Phase 1 backward compat).
   */
  kind?: SendingAddressKind;
  /**
   * Phase 3: an arbitrary receiving account from the DB (app.inbound_mailboxes).
   * When set, ignores kind/env and connects with this account's host/port/username + decrypted password.
   * The password is received as bytea (encrypted) and decrypted via RPC at connect() time
   * (keeps the constructor synchronous - the kind/env path is still created synchronously as before).
   */
  account?: {
    id: string;
    address: string;
    host: string;
    port: number;
    /** app.inbound_mailboxes.password_encrypted (PostgREST bytea -> hex string). */
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
  /** The account path lazily creates the client at connect() time. Tracks whether creation is done. */
  private clientBuilt = false;
  /** Phase 3: DB-based receiving account (ignores kind/env when set). */
  private readonly account?: MailCarrierClientOptions['account'];
  private isRunning = false;
  private reconnectAttempts = 0;
  private readonly parser: ParserFn;
  private readonly nowProvider: () => Date;
  private readonly maxIterations: number | undefined;
  /** kind identifier (for logs / external_data metadata). */
  public readonly kind: SendingAddressKind | 'default' | 'account';
  /** username currently used for IMAP auth (for logging). */
  public readonly username: string;

  /** Actual IMAP host/port this carrier will dial (account path uses the DB
   *  values; otherwise the env defaults). For accurate worker logging. */
  public get connectHost(): string {
    return this.account?.host ?? env.MAILCARRIER_HOST ?? '(unset)';
  }
  public get connectPort(): number {
    return this.account?.port ?? env.MAILCARRIER_PORT;
  }
  /** 2026-06-12: prevents overlapping fetch passes on the same client. */
  private fetchInFlight = false;

  /** 2026-06-12: log tag including the account address so multiple DB
   *  mailboxes (all kind='account') are distinguishable in worker logs. */
  private get logTag(): string {
    return this.username ? `${this.kind}:${this.username}` : String(this.kind);
  }

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
      // Test-injected client - used as-is regardless of kind/account.
      this.kind = options.account ? 'account' : (options.kind ?? 'default');
      this.username =
        options.account?.address ??
        this.resolveCredentials(options.kind).username;
      this.client = options.imapClient;
      this.clientBuilt = true;
    } else if (options.account) {
      // Phase 3: DB account - password decryption is async, so the client is lazily created in connect().
      this.kind = 'account';
      this.username = options.account.address;
      // this.client is set in ensureClient() (clientBuilt stays false)
    } else {
      // Phase 1/2: env (kind/default) based - created synchronously, same behavior as before.
      this.kind = options.kind ?? 'default';
      const creds = this.resolveCredentials(options.kind);
      this.username = creds.username;
      this.client = this.buildClient(creds);
      this.clientBuilt = true;
    }
  }

  /**
   * Determine IMAP credentials based on kind.
   * - kind set: use MAIL_<KIND>_USERNAME/PASSWORD
   * - unset: use MAILCARRIER_USERNAME/PASSWORD (Phase 1 backward compat)
   */
  private resolveCredentials(
    kind?: SendingAddressKind,
  ): { username: string; password: string } {
    if (!kind) {
      // Phase 1 backward compat (worker-only env; fail fast if unset)
      const mc = requireMailcarrierEnv();
      return { username: mc.username, password: mc.password };
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
    // The account path uses per-account host/port; otherwise the existing single env values (backward compat).
    const host = creds.host ?? requireMailcarrierEnv().host;
    const port = creds.port ?? env.MAILCARRIER_PORT;
    // 993: implicit TLS. 143: plaintext. This server is plaintext-only with NO
    // STARTTLS, so doSTARTTLS:false stops ImapFlow from attempting an upgrade
    // (the default opportunistic STARTTLS handshake hung against this server).
    const isImplicitTls = port === 993;
    // option to allow self-signed certificates (verification environments only)
    const rejectUnauthorized = env.MAILCARRIER_TLS_REJECT_UNAUTHORIZED ?? true;

    return new ImapFlow({
      host,
      port,
      secure: isImplicitTls,
      doSTARTTLS: isImplicitTls ? undefined : false,
      auth: {
        user: creds.username,
        pass: creds.password,
      },
      tls: { rejectUnauthorized },
      logger: false,
      // plaintext server should answer fast; fail quickly if it does not.
      socketTimeout: 20_000,
    }) as unknown as IImapClient;
  }

  /* --------------------------------------------------------
   * Lazy client creation (Phase 3)
   *
   * the account path can't be built in the constructor because password decryption is async.
   * connect()/handleReconnect() build the actual client via these methods.
   * the env (kind/default) path is already built in the constructor (clientBuilt=true), so this is a no-op.
   * -------------------------------------------------------- */

  private async ensureClient(): Promise<void> {
    if (this.clientBuilt) return;
    await this.rebuildClient();
  }

  /** For an account, rebuild with the decrypted password + account host/port; otherwise with kind/env creds. */
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
   * Decrypt app.inbound_mailboxes.password_encrypted (bytea).
   * Uses the pgcrypto RPC + CALENDAR_TOKEN_ENCRYPTION_KEY, same as calendar token-crypto.
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
      // graceful - ignore
    }
  }

  /* --------------------------------------------------------
   * startListening - IDLE or polling
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
        // IDLE wait - some IMAP servers drop after 30 minutes, so imapflow auto-restarts
        await this.client.idle();
      } catch (err) {
        if (!this.isRunning) break;
        // eslint-disable-next-line no-console
        console.error(`[mailcarrier:${this.logTag}] idle loop error:`, err);
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
   * - iteration tick visibility logs
   * - a single error doesn't break the loop; it retries on the next tick
   * - abort after 10 consecutive errors (guard against permanent auth/network errors)
   * - auto-reconnect on connection-level errors (NoConnection/ETIMEOUT/ECONNRESET/ECONNREFUSED)
   * -------------------------------------------------------- */

  private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
    let iterations = 0;
    let consecutiveErrors = 0;

    // eslint-disable-next-line no-console
    console.log(
      `[mailcarrier:${this.logTag}] polling loop start ` +
        `(interval=${env.MAILCARRIER_POLL_INTERVAL_SECONDS}s, isRunning=${this.isRunning})`,
    );

    while (this.isRunning) {
      iterations += 1;
      const tickStart = Date.now();
      // eslint-disable-next-line no-console
      console.log(
        `[mailcarrier:${this.logTag}] polling tick #${iterations} — searching new messages`,
      );

      try {
        await this.fetchAndProcessNew(onMessage);
        const elapsed = Date.now() - tickStart;
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.logTag}] polling tick #${iterations} done (${elapsed}ms)`,
        );
        consecutiveErrors = 0;
      } catch (err) {
        consecutiveErrors += 1;
        const elapsed = Date.now() - tickStart;
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier:${this.logTag}] polling iteration #${iterations} error ` +
            `after ${elapsed}ms (consecutive=${consecutiveErrors}):`,
          err,
        );

        // Attempt auto-reconnect on connection-level errors
        const errCode = (err as { code?: string }).code;
        if (
          errCode === 'NoConnection' ||
          errCode === 'ETIMEOUT' ||
          errCode === 'ECONNRESET' ||
          errCode === 'ECONNREFUSED'
        ) {
          // eslint-disable-next-line no-console
          console.warn(
            `[mailcarrier:${this.logTag}] connection-level error detected (${errCode}) — attempting reconnect`,
          );
          try {
            await this.handleReconnect();
            // eslint-disable-next-line no-console
            console.log(`[mailcarrier:${this.logTag}] reconnect succeeded`);
            consecutiveErrors = 0; // reset the counter on successful reconnect
          } catch (reconnectErr) {
            // eslint-disable-next-line no-console
            console.error(
              `[mailcarrier:${this.logTag}] reconnect failed:`,
              reconnectErr,
            );
          }
        }

        if (consecutiveErrors >= 10) {
          // eslint-disable-next-line no-console
          console.error(
            `[mailcarrier:${this.logTag}] aborting polling loop after ${consecutiveErrors} consecutive errors`,
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
      `[mailcarrier:${this.logTag}] polling loop exited ` +
        `(isRunning=${this.isRunning}, iterations=${iterations})`,
    );
  }

  /* --------------------------------------------------------
   * withCommandTimeout - IMAP command timeout wrapper
   *
   * Guards against cases where some IMAP servers hang without responding to certain commands.
   * In Phase 2-c the messageFlagsAdd call was removed, so it's currently unused;
   * kept for future use when another IMAP command needs a timeout.
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
   * UID-based tracking - load / save (Phase 2-c)
   *
   * In the app.mailcarrier_state table, per (org, kind, username),
   * store the last processed UID. Removes the \Seen flag dependency.
   * -------------------------------------------------------- */

  /**
   * Look up the last processed UID from the DB. Returns 0 if no record (treats all messages as new).
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
        `[mailcarrier:${this.logTag}] loadLastProcessedUid failed, defaulting to 0:`,
        error.message,
      );
      return 0;
    }
    return data?.last_processed_uid ?? 0;
  }

  /**
   * UPSERT the last processed UID into the DB.
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
        `[mailcarrier:${this.logTag}] saveLastProcessedUid failed for uid=${uid}:`,
        error.message,
      );
      // doesn't throw - retries on the next tick. Worst case the same message is processed again, but
      // message_id UNIQUE blocks the duplicate INSERT.
    }
  }

  /* --------------------------------------------------------
   * fetchAndProcessNew - UID-based new-message processing (Phase 2-c)
   *
   * Removes the \Seen flag dependency. Based on the last_processed_uid stored in the DB,
   * fetch only new messages. No messageFlagsAdd call.
   * -------------------------------------------------------- */

  async fetchAndProcessNew(onMessage: InboundHandler): Promise<void> {
    // 2026-06-12: skip if a previous pass on this client is still running
    // (long initial scans overlapped with poll ticks and mixed their logs).
    if (this.fetchInFlight) {
      // eslint-disable-next-line no-console
      console.log(`[mailcarrier:${this.logTag}] fetch: previous pass still in flight - skipping tick`);
      return;
    }
    this.fetchInFlight = true;

    const t0 = Date.now();
    // eslint-disable-next-line no-console
    console.log(`[mailcarrier:${this.logTag}] fetch: acquiring lock`);

    const lock = await this.client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);

    // eslint-disable-next-line no-console
    console.log(
      `[mailcarrier:${this.logTag}] fetch: lock acquired (+${Date.now() - t0}ms)`,
    );

    let msgCount = 0;
    let lastUidProcessed: number | undefined;

    try {
      // 1. look up the last UID from the DB
      const lastUid = await this.loadLastProcessedUid();
      const range = `${lastUid + 1}:*`;
      // eslint-disable-next-line no-console
      console.log(
        `[mailcarrier:${this.logTag}] fetch: range=${range} (last_uid=${lastUid})`,
      );

      // 2. UID-based fetch (imapflow's third argument { uid: true })
      for await (const message of this.client.fetch(
        range,
        { source: true, envelope: true, uid: true },
        { uid: true },
      )) {
        const uid = Number((message as unknown as { uid?: number | string }).uid);

        // safety guard: skip UIDs already processed (the IMAP server may return them inclusively)
        if (!Number.isFinite(uid) || uid <= lastUid) {
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.logTag}] fetch: skipping uid=${uid} (<= last_uid=${lastUid})`,
          );
          continue;
        }

        msgCount += 1;
        const msgT0 = Date.now();
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.logTag}] fetch: msg #${msgCount} received uid=${uid} (+${Date.now() - t0}ms)`,
        );

        try {
          if (!message.source) {
            // eslint-disable-next-line no-console
            console.log(
              `[mailcarrier:${this.logTag}] fetch: msg #${msgCount} no source, marking as processed`,
            );
            lastUidProcessed = uid;
            await this.saveLastProcessedUid(uid); // 2026-06-12: incremental save
            continue;
          }

          const parsed = await this.parser(message.source);
          const event = await this.persistInbound(parsed);
          // eslint-disable-next-line no-console
          console.log(
            `[mailcarrier:${this.logTag}] fetch: msg #${msgCount} persistInbound done ` +
              `(event=${event ? 'yes' : 'null'}) (+${Date.now() - msgT0}ms)`,
          );

          if (event) {
            try {
              await onMessage(event);
              // eslint-disable-next-line no-console
              console.log(
                `[mailcarrier:${this.logTag}] fetch: msg #${msgCount} onMessage done (+${Date.now() - msgT0}ms)`,
              );
            } catch (handlerErr) {
              // eslint-disable-next-line no-console
              console.error(
                `[mailcarrier:${this.logTag}] fetch: msg #${msgCount} onMessage failed:`,
                handlerErr,
              );
              // even if onMessage fails, the mail itself is fully persisted - proceed with the UID update
            }
          }

          // processing done (covers both persist success and whitelist skip) -> update the UID
          // 2026-06-12: save IMMEDIATELY per message. Previously the UID was saved only
          // once at the end of the whole pass, so a dropped IMAP connection during a long
          // initial scan lost all progress and every restart re-scanned the entire mailbox
          // (state stuck, e.g. contact@ frozen at uid=75 while uids up to 230 were streamed).
          lastUidProcessed = uid;
          await this.saveLastProcessedUid(uid);
        } catch (err) {
          // eslint-disable-next-line no-console
          console.error(
            `[mailcarrier:${this.logTag}] fetch: msg #${msgCount} uid=${uid} processing failed:`,
            err,
          );
          // on a single failure, don't update lastUidProcessed -> retry on the next tick.
          // but the messages after it are also not processed this tick (guarantees sequential order).
          break;
        }
      }

      // 3. save the last processed UID to the DB
      if (lastUidProcessed !== undefined) {
        await this.saveLastProcessedUid(lastUidProcessed);
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.logTag}] fetch: saved last_uid=${lastUidProcessed} ` +
            `(${msgCount} msgs in this tick, total +${Date.now() - t0}ms)`,
        );
      } else {
        // eslint-disable-next-line no-console
        console.log(
          `[mailcarrier:${this.logTag}] fetch: no new messages (+${Date.now() - t0}ms)`,
        );
      }
    } finally {
      this.fetchInFlight = false;
      // eslint-disable-next-line no-console
      console.log(`[mailcarrier:${this.logTag}] fetch: releasing lock`);
      try {
        await lock.release();
        // eslint-disable-next-line no-console
        console.log(`[mailcarrier:${this.logTag}] fetch: lock released`);
      } catch (releaseErr) {
        // eslint-disable-next-line no-console
        console.warn(
          `[mailcarrier:${this.logTag}] fetch: lock release failed:`,
          releaseErr,
        );
      }
    }
  }

  /* --------------------------------------------------------
   * persistInbound — communications + attachments INSERT
   *
   * Phase 2: whitelist check on entry.
   * -------------------------------------------------------- */

  async persistInbound(
    parsed: ParsedMail,
  ): Promise<InboundMessageEvent | null> {
    const headers = parseInboundMessage(parsed);

    // -- whitelist check (Phase 2) --
    const fromAddress = headers.from.address;
    const isAllowed = await isFromAllowedSender(
      this.supabase,
      this.organizationId,
      fromAddress,
    );
    if (!isAllowed) {
      // eslint-disable-next-line no-console
      console.log(`[mailcarrier:${this.logTag}] skip — not in whitelist: ${fromAddress}`);
      return null;
    }

    // idempotency - Message-ID UNIQUE
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
      // already-processed message - ignore
      return null;
    }

    // thread matching
    const threadMatch = await findThreadId(
      this.supabase,
      this.organizationId,
      headers,
    );
    const threadId = threadMatch.threadId ?? randomUUID();

    // sender -> contact/party matching
    const senderMatch = await matchSenderToContactAndParty(
      this.supabase,
      this.organizationId,
      headers.from.address,
    );

    // PII pre-masking
    const bodyPlainRaw = parsed.text ?? '';
    const { categories } = maskPii(bodyPlainRaw); // A-fix: store raw body; keep categories for AI-run metadata

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
        // Step 2 (2026-06-12): record which DB mail account received this message.
        // Basis for reply From auto-selection (Step 3/4). NULL on the env(kind) fallback path.
        mail_account_id: this.account?.id ?? null,
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
        body_plain: bodyPlainRaw,
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
          mailcarrier_account_id: this.account?.id ?? null,
          pii_masked: false,
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

    // attachment handling
    for (const att of parsed.attachments ?? []) {
      try {
        await this.persistAttachment(communicationId, att);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier:${this.logTag}] attachment persist failed for comm=${communicationId}:`,
          err,
        );
      }
    }

    return {
      communicationId,
      organizationId: this.organizationId,
      threadId,
      messageId: headers.messageId,
      bodyText: bodyPlainRaw,
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
        `[mailcarrier:${this.logTag}] attachment too large, skipping: ${att.filename ?? '(unknown)'} size=${att.content.length}`,
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
        `[mailcarrier:${this.logTag}] attachments INSERT failed, attempting Storage cleanup:`,
        insertError,
      );
      try {
        await this.supabase.storage
          .from(env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS)
          .remove([path]);
      } catch {
        /* ignore cleanup failures too */
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
      `[mailcarrier:${this.logTag}] reconnect attempt ${this.reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS} after ${delayMs}ms`,
    );
    await new Promise((r) => setTimeout(r, delayMs));
    try {
      await this.client.logout();
    } catch {
      // already-disconnected session - ignore
    }
    await this.rebuildClient();
    await this.connect();
  }
}

/* ============================================================
 * 4. Helper functions
 * ============================================================ */

/**
 * Filename normalization - allows only characters safe for a Storage path.
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