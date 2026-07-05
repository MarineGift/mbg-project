/**
 * lib/queries/party-detail.ts
 *
 * Fetch data for the party (parties) detail screen.
 *   - the parties row body
 *   - statistics (contacts/communications/drafts/engagements/tasks counts)
 *   - recent activity timeline (communications + tasks merged chronologically)
 *   - contacts / engagements / tasks sidebar lists
 *
 * RLS auto-validates organization_id.
 *
 * Change history:
 *   - 2026-05-11: aligned column names with the actual schema (industry -> industry_tags,
 *                 tags -> interest_tags). Added a deleted_at filter, strengthened error logging.
 *   - 2026-05-11: 1:1 mapping to match the cleaned-up PartyDetail interface.
 *   - 2026-05-12: fixed the contacts SELECT column name job_title -> title.
 *   - 2026-05-12: in the engagements SELECT, stage -> current_stage_id,
 *                 close_date -> expected_close_date + a pipeline_stages
 *                 JOIN to get the stage name. The openEngagements count
 *                 filter's status enum values were matched to the actual schema.
 *   - 2026-05-14: Phase 6 - industry_paper_company_id /
 *                 Added the industry_filler_supplier_id FK column to the SELECT + mapping.
 *   - 2026-06-11: added app.contact_profiles enrichment via a separate parallel
 *                 fetch + in-memory join (no PostgREST embed; the table is new and
 *                 the relationship may not be in the schema cache yet).
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { PartyTypeCode } from '@/types/ai';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
} from '@/types/inbox';
import type {
  ContactProfile,
  PartyContact,
  PartyDetail,
  PartyDetailFull,
  PartyEngagement,
  PartyStatus,
  PartyTask,
  PartyTier,
  TimelineCommunicationItem,
  TimelineItem,
  TimelineTaskItem, InvestorProfile, InvestorPriority } from '@/types/party-detail';

interface RawPartyRow {
  id: string;
  organization_id: string;
  party_name: string;
  party_type_id: string;
  status: PartyStatus;
  country_code: string | null;
  city: string | null;
  region: string | null;
  website: string | null;
  interest_tags: string[];   // NOT NULL in DB
  notes: string | null;
  source: string | null;
  intro_ko: string | null;
  intro_en: string | null;
  email: string | null;
  street_address: string | null;
  created_at: string;
  updated_at: string;
  // Phase 6 (2026-05-14)
}

const TIMELINE_LIMIT = 30;
const SIDEBAR_LIMIT = 10;
const MEETINGS_LIMIT = 100;  // 2026-05-19

/**
 * status values to exclude when counting an engagement as "Open".
 * Must match the actual app.engagement_status enum.
 * (won, lost, archived are terminal states)
 */
const TERMINAL_ENGAGEMENT_STATUSES = new Set([
  'won',
  'lost',
  'archived',
]);

// ============================================================
// 2026-05-19: meeting-related types (app.meetings)
// Note: the meeting_mode column does not exist in the DB.
// To be reorganized into the channel enum in Stage 24.
// ============================================================

export type MeetingStatus =
  | 'scheduled'
  | 'completed'
  | 'cancelled'
  | 'no_show'
  | 'rescheduled';

export interface MeetingAttendeeRef {
  name?: string;
  email?: string;
  role?: string;
  party_id?: string;
  response?: 'no_response' | 'accepted' | 'declined' | 'tentative';
}

export interface PartyMeeting {
  id: string;
  partyId: string;
  engagementId: string | null;
  meetingType: string;
  title: string;
  agenda: string | null;
  notes: string | null;
  aiSummary: string | null;
  outcome: string | null;
  nextSteps: string | null;
  occurredAt: string;
  scheduledAt: string | null;
  actualStartedAt: string | null;
  actualEndedAt: string | null;
  durationMin: number | null;
  attendees: MeetingAttendeeRef[] | null;
  status: MeetingStatus;
  location: string | null;
  meetingUrl: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PartyMeetingStats {
  total: number;
  completed: number;
  scheduled: number;
  upcoming: number;
  lastOccurredAt: string | null;
  nextScheduledAt: string | null;
}

export async function fetchPartyDetail(
  partyId: string,
): Promise<PartyDetailFull | null> {
  const supabase = await createSupabaseServerClient();

  // party body
  const { data: partyRaw, error: partyErr } = await supabase
    .schema('app')
    .from('parties' as never)
    .select(
      'id, organization_id, party_name, party_type_id, status, country_code, city, region, website, email, street_address, interest_tags, notes, source, intro_ko, intro_en, created_at, updated_at',
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

  // Normalized canonical tags are the source of truth for interestTags so the
  // edit form round-trips the same set the directory shows (legacy jsonb is
  // the fallback for parties not yet backfilled / non-investors).
  let normalizedInterestTags: string[] = [];
  {
    const { data: prof } = await supabase
      .schema('app')
      .from('investor_profile' as never)
      .select('id')
      .eq('party_id', partyId)
      .maybeSingle();
    const profileId = (prof as { id: string } | null)?.id;
    if (profileId) {
      const [{ data: linkRows }, { data: tagRows }] = await Promise.all([
        supabase
          .schema('app')
          .from('investor_interest_tags' as never)
          .select('interest_tag_id')
          .eq('investor_profile_id', profileId),
        supabase
          .schema('app')
          .from('interest_tags' as never)
          .select('id, code, sort_order'),
      ]);
      const byId = new Map<number, { code: string; sort: number }>();
      for (const t of ((tagRows ?? []) as any[])) {
        byId.set(t.id, { code: t.code, sort: t.sort_order ?? 9999 });
      }
      normalizedInterestTags = ((linkRows ?? []) as any[])
        .map((l) => byId.get(l.interest_tag_id))
        .filter((x): x is { code: string; sort: number } => !!x)
        .sort((a, b) => a.sort - b.sort || a.code.localeCompare(b.code))
        .map((x) => x.code);
    }
  }

  // fetch statistics + sidebar lists + timeline in parallel
  const [
    contactsRes,
    engagementsRes,
    tasksRes,
    commsRes,
    pendingDraftsCountRes,
  ] = await Promise.all([
    // contacts list (10) + count
    supabase
      .schema('app')
      .from('contacts' as never)
      .select('id, full_name, email, title_text, phone_e164, is_primary, notes', {
        count: 'exact',
      })
      .eq('party_id', partyId)
      .is('deleted_at', null)
      .order('is_primary', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(SIDEBAR_LIMIT),

    // engagements (10) - fetch stage name via a pipeline_stages JOIN
    supabase
      .schema('app')
      .from('deals' as never)
      .select(
        `id, deal_name, status, current_stage_id, value_amount, value_currency,
         expected_close_date, updated_at,
         stages:current_stage_id ( name )`,
        { count: 'exact' },
      )
      .eq('party_id', partyId)
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(SIDEBAR_LIMIT),

    // tasks (10)
    // D6-5e stub: tasks.party_id removed; tasks now FK to app.deals.
    // Re-implement via deal_id JOIN once deals exist. For now: empty result.
    Promise.resolve({ data: [] as unknown[], error: null, count: 0 } as any),

    // communications (30) - for the timeline
    supabase
      .schema('app')
      .from('communications' as never)
      .select(
        'id, channel, direction, status, subject, body_plain, from_address, occurred_at, ai_generated',
        { count: 'exact' },
      )
      .eq('party_id', partyId)
      .is('deleted_at', null)
      .order('occurred_at', { ascending: false })
      .limit(TIMELINE_LIMIT),

    // pending draft count (ai schema - ai must be included in Exposed schemas)
    supabase
      .schema('ai')
      .from('drafts' as never)
      .select('id', { count: 'exact', head: true })
      .eq('party_id', partyId)
      .eq('status', 'pending_review'),
  ]);

  // log parallel query errors (avoid silent swallow - data falls back to empty values but
  // errors are always logged)
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

  // contact_profiles enrichment - separate fetch keyed by the contact ids we got.
  // In-memory join (no embed): the table is new; embedding risks a stale schema cache.
  const contactRows = (contactsRes.data ?? []) as Array<{ id: string }>;
  const contactIds = contactRows.map((c) => c.id);
  const profilesByContact = new Map<string, ContactProfile>();
  if (contactIds.length > 0) {
    const profilesRes = await supabase
      .schema('app')
      .from('contact_profiles' as never)
      .select(
        'contact_id, coverage_region, location_text, board_roles, mbg_fit_rating, mbg_fit_note, entry_channel, verified_at, verify_source',
      )
      .in('contact_id', contactIds);

    if (profilesRes.error) {
      console.error('[party-detail] contact_profiles error:', profilesRes.error);
    } else {
      for (const raw of (profilesRes.data ?? []) as unknown[]) {
        const r = raw as Record<string, unknown>;
        const cid = r.contact_id as string;
        profilesByContact.set(cid, {
          coverageRegion: (r.coverage_region as string | null) ?? null,
          locationText: (r.location_text as string | null) ?? null,
          boardRoles: (r.board_roles as string | null) ?? null,
          mbgFitRating: (r.mbg_fit_rating as ContactProfile['mbgFitRating']) ?? null,
          mbgFitNote: (r.mbg_fit_note as string | null) ?? null,
          entryChannel: (r.entry_channel as string | null) ?? null,
          verifiedAt: (r.verified_at as string | null) ?? null,
          verifySource: (r.verify_source as string | null) ?? null,
        });
      }
    }
  }

  // contact_emails (all emails per contact, primary first). Separate fetch -
  // new table; embedding risks a stale PostgREST schema cache.
  const emailsByContact = new Map<string, { email: string; isPrimary: boolean; label: string | null }[]>();
  if (contactIds.length > 0) {
    const emailsRes = await supabase
      .schema('app')
      .from('contact_emails' as never)
      .select('contact_id, email, is_primary, label')
      .in('contact_id', contactIds);
    if (emailsRes.error) {
      console.error('[party-detail] contact_emails error:', emailsRes.error);
    } else {
      for (const raw of (emailsRes.data ?? []) as unknown[]) {
        const r = raw as Record<string, unknown>;
        const cid = r.contact_id as string;
        const arr = emailsByContact.get(cid) ?? [];
        arr.push({
          email: (r.email as string) ?? '',
          isPrimary: (r.is_primary as boolean) ?? false,
          label: (r.label as string | null) ?? null,
        });
        emailsByContact.set(cid, arr);
      }
      for (const arr of emailsByContact.values()) {
        arr.sort((a, b) => Number(b.isPrimary) - Number(a.isPrimary));
      }
    }
  }

  const contacts: PartyContact[] = ((contactsRes.data ?? []) as unknown[]).map(
    (raw) => mapContact(raw, profilesByContact, emailsByContact),
  );
  const engagements: PartyEngagement[] = (
    (engagementsRes.data ?? []) as unknown[]
  ).map(mapEngagement);
  const tasks: PartyTask[] = ((tasksRes.data ?? []) as unknown[]).map(mapTask);

  // PartyDetail mapping - 1:1 with DB columns
  // D6-5e: party_type code via party_types lookup (col is now party_type_id FK)
  const { data: ptCodeRow } = await supabase
    .schema('app')
    .from('party_types' as never)
    .select('code')
    .eq('id', p.party_type_id)
    .maybeSingle();
  const partyTypeCode = ((ptCodeRow as { code?: string } | null)?.code ?? 'paper_mill') as PartyTypeCode;

  const detail: PartyDetail = {
    id: p.id,
    organizationId: p.organization_id,
    name: p.party_name,
    partyType: partyTypeCode,
    tier: null,
    status: p.status,
    countryCode: p.country_code,
    city: p.city,
    region: p.region,
    website: p.website,
    industryTags: [],
    interestTags: normalizedInterestTags.length > 0 ? normalizedInterestTags : p.interest_tags,
    notes: p.notes,
    source: p.source,
    introKo: p.intro_ko,
    introEn: p.intro_en,
    email: p.email,
    streetAddress: p.street_address,
    createdAt: p.created_at,
    updatedAt: p.updated_at,
    // Phase 6 (2026-05-14)
    industryPaperCompanyId: null,
    industryFillerSupplierId: null,
    counts: {
      contacts: contactsRes.count ?? 0,
      communications: commsRes.count ?? 0,
      pendingDrafts: pendingDraftsCountRes.count ?? 0,
      // open engagement: those not in a terminal status (won/lost/archived)
      openEngagements: ((engagementsRes.data ?? []) as Array<{ status: string }>)
        .filter((e) => !TERMINAL_ENGAGEMENT_STATUSES.has(e.status))
        .length,
      openTasks: ((tasksRes.data ?? []) as Array<{ status: string }>)
        .filter((t) => !['done', 'cancelled'].includes(t.status))
        .length,
    },
  };

  // timeline - communications + recently completed tasks merged
  const timeline = buildTimeline(
    (commsRes.data ?? []) as unknown[],
    (tasksRes.data ?? []) as unknown[],
  );

  // investor profile (1:1 via party_id) - only meaningful for investor parties
  let investorProfile: InvestorProfile | null = null;
  if (partyTypeCode === 'investor') {
    const { data: ipRow } = await supabase
      .schema('app')
      .from('investor_profile' as never)
      .select(
        'priority, fund_name, investor_type_id, fund_size_usd, aum_usd, fund_vintage_year, ' +
        'ticket_min_usd, ticket_max_usd, sector_focus, ' +
        'is_lead_investor, is_strategic, ' +
        'type:investor_type_id(code, display_name, category)',
      )
      .eq('party_id', partyId)
      .maybeSingle();
    investorProfile = ipRow ? mapInvestorProfile(ipRow) : emptyInvestorProfile();
  }

  return {    party: detail,
    contacts,
    engagements,
    tasks,
    timeline,
    investorProfile,
  };
}

/* ============================================================
 * mappers
 * ============================================================ */

function mapContact(
  raw: unknown,
  profilesByContact: Map<string, ContactProfile>,
  emailsByContact: Map<string, { email: string; isPrimary: boolean; label: string | null }[]>,
): PartyContact {
  const r = raw as Record<string, unknown>;
  const id = r.id as string;
  return {
    id,
    fullName: (r.full_name as string | null) ?? null,
    email: (r.email as string | null) ?? null,
    jobTitle: (r.title_text as string | null) ?? null,
    phone: (r.phone_e164 as string | null) ?? null,
    notes: (r.notes as string | null) ?? null,
    isPrimary: (r.is_primary as boolean) ?? false,
    emails: emailsByContact.get(id) ?? [],
    profile: profilesByContact.get(id),
  };
}

function mapEngagement(raw: unknown): PartyEngagement {
  const r = raw as Record<string, unknown>;
  // Supabase may return a nested join as an object or an array - handle both
  const stageJoin = r.stages;
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
    name: (r.deal_name as string) ?? '',
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

  // sort in reverse chronological order
  items.sort((a, b) => {
    return new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime();
  });

  return items.slice(0, TIMELINE_LIMIT);
}

// ============================================================
// 2026-05-19: meeting query functions (direction Y - meeting_mode column unused)
// ============================================================

const MEETING_SELECT_COLS = [
  'id', 'party_id', 'engagement_id', 'meeting_type', 'title',
  'agenda', 'notes', 'ai_summary', 'outcome', 'next_steps',
  'occurred_at', 'scheduled_at', 'actual_started_at', 'actual_ended_at',
  'duration_min', 'status', 'location', 'meeting_url',
  'created_at', 'updated_at',
].join(', ');

export async function fetchPartyMeetings(
  partyId: string,
  limit: number = MEETINGS_LIMIT,
): Promise<PartyMeeting[]> {
  if (!partyId) return [];
  const supabase = await createSupabaseServerClient();

  const { data, error } = await supabase
    .schema('app')
    .from('meetings' as never)
    .select(MEETING_SELECT_COLS)
    .eq('party_id', partyId)
    .order('occurred_at', { ascending: false, nullsFirst: false })
    .limit(limit);

  if (error) {
    console.error('[party-detail] meetings fetch error:', error);
    return [];
  }
  return ((data ?? []) as unknown[]).map(mapMeeting);
}

export async function fetchUpcomingPartyMeetings(
  partyId: string,
): Promise<PartyMeeting[]> {
  if (!partyId) return [];
  const supabase = await createSupabaseServerClient();

  const nowIso = new Date().toISOString();
  const { data, error } = await supabase
    .schema('app')
    .from('meetings' as never)
    .select(MEETING_SELECT_COLS)
    .eq('party_id', partyId)
    .eq('status', 'scheduled')
    .gte('scheduled_at', nowIso)
    .order('scheduled_at', { ascending: true })
    .limit(SIDEBAR_LIMIT);

  if (error) {
    console.error('[party-detail] upcoming meetings error:', error);
    return [];
  }
  return ((data ?? []) as unknown[]).map(mapMeeting);
}

export async function fetchPartyMeetingStats(
  partyId: string,
): Promise<PartyMeetingStats> {
  const empty: PartyMeetingStats = {
    total: 0,
    completed: 0,
    scheduled: 0,
    upcoming: 0,
    lastOccurredAt: null,
    nextScheduledAt: null,
  };
  if (!partyId) return empty;

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('meetings' as never)
    .select('status, occurred_at, scheduled_at')
    .eq('party_id', partyId);

  if (error) {
    console.error('[party-detail] meeting stats error:', error);
    return empty;
  }

  const rows = (data ?? []) as Array<{
    status: MeetingStatus;
    occurred_at: string | null;
    scheduled_at: string | null;
  }>;
  const nowMs = Date.now();

  const occurredTimes = rows
    .map((r) => r.occurred_at)
    .filter((v): v is string => !!v)
    .sort();
  const upcomingTimes = rows
    .filter(
      (r) =>
        r.status === 'scheduled' &&
        r.scheduled_at &&
        new Date(r.scheduled_at).getTime() >= nowMs,
    )
    .map((r) => r.scheduled_at as string)
    .sort();

  return {
    total: rows.length,
    completed: rows.filter((r) => r.status === 'completed').length,
    scheduled: rows.filter((r) => r.status === 'scheduled').length,
    upcoming: upcomingTimes.length,
    lastOccurredAt: occurredTimes.length
      ? (occurredTimes[occurredTimes.length - 1] ?? null)
      : null,
    nextScheduledAt: upcomingTimes.length ? (upcomingTimes[0] ?? null) : null,
  };
}

function mapMeeting(raw: unknown): PartyMeeting {
  const r = raw as Record<string, unknown>;
  const rawAttendees = r.attendees;
  let attendees: MeetingAttendeeRef[] | null = null;
  if (Array.isArray(rawAttendees)) {
    attendees = rawAttendees as MeetingAttendeeRef[];
  } else if (rawAttendees && typeof rawAttendees === 'object') {
    attendees = [rawAttendees as MeetingAttendeeRef];
  }

  return {
    id: r.id as string,
    partyId: r.party_id as string,
    engagementId: (r.engagement_id as string | null) ?? null,
    meetingType: (r.meeting_type as string) ?? '',
    title: (r.title as string) ?? '',
    agenda: (r.agenda as string | null) ?? null,
    notes: (r.notes as string | null) ?? null,
    aiSummary: (r.ai_summary as string | null) ?? null,
    outcome: (r.outcome as string | null) ?? null,
    nextSteps: (r.next_steps as string | null) ?? null,
    occurredAt: r.occurred_at as string,
    scheduledAt: (r.scheduled_at as string | null) ?? null,
    actualStartedAt: (r.actual_started_at as string | null) ?? null,
    actualEndedAt: (r.actual_ended_at as string | null) ?? null,
    durationMin:
      typeof r.duration_min === 'number'
        ? r.duration_min
        : r.duration_min != null
          ? Number(r.duration_min)
          : null,
    attendees,
    status: r.status as MeetingStatus,
    location: (r.location as string | null) ?? null,
    meetingUrl: (r.meeting_url as string | null) ?? null,
    createdAt: r.created_at as string,
    updatedAt: r.updated_at as string,
  };
}

function emptyInvestorProfile(): InvestorProfile {
  return {
    priority: null,
    fundName: null,
    typeCode: null,
    typeName: null,
    investorCategory: null,
    fundSizeUsd: null,
    aumUsd: null,
    fundVintageYear: null,
    ticketMinUsd: null,
    ticketMaxUsd: null,
    sectorFocus: [],
    geographicFocus: [],
    isLeadInvestor: false,
    isStrategic: false,
  };
}

function mapInvestorProfile(raw: unknown): InvestorProfile {
  const r = raw as Record<string, unknown>;
  const num = (v: unknown) => (typeof v === 'number' ? v : v == null ? null : Number(v));
  const arr = (v: unknown) => (Array.isArray(v) ? (v as string[]) : []);
  const t = Array.isArray(r.type) ? ((r.type as unknown[])[0] ?? null) : (r.type ?? null);
  const tt = t as { code?: string; display_name?: string; category?: string } | null;
  return {
    priority: (r.priority as InvestorPriority | null) ?? null,
    fundName: (r.fund_name as string | null) ?? null,
    typeCode: tt?.code ?? null,
    typeName: tt?.display_name ?? null,
    investorCategory: tt?.category ?? null,
    fundSizeUsd: num(r.fund_size_usd),
    aumUsd: num(r.aum_usd),
    fundVintageYear: (r.fund_vintage_year as number | null) ?? null,
    ticketMinUsd: num(r.ticket_min_usd),
    ticketMaxUsd: num(r.ticket_max_usd),
    sectorFocus: arr(r.sector_focus),
    geographicFocus: [],  // column dropped 2026-07-04
    isLeadInvestor: (r.is_lead_investor as boolean) ?? false,
    isStrategic: (r.is_strategic as boolean) ?? false,
  };
}
