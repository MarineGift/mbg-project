'use server';
import { randomUUID } from 'node:crypto';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { requireAuth } from '@/lib/auth';
import { toStorageKeySegment } from '@/lib/email/mailcarrier';

const BUCKET = 'email-attachments';
const MAX_BYTES = 25 * 1024 * 1024;

export interface UploadedAttachment {
  path: string;
  filename: string;
  size: number;
  mimeType: string;
}

/** Guard: an object path must live under the caller's organization prefix. */
function assertOwnedPath(path: string, organizationId: string): void {
  if (!path.startsWith(`${organizationId}/`)) {
    throw new Error('Forbidden: attachment path does not belong to your organization.');
  }
}

export async function uploadAttachment(formData: FormData): Promise<UploadedAttachment> {
  const auth = await requireAuth();
  const supabase = await createSupabaseServerClient();

  const file = formData.get('file') as File | null;
  if (!file) throw new Error('No file provided.');
  if (file.size > MAX_BYTES) throw new Error('File exceeds the 25MB limit.');

  const safeName = toStorageKeySegment(file.name);
  const path = `${auth.organizationId}/${randomUUID()}-${safeName}`;
  const buffer = Buffer.from(await file.arrayBuffer());

  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(path, buffer, {
      contentType: file.type || 'application/octet-stream',
      upsert: false,
    });
  if (error) throw new Error('Upload failed: ' + error.message);

  return { path, filename: file.name, size: file.size, mimeType: file.type };
}

export async function getAttachmentSignedUrl(path: string): Promise<string> {
  const auth = await requireAuth();
  assertOwnedPath(path, auth.organizationId);
  const supabase = await createSupabaseServerClient();

  const { data, error } = await supabase.storage
    .from(BUCKET)
    .createSignedUrl(path, 3600);
  if (error) throw new Error('Signed URL generation failed: ' + error.message);
  return data.signedUrl;
}

export async function deleteAttachment(path: string): Promise<void> {
  const auth = await requireAuth();
  assertOwnedPath(path, auth.organizationId);
  const supabase = await createSupabaseServerClient();

  const { error } = await supabase.storage.from(BUCKET).remove([path]);
  if (error) throw new Error('Delete failed: ' + error.message);
}