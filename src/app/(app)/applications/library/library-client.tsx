// src/app/(app)/applications/library/library-client.tsx
'use client'

import { useMemo, useState } from 'react'
import Link from 'next/link'
import { toast } from 'sonner'

export type LibraryRow = {
  id: string
  answer_key: string
  title: string
  body_en: string | null
  body_ko: string | null
  disclosure_level: 'public' | 'nda_only'
  tags: string[]
  updated_at: string
}

type Draft = Omit<LibraryRow, 'id' | 'updated_at'> & { id?: string }

const EMPTY_DRAFT: Draft = {
  answer_key: '',
  title: '',
  body_en: '',
  body_ko: '',
  disclosure_level: 'public',
  tags: [],
}

export default function LibraryClient({
  initialAnswers,
}: {
  initialAnswers: LibraryRow[]
}) {
  const [answers, setAnswers] = useState<LibraryRow[]>(initialAnswers)
  const [lang, setLang] = useState<'en' | 'ko'>('en')
  const [tagFilter, setTagFilter] = useState<string>('')
  const [draft, setDraft] = useState<Draft | null>(null)
  const [saving, setSaving] = useState(false)

  const allTags = useMemo(() => {
    const s = new Set<string>()
    for (const a of answers) for (const t of a.tags) s.add(t)
    return Array.from(s).sort()
  }, [answers])

  const visible = tagFilter
    ? answers.filter((a) => a.tags.includes(tagFilter))
    : answers

  const save = async () => {
    if (!draft) return
    if (!draft.answer_key.trim() || !draft.title.trim()) {
      toast.error('answer_key and title are required')
      return
    }
    setSaving(true)
    try {
      const isEdit = !!draft.id
      const res = await fetch('/api/answer-library', {
        method: isEdit ? 'PATCH' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(draft),
      })
      if (!res.ok) throw new Error(await res.text())
      const saved = (await res.json()) as LibraryRow
      setAnswers((prev) =>
        isEdit
          ? prev.map((a) => (a.id === saved.id ? saved : a))
          : [...prev, saved].sort((x, y) => x.answer_key.localeCompare(y.answer_key)),
      )
      setDraft(null)
      toast.success(isEdit ? 'Updated' : 'Created')
    } catch (err) {
      toast.error('Save failed')
      console.error(err)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="mx-auto max-w-3xl p-6">
      <div className="mb-1 text-sm">
        <Link href="/applications" className="text-muted-foreground hover:underline">
          &larr; Applications
        </Link>
      </div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Answer Library</h1>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setLang(lang === 'en' ? 'ko' : 'en')}
            className="rounded-md border px-3 py-1.5 text-sm hover:bg-muted"
          >
            {lang.toUpperCase()}
          </button>
          <button
            onClick={() => setDraft({ ...EMPTY_DRAFT })}
            className="rounded-md bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700"
          >
            + New answer
          </button>
        </div>
      </div>

      <div className="mb-4 flex flex-wrap gap-2">
        <button
          onClick={() => setTagFilter('')}
          className={`rounded-full border px-2 py-0.5 text-xs ${
            tagFilter === '' ? 'bg-foreground text-background' : 'hover:bg-muted'
          }`}
        >
          all
        </button>
        {allTags.map((t) => (
          <button
            key={t}
            onClick={() => setTagFilter(t === tagFilter ? '' : t)}
            className={`rounded-full border px-2 py-0.5 text-xs ${
              tagFilter === t ? 'bg-foreground text-background' : 'hover:bg-muted'
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {draft && (
        <div className="mb-6 rounded-lg border-2 border-blue-300 p-4">
          <div className="mb-3 grid grid-cols-2 gap-3">
            <input
              placeholder="answer_key (e.g. problem_statement)"
              value={draft.answer_key}
              onChange={(e) => setDraft({ ...draft, answer_key: e.target.value })}
              disabled={!!draft.id}
              className="rounded-md border p-2 text-sm disabled:opacity-60"
            />
            <input
              placeholder="Title"
              value={draft.title}
              onChange={(e) => setDraft({ ...draft, title: e.target.value })}
              className="rounded-md border p-2 text-sm"
            />
          </div>
          <textarea
            placeholder="body_en"
            value={draft.body_en ?? ''}
            onChange={(e) => setDraft({ ...draft, body_en: e.target.value })}
            rows={4}
            className="mb-2 w-full rounded-md border p-2 text-sm"
          />
          <textarea
            placeholder="body_ko"
            value={draft.body_ko ?? ''}
            onChange={(e) => setDraft({ ...draft, body_ko: e.target.value })}
            rows={3}
            className="mb-2 w-full rounded-md border p-2 text-sm"
          />
          <input
            placeholder="tags, comma separated"
            value={draft.tags.join(', ')}
            onChange={(e) =>
              setDraft({
                ...draft,
                tags: e.target.value.split(',').map((t) => t.trim()).filter(Boolean),
              })
            }
            className="mb-3 w-full rounded-md border p-2 text-sm"
          />

          <label className="mb-3 flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={draft.disclosure_level === 'nda_only'}
              onChange={(e) =>
                setDraft({
                  ...draft,
                  disclosure_level: e.target.checked ? 'nda_only' : 'public',
                })
              }
            />
            <span
              className={
                draft.disclosure_level === 'nda_only'
                  ? 'font-semibold text-red-600'
                  : ''
              }
            >
              {'\u{1F512}'} NDA only {'\u2014'} never pasted into external forms, in-person disclosure only
            </span>
          </label>

          <div className="flex gap-2">
            <button
              onClick={() => void save()}
              disabled={saving}
              className="rounded-md bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700 disabled:opacity-50"
            >
              Save
            </button>
            <button
              onClick={() => setDraft(null)}
              className="rounded-md border px-3 py-1.5 text-sm hover:bg-muted"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      <ul className="space-y-3">
        {visible.map((a) => (
          <li key={a.id} className="rounded-lg border p-4">
            <div className="mb-1 flex items-center justify-between gap-2">
              <div className="text-sm font-medium">
                {a.disclosure_level === 'nda_only' && (
                  <span className="mr-1 rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">
                    {'\u{1F512}'} NDA
                  </span>
                )}
                {a.answer_key} <span className="text-muted-foreground">{'\u2014'} {a.title}</span>
              </div>
              <button
                onClick={() =>
                  setDraft({
                    id: a.id,
                    answer_key: a.answer_key,
                    title: a.title,
                    body_en: a.body_en,
                    body_ko: a.body_ko,
                    disclosure_level: a.disclosure_level,
                    tags: a.tags,
                  })
                }
                className="rounded-md border px-2 py-1 text-xs hover:bg-muted"
              >
                Edit
              </button>
            </div>
            <p className="whitespace-pre-wrap text-sm text-muted-foreground">
              {(lang === 'en' ? a.body_en : a.body_ko) ?? (
                <em>no {lang} body</em>
              )}
            </p>
            {a.tags.length > 0 && (
              <div className="mt-2 flex flex-wrap gap-1">
                {a.tags.map((t) => (
                  <span key={t} className="rounded-full border px-2 py-0.5 text-xs">
                    {t}
                  </span>
                ))}
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}
