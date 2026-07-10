// src/app/(app)/applications/[formId]/application-editor-client.tsx
// 2026-07-09: Copy next sequential mode + canonical_key / variant display.
'use client'

import { useMemo, useRef, useState } from 'react'
import Link from 'next/link'
import { toast } from 'sonner'

export type LibraryAnswer = {
  id: string
  answer_key: string
  title: string
  body_en: string | null
  body_ko: string | null
  disclosure_level: 'public' | 'nda_only'
  variant: string | null
  target_length: number | null
  tags: string[]
}

export type EditorField = {
  fieldId: string
  seq: number
  label: string
  fieldType: string
  maxLength: number | null
  isRequired: boolean
  canonicalKey: string | null
  answerId: string | null
  answerKey: string | null
  answerVariant: string | null
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
  const cardRefs = useRef<Map<string, HTMLDivElement>>(new Map())

  type TabKey = 'all' | 'issues' | 'todo' | 'copied'
  const [tab, setTab] = useState<TabKey>('all')

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
      answerVariant: a.variant,
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

  const copyText = async (f: EditorField): Promise<boolean> => {
    const st = stateOf(f)
    if (st === 'nda_blocked') {
      toast.error(
        'This answer contains partner names under NDA. Disclose in person only.',
      )
      return false
    }
    if (st === 'over_limit') return false
    await navigator.clipboard.writeText(f.finalText)
    const next = { ...f, isCopied: true }
    patchField(f.fieldId, next)
    void saveField(next)
    return true
  }

  // ── Copy next: sequential copy mode ────────────────────────
  // Sit this screen next to the actual form and walk the fields in
  // order: each click copies the next uncopied ok field, marks
  // is_copied, and scrolls it into view.
  const copyableStates = useMemo(() => fields.map((f) => stateOf(f)), [fields])
  const copyTargets = fields.filter((_, i) => copyableStates[i] === 'ok')
  const copiedCount = copyTargets.filter((f) => f.isCopied).length
  const nextTarget = copyTargets.find((f) => !f.isCopied) ?? null

  // ── status tabs: quickly isolate problem fields ─────────────
  const issueFields = fields.filter((f) =>
    ['over_limit', 'nda_blocked', 'empty'].includes(stateOf(f)),
  )
  const todoFields = copyTargets.filter((f) => !f.isCopied)
  const copiedFields = copyTargets.filter((f) => f.isCopied)
  const visibleFields =
    tab === 'all'
      ? fields
      : tab === 'issues'
        ? issueFields
        : tab === 'todo'
          ? todoFields
          : copiedFields
  const tabs: { key: TabKey; label: string; count: number }[] = [
    { key: 'all', label: 'All', count: fields.length },
    { key: 'issues', label: 'Needs fix', count: issueFields.length },
    { key: 'todo', label: 'To copy', count: todoFields.length },
    { key: 'copied', label: 'Copied', count: copiedFields.length },
  ]

  const copyNext = async () => {
    if (!nextTarget) return
    const ok = await copyText(nextTarget)
    if (!ok) return
    toast.success(`Copied [${nextTarget.seq}] ${nextTarget.label}`)
    // scroll the FOLLOWING target into view so you can see what comes next
    const after = copyTargets.find(
      (f) => !f.isCopied && f.fieldId !== nextTarget.fieldId,
    )
    const el = cardRefs.current.get((after ?? nextTarget).fieldId)
    el?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }

  const resetCopied = () => {
    for (const f of fields) {
      if (f.isCopied) {
        const next = { ...f, isCopied: false }
        patchField(f.fieldId, next)
        void saveField(next)
      }
    }
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
      <div className="mb-4 flex items-start justify-between gap-3">
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

      {/* Copy next toolbar (sticky so it stays visible while scrolling) */}
      {copyTargets.length > 0 && (
        <div className="sticky top-2 z-10 mb-6 flex items-center gap-3 rounded-lg border bg-background/95 px-4 py-2.5 shadow-sm backdrop-blur">
          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span>
                Copy progress {copiedCount} / {copyTargets.length}
                {nextTarget
                  ? ` \u00b7 next: [${nextTarget.seq}] ${nextTarget.label}`
                  : ' \u00b7 all copied \u2713'}
              </span>
            </div>
            <div className="mt-1 h-1.5 w-full rounded-full bg-muted">
              <div
                className="h-1.5 rounded-full bg-emerald-500 transition-all"
                style={{
                  width: `${copyTargets.length ? (copiedCount / copyTargets.length) * 100 : 0}%`,
                }}
              />
            </div>
          </div>
          <button
            onClick={() => void copyNext()}
            disabled={!nextTarget}
            className={`rounded-md px-3 py-1.5 text-sm text-white ${
              nextTarget
                ? 'bg-blue-600 hover:bg-blue-700'
                : 'cursor-not-allowed bg-muted-foreground/40'
            }`}
          >
            Copy next
          </button>
          {copiedCount > 0 && (
            <button
              onClick={resetCopied}
              className="rounded-md border px-2.5 py-1.5 text-xs text-muted-foreground hover:bg-muted"
              title="Clear all copied flags"
            >
              Reset
            </button>
          )}
        </div>
      )}

      {/* status tabs */}
      <div className="mb-4 flex items-center gap-1 rounded-lg border bg-muted/40 p-1">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`flex-1 rounded-md px-3 py-1.5 text-sm transition-colors ${
              tab === t.key
                ? 'bg-background font-medium shadow-sm'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {t.label}{' '}
            <span
              className={`ml-1 rounded-full px-1.5 py-0.5 text-[10px] ${
                t.key === 'issues' && t.count > 0
                  ? 'bg-red-100 text-red-700'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {t.count}
            </span>
          </button>
        ))}
      </div>

      <div className="space-y-6">
        {visibleFields.length === 0 && (
          <div className="rounded-lg border border-dashed p-8 text-center text-sm text-muted-foreground">
            Nothing in this tab.
          </div>
        )}
        {visibleFields.map((f) => {
          const st = stateOf(f)
          const over = st === 'over_limit'
          const nda = st === 'nda_blocked'
          const count = f.finalText.length
          const isNext = nextTarget?.fieldId === f.fieldId
          return (
            <div
              key={f.fieldId}
              ref={(el) => {
                if (el) cardRefs.current.set(f.fieldId, el)
                else cardRefs.current.delete(f.fieldId)
              }}
              className={`rounded-lg border p-4 ${
                isNext ? 'border-blue-400 ring-1 ring-blue-300/50' : ''
              } ${f.isCopied ? 'opacity-70' : ''}`}
            >
              <div className="mb-2 flex items-center justify-between gap-2">
                <div className="text-sm font-medium">
                  [{f.seq}] {f.label}{' '}
                  <span className="font-normal text-muted-foreground">
                    ({f.isRequired ? 'required' : 'optional'}
                    {f.maxLength != null ? ` \u00b7 max ${f.maxLength}` : ''})
                  </span>
                </div>
                <div className="flex items-center gap-1.5">
                  {f.canonicalKey && (
                    <span className="rounded-full bg-muted px-2 py-0.5 text-[10px] text-muted-foreground">
                      {f.canonicalKey}
                      {f.answerVariant ? ` \u00b7 ${f.answerVariant}` : ''}
                    </span>
                  )}
                  {nda && (
                    <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">
                      {'\u{1F512}'} NDA only
                    </span>
                  )}
                </div>
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
                      {a.answer_key}
                      {a.variant ? ` [${a.variant}]` : ''} {'\u2014'} {a.title}
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
                    onClick={() => {
                      void copyText(f).then((ok) => ok && toast.success('Copied'))
                    }}
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
