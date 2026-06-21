// src/app/(app)/reports/page.tsx
//
// Reports / analytics for cycle-time (duration) analysis. v1 metrics, scoped
// to one pipeline (chosen via ?pipeline=<code>, default = first active):
//   1) Average time-in-stage  -- from app.deal_stage_history (completed visits)
//   2) Deals by current stage -- distribution across the pipeline
//   3) Task summary           -- total / done / overdue + avg planned duration
//
// Server component; no chart lib (plain CSS bars). Lives in (app) so it
// inherits the sidebar/topbar layout.

import Link from 'next/link';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

const DAY_MS = 86_400_000;

function fmtDays(days: number | null): string {
  if (days == null) return '—';
  if (days < 1) return Math.max(1, Math.round(days * 24)) + 'h';
  return days.toFixed(1) + 'd';
}

function Bar({ pct, tone = 'foreground' }: { pct: number; tone?: 'foreground' | 'emerald' }) {
  const w = Math.max(0, Math.min(100, pct));
  const cls = tone === 'emerald' ? 'bg-emerald-500' : 'bg-foreground/70';
  return (
    <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
      <div className={'h-full rounded-full ' + cls} style={{ width: w + '%' }} />
    </div>
  );
}

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: { pipeline?: string };
}) {
  const supabase = await createSupabaseServerClient();

  const { data: pl } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name, sort_order')
    .eq('is_active', true)
    .neq('code', 'default')
    .order('sort_order', { ascending: true });
  const pipelines = (pl ?? []) as Array<{
    id: string;
    code: string;
    name: string;
    sort_order: number;
  }>;

  if (pipelines.length === 0) {
    return (
      <div className="p-6 text-sm text-muted-foreground">No active pipelines yet.</div>
    );
  }

  const selected =
    pipelines.find((p) => p.code === searchParams.pipeline) ?? pipelines[0]!;

  // Stages + deals of the selected pipeline.
  const [{ data: st }, { data: dl }] = await Promise.all([
    supabase
      .schema('app')
      .from('stages' as never)
      .select('id, name, sort_order')
      .eq('pipeline_id', selected.id)
      .order('sort_order', { ascending: true }),
    supabase
      .schema('app')
      .from('deals' as never)
      .select('id, current_stage_id')
      .eq('pipeline_id', selected.id)
      .is('deleted_at', null),
  ]);
  const stages = (st ?? []) as Array<{ id: string; name: string; sort_order: number }>;
  const deals = (dl ?? []) as Array<{ id: string; current_stage_id: string | null }>;
  const dealIds = deals.map((d) => d.id);

  // Deals by current stage.
  const dealsPerStage = new Map<string, number>();
  for (const d of deals) {
    if (d.current_stage_id) {
      dealsPerStage.set(d.current_stage_id, (dealsPerStage.get(d.current_stage_id) ?? 0) + 1);
    }
  }

  // Average time-in-stage from stage history (completed visits only).
  const stageDur = new Map<string, { sum: number; n: number }>();
  if (dealIds.length > 0) {
    const { data: hist } = await supabase
      .schema('app')
      .from('deal_stage_history' as never)
      .select('deal_id, to_stage_id, changed_at')
      .in('deal_id', dealIds)
      .order('changed_at', { ascending: true });
    const rows = (hist ?? []) as Array<{
      deal_id: string;
      to_stage_id: string | null;
      changed_at: string;
    }>;
    const byDeal = new Map<string, Array<{ to: string | null; at: number }>>();
    for (const r of rows) {
      if (!byDeal.has(r.deal_id)) byDeal.set(r.deal_id, []);
      byDeal.get(r.deal_id)!.push({ to: r.to_stage_id, at: new Date(r.changed_at).getTime() });
    }
    for (const [, seq] of byDeal) {
      for (let i = 0; i < seq.length - 1; i++) {
        const cur = seq[i];
        const nxt = seq[i + 1];
        if (!cur || !nxt || !cur.to) continue;
        const dur = nxt.at - cur.at;
        if (dur <= 0) continue;
        const acc = stageDur.get(cur.to) ?? { sum: 0, n: 0 };
        acc.sum += dur;
        acc.n += 1;
        stageDur.set(cur.to, acc);
      }
    }
  }

  // Task summary.
  let taskTotal = 0;
  let taskDone = 0;
  let taskOverdue = 0;
  let plannedSum = 0;
  let plannedN = 0;
  if (dealIds.length > 0) {
    const { data: tk } = await supabase
      .schema('app')
      .from('tasks' as never)
      .select('status, start_at, due_at')
      .in('deal_id', dealIds)
      .is('deleted_at', null);
    const tasks = (tk ?? []) as Array<{
      status: string | null;
      start_at: string | null;
      due_at: string | null;
    }>;
    const now = Date.now();
    for (const t of tasks) {
      taskTotal += 1;
      const done = t.status === 'completed' || t.status === 'done';
      if (done) taskDone += 1;
      if (!done && t.due_at && new Date(t.due_at).getTime() < now) taskOverdue += 1;
      if (t.start_at && t.due_at) {
        const d = new Date(t.due_at).getTime() - new Date(t.start_at).getTime();
        if (d >= 0) {
          plannedSum += d;
          plannedN += 1;
        }
      }
    }
  }
  const avgPlannedDays = plannedN > 0 ? plannedSum / plannedN / DAY_MS : null;

  // Display rows.
  const stageRows = stages.map((s) => {
    const acc = stageDur.get(s.id);
    const avgDays = acc && acc.n > 0 ? acc.sum / acc.n / DAY_MS : null;
    return {
      id: s.id,
      name: s.name,
      avgDays,
      visits: acc?.n ?? 0,
      deals: dealsPerStage.get(s.id) ?? 0,
    };
  });
  const maxAvg = Math.max(1, ...stageRows.map((r) => r.avgDays ?? 0));
  const maxDeals = Math.max(1, ...stageRows.map((r) => r.deals));

  return (
    <div className="mx-auto max-w-app p-6">
      <div className="mb-1 flex items-baseline justify-between">
        <h1 className="text-xl font-semibold text-foreground">Reports</h1>
        <span className="text-xs text-muted-foreground">Cycle-time analysis</span>
      </div>
      <p className="mb-4 text-sm text-muted-foreground">
        How long deals spend in each stage, and the task workload behind them.
      </p>

      {/* Pipeline selector */}
      <div className="mb-6 flex flex-wrap gap-2">
        {pipelines.map((p) => {
          const active = p.id === selected.id;
          return (
            <Link
              key={p.id}
              href={'/reports?pipeline=' + p.code}
              className={
                'rounded-full border px-3 py-1 text-xs font-medium transition ' +
                (active
                  ? 'border-foreground bg-foreground text-background'
                  : 'border-border bg-background text-foreground hover:bg-muted')
              }
            >
              {p.name}
            </Link>
          );
        })}
      </div>

      {/* Average time-in-stage */}
      <section className="mb-6 rounded-lg border bg-card p-4">
        <div className="mb-3 flex items-baseline justify-between">
          <h2 className="text-sm font-semibold text-foreground">Average time in stage</h2>
          <span className="text-xs text-muted-foreground">completed visits only</span>
        </div>
        {stageRows.length === 0 ? (
          <div className="text-sm text-muted-foreground">No stages.</div>
        ) : (
          <div className="space-y-3">
            {stageRows.map((r) => (
              <div key={r.id}>
                <div className="mb-1 flex items-center justify-between text-xs">
                  <span className="font-medium text-foreground">{r.name}</span>
                  <span className="tabular-nums text-muted-foreground">
                    {fmtDays(r.avgDays)}
                    {r.visits > 0 ? ' · ' + r.visits + ' moves' : ''}
                  </span>
                </div>
                <Bar pct={r.avgDays != null ? (r.avgDays / maxAvg) * 100 : 0} />
              </div>
            ))}
          </div>
        )}
        <p className="mt-3 text-[11px] text-muted-foreground/70">
          Measured from stage-change history. Deals still sitting in their current stage
          aren&apos;t counted until they move on.
        </p>
      </section>

      {/* Deals by stage */}
      <section className="mb-6 rounded-lg border bg-card p-4">
        <h2 className="mb-3 text-sm font-semibold text-foreground">
          Deals by stage{' '}
          <span className="font-normal text-muted-foreground">({deals.length} total)</span>
        </h2>
        <div className="space-y-3">
          {stageRows.map((r) => (
            <div key={r.id}>
              <div className="mb-1 flex items-center justify-between text-xs">
                <span className="font-medium text-foreground">{r.name}</span>
                <span className="tabular-nums text-muted-foreground">{r.deals}</span>
              </div>
              <Bar pct={(r.deals / maxDeals) * 100} tone="emerald" />
            </div>
          ))}
        </div>
      </section>

      {/* Task summary */}
      <section className="rounded-lg border bg-card p-4">
        <h2 className="mb-3 text-sm font-semibold text-foreground">Tasks</h2>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            { label: 'Total', value: String(taskTotal) },
            { label: 'Completed', value: String(taskDone) },
            { label: 'Overdue', value: String(taskOverdue) },
            { label: 'Avg planned', value: fmtDays(avgPlannedDays) },
          ].map((c) => (
            <div key={c.label} className="rounded-md border bg-background p-3">
              <div className="text-lg font-semibold tabular-nums text-foreground">{c.value}</div>
              <div className="text-xs text-muted-foreground">{c.label}</div>
            </div>
          ))}
        </div>
        <p className="mt-3 text-[11px] text-muted-foreground/70">
          Avg planned = average of (due date − start date) across tasks that have both.
        </p>
      </section>
    </div>
  );
}
