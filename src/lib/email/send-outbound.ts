// src/lib/email/send-outbound.ts
//
// Stage B: single outbound send contract extracted from the runtime-verified
// dialog sendEmail() path. Three send sites (sendEmail / sendOutboundManual /
// sendApprovedDraft) become thin adapters over sendOutboundEmail().
//
// Contract (verified 8/8 in HANDOFF 7):
//   whitelist guard -> (optional) template+subject render -> signature
//   -> insert communications(status='sending') -> createEmailTracking(1a)
//   -> sendOne(inReplyTo/references/urmHeaders/attachments)
//   -> update(sent: message_id/thread_id/sent_at | failed: status+error_message)
//   -> attachments insert (app.attachments)
//
// NOTE: this is a plain server-side helper (NOT a 'use server' file). It is
// imported only by server action modules and runs server-side.

import type { SbClient } from '@/lib/supabase/server';
import type { SendingAddressKind, AttachmentInput } from '@/types/email';
import { createTabsMailer } from '@/lib/email/tabs-mailer';
import { createEmailTracking } from '@/lib/actions/email-tracking';
import { hasUnrestoredTokens, findUnrestoredTokens } from '@/lib/ai/pii-masker';

/* ============================================================
 * Input / Output
 * ============================================================ */

export interface OutboundAttachmentMeta {
  /** storage path inside the 'email-attachments' bucket */
  path: string;
  filename: string;
  size: number;
  mimeType: string;
}

/** When present, the core renders subject (+ template body) via renderWithContext. */
export interface MergeContext {
  partyId: string;
  contactId?: string | null;
  /** if set, body is fetched from app.email_templates(body_html) then merged */
  templateId?: string;
}

export interface SendOutboundInput {
  /** caller passes its own server client so RLS/auth context is preserved */
  supabase: SbClient;
  organizationId: string;
  sentByUserId?: string;

  // recipient (single primary; matches all three sites today)
  to: string;
  cc?: string[];

  // identity - caller resolves (decision c). Core does not pick env vs DB policy.
  fromName: string;
  fromAddress: string;
  sendingAddressKind?: SendingAddressKind;
  replyTo?: string;

  // content
  subject: string;
  /** pre-rendered HTML. If `merge.templateId` is set, this is ignored and the
   *  template body_html is used instead. */
  bodyHtml: string;
  /** optional plain fallback; derived from bodyHtml when omitted */
  bodyText?: string;

  // template / merge (decision b) - only the dialog uses this today
  merge?: MergeContext;

  // signature - default true; closes the drafts no-signature gap
  useSignature?: boolean;

  // threading - always forwarded to sendOne (closes drafts wire-header gap)
  inReplyTo?: string;
  references?: string[];

  // linkage / flags
  partyId?: string | null;
  contactId?: string | null;
  threadId?: string | null;
  /** urmHeaders.autoSend; true for the AI auto-send path */
  autoSend?: boolean;
  aiGenerated?: boolean;
  aiDraftId?: string;
  attachments?: OutboundAttachmentMeta[];
  traceLabel?: string;

  // safety (decision a) - core enforces whitelist unless explicitly skipped
  skipWhitelist?: boolean;
}

export interface SendOutboundResult {
  ok: boolean;
  status: 'sent' | 'failed' | 'blocked';
  /** undefined when blocked before the communications insert */
  communicationId?: string;
  messageId?: string;
  threadId?: string;
  errorCode?: 'not_whitelisted' | 'database' | 'send_failed' | 'pii_tokens_present';
  errorMessage?: string;
}

/* ============================================================
 * Helpers moved from email-compose.ts (verified equivalents).
 * email-compose.ts private copies are removed in the adapter step.
 * ============================================================ */

/** Render {{party.*}} / {{contact.*}} merge variables; strip unmatched. */
async function renderWithContext(
  supabase: SbClient,
  template: string,
  partyId: string,
  contactId?: string | null,
): Promise<string> {
  let result = template;

  const { data: partyRaw } = await supabase
    .schema('app')
    .from('parties' as never)
    .select('party_name, country_code, website')
    .eq('id', partyId)
    .single();
  const party = partyRaw as
    | { party_name: string | null; country_code: string | null; website: string | null }
    | null;

  if (party) {
    result = result
      .replace(/{{party\.name}}/g, party.party_name ?? '')
      .replace(/{{party\.country}}/g, party.country_code ?? '')
      .replace(/{{party\.website}}/g, party.website ?? '');
  }

  let resolvedContactId = contactId ?? null;
  if (!resolvedContactId) {
    const { data: primaryRaw } = await supabase
      .schema('app')
      .from('contacts' as never)
      .select('id')
      .eq('party_id', partyId)
      .eq('is_primary', true)
      .maybeSingle();
    resolvedContactId = (primaryRaw as { id: string } | null)?.id ?? null;
  }

  if (resolvedContactId) {
    const { data: contactRaw } = await supabase
      .schema('app')
      .from('contacts' as never)
      .select('given_name, family_name, email, title_text, department, phone_e164')
      .eq('id', resolvedContactId)
      .single();
    const contact = contactRaw as
      | {
          given_name: string | null;
          family_name: string | null;
          email: string | null;
          title_text: string | null;
          department: string | null;
          phone_e164: string | null;
        }
      | null;

    if (contact) {
      const fullName = [contact.given_name, contact.family_name].filter(Boolean).join(' ');
      result = result
        .replace(/{{contact\.given_name}}/g, contact.given_name ?? '')
        .replace(/{{contact\.family_name}}/g, contact.family_name ?? '')
        .replace(/{{contact\.full_name}}/g, fullName)
        .replace(/{{contact\.email}}/g, contact.email ?? '')
        .replace(/{{contact\.title}}/g, contact.title_text ?? '')
        .replace(/{{contact\.department}}/g, contact.department ?? '')
        .replace(/{{contact\.phone}}/g, contact.phone_e164 ?? '');
    }
  }

  // strip any unmatched variables
  result = result.replace(/{{[^}]+}}/g, '');
  return result;
}

/** Default signature HTML for the org, or null. */
async function getDefaultSignature(supabase: SbClient, orgId: string): Promise<string | null> {
  const { data } = await supabase
    .schema('app')
    .from('email_signatures' as never)
    .select('html_content')
    .eq('organization_id', orgId)
    .eq('is_default', true)
    .maybeSingle();
  return (data as { html_content: string | null } | null)?.html_content ?? null;
}

/** Minimal plain-text -> HTML (used when a caller has only plain text, e.g. AI drafts). */
function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function plainToHtml(text: string): string {
  const parts = text.split('\n').map((line) => {
    const t = line.trim();
    return t === '' ? '<br>' : `<p style="margin:0 0 8px 0">${escapeHtml(t)}</p>`;
  });
  return `<div style="font-family:sans-serif;font-size:14px;line-height:1.6;color:#333">${parts.join('\n')}</div>`;
}

/* ============================================================
 * Core
 * ============================================================ */

export async function sendOutboundEmail(input: SendOutboundInput): Promise<SendOutboundResult> {
  const { supabase } = input;
  const orgId = input.organizationId;

  // [1] whitelist guard (before any DB write). cc is intentionally not checked.
  if (!input.skipWhitelist) {
    const domain = input.to.split('@')[1]?.toLowerCase();
    if (domain) {
      const { data: wlRows, error: wlErr } = await supabase
        .schema('app')
        .from('email_whitelist' as never)
        .select('id')
        .eq('organization_id', orgId)
        .eq('is_active', true)
        .in('pattern', [domain, input.to.toLowerCase()])
        .limit(1);
      if (wlErr) {
        return {
          ok: false,
          status: 'blocked',
          errorCode: 'database',
          errorMessage: `Whitelist lookup failed: ${wlErr.message}`,
        };
      }
      if (((wlRows ?? []) as unknown[]).length === 0) {
        return {
          ok: false,
          status: 'blocked',
          errorCode: 'not_whitelisted',
          errorMessage: `Recipient not in whitelist: ${input.to}`,
        };
      }
    }
  }

  // [2] template + subject render (only when merge context is given)
  let finalSubject = input.subject;
  let finalBody = input.bodyHtml;
  if (input.merge) {
    const { partyId, contactId, templateId } = input.merge;
    if (templateId) {
      const { data: tmplRaw } = await supabase
        .schema('app')
        .from('email_templates' as never)
        .select('body_html')
        .eq('id', templateId)
        .single();
      const tmpl = tmplRaw as { body_html: string | null } | null;
      if (tmpl) {
        finalBody = await renderWithContext(supabase, tmpl.body_html ?? '', partyId, contactId ?? undefined);
      }
    }
    finalSubject = await renderWithContext(supabase, input.subject, partyId, contactId ?? undefined);
  }

  // [2b] ensure an HTML body exists (tracking pixel + signature require HTML).
  if (!finalBody.trim() && input.bodyText) {
    finalBody = plainToHtml(input.bodyText);
  }

  // [3] signature (default true)
  if (input.useSignature !== false) {
    const sig = await getDefaultSignature(supabase, orgId);
    if (sig) {
      finalBody = `${finalBody}<br><br><hr style="border:none;border-top:1px solid #e5e7eb;margin:16px 0">${sig}`;
    }
  }

  // [3b] PII token guard (A-fix defense-in-depth): never send a body/subject that
  // still contains unrestored {{PII_nnn}} tokens. Indicates an upstream mask/restore failure.
  if (hasUnrestoredTokens(finalBody) || hasUnrestoredTokens(finalSubject)) {
    const leakedTokens = [
      ...findUnrestoredTokens(finalBody),
      ...findUnrestoredTokens(finalSubject),
    ];
    console.error('[sendOutbound] blocked: unrestored PII tokens present:', leakedTokens);
    return {
      ok: false,
      status: 'blocked',
      errorCode: 'pii_tokens_present',
      errorMessage: `Unrestored PII tokens present; send blocked: `,
    };
  }

  // [4] insert communications (status='sending')
  const insertRow: Record<string, unknown> = {
    organization_id: orgId,
    channel: 'email',
    direction: 'outbound',
    party_id: input.partyId ?? null,
    contact_id: input.contactId ?? null,
    from_address: input.fromAddress,
    from_name: input.fromName,
    to_addresses: [input.to],
    cc_addresses: input.cc ?? [],
    subject: finalSubject,
    body_html: finalBody,
    thread_id: input.threadId ?? null,
    in_reply_to: input.inReplyTo ?? null,
    status: 'sending',
    ai_generated: input.aiGenerated ?? false,
    occurred_at: new Date().toISOString(),
  };
  if (input.sentByUserId) insertRow.sent_by_user_id = input.sentByUserId;
  if (input.aiDraftId) insertRow.ai_draft_id = input.aiDraftId;

  const { data: insRaw, error: insErr } = await supabase
    .schema('app')
    .from('communications' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (insErr || !insRaw) {
    return {
      ok: false,
      status: 'failed',
      errorCode: 'database',
      errorMessage: insErr?.message ?? 'Insert failed',
    };
  }
  const communicationId = (insRaw as { id: string }).id;

  // [5] app-level tracking (non-blocking)
  let injectedHtml = finalBody;
  try {
    const tracking = await createEmailTracking({
      orgId,
      communicationId,
      partyId: input.partyId ?? undefined,
      contactId: input.contactId ?? undefined,
      subject: finalSubject,
      sentTo: input.to,
      htmlBody: finalBody,
    });
    injectedHtml = tracking.injectedHtml;
  } catch (trackingErr) {
    console.warn('[sendOutbound] tracking setup failed:', trackingErr);
  }

  // [6] resolve attachments from storage -> Buffer for nodemailer
  const mailAttachments: AttachmentInput[] = [];
  for (const att of input.attachments ?? []) {
    const { data: fileData, error: dlErr } = await supabase.storage
      .from('email-attachments')
      .download(att.path);
    if (dlErr || !fileData) {
      console.error('[sendOutbound] attachment download failed:', att.path, dlErr);
      continue;
    }
    mailAttachments.push({
      filename: att.filename || (att.path.split('/').pop() ?? 'attachment'),
      content: Buffer.from(await fileData.arrayBuffer()),
      contentType: att.mimeType || undefined,
    });
  }

  // [7] send via TabsMailer; then update sent | failed
  const bodyText =
    input.bodyText ?? finalBody.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  try {
    const mailer = await createTabsMailer();
    const sendResult = await mailer.sendOne({
      to: { address: input.to },
      cc: input.cc?.map((a) => ({ address: a })),
      fromName: input.fromName,
      fromAddress: input.fromAddress,
      replyTo: input.replyTo,
      subject: finalSubject,
      bodyText,
      bodyHtml: injectedHtml,
      inReplyTo: input.inReplyTo,
      references: input.references ?? (input.inReplyTo ? [input.inReplyTo] : undefined),
      urmHeaders: { communicationId, autoSend: input.autoSend ?? false },
      attachments: mailAttachments.length > 0 ? mailAttachments : undefined,
      sendingAddressKind: input.sendingAddressKind,
      traceLabel: input.traceLabel,
    });

    const threadId = input.threadId ?? sendResult.messageId;
    await supabase
      .schema('app')
      .from('communications' as never)
      .update({
        message_id: sendResult.messageId,
        thread_id: threadId,
        status: 'sent',
        sent_at: sendResult.sentAt,
      } as never)
      .eq('id', communicationId)
      .eq('organization_id', orgId);

    // [8] attachment records
    if ((input.attachments ?? []).length > 0) {
      const attachmentRows = (input.attachments ?? []).map((m) => ({
        organization_id: orgId,
        entity_type: 'communication',
        entity_id: communicationId,
        file_name: m.filename,
        file_size_bytes: m.size ?? 0,
        mime_type: m.mimeType || 'application/octet-stream',
        storage_provider: 'supabase',
        storage_bucket: 'email-attachments',
        storage_path: m.path,
      }));
      const { error: attErr } = await supabase
        .schema('app')
        .from('attachments' as never)
        .insert(attachmentRows as never);
      if (attErr) console.error('[sendOutbound] attachment record error:', attErr);
    }

    return {
      ok: true,
      status: 'sent',
      communicationId,
      messageId: sendResult.messageId,
      threadId,
    };
  } catch (sendErr) {
    const errMsg = sendErr instanceof Error ? sendErr.message : String(sendErr);
    const { error: failUpdErr } = await supabase
      .schema('app')
      .from('communications' as never)
      .update({ status: 'failed', error_message: errMsg } as never)
      .eq('id', communicationId)
      .eq('organization_id', orgId);
    if (failUpdErr) {
      console.error('[sendOutbound] failed-status update error:', failUpdErr);
    }
    return {
      ok: false,
      status: 'failed',
      communicationId,
      errorCode: 'send_failed',
      errorMessage: errMsg,
    };
  }
}