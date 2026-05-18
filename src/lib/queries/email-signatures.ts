'use server';
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';

export interface EmailSignature {
  id: string;
  org_id: string;
  name: string;
  html: string;
  plain_text: string;
  is_default: boolean;
}

export async function getSignatures(orgId: string): Promise<EmailSignature[]> {
  const supabase = createServerComponentClient({ cookies });
  const { data, error } = await supabase
    .from('email_signatures').select('*').eq('org_id', orgId)
    .order('is_default', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getDefaultSignature(orgId: string): Promise<EmailSignature | null> {
  const supabase = createServerComponentClient({ cookies });
  const { data } = await supabase
    .from('email_signatures').select('*')
    .eq('org_id', orgId).eq('is_default', true).maybeSingle();
  return data;
}

export async function upsertSignature(
  sig: Partial<EmailSignature> & { org_id: string }
): Promise<EmailSignature> {
  const supabase = createServerComponentClient({ cookies });
  const { data, error } = await supabase
    .from('email_signatures').upsert(sig, { onConflict: 'id' }).select().single();
  if (error) throw error;
  return data;
}

export async function deleteSignature(id: string) {
  const supabase = createServerComponentClient({ cookies });
  const { error } = await supabase.from('email_signatures').delete().eq('id', id);
  if (error) throw error;
}

export async function setDefaultSignature(id: string, orgId: string) {
  const supabase = createServerComponentClient({ cookies });
  await supabase.from('email_signatures')
    .update({ is_default: false }).eq('org_id', orgId).eq('is_default', true);
  const { error } = await supabase.from('email_signatures')
    .update({ is_default: true }).eq('id', id);
  if (error) throw error;
}