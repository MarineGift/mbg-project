// src/lib/attachments/drive.ts
// Pure helpers for parsing Google Drive / Docs share links. No dependencies.

export interface DriveLinkInfo {
  fileId: string | null;
  /** Normalized URL to store and open. */
  url: string;
  kind: 'file' | 'doc' | 'sheet' | 'slide' | 'folder' | 'unknown';
  /** Best-effort mime type guess for the attachments row. */
  mimeGuess: string;
  /** true when the URL belongs to Google Drive / Docs domains. */
  isGoogle: boolean;
}

const PATTERNS: Array<{
  re: RegExp;
  kind: DriveLinkInfo['kind'];
  mime: string;
}> = [
  {
    re: /docs\.google\.com\/document\/d\/([a-zA-Z0-9_-]+)/,
    kind: 'doc',
    mime: 'application/vnd.google-apps.document',
  },
  {
    re: /docs\.google\.com\/spreadsheets\/d\/([a-zA-Z0-9_-]+)/,
    kind: 'sheet',
    mime: 'application/vnd.google-apps.spreadsheet',
  },
  {
    re: /docs\.google\.com\/presentation\/d\/([a-zA-Z0-9_-]+)/,
    kind: 'slide',
    mime: 'application/vnd.google-apps.presentation',
  },
  {
    re: /drive\.google\.com\/drive\/folders\/([a-zA-Z0-9_-]+)/,
    kind: 'folder',
    mime: 'application/vnd.google-apps.folder',
  },
  {
    re: /drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)/,
    kind: 'file',
    mime: 'application/octet-stream',
  },
  {
    re: /drive\.google\.com\/open\?id=([a-zA-Z0-9_-]+)/,
    kind: 'file',
    mime: 'application/octet-stream',
  },
];

/**
 * Parse a pasted URL. Returns DriveLinkInfo for any http(s) URL,
 * with isGoogle=false (provider 'url') when it is not a Drive link.
 * Returns null when the input is not a valid http(s) URL at all.
 */
export function parseDriveLink(raw: string): DriveLinkInfo | null {
  const input = raw.trim();
  if (!/^https?:\/\//i.test(input)) return null;

  for (const p of PATTERNS) {
    const m = input.match(p.re);
    if (m) {
      return {
        fileId: m[1] ?? null,
        url: input,
        kind: p.kind,
        mimeGuess: p.mime,
        isGoogle: true,
      };
    }
  }

  return {
    fileId: null,
    url: input,
    kind: 'unknown',
    mimeGuess: 'text/uri-list',
    isGoogle: false,
  };
}

/** Short human label for an attachment row, e.g. for icon selection. */
export function mimeLabel(mime: string): string {
  if (mime.includes('spreadsheet')) return 'Sheet';
  if (mime.includes('document')) return 'Doc';
  if (mime.includes('presentation')) return 'Slides';
  if (mime.includes('folder')) return 'Folder';
  if (mime.includes('pdf')) return 'PDF';
  if (mime.startsWith('image/')) return 'Image';
  if (mime === 'text/uri-list') return 'Link';
  return 'File';
}
