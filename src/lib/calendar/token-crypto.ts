// src/lib/calendar/token-crypto.ts
// 토큰 암호화 / 복호화 — Supabase RPC (service_role) 경유
import { createClient } from '@supabase/supabase-js'

const ENC_KEY = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY!

if (!ENC_KEY) {
  throw new Error('CALENDAR_TOKEN_ENCRYPTION_KEY env var is required')
}

/** service_role 클라이언트 (RLS 우회, 서버 전용) */
function serviceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { db: { schema: 'app' } }
  )
}

// ─────────────────────────────────────────────
// connection 저장 (upsert + 암호화 원자적)
// ─────────────────────────────────────────────

export interface SaveConnectionInput {
  organization_id: string
  user_id: string
  provider: 'google' | 'microsoft'
  account_email: string
  account_name?: string
  access_token: string
  refresh_token: string
  expires_at: Date
  scopes: string[]
}

export async function saveCalendarConnection(input: SaveConnectionInput): Promise<string> {
  const sb = serviceClient()
  const { data, error } = await sb.rpc('upsert_calendar_connection', {
    p_organization_id: input.organization_id,
    p_user_id:         input.user_id,
    p_provider:        input.provider,
    p_account_email:   input.account_email,
    p_account_name:    input.account_name ?? null,
    p_access_token:    input.access_token,
    p_refresh_token:   input.refresh_token,
    p_expires_at:      input.expires_at.toISOString(),
    p_scopes:          input.scopes,
    p_enc_key:         ENC_KEY,
  })
  if (error) throw error
  return data as string   // connection id (uuid)
}

// ─────────────────────────────────────────────
// 토큰 복호화 (sync engine 전용)
// ─────────────────────────────────────────────

export async function decryptToken(encryptedBytea: string): Promise<string> {
  const sb = serviceClient()
  const { data, error } = await sb.rpc('decrypt_calendar_token', {
    encrypted: encryptedBytea,
    enc_key:   ENC_KEY,
  })
  if (error) throw error
  return data as string
}

// ─────────────────────────────────────────────
// access_token 갱신 저장
// ─────────────────────────────────────────────

export async function updateAccessToken(
  connectionId: string,
  accessToken: string,
  expiresAt: Date
): Promise<void> {
  const sb = serviceClient()
  const { error } = await sb.rpc('update_calendar_tokens', {
    p_connection_id: connectionId,
    p_access_token:  accessToken,
    p_expires_at:    expiresAt.toISOString(),
    p_enc_key:       ENC_KEY,
  })
  if (error) throw error
}

// ─────────────────────────────────────────────
// sync 상태 업데이트
// ─────────────────────────────────────────────

export async function updateSyncState(
  connectionId: string,
  opts: {
    syncToken?:  string
    deltaLink?:  string
    status:      'pending' | 'syncing' | 'success' | 'partial' | 'failed'
    lastError?:  string
  }
): Promise<void> {
  const sb = serviceClient()
  const { error } = await sb.rpc('update_calendar_sync_state', {
    p_connection_id: connectionId,
    p_sync_token:    opts.syncToken  ?? null,
    p_delta_link:    opts.deltaLink  ?? null,
    p_sync_status:   opts.status,
    p_last_error:    opts.lastError  ?? null,
  })
  if (error) throw error
}

// ─────────────────────────────────────────────
// active connections 조회 (복호화 포함)
// ─────────────────────────────────────────────

export interface DecryptedConnection {
  id: string
  provider: 'google' | 'microsoft'
  account_email: string
  account_name: string | null
  access_token: string       // 복호화된 평문
  refresh_token: string | null
  expires_at: string | null
  scopes: string[]
  sync_token: string | null
  delta_link: string | null
  last_sync_at: string | null
  sync_failures: number
  organization_id: string
  user_id: string
}

export async function getActiveConnections(
  organizationId: string
): Promise<DecryptedConnection[]> {
  const sb = serviceClient()

  const { data: rows, error } = await sb
    .from('calendar_connections')
    .select('*')
    .eq('organization_id', organizationId)
    .eq('is_active', true)
    .order('created_at')

  if (error) throw error
  if (!rows || rows.length === 0) return []

  // 병렬 복호화
  const connections = await Promise.all(
    rows.map(async (row: any) => {
      const [access, refresh] = await Promise.all([
        decryptToken(row.access_token),
        row.refresh_token ? decryptToken(row.refresh_token) : Promise.resolve(null),
      ])
      return {
        ...row,
        access_token:  access,
        refresh_token: refresh,
      } as DecryptedConnection
    })
  )

  return connections
}
