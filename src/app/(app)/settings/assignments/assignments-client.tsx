// src/app/(app)/settings/assignments/assignments-client.tsx
'use client'

import { useEffect, useMemo, useState, useTransition } from 'react'
import { Button } from '@/components/ui/button'
import {
  searchAssignableParties,
  assignParties,
  type PartyRow,
} from './actions'

export type OrgUser = {
  id: string
  full_name: string | null
  display_name: string | null
  email: string | null
  avatar_url: string | null
}

function userLabel(u: OrgUser | undefined): string {
  if (!u) return '(unknown)'
  return u.display_name?.trim() || u.full_name?.trim() || u.email || '(no name)'
}

export default function AssignmentsClient({ users }: { users: OrgUser[] }) {
  const [query, setQuery] = useState('')
  const [ownerFilter, setOwnerFilter] = useState<string>('unassigned')
  const [rows, setRows] = useState<PartyRow[]>([])
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [bulkTarget, setBulkTarget] = useState<string>('') // '' = unassign
  const [loading, setLoading] = useState(true)
  const [msg, setMsg] = useState<string | null>(null)
  const [pending, startTransition] = useTransition()

  const userMap = useMemo(() => {
    const m = new Map<string, OrgUser>()
    for (const u of users) m.set(u.id, u)
    return m
  }, [users])

  // debounced load on query/filter change
  useEffect(() => {
    setLoading(true)
    const t = setTimeout(async () => {
      try {
        const data = await searchAssignableParties(query, ownerFilter)
        setRows(data)
        setSelected(new Set())
      } catch (e) {
        setMsg('Load error: ' + (e as Error).message)
        setRows([])
      } finally {
        setLoading(false)
      }
    }, 250)
    return () => clearTimeout(t)
  }, [query, ownerFilter])

  function reload() {
    startTransition(async () => {
      const data = await searchAssignableParties(query, ownerFilter)
      setRows(data)
      setSelected(new Set())
    })
  }

  function toggle(id: string) {
    setSelected((prev) => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  function toggleAll() {
    setSelected((prev) =>
      prev.size === rows.length ? new Set() : new Set(rows.map((r) => r.id)),
    )
  }

  function doAssign(partyIds: string[], target: string) {
    if (!partyIds.length) return
    setMsg(null)
    startTransition(async () => {
      const res = await assignParties(partyIds, target || null)
      if (!res.ok) {
        setMsg(res.error ?? 'Assignment failed.')
        return
      }
      setMsg(`Assigned ${res.count} party(ies).`)
      reload()
    })
  }

  return (
    <div className="mx-auto w-full max-w-4xl px-6 py-8">
      <div className="mb-1 flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Account assignments</h1>
      </div>
      <p className="mb-6 text-sm text-muted-foreground">
        Assign parties to a user. Reps see only parties assigned to them (and their contacts).
      </p>

      {/* Filter bar */}
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search parties..."
          className="min-w-[220px] flex-1 rounded-md border bg-background px-3 py-2 text-sm"
        />
        <select
          value={ownerFilter}
          onChange={(e) => setOwnerFilter(e.target.value)}
          className="rounded-md border bg-background px-2.5 py-2 text-sm"
        >
          <option value="all">All owners</option>
          <option value="unassigned">Unassigned</option>
          {users.map((u) => (
            <option key={u.id} value={u.id}>
              {userLabel(u)}
            </option>
          ))}
        </select>
      </div>

      {/* Bulk bar */}
      {selected.size > 0 && (
        <div className="mb-3 flex flex-wrap items-center gap-2 rounded-md border bg-muted/40 px-3 py-2 text-sm">
          <span className="font-medium">{selected.size} selected</span>
          <span className="text-muted-foreground">{'\u2192'}</span>
          <select
            value={bulkTarget}
            onChange={(e) => setBulkTarget(e.target.value)}
            className="rounded-md border bg-background px-2 py-1.5 text-sm"
          >
            <option value="">Unassign</option>
            {users.map((u) => (
              <option key={u.id} value={u.id}>
                {userLabel(u)}
              </option>
            ))}
          </select>
          <Button
            size="sm"
            disabled={pending}
            onClick={() => doAssign(Array.from(selected), bulkTarget)}
          >
            Apply
          </Button>
        </div>
      )}

      {msg && <p className="mb-3 text-sm text-emerald-600">{msg}</p>}

      {/* List */}
      {loading ? (
        <div className="py-16 text-center text-sm text-muted-foreground">Loading...</div>
      ) : rows.length === 0 ? (
        <div className="rounded-lg border border-dashed py-16 text-center text-sm text-muted-foreground">
          No parties match.
        </div>
      ) : (
        <div className="rounded-lg border">
          <div className="flex items-center gap-3 border-b bg-muted/30 px-3 py-2 text-xs font-medium text-muted-foreground">
            <input
              type="checkbox"
              checked={selected.size === rows.length && rows.length > 0}
              onChange={toggleAll}
              className="h-3.5 w-3.5"
            />
            <span className="flex-1">Party ({rows.length}, max 100)</span>
            <span className="w-48">Owner</span>
          </div>
          <ul className="divide-y">
            {rows.map((r) => (
              <li key={r.id} className="flex items-center gap-3 px-3 py-2.5">
                <input
                  type="checkbox"
                  checked={selected.has(r.id)}
                  onChange={() => toggle(r.id)}
                  className="h-3.5 w-3.5"
                />
                <span className="flex-1 truncate text-sm">{r.party_name}</span>
                <select
                  value={r.owner_user_id ?? ''}
                  disabled={pending}
                  onChange={(e) => doAssign([r.id], e.target.value)}
                  className="w-48 rounded-md border bg-background px-2 py-1.5 text-sm"
                >
                  <option value="">(unassigned)</option>
                  {users.map((u) => (
                    <option key={u.id} value={u.id}>
                      {userLabel(u)}
                    </option>
                  ))}
                </select>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}
