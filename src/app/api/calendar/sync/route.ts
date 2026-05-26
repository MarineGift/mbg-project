// src/app/api/calendar/sync/route.ts
// POST /api/calendar/sync — 수동 또는 cron 트리거
import { NextRequest, NextResponse } from 'next/server'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { syncAllConnections } from '@/lib/calendar/sync-engine'

export async function POST(req: NextRequest) {
  // cron 요청: Authorization 헤더로 검증
  const authHeader = req.headers.get('authorization')
  const cronSecret = process.env.CRON_SECRET

  const isCron   = cronSecret && authHeader === `Bearer ${cronSecret}`
  const isManual = !cronSecret  // 개발환경

  if (!isCron && !isManual) {
    // 일반 사용자 세션 확인
    const supabase = await createSupabaseServerClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const supabase    = await createSupabaseServerClient()
    const { data: { user } } = await supabase.auth.getUser()
    const orgId = user?.app_metadata?.organization_id

    if (!orgId) {
      return NextResponse.json({ error: 'No organization' }, { status: 400 })
    }

    const results = await syncAllConnections(orgId)
    const total   = results.reduce((s, r) => s + r.eventsSynced, 0)
    const errors  = results.filter(r => r.error)

    return NextResponse.json({
      synced:      total,
      connections: results.length,
      errors:      errors.length,
      detail:      results,
    })
  } catch (err: any) {
    console.error('[/api/calendar/sync]', err)
    return NextResponse.json({ error: err.message }, { status: 500 })
  }
}
