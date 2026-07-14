/**
 * lib/email/ndr-outcome.ts
 *
 * Pure NDR (Non-Delivery Report) parsing for the send-outcome log
 * (app.email_send_outcomes). Complements lib/email/bounce-parser.ts:
 *
 *   bounce-parser.detectBounce  -> PERMANENT (5xx) only, feeds the blocklist.
 *   ndr-outcome.detectNdrOutcome -> hard (5xx) AND soft (4xx), feeds the
 *                                   outcome log so soft failures are visible
 *                                   on /mailing/outcomes without suppressing.
 *
 * Detection (any of):
 *   - From: mailer-daemon@ / postmaster@ (address or display name)
 *   - Subject: Undeliverable / Delivery Status Notification / Mail delivery
 *     failed / 전송 실패 / 배달 실패 / 반송
 *   - Content-Type: multipart/report; report-type=delivery-status
 *   - DSN body fields (Final-Recipient / Action: failed / Diagnostic-Code)
 *
 * Recipient extraction order (never the daemon's own From):
 *   1. Final-Recipient / Original-Recipient (RFC 3464)
 *   2. RCPT TO:<...>
 *   3. <email> or bare email on/near a 5xx / 4xx SMTP status line
 *
 * Severity:
 *   - hard: enhanced status 5.x.x or basic 55x anywhere in subject/body
 *   - soft: otherwise, enhanced 4.x.x or basic 4xx (421/450/451/452...)
 *   - neither code found -> null (conservative: do not record).
 *
 * Pure module (no I/O) - unit-testable, importable by worker + actions.
 */

import type { InboundForSuppression } from './bounce-parser';

export type BounceSeverity = 'hard' | 'soft';

export interface NdrOutcome {
  /** failed recipient address(es), lowercased, own addresses excluded */
  recipients: string[];
  severity: BounceSeverity;
  /** first SMTP code seen, e.g. "550" / "5.2.1" / "421" (evidence only) */
  smtpCode: string | null;
  /** short evidence string (subject), for email_send_outcomes.reason */
  evidence: string;
}

const EMAIL_INNER = '[^\\s<>@"]+@[^\\s<>@"]+\\.[^\\s<>@".]+';

/** permanent: enhanced 5.x.x OR basic 55x */
const HARD_RE = /\b5\.\d{1,3}\.\d{1,3}\b|\b55[0-4]\b/;
/** transient: enhanced 4.x.x OR basic 4xx SMTP reply (421-459) */
const SOFT_RE = /\b4\.\d{1,3}\.\d{1,3}\b|\b4[2-5]\d\b/;

function stripHtml(h: string): string {
  return h
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ');
}

function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase().replace(/^<+|>+$/g, '');
}

function ownSet(own?: string[]): Set<string> {
  return new Set((own ?? []).map((s) => s.trim().toLowerCase()).filter(Boolean));
}

function isOwn(email: string, own: Set<string>): boolean {
  const e = email.toLowerCase();
  const domain = e.split('@')[1] ?? '';
  return own.has(e) || (domain.length > 0 && own.has(domain));
}

function looksLikeNdr(input: InboundForSuppression, body: string): boolean {
  const from = input.fromAddress.toLowerCase();
  const daemon =
    /(^|[<\s])(mailer-daemon|postmaster|maildelivery|mail-?delivery)@/i.test(from) ||
    /mailer-?daemon|postmaster/i.test(`${input.fromName ?? ''}`);
  const subjectHit =
    /delivery status notification|undeliverable|undelivered mail|mail delivery (failed|subsystem)|delivery (failure|has failed|incomplete|temporarily delayed)|failure notice|returned mail|could not be delivered|전송\s*실패|배달\s*실패|반송/i.test(
      input.subject ?? '',
    );
  const reportHit = /multipart\/report|report-type\s*=\s*delivery-status/i.test(
    input.contentType ?? '',
  );
  const dsnHit =
    /final-recipient:|original-recipient:|action:\s*(failed|delayed)|diagnostic-code:|status:\s*[45]\.|rcpt to:|메일캐리어|발송을\s*중지|전송하지\s*못|받는\s*사람|수신자/i.test(
      body,
    );
  return daemon || subjectHit || reportHit || dsnHit;
}

/** first SMTP code appearing in the haystack (hard codes win over soft). */
function extractCode(hay: string): { severity: BounceSeverity; code: string } | null {
  const hard = hay.match(HARD_RE);
  if (hard) return { severity: 'hard', code: hard[0] };
  const soft = hay.match(SOFT_RE);
  if (soft) return { severity: 'soft', code: soft[0] };
  return null;
}

/**
 * Detect an NDR and classify hard/soft. Returns null when the message is not
 * an NDR, carries no 4xx/5xx signal, or no failed recipient can be extracted.
 */
export function detectNdrOutcome(input: InboundForSuppression): NdrOutcome | null {
  const text = input.text ?? '';
  const html = input.html ? stripHtml(input.html) : '';
  const body = `${text}\n${html}`;

  if (!looksLikeNdr(input, body)) return null;

  const hay = `${input.subject ?? ''}\n${body}`;
  const sig = extractCode(hay);
  if (!sig) return null; // NDR-looking but no SMTP code -> too vague to log

  const own = ownSet(input.ownAddresses);
  const found = new Set<string>();
  const add = (raw?: string | null) => {
    if (!raw) return;
    const e = normalizeEmail(raw);
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e)) return;
    if (/mailer-daemon|postmaster/i.test(e)) return;
    if (isOwn(e, own)) return;
    if (e === input.fromAddress.trim().toLowerCase()) return;
    found.add(e);
  };

  // 1) structured DSN fields (most reliable)
  for (const m of body.matchAll(
    new RegExp(`(?:final|original)-recipient:\\s*(?:rfc822;)?\\s*<?(${EMAIL_INNER})>?`, 'gi'),
  ))
    add(m[1]);

  // 2) RCPT TO:<...>
  for (const m of body.matchAll(new RegExp(`rcpt to:\\s*<?(${EMAIL_INNER})>?`, 'gi'))) add(m[1]);

  // 3) <email> near an SMTP status line or recipient marker
  if (found.size === 0) {
    for (const m of body.matchAll(new RegExp(`<(${EMAIL_INNER})>`, 'gi'))) {
      const idx = m.index ?? 0;
      const around = body.slice(Math.max(0, idx - 120), idx + 240);
      if (
        HARD_RE.test(around) ||
        SOFT_RE.test(around) ||
        /rcpt|recipient|받는\s*사람|수신자/i.test(around)
      ) {
        add(m[1]);
      }
    }
  }

  // 4) bare email sitting on the same line as a 4xx/5xx code
  //    ("550 5.2.1 startups@planet-a.com: account disabled")
  if (found.size === 0) {
    for (const line of body.split(/\r?\n/)) {
      if (!HARD_RE.test(line) && !SOFT_RE.test(line)) continue;
      for (const m of line.matchAll(new RegExp(`(${EMAIL_INNER})`, 'gi'))) add(m[1]);
    }
  }

  const recipients = [...found];
  if (recipients.length === 0) return null;

  return {
    recipients,
    severity: sig.severity,
    smtpCode: sig.code,
    evidence: (input.subject ?? '').slice(0, 140),
  };
}
