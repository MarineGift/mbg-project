// src/lib/utils/email-tracking.ts
// Inject tracking pixel + wrap tracked links into outbound HTML emails

import type { TrackingPayload } from '@/types/phase21';

const BASE_URL =
  process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, '') ?? 'http://localhost:3000';

/** 1×1 transparent GIF — used by the pixel API route */
export const PIXEL_GIF_B64 =
  'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';

// ── Link extraction ──────────────────────────────────────────

/**
 * Extract all unique http/https hrefs from an HTML string.
 * Skips mailto: anchors and already-tracked /api/track/ paths.
 */
export function extractLinks(html: string): string[] {
  const seen = new Set<string>();
  const results: string[] = [];
  const re = /href=["']([^"']+)["']/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null) {
    const url = m[1]!;
    if (
      !seen.has(url) &&
      (url.startsWith('http://') || url.startsWith('https://')) &&
      !url.includes('/api/track/')
    ) {
      seen.add(url);
      results.push(url);
    }
  }
  return results;
}

// ── Injection ────────────────────────────────────────────────

/**
 * Given a rendered HTML body and a TrackingPayload from `create_email_tracking`,
 * this function:
 *  1. Replaces each original link href with the click-tracking redirect URL
 *  2. Appends a 1×1 tracking pixel before </body> (or at the end)
 *
 * Call AFTER `createEmailTracking()` so you have the token map.
 */
export function injectTracking(html: string, payload: TrackingPayload): string {
  let result = html;

  // 1. Wrap links
  for (const link of payload.links) {
    const clickUrl = `${BASE_URL}/api/track/click/${link.token}`;
    // replaceAll: same URL may appear multiple times in the body
    result = result.split(link.url).join(clickUrl);
  }

  // 2. Pixel
  const pixelUrl = `${BASE_URL}/api/track/open/${payload.open_token}`;
  const pixel = `<img src="${pixelUrl}" width="1" height="1" alt="" style="display:none;width:1px;height:1px;border:0;opacity:0" />`;

  if (result.includes('</body>')) {
    result = result.replace('</body>', `${pixel}</body>`);
  } else if (result.includes('</html>')) {
    result = result.replace('</html>', `${pixel}</html>`);
  } else {
    result += pixel;
  }

  return result;
}

/** Build just the pixel URL (useful for testing / plain-text footer links) */
export function buildPixelUrl(openToken: string): string {
  return `${BASE_URL}/api/track/open/${openToken}`;
}

/** Build a single click-redirect URL from a link token */
export function buildClickUrl(linkToken: string): string {
  return `${BASE_URL}/api/track/click/${linkToken}`;
}
