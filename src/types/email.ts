import type { ClassificationOutput, StandardCategory } from './classification';

// ───────────────────────────────────────────────────────────────────
// 1. 핵심 ENUM
// ───────────────────────────────────────────────────────────────────

export type Direction = 'inbound' | 'outbound';
export type Channel = 'email' | 'phone' | 'meeting' | 'note' | 'chat' | 'social';

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

export type DetectedLanguage = 'ko' | 'en' | 'ja' | 'zh-CN' | 'other';

export type ModuleType =
  | 'investor'
  | 'buyer'
  | 'partner'
  | 'customer'
  | 'crowdfunding'
  | 'product_launch'
  | 'sales';

// ───────────────────────────────────────────────────────────────────
// 2. app.communications
// ───────────────────────────────────────────────────────────────────

export interface EmailAddress {
  name?: string;
  address: string;
}

export interface CommunicationRow {
  id: string;
  organizationId: string;
  partyId?: string;
  contactId?: string;
  engagementId?: string;
  module?: ModuleType;

  channel: Channel;
  direction: Direction;

  messageId?: string;
  inReplyTo?: string;
  threadId?: string;

  fromAddress?: string;
  fromName?: string;
  toAddresses: string[];
  ccAddresses: string[];
  bccAddresses: string[];
  replyToAddress?: string;

  subject?: string;
  bodyHtml?: string;
  bodyPlain?: string;
  bodySummary?: string;

  languageDetected?: DetectedLanguage;
  status: CommunicationStatus;

  occurredAt: string;
  sentAt?: string;
  deliveredAt?: string;
  receivedAt?: string;
  openedAt?: string;
  clickedAt?: string;
  repliedAt?: string;
  bouncedAt?: string;
  bounceReason?: string;

  aiClassification?: ClassificationOutput;
  aiDraftId?: string;
  aiGenerated: boolean;
  aiProcessingStatus?: 'pending' | 'processing' | 'processed' | 'failed' | 'skipped';

  templateId?: string;
  templateVariables: Record<string, unknown>;

  externalData: Record<string, unknown>;

  sentByUserId?: string;

  piiMasked?: boolean;
  piiCategoriesDetected?: string[];

  isStarred: boolean;
  isImportant: boolean;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  createdBy?: string;
  updatedBy?: string;
  deletedAt?: string;
}

export function toCommunicationRow(dbRow: Record<string, unknown>): CommunicationRow {
  const r = dbRow;
  return {
    id: String(r.id),
    organizationId: String(r.organization_id),
    partyId: optStr(r.party_id),
    contactId: optStr(r.contact_id),
    engagementId: optStr(r.engagement_id),
    module: optStr(r.module) as ModuleType | undefined,

    channel: r.channel as Channel,
    direction: r.direction as Direction,

    messageId: optStr(r.message_id),
    inReplyTo: optStr(r.in_reply_to),
    threadId: optStr(r.thread_id),

    fromAddress: optStr(r.from_address),
    fromName: optStr(r.from_name),
    toAddresses: Array.isArray(r.to_addresses) ? (r.to_addresses as string[]) : [],
    ccAddresses: Array.isArray(r.cc_addresses) ? (r.cc_addresses as string[]) : [],
    bccAddresses: Array.isArray(r.bcc_addresses) ? (r.bcc_addresses as string[]) : [],
    replyToAddress: optStr(r.reply_to_address),

    subject: optStr(r.subject),
    bodyHtml: optStr(r.body_html),
    bodyPlain: optStr(r.body_plain),
    bodySummary: optStr(r.body_summary),

    languageDetected: optStr(r.language_detected) as DetectedLanguage | undefined,
    status: (r.status as CommunicationStatus) ?? 'received',

    occurredAt: String(r.occurred_at),
    sentAt: optStr(r.sent_at),
    deliveredAt: optStr(r.delivered_at),
    receivedAt: optStr(r.received_at),
    openedAt: optStr(r.opened_at),
    clickedAt: optStr(r.clicked_at),
    repliedAt: optStr(r.replied_at),
    bouncedAt: optStr(r.bounced_at),
    bounceReason: optStr(r.bounce_reason),

    aiClassification: (r.ai_classification as ClassificationOutput) ?? undefined,
    aiDraftId: optStr(r.ai_draft_id),
    aiGenerated: r.ai_generated === true,
    aiProcessingStatus: optStr(r.ai_processing_status) as
      | CommunicationRow['aiProcessingStatus']
      | undefined,

    templateId: optStr(r.template_id),
    templateVariables:
      (r.template_variables as Record<string, unknown> | null) ?? {},

    externalData: (r.external_data as Record<string, unknown> | null) ?? {},

    sentByUserId: optStr(r.sent_by_user_id),

    piiMasked: typeof r.pii_masked === 'boolean' ? r.pii_masked : undefined,
    piiCategoriesDetected: Array.isArray(r.pii_categories_detected)
      ? (r.pii_categories_detected as string[])
      : undefined,

    isStarred: r.is_starred === true,
    isImportant: r.is_important === true,
    notes: optStr(r.notes),
    createdAt: String(r.created_at),
    updatedAt: String(r.updated_at),
    createdBy: optStr(r.created_by),
    updatedBy: optStr(r.updated_by),
    deletedAt: optStr(r.deleted_at),
  };
}

// ───────────────────────────────────────────────────────────────────
// 3. app.attachments
// ───────────────────────────────────────────────────────────────────

export type AttachmentEntityType =
  | 'communication'
  | 'meeting'
  | 'task'
  | 'party'
  | 'engagement'
  | 'consultation';

export interface AttachmentRow {
  id: string;
  organizationId: string;
  entityType: AttachmentEntityType;
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
  deletedAt?: string;
}

export function toAttachmentRow(dbRow: Record<string, unknown>): AttachmentRow {
  const r = dbRow;
  return {
    id: String(r.id),
    organizationId: String(r.organization_id),
    entityType: r.entity_type as AttachmentEntityType,
    entityId: String(r.entity_id),
    fileName: String(r.file_name),
    fileSizeBytes: Number(r.file_size_bytes ?? 0),
    mimeType: String(r.mime_type),
    storageProvider:
      (r.storage_provider as AttachmentRow['storageProvider']) ?? 'supabase',
    storageBucket: optStr(r.storage_bucket),
    storagePath: String(r.storage_path),
    contentHashSha256: optStr(r.content_hash_sha256),
    isInline: r.is_inline === true,
    isQuarantined: r.is_quarantined === true,
    virusScanStatus: optStr(r.virus_scan_status) as AttachmentRow['virusScanStatus'],
    description: optStr(r.description),
    uploadedBy: optStr(r.uploaded_by),
    uploadedAt: String(r.uploaded_at),
    expiresAt: optStr(r.expires_at),
    deletedAt: optStr(r.deleted_at),
  };
}

// ───────────────────────────────────────────────────────────────────
// 4. URM 헤더
// ───────────────────────────────────────────────────────────────────

export interface UrmHeaders {
  communicationId: string;
  engagementId?: string;
  partyId?: string;
  brandVoiceId?: string;
  autoSend: boolean;
  threadId?: string;
}

// ───────────────────────────────────────────────────────────────────
// 5. TABS Mailer
// ───────────────────────────────────────────────────────────────────

export interface SendOneInput {
  to: EmailAddress | EmailAddress[];
  cc?: EmailAddress[];
  bcc?: EmailAddress[];
  from?: EmailAddress;
  replyTo?: EmailAddress;
  subject: string;
  text?: string;
  html?: string;
  inReplyTo?: string;
  references?: string[];
  messageId?: string;
  urmHeaders: UrmHeaders;
  attachments?: SendAttachment[];
  quietHours?: QuietHours;
  enforceQuietHours?: boolean;
}

export interface SendAttachment {
  filename: string;
  content: Buffer | string;
  contentType?: string;
  cid?: string;
}

export interface SendOneOutput {
  messageId: string;
  accepted: string[];
  rejected: string[];
  response: string;
  mocked: boolean;
}

export interface CreateCampaignInput {
  name: string;
  mergeJobId: string;
  fromAddress: string;
  fromName?: string;
  replyToAddress?: string;
  subjectTemplate: string;
  bodyHtmlTemplate?: string;
  bodyPlainTemplate?: string;
  recipients: CampaignRecipient[];
  scheduledAt?: string;
  rateLimitPerMinute?: number;
  rateLimitPerHour?: number;
  quietHours?: QuietHours;
  urmCampaignHeaders: Omit<UrmHeaders, 'communicationId'>;
}

export interface CampaignRecipient {
  partyId?: string;
  contactId?: string;
  communicationId: string;
  to: EmailAddress;
  variables: Record<string, string | number>;
}

export interface CreateCampaignOutput {
  tabsCampaignId: string;
  acceptedCount: number;
  rejectedCount: number;
  mocked: boolean;
}

export interface CampaignProgress {
  totalRecipients: number;
  totalSent: number;
  totalDelivered: number;
  totalOpened: number;
  totalClicked: number;
  totalBounced: number;
  totalFailed: number;
  upstreamStatus: 'pending' | 'running' | 'completed' | 'failed' | 'unknown';
  syncedAt: string;
}

export interface CampaignStats extends CampaignProgress {
  tabsCampaignId: string;
  startedAt?: string;
  completedAt?: string;
}

export interface QuietHours {
  timezone: string;
  start: string;
  end: string;
  daysOfWeek?: number[];
}

// ───────────────────────────────────────────────────────────────────
// 6. 헬퍼
// ───────────────────────────────────────────────────────────────────

function optStr(v: unknown): string | undefined {
  if (v === null || v === undefined) return undefined;
  return String(v);
}

export type { StandardCategory };
