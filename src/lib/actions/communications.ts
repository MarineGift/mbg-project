/**
 * lib/actions/communications.ts
 *
 * Server Action for manually sending outbound mail.
 * Uses TABS Mailer to send via SMTP + records a communications row.
 *
 * Flow:
 *   1. confirm the user's sending_email
 *   2. communications INSERT (status='sending')
 *   3. createEmailTracking() -> obtain injectedHtml (pixel + tracking links)
 *   4. tabs-mailer.sendOne(bodyHtml: injectedHtml) -> obtain message-id
 *   5. communications UPDATE (status='sent', message_id, sent_at)
 *   6. on failure, status='failed' + error_message
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { sendOutboundEmail } from '@/lib/email/send-outbound';
import type { SendingAddressKind } from '@/types/email';

/* ──────────────────────────────────────────────────────────
 * Plain text -> HTML conversion (minimal conversion for pixel injection)
 * ────────────────────────────────────────────────────────── */

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Convert plain text into minimal HTML.
 * Blank lines separate paragraphs; normal lines are wrapped in <p> tags.
 */
function plainToHtml(text: string): string {
  const lines = text.split('\n');
  const parts: string[] = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === '') {
      parts.push('<br>');
    } else {
      parts.push(
        `<p style="margin:0 0 8px 0">${escapeHtml(trimmed)}</p>`,
      );
    }
  }
  return (
    `<div style="font-family:sans-serif;font-size:14px;line-height:1.6;color:#333">` +
    parts.join('\n') +
    `</div>`
  );
}

/* ──────────────────────────────────────────────────────────
 * Result type + input schema
 * ────────────────────────────────────────────────────────── */

export interface ComposeResult {
  ok: boolean;
  errorCode?:
    | 'unauthorized'
    | 'validation'
    | 'no_sending_email'
    | 'send_failed'
    | 'database'
    | 'not_whitelisted'
    | 'not_found';
  errorMessage?: string;
  /** the outbound communications row id on success */
  communicationId?: string;
}

const composeSchema = z.object({
  // Step 4: one or more recipients, comma/semicolon separated; each validated.
  to: z
    .string()
    .max(2000)
    .refine(
      (v) => {
        const parts = v.split(/[,;]/).map((s) => s.trim()).filter(Boolean);
        return (
          parts.length > 0 &&
          parts.every((p) => z.string().email().max(255).safeParse(p).success)
        );
      },
      { message: 'Invalid recipient email' },
    ),
  cc: z.string().max(2000).optional().or(z.literal('')),
  subject: z.string().min(1, 'Subject is required').max(500),
  bodyPlain: z.string().min(1, 'Body is required').max(50_000),
  /** Attach the org default signature (dialog toggle; default true). */
  useSignature: z.boolean().optional(),
  /** True when composed via the AI Draft tab -> communications.ai_generated. */
  aiGenerated: z.boolean().optional(),
  /** If a rich-text editor exists, HTML can be passed directly (otherwise bodyPlain -> auto-converted) */
  bodyHtml: z.string().max(200_000).optional().nullable(),
  /** Party link (if present, stored in communications.party_id) */
  partyId: z.string().uuid().optional().nullable(),
  contactId: z.string().uuid().optional().nullable(),
  /** Deal link (if present, stored in communications.deal_id; the DB trigger
   *  logs the message as an engagement on that deal's Activity timeline) */
  dealId: z.string().uuid().optional().nullable(),
  /** Starts a new thread - if null, the auto-generated message-id starts the thread */
  inReplyTo: z.string().max(500).optional().nullable(),
  threadId: z.string().max(500).optional().nullable(),
  /** D6-7b-2: which sending account to send from (default: shared = contact@) */
  fromKind: z.enum(['personal', 'role', 'shared']).optional().default('shared'),
  /** Step 4: explicit From account (app.inbound_mailboxes.id) from the dialog dropdown. */
  mailAccountId: z.string().uuid().optional().nullable(),
  attachments: z
    .array(
      z.object({
        path: z.string().max(500),
        filename: z.string().max(255),
        size: z.number().int().nonnegative(),
        mimeType: z.string().max(255),
      }),
    )
    .optional()
    .default([]),
});

/* ──────────────────────────────────────────────────────────
 * sendOutboundManual
 * ────────────────────────────────────────────────────────── */


/* ============================================================
 * D6-7b-2: kind-aware sender info resolution
 * ============================================================ */
type SenderInfo = { username: string; displayName: string };

function resolveSenderInfoForKind(kind: SendingAddressKind): SenderInfo {
  switch (kind) {
    case 'personal':
      return {
        username:    process.env.MAIL_PERSONAL_USERNAME ?? '',
        displayName: process.env.MAIL_PERSONAL_DISPLAY_NAME ?? 'YunYoung Heo',
      };
    case 'role':
      return {
        username:    process.env.MAIL_ROLE_USERNAME ?? '',
        displayName: process.env.MAIL_ROLE_DISPLAY_NAME ?? 'CEO',
      };
    case 'shared':
    default:
      return {
        username:    process.env.MAIL_SHARED_USERNAME ?? '',
        displayName: process.env.MAIL_SHARED_DISPLAY_NAME ?? 'Marinebio Group',
      };
  }
}
export async function sendOutboundManual(
  input: z.input<typeof composeSchema>,
): Promise<ComposeResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = composeSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // From identity (kind-aware; env MAIL_* with user-row fallback).
  const { data: userRaw } = await supabase
    .schema('app')
    .from('users' as never)
    .select('sending_email, full_name, email')
    .eq('id', auth.userId)
    .maybeSingle();
  const userRow = userRaw as
    | { sending_email: string | null; full_name: string; email: string }
    | null;

  const kind: SendingAddressKind = parsed.data.fromKind ?? 'shared';
  const senderInfo = resolveSenderInfoForKind(kind);
  const fromAddress =
    senderInfo.username || (userRow?.sending_email ?? userRow?.email ?? auth.email);
  const fromName =
    senderInfo.displayName || (userRow?.full_name ?? auth.email.split('@')[0] ?? 'Sender');

  const ccAddresses = (parsed.data.cc ?? '')
    .split(/[,;]/)
    .map((s) => s.trim())
    .filter((s) => /\S+@\S+\.\S+/.test(s));

  // Step 4: multi-recipient To (schema guarantees each part is a valid email)
  const toList = parsed.data.to
    .split(/[,;]/)
    .map((s) => s.trim())
    .filter(Boolean);

  // Delegate to the shared outbound core (Stage B). Whitelist, tracking,
  // insert(sending), sendOne, sent/failed update and attachment records all
  // live in the core now. Manual compose exposes no template/signature.
  const result = await sendOutboundEmail({
    supabase,
    organizationId: auth.organizationId,
    sentByUserId: auth.userId,
    to: toList[0] ?? parsed.data.to,
    toAdditional: toList.slice(1),
    cc: ccAddresses,
    fromName,
    fromAddress,
    sendingAddressKind: kind,
    mailAccountId: parsed.data.mailAccountId ?? null,
    subject: parsed.data.subject,
    bodyHtml: parsed.data.bodyHtml?.trim()
      ? parsed.data.bodyHtml
      : plainToHtml(parsed.data.bodyPlain),
    bodyText: parsed.data.bodyPlain,
    useSignature: parsed.data.useSignature ?? true,
    inReplyTo: parsed.data.inReplyTo ?? undefined,
    references: parsed.data.inReplyTo ? [parsed.data.inReplyTo] : undefined,
    partyId: parsed.data.partyId ?? null,
    contactId: parsed.data.contactId ?? null,
    dealId: parsed.data.dealId ?? null,
    threadId: parsed.data.threadId ?? null,
    attachments: parsed.data.attachments ?? [],
    aiGenerated: parsed.data.aiGenerated ?? false,
    traceLabel: `manual-compose:${auth.userId}`,
  });

  revalidatePath('/inbox');
  if (parsed.data.partyId) {
    revalidatePath(`/`, 'layout');
  }

  if (!result.ok) {
    const errorCode: ComposeResult['errorCode'] =
      result.errorCode === 'not_whitelisted'
        ? 'not_whitelisted'
        : result.errorCode === 'database'
          ? 'database'
          : 'send_failed';
    return { ok: false, errorCode, errorMessage: result.errorMessage };
  }

  return { ok: true, communicationId: result.communicationId };
}
