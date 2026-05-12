/**
 * lib/email/mailcarrier.ts
 *
 * MailCarrier 7 외부 IMAP 시스템에서 메일을 수신해 communications에
 * 저장하고 processor.ts(Part 4)로 전달한다.
 *
 * 책임:
 *   - IMAP 연결·인증 (TLS)
 *   - IDLE 또는 폴링 기반 신규 메일 감지
 *   - mailparser로 raw → ParsedMail 변환
 *   - header-parser로 thread/sender 매칭
 *   - 첨부 → Supabase Storage 업로드
 *   - communications + attachments INSERT
 *   - 멱등성 (Message-ID UNIQUE)
 *   - PII 사전 마스킹 (저장 전 body)
 *   - 재연결 (exponential backoff)
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
import type { InboundMessageEvent } from '../../types/email';

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
}

export type InboundHandler = (event: InboundMessageEvent) => Promise<void>;

/* ============================================================
 * 3. MailCarrierClient
 * ============================================================ */

const MAX_RECONNECT_ATTEMPTS = 5;
const ATTACHMENT_MAX_BYTES = 25 * 1024 * 1024; // 25MB

export class MailCarrierClient {
  private client: IImapClient;
  private isRunning = false;
  private reconnectAttempts = 0;
  private readonly parser: ParserFn;
  private readonly nowProvider: () => Date;
  private readonly maxIterations: number | undefined;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
    options: MailCarrierClientOptions = {},
  ) {
    this.parser = options.parser ?? ((src) => simpleParser(src));
    this.nowProvider = options.nowProvider ?? (() => new Date());
    this.maxIterations = options.maxIterations;
    this.client = options.imapClient ?? this.buildClient();
  }

  private buildClient(): IImapClient {
    return new ImapFlow({
      host: env.MAILCARRIER_HOST,
      port: env.MAILCARRIER_PORT,
      secure: env.MAILCARRIER_PORT === 993,
      auth: {
        user: env.MAILCARRIER_USERNAME,
        pass: env.MAILCARRIER_PASSWORD,
      },
      logger: false,
    }) as unknown as IImapClient;
  }

  /* --------------------------------------------------------
   * connect / stop
   * -------------------------------------------------------- */

  async connect(): Promise<void> {
    try {
      await this.client.connect();
      await this.client.mailboxOpen(env.MAILCARRIER_INBOX_FOLDER);
      this.reconnectAttempts = 0;
    } catch (err) {
      throw new MailCarrierConnectionError(
        `IMAP connection failed: ${(err as Error).message}`,
        err,
      );
    }
  }

  async stop(): Promise<void> {
    this.isRunning = false;
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
        console.error('[mailcarrier] idle loop error:', err);
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

  private async runPollingLoop(onMessage: InboundHandler): Promise<void> {
    let iterations = 0;
    while (this.isRunning) {
      try {
        await this.fetchAndProcessNew(onMessage);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error('[mailcarrier] polling iteration error:', err);
        await this.handleReconnect();
      }
      iterations += 1;
      if (
        this.maxIterations !== undefined &&
        iterations >= this.maxIterations
      ) {
        break;
      }
      await new Promise((r) =>
        setTimeout(r, env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000),
      );
    }
  }

  /* --------------------------------------------------------
   * fetchAndProcessNew — UNSEEN 메시지 처리
   * -------------------------------------------------------- */

  async fetchAndProcessNew(onMessage: InboundHandler): Promise<void> {
    const lock = await this.client.getMailboxLock(env.MAILCARRIER_INBOX_FOLDER);
    try {
      for await (const message of this.client.fetch(
        { seen: false },
        { source: true, envelope: true, uid: true },
      )) {
        try {
          if (!message.source) continue;
          const parsed = await this.parser(message.source);
          const event = await this.persistInbound(parsed);
          if (event) {
            // processor 호출 — 실패해도 메일 처리 자체는 계속
            try {
              await onMessage(event);
            } catch (handlerErr) {
              // eslint-disable-next-line no-console
              console.error('[mailcarrier] onMessage handler failed:', handlerErr);
            }
            // 본 메일을 \\Seen 처리 (재처리 방지)
            const uid = (message as unknown as { uid?: number | string }).uid;
            if (uid !== undefined) {
              await this.client.messageFlagsAdd(uid, ['\\Seen']);
            }
          }
        } catch (err) {
          // 단건 실패는 다른 메일에 영향 없음 — 로깅만
          // eslint-disable-next-line no-console
          console.error('[mailcarrier] message processing failed:', err);
        }
      }
    } finally {
      await lock.release();
    }
  }

  /* --------------------------------------------------------
   * persistInbound — communications + attachments INSERT
   * -------------------------------------------------------- */

  async persistInbound(
    parsed: ParsedMail,
  ): Promise<InboundMessageEvent | null> {
    const headers = parseInboundMessage(parsed);

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

    // PII 사전 마스킹 (저장 전 body)
    const bodyPlainRaw = parsed.text ?? '';
    const { masked: maskedPlain, categories } = maskPii(bodyPlainRaw);

    // HTML body는 마스킹하지 않음 (HTML 구조 보존). 단, AI 호출 시
    // body_plain만 사용하므로 PII는 노출되지 않음. HTML 보존은 사람 검토용.

    // 채널 결정 — 현재는 email만, LinkedIn 통합은 미래.
    const channel = 'email';
    const direction = 'inbound';

    // language_detected는 분류기가 채움. 여기서는 NULL 유지.

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

    // 첨부 처리 (실패해도 메일 자체는 저장됨)
    for (const att of parsed.attachments ?? []) {
      try {
        await this.persistAttachment(communicationId, att);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier] attachment persist failed for comm=${communicationId}:`,
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
   * persistAttachment — Storage 업로드 + attachments INSERT
   * -------------------------------------------------------- */

  private async persistAttachment(
    communicationId: string,
    att: Attachment,
  ): Promise<void> {
    if (!att.content || att.content.length === 0) return;
    if (att.content.length > ATTACHMENT_MAX_BYTES) {
      // eslint-disable-next-line no-console
      console.warn(
        `[mailcarrier] attachment too large, skipping: ${att.filename ?? '(unknown)'} size=${att.content.length}`,
      );
      return;
    }

    const filename = sanitizeFilename(att.filename ?? `attachment-${Date.now()}`);
    const path = `${this.organizationId}/${communicationId}/${randomUUID()}-${filename}`;
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
        file_name: filename,
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
      // 업로드는 성공했으나 INSERT 실패 — Storage 정리 시도
      // eslint-disable-next-line no-console
      console.error(
        '[mailcarrier] attachments INSERT failed, attempting Storage cleanup:',
        insertError,
      );
      try {
        await this.supabase.storage
          .from(env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS)
          .remove([path]);
      } catch {/* 정리 실패도 무시 */}
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
      `[mailcarrier] reconnect attempt ${this.reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS} after ${delayMs}ms`,
    );
    await new Promise((r) => setTimeout(r, delayMs));
    try {
      await this.client.logout();
    } catch {
      // 이미 끊어진 세션 — 무시
    }
    this.client = this.buildClient();
    await this.connect();
  }
}

/* ============================================================
 * 4. 보조 함수
 * ============================================================ */

/**
 * 파일명 정규화 — Storage 경로에 안전한 문자만 허용.
 * 한글·일본어는 보존 (Supabase Storage는 UTF-8 안전).
 * 슬래시·역슬래시·제어문자는 _로 치환.
 */
export function sanitizeFilename(name: string): string {
  // 1. 제어 문자·경로 구분자 제거
  let sanitized = name.replace(/[/\\\u0000-\u001f]/g, '_');
  // 2. 양 끝 공백·점 정리 (Windows 호환)
  sanitized = sanitized.replace(/^[\s.]+|[\s.]+$/g, '');
  // 3. 빈 문자열 폴백
  if (sanitized.length === 0) sanitized = `attachment-${Date.now()}`;
  // 4. 길이 제한 (Supabase 200자)
  if (sanitized.length > 180) {
    const dotIdx = sanitized.lastIndexOf('.');
    const ext = dotIdx > 0 ? sanitized.slice(dotIdx) : '';
    sanitized = sanitized.slice(0, 180 - ext.length) + ext;
  }
  return sanitized;
}
