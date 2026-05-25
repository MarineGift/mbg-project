/**
 * types/email.ts
 *
 * 이메일 통신 도메인 객체 타입.
 *
 * 다루는 영역:
 *   - app.communications 행 (CommunicationRow)
 *   - app.attachments 행 (AttachmentRow)
 *   - 수신 메일 파싱 결과 (ParsedHeaders, ParsedInbound)
 *   - URM 자체 헤더 (UrmHeaders, X-URM-* 4종)
 *   - 발송 입력 (SendOneInput, CampaignParams)
 *   - 발송 통계 (TabsCampaignStats)
 *   - 대량발송 잡 (MailMergeJobRow, QuietHours)
 *   - 스레드 매칭 결과
 */

import type { PartyTypeCode, Language } from './ai';

/* ============================================================
 * 1. 채널·방향 enum
 * ============================================================ */

export type Direction = 'inbound' | 'outbound';
export type Channel = 'email' | 'phone' | 'meeting' | 'note' | 'chat' | 'social' | 'linkedin';

/** communications.status (DB CHECK 제약과 일치). */
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
 * 2. URM 자체 헤더 (X-URM-*)
 * ----------------------------------------------------------
 * 발송 시 부착, 수신 시 회수해 thread 매칭 1순위로 사용.
 * TABS Mailer 4가 헤더를 통과시키지 않을 가능성 대비
 * Message-ID·In-Reply-To 기반 fallback 제공 (mailcarrier 모듈).
 * ============================================================ */
export interface UrmHeaders {
  /** 인게이지먼트 UUID. 스레드·수신 매칭 1순위. */
  engagementId?: string;
  /** 발신 communications 행 UUID. 회신 시 thread 1:1 매칭. */
  communicationId?: string;
  /** 자동발송 게이트 통과 여부(true/false). */
  autoSend?: boolean;
  /** 사용된 brand_voice 행 UUID(학습 루프용). */
  brandVoiceId?: string;
}

/** X-URM-* 헤더 이름 상수 (대소문자 비교 시 항상 lowercase 사용). */
export const URM_HEADER_NAMES = {
  engagementId: 'x-urm-engagement-id',
  communicationId: 'x-urm-communication-id',
  autoSend: 'x-urm-auto-send',
  brandVoiceId: 'x-urm-brand-voice-id',
} as const;

/* ============================================================
 * 3. 첨부파일 입출력
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
 * 4. communications 행 (camelCase 도메인 객체)
 * ============================================================ */

export interface CommunicationRow {
  id: string;
  organizationId: string;
  partyId?: string;
  contactId?: string;
  engagementId?: string;
  module?: PartyTypeCode;
  channel: Channel;
  direction: Direction;
  // RFC 5322
  messageId?: string;
  inReplyTo?: string;
  threadId?: string;
  // 발신·수신
  fromAddress?: string;
  fromName?: string;
  toAddresses: string[];
  ccAddresses: string[];
  bccAddresses: string[];
  replyToAddress?: string;
  // 본문
  subject?: string;
  bodyHtml?: string;
  bodyPlain?: string;
  bodySummary?: string;
  // 언어
  languageDetected?: 'ko' | 'en' | 'ja' | 'zh-CN' | 'other';
  // 상태
  status: CommunicationStatus;
  // 타임스탬프
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
  // 템플릿
  templateId?: string;
  templateVariables?: Record<string, unknown>;
  // 외부
  externalData: Record<string, unknown>;
  // 메타
  sentByUserId?: string;
  isStarred: boolean;
  isImportant: boolean;
  notes?: string;
}

/* ============================================================
 * 5. 수신 메일 파싱 결과
 * ============================================================ */

/** mailparser ParsedMail에서 추출한 우리 도메인 헤더. */
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
  /** 원본 헤더 일부 (디버깅·재처리용). */
  rawSelectedHeaders?: Record<string, string>;
}

/** mailcarrier가 communications INSERT 후 processor.ts에 전달하는 메시지. */
export interface InboundMessageEvent {
  communicationId: string;
  organizationId: string;
  threadId: string;
  messageId: string;
  /** 사전 마스킹된 본문(processor가 다시 마스킹할 필요 없게). */
  bodyText: string;
  /** 마스킹된 PII 카테고리(통계용). */
  piiCategories: string[];
  /** ParsedHeaders 일부 발췌 (party 매칭용). */
  fromAddress: string;
}

/* ============================================================
 * 6. 발송 입력
 * ============================================================ */

export interface MailRecipient {
  name?: string;
  address: string;
}

/**
 * 발신 주소 종류. 사용자가 회신 시 선택.
 * - personal: 개인 메일 (예: yunyoung.heo@marinebiogroup.com)
 * - role:     직책 메일 (예: ceo@marinebiogroup.com)
 * - shared:   공통/팀 메일 (예: contact@marinebiogroup.com)
 */
export type SendingAddressKind = 'personal' | 'role' | 'shared';

export interface SendOneInput {
  to: MailRecipient;
  cc?: MailRecipient[];
  bcc?: MailRecipient[];
  fromName: string;
  fromAddress: string;
  replyTo?: string;
  subject: string;
  bodyText: string;
  bodyHtml?: string;
  /** 부착할 X-URM-* 헤더. communicationId만 필수. */
  urmHeaders: Required<Pick<UrmHeaders, 'communicationId'>> &
    Omit<UrmHeaders, 'communicationId'> & { autoSend: boolean };
  attachments?: AttachmentInput[];
  /** quiet hours 검증 우회(테스트·운영자 수동 발송용). */
  bypassQuietHours?: boolean;
  /** 적용할 quiet hours(미지정 시 검증 안 함). */
  quietHours?: QuietHours;
  /** 추적용 라벨(로그·ai.runs trace_label). */
  traceLabel?: string;
  /** 사용할 SMTP 자격증명 종류. 미지정 시 기존 단일 transporter 사용(하위호환). */
  sendingAddressKind?: SendingAddressKind;
}

export interface SendOneOutput {
  /** RFC 5322 Message-ID. */
  messageId: string;
  acceptedRecipients: string[];
  rejectedRecipients: string[];
  rawResponse: string;
  /** 발송 시각(서버 응답 시각). */
  sentAt: string;
}

/* ============================================================
 * 7. 캠페인 (대량발송)
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
  /** IANA 타임존 (예: "Asia/Seoul", "America/New_York"). */
  timezone: string;
  /** "HH:mm" 24h. 자정을 넘는 경우(22:00 → 08:00) 지원. */
  start: string;
  /** "HH:mm" 24h. */
  end: string;
  /** 토·일 차단 여부. */
  weekends_blocked: boolean;
}

/* ============================================================
 * 9. mail_merge_jobs 행
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
  /** 워커가 재시도 백오프를 적용할 다음 시각. */
  nextSendAt?: string;
  retryCount: number;
  maxRetries: number;
  requiresLegalApproval: boolean;
  legalApprovedAt?: string;
  legalApprovedBy?: string;
}

/* ============================================================
 * 10. DB row → 도메인 객체 매퍼 (mail_merge_jobs)
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
 * 11. 회신 언어 결정 헬퍼
 * ----------------------------------------------------------
 * 마스터 §8.2의 우선순위 규칙을 코드화.
 *   1. contacts.preferred_language
 *   2. communications.language_detected
 *   3. parties.country 기본 언어
 *   4. 조직 기본 언어
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
  if (country) return 'en'; // 그 외 국가는 영어로

  return input.organizationDefault ?? 'en';
}
