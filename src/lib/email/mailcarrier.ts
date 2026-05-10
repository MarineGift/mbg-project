import { ImapFlow, type FetchMessageObject, type MailboxLockObject } from 'imapflow';
import { simpleParser, type ParsedMail, type Attachment as ParsedAttachment } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';
import { createHash, randomUUID } from 'node:crypto';
import { env } from '@/lib/env';
import { maskPii } from '@/lib/ai/pii-masker';
import {
  findThreadId,
  findContactByEmail,
  parseInboundMessage,
  type ParsedHeaders,
} from './header-parser';

// ───────────────────────────────────────────────────────────────────
// 에러
// ───────────────────────────────────────────────────────────────────

export class MailCarrierError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'MailCarrierError';
  }
}

export class MailCarrierConnectionError extends MailCarrierError {
  constructor(message: string, cause?: unknown) {
    super(message, cause);
    this.name = 'MailCarrierConnectionError';
  }
}

// ───────────────────────────────────────────────────────────────────
// 타입
// ───────────────────────────────────────────────────────────────────

export interface InboundMessageNotification {
  communicationId: string;
  threadId: string;
  messageId: string;
  organizationId: string;
  partyId?: string;
  engagementId?: string;
  isAutoReply: boolean;
}

export type InboundMessageHandler = (
  msg: InboundMessageNotification,
) => Promise<void>;

// ───────────────────────────────────────────────────────────────────
// 정수
// ───────────────────────────────────────────────────────────────────

const MAX_RECONNECT_ATTEMPTS = 5;
const RECONNECT_BASE_DELAY_MS = 1_000;
const RECONNECT_MAX_DELAY_MS = 60_000;
const IDLE_RENEW_MS = 28 * 60 * 1000;

// ───────────────────────────────────────────────────────────────────
// MailCarrierClient
// ───────────────────────────────────────────────────────────────────

export class MailCarrierClient {
  private client: ImapFlow;
  private isRunning = false;
  private reconnectAttempts = 0;
  private idleRenewTimer: NodeJS.Timeout | null = null;
  private currentLock: MailboxLockObject | null = null;

  constructor(
    private readonly supabase: SupabaseClient,
    private readonly organizationId: string,
    imapClient?: ImapFlow,
  ) {
    this.client = imapClient ?? this.createImapClient();
  }

  private createImapClient(): ImapFlow {
    return new ImapFlow({
      host: env.MAILCARRIER_HOST,
      port: env.MAILCARRIER_PORT,
      secure: env.MAILCARRIER_PORT === 993,
      auth: {
        user: env.MAILCARRIER_USERNAME,
        pass: env.MAILCARRIER_PASSWORD,
      },
      logger: false,
    });
  }

  async connect(): Promise<void> {
    try {
      await this.client.connect();
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
    if (this.idleRenewTimer) {
      clearTimeout(this.idleRenewTimer);
      this.idleRenewTimer = null;
    }
    if (this.currentLock) {
      try {
        this.currentLock.release();
      } catch {
        // ignore
      }
      this.currentLock = null;
    }
    try {
      await this.client.logout();
    } catch {
      // ignore
    }
  }

  async startListening(onMessage: InboundMessageHandler): Promise<void> {
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

  private async runIdleLoop(onMessage: InboundMessageHandler): Promise<void> {
    while (this.isRunning) {
      try {
        await this.fetchAndProcessNew(onMessage);
        if (!this.isRunning) break;

        await this.runIdleWithTimeout();
      } catch (err) {
        if (!this.isRunning) break;
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier] idle loop error: ${(err as Error).message}`,
        );
        await this.handleReconnect();
      }
    }
  }

  private async runPollingLoop(onMessage: InboundMessageHandler): Promise<void> {
    const intervalMs = env.MAILCARRIER_POLL_INTERVAL_SECONDS * 1000;
    while (this.isRunning) {
      try {
        await this.fetchAndProcessNew(onMessage);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(
          `[mailcarrier] polling error: ${(err as Error).message}`,
        );
        await this.handleReconnect();
      }
      if (!this.isRunning) break;
      await sleep(intervalMs);
    }
  }

  private async runIdleWithTimeout(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      this.idleRenewTimer = setTimeout(() => {
        resolve();
      }, IDLE_RENEW_MS);

      this.client
        .idle()
        .then(() => {
          if (this.idleRenewTimer) clearTimeout(this.idleRenewTimer);
          resolve();
        })
        .catch((err) => {
          if (this.idleRenewTimer) clearTimeout(this.idleRenewTimer);
          reject(err);
        });
    });
  }

  private async fetchAndProcessNew(onMessage: InboundMessageHandler): Promise<void> {
    const folder = env.MAILCARRIER_INBOX_FOLDER;
    const lock = await this.client.getMailboxLock(folder);
    this.currentLock = lock;
    try {
      const iterator = this.client.fetch(
        { seen: false },
        { source: true, envelope: true, uid: true, flags: true },
      );

      for await (const message of iterator) {
        if (!this.isRunning) break;
        try {
          await this.processSingleMessage(message, onMessage);
          await this.client.messageFlagsAdd(message.uid, ['\\Seen'], { uid: true });
        } catch (err) {
          // eslint-disable-next-line no-console
          console.error(
            `[mailcarrier] message processing failed (uid=${message.uid}): ${(err as Error).message}`,
          );
        }
      }
    } finally {
      lock.release();
      this.currentLock = null;
    }
  }

  private async processSingleMessage(
    message: FetchMessageObject,
    onMessage: InboundMessageHandler,
  ): Promise<void> {
    if (!message.source) {
      throw new MailCarrierError(`Message uid=${message.uid} has no source`);
    }
    const parsed = await simpleParser(message.source);
    const inbound = await this.persistInbound(parsed);
    if (!inbound) return;
    try {
      await onMessage(inbound);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(
        `[mailcarrier] onMessage handler failed for ${inbound.messageId}: ${(err as Error).message}`,
      );
    }
  }

  private async persistInbound(parsed: ParsedMail): Promise<InboundMessageNotification | null> {
    return persistInbound(this.supabase, this.organizationId, parsed);
  }

  private async persistAttachment(
    communicationId: string,
    att: ParsedAttachment,
  ): Promise<void> {
    return persistAttachment(this.supabase, this.organizationId, communicationId, att);
  }

  private async handleReconnect(): Promise<void> {
    if (!this.isRunning) return;

    this.reconnectAttempts += 1;
    if (this.reconnectAttempts > MAX_RECONNECT_ATTEMPTS) {
      this.isRunning = false;
      throw new MailCarrierConnectionError(
        `Reconnect attempts exhausted (${MAX_RECONNECT_ATTEMPTS})`,
      );
    }

    const delayMs = Math.min(
      RECONNECT_BASE_DELAY_MS * Math.pow(2, this.reconnectAttempts - 1),
      RECONNECT_MAX_DELAY_MS,
    );
    // eslint-disable-next-line no-console
    console.warn(
      `[mailcarrier] reconnecting in ${delayMs}ms (attempt ${this.reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS})`,
    );
    await sleep(delayMs);

    try {
      await this.client.logout();
    } catch {
      // ignore
    }

    this.client = this.createImapClient();
    try {
      await this.client.connect();
      this.reconnectAttempts = 0;
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(
        `[mailcarrier] reconnect failed: ${(err as Error).message}`,
      );
    }
  }
}

// ───────────────────────────────────────────────────────────────────
// 자유 함수 (재사용을 위한 export — 웹훅 경로 등에서 직접 호출 가능)
// ───────────────────────────────────────────────────────────────────

/**
 * raw ParsedMail을 받아 communications + attachments에 INSERT하고 알림을 반환.
 * IMAP 루프와 HTTP 웹훅 양쪽에서 동일하게 사용됨.
 *
 * 멱등성: messages_id가 이미 존재하면 null 반환 (UNIQUE 위반 23505도 동일 처리).
 *
 * 호출자는 이 함수가 throw하는 경우 (네트워크/Storage/DB 비-23505 에러)를 적절히 catch해야 함.
 */
export async function persistInbound(
  supabase: SupabaseClient,
  organizationId: string,
  parsed: ParsedMail,
): Promise<InboundMessageNotification | null> {
  const headers = parseInboundMessage(parsed);

  const { data: existing } = await supabase
    .schema('app')
    .from('communications')
    .select('id')
    .eq('organization_id', organizationId)
    .eq('message_id', headers.messageId)
    .maybeSingle();
  if (existing) return null;

  const matchedThreadId = await findThreadId(supabase, organizationId, headers);
  const threadId = matchedThreadId ?? randomUUID();

  const contactMatch = await findContactByEmail(
    supabase,
    organizationId,
    headers.from.address,
  );

  const bodyPlainRaw = parsed.text ?? '';
  const { masked: maskedBodyPlain, categories: piiCategories } = maskPii(bodyPlainRaw);
  const bodyHtml = typeof parsed.html === 'string' ? parsed.html : null;

  const languageDetected = detectLanguage(headers, bodyPlainRaw);
  const isAutoReply = detectAutoReply(parsed, headers);

  const insertPayload = {
    organization_id: organizationId,
    party_id: contactMatch?.partyId ?? headers.urmHeaders.partyId ?? null,
    contact_id: contactMatch?.contactId ?? null,
    engagement_id: headers.urmHeaders.engagementId ?? null,
    message_id: headers.messageId,
    thread_id: threadId,
    in_reply_to: headers.inReplyTo ?? null,
    direction: 'inbound',
    channel: 'email',
    from_address: headers.from.address,
    from_name: headers.from.name ?? null,
    to_addresses: headers.to.map((t) => t.address),
    cc_addresses: headers.cc.map((c) => c.address),
    bcc_addresses: headers.bcc.map((b) => b.address),
    reply_to_address: headers.replyTo?.address ?? null,
    subject: headers.subject,
    body_plain: maskedBodyPlain,
    body_html: bodyHtml,
    language_detected: languageDetected,
    status: 'received',
    occurred_at: headers.date.toISOString(),
    received_at: new Date().toISOString(),
    external_data: {
      urm_headers: headers.urmHeaders,
      references: headers.references,
      is_auto_reply: isAutoReply,
      content_language: headers.contentLanguage ?? null,
    },
    ai_processing_status: 'pending',
    ai_generated: false,
    pii_masked: true,
    pii_categories_detected: piiCategories,
  };

  const { data: comm, error: commError } = await supabase
    .schema('app')
    .from('communications')
    .insert(insertPayload)
    .select('id')
    .single();

  if (commError || !comm) {
    if ((commError as { code?: string } | null)?.code === '23505') {
      return null;
    }
    throw new MailCarrierError(
      `communications INSERT failed: ${commError?.message}`,
      commError,
    );
  }

  const communicationId = String((comm as { id: string }).id);

  for (const att of parsed.attachments ?? []) {
    try {
      await persistAttachment(supabase, organizationId, communicationId, att);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(
        `[mailcarrier] attachment persist failed (${att.filename ?? 'noname'}): ${(err as Error).message}`,
      );
    }
  }

  return {
    communicationId,
    threadId,
    messageId: headers.messageId,
    organizationId,
    partyId: contactMatch?.partyId ?? headers.urmHeaders.partyId,
    engagementId: headers.urmHeaders.engagementId,
    isAutoReply,
  };
}

export async function persistAttachment(
  supabase: SupabaseClient,
  organizationId: string,
  communicationId: string,
  att: ParsedAttachment,
): Promise<void> {
  const filename = sanitizeFilename(att.filename ?? `attachment-${Date.now()}`);
  const storagePath = `${organizationId}/${communicationId}/${filename}`;
  const mimeType = att.contentType ?? 'application/octet-stream';
  const bucket = env.SUPABASE_STORAGE_BUCKET_ATTACHMENTS;

  const content = Buffer.isBuffer(att.content)
    ? att.content
    : Buffer.from(att.content as unknown as ArrayBuffer);

  const { error: uploadError } = await supabase.storage
    .from(bucket)
    .upload(storagePath, content, {
      contentType: mimeType,
      upsert: false,
    });

  if (uploadError) {
    throw new MailCarrierError(
      `Storage upload failed: ${uploadError.message}`,
      uploadError,
    );
  }

  const sha256 = createHash('sha256').update(content).digest('hex');

  const { error: insertError } = await supabase
    .schema('app')
    .from('attachments')
    .insert({
      organization_id: organizationId,
      entity_type: 'communication',
      entity_id: communicationId,
      file_name: filename,
      file_size_bytes: content.byteLength,
      mime_type: mimeType,
      storage_provider: 'supabase',
      storage_bucket: bucket,
      storage_path: storagePath,
      content_hash_sha256: sha256,
      is_inline: !!att.cid,
      is_quarantined: false,
      virus_scan_status: 'pending',
    });

  if (insertError) {
    throw new MailCarrierError(
      `attachments INSERT failed: ${insertError.message}`,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// 헬퍼
// ───────────────────────────────────────────────────────────────────

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function sanitizeFilename(raw: string): string {
  return raw
    // eslint-disable-next-line no-control-regex
    .replace(/[\x00-\x1f/\\]/g, '_')
    .replace(/\.\.+/g, '.')
    .slice(0, 200);
}

function detectLanguage(
  headers: ParsedHeaders,
  bodyPlain: string,
): 'ko' | 'en' | 'ja' | 'zh-CN' | 'other' {
  const cl = (headers.contentLanguage ?? '').toLowerCase();
  if (cl.startsWith('ko')) return 'ko';
  if (cl.startsWith('ja')) return 'ja';
  if (cl.startsWith('zh')) return 'zh-CN';
  if (cl.startsWith('en')) return 'en';

  const sample = bodyPlain.slice(0, 1_500);
  const hangul = (sample.match(/[\uAC00-\uD7AF]/g) ?? []).length;
  const hiraganaKatakana = (sample.match(/[\u3040-\u30FF]/g) ?? []).length;
  const cjkUnified = (sample.match(/[\u4E00-\u9FFF]/g) ?? []).length;

  const total = sample.length;
  if (total > 0) {
    if (hangul / total > 0.05) return 'ko';
    if (hiraganaKatakana / total > 0.03) return 'ja';
    if (cjkUnified / total > 0.05) return 'zh-CN';
  }

  const latin = (sample.match(/[A-Za-z]/g) ?? []).length;
  if (total > 0 && latin / total > 0.4) return 'en';
  return 'other';
}

function detectAutoReply(parsed: ParsedMail, headers: ParsedHeaders): boolean {
  const h = parsed.headers;
  if (!h) return false;
  const autoSubmitted = h.get('auto-submitted');
  if (typeof autoSubmitted === 'string' && autoSubmitted.toLowerCase() !== 'no') {
    return true;
  }
  const autoresponse = h.get('x-auto-response-suppress');
  if (typeof autoresponse === 'string' && autoresponse.length > 0) {
    return true;
  }
  const subject = headers.subject.toLowerCase();
  if (
    subject.startsWith('auto:')
    || subject.startsWith('automatic reply')
    || subject.startsWith('out of office')
    || subject.startsWith('자동 응답')
    || subject.startsWith('자동 회신')
    || subject.includes('vacation')
  ) {
    return true;
  }
  return false;
}
