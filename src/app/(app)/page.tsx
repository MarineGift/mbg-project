/**
 * app/(app)/page.tsx
 *
 * Unified dashboard.
 * Shows quick stats (AI drafts, Inbox, Tasks) + welcome card.
 */

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Sparkles, Inbox, CheckSquare } from 'lucide-react';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export default async function DashboardPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  // Quick counts (best-effort; failures fall back to 0)
  const [draftsRes, inboxRes, tasksRes] = await Promise.all([
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
      .is('read_at' as never, null),
    supabase
      .schema('app')
      .from('tasks' as never)
      .select('id', { count: 'exact', head: true })
      .not('status' as never, 'in', '("done","cancelled")'),
  ]);

  const draftsCount = (draftsRes as any).count ?? 0;
  const inboxCount = (inboxRes as any).count ?? 0;
  const tasksCount = (tasksRes as any).count ?? 0;

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">URM Platform</h1>
        <p className="text-sm text-muted-foreground mt-1">{auth.email}</p>
      </header>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">AI Drafts</CardTitle>
            <Sparkles className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums">{draftsCount}</div>
            <CardDescription className="mt-1">Pending review</CardDescription>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Inbox</CardTitle>
            <Inbox className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums">{inboxCount}</div>
            <CardDescription className="mt-1">Unread inbound</CardDescription>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tasks</CardTitle>
            <CheckSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums">{tasksCount}</div>
            <CardDescription className="mt-1">Open</CardDescription>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Welcome</CardTitle>
          <CardDescription>
            Your unified dashboard. Real-time counts above update automatically.
            Use the sidebar to navigate to AI Drafts, Inbox, Tasks, and per-module Parties.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  );
}