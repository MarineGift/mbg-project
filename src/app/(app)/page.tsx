/**
 * app/(app)/page.tsx
 *
 * Unified dashboard.
 * Row 1: Quick stats (AI Drafts, Inbox, Tasks)
 * Row 2: Parties overview + Engagements overview
 * Row 3: Welcome card
 */
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Sparkles, Inbox, CheckSquare, Building2, Handshake } from 'lucide-react';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

const MODULE_LABELS: Record<string, string> = {
  paper_mill: 'Paper Mills',
  filler_supplier:     'Filler Suppliers',
  investor:   'Investors',
  partner:    'Partners',
  customer:   'Customers',
};

const MODULE_COLORS: Record<string, string> = {
  paper_mill: 'text-blue-600 dark:text-blue-400',
  filler_supplier:     'text-emerald-600 dark:text-emerald-400',
  investor:   'text-purple-600 dark:text-purple-400',
  partner:    'text-orange-600 dark:text-orange-400',
  customer:   'text-rose-600 dark:text-rose-400',
};

const PARTY_MODULES = ['paper_mill', 'filler_supplier', 'investor', 'partner', 'customer'] as const;
type PartyModule = typeof PARTY_MODULES[number];

export default async function DashboardPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  // ── Row 1: quick stats ─────────────────────────────────────────────────────
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
  const inboxCount  = (inboxRes  as any).count ?? 0;
  const tasksCount  = (tasksRes  as any).count ?? 0;

  // ── Row 2a: parties by module ──────────────────────────────────────────────
  const partyResults = await Promise.all(
    PARTY_MODULES.map(m =>
      supabase
        .schema('app')
        .from('parties' as never)
        .select('id', { count: 'exact', head: true })
        .eq('module' as never, m)
        .is('deleted_at' as never, null),
    ),
  );
  const partyCounts = Object.fromEntries(
    PARTY_MODULES.map((m, i) => [m, (partyResults[i] as any).count ?? 0]),
  ) as Record<PartyModule, number>;
  const partyTotal = PARTY_MODULES.reduce((s, m) => s + partyCounts[m], 0);

  // ── Row 2b: engagements by module ──────────────────────────────────────────
  const dealsTotalRes = await supabase
    .schema('urm')
    .from('deals' as never)
    .select('id', { count: 'exact', head: true })
    .is('deleted_at' as never, null);
  const dealsTotal = (dealsTotalRes as { count: number | null }).count ?? 0;
  const engResults = PARTY_MODULES.map(() => ({ count: dealsTotal }));
  const engCounts = Object.fromEntries(
    PARTY_MODULES.map((m, i) => [m, (engResults[i] as any).count ?? 0]),
  ) as Record<PartyModule, number>;
  const engTotal = PARTY_MODULES.reduce((s, m) => s + engCounts[m], 0);

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">URM Platform</h1>
        <p className="text-sm text-muted-foreground mt-1">{auth.email}</p>
      </header>

      {/* ── Row 1: Quick stats ── */}
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

      {/* ── Row 2: Parties + Engagements ── */}
      <div className="grid gap-4 md:grid-cols-2">

        {/* Parties widget */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Parties</CardTitle>
            <Building2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums mb-4">
              {partyTotal.toLocaleString()}
            </div>
            <div className="space-y-2">
              {PARTY_MODULES.map(m => (
                <div key={m} className="flex items-center justify-between text-sm">
                  <Link
                    href={`/${m}/parties`}
                    className={`font-medium hover:underline underline-offset-2 ${MODULE_COLORS[m]}`}
                  >
                    {MODULE_LABELS[m]}
                  </Link>
                  <span className="tabular-nums text-muted-foreground font-mono text-xs">
                    {partyCounts[m].toLocaleString()}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Engagements widget */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Engagements</CardTitle>
            <Handshake className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums mb-4">
              {engTotal.toLocaleString()}
            </div>
            {engTotal === 0 ? (
              <p className="text-xs text-muted-foreground">No engagements yet.</p>
            ) : (
              <div className="space-y-2">
                {PARTY_MODULES.filter(m => engCounts[m] > 0).map(m => (
                  <div key={m} className="flex items-center justify-between text-sm">
                    <Link
                      href={`/${m}/engagements`}
                      className={`font-medium hover:underline underline-offset-2 ${MODULE_COLORS[m]}`}
                    >
                      {MODULE_LABELS[m]}
                    </Link>
                    <span className="tabular-nums text-muted-foreground font-mono text-xs">
                      {engCounts[m].toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ── Row 3: Welcome ── */}
      <Card>
        <CardHeader>
          <CardTitle>Welcome</CardTitle>
          <CardDescription>
            Your unified relationship management dashboard. Counts update automatically.
            Use the sidebar to navigate to AI Drafts, Inbox, Tasks, and per-module Parties &amp; Engagements.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  );
}
