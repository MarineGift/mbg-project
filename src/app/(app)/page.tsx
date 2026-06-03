/**
 * app/(app)/page.tsx
 *
 * Unified dashboard.
 * Row 1: Quick stats (AI Drafts, Inbox, Tasks) -- each card links to its screen.
 * Row 2: Parties overview (per-type, linked) + Engagements overview.
 * Row 3: Welcome card.
 */
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Sparkles, Inbox, CheckSquare, Building2, Handshake } from 'lucide-react';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

const PARTY_TYPE_LABELS: Record<string, string> = {
  paper_mill:      'Paper Mills',
  filler_supplier: 'Filler Suppliers',
  investor:        'Investors',
  partner:         'Partners',
  customer:        'Customers',
};

const MODULE_COLORS: Record<string, string> = {
  paper_mill:      'text-blue-600 dark:text-blue-400',
  filler_supplier: 'text-emerald-600 dark:text-emerald-400',
  investor:        'text-purple-600 dark:text-purple-400',
  partner:         'text-orange-600 dark:text-orange-400',
  customer:        'text-rose-600 dark:text-rose-400',
};

const PARTY_TYPES = ['paper_mill', 'filler_supplier', 'investor', 'partner', 'customer'] as const;
type PartyTypeCode = typeof PARTY_TYPES[number];

// app.party_types lookup ids (1-8). Counts join on party_type_id, NOT a code string.
const PARTY_TYPE_IDS: Record<PartyTypeCode, number> = {
  investor:        1,
  paper_mill:      2,
  filler_supplier: 3,
  partner:         6,
  customer:        5,
};

export default async function DashboardPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  // Row 1: quick stats --------------------------------------------------------
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
    // Tasks card links to /todo, so count the To-Do engine (task_items), not
    // the legacy deal-scoped app.tasks table.
    supabase
      .schema('app')
      .from('task_items' as never)
      .select('id', { count: 'exact', head: true })
      .neq('status' as never, 'done')
      .is('archived_at' as never, null),
  ]);
  const draftsCount = (draftsRes as any).count ?? 0;
  const inboxCount  = (inboxRes  as any).count ?? 0;
  const tasksCount  = (tasksRes  as any).count ?? 0;

  // Row 2a: parties by type (count on party_type_id) --------------------------
  const partyResults = await Promise.all(
    PARTY_TYPES.map(m =>
      supabase
        .schema('app')
        .from('parties' as never)
        .select('id', { count: 'exact', head: true })
        .eq('party_type_id' as never, PARTY_TYPE_IDS[m])
        .is('deleted_at' as never, null),
    ),
  );
  const partyCounts = Object.fromEntries(
    PARTY_TYPES.map((m, i) => [m, (partyResults[i] as any).count ?? 0]),
  ) as Record<PartyTypeCode, number>;
  const partyTotal = PARTY_TYPES.reduce((s, m) => s + partyCounts[m], 0);

  // Row 2b: engagements (deals total) -----------------------------------------
  const dealsTotalRes = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id', { count: 'exact', head: true })
    .is('deleted_at' as never, null);
  const dealsTotal = (dealsTotalRes as { count: number | null }).count ?? 0;
  const engResults = PARTY_TYPES.map(() => ({ count: dealsTotal }));
  const engCounts = Object.fromEntries(
    PARTY_TYPES.map((m, i) => [m, (engResults[i] as any).count ?? 0]),
  ) as Record<PartyTypeCode, number>;
  const engTotal = PARTY_TYPES.reduce((s, m) => s + engCounts[m], 0);

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">URM Platform</h1>
        <p className="text-sm text-muted-foreground mt-1">{auth.email}</p>
      </header>

      {/* Row 1: Quick stats (clickable) */}
      <div className="grid gap-4 md:grid-cols-3">
        <Link href="/drafts" className="block rounded-xl transition-colors hover:bg-muted/40">
          <Card className="h-full">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">AI Drafts</CardTitle>
              <Sparkles className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold tabular-nums">{draftsCount}</div>
              <CardDescription className="mt-1">Pending review</CardDescription>
            </CardContent>
          </Card>
        </Link>
        <Link href="/inbox" className="block rounded-xl transition-colors hover:bg-muted/40">
          <Card className="h-full">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Inbox</CardTitle>
              <Inbox className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold tabular-nums">{inboxCount}</div>
              <CardDescription className="mt-1">Unread inbound</CardDescription>
            </CardContent>
          </Card>
        </Link>
        <Link href="/todo" className="block rounded-xl transition-colors hover:bg-muted/40">
          <Card className="h-full">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Tasks</CardTitle>
              <CheckSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold tabular-nums">{tasksCount}</div>
              <CardDescription className="mt-1">Open</CardDescription>
            </CardContent>
          </Card>
        </Link>
      </div>

      {/* Row 2: Parties + Engagements */}
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
              {PARTY_TYPES.map(m => (
                <div key={m} className="flex items-center justify-between text-sm">
                  <Link
                    href={`/${m}/parties`}
                    className={`font-medium hover:underline underline-offset-2 ${MODULE_COLORS[m]}`}
                  >
                    {PARTY_TYPE_LABELS[m]}
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
                {PARTY_TYPES.filter(m => engCounts[m] > 0).map(m => (
                  <div key={m} className="flex items-center justify-between text-sm">
                    <span className={`font-medium ${MODULE_COLORS[m]}`}>{PARTY_TYPE_LABELS[m]}</span>
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

      {/* Row 3: Welcome */}
      <Card>
        <CardHeader>
          <CardTitle>Welcome to URM Platform</CardTitle>
          <CardDescription>
            Marinebio Group&apos;s unified relationship management for the paper &amp;
            filler-mineral industry. Track investor outreach, run deal pipelines across
            investors, paper mills, and filler suppliers, and nurture partner relationships
            &mdash; all in one place. Counts update automatically; use the sidebar or the
            cards above to navigate.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  );
}
