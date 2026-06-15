/**
 * lib/actions/bulk-mail.ts
 *
 * Server actions for the bulk mailing system (Fork A).
 *
 *   previewBulkMail  -- resolve candidates + dedup + whitelist status, no send.
 *   sendBulkMail     -- batch loop over sendOutboundEmail (-> TabsMailer.sendOne).
 *
 * Design (locked 2026-06-15):
 *   - stage<->template mapping: none; operator picks pipeline -> stage -> template.
 *   - recipients: per-party primary contact, or ALL contacts with an email.
 *   - dedup: communications.template_id + party_id (permanent per template),
 *     plus an optional recency guard (any outbound email in the last N days).
 *   - From: app.inbound_mailboxes account chosen by the operator (mailAccountId).
 *   - whitelist: not hardcoded; bypassWhitelist is an explicit operator choice,
 *     default respects the whitelist. The preview reports per-recipient status.
 *   - architecture (V1): synchronous sequential batch, hard-capped, gentle
 *     pacing. Large runs / a queue worker are V2.
 *
 * Recipients are ALWAYS re-resolved server-side at send time; the client never
 * supplies recipient emails (it may only narrow the set via onlyKeys).
 */

'use server';

import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { sendOutboundEmail } from '@/lib/email/send-outbound';
import { listMailAccountOptions } from '@/lib/actions/mail-account-options';
import {
  resolveBulkCandidates,
  type BulkMailPreview,
  type BulkMailSource,
  type RecipientMode,
} from '@/lib/queries/bulk-mail';

/** V1 safety ceiling per invocation (a server action, not a worker). */
const HARD_CAP = 100;
/** ms between sends - gentle pacing for the shared SMTP host. */
const SEND_PACING_MS = 150;

const sourceSchema = z.discriminatedUnion('mode', [
  z.object({ mode: z.literal('pipeline_stage'), stageId: z.string().uuid() }),
  z.object({ mode: z.literal('parties'), partyIds: z.array(z.string().uuid()).min(1) }),
]);
const recipientModeSchema = z.enum(['primary', 'all_contacts']);
const dedupSchema = z.object({ recentDays: z.number().int().min(0).max(3650).optional() }).optional();

export interface BulkMailActionResult {
  ok: boolean;
  errorCode?: 'unauthorized' | 'validation' | 'no_mail_account' | 'not_found' | 'database';
  errorMessage?: string;
}

/* ============================================================
 * previewBulkMail
 * ============================================================ */

export async function previewBulkMail(input: {
  templateId: string;
  source: BulkMailSource;
  recipientMode?: RecipientMode;
  recentDays?: number;
}): Promise<BulkMailActionResult & { preview?: BulkMailPreview }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = z
    .object({
      templateId: z.string().uuid(),
      source: sourceSchema,
      recipientMode: recipientModeSchema.optional().default('primary'),
      recentDays: z.number().int().min(0).max(3650).optional(),
    })
    .safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }

  const supabase = await createSupabaseServerClient();
  try {
    const preview = await resolveBulkCandidates(
      supabase,
      auth.organizationId,
      parsed.data.templateId,
      parsed.data.source,
      parsed.data.recipientMode,
      { recentDays: parsed.data.recentDays },
    );
    return { ok: true, preview };
  } catch (err) {
    return { ok: false, errorCode: 'database', errorMessage: err instanceof Error ? err.message : 'Preview failed' };
  }
}

/* ============================================================
 * sendBulkMail
 * ============================================================ */

export interface BulkMailSendResultRow {
  key: string;
  partyId: string;
  email: string;
  status: 'sent' | 'failed' | 'blocked';
  error?: string;
}

export interface BulkMailSendSummary {
  runId: string;
  attempted: number;
  sent: number;
  failed: number;
  blocked: number;
  /** true when eligible recipients exceeded the cap (remainder not sent). */
  capped: boolean;
  results: BulkMailSendResultRow[];
}

export async function sendBulkMail(input: {
  templateId: string;
  source: BulkMailSource;
  mailAccountId: string;
  recipientMode?: RecipientMode;
  recentDays?: number;
  /** explicit operator opt-out of the per-recipient whitelist guard. */
  bypassWhitelist?: boolean;
  /** restrict the send to a confirmed subset of recipient keys. */
  onlyKeys?: string[];
  /** per-call cap; hard-limited to HARD_CAP regardless of value. */
  limit?: number;
}): Promise<BulkMailActionResult & { summary?: BulkMailSendSummary }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = z
    .object({
      templateId: z.string().uuid(),
      source: sourceSchema,
      mailAccountId: z.string().uuid(),
      recipientMode: recipientModeSchema.optional().default('primary'),
      recentDays: z.number().int().min(0).max(3650).optional(),
      bypassWhitelist: z.boolean().optional().default(false),
      onlyKeys: z.array(z.string()).optional(),
      limit: z.number().int().positive().optional(),
    })
    .safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const { templateId, source, mailAccountId, recipientMode, recentDays, bypassWhitelist, onlyKeys } = parsed.data;
  const cap = Math.min(parsed.data.limit ?? HARD_CAP, HARD_CAP);

  const supabase = await createSupabaseServerClient();

  // From account (address + display name); must be an active configured account.
  const acctRes = await listMailAccountOptions();
  const account = acctRes.accounts.find((a) => a.id === mailAccountId);
  if (!account) {
    return { ok: false, errorCode: 'no_mail_account', errorMessage: 'Selected mail account not found (no active SMTP accounts?).' };
  }

  // Template subject (the body is rendered from merge.templateId by the send core).
  const { data: tmplRaw, error: tmplErr } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .select('subject')
    .eq('id', templateId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();
  if (tmplErr) return { ok: false, errorCode: 'database', errorMessage: tmplErr.message };
  if (!tmplRaw) return { ok: false, errorCode: 'not_found', errorMessage: 'Template not found' };
  const templateSubject = (tmplRaw as { subject: string | null }).subject ?? '';

  // Re-resolve candidates server-side (never trust a client recipient list).
  let preview: BulkMailPreview;
  try {
    preview = await resolveBulkCandidates(
      supabase,
      auth.organizationId,
      templateId,
      source,
      recipientMode,
      { recentDays },
    );
  } catch (err) {
    return { ok: false, errorCode: 'database', errorMessage: err instanceof Error ? err.message : 'Resolve failed' };
  }

  const only = onlyKeys ? new Set(onlyKeys) : null;
  const eligible = preview.toSend.filter((c) => c.email && (!only || only.has(c.key)));
  const recipients = eligible.slice(0, cap);

  const runId = crypto.randomUUID();
  const summary: BulkMailSendSummary = {
    runId,
    attempted: 0,
    sent: 0,
    failed: 0,
    blocked: 0,
    capped: eligible.length > recipients.length,
    results: [],
  };

  for (const r of recipients) {
    const email = r.email as string;
    summary.attempted += 1;

    const res = await sendOutboundEmail({
      supabase,
      organizationId: auth.organizationId,
      sentByUserId: auth.userId,
      to: email,
      fromName: account.displayName ?? account.address,
      fromAddress: account.address,
      mailAccountId: account.id,
      subject: templateSubject,
      bodyHtml: '', // ignored: merge.templateId provides the body
      merge: { partyId: r.partyId, contactId: r.contactId ?? undefined, templateId },
      partyId: r.partyId,
      contactId: r.contactId,
      dealId: r.dealId,
      useSignature: true,
      skipWhitelist: bypassWhitelist,
      externalData: { source: 'bulk', mail_run_id: runId, template_id: templateId },
      traceLabel: `bulk:${runId}`,
    });

    const status: BulkMailSendResultRow['status'] =
      res.status === 'sent' ? 'sent' : res.status === 'blocked' ? 'blocked' : 'failed';
    if (status === 'sent') summary.sent += 1;
    else if (status === 'blocked') summary.blocked += 1;
    else summary.failed += 1;

    summary.results.push({ key: r.key, partyId: r.partyId, email, status, error: res.errorMessage });

    if (SEND_PACING_MS > 0) {
      await new Promise<void>((resolve) => setTimeout(resolve, SEND_PACING_MS));
    }
  }

  return { ok: true, summary };
}
