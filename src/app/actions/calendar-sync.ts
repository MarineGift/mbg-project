'use server'
// src/app/actions/calendar-sync.ts

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { syncAllConnections, SyncResult } from '@/lib/calendar/sync-engine'
import { revalidatePath } from 'next/cache'
import { createClient } from '@supabase/supabase-js'

// ?????????????????????????????????????????????
// ?섎룞 ?숆린??(UI 踰꾪듉)
// ?????????????????????????????????????????????

export async function triggerCalendarSync(): Promise<{
  ok: boolean
  results: SyncResult[]
  error?: string
}> {
  try {
    const supabase = await createSupabaseServerClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    const token = (await (await createSupabaseServerClient()).auth.getSession()).data.session?.access_token
    const payload = token ? JSON.parse(Buffer.from(token.split(`.`)[1]!, `base64`).toString()) : {}
    const orgId = payload.organization_id ?? payload.app_metadata?.organization_id ?? payload.user_metadata?.organization_id
    if (!orgId) throw new Error('No organization')

    const results = await syncAllConnections(orgId)
    revalidatePath('/calendar')
    return { ok: true, results }
  } catch (err: any) {
    return { ok: false, results: [], error: err.message }
  }
}

// ?????????????????????????????????????????????
// ?곌껐 紐⑸줉 議고쉶 (蹂듯샇???놁씠 ???쒖떆??
// ?????????????????????????????????????????????

export interface ConnectionSummary {
  id:               string
  provider:         'google' | 'microsoft'
  account_email:    string
  account_name:     string | null
  is_active:        boolean
  is_primary:       boolean
  last_sync_at:     string | null
  last_sync_status: string | null
  sync_failures:    number
}

export async function getCalendarConnections(): Promise<ConnectionSummary[]> {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return []
  const session = await supabase.auth.getSession()
  const token = session.data.session?.access_token
  const payload = token ? JSON.parse(Buffer.from(token.split(`.`)[1]!, `base64`).toString()) : {}
  const orgId = payload.organization_id ?? payload.app_metadata?.organization_id ?? user.app_metadata?.organization_id

  const sb = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { db: { schema: 'app' } }
  )

  const { data, error } = await sb
    .from('calendar_connections')
    .select(
      'id, provider, account_email, account_name, is_active, is_primary, ' +
      'last_sync_at, last_sync_status, sync_failures'
    )
    .eq('organization_id', orgId)
    .eq('user_id', user.id)
    .order('created_at')

  if (error) throw error
  return (data ?? []) as unknown as ConnectionSummary[]
}

// ?????????????????????????????????????????????
// ?곌껐 鍮꾪솢?깊솕 (soft disconnect)
// ?????????????????????????????????????????????

export async function disconnectCalendar(connectionId: string): Promise<void> {
  const sb = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { db: { schema: 'app' } }
  )
  const { error } = await sb
    .from('calendar_connections')
    .update({ is_active: false })
    .eq('id', connectionId)

  if (error) throw error
  revalidatePath('/settings/calendar')
}



