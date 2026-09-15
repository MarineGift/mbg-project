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
import { Plus, Trash2 } from 'lucide-react'
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

  const [mails, setMails] = useState<ColdMail[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [showForm, setShowForm] = useState(false)
  const [source, setSource] = useState('greentown')
  const [subject, setSubject] = useState('')
  const [recipient, setRecipient] = useState('')
  const [sentAt, setSentAt] = useState('')
  const [body, setBody] = useState('')
  const [saving, setSaving] = useState(false)

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

  async function handleAddMail() {
    setSaving(true)
    setError(null)
    const res = await createColdMailAction({
      partyId,
      source,
      subject,
      body,
      recipient,
      sentAt: sentAt ? new Date(sentAt).toISOString() : null,
    })
    setSaving(false)
    if (!res.ok) { setError(res.error); return }
    setSubject(''); setBody(''); setRecipient(''); setSentAt(''); setShowForm(false)
    setMails((prev) => [res.data, ...prev])
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
            {dirty && <span className="text-xs text-amber-600">Unsaved changes</span>}
            <Button size="sm" onClick={handleSaveNotes} disabled={savingNotes || !dirty}>
              {savingNotes ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </div>

        <Textarea
          className="mt-3 min-h-[220px] text-sm"
          placeholder={loading ? 'Loading...' : 'What did we find out about this firm?'}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          disabled={loading}
        />
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
          <Button size="sm" variant="outline" onClick={() => setShowForm((v) => !v)}>
            <Plus className="mr-1 h-4 w-4" />
            {showForm ? 'Cancel' : 'Add'}
          </Button>
        </div>

        {showForm && (
          <div className="grid gap-3 border-b bg-muted/20 px-4 py-4 md:grid-cols-2">
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
                className="min-h-[160px] text-sm"
                placeholder="Paste what was sent"
                value={body}
                onChange={(e) => setBody(e.target.value)}
              />
            </div>

            <div className="md:col-span-2">
              <Button size="sm" onClick={handleAddMail} disabled={saving}>
                {saving ? 'Saving...' : 'Save cold mail'}
              </Button>
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
              <li key={m.id} className="px-4 py-3">
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
                    title="Remove"
                    onClick={() => handleDeleteMail(m.id)}
                    className="rounded p-1 text-muted-foreground hover:bg-red-50 hover:text-red-600"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>

                {m.subject && (
                  <p className="mt-1.5 text-sm font-medium">{m.subject}</p>
                )}
                {m.body && (
                  <p className="mt-1 whitespace-pre-wrap text-sm text-muted-foreground">
                    {m.body}
                  </p>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  )
}
