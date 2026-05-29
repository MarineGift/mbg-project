// src/app/api/calendar/callback/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { google } from 'googleapis'
import { getOAuthClient } from '@/lib/google/client'
import { createSupabaseServerClient } from '@/lib/supabase/server'

export async function GET(req: NextRequest) {
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? req.nextUrl.origin
  const code = req.nextUrl.searchParams.get('code')
  if (!code) return NextResponse.redirect(new URL('/calendar?google=error', base))

  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return NextResponse.redirect(new URL('/calendar?google=noauth', base))

  const auth = getOAuthClient()
  const { tokens } = await auth.getToken(code)
  auth.setCredentials(tokens)

  // refresh_token only comes back when access_type=offline + prompt=consent
  if (!tokens.refresh_token) {
    return NextResponse.redirect(new URL('/calendar?google=norefresh', base))
  }

  // grab the connected Google account email (nice for the UI)
  let googleEmail: string | null = null
  try {
    const oauth2 = google.oauth2({ version: 'v2', auth })
    const me = await oauth2.userinfo.get()
    googleEmail = me.data.email ?? null
  } catch {
    /* non-fatal */
  }

  const { error } = await supabase
    .schema('app')
    .from('google_calendar_tokens' as never)
    .upsert(
      {
        user_id: user.id,
        google_email: googleEmail,
        refresh_token: tokens.refresh_token,
        access_token: tokens.access_token ?? null,
        expiry: tokens.expiry_date ? new Date(tokens.expiry_date).toISOString() : null,
        calendar_id: 'primary',
        updated_at: new Date().toISOString(),
      } as any,
      { onConflict: 'user_id' },
    )

  if (error) {
    console.error('[google callback] token save failed:', error.message)
    return NextResponse.redirect(new URL('/calendar?google=savefail', base))
  }

  return NextResponse.redirect(new URL('/calendar?google=connected', base))
}
