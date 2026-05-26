'use server';
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { cookies } from 'next/headers';

export interface UploadedAttachment {
  path: string;
  filename: string;
  size: number;
  mimeType: string;
}

export async function uploadAttachment(formData: FormData): Promise<UploadedAttachment> {
  const supabase = await createSupabaseServerClient();
  const file = formData.get('file') as File;
  if (!file) throw new Error('파일이 없습니다.');
  if (file.size > 25 * 1024 * 1024) throw new Error('25MB 초과 파일은 첨부 불가합니다.');

  const ext = file.name.split('.').pop() ?? 'bin';
  const rand = Math.random().toString(36).slice(2);
  const path = Date.now().toString() + '-' + rand + '.' + ext;
  const buffer = Buffer.from(await file.arrayBuffer());

  const { error } = await supabase.storage
    .from('email-attachments')
    .upload(path, buffer, { contentType: file.type || 'application/octet-stream', upsert: false });
  if (error) throw new Error('업로드 실패: ' + error.message);
  return { path, filename: file.name, size: file.size, mimeType: file.type };
}

export async function getAttachmentSignedUrl(path: string): Promise<string> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.storage
    .from('email-attachments').createSignedUrl(path, 3600);
  if (error) throw new Error('URL 생성 실패: ' + error.message);
  return data.signedUrl;
}

export async function deleteAttachment(path: string) {
  const supabase = await createSupabaseServerClient();
  await supabase.storage.from('email-attachments').remove([path]);
}