/**
 * app/(app)/layout.tsx
 * Phase 22b: inbox unread + open tasks badges
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

  const [userRes, pendingCountRes, inboxUnreadRes, openTaskRes] = await Promise.all([
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
    supabase
      .schema('app')
      .from('communications' as never)
      .select('id', { count: 'exact', head: true })
      .eq('direction', 'inbound')
      .is('read_at' as never, null)
      .is('deleted_at' as never, null),
    supabase
      .schema('app')
      .from('tasks' as never)
      .select('id', { count: 'exact', head: true })
      .not('status' as never, 'in', '("done","cancelled")')
      .is('deleted_at' as never, null),
  ]);

  const userRow = (userRes.data ?? null) as
    | { full_name?: string | null; display_name?: string | null }
    | null;
  const displayName = userRow?.display_name ?? userRow?.full_name ?? null;
  const initialPendingCount = pendingCountRes.count ?? 0;
  const initialInboxUnreadCount = (inboxUnreadRes as any).count ?? 0;
  const initialOpenTaskCount = (openTaskRes as any).count ?? 0;

  return (
    <>
      <RealtimeProvider
        organizationId={auth.organizationId}
        initialPendingCount={initialPendingCount}
        initialInboxUnreadCount={initialInboxUnreadCount}
        initialOpenTaskCount={initialOpenTaskCount}
      />
      <AppShell email={auth.email} displayName={displayName}>
        {children}
      </AppShell>
    </>
  );
}