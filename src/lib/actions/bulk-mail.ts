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
/** Default / max simultaneous sends (overlaps SMTP + DB latency). */
const DEFAULT_CONCURRENCY = 4;
const MAX_CONCURRENCY = 8;

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
  /** simultaneous sends (1..MAX_CONCURRENCY); default DEFAULT_CONCURRENCY. */
  concurrency?: number;
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
      concurrency: z.number().int().min(1).max(MAX_CONCURRENCY).optional(),
    })
    .safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const { templateId, source, mailAccountId, recipientMode, recentDays, bypassWhitelist, onlyKeys } = parsed.data;
  const cap = Math.min(parsed.data.limit ?? HARD_CAP, HARD_CAP);
  const concurrency = Math.min(
    Math.max(parsed.data.concurrency ?? DEFAULT_CONCURRENCY, 1),
    MAX_CONCURRENCY,
  );

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

  // Bounded-concurrency pool: send up to `concurrency` recipients at once
  // instead of strictly one-at-a-time. sendOutboundEmail is independent per
  // recipient (separate communications rows), and the SMTP transporter is
  // cached per account, so overlapping sends is safe. JS is single-threaded,
  // so the summary mutations below are not a data race.
  const sendOne = async (r: (typeof recipients)[number]): Promise<void> => {
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
  };

  let cursor = 0;
  const worker = async (): Promise<void> => {
    for (let idx = cursor++; idx < recipients.length; idx = cursor++) {
      const r = recipients[idx];
      if (r) await sendOne(r);
    }
  };
  const lanes = Math.min(concurrency, recipients.length);
  await Promise.all(Array.from({ length: Math.max(lanes, 0) }, () => worker()));

  return { ok: true, summary };
}

/* ============================================================
 * enqueueBulkMail - create a background run (drained by mailrun-worker)
 * ============================================================ */

export interface EnqueueResult extends BulkMailActionResult {
  runId?: string;
  total?: number;
}

export async function enqueueBulkMail(input: {
  templateId: string;
  source: BulkMailSource;
  mailAccountId: string;
  recipientMode?: RecipientMode;
  recentDays?: number;
  bypassWhitelist?: boolean;
  onlyKeys?: string[];
  ratePerMinute?: number;
  concurrency?: number;
  scheduledAt?: string;
}): Promise<EnqueueResult> {
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
      ratePerMinute: z.number().int().min(1).max(600).optional(),
      concurrency: z.number().int().min(1).max(MAX_CONCURRENCY).optional(),
      scheduledAt: z.string().datetime({ offset: true }).optional(),
    })
    .safeParse(input);
  if (!parsed.success) {
    return { ok: false, errorCode: 'validation', errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  const { templateId, source, mailAccountId, recipientMode, recentDays, bypassWhitelist, onlyKeys, scheduledAt } = parsed.data;
  if (scheduledAt) {
    const whenMs = new Date(scheduledAt).getTime();
    if (Number.isNaN(whenMs)) return { ok: false, errorCode: 'validation', errorMessage: 'Invalid scheduled time.' };
    if (whenMs < Date.now() - 60_000) return { ok: false, errorCode: 'validation', errorMessage: 'Scheduled time is in the past.' };
    if (whenMs > Date.now() + 90 * 24 * 3_600_000) return { ok: false, errorCode: 'validation', errorMessage: 'Scheduled time is too far out (max 90 days).' };
  }

  const supabase = await createSupabaseServerClient();

  // template snapshot (frozen at enqueue)
  const { data: tmplRaw, error: tErr } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .select('subject, body_html, body_plain')
    .eq('id', templateId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();
  if (tErr) return { ok: false, errorCode: 'database', errorMessage: tErr.message };
  if (!tmplRaw) return { ok: false, errorCode: 'not_found', errorMessage: 'Template not found' };
  const t = tmplRaw as { subject: string | null; body_html: string | null; body_plain: string | null };
  const snapshotSubject = t.subject ?? '';
  const snapshotBody = t.body_html && t.body_html.trim() ? t.body_html : (t.body_plain ?? '');

  // resolve recipients (server-side; client only narrows via onlyKeys)
  let preview;
  try {
    preview = await resolveBulkCandidates(supabase, auth.organizationId, templateId, source, recipientMode, { recentDays });
  } catch (err) {
    return { ok: false, errorCode: 'database', errorMessage: err instanceof Error ? err.message : 'Resolve failed' };
  }
  const only = onlyKeys ? new Set(onlyKeys) : null;
  const seen = new Set<string>();
  const recipients = preview.toSend.filter((c) => {
    if (!c.email || (only && !only.has(c.key))) return false;
    const e = c.email.toLowerCase();
    if (seen.has(e)) return false;
    seen.add(e);
    return true;
  });
  if (recipients.length === 0) {
    return { ok: false, errorCode: 'validation', errorMessage: 'No eligible recipients to queue.' };
  }

  const { data: runRaw, error: rErr } = await supabase
    .schema('app')
    .from('mail_runs' as never)
    .insert({
      organization_id: auth.organizationId,
      template_id: templateId,
      template_subject: snapshotSubject,
      template_body: snapshotBody,
      mail_account_id: mailAccountId,
      recipient_mode: recipientMode,
      bypass_whitelist: bypassWhitelist,
      rate_per_minute: parsed.data.ratePerMinute ?? 30,
      concurrency: Math.min(parsed.data.concurrency ?? DEFAULT_CONCURRENCY, MAX_CONCURRENCY),
      source_kind: source.mode,
      source_ref: source.mode === 'pipeline_stage' ? source.stageId : null,
      scheduled_at: scheduledAt ?? null,
      status: 'queued',
      total_count: recipients.length,
      created_by: auth.userId,
    } as never)
    .select('id')
    .single();
  if (rErr || !runRaw) return { ok: false, errorCode: 'database', errorMessage: rErr?.message ?? 'Run insert failed' };
  const runId = (runRaw as { id: string }).id;

  const rows = recipients.map((c) => ({
    organization_id: auth.organizationId,
    run_id: runId,
    party_id: c.partyId,
    contact_id: c.contactId,
    email: (c.email as string).toLowerCase(),
    status: 'pending',
  }));
  const { error: recErr } = await supabase
    .schema('app')
    .from('mail_run_recipients' as never)
    .insert(rows as never);
  if (recErr) {
    await supabase.schema('app').from('mail_runs' as never).delete().eq('id', runId);
    return { ok: false, errorCode: 'database', errorMessage: recErr.message };
  }

  return { ok: true, runId, total: recipients.length };
}

/* ============================================================
 * Run status (for the progress UI)
 * ============================================================ */

export interface MailRunStatus {
  id: string;
  status: string;
  total: number;
  sent: number;
  failed: number;
  blocked: number;
  createdAt: string;
  startedAt: string | null;
  completedAt: string | null;
}

const RUN_COLS =
  'id, status, total_count, sent_count, failed_count, blocked_count, created_at, started_at, completed_at';

interface RawRun {
  id: string;
  status: string;
  total_count: number;
  sent_count: number;
  failed_count: number;
  blocked_count: number;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
}
const mapRun = (r: RawRun): MailRunStatus => ({
  id: r.id,
  status: r.status,
  total: r.total_count,
  sent: r.sent_count,
  failed: r.failed_count,
  blocked: r.blocked_count,
  createdAt: r.created_at,
  startedAt: r.started_at,
  completedAt: r.completed_at,
});

export async function getMailRunStatus(
  runId: string,
): Promise<BulkMailActionResult & { run?: MailRunStatus }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  if (!z.string().uuid().safeParse(runId).success) {
    return { ok: false, errorCode: 'validation', errorMessage: 'Bad runId' };
  }
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('mail_runs' as never)
    .select(RUN_COLS)
    .eq('id', runId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();
  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  if (!data) return { ok: false, errorCode: 'not_found', errorMessage: 'Run not found' };
  return { ok: true, run: mapRun(data as unknown as RawRun) };
}

export async function listRecentMailRuns(
  limit = 10,
): Promise<BulkMailActionResult & { runs?: MailRunStatus[] }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }
  const n = Math.min(Math.max(limit, 1), 50);
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('mail_runs' as never)
    .select(RUN_COLS)
    .eq('organization_id', auth.organizationId)
    .order('created_at', { ascending: false })
    .limit(n);
  if (error) return { ok: false, errorCode: 'database', errorMessage: error.message };
  return { ok: true, runs: ((data ?? []) as unknown as RawRun[]).map(mapRun) };
}
