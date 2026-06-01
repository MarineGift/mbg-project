/**
 * lib/permissions.ts
 *
 * Permission-check helper. Phase 1 uses simplified rules:
 *   - org member = almost all permissions (read/write/approve)
 *   - is_owner = true -> extra permissions (org settings, audit log SELECT, etc.)
 *
 * When Phase 2 later applies fine-grained app.permissions/role_permissions mapping,
 * keeping just this module's signature (requirePermission) means callers need no changes.
 *
 * Rationale: in a solo-founder scenario, RBAC complexity is over-engineering.
 */

import 'server-only';
import type { AuthContext } from '@/lib/auth';

/** Permission action - same as the DB's app.permissions.action enum. */
export type PermissionAction =
  | 'create'
  | 'read'
  | 'update'
  | 'delete'
  | 'approve'
  | 'export'
  | 'admin';

/** Permission resource - the DB's app.permissions.resource. */
export type PermissionResource =
  | 'parties'
  | 'contacts'
  | 'engagements'
  | 'communications'
  | 'tasks'
  | 'meetings'
  | 'ai.drafts'
  | 'ai.agents'
  | 'ai.brand_voice'
  | 'organization.settings'
  | 'audit.change_log';

export class PermissionError extends Error {
  constructor(
    public readonly resource: PermissionResource,
    public readonly action: PermissionAction,
  ) {
    super(`Permission denied: ${action} on ${resource}`);
    this.name = 'PermissionError';
  }
}

/**
 * Returns a boolean for whether permission is granted. Used to show/hide UI.
 */
export function hasPermission(
  auth: AuthContext | null,
  resource: PermissionResource,
  action: PermissionAction,
): boolean {
  if (!auth) return false;

  // Phase 1 rules
  switch (resource) {
    case 'audit.change_log':
      // audit log SELECT is owner-only (matches RLS)
      return auth.isOwner;

    case 'organization.settings':
      // changing org settings is owner-only
      if (action === 'update' || action === 'admin') return auth.isOwner;
      // reads are for all members
      return action === 'read';

    case 'ai.agents':
    case 'ai.brand_voice':
      // editing agents/brand voice is Phase 2, so read only
      return action === 'read';

    default:
      // all other resources - members can read/create/update/delete/approve
      return action !== 'admin';
  }
}

/**
 * throw if no permission - used in Server Actions.
 */
export function requirePermission(
  auth: AuthContext | null,
  resource: PermissionResource,
  action: PermissionAction,
): asserts auth is AuthContext {
  if (!hasPermission(auth, resource, action)) {
    throw new PermissionError(resource, action);
  }
}
