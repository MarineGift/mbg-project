'use server';
// src/lib/actions/sequence-sender.ts
//
// Sender selection + send-document preview for email sequences.
// Kept separate from email-sequences.ts so the create_sequence / update_sequence
// RPCs are untouched. The From dropdown reuses the same account source as the
// compose/reply dialog (listMailAccountOptions -> app.inbound_mailboxes).

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { renderMergeFields } from '@/lib/utils/merge-fields';
import { revalidatePath } from 'next/cache';

/* ----------------------------------------------------------------
 * from_account_id read / write (direct, no RPC)
 * from_account_id is not in the generated Database types yet, so the
 * query builder is cast (same `as unknown as` pattern used elsewhere).
 * ---------------------------------------------------------------- */

export async function getSequenceFromAccountId(
  sequenceId: string,
): Promise<{ accountId: string | null } | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (
    supabase.schema('app').from('email_sequences') as unknown as {
      select: (c: string) => {
        eq: (
          k: string,
          v: string,
        ) => {
          maybeSingle: () => Promise<{
            data: { from_account_id: string | null } | null;
            error: { message: string } | null;
          }>;
        };
      };
    }
  )
    .select('from_account_id')
    .eq('id', sequenceId)
    .maybeSingle();

  if (error) return { error: error.message };
  return { accountId: data?.from_account_id ?? null };
}

export async function setSequenceFromAccount(
  sequenceId: string,
  accountId: string | null,
): Promise<{ ok: true } | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { error } = await (
    supabase.schema('app').from('email_sequences') as unknown as {
      update: (vals: Record<string, unknown>) => {
        eq: (k: string, v: string) => Promise<{ error: { message: string } | null }>;
      };
    }
  )
    .update({ from_account_id: accountId })
    .eq('id', sequenceId);

  if (error) return { error: error.message };
  revalidatePath('/settings/email-sequences');
  return { ok: true };
}

type SequenceQuietHours = { timezone: string; start: string; end: string; weekends_blocked: boolean };

export async function getSequenceQuietHours(
  sequenceId: string,
): Promise<{ quietHours: SequenceQuietHours | null } | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (
    supabase.schema('app').from('email_sequences') as unknown as {
      select: (c: string) => {
        eq: (k: string, v: string) => {
          maybeSingle: () => Promise<{
            data: { quiet_hours: SequenceQuietHours | null } | null;
            error: { message: string } | null;
          }>;
        };
      };
    }
  )
    .select('quiet_hours')
    .eq('id', sequenceId)
    .maybeSingle();

  if (error) return { error: error.message };
  return { quietHours: data?.quiet_hours ?? null };
}

export async function setSequenceQuietHours(
  sequenceId: string,
  quietHours: SequenceQuietHours | null,
): Promise<{ ok: true } | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { error } = await (
    supabase.schema('app').from('email_sequences') as unknown as {
      update: (vals: Record<string, unknown>) => {
        eq: (k: string, v: string) => Promise<{ error: { message: string } | null }>;
      };
    }
  )
    .update({ quiet_hours: quietHours })
    .eq('id', sequenceId);

  if (error) return { error: error.message };
  revalidatePath('/settings/email-sequences');
  return { ok: true };
}

/* ----------------------------------------------------------------
 * Step preview
 * Renders a step with representative sample data so merge tokens fill,
 * then appends the org default signature - the same signature
 * sendOutboundEmail attaches on the real send.
 * ---------------------------------------------------------------- */

// Flat key map: renderMergeFields looks up the literal token (e.g.
// "contact.firstName"), not nested objects. Covers the tokens the editor
// advertises so the preview shows realistic personalization.
const PREVIEW_SAMPLE: Record<string, string> = {
  'party.name': 'Acme Ventures',
  'party.countryCode': 'US',
  'party.website': 'acme.vc',
  'contact.fullName': 'Alex Kim',
  'contact.firstName': 'Alex',
  'contact.email': 'alex@acme.vc',
  'my.name': 'YunYoung Heo',
  'my.email': 'yunyoung.heo@marinebiogroup.com',
};

export async function getSequenceStartAt(sequenceId: string) {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await (supabase.schema('app').from('email_sequences') as any)
    .select('start_at').eq('id', sequenceId).maybeSingle();
  if (error) return { error: error.message as string };
  return { startAt: (data?.start_at ?? null) as string | null };
}

export async function setSequenceStartAt(sequenceId: string, startAt: string | null) {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase.schema('app').from('email_sequences') as any)
    .update({ start_at: startAt }).eq('id', sequenceId);
  if (error) return { error: error.message as string };
  revalidatePath('/settings/email-sequences');
  return { ok: true as const };
}

export async function previewSequenceStep(input: {
  orgId: string;
  subject: string;
  bodyPlain: string;
}): Promise<{ subject: string; html: string } | { error: string }> {
  const supabase = await createSupabaseServerClient();

  const subject = renderMergeFields(input.subject || '', PREVIEW_SAMPLE);
  const bodyRendered = renderMergeFields(input.bodyPlain || '', PREVIEW_SAMPLE);
  let html = plainToHtml(bodyRendered);

  const { data: sigRow } = await supabase
    .schema('app')
    .from('email_signatures')
    .select('html_content')
    .eq('organization_id', input.orgId)
    .eq('is_default', true)
    .maybeSingle();
  const sig = (sigRow as { html_content: string | null } | null)?.html_content ?? null;
  if (sig) {
    html = `${html}<br><br><hr style="border:none;border-top:1px solid #e5e7eb;margin:16px 0">${sig}`;
  }

  return { subject, html };
}

function plainToHtml(plain: string): string {
  if (!plain) return '';
  const escaped = plain
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
  return escaped
    .split(/\n\n+/)
    .map((p) => `<p>${p.replace(/\n/g, '<br/>')}</p>`)
    .join('\n');
}
