// src/app/(app)/settings/permissions/actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient } from '@/lib/supabase/server'

type R = { ok: boolean; error?: string }

export async function assignRole(userId: string, roleId: string): Promise<R> {
  const supabase = await createSupabaseServerClient()
  const { data: role } = await supabase
    .schema('app').from('roles' as never)
    .select('organization_id').eq('id', roleId).single()
  if (!role) return { ok: false, error: 'Role not found.' }

  const { error } = await supabase
    .schema('app').from('user_roles' as never)
    .upsert({
      user_id: userId,
      role_id: roleId,
      organization_id: (role as any).organization_id,
    } as any, { onConflict: 'user_id,role_id' })

  if (error) return { ok: false, error: error.message }
  revalidatePath('/settings/permissions')
  return { ok: true }
}

export async function unassignRole(userId: string, roleId: string): Promise<R> {
  const supabase = await createSupabaseServerClient()
  const { error } = await supabase
    .schema('app').from('user_roles' as never)
    .delete().eq('user_id', userId).eq('role_id', roleId)
  if (error) return { ok: false, error: error.message }
  revalidatePath('/settings/permissions')
  return { ok: true }
}

// scope = null  -> remove the permission from the role
export async function setRolePermission(
  roleId: string,
  resource: string,
  action: string,
  scope: 'own' | 'all' | null,
): Promise<R> {
  const supabase = await createSupabaseServerClient()

  if (scope === null) {
    const { error } = await supabase
      .schema('app').from('role_permissions' as never)
      .delete().eq('role_id', roleId).eq('resource', resource).eq('action', action)
    if (error) return { ok: false, error: error.message }
  } else {
    const { error } = await supabase
      .schema('app').from('role_permissions' as never)
      .upsert({ role_id: roleId, resource, action, scope } as any,
              { onConflict: 'role_id,resource,action' })
    if (error) return { ok: false, error: error.message }
  }
  revalidatePath('/settings/permissions')
  return { ok: true }
}
