/**
 * lib/queries/drafts.ts
 *
 * Server-side fetcher for the AI draft queue.
 *
 * RLS auto-isolates by the JWT's organization_id, so an explicit .eq('organization_id', ...) is unnecessary.
 * However, the Database stub is empty so .from() resolves to never; hence explicit type assertions.
 *
 * Default sort (`urgent`): confidence ASC, expires_at ASC (uses idx_drafts_queue_sort).
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import {
  CLASSIFICATION_CATEGORIES,
  type ClassificationCategory,
  type DraftStatus,
  type Language,
  type PartyTypeCode,
} from '@/types/ai';
import {
  DEFAULT_FILTERS,
  DEFAULT_PAGE_SIZE,
  DEFAULT_SORT,
  type DraftQueueFilters,
  type DraftQueuePagination,
  type DraftQueueResult,
  type DraftQueueRow,
  type DraftQueueSort,
  PAGE_SIZE_OPTIONS,
} from '@/types/draft-queue';

const ALL_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

const ALL_STATUSES: readonly DraftStatus[] = [
  'pending_review',
  'approved',
  'sent',
  'rejected',
  'expired',
  'auto_sent',
] as const;

const ALL_SORTS: readonly DraftQueueSort[] = [
  'urgent',
  'newest',
  'oldest',
  'confidence_high',
  'expiring_soon',
] as const;

/* ============================================================
 * Parse URL searchParams
 * ============================================================ */

export function parseFilters(
  params: Record<string, string | string[] | undefined>,
): DraftQueueFilters {
  const status = pickEnum(params.status, ALL_STATUSES, 'pending_review' as const);
  const module = pickEnum(params.partyType, ALL_MODULES, 'all' as const);
  const category = pickEnum(
    params.category,
    CLASSIFICATION_CATEGORIES,
    'all' as const,
  );
  const confRaw = single(params.conf);
  const minConfidence = confRaw ? clamp01(Number(confRaw)) : 0;
  const onlyRisky = single(params.risk) === '1';

  return {
    status: (status === 'pending_review' || status === 'all') && params.status === undefined
      ? 'pending_review'  // default
      : (status as DraftStatus | 'all'),
    partyType: module as PartyTypeCode | 'all',
    category: category as ClassificationCategory | 'all',
    minConfidence,
    onlyRisky,
  };
}

export function parseSort(
  params: Record<string, string | string[] | undefined>,
): DraftQueueSort {
  const raw = single(params.sort);
  if (raw && (ALL_SORTS as readonly string[]).includes(raw)) {
    return raw as DraftQueueSort;
  }
  return DEFAULT_SORT;
}

export function parsePagination(
  params: Record<string, string | string[] | undefined>,
): DraftQueuePagination {
  const pageRaw = Number(single(params.page) ?? '1');
  const sizeRaw = Number(single(params.size) ?? String(DEFAULT_PAGE_SIZE));
  const page = Number.isFinite(pageRaw) && pageRaw >= 1 ? Math.floor(pageRaw) : 1;
  const pageSize = (PAGE_SIZE_OPTIONS as readonly number[]).includes(sizeRaw)
    ? sizeRaw
    : DEFAULT_PAGE_SIZE;
  return { page, pageSize };
}

function single(v: string | string[] | undefined): string | undefined {
  if (Array.isArray(v)) return v[0];
  return v;
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

function clamp01(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

/* ============================================================
 * Server-side query
 * ============================================================ */

interface RawJoinedDraft {
  id: string;
  status: DraftStatus;
  partyType: PartyTypeCode | null;
  classification_category: ClassificationCategory | null;
  confidence_score: number | null;
  language: Language;
  subject: string | null;
  body_plain: string;
  final_body_plain: string | null;
  risk_flags: string[];
  requires_human_approval: boolean;
  auto_send_eligible: boolean;
  expires_at: string;
  created_at: string;
  party_id: string | null;
  engagement_id: string | null;
  parties: { name: string } | null;
  engagements: { name: string } | null;
  // an ssr joined select can return multiple rows as an array, which is ambiguous -
  // handle the case where it arrives as a single object. Use a type guard based on the actual query result.
  inbound_communication: {
    from_address: string | null;
    subject: string | null;
  } | null;
}
// ============================================================
// Using the contents of this file, replace only the single
// `export async function fetchDraftQueue(...)` function in src/lib/queries/drafts.ts.
// (leave the rest - RawJoinedDraft, toQueueRow, import statements, etc. - unchanged)
// ============================================================
//
// Reason for the change:
//   PostgREST cannot index cross-schema FK (ai.drafts -> app.parties / app.engagements
//   / app.communications) metadata into its cache - an environment issue.
//   There are cases not fixed even by a schema reload / project restart,
//   so we work around it by querying separately and merging in JS instead of a nested join.
//
// Impact:
//   - works 100% regardless of PostgREST cache state
//   - queries increase from 1 to 4 (drafts + parties + engagements + communications)
//   - the 3 auxiliary queries each run once via an in() clause, parallelized with Promise.all - negligible perf impact
//   - reassembled into the RawJoinedDraft shape so toQueueRow logic stays unchanged

export async function fetchDraftQueue(
  filters: DraftQueueFilters = DEFAULT_FILTERS,
  sort: DraftQueueSort = DEFAULT_SORT,
  pagination: DraftQueuePagination = { page: 1, pageSize: DEFAULT_PAGE_SIZE },
): Promise<DraftQueueResult> {
  const supabase = await createSupabaseServerClient();

  // sort -> SQL ORDER BY mapping
  const orderClauses: Array<{ column: string; ascending: boolean }> = [];
  switch (sort) {
    case 'urgent':
      orderClauses.push({ column: 'confidence_score', ascending: true });
      orderClauses.push({ column: 'expires_at', ascending: true });
      break;
    case 'newest':
      orderClauses.push({ column: 'created_at', ascending: false });
      break;
    case 'oldest':
      orderClauses.push({ column: 'created_at', ascending: true });
      break;
    case 'confidence_high':
      orderClauses.push({ column: 'confidence_score', ascending: false });
      break;
    case 'expiring_soon':
      orderClauses.push({ column: 'expires_at', ascending: true });
      break;
  }

  // ── [1] select only the drafts body (nested join removed) ──
  let query = supabase
    .schema('ai')
    .from('drafts' as never)
    .select(
      `id, status, partyType:party_type, classification_category, confidence_score, language,
       subject, body_plain, final_body_plain,
       risk_flags, requires_human_approval, auto_send_eligible,
       expires_at, created_at,
       party_id, engagement_id, inbound_communication_id`,
      { count: 'exact' },
    );

  // filters
  if (filters.status !== 'all') {
    query = query.eq('status', filters.status);
  }
  if (filters.partyType !== 'all') {
    query = query.eq('party_type', filters.partyType);
  }
  if (filters.category !== 'all') {
    query = query.eq('classification_category', filters.category);
  }
  if (filters.minConfidence > 0) {
    query = query.gte('confidence_score', filters.minConfidence);
  }
  if (filters.onlyRisky) {
    query = query.not('risk_flags', 'eq', '{}');
  }

  // sort
  for (const clause of orderClauses) {
    query = query.order(clause.column, {
      ascending: clause.ascending,
      nullsFirst: false,
    });
  }
  query = query.order('id', { ascending: true });

  // pagination
  const from = (pagination.page - 1) * pagination.pageSize;
  const to = from + pagination.pageSize - 1;
  query = query.range(from, to);

  const { data, error, count } = await query;

  if (error) {
    // eslint-disable-next-line no-console
    console.error('[queries/drafts.fetchDraftQueue] failed:', error);
    return {
      rows: [],
      totalCount: 0,
      filters,
      sort,
      pagination,
    };
  }

  // skip auxiliary queries on an empty result
  const draftRows = (data ?? []) as Array<{
    id: string;
    status: string;
    partyType: string | null;
    classification_category: string;
    confidence_score: number;
    language: string;
    subject: string;
    body_plain: string;
    final_body_plain: string | null;
    risk_flags: string[];
    requires_human_approval: boolean;
    auto_send_eligible: boolean;
    expires_at: string;
    created_at: string;
    party_id: string | null;
    engagement_id: string | null;
    inbound_communication_id: string | null;
  }>;

  if (draftRows.length === 0) {
    return {
      rows: [],
      totalCount: count ?? 0,
      filters,
      sort,
      pagination,
    };
  }

  // ── [2] collect auxiliary ids (deduplicated) ──
  const partyIds = Array.from(
    new Set(draftRows.map((d) => d.party_id).filter((v): v is string => !!v)),
  );
  const engagementIds = Array.from(
    new Set(draftRows.map((d) => d.engagement_id).filter((v): v is string => !!v)),
  );
  const communicationIds = Array.from(
    new Set(
      draftRows
        .map((d) => d.inbound_communication_id)
        .filter((v): v is string => !!v),
    ),
  );

  // ── [3] fetch auxiliary info in parallel ──
  const [partiesRes, engagementsRes, commsRes] = await Promise.all([
    partyIds.length > 0
      ? supabase
          .schema('app')
          .from('parties' as never)
          .select('id, name:party_name')
          .in('id', partyIds)
      : Promise.resolve({ data: [], error: null }),
    engagementIds.length > 0
      ? supabase
          .schema('app')
          .from('deals' as never)
          .select('id, deal_name')
          .in('id', engagementIds)
      : Promise.resolve({ data: [], error: null }),
    communicationIds.length > 0
      ? supabase
          .schema('app')
          .from('communications' as never)
          .select('id, from_address, subject')
          .in('id', communicationIds)
      : Promise.resolve({ data: [], error: null }),
  ]);

  // auxiliary lookup errors are non-fatal - just log and proceed with empty maps
  if (partiesRes.error) {
    // eslint-disable-next-line no-console
    console.error('[queries/drafts.fetchDraftQueue] parties lookup:', partiesRes.error);
  }
  if (engagementsRes.error) {
    // eslint-disable-next-line no-console
    console.error('[queries/drafts.fetchDraftQueue] engagements lookup:', engagementsRes.error);
  }
  if (commsRes.error) {
    // eslint-disable-next-line no-console
    console.error('[queries/drafts.fetchDraftQueue] communications lookup:', commsRes.error);
  }

  // ── [4] build maps (id -> row) ──
  const partyMap = new Map<string, { name: string }>();
  for (const p of (partiesRes.data ?? []) as Array<{ id: string; name: string }>) {
    partyMap.set(p.id, { name: p.name });
  }
  const engagementMap = new Map<string, { name: string }>();
  for (const e of (engagementsRes.data ?? []) as Array<{ id: string; deal_name: string }>) {
    engagementMap.set(e.id, { name: e.deal_name });
  }
  const commMap = new Map<string, { from_address: string | null; subject: string | null }>();
  for (const c of (commsRes.data ?? []) as Array<{
    id: string;
    from_address: string | null;
    subject: string | null;
  }>) {
    commMap.set(c.id, { from_address: c.from_address, subject: c.subject });
  }

  // ── [5] reassemble into the RawJoinedDraft shape ──
  const rawRows: RawJoinedDraft[] = draftRows.map((d) => ({
    ...d,
    parties: d.party_id ? partyMap.get(d.party_id) ?? null : null,
    engagements: d.engagement_id ? engagementMap.get(d.engagement_id) ?? null : null,
    inbound_communication: d.inbound_communication_id
      ? commMap.get(d.inbound_communication_id) ?? null
      : null,
  })) as unknown as RawJoinedDraft[];

  const rows: DraftQueueRow[] = rawRows.map(toQueueRow);

  return {
    rows,
    totalCount: count ?? 0,
    filters,
    sort,
    pagination,
  };
}
/**
 * Convert one SELECT result row into a DraftQueueRow.
 * Safely handle both cases where the join result arrives as a single object or an array.
 */
function toQueueRow(raw: RawJoinedDraft): DraftQueueRow {
  const party = extractFirst(raw.parties);
  const engagement = extractFirst(raw.engagements);
  const inbound = extractFirst(raw.inbound_communication);

  const bodyPreview = (raw.body_plain ?? '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 120);

  return {
    id: raw.id,
    status: raw.status,
    partyType: raw.partyType,
    classificationCategory: raw.classification_category,
    confidenceScore: raw.confidence_score,
    language: raw.language,
    subject: raw.subject,
    bodyPlainPreview: bodyPreview,
    riskFlags: raw.risk_flags ?? [],
    requiresHumanApproval: raw.requires_human_approval,
    autoSendEligible: raw.auto_send_eligible,
    hasEdits: raw.final_body_plain != null && raw.final_body_plain.length > 0,
    expiresAt: raw.expires_at,
    createdAt: raw.created_at,
    partyId: raw.party_id,
    partyName: party?.name ?? null,
    fromAddress: inbound?.from_address ?? null,
    inboundSubject: inbound?.subject ?? null,
    engagementId: raw.engagement_id,
    engagementName: engagement?.name ?? null,
  };
}

function extractFirst<T>(v: T | T[] | null | undefined): T | null {
  if (v == null) return null;
  if (Array.isArray(v)) return v[0] ?? null;
  return v;
}
