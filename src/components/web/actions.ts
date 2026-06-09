'use server';
// src/components/web/actions.ts
// Server action invoked by public form sections. Inserts into the unified
// web.submissions inbox. Uses service role (RLS allows anon insert anyway,
// but server keeps IP/host trustworthy). Lightweight honeypot + validation.

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
    } as never);

  if (error) return { ok: false, error: 'could not save' };
  return { ok: true };
}
