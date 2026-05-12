/**
 * lib/email/header-parser.ts
 *
 * 순수 함수 모음 — DB 접근은 findThreadId만 수행하고, 나머지는 입력→출력만.
 * 단위 테스트가 가장 쉬운 모듈이므로 비즈니스 로직(스레드 매칭 우선순위 등)을
 * 모두 본 파일에 모은다.
 *
 * mailcarrier.ts는 본 파일의 함수를 호출만 하고 IMAP I/O에 집중.
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
 * mailparser의 ParsedMail에서 우리 도메인이 필요로 하는 헤더만 추출.
 *
 * 예외 처리:
 *   - messageId 없음 → `unknown-{timestamp}@local` 자동 생성 (멱등성 보존)
 *   - from.address 없음 → `unknown@unknown` (DB INSERT 실패 방지)
 *   - subject 없음 → `(no subject)`
 *   - date 없음 → 현재 시각
 *
 * URM 헤더(X-URM-*)는 4종 모두 추출. 헤더가 누락된 경우 invisible footer
 * (`<!-- urm:c=...;auto=...;e=... -->`)에서 회수 시도 — fallback.
 */
export function parseInboundMessage(parsed: ParsedMail): ParsedHeaders {
  const messageId = parsed.messageId ?? `<unknown-${Date.now()}@local>`;

  // References: 배열 또는 공백 분리 문자열
  const referencesRaw = parsed.references;
  const references: string[] = Array.isArray(referencesRaw)
    ? referencesRaw.map((s) => String(s)).filter((s) => s.length > 0)
    : typeof referencesRaw === 'string'
      ? referencesRaw.split(/\s+/).filter((s) => s.length > 0)
      : [];

  // X-URM-* 헤더 추출
  const headers = parsed.headers;
  const urmHeaders = extractUrmHeadersFromMap(headers);

  // 헤더 손실 시 fallback: HTML body의 invisible footer
  if (!hasAnyUrmHeader(urmHeaders) && typeof parsed.html === 'string') {
    const fromFooter = extractUrmHeadersFromHtmlFooter(parsed.html);
    Object.assign(urmHeaders, fromFooter);
  }

  // From 정규화 — mailparser는 from.value: AddressObject[]
  const fromAddr = parsed.from?.value?.[0];

  // To/Cc 배열 평탄화
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

  // 보존할 raw 헤더 (디버깅·재처리용 — 작은 화이트리스트만)
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
 * 2. URM 헤더 추출 헬퍼
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
  // mailparser는 헤더 이름을 lowercase로 보관
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
 * HTML body의 invisible footer에서 URM 정보 회수.
 * 형식: `<!-- urm:c=<commId>;auto=<0|1>[;e=<engId>][;bv=<brandVoiceId>] -->`
 *
 * tabs-mailer가 헤더 통과를 보장하지 못할 때의 fallback.
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
 * 3. 스레드 매칭 알고리즘 (DB 접근)
 * ============================================================ */

export interface ThreadMatchResult {
  threadId: string | null;
  matchedBy: 'urm_header' | 'in_reply_to' | 'references' | 'none';
  matchedCommId?: string;
  matchedEngagementId?: string;
}

/**
 * 우선순위:
 *   1. X-URM-Communication-Id 헤더 → 발신 communications.id 직접 매칭
 *   2. In-Reply-To → 발신 communications.message_id 매칭
 *   3. References (역순) → 동일 매칭
 *
 * 어느 것도 매칭되지 않으면 null 반환 → 호출자가 새 thread_id 생성.
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

  // [3] References — 가장 최근(끝쪽)부터 매칭 시도
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
 * 4. From 주소 → contact·party 매칭 후보
 * ----------------------------------------------------------
 * 본 함수는 contact_id·party_id를 추정하기 위한 보조 — 실제 INSERT 시
 * mailcarrier가 호출. 여러 후보가 나오면 가장 최근 활동 기준 1개 선택.
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

  // [1] contacts.email 정확 매칭
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

  // [2] 도메인 기반 party 매칭 (보조)
  const at = lowered.lastIndexOf('@');
  if (at < 0) return { matchedBy: 'none' };
  const domain = lowered.slice(at + 1);
  if (domain.length === 0) return { matchedBy: 'none' };

  // 일반 메일 도메인은 매칭 제외 (false positive 방지)
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

  // contacts.email 또는 parties.website에서 도메인 매칭
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
