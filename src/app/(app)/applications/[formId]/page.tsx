// src/app/(app)/applications/[formId]/page.tsx
// Server component: loads one form's fields from the status view plus the
// answer library (for the dropdown), hands both to the editor client.

import { createSupabaseServerClient } from '@/lib/supabase/server'
import ApplicationEditorClient, {
  type EditorField,
  type LibraryAnswer,
} from './application-editor-client'

export const dynamic = 'force-dynamic'

type ViewRow = {
  form_id: string
  party_name: string
  form_url: string
  form_status: string
  deadline: string | null
  field_id: string | null
  seq: number | null
  label: string | null
  field_type: string | null
  max_length: number | null
  is_required: boolean | null
  answer_id: string | null
  answer_key: string | null
  disclosure_level: string | null
  final_text: string | null
  char_count: number | null
  is_copied: boolean | null
  field_state: string | null
  submission_method: string | null
  submit_email: string | null
  login_required: boolean | null
}

export default async function ApplicationEditorPage({
  params,
}: {
  // Next 14.2 App Router = sync params (NOT a Promise)
  params: { formId: string }
}) {
  const supabase = await createSupabaseServerClient()

  const [{ data: viewData, error: viewErr }, { data: libData, error: libErr }] =
    await Promise.all([
      supabase
        .schema('app')
        .from('v_application_field_status' as never)
        .select('*')
        .eq('form_id', params.formId)
        .order('seq', { ascending: true }),
      supabase
        .schema('app')
        .from('answer_library' as never)
        .select('id, answer_key, title, body_en, body_ko, disclosure_level, tags')
        .order('answer_key', { ascending: true }),
    ])

  if (viewErr) console.error('[application editor] view fetch failed:', viewErr.message)
  if (libErr) console.error('[application editor] library fetch failed:', libErr.message)

  const rows = (viewData ?? []) as unknown as ViewRow[]
  const library = (libData ?? []) as unknown as LibraryAnswer[]

  if (rows.length === 0) {
    return (
      <div className="mx-auto max-w-3xl p-6">
        <p className="text-sm text-muted-foreground">Form not found.</p>
      </div>
    )
  }

  const head = rows[0]
  const fields: EditorField[] = rows
    .filter((r) => r.field_id != null)
    .map((r) => ({
      fieldId: r.field_id as string,
      seq: r.seq ?? 0,
      label: r.label ?? '',
      fieldType: r.field_type ?? 'textarea',
      maxLength: r.max_length,
      isRequired: r.is_required ?? false,
      answerId: r.answer_id,
      answerKey: r.answer_key,
      disclosureLevel: r.disclosure_level,
      finalText: r.final_text ?? '',
      isCopied: r.is_copied ?? false,
      fieldState: (r.field_state ?? 'empty') as EditorField['fieldState'],
    }))

  return (
    <ApplicationEditorClient
      formId={params.formId}
      partyName={head.party_name}
      formUrl={head.form_url}
      formStatus={head.form_status}
      deadline={head.deadline}
      submissionMethod={head.submission_method ?? 'web_form'}
      submitEmail={head.submit_email}
      initialFields={fields}
      library={library}
    />
  )
}
