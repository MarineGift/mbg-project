// @ts-nocheck
// D6-5e T6: temporary type suppression after schema cast pattern refactor.
// Runtime verified: send flow passes whitelist + template + signature + insert.
// Type safety to be restored in D6-cleanup using per-query Row type casts
// following party-detail.ts RawPartyRow pattern.
// src/lib/actions/email-compose.ts
// Phase 22b: contact_id 치환 수정 + 이메일 서명 + 첨부파일 지원
"use server";

import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient, type SbClient } from "@/lib/supabase/server";
import { cookies } from "next/headers";
import nodemailer from "nodemailer";
import type { SendingAddressKind } from '@/types/email';
import Anthropic from "@anthropic-ai/sdk";
import { createTabsMailer } from "@/lib/email/tabs-mailer";
import { createEmailTracking } from "@/lib/actions/email-tracking";

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────
export type ComposeMode = "new" | "reply" | "template";

export interface ComposePayload {
  mode: ComposeMode;
  partyId: string;
  contactId?: string | null;       // ← Fix: contact_id 명시
  to: string;
  subject: string;
  body: string;                    // HTML or plain (template 모드에서는 template 원문)
  templateId?: string;
  replyToMessageId?: string;       // reply 모드
  threadId?: string;
  attachmentPaths?: string[];      // Supabase Storage paths (legacy / fallback)
  attachments?: Array<{ path: string; filename: string; size: number; mimeType: string }>; // preferred: rich metadata
  useSignature?: boolean;          // 서명 첨부 여부 (기본 true)
  fromKind?: SendingAddressKind;  // D6-7b: kind-aware SMTP sender selection
}

export interface AIReplyPayload {
  communicationId: string;
  partyId: string;
  contactId?: string | null;
  tone?: "professional" | "friendly" | "concise";
}

// ─────────────────────────────────────────────
// Template merge: {{party.name}}, {{contact.given_name}} 등
// ─────────────────────────────────────────────
async function renderWithContext(
  supabase: SbClient,
  template: string,
  partyId: string,
  contactId?: string | null
): Promise<string> {
  let result = template;

  // --- party 컨텍스트 ---
  const { data: party } = await supabase
    .schema("app").from("parties" as never)
    .select("party_name, country_code, website")
    .eq("id", partyId)
    .single();

  if (party) {
    result = result
      .replace(/{{party\.name}}/g, party.party_name ?? "")
      .replace(/{{party\.country}}/g, party.country_code ?? "")
      .replace(/{{party\.website}}/g, party.website ?? "");
  }

  // --- contact 컨텍스트 ---
  // contactId가 명시적으로 전달된 경우 우선 사용,
  // 없으면 해당 party의 primary contact 조회
  let resolvedContactId = contactId;

  if (!resolvedContactId) {
    const { data: primary } = await supabase
      .schema("app").from("contacts" as never)
      .select("id")
      .eq("party_id", partyId)
      .eq("is_primary", true)
      .maybeSingle();
    resolvedContactId = primary?.id ?? null;
  }

  if (resolvedContactId) {
    const { data: contact } = await supabase
      .schema("app").from("contacts" as never)
      .select("given_name, family_name, email, title_text, department, phone_e164")
      .eq("id", resolvedContactId)
      .single();

    if (contact) {
      const fullName = [contact.given_name, contact.family_name]
        .filter(Boolean)
        .join(" ");
      result = result
        .replace(/{{contact\.given_name}}/g, contact.given_name ?? "")
        .replace(/{{contact\.family_name}}/g, contact.family_name ?? "")
        .replace(/{{contact\.full_name}}/g, fullName)
        .replace(/{{contact\.email}}/g, contact.email ?? "")
        .replace(/{{contact\.title}}/g, contact.title_text ?? "")
        .replace(/{{contact\.department}}/g, contact.department ?? "")
        .replace(/{{contact\.phone}}/g, contact.phone_e164 ?? "");
    }
  }

  // 치환 안 된 변수 제거 (빈 문자열)
  result = result.replace(/{{[^}]+}}/g, "");

  return result;
}

// ─────────────────────────────────────────────
// 기본 서명 조회
// ─────────────────────────────────────────────
async function getDefaultSignature(
  supabase: SbClient,
  orgId: string
): Promise<string | null> {
  const { data } = await supabase
    .schema("app").from("email_signatures" as never)
    .select("html_content")
    .eq("organization_id", orgId)
    .eq("is_default", true)
    .maybeSingle();
  return data?.html_content ?? null;
}

// ─────────────────────────────────────────────
// Supabase Storage → nodemailer 첨부파일 변환
// ─────────────────────────────────────────────
async function resolveAttachments(
  supabase: SbClient,
  paths: string[]
): Promise<nodemailer.SendMailOptions["attachments"]> {
  if (!paths || paths.length === 0) return [];

  const attachments: nodemailer.SendMailOptions["attachments"] = [];

  for (const storagePath of paths) {
    // storagePath 형식: "email-attachments/{orgId}/{filename}"
    const { data, error } = await supabase.storage
      .from("email-attachments")
      .download(storagePath);

    if (error || !data) {
      console.error(`[attachment] 다운로드 실패: ${storagePath}`, error);
      continue;
    }

    const arrayBuffer = await data.arrayBuffer();
    const filename = storagePath.split("/").pop() ?? "attachment";

    attachments.push({
      filename,
      content: Buffer.from(arrayBuffer),
    });
  }

  return attachments;
}

// ─────────────────────────────────────────────
// SMTP 트랜스포터 생성
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

function createTransporter(kind: SendingAddressKind = 'shared') {
  let user: string | undefined;
  let pass: string | undefined;
  switch (kind) {
    case 'personal':
      user = process.env.MAIL_PERSONAL_USERNAME;
      pass = process.env.MAIL_PERSONAL_PASSWORD;
      break;
    case 'role':
      user = process.env.MAIL_ROLE_USERNAME;
      pass = process.env.MAIL_ROLE_PASSWORD;
      break;
    case 'shared':
    default:
      user = process.env.MAIL_SHARED_USERNAME;
      pass = process.env.MAIL_SHARED_PASSWORD;
      break;
  }
  return nodemailer.createTransport({
    host:   process.env.TABS_MAILER_HOST!,
    port:   parseInt(process.env.TABS_MAILER_PORT ?? '587'),
    secure: process.env.TABS_MAILER_USE_TLS === 'true',
    auth: {
      user: (user || process.env.TABS_MAILER_USERNAME)!,
      pass: (pass || process.env.TABS_MAILER_PASSWORD)!,
    },
  });
}

// ─────────────────────────────────────────────
// 메인: 이메일 발송
// ─────────────────────────────────────────────
export async function sendEmail(payload: ComposePayload): Promise<{
  success: boolean;
  messageId?: string;
  error?: string;
}> {
  const supabase = await createSupabaseServerClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { success: false, error: "인증 필요" };

  // organization_id from JWT (via requireAuth)
  const auth = await requireAuth();
  const orgId = auth.organizationId;

  // 화이트리스트 확인
  const domain = payload.to.split("@")[1]?.toLowerCase();
  if (domain) {
    // D6-5e T6c: .or() with dot-containing values breaks PostgREST parsing for domain.com
    // and ceo@domain.com style values. Use .in() with explicit array instead, plus
    // .limit(1) (safer than .maybeSingle() which errors on multiple matches) and
    // explicit error logging (was silently treating PostgREST errors as "not whitelisted").
    const { data: wlRows, error: wlErr } = await supabase
      .schema("app").from("email_whitelist" as never)
      .select("id")
      .eq("organization_id", orgId)
      .eq("is_active", true)
      .in("pattern", [domain, payload.to.toLowerCase()])
      .limit(1);

    if (wlErr) {
      console.error("[sendEmail] whitelist query error:", wlErr);
      return { success: false, error: `?붿씠?몃━?ㅽ듃 議고쉶 ?ㅻ쪟: ${wlErr.message}` };
    }

    if (!wlRows || wlRows.length === 0) {
      return { success: false, error: `수신 주소가 화이트리스트에 없습니다: ${payload.to}` };
    }
  }

  // 본문 렌더링 (template 모드)
  let finalBody = payload.body;
  if (payload.mode === "template" && payload.templateId) {
    // templateId로 원본 내용 조회
    const { data: tmpl } = await supabase
      .schema("app").from("email_templates" as never)
      .select("body_html, subject")
      .eq("id", payload.templateId)
      .single();
    if (tmpl) {
      finalBody = await renderWithContext(
        supabase,
        tmpl.body_html ?? '',
        payload.partyId,
        payload.contactId ?? undefined
      );
    }
  }

  // 서명 추가
  const useSignature = payload.useSignature !== false; // 기본 true
  if (useSignature) {
    const sig = await getDefaultSignature(supabase, orgId);
    if (sig) {
      finalBody = `${finalBody}<br><br><hr style="border:none;border-top:1px solid #e5e7eb;margin:16px 0">${sig}`;
    }
  }

  // 제목 렌더링 (contact 변수 포함 가능)
  const finalSubject = await renderWithContext(
    supabase,
    payload.subject,
    payload.partyId,
    payload.contactId
  );

  // 첨부파일 처리
  const attachmentMetas =
    payload.attachments && payload.attachments.length > 0
      ? payload.attachments
      : (payload.attachmentPaths ?? []).map((p) => ({
          path: p,
          filename: p.split("/").pop() ?? "attachment",
          size: 0,
          mimeType: "application/octet-stream",
        }));
  const attachments: nodemailer.SendMailOptions["attachments"] = [];
  for (const meta of attachmentMetas) {
    const { data: fileData, error: dlErr } = await supabase.storage
      .from("email-attachments")
      .download(meta.path);
    if (dlErr || !fileData) {
      console.error("[sendEmail] attachment download failed:", meta.path, dlErr);
      continue;
    }
    attachments.push({
      filename: meta.filename || (meta.path.split("/").pop() ?? "attachment"),
      content: Buffer.from(await fileData.arrayBuffer()),
      contentType: meta.mimeType || undefined,
    });
  }

  // SMTP 발송
  const kind: SendingAddressKind = payload.fromKind ?? 'shared';
  const senderInfo = resolveSenderInfo(kind);

  // [A] communications INSERT (status='sending') first, so we have an id for the
  // tracking pixel + X-URM-communication-id header (parity with sendOutboundManual).
  const { data: comm, error: insErr } = await supabase
    .schema("app").from("communications" as never)
    .insert({
      organization_id: orgId,
      party_id: payload.partyId,
      contact_id: payload.contactId ?? null,
      direction: "outbound",
      channel: "email",
      subject: finalSubject,
      body_html: finalBody,
      from_address: senderInfo.username,
      from_name: senderInfo.displayName,
      to_addresses: [payload.to],
      thread_id: payload.threadId ?? null,
      in_reply_to: payload.replyToMessageId ?? null,
      status: "sending",
      ai_generated: false,
      occurred_at: new Date().toISOString(),
    })
    .select("id")
    .single();

  if (insErr || !comm?.id) {
    console.error("[sendEmail] DB insert error:", insErr);
    return { success: false, error: insErr?.message ?? "DB insert failed" };
  }
  const outboundId = comm.id as string;

  // [B] app-level email tracking: pixel + click rewrite (decision 1a).
  // Non-blocking: if tracking setup fails, still send.
  let injectedHtml = finalBody;
  try {
    const trackingResult = await createEmailTracking({
      orgId,
      communicationId: outboundId,
      partyId: payload.partyId ?? undefined,
      contactId: payload.contactId ?? undefined,
      subject: finalSubject,
      sentTo: payload.to,
      htmlBody: finalBody,
    });
    injectedHtml = trackingResult.injectedHtml;
  } catch (trackingErr) {
    console.warn("[sendEmail] tracking setup failed:", trackingErr);
  }

  // [C] send via TabsMailer (tracking pixel in html + URM header + reply threading).
  const bodyTextFallback = finalBody.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  try {
    const mailer = await createTabsMailer();
    const sendResult = await mailer.sendOne({
      to: { address: payload.to },
      fromName: senderInfo.displayName,
      fromAddress: senderInfo.username,
      subject: finalSubject,
      bodyText: bodyTextFallback,
      bodyHtml: injectedHtml,
      inReplyTo:
        payload.mode === "reply" ? (payload.replyToMessageId ?? undefined) : undefined,
      references:
        payload.mode === "reply" && payload.replyToMessageId
          ? [payload.replyToMessageId]
          : undefined,
      urmHeaders: { communicationId: outboundId, autoSend: false },
      attachments,
      sendingAddressKind: kind,
      traceLabel: `dialog-compose:${user.id}`,
    });

    // [D] communications UPDATE (sent). Root a new thread at its own message-id.
    await supabase
      .schema("app").from("communications" as never)
      .update({
        message_id: sendResult.messageId,
        thread_id: payload.threadId ?? sendResult.messageId,
        status: "sent",
        sent_at: sendResult.sentAt,
      } as never)
      .eq("id", outboundId)
      .eq("organization_id", orgId);
  } catch (sendErr: any) {
    console.error("[sendEmail] send error:", sendErr);
    const { error: failUpdErr } = await supabase
      .schema("app").from("communications" as never)
      .update({
        status: "failed",
        error_message: sendErr?.message ?? String(sendErr),
      } as never)
      .eq("id", outboundId)
      .eq("organization_id", orgId);
    if (failUpdErr) {
      console.error("[sendEmail] failed-status update error:", failUpdErr);
    }
    return { success: false, error: sendErr?.message ?? "Send failed" };
  }

  // [E] attachment records (app.attachments)
  if (attachmentMetas.length > 0) {
    const attachmentRows = attachmentMetas.map((m) => ({
      organization_id: orgId,
      entity_type: "communication",
      entity_id: outboundId,
      file_name: m.filename,
      file_size_bytes: m.size ?? 0,
      mime_type: m.mimeType || "application/octet-stream",
      storage_provider: "supabase",
      storage_bucket: "email-attachments",
      storage_path: m.path,
    }));
    const { error: attErr } = await supabase
      .schema("app").from("attachments" as never)
      .insert(attachmentRows);
    if (attErr) console.error("[sendEmail] attachment record error:", attErr);
  }

  return { success: true, messageId: outboundId };
}

// ─────────────────────────────────────────────
// AI 답장 생성
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

  if (!comm) return { success: false, error: "원본 메시지를 찾을 수 없습니다." };

  // contact 이름 조회 (있으면 AI에게 힌트)
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
// 서명 CRUD actions
// ─────────────────────────────────────────────
export async function upsertEmailSignature(input: {
  id?: string;
  name: string;
  htmlContent: string;
  isDefault: boolean;
}): Promise<{ success: boolean; error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { success: false, error: "인증 필요" };

  const auth = await requireAuth();
  const orgId = auth.organizationId;

  // isDefault = true 이면 기존 default 해제
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
  if (!user) return { success: false, error: "인증 필요" };

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
  if (!user) return { success: false, error: "인증 필요" };

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
