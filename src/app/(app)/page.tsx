/**
 * app/(app)/page.tsx
 *
 * Unified dashboard.
 * Row 1: Quick stats (AI Drafts, Inbox, To-Do) -- each card links to its screen.
 * Row 2: Parties overview (per-type, linked) + Deals/Engagements overview.
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
};

const MODULE_COLORS: Record<string, string> = {
  paper_mill:      'text-blue-600 dark:text-blue-400',
  filler_supplier: 'text-emerald-600 dark:text-emerald-400',
  investor:        'text-purple-600 dark:text-purple-400',
  partner:         'text-orange-600 dark:text-orange-400',
};

// Customers intentionally omitted (party_type 5 has no data / not used here).
const PARTY_TYPES = ['paper_mill', 'filler_supplier', 'investor', 'partner'] as const;
type PartyTypeCode = typeof PARTY_TYPES[number];

// app.party_types lookup ids (1-8). Counts join on party_type_id, NOT a code string.
const PARTY_TYPE_IDS: Record<PartyTypeCode, number> = {
  investor:        1,
  paper_mill:      2,
  filler_supplier: 3,
  partner:         6,
};

export default async function DashboardPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  // Row 1: quick stats --------------------------------------------------------
  const [draftsRes, inboxRes, todoRes] = await Promise.all([
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
    // To-Do card links to /todo -> count the To-Do engine (todo_items),
    // NOT the deal-scoped app.tasks table.
    supabase
      .schema('app')
      .from('todo_items' as never)
      .select('id', { count: 'exact', head: true })
      .neq('status' as never, 'done')
      .is('archived_at' as never, null),
  ]);
  const draftsCount = (draftsRes as any).count ?? 0;
  const inboxCount  = (inboxRes  as any).count ?? 0;
  const todoCount   = (todoRes   as any).count ?? 0;

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

  // Row 2b: deals with per-deal task + engagement counts ----------------------
  // PostgREST embedded counts via FK: tasks.deal_id and engagements.deal_id.
  const dealsRes = await supabase
    .schema('app')
    .from('deals' as never)
    .select('id, deal_name, tasks(count), engagements(count)')
    .is('deleted_at' as never, null)
    .order('created_at' as never, { ascending: false });
  type DealRow = {
    id: string;
    deal_name: string | null;
    tasks: { count: number }[] | null;
    engagements: { count: number }[] | null;
  };
  const dealRows = (((dealsRes as any).data ?? []) as DealRow[]).map(d => ({
    id: d.id,
    name: d.deal_name ?? '(untitled deal)',
    taskCount: d.tasks?.[0]?.count ?? 0,
    engCount: d.engagements?.[0]?.count ?? 0,
  }));
  const dealsTotal = dealRows.length;
  const taskTotal  = dealRows.reduce((s, d) => s + d.taskCount, 0);
  const engTotal   = dealRows.reduce((s, d) => s + d.engCount, 0);

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">URM (Marinebio Group)</h1>
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
              <CardTitle className="text-sm font-medium">To-Do</CardTitle>
              <CheckSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold tabular-nums">{todoCount}</div>
              <CardDescription className="mt-1">Open</CardDescription>
            </CardContent>
          </Card>
        </Link>
      </div>

      {/* Row 2: Parties + Deals/Engagements */}
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

        {/* Deals / Engagements widget */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Deals &amp; Engagements</CardTitle>
            <Handshake className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="flex items-baseline gap-2 mb-1">
              <span className="text-2xl font-bold tabular-nums">{dealsTotal.toLocaleString()}</span>
              <span className="text-sm text-muted-foreground">deals</span>
            </div>
            <p className="text-xs text-muted-foreground mb-4">
              {engTotal.toLocaleString()} engagements &middot; {taskTotal.toLocaleString()} tasks
            </p>
            {dealsTotal === 0 ? (
              <p className="text-xs text-muted-foreground">No deals yet.</p>
            ) : (
              <div className="space-y-2">
                {dealRows.slice(0, 6).map(d => (
                  <div key={d.id} className="flex items-center justify-between text-sm gap-2">
                    <span className="font-medium truncate">{d.name}</span>
                    <span className="tabular-nums text-muted-foreground font-mono text-xs shrink-0">
                      {d.taskCount} tasks &middot; {d.engCount} eng
                    </span>
                  </div>
                ))}
                {dealsTotal > 6 && (
                  <p className="text-xs text-muted-foreground pt-1">
                    +{(dealsTotal - 6).toLocaleString()} more
                  </p>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Row 3: Welcome */}
      <Card>
        <CardHeader>
          <CardTitle>Welcome to Marinebio Group</CardTitle>
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
