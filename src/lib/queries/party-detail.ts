/**
 * lib/queries/party-detail.ts
 *
 * 거래처(parties) 상세 화면 데이터 fetch.
 *   - parties 행 본체
 *   - 통계 (contacts/communications/drafts/engagements/tasks 카운트)
 *   - 최근 활동 타임라인 (communications + tasks 통합 시간순)
 *   - 컨택트 / 인게이지먼트 / 태스크 사이드바 목록
 *
 * RLS가 organization_id 자동 검증.
 *
 * 변경 이력:
 *   - 2026-05-11: 실제 스키마와 컬럼명 정합 (industry → industry_tags,
 *                 tags → interest_tags). deleted_at 필터 추가, 에러 로깅 강화.
 *   - 2026-05-11: PartyDetail 인터페이스 정리에 맞춰 1:1 매핑.
 *   - 2026-05-12: contacts SELECT의 job_title → title 컬럼명 수정.
 *   - 2026-05-12: engagements SELECT의 stage → current_stage_id,
 *                 close_date → expected_close_date 수정 + pipeline_stages
 *                 JOIN으로 stage 이름 가져오기. openEngagements 카운트
 *                 필터의 status enum 값을 실제 schema와 일치시킴.
 *   - 2026-05-14: Phase 6 — industry_paper_company_id /
 *                 industry_filler_supplier_id FK 컬럼 SELECT + mapping 추가.
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { ModuleType } from '@/types/ai';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
} from '@/types/inbox';
import type {
  PartyContact,
  PartyDetail,
  PartyDetailFull,
  PartyEngagement,
  PartyStatus,
  PartyTask,
  PartyTier,
  TimelineCommunicationItem,
  TimelineItem,
  TimelineTaskItem,
} from '@/types/party-detail';

interface RawPartyRow {
  id: string;
  organization_id: string;
  name: string;
  module: ModuleType;
  tier: PartyTier | null;
  status: PartyStatus;
  country_code: string | null;
  website: string | null;
  industry_tags: string[];   // NOT NULL in DB
  interest_tags: string[];   // NOT NULL in DB
  notes: string | null;
  source: string | null;
  created_at: string;
  updated_at: string;
  // ▼ Phase 6 (2026-05-14)
  industry_paper_company_id: number | null;
  industry_filler_supplier_id: number | null;
}

const TIMELINE_LIMIT = 30;
const SIDEBAR_LIMIT = 10;

/**
 * "Open" engagement로 카운트할 때 제외할 status 값.
 * 실제 app.engagement_status enum과 일치해야 함.
 * (won, lost, archived는 종료 상태)
 */
const TERMINAL_ENGAGEMENT_STATUSES = new Set([
  'won',
  'lost',
  'archived',
]);

export async function fetchPartyDetail(
  partyId: string,
): Promise<PartyDetailFull | null> {
  const supabase = await createSupabaseServerClient();

  // 거래처 본체
  const { data: partyRaw, error: partyErr } = await supabase
    .schema('app')
    .from('parties' as never)
    .select(
      'id, organization_id, name, module, tier, status, country_code, website, industry_tags, interest_tags, notes, source, created_at, updated_at, industry_paper_company_id, industry_filler_supplier_id',
    )
    .eq('id', partyId)
    .is('deleted_at', null)
    .maybeSingle();

  if (partyErr) {
    console.error('[party-detail] parties fetch error:', partyErr);
    return null;
  }
  if (!partyRaw) {
    return null;
  }
  const p = partyRaw as unknown as RawPartyRow;

  // 통계 + 사이드바 목록 + 타임라인 병렬 fetch
  const [
    contactsRes,
    engagementsRes,
    tasksRes,
    commsRes,
    pendingDraftsCountRes,
  ] = await Promise.all([
    // contacts 목록 (10개) + 카운트
    supabase
      .schema('app')
      .from('contacts' as never)
      .select('id, full_name, email, title, phone, is_primary', {
        count: 'exact',
      })
      .eq('party_id', partyId)
      .order('is_primary', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(SIDEBAR_LIMIT),

    // engagements (10개) — pipeline_stages JOIN으로 stage 이름 함께 fetch
    supabase
      .schema('app')
      .from('engagements' as never)
      .select(
        `id, name, status, current_stage_id, value_amount, value_currency,
         expected_close_date, updated_at,
         pipeline_stages:current_stage_id ( name )`,
        { count: 'exact' },
      )
      .eq('party_id', partyId)
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(SIDEBAR_LIMIT),

    // tasks (10개)
    supabase
      .schema('app')
      .from('tasks' as never)
      .select('id, title, status, priority, due_at, created_at', {
        count: 'exact',
      })
      .eq('party_id', partyId)
      .order('created_at', { ascending: false })
      .limit(SIDEBAR_LIMIT),

    // communications (30개) — 타임라인용
    supabase
      .schema('app')
      .from('communications' as never)
      .select(
        'id, channel, direction, status, subject, body_plain, from_address, occurred_at, ai_generated',
        { count: 'exact' },
      )
      .eq('party_id', partyId)
      .order('occurred_at', { ascending: false })
      .limit(TIMELINE_LIMIT),

    // pending draft 카운트 (ai 스키마 — Exposed schemas에 ai 포함 필요)
    supabase
      .schema('ai')
      .from('drafts' as never)
      .select('id', { count: 'exact', head: true })
      .eq('party_id', partyId)
      .eq('status', 'pending_review'),
  ]);

  // 병렬 쿼리 에러 로깅 (silent swallow 방지 — 데이터는 빈 값으로 fallback하되
  // 에러는 반드시 로그에 남김)
  if (contactsRes.error) {
    console.error('[party-detail] contacts error:', contactsRes.error);
  }
  if (engagementsRes.error) {
    console.error('[party-detail] engagements error:', engagementsRes.error);
  }
  if (tasksRes.error) {
    console.error('[party-detail] tasks error:', tasksRes.error);
  }
  if (commsRes.error) {
    console.error('[party-detail] communications error:', commsRes.error);
  }
  if (pendingDraftsCountRes.error) {
    console.error(
      '[party-detail] ai.drafts error (check ai schema is exposed):',
      pendingDraftsCountRes.error,
    );
  }

  const contacts: PartyContact[] = ((contactsRes.data ?? []) as unknown[]).map(
    mapContact,
  );
  const engagements: PartyEngagement[] = (
    (engagementsRes.data ?? []) as unknown[]
  ).map(mapEngagement);
  const tasks: PartyTask[] = ((tasksRes.data ?? []) as unknown[]).map(mapTask);

  // PartyDetail 매핑 — DB 컬럼과 1:1 대응
  const detail: PartyDetail = {
    id: p.id,
    organizationId: p.organization_id,
    name: p.name,
    module: p.module,
    tier: p.tier,
    status: p.status,
    countryCode: p.country_code,
    website: p.website,
    industryTags: p.industry_tags,
    interestTags: p.interest_tags,
    notes: p.notes,
    source: p.source,
    createdAt: p.created_at,
    updatedAt: p.updated_at,
    // ▼ Phase 6 (2026-05-14)
    industryPaperCompanyId: p.industry_paper_company_id,
    industryFillerSupplierId: p.industry_filler_supplier_id,
    counts: {
      contacts: contactsRes.count ?? 0,
      communications: commsRes.count ?? 0,
      pendingDrafts: pendingDraftsCountRes.count ?? 0,
      // open engagement: terminal status (won/lost/archived)가 아닌 것
      openEngagements: ((engagementsRes.data ?? []) as Array<{ status: string }>)
        .filter((e) => !TERMINAL_ENGAGEMENT_STATUSES.has(e.status))
        .length,
      openTasks: ((tasksRes.data ?? []) as Array<{ status: string }>)
        .filter((t) => !['done', 'cancelled'].includes(t.status))
        .length,
    },
  };

  // 타임라인 — communications + 최근 완료된 tasks 통합
  const timeline = buildTimeline(
    (commsRes.data ?? []) as unknown[],
    (tasksRes.data ?? []) as unknown[],
  );

  return {
    party: detail,
    contacts,
    engagements,
    tasks,
    timeline,
  };
}

/* ============================================================
 * 매퍼
 * ============================================================ */

function mapContact(raw: unknown): PartyContact {
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    fullName: (r.full_name as string | null) ?? null,
    email: (r.email as string | null) ?? null,
    jobTitle: (r.title as string | null) ?? null,
    phone: (r.phone as string | null) ?? null,
    isPrimary: (r.is_primary as boolean) ?? false,
  };
}

function mapEngagement(raw: unknown): PartyEngagement {
  const r = raw as Record<string, unknown>;
  // Supabase가 nested join을 객체 또는 배열로 반환할 수 있음 — 둘 다 처리
  const stageJoin = r.pipeline_stages;
  let stageName: string | null = null;
  if (stageJoin) {
    if (Array.isArray(stageJoin) && stageJoin.length > 0) {
      stageName = (stageJoin[0] as { name?: string }).name ?? null;
    } else if (typeof stageJoin === 'object') {
      stageName = (stageJoin as { name?: string }).name ?? null;
    }
  }

  return {
    id: r.id as string,
    name: (r.name as string) ?? '',
    status: (r.status as string) ?? '',
    stage: stageName,
    valueAmount:
      typeof r.value_amount === 'number'
        ? r.value_amount
        : r.value_amount != null
          ? Number(r.value_amount)
          : null,
    valueCurrency: (r.value_currency as string) ?? 'USD',
    closeDate: (r.expected_close_date as string | null) ?? null,
    updatedAt: r.updated_at as string,
  };
}

function mapTask(raw: unknown): PartyTask {
  const r = raw as Record<string, unknown>;
  return {
    id: r.id as string,
    title: (r.title as string) ?? '',
    status: (r.status as string) ?? '',
    priority: (r.priority as string | null) ?? null,
    dueAt: (r.due_at as string | null) ?? null,
    createdAt: r.created_at as string,
  };
}

function buildTimeline(
  comms: unknown[],
  tasks: unknown[],
): TimelineItem[] {
  const items: TimelineItem[] = [];

  for (const raw of comms) {
    const r = raw as Record<string, unknown>;
    const bodyPlain = (r.body_plain as string | null) ?? '';
    const item: TimelineCommunicationItem = {
      kind: 'communication',
      id: r.id as string,
      occurredAt: r.occurred_at as string,
      channel: r.channel as CommunicationChannel,
      direction: r.direction as CommunicationDirection,
      status: r.status as CommunicationStatus,
      subject: (r.subject as string | null) ?? null,
      bodyPreview: bodyPlain.replace(/\s+/g, ' ').trim().slice(0, 120),
      fromAddress: (r.from_address as string | null) ?? null,
      aiGenerated: (r.ai_generated as boolean) ?? false,
    };
    items.push(item);
  }

  for (const raw of tasks) {
    const r = raw as Record<string, unknown>;
    const item: TimelineTaskItem = {
      kind: 'task',
      id: r.id as string,
      occurredAt: r.created_at as string,
      event: 'created',
      title: (r.title as string) ?? '',
      status: (r.status as string) ?? '',
      priority: (r.priority as string | null) ?? null,
      dueAt: (r.due_at as string | null) ?? null,
    };
    items.push(item);
  }

  // 시간 역순 정렬
  items.sort((a, b) => {
    return new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime();
  });

  return items.slice(0, TIMELINE_LIMIT);
}
