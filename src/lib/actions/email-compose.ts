// src/lib/actions/email-compose.ts
// Phase 22b: contact_id 치환 수정 + 이메일 서명 + 첨부파일 지원
"use server";

import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient, type SbClient } from "@/lib/supabase/server";
import { cookies } from "next/headers";
import nodemailer from "nodemailer";
import Anthropic from "@anthropic-ai/sdk";

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
  attachmentPaths?: string[];      // Supabase Storage paths
  useSignature?: boolean;          // 서명 첨부 여부 (기본 true)
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
    .from("parties")
    .select("name, country_code, website")
    .eq("id", partyId)
    .single();

  if (party) {
    result = result
      .replace(/{{party\.name}}/g, party.name ?? "")
      .replace(/{{party\.country}}/g, party.country_code ?? "")
      .replace(/{{party\.website}}/g, party.website ?? "");
  }

  // --- contact 컨텍스트 ---
  // contactId가 명시적으로 전달된 경우 우선 사용,
  // 없으면 해당 party의 primary contact 조회
  let resolvedContactId = contactId;

  if (!resolvedContactId) {
    const { data: primary } = await supabase
      .from("contacts")
      .select("id")
      .eq("party_id", partyId)
      .eq("is_primary", true)
      .maybeSingle();
    resolvedContactId = primary?.id ?? null;
  }

  if (resolvedContactId) {
    const { data: contact } = await supabase
      .from("contacts")
      .select("given_name, family_name, email, title, department, phone")
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
        .replace(/{{contact\.title}}/g, contact.title ?? "")
        .replace(/{{contact\.department}}/g, contact.department ?? "")
        .replace(/{{contact\.phone}}/g, contact.phone ?? "");
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
    .from("email_signatures")
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
function createTransporter() {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST!,
    port: parseInt(process.env.SMTP_PORT ?? "587"),
    secure: process.env.SMTP_SECURE === "true",
    auth: {
      user: process.env.SMTP_USER!,
      pass: process.env.SMTP_PASS!,
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
    const { data: wl } = await supabase
      .from("email_whitelist")
      .select("id")
      .eq("organization_id", orgId)
      .or(`pattern.eq.${domain},pattern.eq.${payload.to.toLowerCase()}`)
      .maybeSingle();

    if (!wl) {
      return { success: false, error: `수신 주소가 화이트리스트에 없습니다: ${payload.to}` };
    }
  }

  // 본문 렌더링 (template 모드)
  let finalBody = payload.body;
  if (payload.mode === "template" && payload.templateId) {
    // templateId로 원본 내용 조회
    const { data: tmpl } = await supabase
      .from("email_templates")
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
  const attachments = await resolveAttachments(
    supabase,
    payload.attachmentPaths ?? []
  );

  // SMTP 발송
  const transporter = createTransporter();
  const fromAddress = `${process.env.SMTP_FROM_NAME ?? "URM Platform"} <${process.env.SMTP_USER}>`;

  let mailOptions: nodemailer.SendMailOptions = {
    from: fromAddress,
    to: payload.to,
    subject: finalSubject,
    html: finalBody,
    attachments,
  };

  // Reply 모드: In-Reply-To / References 헤더
  if (payload.mode === "reply" && payload.replyToMessageId) {
    mailOptions.inReplyTo = payload.replyToMessageId;
    mailOptions.references = payload.replyToMessageId;
  }

  let smtpMessageId: string | undefined;
  try {
    const info = await transporter.sendMail(mailOptions);
    smtpMessageId = info.messageId;
  } catch (err: any) {
    console.error("[sendEmail] SMTP 오류:", err);
    return { success: false, error: err.message };
  }

  // DB 저장 (app.communications)
  const { data: comm, error: dbErr } = await supabase
    .from("communications")
    .insert({
      organization_id: orgId,
      party_id: payload.partyId,
      contact_id: payload.contactId ?? null,
      direction: "outbound",
      channel: "email",
      subject: finalSubject,
      body_html: finalBody,
      from_address: process.env.SMTP_USER,
      to_addresses: [payload.to],
      message_id: smtpMessageId,
      thread_id: payload.threadId ?? smtpMessageId,
      in_reply_to: payload.replyToMessageId ?? null,
      // attachment_paths: payload.attachmentPaths ?? [], // column not in communications - add via migration
      status: "sent",
      sent_at: new Date().toISOString(),
    })
    .select("id")
    .single();

  if (dbErr) {
    console.error("[sendEmail] DB 저장 오류:", dbErr);
  }

  return { success: true, messageId: comm?.id };
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
    .from("communications")
    .select("subject, body_html, body_plain, from_address, to_addresses, sent_at")
    .eq("id", payload.communicationId)
    .single();

  if (!comm) return { success: false, error: "원본 메시지를 찾을 수 없습니다." };

  // contact 이름 조회 (있으면 AI에게 힌트)
  let contactName = "";
  if (payload.contactId) {
    const { data: c } = await supabase
      .from("contacts")
      .select("given_name, family_name")
      .eq("id", payload.contactId)
      .single();
    if (c) contactName = [c.given_name, c.family_name].filter(Boolean).join(" ");
  }

  const originalBody = comm.body_plain ?? comm.body_html?.replace(/<[^>]+>/g, "") ?? "";
  const tone = payload.tone ?? "professional";

  const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  const systemPrompt = `당신은 B2B 영업 이메일 전문가입니다.
주어진 수신 이메일에 대한 ${tone === "professional" ? "전문적이고 정중한" : tone === "friendly" ? "친근하고 따뜻한" : "간결하고 명확한"} 답장 초안을 작성하세요.
- 수신자 이름이 있으면 호칭을 사용하세요.
- HTML 형식으로 작성하세요 (<p> 태그 사용).
- 서명 부분은 포함하지 마세요 (자동으로 추가됩니다).
- 한국어 또는 원본 언어에 맞게 작성하세요.`;

  const userPrompt = `원본 이메일:
발신: ${comm.from_address}
제목: ${comm.subject}
내용:
${originalBody}

${contactName ? `수신자 이름: ${contactName}` : ""}

이 이메일에 대한 답장 초안을 HTML로 작성해주세요.`;

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
      .from("email_signatures")
      .update({ is_default: false })
      .eq("organization_id", orgId)
      .eq("is_default", true);
  }

  if (input.id) {
    const { error } = await supabase
      .from("email_signatures")
      .update({
        name: input.name,
        html_content: input.htmlContent,
        is_default: input.isDefault,
      })
      .eq("id", input.id)
      .eq("organization_id", orgId);
    if (error) return { success: false, error: error.message };
  } else {
    const { error } = await supabase.from("email_signatures").insert({
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
    .from("email_signatures")
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
    .from("email_signatures")
    .select("id, name, html_content, is_default")
    .eq("organization_id", orgId)
    .order("is_default", { ascending: false });

  if (error) return { success: false, error: error.message };
  return { success: true, data: data ?? [] };
}
