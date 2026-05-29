// src/app/(app)/settings/audit/page.tsx
import { createSupabaseServerClient } from '@/lib/supabase/server'
import AuditClient, { type AuditRow, type UserLite } from './audit-client'

export const dynamic = 'force-dynamic'

export default async function AuditPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  // guard: need audit.read (admin/manager)
  let canRead = false
  if (user) {
    const { data: myRoles } = await supabase.schema('app').from('user_roles' as never)
      .select('role_id').eq('user_id', user.id)
    const roleIds = ((myRoles as any[]) ?? []).map((r) => r.role_id)
    if (roleIds.length) {
      const { data: perms } = await supabase.schema('app').from('role_permissions' as never)
        .select('scope').in('role_id', roleIds).eq('resource', 'audit').eq('action', 'read')
      canRead = ((perms as any[]) ?? []).length > 0
    }
  }

  if (!canRead) {
    return (
      <div className="mx-auto max-w-2xl px-6 py-16 text-center">
        <h1 className="text-lg font-semibold">Audit log</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          You do not have permission to view the audit log. (Requires manager or admin.)
        </p>
      </div>
    )
  }

  // recent 100 changes
  const { data: rows } = await supabase
    .schema('app').from('audit_log' as never)
    .select('id, table_name, record_id, operation, actor_user_id, old_data, new_data, changed_at')
    .order('changed_at', { ascending: false })
    .limit(100)

  // resolve actor names
  const { data: users } = await supabase
    .schema('app').from('users' as never)
    .select('id, full_name, display_name, email')

  return (
    <AuditClient
      rows={((rows as any) ?? []) as AuditRow[]}
      users={((users as any) ?? []) as UserLite[]}
    />
  )
}
