// src/lib/utils/email-tracking.ts
// Inject tracking pixel into outbound HTML emails.
//
// CLICK-LINK REWRITING IS DISABLED (A-fix): rewriting visible hrefs to a
// redirect on our own domain (link cloaking — displayed URL != actual href)
// triggers Gmail's "552 5.7.0 ... content presents a potential security issue"
// block, which bounced our outbound to Gmail recipients. We keep open-pixel
// tracking only. To re-enable click tracking safely, either (a) use a reputable
// dedicated tracking domain AND keep anchor text == href, or (b) switch to TABS
// Mailer campaign tracking (X-TABS-Campaign + MailRead.ashx).

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
 *
 * Still used by createEmailTracking() to RECORD links for reporting, even though
 * injectTracking() no longer rewrites them into the body.
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
 * appends a 1×1 open-tracking pixel before </body> (or at the end).
 *
 * Click-link rewriting is intentionally omitted — see the file header.
 *
 * Call AFTER `createEmailTracking()` so you have the open token.
 */
export function injectTracking(html: string, payload: TrackingPayload): string {
  let result = html;

  // [A-fix] Click-link cloaking DISABLED to avoid Gmail 552 5.7.0 content block.
  // Previous behavior (removed):
  //   for (const link of payload.links) {
  //     const clickUrl = `${BASE_URL}/api/track/click/${link.token}`;
  //     result = result.split(link.url).join(clickUrl);
  //   }

  // Open-tracking pixel only.
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
