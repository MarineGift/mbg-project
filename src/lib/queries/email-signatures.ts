'use server';
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { cookies } from 'next/headers';

export interface EmailSignature {
  id: string;
  organization_id: string;
  name: string;
  html_content: string;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

export async function getSignatures(orgId: string): Promise<EmailSignature[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app').from('email_signatures' as never).select('*').eq('organization_id', orgId)
    .order('is_default', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getDefaultSignature(orgId: string): Promise<EmailSignature | null> {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .schema('app').from('email_signatures' as never).select('*')
    .eq('organization_id', orgId).eq('is_default', true).maybeSingle();
  return data;
}

export async function upsertSignature(
  sig: Partial<EmailSignature> & { organization_id: string }
): Promise<EmailSignature> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app').from('email_signatures' as never).upsert(sig as unknown as never, { onConflict: 'id' }).select().single();
  if (error) throw error;
  return data;
}

export async function deleteSignature(id: string) {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.schema('app').from('email_signatures' as never).delete().eq('id', id);
  if (error) throw error;
}

export async function setDefaultSignature(id: string, orgId: string) {
  const supabase = await createSupabaseServerClient();
  await supabase.schema('app').from('email_signatures' as never)
    .update({ is_default: false } as never).eq('organization_id', orgId).eq('is_default', true);
  const { error } = await supabase.schema('app').from('email_signatures' as never)
    .update({ is_default: true } as never).eq('id', id);
  if (error) throw error;
}