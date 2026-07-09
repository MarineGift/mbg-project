// src/app/(app)/applications/page.tsx
// Server component: loads v_application_field_status (RLS scopes to org),
// groups rows per form and computes progress, deadline urgency.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import ApplicationsListClient, { type FormSummary } from './applications-list-client'

export const dynamic = 'force-dynamic'

type ViewRow = {
  form_id: string
  party_name: string
  form_url: string
  form_status: string
  deadline: string | null
  field_id: string | null
  field_state: string | null
  submission_method: string | null
  login_required: boolean | null
}

export default async function ApplicationsPage() {
  const supabase = await createSupabaseServerClient()

  const { data, error } = await supabase
    .schema('app')
    .from('v_application_field_status' as never)
    .select(
      'form_id, party_name, form_url, form_status, deadline, field_id, field_state, submission_method, login_required'
    )

  if (error) {
    console.error('[applications] fetch failed:', error.message)
  }

  const rows = (data ?? []) as unknown as ViewRow[]

  const byForm = new Map<string, FormSummary>()
  for (const r of rows) {
    let f = byForm.get(r.form_id)
    if (!f) {
      f = {
        formId: r.form_id,
        partyName: r.party_name,
        formUrl: r.form_url,
        status: r.form_status,
        deadline: r.deadline,
        submissionMethod: r.submission_method ?? 'web_form',
        loginRequired: r.login_required ?? false,
        totalFields: 0,
        okFields: 0,
        ndaBlocked: 0,
      }
      byForm.set(r.form_id, f)
    }
    if (r.field_id) {
      f.totalFields += 1
      if (r.field_state === 'ok') f.okFields += 1
      if (r.field_state === 'nda_blocked') f.ndaBlocked += 1
    }
  }

  // deadline ascending, nulls last
  const forms = Array.from(byForm.values()).sort((a, b) => {
    if (!a.deadline && !b.deadline) return 0
    if (!a.deadline) return 1
    if (!b.deadline) return -1
    return a.deadline.localeCompare(b.deadline)
  })

  return <ApplicationsListClient forms={forms} />
}
