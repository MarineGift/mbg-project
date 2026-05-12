/**
 * lib/queries/inbox.ts
 *
 * Inbox(받은 편지함) 목록 fetch.
 *
 * 검색: 단순 ilike (Phase 1). pg_trgm GIN 인덱스는 STEP 1에서 생성되어 있어
 *       빠르게 동작. 두 컬럼(subject, body_plain) OR 조건.
 *
 * 정렬: occurred_at DESC (받은 시각 기준). 동일 시각 tiebreaker id ASC.
 *
 * AI 초안 표시: drafts.inbound_communication_id IN (...) 별도 쿼리로 'hasDraft' 결정.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { ModuleType } from '@/types/ai';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
  InboxFilters,
  InboxPagination,
  InboxResult,
  InboxRow,
} from '@/types/inbox';
import {
  DEFAULT_INBOX_FILTERS,
  INBOX_DEFAULT_PAGE_SIZE,
  INBOX_PAGE_SIZE_OPTIONS,
} from '@/types/inbox';

const ALL_CHANNELS: readonly CommunicationChannel[] = [
  'email',
  'slack',
  'sms',
  'phone',
  'other',
] as const;

const ALL_DIRECTIONS: readonly CommunicationDirection[] = [
  'inbound',
  'outbound',
] as const;

/* ============================================================
 * URL params 파싱
 * ============================================================ */

export function parseInboxFilters(
  params: Record<string, string | string[] | undefined>,
): InboxFilters {
  const channel = pickEnum(params.channel, ALL_CHANNELS, 'all' as const);
  const direction = pickEnum(params.direction, ALL_DIRECTIONS, 'all' as const);
  const queryRaw = single(params.q);
  const query = queryRaw?.trim() ?? '';
  const hasDraft = single(params.hasDraft) === '1';
  const partyIdRaw = single(params.party);
  const partyId = partyIdRaw && /^[0-9a-f-]{36}$/i.test(partyIdRaw) ? partyIdRaw : null;

  return {
    channel: channel as CommunicationChannel | 'all',
    direction: direction as CommunicationDirection | 'all',
    query,
    hasDraft,
    partyId,
  };
}

export function parseInboxPagination(
  params: Record<string, string | string[] | undefined>,
): InboxPagination {
  const pageRaw = Number(single(params.page) ?? '1');
  const sizeRaw = Number(single(params.size) ?? String(INBOX_DEFAULT_PAGE_SIZE));
  const page = Number.isFinite(pageRaw) && pageRaw >= 1 ? Math.floor(pageRaw) : 1;
  const pageSize = (INBOX_PAGE_SIZE_OPTIONS as readonly number[]).includes(sizeRaw)
    ? sizeRaw
    : INBOX_DEFAULT_PAGE_SIZE;
  return { page, pageSize };
}

function single(v: string | string[] | undefined): string | undefined {
  return Array.isArray(v) ? v[0] : v;
}

function pickEnum<T extends string>(
  v: string | string[] | undefined,
  allowed: readonly T[],
  fallback: T | 'all',
): T | 'all' {
  const s = single(v);
  if (!s) return fallback;
  if (s === 'all') return 'all';
  if ((allowed as readonly string[]).includes(s)) return s as T;
  return fallback;
}

/* ============================================================
 * Server fetcher
 * ============================================================ */

interface RawInboxRow {
  id: string;
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  status: CommunicationStatus;
  from_address: string | null;
  from_name: string | null;
  to_addresses: string[] | null;
  subject: string | null;
  body_plain: string | null;
  occurred_at: string;
  sent_at: string | null;
  ai_generated: boolean;
  attachment_count: number | null;
  party_id: string | null;
  parties: { name: string; module: ModuleType } | null;
}

export async function fetchInbox(
  filters: InboxFilters = DEFAULT_INBOX_FILTERS,
  pagination: InboxPagination = { page: 1, pageSize: INBOX_DEFAULT_PAGE_SIZE },
): Promise<InboxResult> {
  const supabase = await createSupabaseServerClient();

  let query = supabase
    .schema('app')
    .from('communications' as never)
    .select(
      `id, channel, direction, status, from_address, from_name, to_addresses,
       subject, body_plain, occurred_at, sent_at, ai_generated, attachment_count,
       party_id,
       parties:party_id ( name, module )`,
      { count: 'exact' },
    );

  // 필터
  if (filters.channel !== 'all') {
    query = query.eq('channel', filters.channel);
  }
  if (filters.direction !== 'all') {
    query = query.eq('direction', filters.direction);
  }
  if (filters.partyId) {
    query = query.eq('party_id', filters.partyId);
  }
  if (filters.query.length > 0) {
    // ilike + OR — pg_trgm GIN 인덱스 활용
    // PostgREST의 .or()는 'col.ilike.pattern,col2.ilike.pattern' 형식
    const pattern = `%${escapeLikePattern(filters.query)}%`;
    query = query.or(`subject.ilike.${pattern},body_plain.ilike.${pattern}`);
  }

  // 정렬
  query = query
    .order('occurred_at', { ascending: false, nullsFirst: false })
    .order('id', { ascending: true });

  // 페이지네이션
  const from = (pagination.page - 1) * pagination.pageSize;
  const to = from + pagination.pageSize - 1;
  query = query.range(from, to);

  const { data, error, count } = await query;
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[queries/inbox.fetchInbox] failed:', error);
    return { rows: [], totalCount: 0, filters, pagination };
  }

  const rawRows = (data ?? []) as unknown as RawInboxRow[];

  // hasDraft 결정 — inbound 통신 ID 중 ai.drafts.inbound_communication_id에 존재하는 것
  const inboundIds = rawRows
    .filter((r) => r.direction === 'inbound')
    .map((r) => r.id);

  let draftsByInboundId = new Set<string>();
  if (inboundIds.length > 0) {
    const { data: draftRows } = await supabase
      .schema('ai')
      .from('drafts' as never)
      .select('inbound_communication_id')
      .in('inbound_communication_id', inboundIds);
    const ids = (draftRows ?? []) as unknown as Array<{
      inbound_communication_id: string;
    }>;
    draftsByInboundId = new Set(ids.map((r) => r.inbound_communication_id));
  }

  let rows: InboxRow[] = rawRows.map((r) => toInboxRow(r, draftsByInboundId));

  // hasDraft 필터는 위 단계에서 모든 행 가져온 후 사후 필터 (성능상 ok — 페이지당 최대 100)
  if (filters.hasDraft) {
    rows = rows.filter((r) => r.hasDraft);
  }

  return {
    rows,
    totalCount: count ?? 0,
    filters,
    pagination,
  };
}

function toInboxRow(
  raw: RawInboxRow,
  draftsByInboundId: Set<string>,
): InboxRow {
  const partyArr = Array.isArray(raw.parties) ? raw.parties[0] : raw.parties;
  const party = partyArr ?? null;

  const bodyPreview = (raw.body_plain ?? '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 120);

  return {
    id: raw.id,
    channel: raw.channel,
    direction: raw.direction,
    status: raw.status,
    fromAddress: raw.from_address,
    fromName: raw.from_name,
    toAddresses: raw.to_addresses ?? [],
    subject: raw.subject,
    bodyPreview,
    occurredAt: raw.occurred_at,
    sentAt: raw.sent_at,
    partyId: raw.party_id,
    partyName: party?.name ?? null,
    partyModule: party?.module ?? null,
    hasDraft:
      raw.direction === 'inbound' && draftsByInboundId.has(raw.id),
    aiGenerated: raw.ai_generated,
    attachmentCount: raw.attachment_count ?? 0,
  };
}

/**
 * ilike 패턴 안전 escape — % 와 _ 를 리터럴로 변환.
 */
function escapeLikePattern(s: string): string {
  return s.replace(/[%_]/g, '\\$&').replace(/,/g, ''); // PostgREST or() 구문 보호용 , 제거
}
