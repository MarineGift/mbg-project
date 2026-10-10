'use server';

/**
 * lib/actions/mail-run-detail.ts
 *
 * getMailRunDetail -- one bulk mail run (app.mail_runs) with every recipient
 * row (app.mail_run_recipients) joined in memory to party name / party type,
 * template name and sending account. Used by the run detail dialog on
 * /marketing and /mailing.
 */

import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { listMailAccountOptions } from '@/lib/actions/mail-account-options';

export interface MailRunRecipientRow {
  id: string;
  partyId: string | null;
  partyName: string;
  partyTypeCode: string | null;
  email: string;
  status: string;
  error: string | null;
  sentAt: string | null;
  communicationId: string | null;
}

export interface MailRunDetail {
  id: string;
  status: string;
  templateName: string | null;
  subject: string;
  fromAddress: string | null;
  recipientMode: string | null;
  sourceKind: string | null;
  bypassWhitelist: boolean;
  ratePerMinute: number | null;
  total: number;
  sent: number;
  failed: number;
  blocked: number;
  createdAt: string;
  scheduledAt: string | null;
  startedAt: string | null;
  completedAt: string | null;
  recipients: MailRunRecipientRow[];
}

const PAGE = 1000;

export async function getMailRunDetail(
  runId: string,
): Promise<{ ok: boolean; errorMessage?: string; detail?: MailRunDetail }> {
  let auth;
  try {
    auth = await requireAuth();
  } catch {
    return { ok: false, errorMessage: 'Not signed in.' };
  }
  if (!z.string().uuid().safeParse(runId).success) return { ok: false, errorMessage: 'Bad run id' };

  const supabase = await createSupabaseServerClient();
  const db = supabase.schema('app');

  const { data: runRaw, error: runErr } = await db
    .from('mail_runs' as never)
    .select(
      'id, status, template_id, template_subject, mail_account_id, recipient_mode, source_kind, bypass_whitelist, rate_per_minute, total_count, sent_count, failed_count, blocked_count, created_at, scheduled_at, started_at, completed_at',
    )
    .eq('id', runId)
    .eq('organization_id', auth.organizationId)
    .maybeSingle();
  if (runErr) return { ok: false, errorMessage: runErr.message };
  if (!runRaw) return { ok: false, errorMessage: 'Run not found' };
  const run = runRaw as {
    id: string; status: string; template_id: string | null; template_subject: string | null;
    mail_account_id: string | null; recipient_mode: string | null; source_kind: string | null;
    bypass_whitelist: boolean | null; rate_per_minute: number | null; total_count: number;
    sent_count: number; failed_count: number; blocked_count: number; created_at: string;
    scheduled_at: string | null; started_at: string | null; completed_at: string | null;
  };

  // recipients (paginated)
  type RawRec = {
    id: string; party_id: string | null; email: string | null; status: string;
    error: string | null; sent_at: string | null; communication_id: string | null;
  };
  const recs: RawRec[] = [];
  for (let from = 0; from < 50_000; from += PAGE) {
    const { data, error } = await db
      .from('mail_run_recipients' as never)
      .select('id, party_id, email, status, error, sent_at, communication_id')
      .eq('run_id', runId)
      .order('id', { ascending: true })
      .range(from, from + PAGE - 1);
    if (error) return { ok: false, errorMessage: error.message };
    const rows = (data ?? []) as unknown as RawRec[];
    recs.push(...rows);
    if (rows.length < PAGE) break;
  }

  // party names + type codes (chunked in-filters)
  const partyIds = Array.from(new Set(recs.map((r) => r.party_id).filter(Boolean) as string[]));
  const partyById = new Map<string, { name: string; typeId: number | null }>();
  for (let i = 0; i < partyIds.length; i += 150) {
    const { data } = await db
      .from('parties' as never)
      .select('id, party_name, party_type_id')
      .eq('organization_id', auth.organizationId)
      .in('id', partyIds.slice(i, i + 150));
    for (const p of (data ?? []) as Array<{ id: string; party_name: string | null; party_type_id: number | null }>) {
      partyById.set(p.id, { name: p.party_name ?? '', typeId: p.party_type_id });
    }
  }
  const { data: ptRaw } = await db.from('party_types' as never).select('id, code');
  const codeById = new Map<number, string>();
  for (const t of (ptRaw ?? []) as Array<{ id: number; code: string }>) codeById.set(t.id, t.code);

  let templateName: string | null = null;
  if (run.template_id) {
    const { data } = await db.from('email_templates' as never).select('name').eq('id', run.template_id).maybeSingle();
    templateName = (data as { name: string } | null)?.name ?? null;
  }

  let fromAddress: string | null = null;
  if (run.mail_account_id) {
    const acc = await listMailAccountOptions();
    fromAddress = acc.accounts.find((a) => a.id === run.mail_account_id)?.address ?? null;
  }

  const order: Record<string, number> = { failed: 0, blocked: 1, sending: 2, pending: 3, sent: 4 };
  const recipients: MailRunRecipientRow[] = recs
    .map((r) => {
      const p = r.party_id ? partyById.get(r.party_id) : undefined;
      return {
        id: r.id,
        partyId: r.party_id,
        partyName: p?.name ?? '',
        partyTypeCode: p?.typeId != null ? (codeById.get(p.typeId) ?? null) : null,
        email: r.email ?? '',
        status: r.status,
        error: r.error,
        sentAt: r.sent_at,
        communicationId: r.communication_id,
      };
    })
    .sort((a, b) => (order[a.status] ?? 9) - (order[b.status] ?? 9) || a.partyName.localeCompare(b.partyName));

  return {
    ok: true,
    detail: {
      id: run.id,
      status: run.status,
      templateName,
      subject: run.template_subject ?? '',
      fromAddress,
      recipientMode: run.recipient_mode,
      sourceKind: run.source_kind,
      bypassWhitelist: !!run.bypass_whitelist,
      ratePerMinute: run.rate_per_minute,
      total: run.total_count,
      sent: run.sent_count,
      failed: run.failed_count,
      blocked: run.blocked_count,
      createdAt: run.created_at,
      scheduledAt: run.scheduled_at,
      startedAt: run.started_at,
      completedAt: run.completed_at,
      recipients,
    },
  };
}
