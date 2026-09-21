// src/app/(app)/ipo/page.tsx
//
// Nasdaq IPO readiness module. Reads app.ipo_* + views (security_invoker,
// org-scoped via JWT). Tabs via ?tab=overview|gantt|gates|metrics.
//
// Design rules mirrored from the DB:
//   - numbers are entered ONLY through ipo_metric_snapshots (SnapshotForm)
//   - gate verdicts are human; linked milestone progress is a hint
//   - listing criteria (nasdaq/sec) and internal KPIs are shown separately

import Link from 'next/link';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { IpoGantt, type GanttRow, type Workstream, type Dep } from './ipo-gantt';
import { GatePanel, type GateRow } from './gate-panel';
import { SnapshotForm, DecisionForm, type MetricOpt } from './snapshot-panel';
import { PatentsPanel, type PatentRow, type Horizon } from './patents-panel';

export const dynamic = 'force-dynamic';

type Dash = {
  program_id: string; name: string; window_start: string; window_end: string; build_to_quarter: string;
  level_verdicts: Record<string, string> | null; listing_unmeasured: number; listing_failing: number; kpi_failing: number;
  milestone_gates_open: number; milestones_overdue: number; patent_min_remaining_years: number | null;
  patents_unrecorded: number | null; royalty_periods_not_clean: number; latest_decision: string | null;
};
type Tab = 'overview' | 'gantt' | 'gates' | 'metrics' | 'patents';
const TABS: Array<[Tab, string]> = [['overview', 'Overview'], ['gantt', 'Timeline'], ['gates', 'Readiness Gates'], ['metrics', 'Criteria & KPIs'], ['patents', 'Patents']];

function quarterRange(q: string): { start: string; end: string } {
  const y = Number(q.slice(0, 4)); const n = Number(q.slice(5));
  const m0 = (n - 1) * 3; const endM = m0 + 3;
  const end = new Date(y, endM, 0);
  return { start: `${y}-${String(m0 + 1).padStart(2, '0')}-01`, end: `${y}-${String(endM).padStart(2, '0')}-${String(end.getDate()).padStart(2, '0')}` };
}
function fmt(v: number | null | undefined, unit?: string) {
  if (v == null) return '—';
  if (unit === 'usd') return '$' + Number(v).toLocaleString();
  if (unit === 'pct') return Number(v) + '%';
  return Number(v).toLocaleString();
}
const VERDICT_CLS: Record<string, string> = {
  go: 'bg-emerald-100 text-emerald-800', at_risk: 'bg-amber-100 text-amber-800',
  incomplete: 'bg-muted text-muted-foreground', no_go: 'bg-red-100 text-red-800',
};

export default async function IpoPage({ searchParams }: { searchParams: { tab?: string } }) {
  const tab: Tab = (['overview', 'gantt', 'gates', 'metrics', 'patents'] as const).includes(searchParams.tab as Tab) ? (searchParams.tab as Tab) : 'overview';
  const sb = await createSupabaseServerClient();
  const app = sb.schema('app');

  const { data: dashRaw } = await app.from('v_ipo_dashboard' as never).select('*').limit(1).maybeSingle();
  const dash = dashRaw as Dash | null;

  if (!dash) {
    return (
      <div className="p-6 text-sm text-muted-foreground">
        No IPO program found. Run <code>seed_ipo_module.sql</code> first.
      </div>
    );
  }
  const pid = dash.program_id;

  const [{ data: prog }, { data: gantt }, { data: ms }, { data: depsRaw }, { data: wsRaw }] = await Promise.all([
    app.from('ipo_programs' as never).select('program_start').eq('id', pid).maybeSingle(),
    app.from('v_ipo_gantt' as never).select('*').eq('program_id', pid).order('ord'),
    app.from('ipo_milestones' as never).select('id, code, status').eq('program_id', pid),
    app.from('ipo_milestone_deps' as never).select('milestone_id, depends_on_milestone_id'),
    app.from('ipo_workstreams' as never).select('code, name, color_hex').order('sort_order'),
  ]);
  const milestones = (ms ?? []) as Array<{ id: string; code: string; status: string }>;
  const idToCode = new Map(milestones.map((m) => [m.id, m.code]));
  const codeToId = new Map(milestones.map((m) => [m.code, m.id]));
  const rows: GanttRow[] = ((gantt ?? []) as GanttRow[]).map((r) => ({ ...r, milestone_id: r.row_type === 'milestone' ? codeToId.get(r.code) ?? null : null }));
  const deps: Dep[] = ((depsRaw ?? []) as Array<{ milestone_id: string; depends_on_milestone_id: string }>)
    .map((d) => ({ milestone_code: idToCode.get(d.milestone_id) ?? '', depends_on_code: idToCode.get(d.depends_on_milestone_id) ?? '' }))
    .filter((d) => d.milestone_code && d.depends_on_code);
  const workstreams = (wsRaw ?? []) as Workstream[];
  const programStart = (prog as { program_start: string } | null)?.program_start ?? '2026-09-01';
  const programEnd = quarterRange(dash.window_end).end;
  const today = new Date().toISOString().slice(0, 10);
  const windows = [
    { name: `Accelerated — ${dash.window_start}`, tone: 'red' as const, ...quarterRange(dash.window_start) },
    { name: `Base — ${dash.window_end}`, tone: 'blue' as const, ...quarterRange(dash.window_end) },
  ];

  return (
    <div className="flex flex-col gap-4 p-6">
      <header className="flex flex-wrap items-baseline gap-x-6 gap-y-1">
        <h1 className="text-lg font-semibold">{dash.name}</h1>
        <span className="text-sm text-muted-foreground">Build-to <b className="text-foreground">{dash.build_to_quarter}</b></span>
        <span className="text-sm text-muted-foreground">IPO window <b className="text-foreground">{dash.window_start} – {dash.window_end}</b></span>
        {dash.latest_decision && <span className="text-sm text-muted-foreground">Latest decision <b className="text-foreground">{dash.latest_decision}</b></span>}
      </header>

      <nav className="flex gap-1 border-b text-sm">
        {TABS.map(([t, l]) => (
          <Link key={t} href={`/ipo?tab=${t}`} className={'-mb-px border-b-2 px-3 py-2 ' + (tab === t ? 'border-foreground font-medium' : 'border-transparent text-muted-foreground hover:text-foreground')}>{l}</Link>
        ))}
      </nav>

      {tab === 'overview' && (await Overview({ dash, pid }))}
      {tab === 'gantt' && (
        <IpoGantt rows={rows} workstreams={workstreams} deps={deps} programStart={programStart} programEnd={programEnd} today={today} windows={windows} />
      )}
      {tab === 'gates' && (await Gates({ pid, milestones }))}
      {tab === 'metrics' && (await Metrics({ pid }))}
      {tab === 'patents' && (await Patents({ pid }))}
    </div>
  );
}

/* ---------------- Overview ---------------- */
async function Overview({ dash, pid }: { dash: Dash; pid: string }) {
  const sb = await createSupabaseServerClient();
  const app = sb.schema('app');
  const [{ data: ph }, { data: sc }, { data: rv }, { data: gap }] = await Promise.all([
    app.from('v_ipo_phase_progress' as never).select('*').eq('program_id', pid).order('sort_order'),
    app.from('v_ipo_scenario_royalty' as never).select('*').eq('program_id', pid).eq('is_planning_default', true).order('fiscal_year'),
    app.from('ipo_decision_reviews' as never).select('review_date, stage, window_decision, rationale').eq('program_id', pid).order('review_date', { ascending: false }).limit(5),
    app.from('v_royalty_vs_gaap' as never).select('*').eq('program_id', pid).order('fy'),
  ]);
  const phases = (ph ?? []) as Array<{ phase_code: string; phase_name: string; phase_start: string; phase_end: string; total: number; done: number; open_gates: number; overdue: number; pct_done: number | null }>;
  const scen = (sc ?? []) as Array<{ fiscal_year: number; volume_tons_low: number; volume_tons_high: number; derived_royalty_per_ton: number; royalty_usd_low: number; royalty_usd_high: number; actual_tons: number | null; actual_vs_range: string | null }>;
  const reviews = (rv ?? []) as Array<{ review_date: string; stage: string; window_decision: string; rationale: string | null }>;
  const vsGaap = (gap ?? []) as Array<{ fy: number; recognized_revenue_ledger: number | null; gaap_royalty_revenue: number | null; reconciliation_difference: number | null }>;
  const lv = dash.level_verdicts ?? {};
  const LEVELS = ['Legal', 'Audit', 'Commercial', 'IP & Legal', 'Governance', 'Capital'];

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Six-level readiness</h2>
        <div className="grid grid-cols-3 gap-2 sm:grid-cols-6">
          {LEVELS.map((n, i) => {
            const v = lv[String(i + 1)] ?? 'incomplete';
            return <div key={n} className={'rounded p-2 text-center text-xs ' + (VERDICT_CLS[v] ?? '')}><div className="font-medium">L{i + 1}</div><div>{n}</div><div className="mt-1">{v}</div></div>;
          })}
        </div>
        <p className="mt-2 text-xs text-muted-foreground">Any unknown gate makes the level incomplete. Unassessed is more dangerous than failing.</p>
      </section>

      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Numbers to watch</h2>
        <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-sm sm:grid-cols-4">
          <Stat label="Listing criteria unmeasured" v={dash.listing_unmeasured} warn={dash.listing_unmeasured > 0} />
          <Stat label="Listing criteria failing" v={dash.listing_failing} warn={dash.listing_failing > 0} />
          <Stat label="Internal KPIs failing" v={dash.kpi_failing} warn={dash.kpi_failing > 0} />
          <Stat label="Open gate milestones" v={dash.milestone_gates_open} />
          <Stat label="Overdue milestones" v={dash.milestones_overdue} warn={dash.milestones_overdue > 0} />
          <Stat label="Royalty periods not clean" v={dash.royalty_periods_not_clean} warn={dash.royalty_periods_not_clean > 0} />
          <Stat label="Material patent min. life" v={dash.patent_min_remaining_years == null ? '—' : dash.patent_min_remaining_years + ' yrs'} />
          <Stat label="Material patents unrecorded" v={dash.patents_unrecorded ?? '—'} warn={(dash.patents_unrecorded ?? 0) > 0} />
        </dl>
      </section>

      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Phase progress</h2>
        <table className="w-full text-xs">
          <thead className="text-muted-foreground"><tr><th className="text-left">Phase</th><th>Window</th><th>Done</th><th>Gates</th><th>Overdue</th></tr></thead>
          <tbody>
            {phases.map((p) => (
              <tr key={p.phase_code} className="border-t">
                <td className="py-1"><span className="mr-2 text-muted-foreground">{p.phase_code}</span>{p.phase_name}</td>
                <td className="text-center whitespace-nowrap">{p.phase_start.slice(0, 7)} – {p.phase_end.slice(0, 7)}</td>
                <td className="text-center">{p.done}/{p.total}</td>
                <td className="text-center">{p.open_gates}</td>
                <td className={'text-center ' + (p.overdue > 0 ? 'text-red-600' : '')}>{p.overdue}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Conservative scenario vs. actual</h2>
        <table className="w-full text-xs">
          <thead className="text-muted-foreground"><tr><th className="text-left">FY</th><th>Volume (t)</th><th>$/t</th><th>Royalty</th><th>Actual</th></tr></thead>
          <tbody>
            {scen.map((s) => (
              <tr key={s.fiscal_year} className="border-t">
                <td className="py-1">{s.fiscal_year}</td>
                <td className="text-center">{fmt(s.volume_tons_low)}–{fmt(s.volume_tons_high)}</td>
                <td className="text-center">${s.derived_royalty_per_ton}</td>
                <td className="text-center">{fmt(s.royalty_usd_low, 'usd')}–{fmt(s.royalty_usd_high, 'usd')}</td>
                <td className={'text-center ' + (s.actual_vs_range === 'below_low' ? 'text-red-600' : '')}>{s.actual_tons == null ? '—' : `${fmt(s.actual_tons)} (${s.actual_vs_range})`}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="mt-2 text-xs text-muted-foreground">$/t is derived (assumed price × rate), never stored. Management and Global Rollout stay empty until approved.</p>
      </section>

      {vsGaap.length > 0 && (
        <section className="rounded-md border p-4">
          <h2 className="mb-2 text-sm font-semibold">Royalty ledger vs. GAAP</h2>
          <table className="w-full text-xs">
            <thead className="text-muted-foreground"><tr><th className="text-left">FY</th><th>Ledger recognized</th><th>GAAP</th><th>Difference</th></tr></thead>
            <tbody>{vsGaap.map((g) => (
              <tr key={g.fy} className="border-t"><td className="py-1">{g.fy}</td><td className="text-center">{fmt(g.recognized_revenue_ledger, 'usd')}</td><td className="text-center">{fmt(g.gaap_royalty_revenue, 'usd')}</td><td className={'text-center ' + ((g.reconciliation_difference ?? 0) !== 0 ? 'text-amber-700' : '')}>{fmt(g.reconciliation_difference, 'usd')}</td></tr>
            ))}</tbody>
          </table>
        </section>
      )}

      <section className="rounded-md border p-4 lg:col-span-2">
        <h2 className="mb-2 text-sm font-semibold">Decision log</h2>
        {reviews.length === 0 ? <p className="text-xs text-muted-foreground">Nothing yet. One line per quarter.</p> : (
          <ul className="mb-3 text-xs">{reviews.map((r) => <li key={r.review_date + r.stage} className="border-t py-1"><b>{r.review_date}</b> · {r.stage} · {r.window_decision}{r.rationale && <> — {r.rationale}</>}</li>)}</ul>
        )}
        <DecisionForm programId={pid} />
      </section>
    </div>
  );
}

function Stat({ label, v, warn }: { label: string; v: number | string; warn?: boolean }) {
  return <><dt className="text-muted-foreground">{label}</dt><dd className={'font-medium ' + (warn ? 'text-red-600' : '')}>{v}</dd></>;
}

/* ---------------- Gates ---------------- */
async function Gates({ pid, milestones }: { pid: string; milestones: Array<{ id: string; code: string; status: string }> }) {
  const sb = await createSupabaseServerClient();
  const app = sb.schema('app');
  const [{ data: g }, { data: gm }] = await Promise.all([
    app.from('ipo_readiness_gates' as never).select('id, level, code, question, pass_condition, verdict, evidence, assessed_at, is_blocking').eq('program_id', pid).order('sort_order'),
    app.from('ipo_gate_milestones' as never).select('gate_id, milestone_id'),
  ]);
  const doneIds = new Set(milestones.filter((m) => m.status === 'done').map((m) => m.id));
  const links = (gm ?? []) as Array<{ gate_id: string; milestone_id: string }>;
  const gates: GateRow[] = ((g ?? []) as Array<Omit<GateRow, 'linked_done' | 'linked_total'>>).map((x) => {
    const mine = links.filter((l) => l.gate_id === x.id);
    return { ...x, linked_total: mine.length, linked_done: mine.filter((l) => doneIds.has(l.milestone_id)).length };
  });
  return <GatePanel gates={gates} />;
}

/* ---------------- Metrics ---------------- */
async function Metrics({ pid }: { pid: string }) {
  const sb = await createSupabaseServerClient();
  const app = sb.schema('app');
  const [{ data: ls }, { data: ks }, { data: ms }] = await Promise.all([
    app.from('v_ipo_listing_status' as never).select('*').eq('program_id', pid).order('sort_order'),
    app.from('v_ipo_kpi_status' as never).select('*').eq('program_id', pid).order('sort_order'),
    app.from('ipo_metrics' as never).select('id, code, label, unit, requires_verification').eq('program_id', pid).order('sort_order'),
  ]);
  type Row = { code: string; label: string; unit: string; comparator: string; threshold: number; value: number | null; measured_at: string | null; meets: boolean | null; rule_ref?: string; category?: string; is_alternate?: boolean; from_offering_only?: boolean; rationale?: string };
  const listing = (ls ?? []) as Row[];
  const kpis = (ks ?? []) as Row[];
  const metrics = (ms ?? []) as MetricOpt[];

  const Table = ({ rows, showRule }: { rows: Row[]; showRule?: boolean }) => (
    <table className="w-full text-xs">
      <thead className="text-muted-foreground"><tr><th className="text-left">Item</th>{showRule && <th>Rule</th>}<th>Threshold</th><th>Current</th><th>As of</th><th>Meets</th></tr></thead>
      <tbody>{rows.map((r) => (
        <tr key={r.code} className="border-t">
          <td className="py-1">{r.label}{r.from_offering_only && <span className="ml-1 rounded border px-1 text-[10px] text-amber-700">offering proceeds only</span>}</td>
          {showRule && <td className="text-center text-muted-foreground">{r.rule_ref}</td>}
          <td className="text-center">{r.comparator === 'lte' ? '≤' : '≥'} {fmt(r.threshold, r.unit)}</td>
          <td className="text-center">{fmt(r.value, r.unit)}</td>
          <td className="text-center text-muted-foreground">{r.measured_at ?? '—'}</td>
          <td className="text-center">{r.meets == null ? <span className="rounded bg-muted px-1.5 text-muted-foreground">unmeasured</span> : r.meets ? <span className="rounded bg-emerald-100 px-1.5 text-emerald-800">meets</span> : <span className="rounded bg-red-100 px-1.5 text-red-800">fails</span>}</td>
        </tr>
      ))}</tbody>
    </table>
  );

  return (
    <div className="flex flex-col gap-4">
      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Metric snapshot — the only place numbers enter</h2>
        <SnapshotForm metrics={metrics} />
      </section>
      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Nasdaq / SEC listing criteria (Capital Market · Equity Standard)</h2>
        <Table rows={listing.filter((r) => !r.is_alternate)} showRule />
        <details className="mt-2 text-xs"><summary className="cursor-pointer text-muted-foreground">Show alternate / uplist standards</summary><div className="mt-2"><Table rows={listing.filter((r) => r.is_alternate)} showRule /></div></details>
      </section>
      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Internal KPIs — decision reference, not listing requirements</h2>
        <Table rows={kpis} />
      </section>
    </div>
  );
}

/* ---------------- Patents ---------------- */
async function Patents({ pid }: { pid: string }) {
  const sb = await createSupabaseServerClient();
  const app = sb.schema('app');
  const [{ data: ps }, { data: hz }] = await Promise.all([
    app.from('patents' as never).select('*').eq('program_id', pid).order('family_code').order('jurisdiction'),
    app.from('v_patent_horizon' as never).select('*').eq('program_id', pid).maybeSingle(),
  ]);
  return <PatentsPanel patents={(ps ?? []) as PatentRow[]} horizon={(hz ?? null) as Horizon} programId={pid} />;
}
