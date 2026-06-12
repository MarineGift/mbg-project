// src/app/actions/attachments.ts
'use server';

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
import { parseDriveLink } from '@/lib/attachments/drive';
import type {
  AddAttachmentInput,
  Attachment,
  AttachmentEntityType,
} from '@/types/attachments';

// Single-org deployment. Replace with your org-resolution helper if one exists.
const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169';

export async function listAttachments(
  entityType: AttachmentEntityType,
  entityId: string
): Promise<{ data: Attachment[]; error: string | null }> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('attachments')
    .select('*')
    .eq('entity_type', entityType)
    .eq('entity_id', entityId)
    .is('deleted_at', null)
    .order('uploaded_at', { ascending: false });

  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as Attachment[], error: null };
}

export async function addAttachment(
  input: AddAttachmentInput
): Promise<{ data: Attachment | null; error: string | null }> {
  const parsed = parseDriveLink(input.url);
  if (!parsed) {
    return { data: null, error: 'Invalid URL. Paste a full http(s) link.' };
  }

  const fileName =
    input.fileName.trim() ||
    (parsed.fileId ? `Drive file ${parsed.fileId}` : parsed.url);

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('attachments')
    .insert({
      organization_id: ORG_ID,
      entity_type: input.entityType,
      entity_id: input.entityId,
      file_name: fileName,
      file_size_bytes: 0,
      mime_type: parsed.mimeGuess,
      storage_provider: parsed.isGoogle ? 'google_drive' : 'external_url',
      storage_bucket: null,
      storage_path: parsed.url,
      description: input.description?.trim() || null,
    })
    .select('*')
    .single();

  if (error) return { data: null, error: error.message };
  revalidatePath('/', 'layout');
  return { data: data as Attachment, error: null };
}

export async function removeAttachment(
  id: string
): Promise<{ error: string | null }> {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('attachments')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id);

  if (error) return { error: error.message };
  revalidatePath('/', 'layout');
  return { error: null };
}
