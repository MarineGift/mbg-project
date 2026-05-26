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
 * URL searchParams 파싱
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
      ? 'pending_review'  // 기본
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
  // ssr의 joined select는 다중 행도 array로 올 수 있어 ambiguous —
  // 단일 객체로 들어오는 경우 대비. 실제 쿼리 결과에 따라 type guard로 처리.
  inbound_communication: {
    from_address: string | null;
    subject: string | null;
  } | null;
}
// ============================================================
// 이 파일의 내용으로 src/lib/queries/drafts.ts 의
// `export async function fetchDraftQueue(...)` 함수 한 개만 교체.
// (다른 코드 — RawJoinedDraft, toQueueRow, import 문 등 — 은 그대로 둠)
// ============================================================
//
// 변경 사유:
//   PostgREST가 cross-schema FK (ai.drafts → app.parties / app.engagements
//   / app.communications) 메타데이터를 캐시에 인덱싱하지 못하는 환경 이슈.
//   schema reload / 프로젝트 재시작에도 해결 안 되는 케이스가 있어,
//   nested join 대신 별도 조회 후 JS에서 합치는 방식으로 우회.
//
// 영향:
//   - PostgREST 캐시 상태와 무관하게 100% 동작
//   - 쿼리 1개 → 4개로 증가 (drafts + parties + engagements + communications)
//   - 3개 보조 쿼리는 in() 절로 1회씩만 호출, Promise.all로 병렬 — 성능 영향 미미
//   - RawJoinedDraft 형식으로 재조립해서 toQueueRow 로직 그대로 유지

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

  // ── [1] drafts 본체만 select (nested join 제거) ─────────────
  let query = supabase
    .schema('ai')
    .from('drafts' as never)
    .select(
      `id, status, module, classification_category, confidence_score, language,
       subject, body_plain, final_body_plain,
       risk_flags, requires_human_approval, auto_send_eligible,
       expires_at, created_at,
       party_id, engagement_id, inbound_communication_id`,
      { count: 'exact' },
    );

  // 필터
  if (filters.status !== 'all') {
    query = query.eq('status', filters.status);
  }
  if (filters.partyType !== 'all') {
    query = query.eq('module', filters.partyType);
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

  // 정렬
  for (const clause of orderClauses) {
    query = query.order(clause.column, {
      ascending: clause.ascending,
      nullsFirst: false,
    });
  }
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

  // 빈 결과면 보조 쿼리 스킵
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

  // ── [2] 보조 id 모으기 (중복 제거) ──────────────────────────
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

  // ── [3] 보조 정보 병렬 조회 ─────────────────────────────────
  const [partiesRes, engagementsRes, commsRes] = await Promise.all([
    partyIds.length > 0
      ? supabase
          .schema('app')
          .from('parties' as never)
          .select('id, name')
          .in('id', partyIds)
      : Promise.resolve({ data: [], error: null }),
    engagementIds.length > 0
      ? supabase
          .schema('urm')
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

  // 보조 조회 에러는 치명적이지 않게 — 로그만 남기고 빈 맵으로 진행
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

  // ── [4] Map 생성 (id → 행) ──────────────────────────────────
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

  // ── [5] RawJoinedDraft 형식으로 재조립 ─────────────────────
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
