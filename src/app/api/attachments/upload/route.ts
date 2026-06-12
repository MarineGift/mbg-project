// src/app/api/attachments/upload/route.ts
// POST multipart/form-data: file, entityType, entityId, description?, folderLabel?
// Uploads the file to Google Drive (URM Attachments/<folderLabel>) using the
// org's connected Google account, then records it in app.attachments.

import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import {
  DRIVE_ROOT_FOLDER,
  ensureDriveFolder,
  getDriveAccessToken,
  uploadToDrive,
} from '@/lib/attachments/google-drive';

export const runtime = 'nodejs';

const MAX_BYTES = 25 * 1024 * 1024; // 25 MB
const ALLOWED_ENTITY_TYPES = new Set([
  'deal',
  'deal_checklist',
  'task',
  'engagement',
  'party',
  'communication',
  'meeting',
  'consultation',
]);

export async function POST(req: NextRequest) {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Org from app.users -- same source of truth as the calendar callback.
    const { data: appUser } = await supabase
      .schema('app')
      .from('users')
      .select('organization_id')
      .eq('id', user.id)
      .single();
    const orgId = (appUser as { organization_id?: string } | null)?.organization_id;
    if (!orgId) {
      return NextResponse.json({ error: 'No organization' }, { status: 403 });
    }

    const form = await req.formData();
    const file = form.get('file');
    const entityType = String(form.get('entityType') ?? '');
    const entityId = String(form.get('entityId') ?? '');
    const description = String(form.get('description') ?? '').trim() || null;
    const folderLabel = String(form.get('folderLabel') ?? '').trim();

    if (!(file instanceof File)) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }
    if (!ALLOWED_ENTITY_TYPES.has(entityType) || !entityId) {
      return NextResponse.json({ error: 'Invalid entityType/entityId' }, { status: 400 });
    }
    if (file.size === 0) {
      return NextResponse.json({ error: 'Empty file' }, { status: 400 });
    }
    if (file.size > MAX_BYTES) {
      return NextResponse.json(
        { error: 'File exceeds the 25 MB limit' },
        { status: 413 }
      );
    }

    const { accessToken } = await getDriveAccessToken(orgId);

    // URM Attachments / <folderLabel or entityType>
    const rootId = await ensureDriveFolder(accessToken, DRIVE_ROOT_FOLDER);
    const subName = folderLabel || entityType;
    const folderId = await ensureDriveFolder(accessToken, subName, rootId);

    const data = Buffer.from(await file.arrayBuffer());
    const uploaded = await uploadToDrive(accessToken, {
      name: file.name,
      mimeType: file.type || 'application/octet-stream',
      data,
      folderId,
    });

    // Insert through the user's client so RLS applies.
    // NOTE: payload cast follows the codebase's `as never` idiom -- the
    // generated Database types predate the drive_file_id column (33_*.sql).
    // Regenerating supabase types removes the need for this cast.
    const payload = {
      organization_id: orgId,
      entity_type: entityType,
      entity_id: entityId,
      file_name: uploaded.name,
      file_size_bytes: uploaded.size,
      mime_type: uploaded.mimeType,
      storage_provider: 'google_drive',
      storage_bucket: null,
      storage_path: uploaded.webViewLink,
      drive_file_id: uploaded.id,
      description,
      uploaded_by: user.id,
    };
    const { data: row, error } = await supabase
      .schema('app')
      .from('attachments')
      .insert(payload as never)
      .select('*')
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    return NextResponse.json({ data: row });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Upload failed';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
