// src/app/(app)/applications/[formId]/application-editor-client.tsx
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { toast } from 'sonner'

export type LibraryAnswer = {
  id: string
  answer_key: string
  title: string
  body_en: string | null
  body_ko: string | null
  disclosure_level: 'public' | 'nda_only'
  tags: string[]
}

export type EditorField = {
  fieldId: string
  seq: number
  label: string
  fieldType: string
  maxLength: number | null
  isRequired: boolean
  answerId: string | null
  answerKey: string | null
  disclosureLevel: string | null
  finalText: string
  isCopied: boolean
  fieldState: 'empty' | 'over_limit' | 'nda_blocked' | 'ok'
}

type Props = {
  formId: string
  partyName: string
  formUrl: string
  formStatus: string
  deadline: string | null
  submissionMethod: string
  submitEmail: string | null
  initialFields: EditorField[]
  library: LibraryAnswer[]
}

function stateOf(f: EditorField): EditorField['fieldState'] {
  if (!f.finalText || f.finalText.trim().length === 0) return 'empty'
  if (f.maxLength != null && f.finalText.length > f.maxLength) return 'over_limit'
  if (f.disclosureLevel === 'nda_only') return 'nda_blocked'
  return 'ok'
}

export default function ApplicationEditorClient({
  formId,
  partyName,
  formUrl,
  formStatus,
  deadline,
  submissionMethod,
  submitEmail,
  initialFields,
  library,
}: Props) {
  const [fields, setFields] = useState<EditorField[]>(initialFields)
  const [status, setStatus] = useState(formStatus)
  const [savingId, setSavingId] = useState<string | null>(null)

  const patchField = (fieldId: string, patch: Partial<EditorField>) => {
    setFields((prev) =>
      prev.map((f) => (f.fieldId === fieldId ? { ...f, ...patch } : f)),
    )
  }

  const saveField = async (f: EditorField) => {
    setSavingId(f.fieldId)
    try {
      const res = await fetch(`/api/applications/${formId}/fields/${f.fieldId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          final_text: f.finalText,
          answer_id: f.answerId,
          is_copied: f.isCopied,
        }),
      })
      if (!res.ok) throw new Error(await res.text())
    } catch (err) {
      toast.error('Save failed')
      console.error(err)
    } finally {
      setSavingId(null)
    }
  }

  const applyLibrary = (f: EditorField, answerId: string) => {
    const a = library.find((x) => x.id === answerId)
    if (!a) return
    const next: EditorField = {
      ...f,
      answerId: a.id,
      answerKey: a.answer_key,
      disclosureLevel: a.disclosure_level,
      finalText: a.body_en ?? '', // inject body_en; the library original stays untouched
      isCopied: false,
    }
    patchField(f.fieldId, next)
    void saveField(next)
    if (a.disclosure_level === 'nda_only') {
      toast.warning(
        'This answer contains partner names under NDA. Disclose in person only.',
      )
    }
  }

  const copyText = async (f: EditorField) => {
    const st = stateOf(f)
    if (st === 'nda_blocked') {
      toast.error(
        'This answer contains partner names under NDA. Disclose in person only.',
      )
      return
    }
    if (st === 'over_limit') return
    await navigator.clipboard.writeText(f.finalText)
    const next = { ...f, isCopied: true }
    patchField(f.fieldId, next)
    void saveField(next)
    toast.success('Copied')
  }

  const markSubmitted = async () => {
    const res = await fetch(`/api/applications/${formId}/submit`, { method: 'POST' })
    if (res.ok) {
      setStatus('submitted')
      toast.success('Marked as submitted')
    } else {
      toast.error('Failed to mark as submitted')
    }
  }

  return (
    <div className="mx-auto max-w-3xl p-6">
      <div className="mb-1 text-sm">
        <Link href="/applications" className="text-muted-foreground hover:underline">
          &larr; Applications
        </Link>
      </div>
      <div className="mb-6 flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">{partyName}</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {submissionMethod}
            {submitEmail ? ` \u2192 ${submitEmail}` : ''}
            {deadline ? ` \u00b7 deadline ${deadline}` : ''} {'\u00b7'} {status}
          </p>
          <a
            href={formUrl}
            target="_blank"
            rel="noreferrer"
            className="text-sm text-blue-600 hover:underline"
          >
            {formUrl}
          </a>
        </div>
        {status !== 'submitted' && status !== 'decided' && (
          <button
            onClick={markSubmitted}
            className="rounded-md bg-emerald-600 px-3 py-1.5 text-sm text-white hover:bg-emerald-700"
          >
            Mark as submitted
          </button>
        )}
      </div>

      <div className="space-y-6">
        {fields.map((f) => {
          const st = stateOf(f)
          const over = st === 'over_limit'
          const nda = st === 'nda_blocked'
          const count = f.finalText.length
          return (
            <div key={f.fieldId} className="rounded-lg border p-4">
              <div className="mb-2 flex items-center justify-between gap-2">
                <div className="text-sm font-medium">
                  [{f.seq}] {f.label}{' '}
                  <span className="font-normal text-muted-foreground">
                    ({f.isRequired ? 'required' : 'optional'}
                    {f.maxLength != null ? ` \u00b7 max ${f.maxLength}` : ''})
                  </span>
                </div>
                {nda && (
                  <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">
                    {'\u{1F512}'} NDA only
                  </span>
                )}
              </div>

              <textarea
                value={f.finalText}
                onChange={(e) => patchField(f.fieldId, { finalText: e.target.value })}
                onBlur={() => void saveField({ ...f })}
                rows={f.fieldType === 'textarea' ? 5 : 2}
                className={`w-full rounded-md border p-2 text-sm ${
                  over ? 'border-red-500' : ''
                }`}
              />

              <div className="mt-2 flex items-center justify-between gap-3">
                <select
                  value={f.answerId ?? ''}
                  onChange={(e) => e.target.value && applyLibrary(f, e.target.value)}
                  className="max-w-[50%] rounded-md border px-2 py-1 text-sm"
                >
                  <option value="">Library {'\u25BE'}</option>
                  {library.map((a) => (
                    <option key={a.id} value={a.id}>
                      {a.disclosure_level === 'nda_only' ? '\u{1F512} ' : ''}
                      {a.answer_key} {'\u2014'} {a.title}
                    </option>
                  ))}
                </select>

                <div className="flex items-center gap-3">
                  <span
                    className={`text-xs ${
                      over ? 'font-semibold text-red-600' : 'text-muted-foreground'
                    }`}
                  >
                    {count}
                    {f.maxLength != null ? ` / ${f.maxLength}` : ''}
                  </span>
                  <button
                    onClick={() => void copyText(f)}
                    disabled={over || nda || savingId === f.fieldId}
                    className={`rounded-md border px-3 py-1 text-sm ${
                      over || nda
                        ? 'cursor-not-allowed opacity-40'
                        : 'hover:bg-muted'
                    }`}
                    title={
                      nda
                        ? 'NDA-only answer: never paste into external forms'
                        : over
                          ? 'Over the character limit'
                          : 'Copy to clipboard'
                    }
                  >
                    {f.isCopied ? 'Copied \u2713' : 'Copy'}
                  </button>
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
