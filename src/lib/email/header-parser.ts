/**
 * lib/email/header-parser.ts
 *
 * Collection of pure functions - only findThreadId touches the DB; everything else is input->output.
 * Since this is the easiest module to unit-test, the business logic (thread-matching priority, etc.)
 * is all gathered in this file.
 *
 * mailcarrier.ts only calls functions from this file and focuses on IMAP I/O.
 */

import type { ParsedMail } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';
import {
  URM_HEADER_NAMES,
  type ParsedHeaders,
  type UrmHeaders,
} from '../../types/email';

/* ============================================================
 * 1. parseInboundMessage — ParsedMail → ParsedHeaders
 * ============================================================ */

/**
 * Extract from mailparser's ParsedMail only the headers our domain needs.
 *
 * Exception handling:
 *   - missing messageId -> auto-generate `unknown-{timestamp}@local` (idempotency preserved)
 *   - missing from.address -> `unknown@unknown` (prevents DB INSERT failure)
 *   - missing subject -> `(no subject)`
 *   - missing date -> current time
 *
 * All four URM headers (X-URM-*) are extracted. If a header is missing, the invisible footer
 * (`<!-- urm:c=...;auto=...;e=... -->`) is used to recover it - fallback.
 */
export function parseInboundMessage(parsed: ParsedMail): ParsedHeaders {
  const messageId = parsed.messageId ?? `<unknown-${Date.now()}@local>`;

  // References: array or whitespace-separated string
  const referencesRaw = parsed.references;
  const references: string[] = Array.isArray(referencesRaw)
    ? referencesRaw.map((s) => String(s)).filter((s) => s.length > 0)
    : typeof referencesRaw === 'string'
      ? referencesRaw.split(/\s+/).filter((s) => s.length > 0)
      : [];

  // Extract X-URM-* headers
  const headers = parsed.headers;
  const urmHeaders = extractUrmHeadersFromMap(headers);

  // Fallback when headers are lost: invisible footer in the HTML body
  if (!hasAnyUrmHeader(urmHeaders) && typeof parsed.html === 'string') {
    const fromFooter = extractUrmHeadersFromHtmlFooter(parsed.html);
    Object.assign(urmHeaders, fromFooter);
  }

  // Normalize From - mailparser returns from.value: AddressObject[]
  const fromAddr = parsed.from?.value?.[0];

  // Flatten To/Cc arrays
  const toList: ParsedHeaders['to'] = [];
  if (parsed.to) {
    const arr = Array.isArray(parsed.to) ? parsed.to : [parsed.to];
    for (const a of arr) {
      for (const v of a.value ?? []) {
        if (v.address) toList.push({ name: v.name, address: v.address });
      }
    }
  }
  const ccList: ParsedHeaders['cc'] = [];
  if (parsed.cc) {
    const arr = Array.isArray(parsed.cc) ? parsed.cc : [parsed.cc];
    for (const a of arr) {
      for (const v of a.value ?? []) {
        if (v.address) ccList.push({ name: v.name, address: v.address });
      }
    }
  }

  // Reply-To
  let replyTo: string | undefined;
  if (parsed.replyTo) {
    const arr = Array.isArray(parsed.replyTo)
      ? parsed.replyTo
      : [parsed.replyTo];
    const first = arr[0]?.value?.[0]?.address;
    if (first) replyTo = first;
  }

  // Raw headers to keep (for debugging/reprocessing - small whitelist only)
  const rawSelectedHeaders: Record<string, string> = {};
  for (const name of [
    'message-id',
    'in-reply-to',
    'references',
    'subject',
    'date',
    'return-path',
    'list-unsubscribe',
  ]) {
    const v = headers.get(name);
    if (typeof v === 'string') rawSelectedHeaders[name] = v;
  }

  return {
    messageId,
    inReplyTo: parsed.inReplyTo ?? undefined,
    references,
    from: {
      name: fromAddr?.name,
      address: fromAddr?.address ?? 'unknown@unknown',
    },
    to: toList,
    cc: ccList.length > 0 ? ccList : undefined,
    replyTo,
    subject: parsed.subject ?? '(no subject)',
    date: parsed.date ?? new Date(),
    urmHeaders,
    rawSelectedHeaders,
  };
}

/* ============================================================
 * 2. URM header extraction helper
 * ============================================================ */

/** mailparser headers Map → UrmHeaders. */
export function extractUrmHeadersFromMap(
  headers: Map<string, unknown>,
): UrmHeaders {
  const urm: UrmHeaders = {};

  const eng = readStringHeader(headers, URM_HEADER_NAMES.engagementId);
  const comm = readStringHeader(headers, URM_HEADER_NAMES.communicationId);
  const autoSend = readStringHeader(headers, URM_HEADER_NAMES.autoSend);
  const brandVoice = readStringHeader(headers, URM_HEADER_NAMES.brandVoiceId);

  if (eng) urm.engagementId = eng;
  if (comm) urm.communicationId = comm;
  if (autoSend) urm.autoSend = autoSend.trim().toLowerCase() === 'true';
  if (brandVoice) urm.brandVoiceId = brandVoice;

  return urm;
}

function readStringHeader(
  headers: Map<string, unknown>,
  name: string,
): string | undefined {
  // mailparser stores header names in lowercase
  const v = headers.get(name) ?? headers.get(name.toLowerCase());
  if (typeof v === 'string') return v;
  if (Array.isArray(v) && typeof v[0] === 'string') return v[0];
  return undefined;
}

export function hasAnyUrmHeader(urm: UrmHeaders): boolean {
  return (
    urm.engagementId !== undefined ||
    urm.communicationId !== undefined ||
    urm.autoSend !== undefined ||
    urm.brandVoiceId !== undefined
  );
}

/**
 * Recover URM info from the invisible footer in the HTML body.
 * Format: `<!-- urm:c=<commId>;auto=<0|1>[;e=<engId>][;bv=<brandVoiceId>] -->`
 *
 * Fallback for when tabs-mailer cannot guarantee headers pass through.
 */
export function extractUrmHeadersFromHtmlFooter(html: string): UrmHeaders {
  const m = /<!--\s*urm:([^>]+?)\s*-->/i.exec(html);
  if (!m) return {};
  const body = (m[1] ?? '').trim();
  const result: UrmHeaders = {};
  for (const part of body.split(';')) {
    const [k, v] = part.split('=').map((s) => s.trim());
    if (!k || v === undefined) continue;
    if (k === 'c') result.communicationId = v;
    else if (k === 'e') result.engagementId = v;
    else if (k === 'bv') result.brandVoiceId = v;
    else if (k === 'auto') result.autoSend = v === '1' || v === 'true';
  }
  return result;
}

/* ============================================================
 * 3. Thread-matching algorithm (DB access)
 * ============================================================ */

export interface ThreadMatchResult {
  threadId: string | null;
  matchedBy: 'urm_header' | 'in_reply_to' | 'references' | 'none';
  matchedCommId?: string;
  matchedEngagementId?: string;
}

/**
 * Priority:
 *   1. X-URM-Communication-Id header -> direct match on outbound communications.id
 *   2. In-Reply-To -> match outbound communications.message_id
 *   3. References (reverse order) -> same match
 *
 * If nothing matches, return null -> the caller generates a new thread_id.
 */
export async function findThreadId(
  supabase: SupabaseClient,
  organizationId: string,
  headers: ParsedHeaders,
): Promise<ThreadMatchResult> {
  // [1] X-URM-Communication-Id
  if (headers.urmHeaders.communicationId) {
    const { data, error } = await supabase
      .schema('app')
      .from('communications')
      .select('thread_id, engagement_id')
      .eq('id', headers.urmHeaders.communicationId)
      .eq('organization_id', organizationId)
      .maybeSingle();
    if (!error && data?.thread_id) {
      return {
        threadId: data.thread_id,
        matchedBy: 'urm_header',
        matchedCommId: headers.urmHeaders.communicationId,
        matchedEngagementId: data.engagement_id ?? undefined,
      };
    }
  }

  // [2] In-Reply-To
  if (headers.inReplyTo) {
    const { data, error } = await supabase
      .schema('app')
      .from('communications')
      .select('id, thread_id, engagement_id')
      .eq('message_id', headers.inReplyTo)
      .eq('organization_id', organizationId)
      .maybeSingle();
    if (!error && data?.thread_id) {
      return {
        threadId: data.thread_id,
        matchedBy: 'in_reply_to',
        matchedCommId: data.id,
        matchedEngagementId: data.engagement_id ?? undefined,
      };
    }
  }

  // [3] References - try matching from the most recent (end) first
  for (const ref of [...headers.references].reverse()) {
    const { data, error } = await supabase
      .schema('app')
      .from('communications')
      .select('id, thread_id, engagement_id')
      .eq('message_id', ref)
      .eq('organization_id', organizationId)
      .maybeSingle();
    if (!error && data?.thread_id) {
      return {
        threadId: data.thread_id,
        matchedBy: 'references',
        matchedCommId: data.id,
        matchedEngagementId: data.engagement_id ?? undefined,
      };
    }
  }

  return { threadId: null, matchedBy: 'none' };
}

/* ============================================================
 * 4. From address -> candidate contact/party matches
 * ----------------------------------------------------------
 * This function is a helper to infer contact_id/party_id - at actual INSERT time
 * mailcarrier calls it. If multiple candidates appear, pick one by most recent activity.
 * ============================================================ */

export interface SenderMatchResult {
  contactId?: string;
  partyId?: string;
  matchedBy: 'contact_email' | 'party_email_domain' | 'none';
}

export async function matchSenderToContactAndParty(
  supabase: SupabaseClient,
  organizationId: string,
  fromAddress: string,
): Promise<SenderMatchResult> {
  if (!fromAddress || fromAddress === 'unknown@unknown') {
    return { matchedBy: 'none' };
  }
  const lowered = fromAddress.toLowerCase();

  // [1] exact match on contacts.email
  const { data: contact } = await supabase
    .schema('app')
    .from('contacts')
    .select('id, party_id')
    .eq('organization_id', organizationId)
    .eq('email', lowered)
    .is('deleted_at', null)
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (contact) {
    return {
      contactId: contact.id,
      partyId: contact.party_id ?? undefined,
      matchedBy: 'contact_email',
    };
  }

  // [2] domain-based party match (secondary)
  const at = lowered.lastIndexOf('@');
  if (at < 0) return { matchedBy: 'none' };
  const domain = lowered.slice(at + 1);
  if (domain.length === 0) return { matchedBy: 'none' };

  // Exclude common mail domains from matching (avoid false positives)
  const generic = new Set([
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'naver.com',
    'daum.net',
    'kakao.com',
    'icloud.com',
    'qq.com',
    '163.com',
  ]);
  if (generic.has(domain)) return { matchedBy: 'none' };

  // Match the domain against contacts.email or parties.website
  const { data: byDomain } = await supabase
    .schema('app')
    .from('contacts')
    .select('id, party_id')
    .eq('organization_id', organizationId)
    .like('email', `%@${domain}`)
    .is('deleted_at', null)
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (byDomain?.party_id) {
    return {
      partyId: byDomain.party_id,
      contactId: byDomain.id,
      matchedBy: 'party_email_domain',
    };
  }

  return { matchedBy: 'none' };
}
