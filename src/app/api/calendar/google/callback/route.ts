// src/app/api/calendar/google/callback/route.ts
//
// Mirrors the Microsoft callback for consistency:
//   - validates the oauth_state_google cookie set by /connect (CSRF)
//   - exchanges the code via google-client.ts (raw fetch; no googleapis dep)
//   - resolves org from app.users (single source of truth, same as MS callback)
//   - stores the encrypted connection via saveCalendarConnection
//   - redirects to /settings/calendar?connected=google | ?error=...
//
// 2026-06-01: replaced the previous googleapis + @/lib/google/client variant,
// which used a different OAuth client than /connect (buildGoogleAuthUrl) and
// skipped state validation + landed on /calendar (no status banner there).

import { NextRequest, NextResponse } from 'next/server'
import { cookies } from 'next/headers'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { exchangeGoogleCode, getGoogleUserInfo, GOOGLE_SCOPES } from '@/lib/calendar/google-client'
import { saveCalendarConnection } from '@/lib/calendar/token-crypto'

const APP_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000'

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl
  const code  = searchParams.get('code')
  const state = searchParams.get('state')
  const error = searchParams.get('error')

  if (error) {
    return NextResponse.redirect(`${APP_URL}/settings/calendar?error=${encodeURIComponent(error)}`)
  }
  if (!code || !state) {
    return NextResponse.redirect(`${APP_URL}/settings/calendar?error=missing_params`)
  }

  const cookieStore = await cookies()
  const savedState  = cookieStore.get('oauth_state_google')?.value
  cookieStore.delete('oauth_state_google')

  if (!savedState || savedState !== state) {
    return NextResponse.redirect(`${APP_URL}/settings/calendar?error=invalid_state`)
  }

  try {
    const supabase = await createSupabaseServerClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    // URM: app.users.organization_id is the single source of truth (same as MS callback).
    const { data: appUser } = await supabase
      .schema('app')
      .from('users')
      .select('organization_id')
      .eq('id', user.id)
      .single()
    const orgId = appUser?.organization_id
    if (!orgId) throw new Error('No organization')

    const tokens = await exchangeGoogleCode(code)

    // Google only returns a refresh_token on first consent; /connect forces
    // prompt=consent + access_type=offline, so it should be present.
    if (!tokens.refresh_token) {
      return NextResponse.redirect(`${APP_URL}/settings/calendar?error=no_refresh_token`)
    }

    let info: { email: string; name: string }
    try {
      info = await getGoogleUserInfo(tokens.access_token)
    } catch {
      info = { email: user.email ?? 'unknown', name: '' }
    }

    await saveCalendarConnection({
      organization_id: orgId,
      user_id:         user.id,
      provider:        'google',
      account_email:   info.email,
      account_name:    info.name || undefined,
      access_token:    tokens.access_token,
      refresh_token:   tokens.refresh_token,
      expires_at:      new Date(Date.now() + tokens.expires_in * 1000),
      scopes:          (tokens.scope ?? GOOGLE_SCOPES).split(' '),
    })

    return NextResponse.redirect(`${APP_URL}/settings/calendar?connected=google`)
  } catch (err: any) {
    console.error('[google/callback]', err)
    return NextResponse.redirect(
      `${APP_URL}/settings/calendar?error=${encodeURIComponent(err.message ?? 'unknown')}`,
    )
  }
}
