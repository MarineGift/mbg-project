// src/app/api/calendar/auth/route.ts
import { NextResponse } from 'next/server'
import { getAuthUrl } from '@/lib/google/client'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export async function GET() {
  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // must be signed in to attach the Google token to a user row
  if (!user) {
    return NextResponse.redirect(
      new URL('/', process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
    )
  }

  return NextResponse.redirect(getAuthUrl())
}
