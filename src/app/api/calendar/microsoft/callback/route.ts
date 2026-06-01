// src/app/api/calendar/microsoft/callback/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { cookies } from 'next/headers'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { exchangeMicrosoftCode, getMicrosoftUserInfo } from '@/lib/calendar/microsoft-client'
import { saveCalendarConnection } from '@/lib/calendar/token-crypto'

const APP_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000'

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl
  const code  = searchParams.get('code')
  const state = searchParams.get('state')
  const error = searchParams.get('error')

  if (error) {
    return NextResponse.redirect(`${APP_URL}/settings/calendar?error=${error}`)
  }
  if (!code || !state) {
    return NextResponse.redirect(`${APP_URL}/settings/calendar?error=missing_params`)
  }

  const cookieStore = await cookies()
  const savedState  = cookieStore.get('oauth_state_microsoft')?.value
  cookieStore.delete('oauth_state_microsoft')

  if (!savedState || savedState !== state) {
    return NextResponse.redirect(`${APP_URL}/settings/calendar?error=invalid_state`)
  }

  try {
    const supabase = await createSupabaseServerClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    // URM: app.users.organization_id is the single source of truth
    const { data: appUser } = await supabase
      .schema('app')
      .from('users')
      .select('organization_id')
      .eq('id', user.id)
      .single()
    const orgId = appUser?.organization_id
    if (!orgId) throw new Error('No organization')

    const tokens   = await exchangeMicrosoftCode(code)
    const userInfo = await getMicrosoftUserInfo(tokens.access_token)

    await saveCalendarConnection({
      organization_id: orgId,
      user_id:         user.id,
      provider:        'microsoft',
      account_email:   userInfo.email,
      account_name:    userInfo.name,
      access_token:    tokens.access_token,
      refresh_token:   tokens.refresh_token,
      expires_at:      new Date(Date.now() + tokens.expires_in * 1000),
      scopes:          tokens.scope.split(' '),
    })

    return NextResponse.redirect(`${APP_URL}/settings/calendar?connected=microsoft`)
  } catch (err: any) {
    console.error('[microsoft/callback]', err)
    return NextResponse.redirect(
      `${APP_URL}/settings/calendar?error=${encodeURIComponent(err.message)}`
    )
  }
}
