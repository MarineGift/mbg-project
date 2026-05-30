// src/app/api/calendar/google/callback/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { google } from 'googleapis'
import { getOAuthClient } from '@/lib/google/client'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { saveCalendarConnection } from '@/lib/calendar/token-crypto'
import { GOOGLE_SCOPES } from '@/lib/calendar/google-client'

export async function GET(req: NextRequest) {
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? req.nextUrl.origin
  const code = req.nextUrl.searchParams.get('code')
  if (!code) return NextResponse.redirect(new URL('/calendar?google=error', base))

  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return NextResponse.redirect(new URL('/calendar?google=noauth', base))

  const orgId = user.app_metadata?.organization_id as string | undefined
  if (!orgId) return NextResponse.redirect(new URL('/calendar?google=noorg', base))

  const auth = getOAuthClient()
  const { tokens } = await auth.getToken(code)
  auth.setCredentials(tokens)

  if (!tokens.refresh_token) {
    return NextResponse.redirect(new URL('/calendar?google=norefresh', base))
  }
  if (!tokens.access_token) {
    return NextResponse.redirect(new URL('/calendar?google=notoken', base))
  }

  let googleEmail: string | null = null
  try {
    const oauth2 = google.oauth2({ version: 'v2', auth })
    const me = await oauth2.userinfo.get()
    googleEmail = me.data.email ?? null
  } catch {
    /* non-fatal */
  }

  try {
    await saveCalendarConnection({
      organization_id: orgId,
      user_id:         user.id,
      provider:        'google',
      account_email:   googleEmail ?? user.email ?? 'unknown',
      access_token:    tokens.access_token,
      refresh_token:   tokens.refresh_token,
      expires_at:      tokens.expiry_date ? new Date(tokens.expiry_date) : new Date(Date.now() + 3600000),
      scopes:          GOOGLE_SCOPES.split(' '),
    })
  } catch (e: any) {
    console.error('[google callback] saveCalendarConnection failed:', e?.message ?? e)
    return NextResponse.redirect(new URL('/calendar?google=savefail', base))
  }

  return NextResponse.redirect(new URL('/calendar?google=connected', base))
}