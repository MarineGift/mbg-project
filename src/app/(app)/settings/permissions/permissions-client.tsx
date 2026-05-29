// src/app/(app)/settings/permissions/permissions-client.tsx
'use client'

import { useMemo, useState, useTransition } from 'react'
import { assignRole, unassignRole, setRolePermission } from './actions'

export type Role = { id: string; code: string; name: string }
export type Perm = { resource: string; action: string; label: string | null }
export type RolePerm = { role_id: string; resource: string; action: string; scope: 'own' | 'all' }
export type OrgUser = { id: string; full_name: string | null; display_name: string | null; email: string | null }
export type UserRole = { user_id: string; role_id: string }

const ROLE_ORDER = ['admin', 'manager', 'sales_rep', 'read_only']

function userLabel(u: OrgUser): string {
  return u.display_name?.trim() || u.full_name?.trim() || u.email || '(no name)'
}

export default function PermissionsClient({
  roles, perms, rolePerms, users, userRoles,
}: {
  roles: Role[]; perms: Perm[]; rolePerms: RolePerm[]; users: OrgUser[]; userRoles: UserRole[]
}) {
  const [pending, startTransition] = useTransition()
  const [msg, setMsg] = useState<string | null>(null)

  // local mirrors for optimistic UI
  const [urSet, setUrSet] = useState<Set<string>>(
    () => new Set(userRoles.map((x) => `${x.user_id}:${x.role_id}`)),
  )
  const [rpMap, setRpMap] = useState<Map<string, 'own' | 'all'>>(
    () => new Map(rolePerms.map((x) => [`${x.role_id}:${x.resource}:${x.action}`, x.scope])),
  )

  const sortedRoles = useMemo(
    () => [...roles].sort((a, b) => ROLE_ORDER.indexOf(a.code) - ROLE_ORDER.indexOf(b.code)),
    [roles],
  )

  function toggleUserRole(userId: string, roleId: string, on: boolean) {
    const key = `${userId}:${roleId}`
    setUrSet((prev) => { const n = new Set(prev); on ? n.add(key) : n.delete(key); return n })
    startTransition(async () => {
      const res = on ? await assignRole(userId, roleId) : await unassignRole(userId, roleId)
      if (!res.ok) { setMsg(res.error ?? 'Failed.'); }
    })
  }

  function changeScope(roleId: string, resource: string, action: string, value: string) {
    const key = `${roleId}:${resource}:${action}`
    const scope = value === '' ? null : (value as 'own' | 'all')
    setRpMap((prev) => {
      const n = new Map(prev)
      if (scope === null) n.delete(key); else n.set(key, scope)
      return n
    })
    startTransition(async () => {
      const res = await setRolePermission(roleId, resource, action, scope)
      if (!res.ok) setMsg(res.error ?? 'Failed.')
    })
  }

  return (
    <div className="mx-auto w-full max-w-5xl px-6 py-8">
      <h1 className="text-2xl font-semibold tracking-tight">Roles &amp; permissions</h1>
      {msg && <p className="mt-2 text-sm text-red-600">{msg}</p>}

      {/* ---------- A) Users -> roles ---------- */}
      <section className="mt-6">
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Users
        </h2>
        <div className="overflow-x-auto rounded-lg border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/30 text-left">
                <th className="px-3 py-2 font-medium">User</th>
                {sortedRoles.map((r) => (
                  <th key={r.id} className="px-3 py-2 text-center font-medium">{r.name}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y">
              {users.map((u) => (
                <tr key={u.id}>
                  <td className="px-3 py-2">
                    <div>{userLabel(u)}</div>
                    {u.email && <div className="text-xs text-muted-foreground">{u.email}</div>}
                  </td>
                  {sortedRoles.map((r) => {
                    const on = urSet.has(`${u.id}:${r.id}`)
                    return (
                      <td key={r.id} className="px-3 py-2 text-center">
                        <input
                          type="checkbox"
                          checked={on}
                          disabled={pending}
                          onChange={(e) => toggleUserRole(u.id, r.id, e.target.checked)}
                          className="h-4 w-4"
                        />
                      </td>
                    )
                  })}
                </tr>
              ))}
              {users.length === 0 && (
                <tr><td className="px-3 py-6 text-center text-muted-foreground" colSpan={sortedRoles.length + 1}>
                  No active users.
                </td></tr>
              )}
            </tbody>
          </table>
        </div>
        <p className="mt-2 text-xs text-muted-foreground">
          To add a sales rep: that person must first have a login (Supabase invite/signup), then check their Sales Rep box here.
        </p>
      </section>

      {/* ---------- B) Role x permission matrix ---------- */}
      <section className="mt-10">
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Role permissions
        </h2>
        <div className="overflow-x-auto rounded-lg border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/30 text-left">
                <th className="px-3 py-2 font-medium">Permission</th>
                {sortedRoles.map((r) => (
                  <th key={r.id} className="px-3 py-2 text-center font-medium">{r.name}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y">
              {perms.map((p) => (
                <tr key={`${p.resource}:${p.action}`}>
                  <td className="px-3 py-2">
                    <span className="font-medium">{p.resource}</span>
                    <span className="text-muted-foreground">.{p.action}</span>
                  </td>
                  {sortedRoles.map((r) => {
                    const cur = rpMap.get(`${r.id}:${p.resource}:${p.action}`) ?? ''
                    return (
                      <td key={r.id} className="px-3 py-2 text-center">
                        <select
                          value={cur}
                          disabled={pending}
                          onChange={(e) => changeScope(r.id, p.resource, p.action, e.target.value)}
                          className="rounded-md border bg-background px-1.5 py-1 text-xs"
                        >
                          <option value="">{'\u2014'}</option>
                          <option value="own">own</option>
                          <option value="all">all</option>
                        </select>
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="mt-2 text-xs text-amber-600">
          Careful: do not remove roles.manage from your own admin role, or you will lock yourself out of this page.
        </p>
      </section>
    </div>
  )
}
