'use client'
// src/components/inbox/mail-folder-manager.tsx
//
// 2026-09-15 - manage pinned party mail folders (/inbox/folders).
// Pick a party, optionally pin extra sender domains, reorder, remove.
// Removing a folder never touches mail - it only drops the saved view.

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { ArrowDown, ArrowUp, FolderOpen, FolderPlus, Plus, Trash2 } from 'lucide-react'
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
  const [parentId, setParentId] = useState('')
  const [saving, setSaving] = useState(false)

  // new group
  const [groupName, setGroupName] = useState('')
  const [groupSaving, setGroupSaving] = useState(false)

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
      parentId: parentId || null,
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

  async function handleAddGroup() {
    if (!groupName.trim()) { setError('Name the group first'); return }
    setGroupSaving(true)
    setError(null)
    const res = await createMailFolderAction({ isGroup: true, label: groupName.trim() })
    setGroupSaving(false)
    if (!res.ok) { setError(res.error); return }
    setGroupName('')
    await reload()
    router.refresh()
  }

  async function handleMoveToGroup(id: string, newParentId: string) {
    const res = await updateMailFolderAction(id, { parentId: newParentId || null })
    if (!res.ok) { setError(res.error); return }
    await reload()
    router.refresh()
  }

  async function handleRemove(id: string, name: string) {
    if (!window.confirm(`Remove "${name}"? The mail itself is not deleted. Folders inside a group move back to the top level.`)) return
    const res = await deleteMailFolderAction(id)
    if (!res.ok) { setError(res.error); return }
    await reload()
    router.refresh()
  }

  // Reorders within the section the arrow was clicked in (a group's children,
  // or the ungrouped list) - not across the whole flat list.
  async function handleMove(
    siblings: MailFolderWithCounts[],
    index: number,
    delta: number,
  ) {
    const target = index + delta
    if (target < 0 || target >= siblings.length) return
    const next = [...siblings]
    const a = next[index]
    const b = next[target]
    if (!a || !b) return
    next[index] = b
    next[target] = a
    const res = await reorderMailFoldersAction(next.map((f) => f.id))
    if (!res.ok) { setError(res.error); return }
    await reload()
    router.refresh()
  }

  async function handleDomainsBlur(f: MailFolderWithCounts, value: string) {
    if (value.trim() === f.matchDomains.join(', ')) return
    const res = await updateMailFolderAction(f.id, { matchDomains: value })
    if (!res.ok) { setError(res.error); return }
    await reload()
  }

  const groups = folders.filter((f) => f.isGroup)
  const groupIds = new Set(groups.map((g) => g.id))
  const childrenOf = (id: string) => folders.filter((f) => !f.isGroup && f.parentId === id)
  const loose = folders.filter((f) => !f.isGroup && (!f.parentId || !groupIds.has(f.parentId)))

  return (
    <div className="space-y-8">
      {error && (
        <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      )}

      {/* -------------------------------------------------------- group */}
      <section className="rounded-lg border p-4">
        <h2 className="text-sm font-semibold">Groups</h2>
        <p className="mt-1 text-xs text-muted-foreground">
          A group holds several party folders - Partners, Investors, Business.
          Opening a group shows the mail of everything inside it at once.
        </p>
        <div className="mt-3 flex flex-wrap items-end gap-2">
          <div className="space-y-1">
            <Label>New group</Label>
            <Input
              className="w-56"
              placeholder="e.g. Business"
              value={groupName}
              onChange={(e) => setGroupName(e.target.value)}
            />
          </div>
          <Button size="sm" variant="outline" onClick={handleAddGroup} disabled={groupSaving}>
            <FolderPlus className="mr-1 h-4 w-4" />
            {groupSaving ? 'Adding...' : 'Add group'}
          </Button>
          {groups.length > 0 && (
            <p className="ml-auto text-xs text-muted-foreground">
              {groups.map((g) => g.name).join(' \u00b7 ')}
            </p>
          )}
        </div>
      </section>

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
            <Label>Group</Label>
            <select
              value={parentId}
              onChange={(e) => setParentId(e.target.value)}
              className="h-9 w-full rounded-md border bg-background px-2 text-sm"
            >
              <option value="">No group (top level)</option>
              {groups.map((g) => (
                <option key={g.id} value={g.id}>{g.name}</option>
              ))}
            </select>
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
            No folders yet. Add a group, then add parties into it.
          </p>
        ) : (
          <div className="mt-3 space-y-5">
            {groups.map((g) => (
              <div key={g.id} className="rounded-lg border">
                <div className="flex items-center gap-2 border-b bg-muted/40 px-4 py-2">
                  <span
                    className="h-2.5 w-2.5 rounded-full"
                    style={{ backgroundColor: g.color ?? '#94a3b8' }}
                  />
                  <Link href={`/inbox?folder=${g.id}`} className="text-sm font-semibold hover:underline">
                    {g.name}
                  </Link>
                  <span className="text-xs text-muted-foreground">
                    {g.unread} unread / {g.total} inbound
                  </span>
                  <button
                    type="button"
                    title="Remove group"
                    onClick={() => handleRemove(g.id, g.name)}
                    className="ml-auto rounded p-1 text-muted-foreground hover:bg-red-50 hover:text-red-600"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
                {childrenOf(g.id).length === 0 ? (
                  <p className="px-4 py-3 text-xs text-muted-foreground">
                    Empty - add a party above and pick this group.
                  </p>
                ) : (
                  <ul className="divide-y">
                    {childrenOf(g.id).map((f, i, arr) => (
                      <FolderRow
                        key={f.id}
                        folder={f}
                        index={i}
                        siblings={arr}
                        groups={groups}
                        onMove={handleMove}
                        onMoveToGroup={handleMoveToGroup}
                        onRemove={handleRemove}
                        onDomainsBlur={handleDomainsBlur}
                      />
                    ))}
                  </ul>
                )}
              </div>
            ))}

            {loose.length > 0 && (
              <div className="rounded-lg border">
                <div className="border-b bg-muted/40 px-4 py-2 text-sm font-semibold text-muted-foreground">
                  Ungrouped
                </div>
                <ul className="divide-y">
                  {loose.map((f, i, arr) => (
                    <FolderRow
                      key={f.id}
                      folder={f}
                      index={i}
                      siblings={arr}
                      groups={groups}
                      onMove={handleMove}
                      onMoveToGroup={handleMoveToGroup}
                      onRemove={handleRemove}
                      onDomainsBlur={handleDomainsBlur}
                    />
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  )
}

function FolderRow({
  folder, index, siblings, groups, onMove, onMoveToGroup, onRemove, onDomainsBlur,
}: {
  folder: MailFolderWithCounts
  index: number
  siblings: MailFolderWithCounts[]
  groups: MailFolderWithCounts[]
  onMove: (siblings: MailFolderWithCounts[], index: number, delta: number) => void
  onMoveToGroup: (id: string, parentId: string) => void
  onRemove: (id: string, name: string) => void
  onDomainsBlur: (f: MailFolderWithCounts, value: string) => void
}) {
  return (
    <li className="flex flex-wrap items-center gap-3 px-4 py-3">
      <span
        className="h-2.5 w-2.5 shrink-0 rounded-full"
        style={{ backgroundColor: folder.color ?? '#94a3b8' }}
      />
      <div className="min-w-0 flex-1">
        <Link
          href={`/inbox?folder=${folder.id}`}
          className="flex items-center gap-1.5 text-sm font-medium hover:underline"
        >
          <FolderOpen className="h-3.5 w-3.5" />
          <span className="truncate">{folder.name}</span>
        </Link>
        <p className="truncate text-xs text-muted-foreground">
          {folder.partyName}
          {' \u00b7 '}
          {folder.unread} unread / {folder.total} inbound
        </p>
      </div>

      <select
        value={folder.parentId ?? ''}
        onChange={(e) => onMoveToGroup(folder.id, e.target.value)}
        className="h-8 rounded-md border bg-background px-2 text-xs"
        title="Group"
      >
        <option value="">Ungrouped</option>
        {groups.map((g) => (
          <option key={g.id} value={g.id}>{g.name}</option>
        ))}
      </select>

      <Input
        defaultValue={folder.matchDomains.join(', ')}
        placeholder="extra domains"
        className="h-8 w-full text-xs md:w-64"
        onBlur={(e) => onDomainsBlur(folder, e.target.value)}
      />

      <div className="flex items-center gap-1">
        <button
          type="button"
          title="Move up"
          onClick={() => onMove(siblings, index, -1)}
          disabled={index === 0}
          className="rounded p-1 text-muted-foreground hover:bg-muted disabled:opacity-30"
        >
          <ArrowUp className="h-4 w-4" />
        </button>
        <button
          type="button"
          title="Move down"
          onClick={() => onMove(siblings, index, 1)}
          disabled={index === siblings.length - 1}
          className="rounded p-1 text-muted-foreground hover:bg-muted disabled:opacity-30"
        >
          <ArrowDown className="h-4 w-4" />
        </button>
        <button
          type="button"
          title="Remove"
          onClick={() => onRemove(folder.id, folder.name)}
          className="rounded p-1 text-muted-foreground hover:bg-red-50 hover:text-red-600"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
    </li>
  )
}
