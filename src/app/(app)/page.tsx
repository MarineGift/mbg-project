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
import { Inbox, CheckSquare, Building2, Handshake } from 'lucide-react';
import { requireAuthOrRedirect } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

// Optional display overrides by party-type code. Falls back to the DB
// display_name_en when a code isn't listed here, so new types appear with their
// own label automatically.
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
const FALLBACK_PARTY_COLOR = 'text-foreground';

export default async function DashboardPage() {
  const auth = await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  // Row 1: quick stats --------------------------------------------------------
  const [draftsRes, inboxRes, inboundRes, outboundRes] = await Promise.all([
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
      .from('communications' as never)
      .select('id', { count: 'exact', head: true })
      .eq('direction', 'inbound'),
    supabase
      .schema('app')
      .from('communications' as never)
      .select('id', { count: 'exact', head: true })
      .eq('direction', 'outbound'),
  ]);
  const draftsCount   = (draftsRes   as any).count ?? 0;
  const inboxCount    = (inboxRes    as any).count ?? 0;
  const inboundCount  = (inboundRes  as any).count ?? 0;
  const outboundCount = (outboundRes as any).count ?? 0;

  // To-Do per-status breakdown (Backlog / To Do / In Progress / Review / Done).
  // Mirrors the /todo board: pick the kind='todo' board (else the first), read
  // its status options (label/color/order) and count its items per status.
  type TodoStage = { key: string; label: string; color: string | null; count: number };
  let todoStages: TodoStage[] = [];
  {
    const { data: boardsData } = await supabase
      .schema('app')
      .from('todo_boards' as never)
      .select('id, kind, position')
      .order('position', { ascending: true });
    const boards = (boardsData ?? []) as Array<{ id: string; kind: string; position: number }>;
    const board = boards.find((b) => b.kind === 'todo') ?? boards[0];
    if (board) {
      const [optsRes, itemsRes] = await Promise.all([
        supabase
          .schema('app')
          .from('todo_status_options' as never)
          .select('key, label, color, position')
          .eq('board_id', board.id)
          .order('position', { ascending: true }),
        supabase
          .schema('app')
          .from('todo_items' as never)
          .select('status')
          .eq('board_id', board.id)
          .is('archived_at', null),
      ]);
      const opts = (optsRes.data ?? []) as Array<{ key: string; label: string; color: string | null; position: number }>;
      const items = (itemsRes.data ?? []) as Array<{ status: string }>;
      const counts = new Map<string, number>();
      for (const it of items) counts.set(it.status, (counts.get(it.status) ?? 0) + 1);
      todoStages = opts.map((o) => ({
        key: o.key,
        label: o.label,
        color: o.color,
        count: counts.get(o.key) ?? 0,
      }));
    }
  }
  const todoTotal = todoStages.reduce((s, st) => s + st.count, 0);

  // Row 2a: parties by type (dynamic from app.party_types) --------------------
  const [partyTypesRes, partyRowsRes] = await Promise.all([
    supabase
      .schema('app')
      .from('party_types' as never)
      .select('id, code, display_name_en, sort_order')
      .order('sort_order', { ascending: true }),
    supabase
      .schema('app')
      .from('parties' as never)
      .select('party_type_id')
      .is('deleted_at' as never, null),
  ]);
  type PartyTypeRow = { id: number; code: string; display_name_en: string | null; sort_order: number };
  const partyTypeRows = ((partyTypesRes as any).data ?? []) as PartyTypeRow[];
  const partyTypeIds = (((partyRowsRes as any).data ?? []) as Array<{ party_type_id: number | null }>);
  const partyCountByType = new Map<number, number>();
  for (const r of partyTypeIds) {
    if (r.party_type_id == null) continue;
    partyCountByType.set(r.party_type_id, (partyCountByType.get(r.party_type_id) ?? 0) + 1);
  }
  // Build display stats; hide the technical 'default' type and zero-count types
  // are kept so the list stays meaningful but not noisy.
  type PartyStat = { code: string; label: string; color: string; count: number };
  const partyStats: PartyStat[] = partyTypeRows
    .filter((t) => t.code !== 'default')
    .map((t) => ({
      code: t.code,
      label: PARTY_TYPE_LABELS[t.code] ?? t.display_name_en ?? t.code,
      color: MODULE_COLORS[t.code] ?? FALLBACK_PARTY_COLOR,
      count: partyCountByType.get(t.id) ?? 0,
    }));
  const partyTotal = partyStats.reduce((s, p) => s + p.count, 0);

  // Row 2b: deals grouped per pipeline, each with deal / task / engagement totals.
  // PostgREST embedded counts via FK: tasks.deal_id and engagements.deal_id.
  // Pipelines come from app.pipelines (dynamic; excludes the 'default' fallback).
  const [pipelinesRes, dealsRes] = await Promise.all([
    supabase
      .schema('app')
      .from('pipelines' as never)
      .select('id, code, name, sort_order')
      .eq('is_active', true)
      .neq('code', 'default')
      .order('sort_order', { ascending: true }),
    supabase
      .schema('app')
      .from('deals' as never)
      .select('id, pipeline_id, tasks(count), engagements(count)')
      .is('deleted_at' as never, null),
  ]);
  type PipelineRow = { id: string; code: string; name: string; sort_order: number };
  type DealRow = {
    id: string;
    pipeline_id: string | null;
    tasks: { count: number }[] | null;
    engagements: { count: number }[] | null;
  };
  const pipelineRows = ((pipelinesRes as any).data ?? []) as PipelineRow[];
  const dealRows = (((dealsRes as any).data ?? []) as DealRow[]).map(d => ({
    pipelineId: d.pipeline_id,
    taskCount: d.tasks?.[0]?.count ?? 0,
    engCount: d.engagements?.[0]?.count ?? 0,
  }));
  const dealsTotal = dealRows.length;
  const taskTotal  = dealRows.reduce((s, d) => s + d.taskCount, 0);
  const engTotal   = dealRows.reduce((s, d) => s + d.engCount, 0);

  // Per-pipeline aggregation (deal / task / engagement counts).
  type PipelineStat = { id: string; name: string; deals: number; tasks: number; engagements: number };
  const pipelineStats: PipelineStat[] = pipelineRows.map((p) => {
    const rows = dealRows.filter((d) => d.pipelineId === p.id);
    return {
      id: p.id,
      name: p.name,
      deals: rows.length,
      tasks: rows.reduce((s, d) => s + d.taskCount, 0),
      engagements: rows.reduce((s, d) => s + d.engCount, 0),
    };
  });

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">URM (Marinebio Group)</h1>
        <p className="text-sm text-muted-foreground mt-1">{auth.email}</p>
      </header>

      {/* Row 1: Quick stats (clickable) */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card className="h-full">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <Link href="/inbox" className="hover:underline underline-offset-2">
              <CardTitle className="text-sm font-medium">Inbox</CardTitle>
            </Link>
            <Inbox className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold tabular-nums mb-4">{inboxCount.toLocaleString()}</div>
            <div className="space-y-2 text-sm">
              <div className="flex items-center justify-between">
                <Link href="/inbox?direction=inbound" className="font-medium hover:underline underline-offset-2">
                  Inbound
                </Link>
                <span className="tabular-nums text-muted-foreground font-mono text-xs">
                  {inboundCount.toLocaleString()}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <Link href="/inbox?direction=outbound" className="font-medium hover:underline underline-offset-2">
                  Outbound
                </Link>
                <span className="tabular-nums text-muted-foreground font-mono text-xs">
                  {outboundCount.toLocaleString()}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <Link href="/inbox?hasDraft=1" className="font-medium hover:underline underline-offset-2">
                  AI Drafts
                </Link>
                <span className="tabular-nums text-muted-foreground font-mono text-xs">
                  {draftsCount.toLocaleString()}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
        <Link href="/todo" className="block rounded-xl transition-colors hover:bg-muted/40">
          <Card className="h-full">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">To-Do</CardTitle>
              <CheckSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold tabular-nums mb-4">{todoTotal.toLocaleString()}</div>
              {todoStages.length === 0 ? (
                <CardDescription>No board found.</CardDescription>
              ) : (
                <div className="space-y-2">
                  {todoStages.map((st) => (
                    <div key={st.key} className="flex items-center justify-between text-sm">
                      <span className="flex items-center gap-2 font-medium">
                        <span
                          className="h-2.5 w-2.5 rounded-full shrink-0"
                          style={{ background: st.color ?? '#94a3b8' }}
                          aria-hidden
                        />
                        {st.label}
                      </span>
                      <span className="tabular-nums text-muted-foreground font-mono text-xs">
                        {st.count.toLocaleString()}
                      </span>
                    </div>
                  ))}
                </div>
              )}
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
              {partyStats.map((p) => (
                <div key={p.code} className="flex items-center justify-between text-sm">
                  <Link
                    href={`/${p.code}/parties`}
                    className={`font-medium hover:underline underline-offset-2 ${p.color}`}
                  >
                    {p.label}
                  </Link>
                  <span className="tabular-nums text-muted-foreground font-mono text-xs">
                    {p.count.toLocaleString()}
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
            {pipelineStats.length === 0 ? (
              <p className="text-xs text-muted-foreground">No pipelines.</p>
            ) : (
              <div className="space-y-2">
                {/* Header: Deal / Task / Engagement */}
                <div className="flex items-center justify-between text-[11px] uppercase tracking-wider text-muted-foreground">
                  <span>Pipeline</span>
                  <span className="font-mono">Deal / Task / Eng</span>
                </div>
                {pipelineStats.map((p) => (
                  <div key={p.id} className="flex items-center justify-between text-sm gap-2">
                    <span className="font-medium truncate">{p.name}</span>
                    <span className="tabular-nums text-muted-foreground font-mono text-xs shrink-0">
                      {p.deals} / {p.tasks} / {p.engagements}
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
