// src/components/settings/settings-nav-perms.ts
'use server'

import { createSupabaseServerClient } from '@/lib/supabase/server'

export type MenuPerms = {
  canAssign: boolean       // parties.update = all  (manager/admin)
  canManageRoles: boolean  // roles.manage          (admin)
  canViewAudit: boolean    // audit.read            (manager/admin)
}

export async function getMyMenuPerms(): Promise<MenuPerms> {
  const result: MenuPerms = { canAssign: false, canManageRoles: false, canViewAudit: false }

  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return result

  const { data: myRoles } = await supabase
    .schema('app').from('user_roles' as never)
    .select('role_id').eq('user_id', user.id)
  const roleIds = ((myRoles as any[]) ?? []).map((r) => r.role_id)
  if (!roleIds.length) return result

  const { data: perms } = await supabase
    .schema('app').from('role_permissions' as never)
    .select('resource, action, scope').in('role_id', roleIds)
  const ps = (perms as any[]) ?? []

  result.canAssign = ps.some((p) => p.resource === 'parties' && p.action === 'update' && p.scope === 'all')
  result.canManageRoles = ps.some((p) => p.resource === 'roles' && p.action === 'manage')
  result.canViewAudit = ps.some((p) => p.resource === 'audit' && p.action === 'read')
  return result
}
