import type { ParsedMail, AddressObject } from 'mailparser';
import type { SupabaseClient } from '@supabase/supabase-js';

export interface ParsedAddress {
  name?: string;
  address: string;
}

export interface ParsedHeaders {
  messageId: string;
  inReplyTo?: string;
  references: string[];
  from: ParsedAddress;
  to: ParsedAddress[];
  cc: ParsedAddress[];
  bcc: ParsedAddress[];
  replyTo?: ParsedAddress;
  subject: string;
  date: Date;
  urmHeaders: {
    communicationId?: string;
    engagementId?: string;
    partyId?: string;
    brandVoiceId?: string;
    threadId?: string;
    autoSend?: boolean;
  };
  contentLanguage?: string;
}

export function parseInboundMessage(parsed: ParsedMail): ParsedHeaders {
  const messageId = normalizeMessageId(parsed.messageId);

  const references = parseReferences(parsed.references);

  const fromAddr = pickFirstAddress(parsed.from);
  const from: ParsedAddress = {
    name: fromAddr.name || undefined,
    address: fromAddr.address || 'unknown@unknown',
  };

  const to = collectAddresses(parsed.to);
  const cc = collectAddresses(parsed.cc);
  const bcc = collectAddresses(parsed.bcc);
  const replyToList = collectAddresses(parsed.replyTo);
  const replyTo = replyToList.length > 0 ? replyToList[0] : undefined;

  const urmHeaders = extractUrmHeaders(parsed.headers);

  const contentLanguageRaw = readSingleHeader(parsed.headers, 'content-language');

  return {
    messageId,
    inReplyTo: typeof parsed.inReplyTo === 'string' ? parsed.inReplyTo : undefined,
    references,
    from,
    to,
    cc,
    bcc,
    replyTo,
    subject: typeof parsed.subject === 'string' ? parsed.subject : '(no subject)',
    date: parsed.date instanceof Date ? parsed.date : new Date(),
    urmHeaders,
    contentLanguage: contentLanguageRaw,
  };
}

export function normalizeMessageId(raw: string | undefined): string {
  if (typeof raw === 'string' && raw.trim().length > 0) {
    return raw.trim();
  }
  return `<missing-${Date.now()}-${randomToken()}@local.urm>`;
}

export function parseReferences(raw: string | string[] | undefined): string[] {
  if (!raw) return [];
  if (Array.isArray(raw)) {
    return raw.map((r) => r.trim()).filter((r) => r.length > 0);
  }
  return raw.split(/\s+/).map((r) => r.trim()).filter((r) => r.length > 0);
}

function collectAddresses(
  raw: AddressObject | AddressObject[] | undefined,
): ParsedAddress[] {
  if (!raw) return [];
  const list = Array.isArray(raw) ? raw : [raw];
  const result: ParsedAddress[] = [];
  for (const obj of list) {
    for (const v of obj.value ?? []) {
      if (v.address) {
        result.push({
          name: v.name && v.name.trim().length > 0 ? v.name : undefined,
          address: v.address,
        });
      }
    }
  }
  return result;
}

function pickFirstAddress(
  raw: AddressObject | AddressObject[] | undefined,
): ParsedAddress {
  const list = collectAddresses(raw);
  return list.length > 0 ? list[0]! : { address: 'unknown@unknown' };
}

function extractUrmHeaders(headers: ParsedMail['headers']): ParsedHeaders['urmHeaders'] {
  const out: ParsedHeaders['urmHeaders'] = {};
  if (!headers) return out;

  const commId = readSingleHeader(headers, 'x-urm-communication-id');
  const engId = readSingleHeader(headers, 'x-urm-engagement-id');
  const partyId = readSingleHeader(headers, 'x-urm-party-id');
  const brandId = readSingleHeader(headers, 'x-urm-brand-voice-id');
  const threadId = readSingleHeader(headers, 'x-urm-thread-id');
  const autoSend = readSingleHeader(headers, 'x-urm-auto-send');

  if (commId) out.communicationId = commId;
  if (engId) out.engagementId = engId;
  if (partyId) out.partyId = partyId;
  if (brandId) out.brandVoiceId = brandId;
  if (threadId) out.threadId = threadId;
  if (autoSend) out.autoSend = autoSend.toLowerCase() === 'true';

  return out;
}

function readSingleHeader(
  headers: ParsedMail['headers'],
  key: string,
): string | undefined {
  if (!headers) return undefined;
  const raw = headers.get(key);
  if (typeof raw === 'string') return raw.trim() || undefined;
  if (Array.isArray(raw) && raw.length > 0 && typeof raw[0] === 'string') {
    return (raw[0] as string).trim() || undefined;
  }
  return undefined;
}

function randomToken(): string {
  return Math.random().toString(36).slice(2, 10);
}

export async function findThreadId(
  supabase: SupabaseClient,
  organizationId: string,
  headers: ParsedHeaders,
): Promise<string | null> {
  if (headers.urmHeaders.threadId) {
    return headers.urmHeaders.threadId;
  }

  if (headers.urmHeaders.communicationId) {
    const { data } = await supabase
      .schema('app')
      .from('communications')
      .select('thread_id')
      .eq('organization_id', organizationId)
      .eq('id', headers.urmHeaders.communicationId)
      .maybeSingle();
    const tid = (data as { thread_id?: string } | null)?.thread_id;
    if (tid) return tid;
  }

  if (headers.inReplyTo) {
    const { data } = await supabase
      .schema('app')
      .from('communications')
      .select('thread_id')
      .eq('organization_id', organizationId)
      .eq('message_id', headers.inReplyTo)
      .maybeSingle();
    const tid = (data as { thread_id?: string } | null)?.thread_id;
    if (tid) return tid;
  }

  for (const ref of [...headers.references].reverse()) {
    const { data } = await supabase
      .schema('app')
      .from('communications')
      .select('thread_id')
      .eq('organization_id', organizationId)
      .eq('message_id', ref)
      .maybeSingle();
    const tid = (data as { thread_id?: string } | null)?.thread_id;
    if (tid) return tid;
  }

  return null;
}

export async function findContactByEmail(
  supabase: SupabaseClient,
  organizationId: string,
  email: string,
): Promise<{ contactId: string; partyId?: string } | null> {
  if (!email) return null;
  const lower = email.toLowerCase();
  const { data, error } = await supabase
    .schema('app')
    .from('contacts')
    .select('id, party_id')
    .eq('organization_id', organizationId)
    .eq('email_lower', lower)
    .is('deleted_at', null)
    .limit(1)
    .maybeSingle();
  if (error || !data) return null;
  const row = data as { id: string; party_id?: string | null };
  return {
    contactId: row.id,
    partyId: row.party_id ?? undefined,
  };
}
