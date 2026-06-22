'use server'
// src/app/actions/create-meeting.ts
// Server action wrapper for createMeeting (extracted for client component use).
// Original: src/lib/queries/meetings.ts:createMeeting
// Returns a result object so the real DB error surfaces in the client modal
// (Next.js hides thrown errors in production builds).

import { createMeeting, type CreateMeetingInput } from '@/lib/queries/meetings'

export type CreateMeetingResult =
  | { ok: true; id: string }
  | { ok: false; error: string }

export async function createMeetingAction(
  input: CreateMeetingInput,
): Promise<CreateMeetingResult> {
  try {
    const row = await createMeeting(input)
    return { ok: true, id: row.id }
  } catch (e: unknown) {
    const err = e as { message?: string; code?: string; details?: string; hint?: string }
    const parts = [err?.message, err?.details, err?.hint, err?.code ? `(${err.code})` : null]
      .filter(Boolean)
    return { ok: false, error: parts.join(' · ') || String(e) }
  }
}
