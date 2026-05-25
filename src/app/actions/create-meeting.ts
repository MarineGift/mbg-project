'use server'
// src/app/actions/create-meeting.ts
// Server action wrapper for createMeeting (extracted for client component use).
// Original: src/lib/queries/meetings.ts:createMeeting

import { createMeeting, type CreateMeetingInput } from '@/lib/queries/meetings'

export async function createMeetingAction(input: CreateMeetingInput) {
  return createMeeting(input)
}