/**
 * app/(app)/layout.tsx
 *
 * 인증된 사용자 전용 route group의 레이아웃.
 *   - middleware가 1차 인증 가드
 *   - 본 레이아웃에서 2차 검증
 *   - Realtime 구독 mount (pending draft 카운트 라이브 갱신)
 */

import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { AppShell } from '@/components/layout/app-shell';
import { RealtimeProvider } from '@/components/providers/realtime-provider';

export default async function AppGroupLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  const [userRes, pendingCountRes] = await Promise.all([
    supabase
      .schema('app')
      .from('users' as never)
      .select('full_name, display_name')
      .eq('id', auth.userId)
      .maybeSingle(),
    supabase
      .schema('ai')
      .from('drafts' as never)
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending_review'),
  ]);

  const userRow = (userRes.data ?? null) as
    | { full_name?: string | null; display_name?: string | null }
    | null;
  const displayName = userRow?.display_name ?? userRow?.full_name ?? null;
  const initialPendingCount = pendingCountRes.count ?? 0;

  return (
    <>
      <RealtimeProvider
        organizationId={auth.organizationId}
        initialPendingCount={initialPendingCount}
      />
      <AppShell email={auth.email} displayName={displayName}>
        {children}
      </AppShell>
    </>
  );
}
