// src/app/(app)/applications/applications-list-client.tsx
'use client'

import Link from 'next/link'

export type FormSummary = {
  formId: string
  partyName: string
  formUrl: string
  status: string
  deadline: string | null
  submissionMethod: string
  loginRequired: boolean
  totalFields: number
  okFields: number
  ndaBlocked: number
}

const METHOD_BADGE: Record<string, { icon: string; label: string }> = {
  email: { icon: '\u{1F4E7}', label: 'email' },
  web_form: { icon: '\u{1F310}', label: 'form' },
  portal: { icon: '\u{1F510}', label: 'portal' },
  email_then_form: { icon: '\u{1F4E7}\u2192\u{1F310}', label: 'email+form' },
}

function dday(deadline: string | null): { text: string; overdue: boolean } | null {
  if (!deadline) return null
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const d = new Date(deadline + 'T00:00:00')
  const diff = Math.round((d.getTime() - today.getTime()) / 86400000)
  if (diff === 0) return { text: 'D-day', overdue: false }
  if (diff > 0) return { text: `D-${diff}`, overdue: false }
  return { text: `D+${-diff}`, overdue: true }
}

export default function ApplicationsListClient({ forms }: { forms: FormSummary[] }) {
  return (
    <div className="mx-auto max-w-4xl p-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Applications</h1>
        <Link
          href="/applications/library"
          className="rounded-md border px-3 py-1.5 text-sm hover:bg-muted"
        >
          Answer Library
        </Link>
      </div>

      {forms.length === 0 && (
        <p className="text-sm text-muted-foreground">
          No application forms yet. Insert one via SQL or ask Claude to seed it.
        </p>
      )}

      <ul className="space-y-3">
        {forms.map((f) => {
          // noUncheckedIndexedAccess: Record lookup is `| undefined` even for
          // the literal fallback key, so fall back to an inline default.
          const badge =
            METHOD_BADGE[f.submissionMethod] ?? { icon: '\u{1F310}', label: 'form' }
          const dd = dday(f.deadline)
          const notSubmitted = f.status !== 'submitted' && f.status !== 'decided'
          const late = dd?.overdue && notSubmitted
          const pct =
            f.totalFields > 0 ? Math.round((f.okFields / f.totalFields) * 100) : 0

          return (
            <li key={f.formId}>
              <Link
                href={`/applications/${f.formId}`}
                className={`block rounded-lg border p-4 transition hover:bg-muted/50 ${
                  late ? 'border-red-500' : ''
                }`}
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{f.partyName}</span>
                    <span className="rounded-full border px-2 py-0.5 text-xs">
                      {badge.icon} {badge.label}
                    </span>
                    {f.loginRequired && (
                      <span className="rounded-full border px-2 py-0.5 text-xs text-muted-foreground">
                        login
                      </span>
                    )}
                    {f.ndaBlocked > 0 && (
                      <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">
                        {'\u{1F512}'} {f.ndaBlocked} NDA
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-3 text-sm">
                    {dd && (
                      <span className={late ? 'font-semibold text-red-600' : 'text-muted-foreground'}>
                        {dd.text}
                      </span>
                    )}
                    <span className="text-xs uppercase tracking-wide text-muted-foreground">
                      {f.status}
                    </span>
                  </div>
                </div>

                <div className="mt-3 flex items-center gap-3">
                  <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full rounded-full bg-emerald-500"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {f.okFields}/{f.totalFields}
                  </span>
                </div>
              </Link>
            </li>
          )
        })}
      </ul>
    </div>
  )
}
