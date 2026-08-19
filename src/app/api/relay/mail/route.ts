/**
 * Multi-domain SMTP relay endpoint.
 *
 * Purpose:
 *   Supabase Edge Functions cannot open outbound SMTP (ports 25/587 are blocked
 *   by the platform). Railway has no such restriction, so external sites POST
 *   here over HTTPS and this route performs the actual SMTP submission.
 *
 * Deploy path: src/app/api/relay/mail/route.ts
 *
 * Env:
 *   MAIL_RELAY_TOKEN     - shared secret; callers send it as `x-relay-token`
 *   MAIL_RELAY_PROFILES  - JSON map of profile key -> SMTP profile, e.g.
 *     {
 *       "koreancoaching": {
 *         "host": "mail.koreancoaching.com",
 *         "port": 587,
 *         "useTls": false,
 *         "user": "hello@koreancoaching.com",
 *         "pass": "********",
 *         "fromName": "Korean Coaching"
 *       }
 *     }
 *   Set useTls to true once a Let's Encrypt certificate is registered in
 *   MailCarrier; the transporter then negotiates STARTTLS on the same port 587.
 */
import { NextResponse } from 'next/server';
import { timingSafeEqual } from 'node:crypto';
import nodemailer, { type Transporter } from 'nodemailer';
import type SMTPTransport from 'nodemailer/lib/smtp-transport';

// SMTP needs raw TCP sockets, which the Edge runtime does not provide.
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_BODY_BYTES = 512 * 1024;

interface RelayProfile {
  host: string;
  port: number;
  useTls?: boolean;
  user: string;
  pass: string;
  fromName?: string;
  fromAddress?: string;
}

let profileCache: Record<string, RelayProfile> | null = null;
const transporters = new Map<string, Transporter>();

function loadProfiles(): Record<string, RelayProfile> {
  if (profileCache) return profileCache;
  const raw = process.env.MAIL_RELAY_PROFILES;
  if (!raw) throw new Error('MAIL_RELAY_PROFILES is not configured');
  profileCache = JSON.parse(raw) as Record<string, RelayProfile>;
  return profileCache;
}

function getTransporter(key: string, profile: RelayProfile): Transporter {
  const cached = transporters.get(key);
  if (cached) return cached;

  const useTls = profile.useTls === true;
  const options: SMTPTransport.Options = {
    host: profile.host,
    port: profile.port,
    // MailCarrier does not listen on 465; 587 is either plaintext or STARTTLS.
    secure: useTls && profile.port === 465,
    requireTLS: useTls && profile.port !== 465,
    ignoreTLS: !useTls,
    auth: { type: 'login', user: profile.user, pass: profile.pass },
    connectionTimeout: 10_000,
    greetingTimeout: 10_000,
    socketTimeout: 20_000,
    pool: true,
    maxConnections: 3,
  };

  const transporter = nodemailer.createTransport(options);
  transporters.set(key, transporter);
  return transporter;
}

/** Constant-time comparison so the token cannot be recovered by timing. */
function tokenMatches(provided: string | null, expected: string): boolean {
  if (!provided) return false;
  const a = Buffer.from(provided);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

function isEmail(value: unknown): value is string {
  return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function normaliseRecipients(value: unknown): string[] | null {
  const list = Array.isArray(value) ? value : [value];
  if (list.length === 0 || list.length > 20) return null;
  return list.every(isEmail) ? (list as string[]) : null;
}

export async function POST(req: Request) {
  const expected = process.env.MAIL_RELAY_TOKEN;
  if (!expected) {
    console.error('[relay/mail] MAIL_RELAY_TOKEN is not configured');
    return NextResponse.json({ ok: false, error: 'server_misconfigured' }, { status: 500 });
  }

  // Reject before parsing so an unauthenticated caller cannot make us do work.
  if (!tokenMatches(req.headers.get('x-relay-token'), expected)) {
    return NextResponse.json({ ok: false, error: 'unauthorized' }, { status: 401 });
  }

  const rawBody = await req.text();
  if (Buffer.byteLength(rawBody) > MAX_BODY_BYTES) {
    return NextResponse.json({ ok: false, error: 'payload_too_large' }, { status: 413 });
  }

  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawBody) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ ok: false, error: 'invalid_json' }, { status: 400 });
  }

  const profileKey = typeof body.profile === 'string' ? body.profile : '';
  const subject = typeof body.subject === 'string' ? body.subject.trim() : '';
  const html = typeof body.html === 'string' ? body.html : undefined;
  const text = typeof body.text === 'string' ? body.text : undefined;
  const to = normaliseRecipients(body.to);

  if (!profileKey) {
    return NextResponse.json({ ok: false, error: 'profile_required' }, { status: 400 });
  }
  if (!to) {
    return NextResponse.json({ ok: false, error: 'invalid_recipients' }, { status: 400 });
  }
  if (!subject || subject.length > 200) {
    return NextResponse.json({ ok: false, error: 'invalid_subject' }, { status: 400 });
  }
  if (!html && !text) {
    return NextResponse.json({ ok: false, error: 'body_required' }, { status: 400 });
  }

  let profiles: Record<string, RelayProfile>;
  try {
    profiles = loadProfiles();
  } catch (err) {
    console.error('[relay/mail] profile load failed:', err);
    return NextResponse.json({ ok: false, error: 'server_misconfigured' }, { status: 500 });
  }

  const profile = profiles[profileKey];
  if (!profile) {
    // Do not echo the key back; it would confirm which profiles exist.
    return NextResponse.json({ ok: false, error: 'unknown_profile' }, { status: 400 });
  }

  const fromAddress = profile.fromAddress ?? profile.user;
  const from = profile.fromName ? `"${profile.fromName}" <${fromAddress}>` : fromAddress;

  try {
    const info = await getTransporter(profileKey, profile).sendMail({
      from,
      to,
      subject,
      html,
      text,
      replyTo: isEmail(body.replyTo) ? body.replyTo : undefined,
    });

    console.info(`[relay/mail] sent profile=${profileKey} id=${info.messageId}`);
    return NextResponse.json({ ok: true, messageId: info.messageId });
  } catch (err) {
    // Log detail server-side, return an opaque error to the caller.
    console.error(`[relay/mail] send failed profile=${profileKey}:`, err);
    return NextResponse.json({ ok: false, error: 'send_failed' }, { status: 502 });
  }
}
