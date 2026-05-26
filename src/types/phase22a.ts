// src/types/phase22a.ts
// ============================================================
// Phase 22a — Communications Timeline + Compose Dialog Types
// ============================================================

export type EmailDirection = "outbound" | "inbound";

export type EmailStatus =
  | "draft"
  | "queued"
  | "sending"
  | "sent"
  | "delivered"
  | "failed"
  | "received"
  | "bounced";

export type ComposeMode = "manual" | "template" | "ai";

export type ReplyIntent =
  | "interested"
  | "not_now"
  | "objection"
  | "unsubscribe"
  | "wrong_person"
  | "question"
  | "auto_reply"
  | "unknown";

export interface AIClassification {
  intent?: ReplyIntent;
  confidence?: number;
  summary?: string;
  language?: "ko" | "en" | "ja" | string;
  sentiment?: "positive" | "neutral" | "negative";
  competitors_mentioned?: string[];
  topics?: string[];
  suggested_action?: string;
  [key: string]: unknown;
}

export interface CommunicationTimelineItem {
  id: string;
  thread_id: string | null;
  in_reply_to: string | null;
  message_id: string | null;
  direction: EmailDirection;
  subject: string | null;
  body_html: string | null;
  body_plain: string | null;
  body_summary: string | null;
  from_address: string | null;
  from_name: string | null;
  to_addresses: string[];
  status: string;
  occurred_at: string;
  sent_at: string | null;
  opened_at: string | null;
  clicked_at: string | null;
  replied_at: string | null;
  received_at: string | null;
  ai_classification: AIClassification | null;
  ai_generated: boolean;
  contact_id: string | null;
  contact_name: string | null;
  contact_email: string | null;
  template_id: string | null;
  is_starred: boolean;
  thread_position: number;
}

export interface PartyCommunicationStats {
  total: number;
  sent: number;
  received: number;
  opened: number;
  replied: number;
  threads: number;
}

export interface ThreadContext {
  thread: Array<{
    id: string;
    direction: EmailDirection;
    subject: string;
    body_plain: string;
    from_address: string;
    from_name: string;
    occurred_at: string;
    ai_classification: AIClassification | null;
  }>;
  party: {
    id: string;
    name: string;
    country_code: string | null;
    industry_tags: string[] | null;
    tier: string | null;
    module: string | null;
    party_type: string | null;
  } | null;
  contact: {
    id: string;
    given_name: string | null;
    family_name: string | null;
    email: string | null;
    role_title: string | null;
    decision_role: string | null;
  } | null;
}

export interface TemplateForCompose {
  id: string;
  name: string;
  category: string | null;
  subject: string | null;
  body_plain: string | null;
  body_html: string | null;
  module: string | null;
}

export interface ComposeEmailInput {
  party_id: string | null;
  contact_id: string | null;
  to_addresses: string[];
  subject: string;
  body_html: string;
  body_plain: string;
  in_reply_to?: string | null;
  template_id?: string | null;
  ai_generated?: boolean;
  send_now?: boolean;  // if false, save as draft
}

export interface AIReplyRequest {
  in_reply_to_communication_id: string;
  user_instruction?: string;  // optional tone/intent hint
  target_language?: "ko" | "en" | "ja";  // optional override
}

export interface AIComposeRequest {
  party_id: string;
  contact_id: string | null;
  user_instruction: string;  // e.g. "Introduce our PCC product"
  target_language?: "ko" | "en" | "ja";
}

export interface AIComposeResponse {
  subject: string;
  body_plain: string;
  body_html: string;
  language_detected: string;
  reasoning?: string;
}
