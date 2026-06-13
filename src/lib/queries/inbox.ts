/**
 * lib/queries/inbox.ts
 *
 * Fetch the Inbox list.
 *
 * Search: simple ilike (Phase 1). The pg_trgm GIN index was created in STEP 1, so it
 *       runs fast. OR condition on two columns (subject, body_plain).
 *
 * Sort: occurred_at DESC (by received time). Tiebreaker for equal times is id ASC.
 *
 * AI draft indicator: a separate drafts.inbound_communication_id IN (...) query determines 'hasDraft'.
 *
 * Change history:
 *   - 2026-05-12 (1st): aligned ALL_CHANNELS to 9 + removed attachment_count.
 *   - 2026-05-12 (2nd): expanded ALL_CHANNELS to 11 (re-included slack, other).
 *   - 2026-05-12 (3rd): ALL_CHANNELS 12 - added webform, fully matches the DB enum.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { PartyTypeCode } from '@/types/ai';
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
  'phone',
  'sms',
  'linkedin',
  'kakaotalk',
  'wechat',
  'whatsapp',
  'in_person',
  'video_call',
  'webform',
  'slack',
  'other',
] as const;

const ALL_DIRECTIONS: readonly CommunicationDirection[] = [
  'inbound',
  'outbound',
] as const;

/* ============================================================
 * Parse URL params
 * ============================================================ */

export function parseInboxFilters(
  params: Record<string, string | string[] | undefined>,
  defaults: InboxFilters = DEFAULT_INBOX_FILTERS,
): InboxFilters {
  const channel = pickEnum(params.channel, ALL_CHANNELS, defaults.channel);
  const direction = pickEnum(params.direction, ALL_DIRECTIONS, defaults.direction);
  const queryRaw = single(params.q);
  const query = queryRaw?.trim() ?? '';
  const searchFieldRaw = single(params.field);
  const searchField = (['all', 'from', 'to', 'subject'] as const).includes(
    searchFieldRaw as never,
  )
    ? (searchFieldRaw as InboxFilters['searchField'])
    : defaults.searchField;
  const hasDraft = single(params.hasDraft) === '1';
  const partyIdRaw = single(params.party);
  const partyId = partyIdRaw && /^[0-9a-f-]{36}$/i.test(partyIdRaw) ? partyIdRaw : null;

  return {
    channel: channel as CommunicationChannel | 'all',
    direction: direction as CommunicationDirection | 'all',
    query,
    searchField,
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
  received_at: string | null;
  ai_generated: boolean;
  read_at: string | null;
  party_id: string | null;
  parties: { name: string; party_types: { code: string } | Array<{ code: string }> | null } | null;
  thread_id: string | null;
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
       subject, body_plain, occurred_at, sent_at, received_at, ai_generated, read_at,
       thread_id,
       party_id,
       parties:party_id ( name:party_name, party_types(code) )`,
      { count: 'exact' },
    );

  // filters
  query = query.is('deleted_at', null); // exclude soft-deleted

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
    const pattern = `%${escapeLikePattern(filters.query)}%`;
    // Field-scoped search. Note: to_addresses is text[], which PostgREST cannot
    // ilike directly, so the To scope (and the To part of "all") uses cs
    // (array-contains, exact element match). from/subject/body use ilike.
    switch (filters.searchField) {
      case 'from':
        query = query.or(
          `from_address.ilike.${pattern},from_name.ilike.${pattern}`,
        );
        break;
      case 'subject':
        query = query.ilike('subject', pattern);
        break;
      case 'to':
        // exact recipient address match (array element)
        query = query.contains('to_addresses', [filters.query]);
        break;
      case 'all':
      default:
        query = query.or(
          `from_address.ilike.${pattern},from_name.ilike.${pattern},subject.ilike.${pattern},body_plain.ilike.${pattern}`,
        );
        break;
    }
  }

  // sort: by the time WE received/handled the message, not the original
  // header date. Freshly pulled old mail has an old occurred_at but a recent
  // received_at; sorting by received_at keeps newly-arrived mail at the top.
  // received_at is null for outbound, so occurred_at is the fallback.
  query = query
    .order('received_at', { ascending: false, nullsFirst: false })
    .order('occurred_at', { ascending: false, nullsFirst: false })
    .order('id', { ascending: true });

  // pagination
  // t9a: fetch all matching messages (no server-side pagination);
  // JS-side group by thread, then paginate. TODO: server-side RPC if msg count > 1000.
  query = query.range(0, 999);

  const { data, error } = await query;
  if (error) {
    // eslint-disable-next-line no-console
    console.error('[queries/inbox.fetchInbox] failed:', error);
    return { rows: [], totalCount: 0, filters, pagination };
  }

  const rawRows = (data ?? []) as unknown as RawInboxRow[];

  // determine hasDraft - inbound communication IDs that exist in ai.drafts.inbound_communication_id
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

  const allRows: InboxRow[] = rawRows.map((r) => toInboxRow(r, draftsByInboundId));

  // t9a: group by threadId, pick latest representative + count + OR-aggregate hasDraft.
  // allRows is sorted by occurred_at desc, so first seen per thread IS the latest message.
  const threadMap = new Map<string, { latest: InboxRow; count: number; anyHasDraft: boolean; allRead: boolean }>();
  for (const row of allRows) {
    const existing = threadMap.get(row.threadId);
    if (existing) {
      existing.count += 1;
      if (row.hasDraft) existing.anyHasDraft = true;
      // a thread is unread if ANY of its inbound messages is unread
      existing.allRead = existing.allRead && row.isRead;
    } else {
      threadMap.set(row.threadId, { latest: row, count: 1, anyHasDraft: row.hasDraft, allRead: row.isRead });
    }
  }

  let rows: InboxRow[] = Array.from(threadMap.values()).map(({ latest, count, anyHasDraft, allRead }) => ({
    ...latest,
    threadCount: count,
    hasDraft: anyHasDraft,
    isRead: allRead,
  }));

  // the hasDraft filter is applied after fetching all rows above (perf ok - max 100 per page)
  if (filters.hasDraft) {
    rows = rows.filter((r) => r.hasDraft);
  }

  // t9a: JS-side pagination on threads (rows already thread-grouped above).
  const totalThreads = rows.length;
  const fromIdx = (pagination.page - 1) * pagination.pageSize;
  const pagedRows = rows.slice(fromIdx, fromIdx + pagination.pageSize);

  return {
    rows: pagedRows,
    totalCount: totalThreads,
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
  // D6-5e: party_type now via party_types(code) FK embed (parties.party_type dropped)
  
const ptJoin = party?.party_types;
  
const partyTypeCode = (Array.isArray(ptJoin) ? ptJoin[0]?.code : ptJoin?.code) ?? null;

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
    receivedAt: raw.received_at,
    sentAt: raw.sent_at,
    partyId: raw.party_id,
    partyName: party?.name ?? null,
    partyTypeCode: (partyTypeCode as PartyTypeCode | null) ?? null,
    hasDraft:
      raw.direction === 'inbound' && draftsByInboundId.has(raw.id),
    aiGenerated: raw.ai_generated,
    // Phase 1: attachment feature not implemented - no attachment_count column in the DB
    attachmentCount: 0,
    threadId: raw.thread_id ?? raw.id,
    threadCount: 1,
    // Outbound is always 'read'; inbound is read once read_at is set.
    isRead: raw.direction !== 'inbound' || raw.read_at !== null,
  };
}

/**
 * safely escape the ilike pattern - convert % and _ to literals.
 */
function escapeLikePattern(s: string): string {
  return s.replace(/[%_]/g, '\\$&').replace(/,/g, ''); // remove ',' to protect the PostgREST or() syntax
}
