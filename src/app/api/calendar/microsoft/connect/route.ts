// src/app/api/calendar/microsoft/connect/route.ts
import { NextResponse } from 'next/server'
import { cookies } from 'next/headers'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { buildMicrosoftAuthUrl } from '@/lib/calendar/microsoft-client'
import { randomBytes, createHmac } from 'crypto'

export async function GET() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const nonce = randomBytes(16).toString('hex')
  const hmac  = createHmac('sha256', process.env.CALENDAR_TOKEN_ENCRYPTION_KEY!)
    .update(nonce).digest('hex')
  const state = `${nonce}.${hmac}`

  const cookieStore = await cookies()
  cookieStore.set('oauth_state_microsoft', state, {
    httpOnly: true,
    secure:   process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge:   900,
    path:     '/',
  })

  return NextResponse.redirect(buildMicrosoftAuthUrl(state))
}
