import type { SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';
import { ClaudeClient } from '@/lib/ai/claude-client';
import {
  STANDARD_CATEGORIES,
  RISK_FLAGS,
  normalizeClassification,
  sanitizeRiskFlags,
  type ClassificationOutput,
  type StandardCategory,
  type RiskFlag,
} from '@/types/classification';
import {
  toCommunicationRow,
  type CommunicationRow,
} from '@/types/email';
import type { ReplyDrafterOutput, DraftInsertPayload } from '@/types/ai';
import { evaluateAutoSend } from './auto-send-gate';

// ───────────────────────────────────────────────────────────────────
// 에러
// ───────────────────────────────────────────────────────────────────

export class ProcessorError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'ProcessorError';
  }
}

// ───────────────────────────────────────────────────────────────────
// 입출력
// ───────────────────────────────────────────────────────────────────

export interface ProcessInboundOptions {
  force?: boolean;
  generateEmbedding?: (text: string) => Promise<number[]>;
}

export interface ProcessInboundResult {
  status: 'processed' | 'skipped' | 'failed';
  reason?: string;
  draftId?: string;
  classifierRunId?: string;
  replyDrafterRunId?: string;
  autoSendAllowed?: boolean;
  blockedReasons?: string[];
}

// ───────────────────────────────────────────────────────────────────
// processInbound
// ───────────────────────────────────────────────────────────────────

export async function processInbound(
  supabase: SupabaseClient,
  organizationId: string,
  communicationId: string,
  options: ProcessInboundOptions = {},
): Promise<ProcessInboundResult> {
  // [1] communications 조회
  const comm = await loadCommunication(supabase, organizationId, communicationId);
  if (!comm) {
    return { status: 'skipped', reason: 'communication_not_found' };
  }
  if (comm.direction !== 'inbound') {
    return { status: 'skipped', reason: 'not_inbound' };
  }
  if (
    !options.force
    && (comm.aiProcessingStatus === 'processed' || comm.aiProcessingStatus === 'failed')
  ) {
    return { status: 'skipped', reason: `already_${comm.aiProcessingStatus}` };
  }

  // [2] processing 락
  await updateProcessingStatus(supabase, communicationId, 'processing');

  const claudeClient = new ClaudeClient(
    supabase,
    organizationId,
    options.generateEmbedding,
  );

  let classification: ClassificationOutput;
  let classifierRunId = '';
  let replyDrafter: ReplyDrafterOutput;
  let replyDrafterRunId = '';

  try {
    // [3] 분류기
    const classifierResult = await claudeClient.complete({
      agentRole: 'classifier',
      partyId: comm.partyId,
      engagementId: comm.engagementId,
      module: comm.module,
      language: mapLanguage(comm.languageDetected),
      inboundMessage: buildInboundContext(comm),
      outputFormat: 'json',
      caller: 'processor:classifier',
    });
    classifierRunId = classifierResult.runId;

    classification = normalizeClassification(classifierResult.parsedJson);

    if (!STANDARD_CATEGORIES.includes(classification.category)) {
      throw new ProcessorError(
        `Classifier produced non-standard category despite normalization: ${classification.category}`,
      );
    }
  } catch (err) {
    await updateProcessingStatus(supabase, communicationId, 'failed', {
      reason: 'classifier_failed',
      message: (err as Error).message,
    });
    return {
      status: 'failed',
      reason: 'classifier_failed',
      classifierRunId,
    };
  }

  // [4] 회신 초안
  try {
    const replyResult = await claudeClient.complete({
      agentRole: 'reply_drafter',
      partyId: comm.partyId,
      engagementId: comm.engagementId,
      module: comm.module,
      language: mapDrafterLanguage(classification.detectedLanguage),
      inboundMessage: buildInboundContext(comm),
      outputFormat: 'json',
      caller: 'processor:reply_drafter',
    });
    replyDrafterRunId = replyResult.runId;

    replyDrafter = parseReplyDrafterOutput(
      replyResult.parsedJson,
      replyResult.content,
      classification,
    );
  } catch (err) {
    await updateProcessingStatus(supabase, communicationId, 'failed', {
      reason: 'reply_drafter_failed',
      message: (err as Error).message,
    });
    return {
      status: 'failed',
      reason: 'reply_drafter_failed',
      classifierRunId,
      replyDrafterRunId,
    };
  }

  // [5] 자동발송 게이트
  const gate = await evaluateAutoSend(supabase, {
    organizationId,
    partyId: comm.partyId,
    module: comm.module,
    classification,
    draftBody: replyDrafter.bodyPlain,
    draftRequiresHuman: replyDrafter.requiresHumanApproval,
    draftRiskFlags: replyDrafter.riskFlags,
  });

  // [6] ai.drafts INSERT
  const expiresAt = new Date(
    Date.now() + env.DRAFT_EXPIRY_DAYS * 24 * 60 * 60 * 1000,
  ).toISOString();

  const draftPayload: DraftInsertPayload = {
    organizationId,
    communicationId,
    partyId: comm.partyId,
    engagementId: comm.engagementId,
    module: comm.module,
    language: replyDrafter.language,
    classificationCategory: replyDrafter.classificationCategory,
    subject: replyDrafter.subject,
    bodyPlain: replyDrafter.bodyPlain,
    bodyHtml: replyDrafter.bodyHtml,
    rationale: replyDrafter.rationale,
    riskFlags: replyDrafter.riskFlags,
    requiresHumanApproval:
      replyDrafter.requiresHumanApproval
      || !gate.allowed
      || classification.requiresHuman,
    autoSendEligible: gate.allowed,
    autoSendBlockedReasons: gate.reasons,
    classifierRunId,
    replyDrafterRunId,
    expiresAt,
  };

  const draftId = await insertDraft(supabase, draftPayload, classification, gate.evaluationLog);

  await supabase
    .schema('app')
    .from('communications')
    .update({
      ai_draft_id: draftId,
      ai_classification: classification,
      ai_processing_status: 'processed',
      language_detected: mapLanguageToDb(classification.detectedLanguage, comm.languageDetected),
    })
    .eq('id', communicationId);

  return {
    status: 'processed',
    draftId,
    classifierRunId,
    replyDrafterRunId,
    autoSendAllowed: gate.allowed,
    blockedReasons: gate.reasons,
  };
}

// ───────────────────────────────────────────────────────────────────
// 내부
// ───────────────────────────────────────────────────────────────────

async function loadCommunication(
  supabase: SupabaseClient,
  organizationId: string,
  communicationId: string,
): Promise<CommunicationRow | null> {
  const { data, error } = await supabase
    .schema('app')
    .from('communications')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('id', communicationId)
    .is('deleted_at', null)
    .maybeSingle();

  if (error || !data) return null;
  return toCommunicationRow(data as Record<string, unknown>);
}

async function updateProcessingStatus(
  supabase: SupabaseClient,
  communicationId: string,
  status: 'processing' | 'processed' | 'failed' | 'skipped',
  errorMeta?: { reason: string; message: string },
): Promise<void> {
  const update: Record<string, unknown> = { ai_processing_status: status };
  if (errorMeta) {
    update.ai_classification = {
      error: errorMeta.reason,
      message: errorMeta.message,
    };
  }
  await supabase
    .schema('app')
    .from('communications')
    .update(update)
    .eq('id', communicationId);
}

function buildInboundContext(comm: CommunicationRow): string {
  const parts: string[] = [];
  parts.push(`From: ${comm.fromName ? `${comm.fromName} <${comm.fromAddress ?? ''}>` : comm.fromAddress ?? ''}`);
  parts.push(`To: ${comm.toAddresses.join(', ')}`);
  if (comm.ccAddresses.length > 0) {
    parts.push(`Cc: ${comm.ccAddresses.join(', ')}`);
  }
  parts.push(`Subject: ${comm.subject ?? '(no subject)'}`);
  parts.push(`Date: ${comm.occurredAt}`);
  parts.push('');
  parts.push(comm.bodyPlain ?? '');
  return parts.join('\n');
}

function mapLanguage(
  raw: CommunicationRow['languageDetected'],
): 'ko' | 'en' | 'ja' | undefined {
  if (raw === 'ko' || raw === 'en' || raw === 'ja') return raw;
  return undefined;
}

function mapDrafterLanguage(
  detected: ClassificationOutput['detectedLanguage'],
): 'ko' | 'en' | 'ja' {
  if (detected === 'ko' || detected === 'en' || detected === 'ja') return detected;
  return 'en';
}

function mapLanguageToDb(
  classifierDetected: ClassificationOutput['detectedLanguage'],
  prior: CommunicationRow['languageDetected'],
): CommunicationRow['languageDetected'] {
  if (classifierDetected === 'ko' || classifierDetected === 'en'
      || classifierDetected === 'ja') {
    return classifierDetected;
  }
  if (classifierDetected === 'zh') return 'zh-CN';
  if (classifierDetected === 'other') return 'other';
  return prior;
}

function parseReplyDrafterOutput(
  parsed: object | undefined,
  rawContent: string,
  classification: ClassificationOutput,
): ReplyDrafterOutput {
  if (!parsed || typeof parsed !== 'object') {
    throw new ProcessorError('Reply drafter returned non-JSON response');
  }
  const r = parsed as Record<string, unknown>;

  const subject = typeof r.subject === 'string' ? r.subject : '';
  const bodyPlain =
    typeof r.bodyPlain === 'string'
      ? r.bodyPlain
      : typeof r.body_plain === 'string'
        ? r.body_plain
        : typeof r.body === 'string'
          ? r.body
          : rawContent;
  const bodyHtml =
    typeof r.bodyHtml === 'string'
      ? r.bodyHtml
      : typeof r.body_html === 'string'
        ? r.body_html
        : undefined;

  if (!subject || !bodyPlain) {
    throw new ProcessorError(
      'Reply drafter missing required fields (subject or bodyPlain)',
    );
  }

  let category: StandardCategory = classification.category;
  const drafterCat = typeof r.classificationCategory === 'string'
    ? r.classificationCategory
    : typeof r.classification_category === 'string'
      ? r.classification_category
      : undefined;
  if (drafterCat && (STANDARD_CATEGORIES as readonly string[]).includes(drafterCat)) {
    category = drafterCat as StandardCategory;
  }

  const drafterRisk = sanitizeRiskFlags(r.riskFlags ?? r.risk_flags);
  const allFlags = new Set<RiskFlag>([...drafterRisk, ...classification.riskFlags]);
  const finalFlags = Array.from(allFlags).filter(
    (f) => (RISK_FLAGS as readonly string[]).includes(f),
  );

  let language: 'ko' | 'en' | 'ja' = 'en';
  if (r.language === 'ko' || r.language === 'en' || r.language === 'ja') {
    language = r.language;
  } else if (
    classification.detectedLanguage === 'ko'
    || classification.detectedLanguage === 'en'
    || classification.detectedLanguage === 'ja'
  ) {
    language = classification.detectedLanguage;
  }

  const requiresHumanApproval =
    r.requiresHumanApproval === true
    || r.requires_human_approval === true
    || classification.requiresHuman;

  return {
    subject,
    bodyPlain,
    bodyHtml,
    rationale: typeof r.rationale === 'string' ? r.rationale : '',
    riskFlags: finalFlags,
    requiresHumanApproval,
    language,
    classificationCategory: category,
  };
}

async function insertDraft(
  supabase: SupabaseClient,
  payload: DraftInsertPayload,
  classification: ClassificationOutput,
  gateLog: Record<string, unknown>,
): Promise<string> {
  const { data, error } = await supabase
    .schema('ai')
    .from('drafts')
    .insert({
      organization_id: payload.organizationId,
      communication_id: payload.communicationId,
      party_id: payload.partyId ?? null,
      engagement_id: payload.engagementId ?? null,
      module: payload.module ?? null,
      language: payload.language,
      classification_category: payload.classificationCategory,
      subject: payload.subject,
      body_plain: payload.bodyPlain,
      body_html: payload.bodyHtml ?? null,
      rationale: payload.rationale,
      risk_flags: payload.riskFlags,
      requires_human_approval: payload.requiresHumanApproval,
      auto_send_eligible: payload.autoSendEligible,
      auto_send_blocked_reasons: payload.autoSendBlockedReasons,
      classifier_run_id: payload.classifierRunId,
      reply_drafter_run_id: payload.replyDrafterRunId,
      expires_at: payload.expiresAt,
      status: 'pending',
      ai_generated: true,
      classification_snapshot: classification,
      gate_evaluation_log: gateLog,
    })
    .select('id')
    .single();

  if (error || !data) {
    throw new ProcessorError(
      `ai.drafts INSERT failed: ${error?.message ?? 'no data'}`,
    );
  }
  return String((data as { id: string }).id);
}
