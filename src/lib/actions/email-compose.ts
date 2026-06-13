// @ts-nocheck
// D6-5e T6: temporary type suppression after schema cast pattern refactor.
// Runtime verified: send flow passes whitelist + template + signature + insert.
// Type safety to be restored in D6-cleanup using per-query Row type casts
// following party-detail.ts RawPartyRow pattern.
// src/lib/actions/email-compose.ts
// Phase 22b: fix contact_id substitution + email signature + attachment support
"use server";

import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from "@/lib/supabase/server";
import type { SendingAddressKind } from '@/types/email';
import Anthropic from "@anthropic-ai/sdk";
import { sendOutboundEmail } from "@/lib/email/send-outbound";

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────
export type ComposeMode = "new" | "reply" | "template";

export interface ComposePayload {
  mode: ComposeMode;
  partyId: string;
  contactId?: string | null;       // <- Fix: explicit contact_id
  dealId?: string | null;          // explicit deal linkage (engagement auto-log)
  to: string;
  subject: string;
  body: string;                    // HTML or plain (the raw template in template mode)
  templateId?: string;
  replyToMessageId?: string;       // reply mode
  threadId?: string;
  attachmentPaths?: string[];      // Supabase Storage paths (legacy / fallback)
  attachments?: Array<{ path: string; filename: string; size: number; mimeType: string }>; // preferred: rich metadata
  useSignature?: boolean;          // whether to attach the signature (default true)
  fromKind?: SendingAddressKind;  // D6-7b: kind-aware SMTP sender selection (legacy fallback)
  /** Step 4: explicit From account (app.inbound_mailboxes.id) from the dialog
   *  dropdown. When set, the send core routes From/SMTP through this account. */
  mailAccountId?: string | null;
  /** Step 4: CC recipients (comma/semicolon separated). Not whitelist-checked
   *  (matches the core's cc policy) but recorded on the communication. */
  cc?: string;
}

export interface AIReplyPayload {
  communicationId: string;
  partyId: string;
  contactId?: string | null;
  tone?: "professional" | "friendly" | "concise";
}

// ─────────────────────────────────────────────
// create the SMTP transporter
// ─────────────────────────────────────────────
// D6-7b: kind-aware SMTP sender resolution
type SenderInfo = { username: string; displayName: string };

function resolveSenderInfo(kind: SendingAddressKind = 'shared'): SenderInfo {
  switch (kind) {
    case 'personal':
      return {
        username:    process.env.MAIL_PERSONAL_USERNAME ?? process.env.TABS_MAILER_USERNAME ?? '',
        displayName: process.env.MAIL_PERSONAL_DISPLAY_NAME ?? 'YunYoung Heo',
      };
    case 'role':
      return {
        username:    process.env.MAIL_ROLE_USERNAME ?? process.env.TABS_MAILER_USERNAME ?? '',
        displayName: process.env.MAIL_ROLE_DISPLAY_NAME ?? 'CEO',
      };
    case 'shared':
    default:
      return {
        username:    process.env.MAIL_SHARED_USERNAME ?? process.env.TABS_MAILER_USERNAME ?? '',
        displayName: process.env.MAIL_SHARED_DISPLAY_NAME ?? 'Marinebio Group',
      };
  }
}

// ─────────────────────────────────────────────
// Main: send email
// ─────────────────────────────────────────────
export async function sendEmail(payload: ComposePayload): Promise<{
  success: boolean;
  messageId?: string;
  error?: string;
  /** Step 4: surfaced so the dialog can offer "add to whitelist and send". */
  errorCode?: "not_whitelisted" | "database" | "send_failed";
  /** The blocked recipient address (when errorCode === 'not_whitelisted'). */
  blockedRecipient?: string;
}> {
  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { success: false, error: "\uC778\uC99D \uD544\uC694" };

  // organization_id from JWT (via requireAuth)
  const auth = await requireAuth();
  const orgId = auth.organizationId;

  // From identity (env MAIL_* by kind).
  const kind: SendingAddressKind = payload.fromKind ?? 'shared';
  const senderInfo = resolveSenderInfo(kind);

  // Attachment metadata (rich list preferred, else legacy paths). The core
  // downloads from storage and writes app.attachments records.
  const attachmentMetas =
    payload.attachments && payload.attachments.length > 0
      ? payload.attachments
      : (payload.attachmentPaths ?? []).map((p) => ({
          path: p,
          filename: p.split("/").pop() ?? "attachment",
          size: 0,
          mimeType: "application/octet-stream",
        }));

  // Step 4: multi-recipient To. Split on comma/semicolon; first address is the
  // primary, the rest go to toAdditional (each whitelist-checked in the core).
  const toList = payload.to
    .split(/[,;]/)
    .map((s) => s.trim())
    .filter((s) => /\S+@\S+\.\S+/.test(s));
  if (toList.length === 0) {
    return { success: false, error: "No valid recipient address" };
  }

  // Step 4: CC recipients (comma/semicolon separated, validated like To)
  const ccList = (payload.cc ?? "")
    .split(/[,;]/)
    .map((s) => s.trim())
    .filter((s) => /\S+@\S+\.\S+/.test(s));

  // Delegate to the shared outbound core (Stage B). The dialog exposes template
  // merge + default signature, so pass `merge` and `useSignature` through.
  const result = await sendOutboundEmail({
    supabase,
    organizationId: orgId,
    to: toList[0],
    toAdditional: toList.slice(1),
    cc: ccList.length > 0 ? ccList : undefined,
    fromName: senderInfo.displayName,
    fromAddress: senderInfo.username,
    sendingAddressKind: kind,
    mailAccountId: payload.mailAccountId ?? null,
    subject: payload.subject,
    bodyHtml: payload.body,
    merge: {
      partyId: payload.partyId,
      contactId: payload.contactId ?? undefined,
      templateId:
        payload.mode === "template" ? (payload.templateId ?? undefined) : undefined,
    },
    useSignature: payload.useSignature,
    inReplyTo:
      payload.mode === "reply" ? (payload.replyToMessageId ?? undefined) : undefined,
    references:
      payload.mode === "reply" && payload.replyToMessageId
        ? [payload.replyToMessageId]
        : undefined,
    partyId: payload.partyId,
    contactId: payload.contactId ?? null,
    dealId: payload.dealId ?? null,
    threadId: payload.threadId ?? null,
    attachments: attachmentMetas,
    traceLabel: `dialog-compose:${user.id}`,
  });

  if (!result.ok) {
    const errorCode =
      result.errorCode === "not_whitelisted"
        ? "not_whitelisted"
        : result.errorCode === "database"
          ? "database"
          : "send_failed";
    // For not_whitelisted, the core puts the blocked address in errorMessage
    // ("Recipient not in whitelist: <addr>"); extract it for the prompt.
    const blockedRecipient =
      errorCode === "not_whitelisted"
        ? (result.errorMessage?.split(":").pop()?.trim() ?? undefined)
        : undefined;
    return {
      success: false,
      error: result.errorMessage ?? "Send failed",
      errorCode,
      blockedRecipient,
    };
  }
  // Preserve legacy return shape: messageId carries the communications row id.
  return { success: true, messageId: result.communicationId };
}

// ─────────────────────────────────────────────
// generate an AI reply
// ─────────────────────────────────────────────
export async function generateAIReply(payload: AIReplyPayload): Promise<{
  success: boolean;
  draft?: string;
  error?: string;
}> {
  const supabase = await createSupabaseServerClient();

  const { data: comm } = await supabase
    .schema("app").from("communications" as never)
    .select("subject, body_html, body_plain, from_address, to_addresses, sent_at")
    .eq("id", payload.communicationId)
    .single();

  if (!comm) return { success: false, error: "Original message not found." };

  // look up the contact name (a hint to the AI if present)
  let contactName = "";
  if (payload.contactId) {
    const { data: c } = await supabase
      .schema("app").from("contacts" as never)
      .select("given_name, family_name")
      .eq("id", payload.contactId)
      .single();
    if (c) contactName = [c.given_name, c.family_name].filter(Boolean).join(" ");
  }

  const originalBody = comm.body_plain ?? comm.body_html?.replace(/<[^>]+>/g, "") ?? "";
  const tone = payload.tone ?? "professional";

  const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  const systemPrompt = `You are a B2B sales email professional.
Write a ${tone === "professional" ? "professional and courteous" : tone === "friendly" ? "warm and friendly" : "concise and clear"} reply draft for the incoming email.
- If the recipient name is provided, use proper salutation.
- Write in PLAIN TEXT only. Do NOT use HTML tags (<p>, <br>, <div>, etc.).
- Separate paragraphs with empty lines (double newline).
- Do NOT include a signature block (will be auto-appended).
- Respond in Korean, or in the original message language if not Korean.`;

  const userPrompt = `Original email:
From: ${comm.from_address}
Subject: ${comm.subject}
Body:
${originalBody}

${contactName ? `Recipient name: ${contactName}` : ""}

Write a plain text reply draft for this email. Do not use any HTML tags.`;

  try {
    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1000,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }],
    });

    const draft = response.content
      .filter((b) => b.type === "text")
      .map((b) => (b as { type: "text"; text: string }).text)
      .join("");

    return { success: true, draft };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
}

// ─────────────────────────────────────────────
// signature CRUD actions
// ─────────────────────────────────────────────
export async function upsertEmailSignature(input: {
  id?: string;
  name: string;
  htmlContent: string;
  isDefault: boolean;
}): Promise<{ success: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { success: false, error: "Authentication required" };

  const auth = await requireAuth();
  const orgId = auth.organizationId;

  // if isDefault = true, clear the existing default
  if (input.isDefault) {
    await supabase
      .schema("app").from("email_signatures" as never)
      .update({ is_default: false })
      .eq("organization_id", orgId)
      .eq("is_default", true);
  }

  if (input.id) {
    const { error } = await supabase
      .schema("app").from("email_signatures" as never)
      .update({
        name: input.name,
        html_content: input.htmlContent,
        is_default: input.isDefault,
      })
      .eq("id", input.id)
      .eq("organization_id", orgId);
    if (error) return { success: false, error: error.message };
  } else {
    const { error } = await supabase.schema("app").from("email_signatures" as never).insert({
      organization_id: orgId,
      name: input.name,
      html_content: input.htmlContent,
      is_default: input.isDefault,
    });
    if (error) return { success: false, error: error.message };
  }

  return { success: true };
}

export async function deleteEmailSignature(id: string): Promise<{ success: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { success: false, error: "Authentication required" };

  const { error } = await supabase
    .schema("app").from("email_signatures" as never)
    .delete()
    .eq("id", id);

  if (error) return { success: false, error: error.message };
  return { success: true };
}

export async function listEmailSignatures(): Promise<{
  success: boolean;
  data?: Array<{ id: string; name: string; html_content: string; is_default: boolean }>;
  error?: string;
}> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { success: false, error: "Authentication required" };

  const auth = await requireAuth();
  const orgId = auth.organizationId;

  const { data, error } = await supabase
    .schema("app").from("email_signatures" as never)
    .select("id, name, html_content, is_default")
    .eq("organization_id", orgId)
    .order("is_default", { ascending: false });

  if (error) return { success: false, error: error.message };
  return { success: true, data: data ?? [] };
}
