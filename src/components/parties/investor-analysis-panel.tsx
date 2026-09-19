'use client'
// src/components/parties/investor-analysis-panel.tsx
//
// 2026-09-15 - the "투자사 분석" tab.
//
//   1. Research: one free-text box per party. What we found out about the firm
//      - thesis, cheque size, portfolio overlap, why FCC would or would not
//      land with them. Saves explicitly, and warns before you navigate away
//      with unsaved text.
//   2. Cold mail sent outside URM (Greentown's investor platform, LinkedIn, a
//      warm intro). Those messages never pass through the mailcarrier, so the
//      Communications tab cannot know about them - paste them here and the
//      party page shows the full contact history.

import { useCallback, useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import {
  getPartyResearchAction,
  savePartyResearchAction,
  listColdMailsAction,
  createColdMailAction,
  updateColdMailAction,
  deleteColdMailAction,
  type ColdMail,
} from '@/app/actions/party-research'

const SOURCES = [
  { value: 'greentown', label: 'Greentown investor platform' },
  { value: 'linkedin',  label: 'LinkedIn' },
  { value: 'warm_intro', label: 'Warm intro' },
  { value: 'other',     label: 'Other' },
]

const OUTCOMES = ['', 'No reply', 'Replied', 'Meeting booked', 'Passed']

function fmtDate(iso: string | null): string {
  if (!iso) return '-'
  const d = new Date(iso)
  return Number.isNaN(d.getTime()) ? '-' : d.toLocaleDateString()
}

export function InvestorAnalysisPanel({
  partyId,
  partyName,
}: {
  partyId: string
  partyName: string
}) {
  const [notes, setNotes] = useState('')
  const [savedNotes, setSavedNotes] = useState('')
  const [updatedAt, setUpdatedAt] = useState<string | null>(null)
  const [savingNotes, setSavingNotes] = useState(false)
  const [editingNotes, setEditingNotes] = useState(false)

  const [mails, setMails] = useState<ColdMail[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // One form serves both "add" and "edit": editingId null means a new record.
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [source, setSource] = useState('greentown')
  const [subject, setSubject] = useState('')
  const [recipient, setRecipient] = useState('')
  const [sentAt, setSentAt] = useState('')
  const [body, setBody] = useState('')
  const [saving, setSaving] = useState(false)
  const [expanded, setExpanded] = useState<Record<string, boolean>>({})

  const dirty = notes !== savedNotes

  const reload = useCallback(async () => {
    setLoading(true)
    const [r, m] = await Promise.all([
      getPartyResearchAction(partyId),
      listColdMailsAction(partyId),
    ])
    if (r.ok) {
      setNotes(r.data?.researchNotes ?? '')
      setSavedNotes(r.data?.researchNotes ?? '')
      setUpdatedAt(r.data?.updatedAt ?? null)
    } else setError(r.error)
    if (m.ok) setMails(m.data)
    else setError(m.error)
    setLoading(false)
  }, [partyId])

  useEffect(() => { void reload() }, [reload])

  // Unsaved research is easy to lose on a tab switch or a back button.
  useEffect(() => {
    if (!dirty) return
    const warn = (e: BeforeUnloadEvent) => { e.preventDefault(); e.returnValue = '' }
    window.addEventListener('beforeunload', warn)
    return () => window.removeEventListener('beforeunload', warn)
  }, [dirty])

  async function handleSaveNotes() {
    setSavingNotes(true)
    setError(null)
    const res = await savePartyResearchAction(partyId, notes)
    setSavingNotes(false)
    if (!res.ok) { setError(res.error); return }
    setSavedNotes(res.data.researchNotes)
    setUpdatedAt(res.data.updatedAt)
  }

  async function handleClearNotes() {
    if (!window.confirm('Delete the research notes for this investor?')) return
    setSavingNotes(true)
    setError(null)
    const res = await savePartyResearchAction(partyId, '')
    setSavingNotes(false)
    if (!res.ok) { setError(res.error); return }
    setNotes(''); setSavedNotes(''); setUpdatedAt(res.data.updatedAt)
  }

  function resetForm() {
    setEditingId(null)
    setSource('greentown')
    setSubject(''); setBody(''); setRecipient(''); setSentAt('')
  }

  function startEdit(m: ColdMail) {
    setEditingId(m.id)
    setSource(m.source || 'greentown')
    setSubject(m.subject ?? '')
    setBody(m.body ?? '')
    setRecipient(m.recipient ?? '')
    // <input type="date"> wants YYYY-MM-DD in local time
    setSentAt(m.sentAt ? new Date(m.sentAt).toISOString().slice(0, 10) : '')
    setShowForm(true)
    if (typeof window !== 'undefined') window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSaveMail() {
    setSaving(true)
    setError(null)
    const payload = {
      source,
      subject,
      body,
      recipient,
      sentAt: sentAt ? new Date(sentAt).toISOString() : null,
    }
    const res = editingId
      ? await updateColdMailAction(editingId, payload)
      : await createColdMailAction({ partyId, ...payload })
    setSaving(false)
    if (!res.ok) { setError(res.error); return }

    setMails((prev) =>
      editingId
        ? prev.map((m) => (m.id === editingId ? res.data : m))
        : [res.data, ...prev],
    )
    resetForm()
    setShowForm(false)
  }

  async function handleOutcome(id: string, outcome: string) {
    const res = await updateColdMailAction(id, { outcome: outcome || null })
    if (!res.ok) { setError(res.error); return }
    setMails((prev) => prev.map((m) => (m.id === id ? res.data : m)))
  }

  async function handleDeleteMail(id: string) {
    if (!window.confirm('Remove this cold mail record?')) return
    const res = await deleteColdMailAction(id)
    if (!res.ok) { setError(res.error); return }
    setMails((prev) => prev.filter((m) => m.id !== id))
  }

  return (
    <div className="space-y-6">
      {error && (
        <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      )}

      {/* ------------------------------------------------------- research */}
      <section className="rounded-lg border p-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div>
            <h3 className="text-sm font-semibold">Research on {partyName}</h3>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Thesis, cheque size, portfolio overlap, who to reach, why FCC would
              or would not land with them.
            </p>
          </div>
          <div className="flex items-center gap-2">
            {updatedAt && !dirty && (
              <span className="text-xs text-muted-foreground">
                Saved {fmtDate(updatedAt)}
              </span>
            )}
            {editingNotes && dirty && (
              <span className="text-xs text-amber-600">Unsaved changes</span>
            )}

            {editingNotes ? (
              <>
                <Button
                  size="sm"
                  onClick={async () => { await handleSaveNotes(); setEditingNotes(false) }}
                  disabled={savingNotes}
                >
                  {savingNotes ? 'Saving...' : 'Save'}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => { setNotes(savedNotes); setEditingNotes(false) }}
                  disabled={savingNotes}
                >
                  Cancel
                </Button>
              </>
            ) : (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  className="gap-1.5"
                  onClick={() => setEditingNotes(true)}
                  disabled={loading}
                >
                  <Pencil className="h-3.5 w-3.5" />
                  {savedNotes ? 'Edit' : 'Add research'}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  className="gap-1.5 text-muted-foreground hover:text-red-600"
                  onClick={async () => {
                    if (!window.confirm('Delete the research note for this party?')) return
                    await handleClearNotes()
                    setEditingNotes(false)
                  }}
                  disabled={savingNotes || !savedNotes}
                >
                  <Trash2 className="h-3.5 w-3.5" />
                  Delete
                </Button>
              </>
            )}
          </div>
        </div>

        {editingNotes ? (
          <Textarea
            className="mt-3 min-h-[60vh] resize-y text-sm leading-relaxed"
            placeholder={loading ? 'Loading...' : 'What did we find out about this firm?'}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            disabled={loading}
            autoFocus
          />
        ) : savedNotes ? (
          <div className="mt-3 max-h-[70vh] overflow-y-auto whitespace-pre-wrap rounded-md border bg-muted/20 px-4 py-3 text-sm leading-relaxed">
            {savedNotes}
          </div>
        ) : (
          <p className="mt-3 rounded-md border border-dashed px-4 py-8 text-center text-sm text-muted-foreground">
            {loading ? 'Loading...' : 'No research yet. Use Add research to start.'}
          </p>
        )}
      </section>

      {/* ------------------------------------------------------ cold mail */}
      <section className="rounded-lg border">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b px-4 py-3">
          <div>
            <h3 className="text-sm font-semibold">
              Cold mail sent outside URM ({mails.length})
            </h3>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Messages sent through Greentown&apos;s investor platform or another
              channel. They never reach our mailbox, so paste them here.
            </p>
          </div>
          <Button
            size="sm"
            variant="outline"
            onClick={() => {
              if (showForm) { setShowForm(false); resetForm() }
              else { resetForm(); setShowForm(true) }
            }}
          >
            <Plus className="mr-1 h-4 w-4" />
            {showForm ? 'Cancel' : 'Add'}
          </Button>
        </div>

        {showForm && (
          <div className="grid gap-3 border-b bg-muted/20 px-4 py-4 md:grid-cols-2">
            <p className="text-xs font-medium text-muted-foreground md:col-span-2">
              {editingId ? 'Edit cold mail' : 'New cold mail'}
            </p>
            <div className="space-y-1">
              <Label>Sent through</Label>
              <select
                value={source}
                onChange={(e) => setSource(e.target.value)}
                className="h-9 w-full rounded-md border bg-background px-2 text-sm"
              >
                {SOURCES.map((s) => (
                  <option key={s.value} value={s.value}>{s.label}</option>
                ))}
              </select>
            </div>

            <div className="space-y-1">
              <Label>Sent on</Label>
              <Input
                type="date"
                value={sentAt}
                onChange={(e) => setSentAt(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label>Recipient</Label>
              <Input
                placeholder="Name or email, if known"
                value={recipient}
                onChange={(e) => setRecipient(e.target.value)}
              />
            </div>

            <div className="space-y-1">
              <Label>Subject</Label>
              <Input value={subject} onChange={(e) => setSubject(e.target.value)} />
            </div>

            <div className="space-y-1 md:col-span-2">
              <Label>Message</Label>
              <Textarea
                className="min-h-[40vh] resize-y text-sm leading-relaxed"
                placeholder="Paste what was sent"
                value={body}
                onChange={(e) => setBody(e.target.value)}
              />
            </div>

            <div className="flex items-center gap-2 md:col-span-2">
              <Button size="sm" onClick={handleSaveMail} disabled={saving}>
                {saving
                  ? 'Saving...'
                  : editingId
                    ? 'Save changes'
                    : 'Save cold mail'}
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => { setShowForm(false); resetForm() }}
                disabled={saving}
              >
                Cancel
              </Button>
              {editingId && (
                <span className="text-xs text-muted-foreground">Editing an existing record</span>
              )}
            </div>
          </div>
        )}

        {loading ? (
          <p className="px-4 py-4 text-sm text-muted-foreground">Loading...</p>
        ) : mails.length === 0 ? (
          <p className="px-4 py-4 text-sm text-muted-foreground">
            Nothing recorded yet.
          </p>
        ) : (
          <ul className="divide-y">
            {mails.map((m) => (
              <li
                key={m.id}
                className={
                  'px-4 py-3 ' + (editingId === m.id ? 'bg-blue-50/60' : '')
                }
              >
                <div className="flex flex-wrap items-center gap-2">
                  <span className="rounded-full bg-muted px-2 py-0.5 text-[10px] font-medium">
                    {SOURCES.find((s) => s.value === m.source)?.label ?? m.source}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {fmtDate(m.sentAt ?? m.createdAt)}
                  </span>
                  {m.recipient && (
                    <span className="text-xs text-muted-foreground">
                      to {m.recipient}
                    </span>
                  )}

                  <select
                    value={m.outcome ?? ''}
                    onChange={(e) => handleOutcome(m.id, e.target.value)}
                    className="ml-auto h-7 rounded-md border bg-background px-2 text-xs"
                    title="Outcome"
                  >
                    {OUTCOMES.map((o) => (
                      <option key={o || 'none'} value={o}>{o || 'No outcome yet'}</option>
                    ))}
                  </select>
                  <button
                    type="button"
                    onClick={() => startEdit(m)}
                    className="inline-flex items-center gap-1 rounded-md border px-2 py-1 text-xs text-muted-foreground hover:bg-muted hover:text-foreground"
                  >
                    <Pencil className="h-3 w-3" />
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeleteMail(m.id)}
                    className="inline-flex items-center gap-1 rounded-md border px-2 py-1 text-xs text-muted-foreground hover:bg-red-50 hover:text-red-600"
                  >
                    <Trash2 className="h-3 w-3" />
                    Delete
                  </button>
                </div>

                {m.subject && (
                  <p className="mt-1.5 text-sm font-medium">{m.subject}</p>
                )}
                {m.body && (
                  <>
                    <p
                      className={
                        'mt-1 whitespace-pre-wrap text-sm text-muted-foreground ' +
                        (expanded[m.id] ? '' : 'line-clamp-4')
                      }
                    >
                      {m.body}
                    </p>
                    {m.body.length > 240 && (
                      <button
                        type="button"
                        onClick={() =>
                          setExpanded((p) => ({ ...p, [m.id]: !p[m.id] }))
                        }
                        className="mt-1 text-xs text-blue-600 hover:underline"
                      >
                        {expanded[m.id] ? 'Show less' : 'Show more'}
                      </button>
                    )}
                  </>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  )
}
