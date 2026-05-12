/**
 * lib/permissions.ts
 *
 * 권한 검사 헬퍼. Phase 1은 단순화된 규칙:
 *   - 조직 멤버 = 거의 모든 권한 (read·write·approve)
 *   - is_owner = true → 추가 권한 (조직 설정·감사 로그 SELECT 등)
 *
 * 향후 Phase 2에서 app.permissions·role_permissions 매핑을 세밀하게 적용할 때
 * 본 모듈의 시그니처(requirePermission)만 유지하면 호출 코드 무변경.
 *
 * 결정 근거: 솔로 창업자 시나리오에서 RBAC 복잡성은 오버 엔지니어링.
 */

import 'server-only';
import type { AuthContext } from '@/lib/auth';

/** 권한 액션 — DB의 app.permissions.action enum과 동일. */
export type PermissionAction =
  | 'create'
  | 'read'
  | 'update'
  | 'delete'
  | 'approve'
  | 'export'
  | 'admin';

/** 권한 리소스 — DB의 app.permissions.resource. */
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
 * 권한이 있는지 boolean 반환. UI 표시·숨김에 사용.
 */
export function hasPermission(
  auth: AuthContext | null,
  resource: PermissionResource,
  action: PermissionAction,
): boolean {
  if (!auth) return false;

  // Phase 1 규칙
  switch (resource) {
    case 'audit.change_log':
      // 감사 로그 SELECT는 소유자만 (RLS와 일치)
      return auth.isOwner;

    case 'organization.settings':
      // 조직 설정 변경은 소유자만
      if (action === 'update' || action === 'admin') return auth.isOwner;
      // 조회는 모든 멤버
      return action === 'read';

    case 'ai.agents':
    case 'ai.brand_voice':
      // 에이전트·브랜드 보이스 편집은 Phase 2이므로 read만 허용
      return action === 'read';

    default:
      // 그 외 모든 리소스 — 멤버는 read/create/update/delete/approve 가능
      return action !== 'admin';
  }
}

/**
 * 권한 없으면 throw — Server Action에서 사용.
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
