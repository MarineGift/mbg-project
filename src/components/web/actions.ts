'use server';
// src/components/web/actions.ts
// Server actions for web submissions, replies, commerce

import { headers } from 'next/headers';
import { createClient } from '@supabase/supabase-js';
import type { SubmissionInput } from '@/lib/web/types';

function webClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );
}

export interface SubmitResult {
  ok: boolean;
  error?: string;
}

// ============= SUBMISSIONS =============

export async function submitForm(
  input: SubmissionInput & { _hp?: string },
): Promise<SubmitResult> {
  // honeypot: real users never fill _hp
  if (input._hp) return { ok: true };

  if (!input.site_id) return { ok: false, error: 'missing site' };
  if (!input.email && !input.message && !input.name) {
    return { ok: false, error: 'empty submission' };
  }
  if (input.email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(input.email)) {
    return { ok: false, error: 'invalid email' };
  }

  const h = headers();
  const sb = webClient();
  const { error } = await sb
    .schema('web')
    .from('submissions' as never)
    .insert({
      site_id: input.site_id,
      page_id: input.page_id ?? null,
      form_type: input.form_type ?? 'contact',
      name: input.name ?? null,
      email: input.email ?? null,
      phone: input.phone ?? null,
      company: input.company ?? null,
      interest: input.interest ?? null,
      message: input.message ?? null,
      data: input.data ?? {},
      source_host: h.get('host') ?? null,
      user_agent: h.get('user-agent') ?? null,
      ip: h.get('x-forwarded-for') ?? null,
    } as never);

  if (error) return { ok: false, error: 'could not save' };
  return { ok: true };
}

export interface ReplyInput {
  submission_id: string;
  subject: string;
  body: string;
  sent_by: string;
}

export async function replyToSubmission(input: ReplyInput): Promise<SubmitResult> {
  if (!input.submission_id || !input.subject || !input.body) {
    return { ok: false, error: 'missing fields' };
  }

  const sb = webClient();

  // 1. Insert reply
  const { data: reply, error: replyError } = await sb
    .schema('web')
    .from('submission_replies')
    .insert({
      submission_id: input.submission_id,
      subject: input.subject,
      body: input.body,
      sent_by: input.sent_by,
      status: 'sent',
    } as never)
    .select()
    .single();

  if (replyError) {
    console.error('[replyToSubmission] insert failed:', replyError);
    return { ok: false, error: 'could not save reply' };
  }

  // 2. Update submission status to 'replied'
  const { error: updateError } = await sb
    .schema('web')
    .from('submissions')
    .update({ status: 'replied' })
    .eq('id', input.submission_id);

  if (updateError) {
    console.error('[replyToSubmission] status update failed:', updateError);
  }

  // 3. Send email (optional - integrate with sendOutboundEmail if available)
  try {
    // Fetch submission for context
    const { data: submission } = await sb
      .schema('web')
      .from('submissions')
      .select('email, name')
      .eq('id', input.submission_id)
      .single();

    if (submission?.email) {
      // Could call sendOutboundEmail here
      // For now, just log
      console.log(`[replyToSubmission] would email ${submission.email} with subject: ${input.subject}`);
    }
  } catch (e) {
    console.error('[replyToSubmission] email send failed:', e);
  }

  return { ok: true };
}

// ============= COMMERCE (stubs) =============

export async function addToCart(
  _productId: string,
  _quantity: number,
): Promise<SubmitResult> {
  // Stub for future implementation
  return { ok: true };
}

export async function createOrder(
  _cartId: string,
  _email: string,
): Promise<SubmitResult> {
  // Stub - integrate with payment processor
  return { ok: true };
}

export async function createPledge(
  _campaignId: string,
  _tierId: string,
  _amount: number,
): Promise<SubmitResult> {
  // Stub for crowdfunding
  return { ok: true };
}
