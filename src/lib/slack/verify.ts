// src/lib/slack/verify.ts
//
// Verifies that an inbound request really came from Slack, using the app's
// Signing Secret (Slack docs: "Verifying requests from Slack").
//   base   = `v0:${timestamp}:${rawBody}`
//   expect = 'v0=' + HMAC_SHA256(signingSecret, base)   (hex)
// Compared in constant time. Requests older than 5 minutes are rejected
// (replay protection). Requires the RAW request body (not parsed).

import crypto from 'crypto';
import { env } from '@/lib/env';

const FIVE_MINUTES = 60 * 5;

export function verifySlackSignature(
  rawBody: string,
  timestamp: string | null,
  signature: string | null,
): boolean {
  const secret = env.SLACK_SIGNING_SECRET;
  if (!secret || !timestamp || !signature) return false;

  const ts = Number(timestamp);
  if (!Number.isFinite(ts)) return false;
  if (Math.abs(Date.now() / 1000 - ts) > FIVE_MINUTES) return false;

  const base = `v0:${timestamp}:${rawBody}`;
  const expected = 'v0=' + crypto.createHmac('sha256', secret).update(base).digest('hex');

  const a = Buffer.from(expected, 'utf8');
  const b = Buffer.from(signature, 'utf8');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}
