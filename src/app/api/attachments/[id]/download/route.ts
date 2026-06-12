// src/app/api/attachments/[id]/download/route.ts
// GET: downloads an attachment.
//  - google_drive uploads (drive_file_id set, binary mime): streams content
//    through the server with a proper Content-Disposition filename.
//  - Google-native files (Docs/Sheets/Slides) and link-only attachments:
//    redirects to the stored URL.

import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import {
  fetchDriveFileContent,
  getDriveAccessToken,
  isGoogleNativeMime,
} from '@/lib/attachments/google-drive';

export const runtime = 'nodejs';

interface AttachmentRow {
  id: string;
  organization_id: string;
  file_name: string;
  mime_type: string;
  storage_provider: string;
  storage_path: string;
  drive_file_id: string | null;
  deleted_at: string | null;
}

export async function GET(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // RLS scopes this to the user's organization.
    const { data, error } = await supabase
      .schema('app')
      .from('attachments')
      .select(
        'id, organization_id, file_name, mime_type, storage_provider, storage_path, drive_file_id, deleted_at'
      )
      .eq('id', params.id)
      .is('deleted_at', null)
      .single();

    if (error || !data) {
      return NextResponse.json({ error: 'Attachment not found' }, { status: 404 });
    }
    const att = data as AttachmentRow;

    const canStream =
      att.storage_provider === 'google_drive' &&
      att.drive_file_id &&
      !isGoogleNativeMime(att.mime_type);

    if (!canStream) {
      if (att.storage_path && /^https?:\/\//i.test(att.storage_path)) {
        return NextResponse.redirect(att.storage_path);
      }
      return NextResponse.json(
        { error: 'This attachment has no downloadable content' },
        { status: 422 }
      );
    }

    const { accessToken } = await getDriveAccessToken(att.organization_id);
    const driveRes = await fetchDriveFileContent(accessToken, att.drive_file_id!);

    const headers = new Headers();
    headers.set('Content-Type', att.mime_type || 'application/octet-stream');
    headers.set(
      'Content-Disposition',
      `attachment; filename*=UTF-8''${encodeURIComponent(att.file_name)}`
    );
    const len = driveRes.headers.get('content-length');
    if (len) headers.set('Content-Length', len);

    return new NextResponse(driveRes.body, { status: 200, headers });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Download failed';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
