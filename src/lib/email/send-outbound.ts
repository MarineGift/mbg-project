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
//
// Multi-Account Mail Hub Step 3 (2026-06-12):
//   From routing through app.inbound_mailboxes (explicit accountId > reply
//   rule > is_default), per-account SMTP via SendOneInput.smtpAccount, and
//   communications.mail_account_id recorded on outbound rows. When the org
//   has no active smtp-ready accounts the legacy env/TABS_MAILER path applies
//   unchanged (caller-provided fromAddress + sendingAddressKind).

import type { SbClient } from '@/lib/supabase/server';
import type { SendingAddressKind, AttachmentInput, SmtpAccountConfig } from '@/types/email';
import { createTabsMailer } from '@/lib/email/tabs-mailer';
import { createEmailTracking } from '@/lib/actions/email-tracking';
import { hasUnrestoredTokens, findUnrestoredTokens } from '@/lib/ai/pii-masker';
import {
  resolveOutboundMailAccount,
  decryptMailAccountSmtpPassword,
  type MailAccount,
} from '@/lib/email/mail-accounts';

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
  /** Step 4: additional To recipients (multi-recipient send). Each is
   *  whitelist-checked like the primary and recorded in to_addresses. */
  toAdditional?: string[];
  cc?: string[];

  // identity - caller resolves (decision c). Core does not pick env vs DB policy.
  fromName: string;
  fromAddress: string;
  sendingAddressKind?: SendingAddressKind;
  replyTo?: string;
  /** Multi-Account Step 3: explicit From account (app.inbound_mailboxes.id).
   *  Wins over the reply/default routing rule. Set by the Step 4 From dropdown.
   *  When the org has active smtp-ready accounts, the core routes From through
   *  them (reply -> original account rule, new -> is_default) and the
   *  fromName/fromAddress/sendingAddressKind above become a legacy fallback. */
  mailAccountId?: string | null;

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
  /** explicit deal chosen in the compose UI; stored on communications.deal_id.
   *  The DB trigger (trg_comm_log_engagement) turns every party/deal-linked
   *  communication into an app.engagements row on the deal timeline. */
  dealId?: string | null;
  threadId?: string | null;
  /** urmHeaders.autoSend; true for the AI auto-send path */
  autoSend?: boolean;
  aiGenerated?: boolean;
  aiDraftId?: string;
  attachments?: OutboundAttachmentMeta[];
  traceLabel?: string;

  // safety (decision a) - core enforces whitelist unless explicitly skipped
  skipWhitelist?: boolean;

  /** Free-form metadata merged into communications.external_data.
   *  Used by the bulk-mail sender to tag a run (source:'bulk', mail_run_id). */
  externalData?: Record<string, unknown>;
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

/** Sender defaults for {{sender_*}} merge tokens (solo-founder org).
 *  NOTE: not derived from input.fromName because the shared inbox resolves
 *  to the org name ("Marinebio Group"), which must not render into
 *  "I am {{sender_name}}, {{sender_title}}". */
const SENDER_NAME = 'YunYoung Heo';
const SENDER_TITLE = 'Founder & CEO';
const SENDER_COMPANY = 'MarineBio Group';

/** Render merge variables; strip unmatched at the end.
 *  Supports both dot-notation ({{contact.given_name}}, {{party.name}}) and
 *  snake_case template tokens ({{contact_first_name}}, {{company_name}},
 *  {{fund_name}}, {{sender_name}}, ...) used by the 2026-06 template set. */
async function renderWithContext(
  supabase: SbClient,
  template: string,
  partyId: string,
  contactId?: string | null,
  sender?: { name?: string | null; title?: string | null; company?: string | null },
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
    const partyName = party.party_name ?? '';
    result = result
      .replace(/{{party\.name}}/g, partyName)
      .replace(/{{party\.country}}/g, party.country_code ?? '')
      .replace(/{{party\.website}}/g, party.website ?? '')
      // snake_case aliases (2026-06 template set)
      .replace(/{{\s*party_name\s*}}/g, partyName)
      .replace(/{{\s*company_name\s*}}/g, partyName)
      .replace(/{{\s*fund_name\s*}}/g, partyName);
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
        .replace(/{{contact\.firstName}}/g, contact.given_name ?? '')
        .replace(/{{contact\.family_name}}/g, contact.family_name ?? '')
        .replace(/{{contact\.full_name}}/g, fullName)
        .replace(/{{contact\.name}}/g, fullName)
        .replace(/{{contact\.email}}/g, contact.email ?? '')
        .replace(/{{contact\.title}}/g, contact.title_text ?? '')
        .replace(/{{contact\.department}}/g, contact.department ?? '')
        .replace(/{{contact\.phone}}/g, contact.phone_e164 ?? '')
        // snake_case aliases (2026-06 template set)
        .replace(/{{\s*contact_first_name\s*}}/g, contact.given_name ?? '')
        .replace(/{{\s*contact_last_name\s*}}/g, contact.family_name ?? '')
        .replace(/{{\s*contact_family_name\s*}}/g, contact.family_name ?? '')
        .replace(/{{\s*contact_full_name\s*}}/g, fullName)
        .replace(/{{\s*contact_name\s*}}/g, fullName)
        .replace(/{{\s*contact_email\s*}}/g, contact.email ?? '')
        .replace(/{{\s*contact_title\s*}}/g, contact.title_text ?? '');
    }
  }

  // sender tokens (both conventions)
  const senderName = sender?.name ?? SENDER_NAME;
  const senderTitle = sender?.title ?? SENDER_TITLE;
  const senderCompany = sender?.company ?? SENDER_COMPANY;
  result = result
    .replace(/{{\s*sender_name\s*}}/g, senderName)
    .replace(/{{sender\.name}}/g, senderName)
    .replace(/{{my\.name}}/g, senderName)
    .replace(/{{\s*sender_title\s*}}/g, senderTitle)
    .replace(/{{sender\.title}}/g, senderTitle)
    .replace(/{{\s*sender_company\s*}}/g, senderCompany)
    .replace(/{{sender\.company}}/g, senderCompany);

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
  //     Step 4: every To recipient (primary + additional) is checked individually.
  const toRecipients = [input.to, ...(input.toAdditional ?? [])]
    .map((a) => a.trim())
    .filter(Boolean);
  if (!input.skipWhitelist) {
    for (const recipient of toRecipients) {
      const domain = recipient.split('@')[1]?.toLowerCase();
      if (!domain) continue;
      const { data: wlRows, error: wlErr } = await supabase
        .schema('app')
        .from('email_whitelist' as never)
        .select('id')
        .eq('organization_id', orgId)
        .eq('is_active', true)
        .in('pattern', [domain, recipient.toLowerCase()])
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
          errorMessage: `Recipient not in whitelist: ${recipient}`,
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
        .select('body_html, body_plain')
        .eq('id', templateId)
        .single();
      const tmpl = tmplRaw as { body_html: string | null; body_plain: string | null } | null;
      if (tmpl) {
        // bulk/template sends render body_html; fall back to body_plain so
        // templates authored as plain text still produce a body (not just the
        // signature). plainToHtml below converts the plain newlines to HTML.
        const rawBody =
          tmpl.body_html && tmpl.body_html.trim() ? tmpl.body_html : (tmpl.body_plain ?? '');
        finalBody = await renderWithContext(supabase, rawBody, partyId, contactId ?? undefined);
      }
    }
    finalSubject = await renderWithContext(supabase, input.subject, partyId, contactId ?? undefined);
  }

  // [2a] If the body is plain text (no HTML tags), convert newlines so the
  //      line breaks survive in the sent HTML. Template bodies are real HTML and
  //      are detected as such (left untouched). AI-draft / plain compose bodies
  //      arrive as plain text with \n and would otherwise collapse to one line.
  const looksLikeHtml =
    /<(?:p|br|div|table|tr|t[dh]|span|a|ul|ol|li|h[1-6]|strong|em|b|i|img|blockquote|pre|hr)\b[^>]*>/i.test(
      finalBody,
    );
  if (finalBody.trim() && !looksLikeHtml) {
    finalBody = plainToHtml(finalBody);
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

  // [3c] Multi-Account Step 3: resolve the From account from app.inbound_mailboxes.
  //      explicit (input.mailAccountId) > reply rule > is_default.
  //      Resolve failure or zero accounts -> legacy env/TABS_MAILER path (fromAccount=null).
  let fromAccount: MailAccount | null = null;
  try {
    fromAccount = await resolveOutboundMailAccount(supabase, orgId, {
      explicitAccountId: input.mailAccountId ?? null,
      inReplyTo: input.inReplyTo ?? null,
    });
  } catch (acctErr) {
    console.warn(
      '[sendOutbound] mail account resolve failed - falling back to env SMTP:',
      acctErr instanceof Error ? acctErr.message : acctErr,
    );
  }
  const effectiveFromAddress = fromAccount?.address ?? input.fromAddress;
  const effectiveFromName = fromAccount?.displayName ?? input.fromName;

  // [4] insert communications (status='sending')
  const insertRow: Record<string, unknown> = {
    organization_id: orgId,
    channel: 'email',
    direction: 'outbound',
    party_id: input.partyId ?? null,
    contact_id: input.contactId ?? null,
    deal_id: input.dealId ?? null,
    from_address: effectiveFromAddress,
    from_name: effectiveFromName,
    // which account sent this (reply continuity for future inbound replies)
    mail_account_id: fromAccount?.id ?? null,
    to_addresses: toRecipients,
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
  // template_id closes the bulk-mail dedup gap (communications.template_id was
  // previously never recorded). Only set when a template render was requested,
  // so compose/draft sends are unaffected.
  if (input.merge?.templateId) insertRow.template_id = input.merge.templateId;
  if (input.externalData) insertRow.external_data = input.externalData;

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
      client: supabase,
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
    // Multi-Account Step 3: per-account SMTP. Decrypt inside the try block so
    // a decrypt failure lands in the same failed-status update path below.
    let smtpAccount: SmtpAccountConfig | undefined;
    if (fromAccount) {
      const smtpPassword = await decryptMailAccountSmtpPassword(supabase, fromAccount);
      smtpAccount = {
        accountId: fromAccount.id,
        address: fromAccount.address,
        displayName: fromAccount.displayName,
        host: fromAccount.smtpHost,
        port: fromAccount.smtpPort,
        useTls: fromAccount.smtpUseTls,
        username: fromAccount.smtpUsername,
        password: smtpPassword,
        authMethod: fromAccount.smtpAuthMethod,
      };
    }

    const mailer = await createTabsMailer();
    const sendResult = await mailer.sendOne({
      to: { address: toRecipients[0] ?? input.to },
      toAdditional: toRecipients.slice(1).map((a) => ({ address: a })),
      cc: input.cc?.map((a) => ({ address: a })),
      fromName: effectiveFromName,
      fromAddress: effectiveFromAddress,
      replyTo: input.replyTo,
      subject: finalSubject,
      bodyText,
      bodyHtml: injectedHtml,
      inReplyTo: input.inReplyTo,
      references: input.references ?? (input.inReplyTo ? [input.inReplyTo] : undefined),
      urmHeaders: { communicationId, autoSend: input.autoSend ?? false },
      attachments: mailAttachments.length > 0 ? mailAttachments : undefined,
      smtpAccount,
      // account path wins; kind only applies on the legacy fallback
      sendingAddressKind: smtpAccount ? undefined : input.sendingAddressKind,
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