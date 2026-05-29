// src/app/(app)/settings/permissions/page.tsx
import { createSupabaseServerClient } from '@/lib/supabase/server'
import PermissionsClient, {
  type Role, type Perm, type RolePerm, type OrgUser, type UserRole,
} from './permissions-client'

export const dynamic = 'force-dynamic'

export default async function PermissionsPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  // guard: need roles.manage (admin)
  let canManage = false
  if (user) {
    const { data: myRoles } = await supabase.schema('app').from('user_roles' as never)
      .select('role_id').eq('user_id', user.id)
    const roleIds = ((myRoles as any[]) ?? []).map((r) => r.role_id)
    if (roleIds.length) {
      const { data: perms } = await supabase.schema('app').from('role_permissions' as never)
        .select('scope').in('role_id', roleIds).eq('resource', 'roles').eq('action', 'manage')
      canManage = ((perms as any[]) ?? []).length > 0
    }
  }

  if (!canManage) {
    return (
      <div className="mx-auto max-w-2xl px-6 py-16 text-center">
        <h1 className="text-lg font-semibold">Roles &amp; permissions</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          You do not have permission to manage roles. (Requires admin.)
        </p>
      </div>
    )
  }

  const [roles, perms, rolePerms, users, userRoles] = await Promise.all([
    supabase.schema('app').from('roles' as never).select('id, code, name'),
    supabase.schema('app').from('permissions' as never).select('resource, action, label'),
    supabase.schema('app').from('role_permissions' as never).select('role_id, resource, action, scope'),
    supabase.schema('app').from('users' as never).select('id, full_name, display_name, email').eq('is_active', true).order('full_name'),
    supabase.schema('app').from('user_roles' as never).select('user_id, role_id'),
  ])

  return (
    <PermissionsClient
      roles={((roles.data as any) ?? []) as Role[]}
      perms={((perms.data as any) ?? []) as Perm[]}
      rolePerms={((rolePerms.data as any) ?? []) as RolePerm[]}
      users={((users.data as any) ?? []) as OrgUser[]}
      userRoles={((userRoles.data as any) ?? []) as UserRole[]}
    />
  )
}
