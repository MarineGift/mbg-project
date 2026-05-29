// src/app/(app)/settings/audit/audit-client.tsx
'use client'

import { useMemo, useState } from 'react'
import { ChevronDown, ChevronRight, Plus, Pencil, Trash2 } from 'lucide-react'

export type AuditRow = {
  id: number
  table_name: string
  record_id: string | null
  operation: 'INSERT' | 'UPDATE' | 'DELETE'
  actor_user_id: string | null
  old_data: Record<string, any> | null
  new_data: Record<string, any> | null
  changed_at: string
}
export type UserLite = { id: string; full_name: string | null; display_name: string | null; email: string | null }

const OP_META: Record<string, { label: string; cls: string; Icon: any }> = {
  INSERT: { label: 'Created', cls: 'text-emerald-600', Icon: Plus },
  UPDATE: { label: 'Updated', cls: 'text-blue-600', Icon: Pencil },
  DELETE: { label: 'Deleted', cls: 'text-red-600', Icon: Trash2 },
}

// fields not worth showing in a diff
const SKIP = new Set(['updated_at', 'created_at'])

function changedFields(oldD: any, newD: any): { key: string; from: any; to: any }[] {
  if (oldD && newD) {
    const keys = new Set([...Object.keys(oldD), ...Object.keys(newD)])
    const out: { key: string; from: any; to: any }[] = []
    keys.forEach((k) => {
      if (SKIP.has(k)) return
      if (JSON.stringify(oldD[k]) !== JSON.stringify(newD[k])) out.push({ key: k, from: oldD[k], to: newD[k] })
    })
    return out
  }
  const src = newD ?? oldD ?? {}
  return Object.keys(src).filter((k) => !SKIP.has(k)).map((k) => ({ key: k, from: oldD?.[k], to: newD?.[k] }))
}

function fmtVal(v: any): string {
  if (v === null || v === undefined) return '\u2014'
  if (typeof v === 'object') return JSON.stringify(v)
  return String(v)
}

export default function AuditClient({ rows, users }: { rows: AuditRow[]; users: UserLite[] }) {
  const [expanded, setExpanded] = useState<Set<number>>(new Set())
  const [table, setTable] = useState('all')
  const [op, setOp] = useState('all')

  const userMap = useMemo(() => {
    const m = new Map<string, UserLite>()
    for (const u of users) m.set(u.id, u)
    return m
  }, [users])

  const tables = useMemo(
    () => Array.from(new Set(rows.map((r) => r.table_name))).sort(),
    [rows],
  )

  const filtered = rows.filter(
    (r) => (table === 'all' || r.table_name === table) && (op === 'all' || r.operation === op),
  )

  function actorLabel(id: string | null): string {
    if (!id) return 'System'
    const u = userMap.get(id)
    return u ? (u.display_name?.trim() || u.full_name?.trim() || u.email || id) : 'Unknown user'
  }

  function toggle(id: number) {
    setExpanded((prev) => { const n = new Set(prev); n.has(id) ? n.delete(id) : n.add(id); return n })
  }

  return (
    <div className="mx-auto w-full max-w-4xl px-6 py-8">
      <h1 className="text-2xl font-semibold tracking-tight">Audit log</h1>
      <p className="mb-6 text-sm text-muted-foreground">
        Most recent 100 changes. System (SQL/import) actions show as {'\u201c'}System{'\u201d'}.
      </p>

      <div className="mb-4 flex flex-wrap items-center gap-3 text-sm">
        <select value={table} onChange={(e) => setTable(e.target.value)} className="rounded-md border bg-background px-2.5 py-1.5">
          <option value="all">All tables</option>
          {tables.map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
        <select value={op} onChange={(e) => setOp(e.target.value)} className="rounded-md border bg-background px-2.5 py-1.5">
          <option value="all">All operations</option>
          <option value="INSERT">Created</option>
          <option value="UPDATE">Updated</option>
          <option value="DELETE">Deleted</option>
        </select>
      </div>

      {filtered.length === 0 ? (
        <div className="rounded-lg border border-dashed py-16 text-center text-sm text-muted-foreground">
          No audit entries.
        </div>
      ) : (
        <ul className="divide-y rounded-lg border">
          {filtered.map((r) => {
            const meta = OP_META[r.operation]
            const open = expanded.has(r.id)
            const diffs = changedFields(r.old_data, r.new_data)
            return (
              <li key={r.id} className="px-3 py-2.5">
                <button onClick={() => toggle(r.id)} className="flex w-full items-center gap-2 text-left">
                  {open ? <ChevronDown className="h-3.5 w-3.5 shrink-0" /> : <ChevronRight className="h-3.5 w-3.5 shrink-0" />}
                  <meta.Icon className={`h-3.5 w-3.5 shrink-0 ${meta.cls}`} />
                  <span className="text-sm">
                    <span className={`font-medium ${meta.cls}`}>{meta.label}</span>{' '}
                    <span className="font-medium">{r.table_name}</span>
                    <span className="text-muted-foreground"> by {actorLabel(r.actor_user_id)}</span>
                  </span>
                  <span className="ml-auto shrink-0 text-xs text-muted-foreground">
                    {new Date(r.changed_at).toLocaleString('en-US')}
                  </span>
                </button>

                {open && (
                  <div className="ml-7 mt-2 space-y-1 text-xs">
                    <div className="text-muted-foreground">record: {r.record_id ?? '\u2014'}</div>
                    {diffs.length === 0 ? (
                      <div className="text-muted-foreground">No field-level changes.</div>
                    ) : (
                      <table className="w-full">
                        <tbody>
                          {diffs.map((d) => (
                            <tr key={d.key} className="align-top">
                              <td className="py-0.5 pr-3 font-medium">{d.key}</td>
                              <td className="py-0.5 pr-2 text-red-600 line-through break-all">{fmtVal(d.from)}</td>
                              <td className="py-0.5 text-emerald-600 break-all">{fmtVal(d.to)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    )}
                  </div>
                )}
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
