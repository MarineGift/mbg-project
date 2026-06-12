// src/lib/attachments/google-drive.ts
// Google Drive helpers for attachment upload/download.
// Reuses the calendar OAuth infrastructure (calendar_connections +
// token-crypto): same Google account, same refresh flow, plus the
// drive.file scope added to GOOGLE_SCOPES in google-client.ts.

import {
  getActiveConnections,
  updateAccessToken,
  type DecryptedConnection,
} from '@/lib/calendar/token-crypto';
import {
  refreshGoogleToken,
  isTokenExpired,
} from '@/lib/calendar/google-client';

const DRIVE_FILES = 'https://www.googleapis.com/drive/v3/files';
const DRIVE_UPLOAD = 'https://www.googleapis.com/upload/drive/v3/files';
const DRIVE_SCOPE = 'https://www.googleapis.com/auth/drive.file';

/** Root folder in the connected Drive under which URM stores uploads. */
export const DRIVE_ROOT_FOLDER = 'URM Attachments';

export interface DriveUploadResult {
  id: string;
  name: string;
  mimeType: string;
  size: number;
  webViewLink: string;
}

/** True for Docs/Sheets/Slides etc. -- no binary content to stream. */
export function isGoogleNativeMime(mime: string): boolean {
  return mime.startsWith('application/vnd.google-apps');
}

/**
 * Returns a fresh access token from the org's active Google connection
 * that carries the drive.file scope. Throws a descriptive error when the
 * account has not been (re)connected with the Drive scope yet.
 */
export async function getDriveAccessToken(
  organizationId: string
): Promise<{ accessToken: string; accountEmail: string }> {
  const conns = await getActiveConnections(organizationId);
  const google: DecryptedConnection | undefined = conns.find(
    (c) => c.provider === 'google' && (c.scopes ?? []).includes(DRIVE_SCOPE)
  );
  if (!google) {
    throw new Error(
      'Google Drive is not connected. Go to Settings > Calendar and reconnect the Google account to grant Drive access.'
    );
  }

  let token = google.access_token;
  if (isTokenExpired(google.expires_at)) {
    if (!google.refresh_token) {
      throw new Error('Google connection has no refresh token. Reconnect the account.');
    }
    const refreshed = await refreshGoogleToken(google.refresh_token);
    token = refreshed.access_token;
    await updateAccessToken(
      google.id,
      refreshed.access_token,
      new Date(Date.now() + refreshed.expires_in * 1000)
    );
  }

  return { accessToken: token, accountEmail: google.account_email };
}

function escapeDriveQuery(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

/** Find a folder by name (optionally under a parent); create when missing. */
export async function ensureDriveFolder(
  accessToken: string,
  name: string,
  parentId?: string
): Promise<string> {
  const qParts = [
    `name = '${escapeDriveQuery(name)}'`,
    "mimeType = 'application/vnd.google-apps.folder'",
    'trashed = false',
  ];
  if (parentId) qParts.push(`'${parentId}' in parents`);

  const searchUrl =
    `${DRIVE_FILES}?q=${encodeURIComponent(qParts.join(' and '))}` +
    '&fields=files(id,name)&pageSize=1&spaces=drive';
  const found = await fetch(searchUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!found.ok) {
    throw new Error(`Drive folder search failed ${found.status}: ${await found.text()}`);
  }
  const data = (await found.json()) as { files?: Array<{ id: string }> };
  if (data.files && data.files.length > 0) return data.files[0]!.id;

  const created = await fetch(`${DRIVE_FILES}?fields=id`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name,
      mimeType: 'application/vnd.google-apps.folder',
      ...(parentId ? { parents: [parentId] } : {}),
    }),
  });
  if (!created.ok) {
    throw new Error(`Drive folder create failed ${created.status}: ${await created.text()}`);
  }
  const folder = (await created.json()) as { id: string };
  return folder.id;
}

/** Multipart upload of a binary file into the given folder. */
export async function uploadToDrive(
  accessToken: string,
  opts: { name: string; mimeType: string; data: Buffer; folderId: string }
): Promise<DriveUploadResult> {
  const boundary = 'urm_attachment_' + Math.random().toString(36).slice(2);
  const metadata = JSON.stringify({
    name: opts.name,
    parents: [opts.folderId],
  });

  const head = Buffer.from(
    `--${boundary}\r\n` +
      'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
      metadata +
      `\r\n--${boundary}\r\n` +
      `Content-Type: ${opts.mimeType || 'application/octet-stream'}\r\n\r\n`,
    'utf-8'
  );
  const tail = Buffer.from(`\r\n--${boundary}--`, 'utf-8');
  const body = Buffer.concat([head, opts.data, tail]);

  const res = await fetch(
    `${DRIVE_UPLOAD}?uploadType=multipart&fields=id,name,mimeType,size,webViewLink`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': `multipart/related; boundary=${boundary}`,
        'Content-Length': String(body.length),
      },
      body,
    }
  );
  if (!res.ok) {
    throw new Error(`Drive upload failed ${res.status}: ${await res.text()}`);
  }
  const file = (await res.json()) as {
    id: string;
    name: string;
    mimeType: string;
    size?: string;
    webViewLink?: string;
  };
  return {
    id: file.id,
    name: file.name,
    mimeType: file.mimeType,
    size: file.size ? Number(file.size) : opts.data.length,
    webViewLink:
      file.webViewLink ?? `https://drive.google.com/file/d/${file.id}/view`,
  };
}

/** Stream a binary file's content (not for Google-native Docs/Sheets). */
export async function fetchDriveFileContent(
  accessToken: string,
  fileId: string
): Promise<Response> {
  const res = await fetch(`${DRIVE_FILES}/${encodeURIComponent(fileId)}?alt=media`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    throw new Error(`Drive download failed ${res.status}: ${await res.text()}`);
  }
  return res;
}
