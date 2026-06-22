// src/lib/queries/meetings.ts
//
// Engagement-first meeting domain.
//
// Stage 24 (2026-05-21) rewrite:
//   - dropped meeting_mode (no DB column) -> use channel (engagement_channel enum)
//   - added stage_id (pipeline_stages FK)
//   - dropped attendees jsonb -> meeting_attendees table as the single source
//   - added engagement-first queries (by engagement / stage / party)
//   - new recordMeetingOutcome + attendee mutations
//   - as never cast (workaround for Supabase types' never inference)
//
// DB schema alignment:
//   app.meetings (party_id NOT NULL, engagement_id nullable, stage_id nullable)
//   app.meeting_attendees (contact_id / user_id / is_internal / email+name snapshot)
//   app.pipeline_stages (FK target of engagements.current_stage_id)
//
import 'server-only'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { requireAuth } from '@/lib/auth'

// =============================================================
// Types - exactly aligned with the DB enum / schema
// =============================================================

// subset of the app.engagement_channel enum (meeting context)
// only the values meaningful as a meeting mode out of all 15.
// the rest (email/sms/kakaotalk/...) belong to the communications domain.
export type MeetingChannel =
  | 'in_person'
  | 'video_call'
  | 'video_conference'
  | 'phone_call'
  | 'hybrid'
  | 'other'

// app.meetings.meeting_type is a text column (free-form).
// a union of commonly used values - used as the UI selector default.
export type MeetingType =
  | 'discovery' | 'demo' | 'proposal' | 'negotiation'
  | 'follow_up' | 'check_in' | 'internal'
  | 'kickoff' | 'review' | 'other'

// app.meeting_status enum (exactly 5 values)
export type MeetingStatus =
  | 'scheduled' | 'completed' | 'cancelled' | 'no_show' | 'rescheduled'

// app.attendee_role / attendee_response enum
export type AttendeeRole = 'organizer' | 'required' | 'optional' | 'resource'
export type AttendeeResponse = 'no_response' | 'accepted' | 'declined' | 'tentative'

// item structure inside the action_items jsonb
export interface ActionItem {
  text: string
  assignee_user_id?: string
  due_at?: string
  done?: boolean
}

// meeting_attendees row - 1:1 with the DB schema
export interface MeetingAttendeeRow {
  id: string
  organization_id: string
  meeting_id: string
  contact_id: string | null
  email: string
  name: string | null
  role: AttendeeRole
  response: AttendeeResponse
  is_internal: boolean
  user_id: string | null
  person_party_id: string | null
  notes: string | null
}

// meetings row - 1:1 with the DB schema
export interface MeetingRow {
  id: string
  organization_id: string
  user_id: string | null
  party_id: string
  engagement_id: string | null
  stage_id: string | null
  meeting_type: string
  channel: MeetingChannel | null
  status: MeetingStatus
  title: string
  agenda: string | null
  notes: string | null
  ai_summary: string | null
  outcome: string | null
  next_steps: string | null
  action_items: ActionItem[]
  occurred_at: string
  scheduled_at: string | null
  actual_started_at: string | null
  actual_ended_at: string | null
  duration_min: number | null
  location: string | null
  meeting_url: string | null
  calendar_event_id: string | null
  follow_up_task_ids: string[]
  created_at: string
  updated_at: string
}

// detail view - for display (includes joins)
export interface MeetingDetail extends MeetingRow {
  parties: { id: string; name: string } | null
  engagements: { id: string; name: string; current_stage_id: string | null } | null
  pipeline_stages: { id: string; name: string; code: string } | null
  meeting_attendees: MeetingAttendeeRow[]
}

// =============================================================
// SELECT column constants
// =============================================================

const BASE_SELECT = [
  'id', 'organization_id', 'user_id',
  'party_id', 'engagement_id', 'stage_id',
  'meeting_type', 'channel', 'status',
  'title', 'agenda', 'notes', 'ai_summary',
  'outcome', 'next_steps', 'action_items',
  'occurred_at', 'scheduled_at',
  'actual_started_at', 'actual_ended_at',
  'duration_min', 'location', 'meeting_url',
  'calendar_event_id', 'follow_up_task_ids',
  'created_at', 'updated_at',
].join(', ')

const DETAIL_SELECT = `
  ${BASE_SELECT},
  parties ( id, name ),
  engagements ( id, name, current_stage_id ),
  pipeline_stages:stage_id ( id, name, code ),
  meeting_attendees (
    id, organization_id, meeting_id, contact_id,
    email, name, role, response,
    is_internal, user_id, person_party_id, notes
  )
`

// =============================================================
// List queries
// =============================================================

export interface FetchMeetingsOptions {
  party_id?: string
  engagement_id?: string
  stage_id?: string
  status?: MeetingStatus
  upcoming?: boolean      // status='scheduled' AND scheduled_at >= now()
  limit?: number
}

export async function fetchMeetings(
  opts: FetchMeetingsOptions = {},
): Promise<MeetingRow[]> {
  const supabase = await createSupabaseServerClient()

  let query = supabase
    .schema('app')
    .from('meetings' as never)
    .select(BASE_SELECT)
    .is('deleted_at', null)
    .order('scheduled_at', { ascending: false, nullsFirst: false })

  if (opts.party_id)      query = query.eq('party_id', opts.party_id)
  if (opts.engagement_id) query = query.eq('engagement_id', opts.engagement_id)
  if (opts.stage_id)      query = query.eq('stage_id', opts.stage_id)
  if (opts.status)        query = query.eq('status', opts.status)
  if (opts.upcoming) {
    query = query
      .eq('status', 'scheduled')
      .gte('scheduled_at', new Date().toISOString())
  }
  if (opts.limit) query = query.limit(opts.limit)

  const { data, error } = await query
  if (error) {
    console.error('[meetings] fetch error:', error)
    throw error
  }
  return (data ?? []) as unknown as MeetingRow[]
}

// engagement-first primary - all meetings of one deal
export async function fetchEngagementMeetings(
  engagementId: string,
  limit = 100,
): Promise<MeetingRow[]> {
  if (!engagementId) return []
  return fetchMeetings({ engagement_id: engagementId, limit })
}

// stage-level - meetings of a specific stage
export async function fetchStageMeetings(
  stageId: string,
  limit = 100,
): Promise<MeetingRow[]> {
  if (!stageId) return []
  return fetchMeetings({ stage_id: stageId, limit })
}

// party-level - all meetings of one company (cross-engagement)
export async function fetchPartyMeetings(
  partyId: string,
  limit = 100,
): Promise<MeetingRow[]> {
  if (!partyId) return []
  return fetchMeetings({ party_id: partyId, limit })
}

// dashboard sidebar
export async function fetchUpcomingMeetings(limit = 5): Promise<MeetingRow[]> {
  return fetchMeetings({ upcoming: true, limit })
}

// =============================================================
// Detail
// =============================================================

export async function fetchMeetingDetail(
  id: string,
): Promise<MeetingDetail | null> {
  if (!id) return null
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('meetings' as never)
    .select(DETAIL_SELECT)
    .eq('id', id)
    .is('deleted_at', null)
    .maybeSingle()

  if (error) {
    console.error('[meetings] detail error:', error)
    throw error
  }
  return (data as unknown as MeetingDetail) ?? null
}

// =============================================================
// Create
// =============================================================

export interface CreateMeetingInput {
  party_id: string                 // required (DB NOT NULL)
  engagement_id?: string           // engagement-first recommended (nullable in DB)
  stage_id?: string                // stage within the engagement
  user_id?: string                 // organizer (default: caller)
  title: string
  meeting_type?: string            // free-form, default 'other'
  channel?: MeetingChannel
  scheduled_at?: string            // ISO
  duration_min?: number            // default 30
  agenda?: string
  location?: string
  meeting_url?: string
  attendees?: Array<{
    email: string
    name?: string
    role?: AttendeeRole
    contact_id?: string
    user_id?: string
    is_internal?: boolean
    person_party_id?: string
  }>
}

export async function createMeeting(
  input: CreateMeetingInput,
): Promise<MeetingRow> {
  const supabase = await createSupabaseServerClient()
  const auth = await requireAuth()
  const { attendees, ...meetingData } = input

  const occurredAt = meetingData.scheduled_at ?? new Date().toISOString()

  const { data: meeting, error } = await supabase
    .schema('app')
    .from('meetings' as never)
    .insert({
      organization_id: auth.organizationId,
      party_id:      meetingData.party_id,
      engagement_id: meetingData.engagement_id ?? null,
      stage_id:      meetingData.stage_id ?? null,
      title:         meetingData.title,
      meeting_type:  meetingData.meeting_type ?? 'other',
      channel:       meetingData.channel ?? null,
      status:        'scheduled' as MeetingStatus,
      scheduled_at:  meetingData.scheduled_at ?? null,
      occurred_at:   occurredAt,
      duration_min:  meetingData.duration_min ?? 30,
      agenda:        meetingData.agenda ?? null,
      location:      meetingData.location ?? null,
      meeting_url:   meetingData.meeting_url ?? null,
      user_id:       meetingData.user_id ?? auth.userId,
      action_items:  [],
      follow_up_task_ids: [],
    } as never)
    .select()
    .single()

  if (error) {
    console.error('[meetings] create error:', error)
    throw error
  }
  const meetingRow = meeting as unknown as MeetingRow

  if (attendees && attendees.length > 0) {
    const rows = attendees.map((a) => ({
      meeting_id: meetingRow.id,
      organization_id: meetingRow.organization_id,
      email: a.email,
      name: a.name ?? null,
      role: (a.role ?? 'required') as AttendeeRole,
      contact_id: a.contact_id ?? null,
      user_id: a.user_id ?? null,
      is_internal: a.is_internal ?? false,
      person_party_id: a.person_party_id ?? null,
      response: 'no_response' as AttendeeResponse,
    }))

    const { error: attError } = await supabase
      .schema('app')
      .from('meeting_attendees' as never)
      .insert(rows as never)

    if (attError) {
      console.error('[meetings] attendees insert error:', attError)
      throw attError
    }
  }

  return meetingRow
}

// =============================================================
// Update
// =============================================================

export type UpdateMeetingPatch = Partial<Pick<MeetingRow,
  | 'title' | 'agenda' | 'notes' | 'ai_summary'
  | 'outcome' | 'next_steps' | 'action_items'
  | 'status' | 'meeting_type' | 'channel'
  | 'scheduled_at' | 'duration_min'
  | 'location' | 'meeting_url'
  | 'actual_started_at' | 'actual_ended_at'
  | 'stage_id' | 'engagement_id'
>>

export async function updateMeeting(
  id: string,
  patch: UpdateMeetingPatch,
): Promise<MeetingRow> {
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('meetings' as never)
    .update(patch as never)
    .eq('id', id)
    .select()
    .single()

  if (error) {
    console.error('[meetings] update error:', error)
    throw error
  }
  return data as unknown as MeetingRow
}

// =============================================================
// Outcome - record the result when a meeting completes
// =============================================================

export interface RecordOutcomeInput {
  outcome?: string
  notes?: string
  next_steps?: string
  action_items?: ActionItem[]
  ai_summary?: string
  actual_started_at?: string
  actual_ended_at?: string
  set_status_completed?: boolean    // default true
}

export async function recordMeetingOutcome(
  id: string,
  input: RecordOutcomeInput,
): Promise<MeetingRow> {
  const patch: UpdateMeetingPatch = {}
  if (input.outcome           !== undefined) patch.outcome = input.outcome
  if (input.notes             !== undefined) patch.notes = input.notes
  if (input.next_steps        !== undefined) patch.next_steps = input.next_steps
  if (input.action_items      !== undefined) patch.action_items = input.action_items
  if (input.ai_summary        !== undefined) patch.ai_summary = input.ai_summary
  if (input.actual_started_at !== undefined) patch.actual_started_at = input.actual_started_at
  if (input.actual_ended_at   !== undefined) patch.actual_ended_at = input.actual_ended_at
  if (input.set_status_completed !== false)  patch.status = 'completed'
  return updateMeeting(id, patch)
}

// =============================================================
// Attendee mutations
// =============================================================

export interface AddAttendeeInput {
  meeting_id: string
  email: string
  name?: string
  role?: AttendeeRole
  contact_id?: string
  user_id?: string
  is_internal?: boolean
  person_party_id?: string
}

export async function addAttendee(
  input: AddAttendeeInput,
): Promise<MeetingAttendeeRow> {
  const supabase = await createSupabaseServerClient()

  // organization_id must come from the meeting (RLS alignment)
  const { data: meeting, error: mErr } = await supabase
    .schema('app')
    .from('meetings' as never)
    .select('organization_id')
    .eq('id', input.meeting_id)
    .maybeSingle()
  if (mErr) throw mErr
  if (!meeting) throw new Error(`meeting not found: ${input.meeting_id}`)

  const orgId = (meeting as { organization_id: string }).organization_id

  const { data, error } = await supabase
    .schema('app')
    .from('meeting_attendees' as never)
    .insert({
      meeting_id: input.meeting_id,
      organization_id: orgId,
      email: input.email,
      name: input.name ?? null,
      role: (input.role ?? 'required') as AttendeeRole,
      contact_id: input.contact_id ?? null,
      user_id: input.user_id ?? null,
      is_internal: input.is_internal ?? false,
      person_party_id: input.person_party_id ?? null,
      response: 'no_response' as AttendeeResponse,
    } as never)
    .select()
    .single()

  if (error) {
    console.error('[meetings] addAttendee error:', error)
    throw error
  }
  return data as unknown as MeetingAttendeeRow
}

export async function removeAttendee(attendeeId: string): Promise<void> {
  const supabase = await createSupabaseServerClient()
  const { error } = await supabase
    .schema('app')
    .from('meeting_attendees' as never)
    .delete()
    .eq('id', attendeeId)
  if (error) {
    console.error('[meetings] removeAttendee error:', error)
    throw error
  }
}

export async function updateAttendeeResponse(
  attendeeId: string,
  response: AttendeeResponse,
): Promise<MeetingAttendeeRow> {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('meeting_attendees' as never)
    .update({ response } as never)
    .eq('id', attendeeId)
    .select()
    .single()
  if (error) {
    console.error('[meetings] updateAttendeeResponse error:', error)
    throw error
  }
  return data as unknown as MeetingAttendeeRow
}

// backward compat re-export (party-detail.ts camelCase types)
export type { PartyMeeting, MeetingAttendeeRef, PartyMeetingStats } from './party-detail'
