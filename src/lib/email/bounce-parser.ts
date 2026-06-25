/**
 * lib/email/bounce-parser.ts
 *
 * Pure detection of (a) hard bounces / delivery-failure notices and
 * (b) unsubscribe requests from an inbound message, so the inbound worker can
 * auto-register the offending address into app.email_blocklist.
 *
 * Handles two bounce shapes seen in this system:
 *   1. Standard RFC-3464 DSN from mailer-daemon@/postmaster@ (Final-Recipient,
 *      Action: failed, Status: 5.x.x, Diagnostic-Code).
 *   2. The URM MailCarrier's own "전송 실패 / Send failed" self-notice, where the
 *      failed recipient is in <...> near "받는 사람 / RCPT:" and a 5xx code.
 *
 * Conservative by design:
 *   - only PERMANENT failures (5.x.x / 55x) are treated as hard bounces;
 *     transient 4.x.x are ignored (stay retryable).
 *   - the failed RECIPIENT is extracted from the body (never the daemon's from).
 *   - own addresses/domains are never suppressed.
 *   - unsubscribe uses a tight, directive-style matcher to avoid footer false
 *     positives, and registers the human SENDER address.
 *
 * Pure module (no I/O) so it is unit-testable and importable by the worker.
 */

export type SuppressReason = 'hard_bounce' | 'unsubscribe';

export interface InboundForSuppression {
  fromAddress: string;
  fromName?: string | null;
  subject: string;
  text?: string | null;
  html?: string | null;
  /** top-level Content-Type header value, if available (for report-type). */
  contentType?: string | null;
  /** our own addresses + domains — never suppressed. */
  ownAddresses?: string[];
}

export interface SuppressSignal {
  email: string;
  reason: SuppressReason;
  evidence: string;
}

const EMAIL_INNER = '[^\\s<>@"]+@[^\\s<>@"]+\\.[^\\s<>@".]+';

/** permanent failure: a 5.x.x enhanced status OR a 55x basic SMTP code. */
const PERM_STATUS_RE = /\b5\.\d{1,3}\.\d{1,3}\b|\b55[0-4]\b/;

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

function bodyOf(input: InboundForSuppression): string {
  const text = input.text ?? '';
  const html = input.html ? stripHtml(input.html) : '';
  return `${text}\n${html}`;
}

function looksLikeBounce(input: InboundForSuppression, body: string): boolean {
  const from = input.fromAddress.toLowerCase();
  const daemon =
    /(^|[<\s])(mailer-daemon|postmaster|maildelivery|mail-?delivery)@/i.test(from) ||
    /mailer-?daemon|postmaster/i.test(`${input.fromName ?? ''}`);
  const subject = input.subject ?? '';
  const subjectHit =
    /delivery status notification|undeliverable|undelivered mail|mail delivery (failed|subsystem)|delivery (failure|has failed|incomplete)|failure notice|returned mail|전송\s*실패|배달\s*실패|반송/i.test(
      subject,
    );
  const reportHit = /multipart\/report|report-type\s*=\s*delivery-status/i.test(
    input.contentType ?? '',
  );
  const dsnHit =
    /final-recipient:|original-recipient:|action:\s*failed|diagnostic-code:|status:\s*5\.|rcpt to:|메일캐리어|발송을\s*중지|전송하지\s*못|받는\s*사람|수신자/i.test(
      body,
    );
  return daemon || subjectHit || reportHit || dsnHit;
}

/**
 * Detect a hard bounce and extract the failed recipient address(es).
 * Returns null if it is not a (permanent) bounce or no recipient can be found.
 */
export function detectBounce(input: InboundForSuppression): { recipients: string[] } | null {
  const body = bodyOf(input);
  if (!looksLikeBounce(input, body)) return null;
  // require a permanent-failure signal somewhere (body or subject)
  if (!PERM_STATUS_RE.test(body) && !PERM_STATUS_RE.test(input.subject ?? '')) return null;

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

  // 3) any <email> that sits near a 5xx code / recipient marker (covers the
  //    URM self-notice and many human-readable bounces).
  if (found.size === 0) {
    for (const m of body.matchAll(new RegExp(`<(${EMAIL_INNER})>`, 'gi'))) {
      const idx = m.index ?? 0;
      const around = body.slice(Math.max(0, idx - 120), idx + 240);
      if (PERM_STATUS_RE.test(around) || /rcpt|recipient|받는\s*사람|수신자|메일링\s*리스트/i.test(around)) {
        add(m[1]);
      }
    }
  }

  const recipients = [...found];
  return recipients.length > 0 ? { recipients } : null;
}

/** directive-style unsubscribe matcher (tight, to avoid footer false positives). */
const UNSUB_RE =
  /\bunsubscribe\s+me\b|\bplease\s+(unsubscribe|remove)\b|\bremove\s+me\b|\btake\s+me\s+off\b|\bopt[\s-]?out\b|\bstop\s+(sending|emailing|contacting)\b|\bdo\s+not\s+(e-?mail|contact)\s+me\b|수신\s*거부|구독\s*취소|메일.*(받지\s*않|그만\s*보내|중단)|더\s*이상.*보내지/i;

/** Detect an unsubscribe request; returns the SENDER address to suppress. */
export function detectUnsubscribe(input: InboundForSuppression): { email: string } | null {
  const from = input.fromAddress.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(from)) return null;
  if (/mailer-daemon|postmaster/i.test(from)) return null;
  const hay = `${input.subject ?? ''}\n${input.text ?? ''}`;
  if (!UNSUB_RE.test(hay)) return null;
  if (isOwn(from, ownSet(input.ownAddresses))) return null;
  return { email: from };
}

/** Convenience: all suppression signals for an inbound message. */
export function detectSuppressions(input: InboundForSuppression): SuppressSignal[] {
  const out: SuppressSignal[] = [];
  const bounce = detectBounce(input);
  if (bounce) {
    for (const email of bounce.recipients) {
      out.push({ email, reason: 'hard_bounce', evidence: (input.subject ?? '').slice(0, 140) });
    }
  } else {
    // a message is either a bounce OR a human unsubscribe, not both
    const unsub = detectUnsubscribe(input);
    if (unsub) out.push({ email: unsub.email, reason: 'unsubscribe', evidence: (input.subject ?? '').slice(0, 140) });
  }
  return out;
}
