/**
 * lib/queries/drafts.ts
 *
 * Server-side fetcher for AI 초안 큐.
 *
 * RLS는 JWT의 organization_id로 자동 격리되므로 명시적 .eq('organization_id', ...) 불필요.
 * 다만 Database stub이 비어있어 .from() 결과가 never가 되므로 명시적 타입 단언 사용.
 *
 * 정렬 기본 (`urgent`): confidence ASC, expires_at ASC (idx_drafts_queue_sort 활용).
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import {
  CLASSIFICATION_CATEGORIES,
  type ClassificationCategory,
  type DraftStatus,
  type Language,
  type ModuleType,
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

const ALL_MODULES: readonly ModuleType[] = [
  'investor',
  'buyer',
  'partner',
  'customer',
  'crowdfunding',
  'product_launch',
  'sales',
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
 * URL searchParams 파싱
 * ============================================================ */

export function parseFilters(
  params: Record<string, string | string[] | undefined>,
): DraftQueueFilters {
  const status = pickEnum(params.status, ALL_STATUSES, 'pending_review' as const);
  const module = pickEnum(params.module, ALL_MODULES, 'all' as const);
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
      ? 'pending_review'  // 기본
      : (status as DraftStatus | 'all'),
    module: module as ModuleType | 'all',
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
  module: ModuleType | null;
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
  // ssr의 joined select는 다중 행도 array로 올 수 있어 ambiguous —
  // 단일 객체로 들어오는 경우 대비. 실제 쿼리 결과에 따라 type guard로 처리.
  inbound_communication: {
    from_address: string | null;
    subject: string | null;
  } | null;
}

export async function fetchDraftQueue(
  filters: DraftQueueFilters = DEFAULT_FILTERS,
  sort: DraftQueueSort = DEFAULT_SORT,
  pagination: DraftQueuePagination = { page: 1, pageSize: DEFAULT_PAGE_SIZE },
): Promise<DraftQueueResult> {
  const supabase = await createSupabaseServerClient();

  // 정렬 → SQL ORDER BY 매핑
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

  // SELECT 절: 조인 포함
  // 주의: stub 한계 때문에 from('drafts' as never) 캐스트
  let query = supabase
    .schema('ai')
    .from('drafts' as never)
    .select(
      `id, status, module, classification_category, confidence_score, language,
       subject, body_plain, final_body_plain,
       risk_flags, requires_human_approval, auto_send_eligible,
       expires_at, created_at,
       party_id, engagement_id,
       parties:party_id ( name ),
       engagements:engagement_id ( name ),
       inbound_communication:inbound_communication_id ( from_address, subject )`,
      { count: 'exact' },
    );

  // 필터
  if (filters.status !== 'all') {
    query = query.eq('status', filters.status);
  }
  if (filters.module !== 'all') {
    query = query.eq('module', filters.module);
  }
  if (filters.category !== 'all') {
    query = query.eq('classification_category', filters.category);
  }
  if (filters.minConfidence > 0) {
    query = query.gte('confidence_score', filters.minConfidence);
  }
  if (filters.onlyRisky) {
    // PostgREST: 배열 길이 > 0 필터 — risk_flags가 '{}' 아닌 행만
    // 'not.eq.{}' 또는 'not.is.null + array_length > 0' 패턴.
    // PostgREST array 비교: 'not.eq.{}' 사용.
    query = query.not('risk_flags', 'eq', '{}');
  }

  // 정렬
  for (const clause of orderClauses) {
    query = query.order(clause.column, {
      ascending: clause.ascending,
      nullsFirst: false,
    });
  }
  // 항상 마지막 tiebreaker로 id 추가 — 결정론적 페이지네이션
  query = query.order('id', { ascending: true });

  // 페이지네이션
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

  const rawRows = (data ?? []) as unknown as RawJoinedDraft[];
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
 * SELECT 결과 한 행을 DraftQueueRow로 변환.
 * 조인 결과가 단일 객체 또는 배열로 오는 케이스를 모두 안전 처리.
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
    module: raw.module,
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
