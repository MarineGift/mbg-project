// src/lib/queries/meetings.ts
import { createSupabaseServerClient } from '@/lib/supabase/server'

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export type MeetingType =
  | 'discovery' | 'demo' | 'proposal' | 'negotiation'
  | 'follow_up' | 'check_in' | 'internal' | 'other'

export type MeetingMode = 'video_call' | 'phone' | 'in_person' | 'hybrid'

export type MeetingStatus =
  | 'scheduled' | 'completed' | 'cancelled' | 'no_show' | 'rescheduled'

export type AttendeeRole = 'organizer' | 'required' | 'optional' | 'resource'
export type AttendeeResponse = 'no_response' | 'accepted' | 'declined' | 'tentative'

export interface ActionItem {
  text: string
  assignee_user_id?: string
  due_at?: string  // ISO string
  done?: boolean
}

export interface MeetingAttendeeRow {
  id: string
  meeting_id: string
  contact_id: string | null
  email: string
  name: string | null
  role: AttendeeRole
  response: AttendeeResponse
  is_internal: boolean
  user_id: string | null
  notes: string | null
}

export interface MeetingRow {
  id: string
  organization_id: string
  user_id: string
  party_id: string
  engagement_id: string | null
  title: string
  agenda: string | null
  notes: string | null
  ai_summary: string | null
  action_items: ActionItem[]
  meeting_type: MeetingType
  meeting_mode: MeetingMode
  scheduled_at: string
  duration_min: number
  actual_started_at: string | null
  actual_ended_at: string | null
  location: string | null
  meeting_url: string | null
  status: MeetingStatus
  calendar_event_id: string | null
  follow_up_task_ids: string[]
  created_at: string
  updated_at: string
  // joined
  parties?: { id: string; name: string } | null
  engagements?: { id: string; title: string } | null
  meeting_attendees?: MeetingAttendeeRow[]
}

// ─────────────────────────────────────────────
// List meetings (party-scoped or org-wide)
// ─────────────────────────────────────────────

export async function fetchMeetings(options?: {
  party_id?: string
  engagement_id?: string
  status?: MeetingStatus
  upcoming?: boolean   // scheduled_at >= now
  limit?: number
}) {
  const supabase = await createSupabaseServerClient()

  let query = supabase
    .schema('app')
    .from('meetings')
    .select(`
      id, title, meeting_type, meeting_mode, status,
      scheduled_at, duration_min, location, meeting_url,
      party_id, engagement_id, calendar_event_id,
      parties ( id, name ),
      engagements ( id, title )
    `)
    .order('scheduled_at', { ascending: false })

  if (options?.party_id)     query = query.eq('party_id', options.party_id)
  if (options?.engagement_id) query = query.eq('engagement_id', options.engagement_id)
  if (options?.status)       query = query.eq('status', options.status)
  if (options?.upcoming)     query = query.gte('scheduled_at', new Date().toISOString())
  if (options?.limit)        query = query.limit(options.limit)

  const { data, error } = await query
  if (error) throw error
  return data as MeetingRow[]
}

// ─────────────────────────────────────────────
// Fetch single meeting with attendees
// ─────────────────────────────────────────────

export async function fetchMeetingDetail(id: string): Promise<MeetingRow> {
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('meetings')
    .select(`
      *,
      parties ( id, name ),
      engagements ( id, title ),
      meeting_attendees (
        id, contact_id, email, name, role, response, is_internal, user_id, notes
      )
    `)
    .eq('id', id)
    .single()

  if (error) throw error
  return data as MeetingRow
}

// ─────────────────────────────────────────────
// Create meeting
// ─────────────────────────────────────────────

export interface CreateMeetingInput {
  party_id: string           // required
  title: string
  scheduled_at: string       // ISO
  duration_min?: number
  meeting_type?: MeetingType
  meeting_mode?: MeetingMode
  agenda?: string
  location?: string
  meeting_url?: string
  engagement_id?: string
  attendees?: Array<{
    email: string
    name?: string
    role?: AttendeeRole
    contact_id?: string
    is_internal?: boolean
  }>
}

export async function createMeeting(input: CreateMeetingInput) {
  const supabase = await createSupabaseServerClient()

  const { attendees, ...meetingData } = input

  const { data: meeting, error } = await supabase
    .schema('app')
    .from('meetings')
    .insert({
      ...meetingData,
      duration_min: meetingData.duration_min ?? 30,
      meeting_type: meetingData.meeting_type ?? 'discovery',
      meeting_mode: meetingData.meeting_mode ?? 'video_call',
      status: 'scheduled',
      action_items: [],
      follow_up_task_ids: [],
    })
    .select()
    .single()

  if (error) throw error

  // Insert attendees if provided
  if (attendees && attendees.length > 0) {
    const rows = attendees.map(a => ({
      meeting_id: meeting.id,
      email: a.email,
      name: a.name ?? null,
      role: a.role ?? 'required',
      contact_id: a.contact_id ?? null,
      is_internal: a.is_internal ?? false,
      response: 'no_response' as AttendeeResponse,
    }))

    const { error: attError } = await supabase
      .schema('app')
      .from('meeting_attendees')
      .insert(rows)

    if (attError) throw attError
  }

  return meeting
}

// ─────────────────────────────────────────────
// Update meeting (notes, status, action_items)
// ─────────────────────────────────────────────

export async function updateMeeting(
  id: string,
  patch: Partial<Pick<MeetingRow,
    | 'title' | 'agenda' | 'notes' | 'ai_summary'
    | 'action_items' | 'status' | 'meeting_type' | 'meeting_mode'
    | 'scheduled_at' | 'duration_min' | 'location' | 'meeting_url'
    | 'actual_started_at' | 'actual_ended_at'
  >>
) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .schema('app')
    .from('meetings')
    .update(patch)
    .eq('id', id)
    .select()
    .single()

  if (error) throw error
  return data
}

// ─────────────────────────────────────────────
// Upcoming meetings for sidebar/dashboard
// ─────────────────────────────────────────────

export async function fetchUpcomingMeetings(limit = 5): Promise<MeetingRow[]> {
  return fetchMeetings({ upcoming: true, status: 'scheduled', limit })
}
