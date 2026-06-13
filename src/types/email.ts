/**
 * types/email.ts
 *
 * Domain object types for email communications.
 *
 * Covered areas:
 *   - app.communications rows (CommunicationRow)
 *   - app.attachments rows (AttachmentRow)
 *   - parsed incoming mail (ParsedHeaders, ParsedInbound)
 *   - URM custom headers (UrmHeaders, 4 X-URM-* headers)
 *   - send input (SendOneInput, CampaignParams)
 *   - send statistics (TabsCampaignStats)
 *   - bulk-send jobs (MailMergeJobRow, QuietHours)
 *   - thread-matching result
 */

import type { PartyTypeCode, Language } from './ai';

/* ============================================================
 * 1. Channel/direction enums
 * ============================================================ */

export type Direction = 'inbound' | 'outbound';
export type Channel = 'email' | 'phone' | 'meeting' | 'note' | 'chat' | 'social' | 'linkedin';

/** communications.status (matches the DB CHECK constraint). */
export type CommunicationStatus =
  | 'draft'
  | 'queued'
  | 'sending'
  | 'sent'
  | 'delivered'
  | 'bounced'
  | 'failed'
  | 'received'
  | 'archived';

export type AiProcessingStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed'
  | 'skipped';

/* ============================================================
 * 2. URM custom headers (X-URM-*)
 * ----------------------------------------------------------
 * Attached on send, recovered on receive, used as the top priority for thread matching.
 * In case TABS Mailer 4 does not pass headers through,
 * a Message-ID/In-Reply-To-based fallback is provided (mailcarrier module).
 * ============================================================ */
export interface UrmHeaders {
  /** Engagement UUID. Top priority for thread/receive matching. */
  engagementId?: string;
  /** Outbound communications row UUID. 1:1 thread match on reply. */
  communicationId?: string;
  /** Whether it passed the auto-send gate (true/false). */
  autoSend?: boolean;
  /** UUID of the brand_voice row used (for the learning loop). */
  brandVoiceId?: string;
}

/** X-URM-* header name constants (always use lowercase for case-insensitive comparison). */
export const URM_HEADER_NAMES = {
  engagementId: 'x-urm-engagement-id',
  communicationId: 'x-urm-communication-id',
  autoSend: 'x-urm-auto-send',
  brandVoiceId: 'x-urm-brand-voice-id',
} as const;

/* ============================================================
 * 3. Attachment I/O
 * ============================================================ */

export interface AttachmentInput {
  filename: string;
  content: Buffer;
  contentType?: string;
}

export interface AttachmentRow {
  id: string;
  organizationId: string;
  entityType: 'communication' | 'meeting' | 'task' | 'party' | 'engagement' | 'consultation';
  entityId: string;
  fileName: string;
  fileSizeBytes: number;
  mimeType: string;
  storageProvider: 'supabase' | 's3' | 'external_url';
  storageBucket?: string;
  storagePath: string;
  contentHashSha256?: string;
  isInline: boolean;
  isQuarantined: boolean;
  virusScanStatus?: 'pending' | 'clean' | 'infected' | 'skipped' | 'failed';
  description?: string;
  uploadedBy?: string;
  uploadedAt: string;
  expiresAt?: string;
}

/* ============================================================
 * 4. communications row (camelCase domain object)
 * ============================================================ */

export interface CommunicationRow {
  id: string;
  organizationId: string;
  partyId?: string;
  contactId?: string;
  engagementId?: string;
  partyType?: PartyTypeCode;
  channel: Channel;
  direction: Direction;
  // RFC 5322
  messageId?: string;
  inReplyTo?: string;
  threadId?: string;
  // send/receive
  fromAddress?: string;
  fromName?: string;
  toAddresses: string[];
  ccAddresses: string[];
  bccAddresses: string[];
  replyToAddress?: string;
  // body
  subject?: string;
  bodyHtml?: string;
  bodyPlain?: string;
  bodySummary?: string;
  // language
  languageDetected?: 'ko' | 'en' | 'ja' | 'zh-CN' | 'other';
  // status
  status: CommunicationStatus;
  // timestamps
  occurredAt: string;
  sentAt?: string;
  deliveredAt?: string;
  receivedAt?: string;
  openedAt?: string;
  clickedAt?: string;
  repliedAt?: string;
  bouncedAt?: string;
  bounceReason?: string;
  // AI
  aiClassification?: Record<string, unknown>;
  aiDraftId?: string;
  aiGenerated: boolean;
  aiProcessingStatus?: AiProcessingStatus;
  // template
  templateId?: string;
  templateVariables?: Record<string, unknown>;
  // external
  externalData: Record<string, unknown>;
  // meta
  sentByUserId?: string;
  isStarred: boolean;
  isImportant: boolean;
  notes?: string;
}

/* ============================================================
 * 5. Parsed incoming mail
 * ============================================================ */

/** Our domain headers extracted from mailparser ParsedMail. */
export interface ParsedHeaders {
  messageId: string;
  inReplyTo?: string;
  references: string[];
  from: { name?: string; address: string };
  to: Array<{ name?: string; address: string }>;
  cc?: Array<{ name?: string; address: string }>;
  replyTo?: string;
  subject: string;
  date: Date;
  urmHeaders: UrmHeaders;
  /** Some raw headers (for debugging/reprocessing). */
  rawSelectedHeaders?: Record<string, string>;
}

/** Message that mailcarrier passes to processor.ts after the communications INSERT. */
export interface InboundMessageEvent {
  communicationId: string;
  organizationId: string;
  threadId: string;
  messageId: string;
  /** Pre-masked body (so processor does not need to mask again). */
  bodyText: string;
  /** Masked PII categories (for statistics). */
  piiCategories: string[];
  /** Excerpt of ParsedHeaders (for party matching). */
  fromAddress: string;
}

/* ============================================================
 * 6. Send input
 * ============================================================ */

export interface MailRecipient {
  name?: string;
  address: string;
}

/**
 * Sender-address kind. Chosen by the user on reply.
 * - personal: personal email (e.g. yunyoung.heo@marinebiogroup.com)
 * - role:     role email (e.g. ceo@marinebiogroup.com)
 * - shared:   shared/team email (e.g. contact@marinebiogroup.com)
 */
export type SendingAddressKind = 'personal' | 'role' | 'shared';

/**
 * Multi-Account Mail Hub Step 3 (2026-06-12).
 * Per-account SMTP override resolved from app.inbound_mailboxes.
 * When set on SendOneInput, takes precedence over sendingAddressKind/env
 * (transporter, From address and From display name all come from the account).
 */
export interface SmtpAccountConfig {
  /** app.inbound_mailboxes.id - transporter cache key + logs */
  accountId: string;
  /** account address; becomes the effective From (SPF/DKIM consistency) */
  address: string;
  displayName?: string | null;
  host: string;
  port: number;
  /** false on 587 means no STARTTLS (plain) - matches current infra */
  useTls: boolean;
  username: string;
  /** decrypted plaintext password - never persisted, never logged */
  password: string;
  /** 'login' (default) forces AUTH LOGIN; any other value lets nodemailer negotiate */
  authMethod?: string | null;
}

export interface SendOneInput {
  to: MailRecipient;
  cc?: MailRecipient[];
  bcc?: MailRecipient[];
  fromName: string;
  fromAddress: string;
  replyTo?: string;
  /** RFC 5322 In-Reply-To header (reply threading). */
  inReplyTo?: string;
  /** RFC 5322 References header chain (reply threading). */
  references?: string[];
  subject: string;
  bodyText: string;
  bodyHtml?: string;
  /** X-URM-* headers to attach. Only communicationId is required. */
  urmHeaders: Required<Pick<UrmHeaders, 'communicationId'>> &
    Omit<UrmHeaders, 'communicationId'> & { autoSend: boolean };
  attachments?: AttachmentInput[];
  /** Bypass quiet hours validation (for tests / operator manual send). */
  bypassQuietHours?: boolean;
  /** Quiet hours to apply (if unset, no validation). */
  quietHours?: QuietHours;
  /** Label for tracing (logs / ai.runs trace_label). */
  traceLabel?: string;
  /** Which SMTP credentials kind to use. If unset, uses the existing single transporter (backward compat). */
  sendingAddressKind?: SendingAddressKind;
  /** Multi-Account Step 3: per-account SMTP override. Wins over sendingAddressKind/env when set. */
  smtpAccount?: SmtpAccountConfig;
}

export interface SendOneOutput {
  /** RFC 5322 Message-ID. */
  messageId: string;
  acceptedRecipients: string[];
  rejectedRecipients: string[];
  rawResponse: string;
  /** Send time (server response time). */
  sentAt: string;
}

/* ============================================================
 * 7. Campaign (bulk send)
 * ============================================================ */

export interface CampaignParams {
  name: string;
  description?: string;
  templateId: string;
  scheduledAt?: Date;
  recipientCount: number;
  fromAddress: string;
  fromName?: string;
  replyToAddress?: string;
}

export interface CampaignCreateResult {
  tabsCampaignId: string;
  status: string;
}

export interface TabsCampaignStats {
  tabsCampaignId: string;
  totalSent: number;
  totalDelivered: number;
  totalOpened: number;
  totalClicked: number;
  totalBounced: number;
  totalUnsubscribed: number;
  totalFailed: number;
  totalReplied: number;
  lastUpdatedAt: Date;
}

/* ============================================================
 * 8. Quiet hours
 * ============================================================ */

export interface QuietHours {
  /** IANA timezone (e.g. "Asia/Seoul", "America/New_York"). */
  timezone: string;
  /** "HH:mm" 24h. Supports crossing midnight (22:00 -> 08:00). */
  start: string;
  /** "HH:mm" 24h. */
  end: string;
  /** Whether to block Sat/Sun. */
  weekends_blocked: boolean;
}

/* ============================================================
 * 9. mail_merge_jobs row
 * ============================================================ */

export type MailMergeJobStatus =
  | 'draft'
  | 'queued'
  | 'running'
  | 'paused'
  | 'completed'
  | 'cancelled'
  | 'failed';

export interface MailMergeProgress {
  sent: number;
  failed: number;
  opened: number;
  clicked: number;
  replied: number;
  bounced: number;
  unsubscribed?: number;
}

export interface MailMergeJobRow {
  id: string;
  organizationId: string;
  name: string;
  description?: string;
  templateId: string;
  templateVersionId?: string;
  abTestId?: string;
  recipientFilter: Record<string, unknown>;
  recipientPartyIds: string[];
  recipientContactIds: string[];
  estimatedRecipientCount?: number;
  fromAddress: string;
  fromName?: string;
  replyToAddress?: string;
  scheduledAt?: string;
  rateLimitPerHour: number;
  rateLimitPerMinute: number;
  quietHours: QuietHours;
  tabsCampaignId?: string;
  tabsCampaignStatus?: string;
  tabsCampaignSyncedAt?: string;
  status: MailMergeJobStatus;
  progress: MailMergeProgress;
  startedAt?: string;
  completedAt?: string;
  errorMessage?: string;
  /** Next time the worker will apply the retry backoff. */
  nextSendAt?: string;
  retryCount: number;
  maxRetries: number;
  requiresLegalApproval: boolean;
  legalApprovedAt?: string;
  legalApprovedBy?: string;
}

/* ============================================================
 * 10. DB row -> domain object mapper (mail_merge_jobs)
 * ============================================================ */

export function mapMailMergeJobRow(row: Record<string, unknown>): MailMergeJobRow {
  const progress = (row.progress ?? {}) as Record<string, unknown>;
  const quietHoursRaw = (row.quiet_hours ?? {}) as Record<string, unknown>;

  return {
    id: row.id as string,
    organizationId: row.organization_id as string,
    name: row.name as string,
    description: (row.description as string | null) ?? undefined,
    templateId: row.template_id as string,
    templateVersionId: (row.template_version_id as string | null) ?? undefined,
    abTestId: (row.ab_test_id as string | null) ?? undefined,
    recipientFilter: (row.recipient_filter ?? {}) as Record<string, unknown>,
    recipientPartyIds: (row.recipient_party_ids ?? []) as string[],
    recipientContactIds: (row.recipient_contact_ids ?? []) as string[],
    estimatedRecipientCount:
      (row.estimated_recipient_count as number | null) ?? undefined,
    fromAddress: row.from_address as string,
    fromName: (row.from_name as string | null) ?? undefined,
    replyToAddress: (row.reply_to_address as string | null) ?? undefined,
    scheduledAt: (row.scheduled_at as string | null) ?? undefined,
    rateLimitPerHour: Number(row.rate_limit_per_hour ?? 100),
    rateLimitPerMinute: Number(row.rate_limit_per_minute ?? 5),
    quietHours: {
      timezone: String(quietHoursRaw.timezone ?? 'Asia/Seoul'),
      start: String(quietHoursRaw.start ?? '22:00'),
      end: String(quietHoursRaw.end ?? '08:00'),
      weekends_blocked: Boolean(quietHoursRaw.weekends_blocked ?? true),
    },
    tabsCampaignId: (row.tabs_campaign_id as string | null) ?? undefined,
    tabsCampaignStatus:
      (row.tabs_campaign_status as string | null) ?? undefined,
    tabsCampaignSyncedAt:
      (row.tabs_campaign_synced_at as string | null) ?? undefined,
    status: row.status as MailMergeJobStatus,
    progress: {
      sent: Number(progress.sent ?? 0),
      failed: Number(progress.failed ?? 0),
      opened: Number(progress.opened ?? 0),
      clicked: Number(progress.clicked ?? 0),
      replied: Number(progress.replied ?? 0),
      bounced: Number(progress.bounced ?? 0),
      unsubscribed:
        progress.unsubscribed !== undefined
          ? Number(progress.unsubscribed)
          : undefined,
    },
    startedAt: (row.started_at as string | null) ?? undefined,
    completedAt: (row.completed_at as string | null) ?? undefined,
    errorMessage: (row.error_message as string | null) ?? undefined,
    nextSendAt: (row.next_send_at as string | null) ?? undefined,
    retryCount: Number(row.retry_count ?? 0),
    maxRetries: Number(row.max_retries ?? 3),
    requiresLegalApproval: Boolean(row.requires_legal_approval ?? false),
    legalApprovedAt: (row.legal_approved_at as string | null) ?? undefined,
    legalApprovedBy: (row.legal_approved_by as string | null) ?? undefined,
  };
}

/* ============================================================
 * 11. Reply-language decision helper
 * ----------------------------------------------------------
 * Codifies the priority rules from master §8.2.
 *   1. contacts.preferred_language
 *   2. communications.language_detected
 *   3. parties.country default language
 *   4. organization default language
 * ============================================================ */
export function resolveReplyLanguage(input: {
  contactPreferred?: string;
  detectedFromInbound?: string;
  partyCountryCode?: string;
  organizationDefault?: Language;
}): Language {
  const contact = input.contactPreferred?.toLowerCase();
  if (contact === 'ko' || contact === 'en' || contact === 'ja') return contact;

  const detected = input.detectedFromInbound?.toLowerCase();
  if (detected === 'ko' || detected === 'en' || detected === 'ja') return detected;

  const country = (input.partyCountryCode ?? '').toUpperCase();
  if (country === 'KR') return 'ko';
  if (country === 'JP') return 'ja';
  if (country) return 'en'; // other countries default to English

  return input.organizationDefault ?? 'en';
}
