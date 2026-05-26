// src/app/(app)/settings/calendar/page.tsx
import { Suspense } from 'react'
import { getCalendarConnections, disconnectCalendar } from '@/app/actions/calendar-sync'
import { Button } from '@/components/ui/button'
import { Badge }  from '@/components/ui/badge'
import { CheckCircle2, XCircle, RefreshCw, Link2Off } from 'lucide-react'
import { revalidatePath } from 'next/cache'

// ─────────────────────────────────────────────
// Connection Card
// ─────────────────────────────────────────────

function ProviderCard({
  provider,
  label,
  icon,
  connected,
  connection,
}: {
  provider:   'google' | 'microsoft'
  label:      string
  icon:       React.ReactNode
  connected:  boolean
  connection?: Awaited<ReturnType<typeof getCalendarConnections>>[0]
}) {
  const syncStatusColor: Record<string, string> = {
    success: 'text-emerald-600',
    failed:  'text-red-500',
    syncing: 'text-blue-500',
    pending: 'text-muted-foreground',
    partial: 'text-orange-500',
  }

  return (
    <div className="rounded-lg border border-border p-5 flex items-start gap-4">
      <div className="text-3xl">{icon}</div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          <span className="font-semibold">{label}</span>
          {connected ? (
            <Badge variant="outline" className="text-emerald-600 border-emerald-200 bg-emerald-50 gap-1 text-xs">
              <CheckCircle2 className="w-3 h-3" /> 연결됨
            </Badge>
          ) : (
            <Badge variant="outline" className="text-muted-foreground text-xs">
              미연결
            </Badge>
          )}
        </div>

        {connection && (
          <div className="text-sm text-muted-foreground space-y-0.5">
            <div>{connection.account_email}</div>
            {connection.last_sync_at && (
              <div className={syncStatusColor[connection.last_sync_status ?? 'pending']}>
                마지막 동기화: {new Date(connection.last_sync_at).toLocaleString('ko-KR')}
                {connection.sync_failures > 0 && (
                  <span className="ml-2 text-red-500">({connection.sync_failures}회 실패)</span>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      <div className="flex flex-col gap-2 shrink-0">
        {connected && connection ? (
          <>
            <form action={async () => {
              'use server'
              const res = await fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/calendar/sync`, {
                method: 'POST',
              })
            }}>
              <Button variant="outline" size="sm" className="gap-1 w-full">
                <RefreshCw className="w-3.5 h-3.5" /> 지금 동기화
              </Button>
            </form>
            <form action={async () => {
              'use server'
              await disconnectCalendar(connection.id)
              revalidatePath('/settings/calendar')
            }}>
              <Button variant="outline" size="sm" className="gap-1 text-red-500 hover:text-red-600 w-full">
                <Link2Off className="w-3.5 h-3.5" /> 연결 해제
              </Button>
            </form>
          </>
        ) : (
          <a href={`/api/calendar/${provider}/connect`}>
            <Button size="sm" className="bg-blue-600 hover:bg-blue-700 text-white w-full">
              연결하기
            </Button>
          </a>
        )}
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

export default async function CalendarSettingsPage({
  searchParams,
}: {
  searchParams: { connected?: string; error?: string }
}) {
  const connections = await getCalendarConnections()

  const googleConn    = connections.find(c => c.provider === 'google')
  const microsoftConn = connections.find(c => c.provider === 'microsoft')

  return (
    <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold">캘린더 연동</h1>
        <p className="text-muted-foreground text-sm mt-1">
          Google Calendar 또는 Microsoft Outlook을 연결하면 일정이 자동으로 동기화됩니다.
        </p>
      </div>

      {/* Status banners */}
      {searchParams.connected && (
        <div className="flex items-center gap-2 rounded-md bg-emerald-50 border border-emerald-200 text-emerald-700 px-4 py-3 text-sm">
          <CheckCircle2 className="w-4 h-4" />
          {searchParams.connected === 'google' ? 'Google Calendar' : 'Microsoft Outlook'} 연결 완료
        </div>
      )}
      {searchParams.error && (
        <div className="flex items-center gap-2 rounded-md bg-red-50 border border-red-200 text-red-700 px-4 py-3 text-sm">
          <XCircle className="w-4 h-4" />
          연결 실패: {decodeURIComponent(searchParams.error)}
        </div>
      )}

      {/* Provider cards */}
      <div className="space-y-3">
        <ProviderCard
          provider="google"
          label="Google Calendar"
          icon="📅"
          connected={!!googleConn}
          connection={googleConn}
        />
        <ProviderCard
          provider="microsoft"
          label="Microsoft Outlook"
          icon="📆"
          connected={!!microsoftConn}
          connection={microsoftConn}
        />
      </div>

      {/* Env vars checklist */}
      <div className="rounded-lg border border-border p-4 space-y-2">
        <p className="text-sm font-medium">환경 변수 체크리스트</p>
        <div className="text-xs text-muted-foreground space-y-1 font-mono">
          {[
            'GOOGLE_CALENDAR_CLIENT_ID',
            'GOOGLE_CALENDAR_CLIENT_SECRET',
            'GOOGLE_CALENDAR_REDIRECT_URI',
            'MICROSOFT_CALENDAR_CLIENT_ID',
            'MICROSOFT_CALENDAR_CLIENT_SECRET',
            'MICROSOFT_CALENDAR_REDIRECT_URI',
            'CALENDAR_TOKEN_ENCRYPTION_KEY',
            'NEXT_PUBLIC_APP_URL',
          ].map(v => (
            <div key={v} className="flex items-center gap-1.5">
              <span className="text-muted-foreground">·</span>
              {v}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
