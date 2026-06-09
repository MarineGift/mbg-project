// src/lib/web/inbox.ts
// Server queries powering the integrated admin inbox: every submission from
// every site in one view, with site name joined in-memory (no PostgREST embed).

import { createClient } from '@supabase/supabase-js';

function webClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );
}

export interface InboxRow {
  id: string;
  site_id: string;
  site_name: string;
  form_type: string;
  name: string | null;
  email: string | null;
  company: string | null;
  interest: string | null;
  message: string | null;
  status: string;
  created_at: string;
}

export interface InboxFilter {
  site_id?: string;
  status?: string;
  search?: string;
  limit?: number;
}

export async function listSubmissions(f: InboxFilter = {}): Promise<InboxRow[]> {
  const sb = webClient();

  // site name lookup (small table) -> in-memory join
  const { data: siteRows } = await sb
    .schema('web')
    .from('sites' as never)
    .select('id,name');
  const siteName = new Map(
    ((siteRows ?? []) as Array<{ id: string; name: string }>).map((s) => [s.id, s.name]),
  );

  let q = sb
    .schema('web')
    .from('submissions' as never)
    .select('id,site_id,form_type,name,email,company,interest,message,status,created_at')
    .order('created_at', { ascending: false })
    .limit(f.limit ?? 100);

  if (f.site_id) q = q.eq('site_id', f.site_id);
  if (f.status) q = q.eq('status', f.status);
  if (f.search) q = q.or(`name.ilike.%${f.search}%,email.ilike.%${f.search}%,company.ilike.%${f.search}%`);

  const { data } = await q;
  return ((data ?? []) as unknown as Omit<InboxRow, 'site_name'>[]).map((r) => ({
    ...r,
    site_name: siteName.get(r.site_id) ?? 'Unknown',
  }));
}

export async function setSubmissionStatus(id: string, status: string): Promise<void> {
  const sb = webClient();
  await sb
    .schema('web')
    .from('submissions' as never)
    .update({ status } as never)
    .eq('id', id);
}

// Reply hook: record the reply, then hand off to the CRM mail core.
// Wire `sendOutboundEmail` from the existing pipeline where marked.
export async function replyToSubmission(args: {
  submission_id: string;
  to: string;
  subject: string;
  body: string;
  sent_by?: string;
}): Promise<{ ok: boolean; error?: string }> {
  const sb = webClient();

  const { data: reply, error: insErr } = await sb
    .schema('web')
    .from('submission_replies' as never)
    .insert({
      submission_id: args.submission_id,
      subject: args.subject,
      body: args.body,
      sent_by: args.sent_by ?? null,
      status: 'queued',
    } as never)
    .select('id')
    .single();
  if (insErr || !reply) return { ok: false, error: 'could not queue reply' };

  // ---- CRM integration point -------------------------------------------
  // import { sendOutboundEmail } from '@/lib/email/send';
  // const sent = await sendOutboundEmail({ to: args.to, subject: args.subject, html: args.body });
  // await sb.schema('web').from('submission_replies' as never)
  //   .update({ status: 'sent', email_message_id: sent.messageId } as never)
  //   .eq('id', (reply as { id: string }).id);
  // ----------------------------------------------------------------------

  await setSubmissionStatus(args.submission_id, 'replied');
  return { ok: true };
}
