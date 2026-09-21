// src/app/(app)/ipo/ipo-gantt.tsx
//
// Client Gantt for app.v_ipo_gantt rows (phase summary bars + milestones +
// decision windows). Month grid, workstream filter, gates-only toggle,
// phase collapse, predecessor highlight on hover. No chart library.

'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { MilestoneStatusSelect } from './milestone-status-select';

export type GanttRow = {
  row_type: 'phase' | 'milestone' | 'decision';
  code: string;
  label: string;
  start_date: string;
  end_date: string;
  status: string | null;
  is_gate: boolean;
  workstream: string | null;
  phase_code: string | null;
  ord: number;
  pct_done: number | null;
  milestone_id?: string | null;
  task_id?: string | null;
};

export type Workstream = { code: string; name: string; color_hex: string | null };
export type Dep = { milestone_code: string; depends_on_code: string };

const MIN_COL = 26;  // px per month when the timeline must scroll
const LEFT = 560;    // label column
const ROW = 40;      // two-line titles
const PHASE_ROW = 38;

function parse(s: string) { return new Date(s + 'T00:00:00'); }

export function IpoGantt({
  rows, workstreams, deps, programStart, programEnd, today,
  windows,
}: {
  rows: GanttRow[];
  workstreams: Workstream[];
  deps: Dep[];
  programStart: string;
  programEnd: string;
  today: string;
  windows: Array<{ name: string; start: string; end: string; tone: 'red' | 'blue' }>;
}) {
  const start = parse(programStart);
  const end = parse(programEnd);
  const wrapRef = useRef<HTMLDivElement>(null);
  const [COL, setCol] = useState(MIN_COL);
  const months = useMemo(() => {
    const out: Date[] = [];
    let d = new Date(start);
    while (d <= end) { out.push(new Date(d)); d = new Date(d.getFullYear(), d.getMonth() + 1, 1); }
    return out;
  }, [programStart, programEnd]); // eslint-disable-line react-hooks/exhaustive-deps

  // Stretch columns to fill the available width; scroll only when narrower than MIN_COL.
  useEffect(() => {
    const el = wrapRef.current; if (!el) return;
    const fit = () => setCol(Math.max(MIN_COL, Math.floor((el.clientWidth - LEFT - 2) / months.length)));
    fit();
    const ro = new ResizeObserver(fit); ro.observe(el);
    return () => ro.disconnect();
  }, [months.length]);

  const x = (s: string) => {
    const d = parse(s);
    return ((d.getFullYear() - start.getFullYear()) * 12 + (d.getMonth() - start.getMonth()) + (d.getDate() - 1) / 30) * COL;
  };

  const wsMap = useMemo(() => Object.fromEntries(workstreams.map((w) => [w.code, w])), [workstreams]);
  const preds = useMemo(() => {
    const m: Record<string, string[]> = {};
    for (const d of deps) (m[d.milestone_code] ||= []).push(d.depends_on_code);
    return m;
  }, [deps]);

  const [ws, setWs] = useState<Set<string>>(() => new Set(workstreams.map((w) => w.code)));
  const [gatesOnly, setGatesOnly] = useState(false);
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const [hover, setHover] = useState<string | null>(null);

  const phases = rows.filter((r) => r.row_type === 'phase');
  const decisions = rows.filter((r) => r.row_type === 'decision');
  const milestonesByPhase = useMemo(() => {
    const m: Record<string, GanttRow[]> = {};
    for (const r of rows) if (r.row_type === 'milestone') (m[r.phase_code ?? ''] ||= []).push(r);
    return m;
  }, [rows]);

  const gridWidth = LEFT + months.length * COL;
  const hoverPreds = hover ? new Set(preds[hover] ?? []) : null;

  const years: Array<{ y: number; n: number }> = [];
  for (const m of months) {
    const last = years[years.length - 1];
    if (last && last.y === m.getFullYear()) last.n += 1; else years.push({ y: m.getFullYear(), n: 1 });
  }

  const toggle = (set: Set<string>, v: string) => { const n = new Set(set); n.has(v) ? n.delete(v) : n.add(v); return n; };

  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap items-center gap-2 text-xs">
        {workstreams.map((w) => (
          <button key={w.code} type="button" aria-pressed={ws.has(w.code)}
            onClick={() => setWs(toggle(ws, w.code))}
            className="inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 aria-[pressed=false]:opacity-40">
            <span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: w.color_hex ?? '#888' }} />
            {w.name}
          </button>
        ))}
        <span className="mx-1 h-5 w-px bg-border" />
        <button type="button" aria-pressed={gatesOnly} onClick={() => setGatesOnly(!gatesOnly)}
          className="rounded-full border px-2.5 py-1 aria-[pressed=false]:opacity-40">Gates only</button>
        <span className="ml-auto text-muted-foreground">
          {rows.filter((r) => r.row_type === 'milestone').length} milestones · {rows.filter((r) => r.row_type === 'milestone' && r.is_gate).length} gates
        </span>
      </div>

      <div ref={wrapRef} className="relative overflow-auto rounded-md border">
        <div className="relative" style={{ width: gridWidth }}>
          {/* header */}
          <div className="sticky top-0 z-20 flex border-b bg-background" style={{ height: 52 }}>
            <div className="sticky left-0 z-30 shrink-0 border-r bg-background" style={{ width: LEFT }} />
            <div className="flex flex-col">
              <div className="flex" style={{ height: 26 }}>
                {years.map((y) => (
                  <div key={y.y} className="border-r px-2 text-xs font-semibold leading-[26px]" style={{ width: y.n * COL }}>{y.y}</div>
                ))}
              </div>
              <div className="flex" style={{ height: 26 }}>
                {months.map((m, i) => (
                  <div key={i} className={'border-r text-center text-[11px] leading-[26px] ' + ((m.getMonth() + 1) % 3 === 0 ? 'font-medium' : 'text-muted-foreground')}
                    style={{ width: COL }}>{m.getMonth() + 1}</div>
                ))}
              </div>
            </div>
          </div>

          {/* bands */}
          {decisions.map((d, i) => (
            <div key={d.code} className="pointer-events-none absolute bottom-0 z-10 border-x border-dashed border-muted-foreground/60 bg-foreground/5"
              style={{ top: 52, left: LEFT + x(d.start_date), width: Math.max(4, x(d.end_date) - x(d.start_date) + COL / 30) }}
              title={d.label}>
              <span className="absolute left-1 whitespace-nowrap rounded bg-background/80 px-1 text-[10px] text-muted-foreground" style={{ top: 2 + i * 14 }}>{d.label.split(' — ')[0]}</span>
            </div>
          ))}
          {windows.map((w) => (
            <div key={w.name} className="pointer-events-none absolute bottom-0 z-10"
              style={{ top: 52, left: LEFT + x(w.start), width: x(w.end) - x(w.start) + COL / 30,
                backgroundImage: `repeating-linear-gradient(135deg, ${w.tone === 'red' ? 'rgba(220,38,38,.12)' : 'rgba(37,99,235,.12)'} 0 6px, transparent 6px 12px)` }}>
              <span className="absolute left-1 whitespace-nowrap rounded bg-background/80 px-1 text-[10px] text-muted-foreground" style={{ top: 46 }}>{w.name}</span>
            </div>
          ))}
          <div className="pointer-events-none absolute bottom-0 z-10 w-0.5 bg-foreground" style={{ top: 52, left: LEFT + x(today) }}>
            <span className="absolute left-1 top-1 rounded bg-foreground px-1 text-[10px] text-background">Today</span>
          </div>

          {/* rows */}
          {phases.map((p) => {
            const ms = (milestonesByPhase[p.code] ?? []).filter((m) =>
              (m.workstream ? ws.has(m.workstream) : true) && (!gatesOnly || m.is_gate));
            const isCollapsed = collapsed.has(p.code);
            return (
              <div key={p.code}>
                <div className="flex border-b bg-muted/40" style={{ height: PHASE_ROW }}>
                  <button type="button" onClick={() => setCollapsed(toggle(collapsed, p.code))}
                    className="sticky left-0 z-20 flex shrink-0 items-center gap-2 border-r bg-muted/40 px-3 text-left text-sm font-semibold backdrop-blur"
                    style={{ width: LEFT }}>
                    <span className="w-8 text-xs text-muted-foreground">{p.code}</span>
                    <span className="min-w-0 flex-1 whitespace-normal leading-tight" style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }} title={p.label}>{p.label}</span>
                    <span className="ml-auto text-xs font-normal text-muted-foreground">{p.pct_done ?? 0}%</span>
                  </button>
                  <div className="relative flex-1" style={{ backgroundImage: 'linear-gradient(to right, hsl(var(--border)) 1px, transparent 1px)', backgroundSize: `${COL}px 100%` }}>
                    <div className="absolute rounded-sm bg-foreground/90" style={{ top: 13, height: 12, left: x(p.start_date), width: Math.max(COL * 0.6, x(p.end_date) - x(p.start_date)) }} />
                  </div>
                </div>
                {!isCollapsed && ms.map((m) => {
                  const dim = hover && hover !== m.code && !hoverPreds?.has(m.code);
                  const isPred = hoverPreds?.has(m.code);
                  const color = m.workstream ? wsMap[m.workstream]?.color_hex ?? '#888' : '#888';
                  const done = m.status === 'done';
                  return (
                    <div key={m.code} className={'flex border-b ' + (dim ? 'opacity-25' : '')} style={{ height: ROW }}
                      onMouseEnter={() => setHover(m.code)} onMouseLeave={() => setHover(null)}>
                      <div className="sticky left-0 z-20 flex shrink-0 items-center gap-2 border-r bg-background px-3 text-xs" style={{ width: LEFT }}>
                        <span className="w-14 shrink-0 text-muted-foreground">{m.code}</span>
                        <span className={'min-w-0 flex-1 whitespace-normal leading-tight text-[11px] ' + (done ? 'line-through text-muted-foreground' : '')}
                          style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }} title={m.label}>{m.label}</span>
                        {m.task_id && (
                          <a href={`/tasks/${m.task_id}`} className="shrink-0 rounded border px-1 text-[10px] text-muted-foreground hover:text-foreground" title="Open URM task (engagements, assignee, notes)">task</a>
                        )}
                        {m.milestone_id && (
                          <span className="shrink-0"><MilestoneStatusSelect id={m.milestone_id} status={m.status ?? 'not_started'} compact /></span>
                        )}
                      </div>
                      <div className="relative flex-1" style={{ backgroundImage: 'linear-gradient(to right, hsl(var(--border)) 1px, transparent 1px)', backgroundSize: `${COL}px 100%` }}
                        title={`${m.start_date} → ${m.end_date}${(preds[m.code] ?? []).length ? ' · after: ' + (preds[m.code] ?? []).join(', ') : ''}`}>
                        <div className={'absolute rounded-sm ' + (isPred ? 'ring-2 ring-foreground ring-offset-1' : '')}
                          style={{ top: 14, height: 12, left: x(m.start_date), width: Math.max(COL * 0.6, x(m.end_date) - x(m.start_date)), background: color, opacity: done ? 0.45 : 0.85 }} />
                        {m.is_gate && (
                          <div className="absolute h-3.5 w-3.5 rotate-45 border-2 border-background bg-foreground" style={{ top: 13, left: x(m.end_date) - 6 }} />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>
      </div>
      <p className="text-xs text-muted-foreground">◆ gate · dashed band = Go/No-Go decision window · hatched = IPO window (red 2029 Q4, blue 2030 Q2) · click a phase to collapse · hover a milestone to highlight predecessors</p>
    </div>
  );
}
