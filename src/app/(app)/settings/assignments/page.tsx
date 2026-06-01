// src/app/(app)/settings/assignments/page.tsx
// Manager/admin-only screen to assign parties to a user (owner).
import { createSupabaseServerClient } from '@/lib/supabase/server'
import AssignmentsClient, { type OrgUser } from './assignments-client'

export const dynamic = 'force-dynamic'

export default async function AssignmentsPage() {
  const supabase = await createSupabaseServerClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Permission guard: need parties.update scope = 'all' (manager/admin).
  let canManage = false
  if (user) {
    const { data: myRoles } = await supabase
      .schema('app')
      .from('user_roles' as never)
      .select('role_id')
      .eq('user_id', user.id)
    const roleIds = ((myRoles as any[]) ?? []).map((r) => r.role_id)
    if (roleIds.length) {
      const { data: perms } = await supabase
        .schema('app')
        .from('role_permissions' as never)
        .select('scope')
        .in('role_id', roleIds)
        .eq('resource', 'parties')
        .eq('action', 'update')
      canManage = ((perms as any[]) ?? []).some((p) => p.scope === 'all')
    }
  }

  if (!canManage) {
    return (
      <div className="mx-auto max-w-2xl px-6 py-16 text-center">
        <h1 className="text-lg font-semibold">Account assignments</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          You do not have permission to manage assignments. (Requires manager or admin.)
        </p>
      </div>
    )
  }

  // assignable users (active, same org)
  const { data: users } = await supabase
    .schema('app')
    .from('users' as never)
    .select('id, full_name, display_name, email, avatar_url')
    .eq('is_active', true)
    .order('full_name')

  return <AssignmentsClient users={((users as any) ?? []) as OrgUser[]} />
}
