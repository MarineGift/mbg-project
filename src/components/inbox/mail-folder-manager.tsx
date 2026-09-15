'use client'
// src/components/inbox/mail-folder-manager.tsx
//
// 2026-09-15 - manage pinned mail folders (/inbox/folders), nested groups.
//
//   Business            group
//     Omya              group   <- omya.com pinned here, once
//       Omya (Korea)    party
//       Omya (USA)      party
//     Specialty Minerals
//
// Removing a folder never touches mail; children move up to the parent level.
// Counts come from app.mail_folder_counts() (distinct per subtree).

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { FolderOpen, FolderPlus, Plus, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { compareFolders } from '@/components/layout/mail-folder-nav'
import {
  listMailFoldersWithCountsAction,
  createMailFolderAction,
  updateMailFolderAction,
  deleteMailFolderAction,
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

  // add-folder form
  const [q, setQ] = useState('')
  const [options, setOptions] = useState<PartyOption[]>([])
  const [picked, setPicked] = useState<PartyOption | null>(null)
  const [label, setLabel] = useState('')
  const [color, setColor] = useState(SWATCHES[0] as string)
  const [domains, setDomains] = useState('')
  const [parentId, setParentId] = useState('')
  const [saving, setSaving] = useState(false)

  // add-group form
  const [groupName, setGroupName] = useState('')
  const [groupParentId, setGroupParentId] = useState('')
  const [groupSaving, setGroupSaving] = useState(false)

  const reload = useCallback(async () => {
    setLoading(true)
    const res = await listMailFoldersWithCountsAction()
    if (res.ok) setFolders(res.data)
    else setError(res.error)
    setLoading(false)
  }, [])

  useEffect(() => { void reload() }, [reload])

  useEffect(() => {
    let cancelled = false
    const t = setTimeout(async () => {
      const res = await searchPartiesForFolderAction(q)
      if (!cancelled && res.ok) setOptions(res.data)
    }, 250)
    return () => { cancelled = true; clearTimeout(t) }
  }, [q])

  /* ---------------------------------------------------------------- tree */

  const ids = new Set(folders.map((f) => f.id))
  // Same order as the sidebar: folders that receive mail first, then A-Z.
  const childrenOf = (id: string | null) =>
    folders
      .filter((f) =>
        id === null ? !f.parentId || !ids.has(f.parentId) : f.parentId === id,
      )
      .sort(compareFolders)

  // Groups, flattened with an indent prefix, for the "move into" selects.
  const groupOptions: Array<{ id: string; label: string }> = []
  const collectGroups = (parent: string | null, depth: number) => {
    for (const f of childrenOf(parent)) {
      if (f.isGroup) {
        groupOptions.push({ id: f.id, label: `${'\u2014 '.repeat(depth)}${f.name}` })
        collectGroups(f.id, depth + 1)
      }
    }
  }
  collectGroups(null, 0)

  const descendantsOf = (id: string): Set<string> => {
    const out = new Set<string>()
    const walk = (parent: string) => {
      for (const f of folders) {
        if (f.parentId === parent && !out.has(f.id)) { out.add(f.id); walk(f.id) }
      }
    }
    walk(id)
    return out
  }

  /* ------------------------------------------------------------ handlers */

  async function handleAddGroup() {
    if (!groupName.trim()) { setError('Name the group first'); return }
    setGroupSaving(true)
    setError(null)
    const res = await createMailFolderAction({
      isGroup: true,
      label: groupName.trim(),
      parentId: groupParentId || null,
    })
    setGroupSaving(false)
    if (!res.ok) { setError(res.error); return }
    setGroupName(''); setGroupParentId('')
    await reload(); router.refresh()
  }

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
    await reload(); router.refresh()
  }

  async function handleRemove(id: string, name: string) {
    if (!window.confirm(`Remove "${name}"? Mail is not deleted. Anything inside it moves up one level.`)) return
    const res = await deleteMailFolderAction(id)
    if (!res.ok) { setError(res.error); return }
    await reload(); router.refresh()
  }

  async function handleMoveToGroup(id: string, newParentId: string) {
    // Never let a group become its own descendant - that would orphan the
    // subtree and make the counts function recurse until the depth cap.
    if (newParentId && descendantsOf(id).has(newParentId)) {
      setError('A group cannot be moved inside itself')
      return
    }
    const res = await updateMailFolderAction(id, { parentId: newParentId || null })
    if (!res.ok) { setError(res.error); return }
    await reload(); router.refresh()
  }

  async function handleDomainsBlur(f: MailFolderWithCounts, value: string) {
    if (value.trim() === f.matchDomains.join(', ')) return
    const res = await updateMailFolderAction(f.id, { matchDomains: value })
    if (!res.ok) { setError(res.error); return }
    await reload()
  }

  /* -------------------------------------------------------------- render */

  const renderRows = (parent: string | null, depth: number): React.ReactNode[] => {
    return childrenOf(parent).flatMap((f) => [
      <li key={f.id} className="border-t first:border-t-0">
        <div
          className="flex flex-wrap items-center gap-3 px-4 py-3"
          style={{ paddingLeft: `${1 + depth * 1.5}rem` }}
        >
          {f.isGroup ? (
            <FolderPlus className="h-4 w-4 shrink-0 text-muted-foreground" />
          ) : (
            <span
              className="h-2.5 w-2.5 shrink-0 rounded-full"
              style={{ backgroundColor: f.color ?? '#94a3b8' }}
            />
          )}

          <div className="min-w-0 flex-1">
            <Link
              href={`/inbox?folder=${f.id}`}
              className={
                'flex items-center gap-1.5 text-sm hover:underline ' +
                (f.isGroup ? 'font-semibold' : 'font-medium')
              }
            >
              {!f.isGroup && <FolderOpen className="h-3.5 w-3.5" />}
              <span className="truncate">{f.name}</span>
            </Link>
            <p className="truncate text-xs text-muted-foreground">
              {f.isGroup ? 'group' : f.partyName}
              {' \u00b7 '}
              {f.unread} unread / {f.total} inbound
            </p>
          </div>

          <select
            value={f.parentId ?? ''}
            onChange={(e) => handleMoveToGroup(f.id, e.target.value)}
            className="h-8 rounded-md border bg-background px-2 text-xs"
            title="Move into group"
          >
            <option value="">Top level</option>
            {groupOptions
              .filter((g) => g.id !== f.id && !descendantsOf(f.id).has(g.id))
              .map((g) => (
                <option key={g.id} value={g.id}>{g.label}</option>
              ))}
          </select>

          <Input
            defaultValue={f.matchDomains.join(', ')}
            placeholder="extra domains"
            className="h-8 w-full text-xs md:w-56"
            onBlur={(e) => handleDomainsBlur(f, e.target.value)}
          />

          <div className="flex items-center gap-1">
            <button
              type="button"
              title="Remove"
              onClick={() => handleRemove(f.id, f.name)}
              className="rounded p-1 text-muted-foreground hover:bg-red-50 hover:text-red-600"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>

        {childrenOf(f.id).length > 0 && (
          <ul className="border-t bg-muted/20">{renderRows(f.id, depth + 1)}</ul>
        )}
      </li>,
    ])
  }

  return (
    <div className="space-y-8">
      {error && (
        <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      )}

      {/* -------------------------------------------------------- groups */}
      <section className="rounded-lg border p-4">
        <h2 className="text-sm font-semibold">Groups</h2>
        <p className="mt-1 text-xs text-muted-foreground">
          Groups hold folders and other groups - Business &gt; Omya &gt; Omya (Korea).
          Opening one shows everything inside it, counted once.
        </p>
        <div className="mt-3 flex flex-wrap items-end gap-2">
          <div className="space-y-1">
            <Label>New group</Label>
            <Input
              className="w-56"
              placeholder="e.g. Omya"
              value={groupName}
              onChange={(e) => setGroupName(e.target.value)}
            />
          </div>
          <div className="space-y-1">
            <Label>Inside</Label>
            <select
              value={groupParentId}
              onChange={(e) => setGroupParentId(e.target.value)}
              className="h-9 w-56 rounded-md border bg-background px-2 text-sm"
            >
              <option value="">Top level</option>
              {groupOptions.map((g) => (
                <option key={g.id} value={g.id}>{g.label}</option>
              ))}
            </select>
          </div>
          <Button size="sm" variant="outline" onClick={handleAddGroup} disabled={groupSaving}>
            <FolderPlus className="mr-1 h-4 w-4" />
            {groupSaving ? 'Adding...' : 'Add group'}
          </Button>
        </div>
      </section>

      {/* ---------------------------------------------------------- add */}
      <section className="rounded-lg border p-4">
        <h2 className="text-sm font-semibold">Add a folder</h2>
        <p className="mt-1 text-xs text-muted-foreground">
          Pick the party whose mail you want to watch. Mail is filed by the sender
          match made at ingest time - nothing is copied or moved.
        </p>

        <div className="mt-4 grid gap-4 md:grid-cols-2">
          <div className="space-y-1">
            <Label>Party</Label>
            <Input
              placeholder="Search parties, e.g. Omya"
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
              placeholder="omya.com"
              value={domains}
              onChange={(e) => setDomains(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              For senders that are not registered contacts. Pin a shared company
              domain on the GROUP instead of on each subsidiary, or the same mail
              shows up under every one of them.
            </p>
          </div>

          <div className="space-y-1">
            <Label>Group</Label>
            <select
              value={parentId}
              onChange={(e) => setParentId(e.target.value)}
              className="h-9 w-full rounded-md border bg-background px-2 text-sm"
            >
              <option value="">Top level</option>
              {groupOptions.map((g) => (
                <option key={g.id} value={g.id}>{g.label}</option>
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

      {/* --------------------------------------------------------- list */}
      <section>
        <h2 className="text-sm font-semibold">Folders</h2>
        <p className="mt-1 text-xs text-muted-foreground">
          Ordered automatically: folders that receive mail first, then A to Z.
          Empty folders sink to the bottom of their group.
        </p>
        {loading ? (
          <p className="mt-3 text-sm text-muted-foreground">Loading...</p>
        ) : folders.length === 0 ? (
          <p className="mt-3 text-sm text-muted-foreground">
            No folders yet. Add a group, then add parties into it.
          </p>
        ) : (
          <ul className="mt-3 rounded-lg border">{renderRows(null, 0)}</ul>
        )}
      </section>
    </div>
  )
}
