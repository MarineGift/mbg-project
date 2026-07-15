/**
 * lib/actions/drafts.ts
 *
 * Server Actions for the AI draft review screen.
 *
 * Security/integration principles:
 *   - call requireAuth() as the first line of every action
 *   - RLS auto-isolates by organization_id (a separate .eq isn't required, but added explicitly too)
 *   - status check: approve/reject/edit allowed only for pending_review
 *   - audit logging is automatic via a DB trigger
 *
 * Send strategy (Phase 1):
 *   - approveDraft({ sendImmediately: true })   -> immediate synchronous SMTP send
 *   - approveDraft({ sendImmediately: false })  -> status='approved' only, send handled later
 *   - bulkApproveDrafts(ids)                    -> bulk 'approved' only, no send (safety)
 *
 * Sender address (Step 1.2):
 *   - sendingAddressKind: 'personal' | 'role' | 'shared'
 *   - the From is determined from the user's email_personal / email_role / email_shared columns
 *   - tabs-mailer authenticates SMTP with the same kind credentials (SPF/DKIM consistency)
 */

'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth, type AuthContext } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { sendOutboundEmail } from '@/lib/email/send-outbound';
import type { RejectReason } from '@/types/draft-detail';
import type { SendingAddressKind } from '@/types/email';

/* ============================================================
 * Shared types
 * ============================================================ */

export interface ActionResult<T = void> {
  ok: boolean;
  data?: T;
  errorCode?:
    | 'unauthorized'
    | 'not_found'
    | 'invalid_status'
    | 'validation'
    | 'send_failed'
    | 'database'
    | 'unknown';
  errorMessage?: string;
}

export interface BulkActionResult {
  ok: boolean;
  succeeded: string[];
  failed: Array<{ id: string; errorCode: string; errorMessage: string }>;
}

/* ============================================================
 * 1. saveDraftEdits - save body/subject edits
 * ============================================================ */

const saveDraftEditsSchema = z.object({
  draftId: z.string().uuid(),
  subject: z.string().min(1).max(500).optional().nullable(),
  bodyPlain: z.string().min(1).max(50_000),
});

export async function saveDraftEdits(input: {
  draftId: string;
  subject?: string | null;
  bodyPlain: string;
}): Promise<ActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = saveDraftEditsSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // status check - only pending_review is editable
  const { data: current, error: fetchErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .select('status')
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();

  if (fetchErr || !current) {
    return { ok: false, errorCode: 'not_found' };
  }
  if ((current as { status: string }).status !== 'pending_review') {
    return {
      ok: false,
      errorCode: 'invalid_status',
      errorMessage: 'Draft is not in pending_review status',
    };
  }

  // edit_distance is computed automatically by the 013 migration trigger
  const { error: updateErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      final_subject: parsed.data.subject ?? null,
      final_body_plain: parsed.data.bodyPlain,
    } as never)
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId);

  if (updateErr) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: updateErr.message,
    };
  }

  revalidatePath(`/drafts/${parsed.data.draftId}`);
  revalidatePath('/drafts');
  return { ok: true };
}

/* ============================================================
 * 2. approveDraft - approve (option: send immediately)
 * ============================================================ */

const approveDraftSchema = z.object({
  draftId: z.string().uuid(),
  sendImmediately: z.boolean().default(false),
  sendingAddressKind: z.enum(['personal', 'role', 'shared']).optional(),
});

export async function approveDraft(input: {
  draftId: string;
  sendImmediately?: boolean;
  sendingAddressKind?: SendingAddressKind;
}): Promise<ActionResult<{ sent: boolean; outboundCommunicationId?: string }>> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = approveDraftSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();

  // fetch the current status + all fields needed for sending
  const { data, error: fetchErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .select(
      'id, status, subject, final_subject, body_plain, final_body_plain, body_html, inbound_communication_id, party_id',
    )
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();

  if (fetchErr || !data) {
    return { ok: false, errorCode: 'not_found' };
  }
  const row = data as {
    id: string;
    status: string;
    subject: string | null;
    final_subject: string | null;
    body_plain: string;
    final_body_plain: string | null;
    body_html: string | null;
    inbound_communication_id: string | null;
    party_id: string | null;
  };

  if (row.status !== 'pending_review') {
    return {
      ok: false,
      errorCode: 'invalid_status',
      errorMessage: `Draft status is ${row.status}; only pending_review can be approved`,
    };
  }

  // [A] update status='approved' first
  const nowIso = new Date().toISOString();
  const { error: approveErr } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'approved',
      reviewed_by_user_id: auth.userId,
      reviewed_at: nowIso,
    } as never)
    .eq('id', row.id)
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review'); // concurrency guard - 0 rows if another request changed it first

  if (approveErr) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: approveErr.message,
    };
  }

  // [B] not sending immediately -> done
  if (!parsed.data.sendImmediately) {
    revalidatePath(`/drafts/${row.id}`);
    revalidatePath('/', 'layout');
    revalidatePath('/drafts');
    return { ok: true, data: { sent: false } };
  }

  // [C] send immediately - an inbound is required to determine the recipient
  if (!row.inbound_communication_id) {
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage:
        'Cannot send: original inbound message is unknown (no inbound_communication_id)',
    };
  }

  // attempt to send (passing the selected kind)
  const sendResult = await sendApprovedDraft(
    supabase,
    auth,
    row,
    parsed.data.sendingAddressKind,
  );
  if (!sendResult.ok) {
    // status stays 'approved' - the user can retry
    return sendResult;
  }

  revalidatePath(`/drafts/${row.id}`);
  revalidatePath('/', 'layout');
  revalidatePath('/drafts');
  return {
    ok: true,
    data: {
      sent: true,
      outboundCommunicationId: sendResult.data?.outboundCommunicationId,
    },
  };
}

/* ============================================================
 * 3. rejectDraft - reject (4 preset reasons + 'other')
 * ============================================================ */

const rejectDraftSchema = z.object({
  draftId: z.string().uuid(),
  reason: z.enum(['outdated_request', 'off_topic', 'wrong_tone', 'incorrect_info', 'other']),
  notes: z.string().max(2000).optional(),
});

export async function rejectDraft(input: {
  draftId: string;
  reason: RejectReason;
  notes?: string;
}): Promise<ActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorCode: 'unauthorized' };
  }

  const parsed = rejectDraftSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  // review_notes - store preset + custom combined (no DB column -> per the Q5 decision)
  const reviewNotes = [
    `[${parsed.data.reason}]`,
    parsed.data.notes?.trim() ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  const supabase = await createSupabaseServerClient();
  const { error, count } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'rejected',
      reviewed_by_user_id: auth.userId,
      reviewed_at: new Date().toISOString(),
      review_notes: reviewNotes,
    } as never)
    .eq('id', parsed.data.draftId)
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review');

  if (error) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error.message,
    };
  }
  // if count is 0, someone else already handled it (race)
  if (count === 0) {
    return {
      ok: false,
      errorCode: 'invalid_status',
      errorMessage: 'Draft already processed',
    };
  }

  revalidatePath('/', 'layout');
  revalidatePath(`/drafts/${parsed.data.draftId}`);
  revalidatePath('/drafts');
  return { ok: true };
}

/* ============================================================
 * 4. bulkApproveDrafts / bulkRejectDrafts - bulk actions
 *    Does not send. Safety first.
 *    Rows being edited (final_body_plain not null) should be excluded, but
 *    the caller (UI) passes only an array of IDs already excluded.
 * ============================================================ */

const bulkIdsSchema = z.array(z.string().uuid()).min(1).max(100);

export async function bulkApproveDrafts(
  draftIds: readonly string[],
): Promise<BulkActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return {
      ok: false,
      succeeded: [],
      failed: draftIds.map((id) => ({
        id,
        errorCode: 'unauthorized',
        errorMessage: 'Sign-in required',
      })),
    };
  }

  const parsed = bulkIdsSchema.safeParse(draftIds);
  if (!parsed.success) {
    return {
      ok: false,
      succeeded: [],
      failed: draftIds.map((id) => ({
        id,
        errorCode: 'validation',
        errorMessage: 'Invalid id list',
      })),
    };
  }

  const supabase = await createSupabaseServerClient();
  const nowIso = new Date().toISOString();

  // a single UPDATE changes only the eligible rows; the rest are confirmed via RETURNING
  const { data: updated, error } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'approved',
      reviewed_by_user_id: auth.userId,
      reviewed_at: nowIso,
    } as never)
    .in('id', parsed.data as string[])
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review')
    .select('id');

  if (error) {
    return {
      ok: false,
      succeeded: [],
      failed: parsed.data.map((id) => ({
        id,
        errorCode: 'database',
        errorMessage: error.message,
      })),
    };
  }

  const succeededIds = new Set(
    ((updated ?? []) as Array<{ id: string }>).map((r) => r.id),
  );
  const failed = parsed.data
    .filter((id) => !succeededIds.has(id))
    .map((id) => ({
      id,
      errorCode: 'invalid_status',
      errorMessage: 'Already processed or not in pending_review',
    }));

  revalidatePath('/', 'layout');
  revalidatePath('/drafts');
  return {
    ok: failed.length === 0,
    succeeded: Array.from(succeededIds),
    failed,
  };
}

const bulkRejectSchema = z.object({
  draftIds: z.array(z.string().uuid()).min(1).max(100),
  reason: z.enum(['outdated_request', 'off_topic', 'wrong_tone', 'incorrect_info', 'other']),
  notes: z.string().max(2000).optional(),
});

export async function bulkRejectDrafts(input: {
  draftIds: readonly string[];
  reason: RejectReason;
  notes?: string;
}): Promise<BulkActionResult> {
  let auth: AuthContext;
  try {
    auth = await requireAuth();
  } catch {
    return {
      ok: false,
      succeeded: [],
      failed: input.draftIds.map((id) => ({
        id,
        errorCode: 'unauthorized',
        errorMessage: 'Sign-in required',
      })),
    };
  }

  const parsed = bulkRejectSchema.safeParse({
    draftIds: input.draftIds,
    reason: input.reason,
    notes: input.notes,
  });
  if (!parsed.success) {
    return {
      ok: false,
      succeeded: [],
      failed: input.draftIds.map((id) => ({
        id,
        errorCode: 'validation',
        errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
      })),
    };
  }

  const reviewNotes = [`[${parsed.data.reason}]`, parsed.data.notes?.trim() ?? '']
    .filter(Boolean)
    .join(' ');

  const supabase = await createSupabaseServerClient();
  const { data: updated, error } = await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'rejected',
      reviewed_by_user_id: auth.userId,
      reviewed_at: new Date().toISOString(),
      review_notes: reviewNotes,
    } as never)
    .in('id', parsed.data.draftIds as string[])
    .eq('organization_id', auth.organizationId)
    .eq('status', 'pending_review')
    .select('id');

  if (error) {
    return {
      ok: false,
      succeeded: [],
      failed: parsed.data.draftIds.map((id) => ({
        id,
        errorCode: 'database',
        errorMessage: error.message,
      })),
    };
  }

  const succeededIds = new Set(
    ((updated ?? []) as Array<{ id: string }>).map((r) => r.id),
  );
  const failed = parsed.data.draftIds
    .filter((id) => !succeededIds.has(id))
    .map((id) => ({
      id,
      errorCode: 'invalid_status',
      errorMessage: 'Already processed or not in pending_review',
    }));

  revalidatePath('/', 'layout');
  revalidatePath('/drafts');
  return {
    ok: failed.length === 0,
    succeeded: Array.from(succeededIds),
    failed,
  };
}

/* ============================================================
 * 5. Send helper - Approve & Send
 *    Call TABS Mailer + INSERT an outbound communication + update draft status='sent'
 *
 *    Step 1.2 changes:
 *    - takes a sendingAddressKind parameter
 *    - looks up the email_personal/role/shared columns from the user row
 *    - determines fromAddress based on kind (includes a fallback chain)
 *    - passes sendingAddressKind when calling mailer.sendOne
 * ============================================================ */

interface DraftSendableRow {
  id: string;
  subject: string | null;
  final_subject: string | null;
  body_plain: string;
  final_body_plain: string | null;
  body_html: string | null;
  inbound_communication_id: string | null;
  party_id: string | null;
}

interface SendApprovedResult
  extends ActionResult<{ sent: boolean; outboundCommunicationId: string }> {}

/**
 * Determine the sender address based on kind.
 * If a kind is specified and the corresponding column has a value, use it.
 * Otherwise the fallback chain: personal -> role -> shared -> sending_email -> email -> auth.email
 */
function resolveFromAddress(
  kind: SendingAddressKind | undefined,
  userRow: {
    email_personal: string | null;
    email_role: string | null;
    email_shared: string | null;
    sending_email: string | null;
    email: string;
  } | null,
  authEmail: string,
): string {
  if (kind === 'personal' && userRow?.email_personal) return userRow.email_personal;
  if (kind === 'role' && userRow?.email_role) return userRow.email_role;
  if (kind === 'shared' && userRow?.email_shared) return userRow.email_shared;

  return (
    userRow?.email_personal ??
    userRow?.email_role ??
    userRow?.email_shared ??
    userRow?.sending_email ??
    userRow?.email ??
    authEmail
  );
}

async function sendApprovedDraft(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  auth: AuthContext,
  draft: DraftSendableRow,
  sendingAddressKind?: SendingAddressKind,
): Promise<SendApprovedResult> {
  if (!draft.inbound_communication_id) {
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: 'No inbound communication linked',
    };
  }

  // 1. inbound communication info (recipient / thread / subject)
  const { data: inboundRaw } = await supabase
    .schema('app')
    .from('communications' as never)
    .select('from_address, from_name, subject, message_id, thread_id, channel')
    .eq('id', draft.inbound_communication_id)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();
  const inbound = inboundRaw as
    | {
        from_address: string | null;
        from_name: string | null;
        subject: string | null;
        message_id: string | null;
        thread_id: string | null;
        channel: string;
      }
    | null;
  if (!inbound || !inbound.from_address) {
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: 'Inbound recipient address unknown',
    };
  }

  // 2. sender identity (DB-column kind resolution; caller-side, decision c)
  const { data: userRaw } = await supabase
    .schema('app')
    .from('users' as never)
    .select('email, sending_email, full_name, email_personal, email_role, email_shared')
    .eq('id', auth.userId)
    .maybeSingle();
  const userRow = userRaw as
    | {
        email: string;
        sending_email: string | null;
        full_name: string | null;
        email_personal: string | null;
        email_role: string | null;
        email_shared: string | null;
      }
    | null;
  const fromAddress = resolveFromAddress(sendingAddressKind, userRow, auth.email);
  const fromName = userRow?.full_name ?? auth.email.split('@')[0] ?? 'Sender';

  // 3. subject / body (edited version wins)
  const finalSubject = draft.final_subject ?? draft.subject ?? `Re: ${inbound.subject ?? ''}`;
  const finalBody = draft.final_body_plain ?? draft.body_plain;

  // 4. delegate to the shared outbound core (Stage B). This closes the AI-path
  //    gaps vs the verified contract: recipient whitelist, app-level tracking,
  //    default signature, real In-Reply-To/References wire headers, failure
  //    persisted to error_message, and urmHeaders.autoSend=true.
  const result = await sendOutboundEmail({ sendClass: 'direct',
    supabase,
    organizationId: auth.organizationId,
    sentByUserId: auth.userId,
    to: inbound.from_address,
    fromName,
    fromAddress,
    sendingAddressKind,
    subject: finalSubject,
    bodyHtml: draft.body_html ?? '',
    bodyText: finalBody,
    useSignature: true,
    inReplyTo: inbound.message_id ?? undefined,
    references: inbound.message_id ? [inbound.message_id] : undefined,
    partyId: draft.party_id,
    threadId: inbound.thread_id,
    autoSend: true,
    aiGenerated: true,
    aiDraftId: draft.id,
    traceLabel: `approve-and-send:${draft.id}`,
  });

  if (!result.ok || !result.communicationId) {
    // The communications row is already 'failed' + error_message (core).
    // Leave the draft in 'approved' so the operator can retry.
    return {
      ok: false,
      errorCode: 'send_failed',
      errorMessage: result.errorMessage ?? 'Send failed',
    };
  }

  // 5. link draft -> sent communication
  await supabase
    .schema('ai')
    .from('drafts' as never)
    .update({
      status: 'sent',
      sent_communication_id: result.communicationId,
    } as never)
    .eq('id', draft.id)
    .eq('organization_id', auth.organizationId);

  return {
    ok: true,
    data: { sent: true, outboundCommunicationId: result.communicationId },
  };
}
