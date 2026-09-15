'use client'
// src/components/inbox/mail-folder-manager.tsx
//
// 2026-09-15 - manage pinned party mail folders (/inbox/folders).
// Pick a party, optionally pin extra sender domains, reorder, remove.
// Removing a folder never touches mail - it only drops the saved view.

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { ArrowDown, ArrowUp, FolderOpen, Plus, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  listMailFoldersWithCountsAction,
  createMailFolderAction,
  updateMailFolderAction,
  deleteMailFolderAction,
  reorderMailFoldersAction,
  searchPartiesForFolderAction,
  type MailFolderWithCounts,
  type PartyOption,
} from '@/app/actions/mail-folders'

const SWATCHES = ['#10b981', '#3b82f6', '#8b5cf6', '#f59e0b', '#ef4444', '#64748b']

export function MailFolderManager() {
  const router = useRouter()
  const [folders, setFolders] = useState<MailFolderWithCounts[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // add form
  const [q, setQ] = useState('')
  const [options, setOptions] = useState<PartyOption[]>([])
  const [picked, setPicked] = useState<PartyOption | null>(null)
  const [label, setLabel] = useState('')
  const [color, setColor] = useState(SWATCHES[0])
  const [domains, setDomains] = useState('')
  const [saving, setSaving] = useState(false)

  const reload = useCallback(async () => {
    setLoading(true)
    const res = await listMailFoldersWithCountsAction()
    if (res.ok) setFolders(res.data)
    else setError(res.error)
    setLoading(false)
  }, [])

  useEffect(() => { void reload() }, [reload])

  // party search (debounced)
  useEffect(() => {
    let cancelled = false
    const t = setTimeout(async () => {
      const res = await searchPartiesForFolderAction(q)
      if (!cancelled && res.ok) setOptions(res.data)
    }, 250)
    return () => { cancelled = true; clearTimeout(t) }
  }, [q])

  async function handleAdd() {
    if (!picked) { setError('Pick a party first'); return }
    setSaving(true)
    setError(null)
    const res = await createMailFolderAction({
      partyId: picked.id,
      label: label.trim() || null,
      color,
      matchDomains: domains,
    })
    setSaving(false)
    if (!res.ok) { setError(res.error); return }
    setPicked(null); setLabel(''); setDomains(''); setQ('')
    await reload()
    router.refresh()
  }

  async function handleRemove(id: string, name: string) {
    if (!window.confirm(`Remove the "${name}" folder? The mail itself is not deleted.`)) return
    const res = await deleteMailFolderAction(id)
    if (!res.ok) { setError(res.error); return }
    await reload()
    router.refresh()
  }

  async function handleMove(index: number, delta: number) {
    const next = [...folders]
    const target = index + delta
    if (target < 0 || target >= next.length) return
    const a = next[index]
    const b = next[target]
    if (!a || !b) return
    next[index] = b
    next[target] = a
    setFolders(next)
    await reorderMailFoldersAction(next.map((f) => f.id))
    router.refresh()
  }

  async function handleDomainsBlur(f: MailFolderWithCounts, value: string) {
    if (value.trim() === f.matchDomains.join(', ')) return
    const res = await updateMailFolderAction(f.id, { matchDomains: value })
    if (!res.ok) { setError(res.error); return }
    await reload()
  }

  return (
    <div className="space-y-8">
      {error && (
        <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      )}

      {/* ---------------------------------------------------------- add */}
      <section className="rounded-lg border p-4">
        <h2 className="text-sm font-semibold">Add a folder</h2>
        <p className="mt-1 text-xs text-muted-foreground">
          Pick the party whose mail you want to watch. Mail is filed automatically by
          the sender match made at ingest time - nothing is copied or moved.
        </p>

        <div className="mt-4 grid gap-4 md:grid-cols-2">
          <div className="space-y-1">
            <Label>Party</Label>
            <Input
              placeholder="Search parties, e.g. Greentown"
              value={picked ? picked.name : q}
              onChange={(e) => { setPicked(null); setQ(e.target.value) }}
            />
            {!picked && q.trim().length > 0 && options.length > 0 && (
              <ul className="max-h-48 overflow-y-auto rounded-md border text-sm">
                {options.map((o) => (
                  <li key={o.id}>
                    <button
                      type="button"
                      className="flex w-full items-center justify-between px-3 py-1.5 text-left hover:bg-muted"
                      onClick={() => { setPicked(o); setOptions([]) }}
                    >
                      <span className="truncate">{o.name}</span>
                      {o.typeCode && (
                        <span className="ml-2 shrink-0 text-xs text-muted-foreground">
                          {o.typeCode}
                        </span>
                      )}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="space-y-1">
            <Label>Folder name (optional)</Label>
            <Input
              placeholder={picked ? picked.name : 'Defaults to the party name'}
              value={label}
              onChange={(e) => setLabel(e.target.value)}
            />
          </div>

          <div className="space-y-1 md:col-span-2">
            <Label>Extra sender domains (optional)</Label>
            <Input
              placeholder="greentownlabs.com, mail.greentownlabs.com"
              value={domains}
              onChange={(e) => setDomains(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              For senders that are not registered contacts (newsletters, no-reply@).
              Comma separated; the @ and any https:// are stripped for you.
            </p>
          </div>

          <div className="space-y-1">
            <Label>Colour</Label>
            <div className="flex items-center gap-2">
              {SWATCHES.map((c) => (
                <button
                  key={c}
                  type="button"
                  aria-label={c}
                  onClick={() => setColor(c)}
                  className={
                    'h-6 w-6 rounded-full ring-offset-2 ' +
                    (color === c ? 'ring-2 ring-foreground' : '')
                  }
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>
        </div>

        <div className="mt-4">
          <Button onClick={handleAdd} disabled={saving || !picked} size="sm">
            <Plus className="mr-1 h-4 w-4" />
            {saving ? 'Adding...' : 'Add folder'}
          </Button>
        </div>
      </section>

      {/* -------------------------------------------------------- list */}
      <section>
        <h2 className="text-sm font-semibold">Folders</h2>
        {loading ? (
          <p className="mt-3 text-sm text-muted-foreground">Loading...</p>
        ) : folders.length === 0 ? (
          <p className="mt-3 text-sm text-muted-foreground">
            No folders yet. Add one above - Greentown Labs Houston is a good first pick.
          </p>
        ) : (
          <ul className="mt-3 divide-y rounded-lg border">
            {folders.map((f, i) => (
              <li key={f.id} className="flex flex-wrap items-center gap-3 px-4 py-3">
                <span
                  className="h-2.5 w-2.5 shrink-0 rounded-full"
                  style={{ backgroundColor: f.color ?? '#94a3b8' }}
                />
                <div className="min-w-0 flex-1">
                  <Link
                    href={`/inbox?folder=${f.id}`}
                    className="flex items-center gap-1.5 text-sm font-medium hover:underline"
                  >
                    <FolderOpen className="h-3.5 w-3.5" />
                    <span className="truncate">{f.name}</span>
                  </Link>
                  <p className="truncate text-xs text-muted-foreground">
                    {f.partyName}
                    {' \u00b7 '}
                    {f.unread} unread / {f.total} inbound
                  </p>
                </div>

                <Input
                  defaultValue={f.matchDomains.join(', ')}
                  placeholder="extra domains"
                  className="h-8 w-full text-xs md:w-72"
                  onBlur={(e) => handleDomainsBlur(f, e.target.value)}
                />

                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    title="Move up"
                    onClick={() => handleMove(i, -1)}
                    disabled={i === 0}
                    className="rounded p-1 text-muted-foreground hover:bg-muted disabled:opacity-30"
                  >
                    <ArrowUp className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    title="Move down"
                    onClick={() => handleMove(i, 1)}
                    disabled={i === folders.length - 1}
                    className="rounded p-1 text-muted-foreground hover:bg-muted disabled:opacity-30"
                  >
                    <ArrowDown className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    title="Remove"
                    onClick={() => handleRemove(f.id, f.name)}
                    className="rounded p-1 text-muted-foreground hover:bg-red-50 hover:text-red-600"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  )
}
