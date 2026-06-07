'use client';

// Campaign-centric timeline for the pipeline board.
// Per campaign: a compact schedule strip (period) on top, then a STAGE axis
// (the pipeline's stages split into equal columns, numbered 1..N with names),
// then one row per participating company showing how far it has progressed and
// its current stage as "N (Stage name)".

import { useMemo, useState } from 'react';

export type TimelineStage = { id: string; name: string; sort_order: number };
export type TimelineDeal = {
  id: string;
  deal_name: string;
  current_stage_id: string;
  campaign_id: string | null;
  value_amount: number | null;
  value_currency: string;
  start_date: string | null;
  end_date: string | null;
  expected_close_date: string | null;
  deal_parties: Array<{ parties: { party_name: string | null } | null }> | null;
};
export type TimelineCampaign = {
  id: string;
  name: string;
  color: string | null;
  start_date: string | null;
  end_date: string | null;
};

const PALETTE = ['#2563eb', '#16a34a', '#f59e0b', '#8b5cf6', '#dc2626', '#0ea5e9', '#db2777', '#65a30d'];
function stageColor(stage: TimelineStage | undefined): string {
  if (!stage) return '#94a3b8';
  return PALETTE[Math.abs(stage.sort_order) % PALETTE.length]!;
}
function parse(d: string | null): Date | null {
  if (!d) return null;
  const t = new Date(d + (d.length <= 10 ? 'T00:00:00' : ''));
  return Number.isNaN(t.getTime()) ? null : t;
}
function ymd(d: Date): string { return d.toISOString().slice(0, 10); }
function keyDate(d: TimelineDeal): Date | null {
  return parse(d.expected_close_date) ?? parse(d.end_date) ?? parse(d.start_date);
}
// Participating company (party) names for a deal, mirroring the Kanban card.
function companyNames(d: TimelineDeal): string[] {
  return (d.deal_parties ?? []).map((p) => p.parties?.party_name ?? '').filter(Boolean);
}
function companyLabel(d: TimelineDeal): string {
  const n = companyNames(d);
  if (n.length === 0) return d.deal_name;
  return n.length === 1 ? n[0]! : n[0]! + '  +' + (n.length - 1);
}
function companyTitle(d: TimelineDeal): string {
  const n = companyNames(d);
  return (n.length ? n.join(', ') + ' \u2014 ' : '') + d.deal_name;
}
// Sort rows so headquarters "(HQ)" companies float to the top of each group,
// then alphabetically by company label.
function hqFirst(a: TimelineDeal, b: TimelineDeal): number {
  const ah = companyNames(a).some((n) => n.includes('(HQ)')) ? 0 : 1;
  const bh = companyNames(b).some((n) => n.includes('(HQ)')) ? 0 : 1;
  if (ah !== bh) return ah - bh;
  return companyLabel(a).localeCompare(companyLabel(b));
}

const NAME_W = 'w-52';
const LABEL_W = 'w-44';

// ============================================================
// Gantt: schedule strip + stage axis + companies' current stage
// ============================================================
export function DealGantt({
  campaigns,
  deals,
  stages,
  onOpen,
  onStageChange,
}: {
  campaigns: TimelineCampaign[];
  deals: TimelineDeal[];
  stages: TimelineStage[];
  onOpen: (id: string) => void;
  onStageChange?: (dealId: string, stageId: string) => void;
}) {
  const ordered = useMemo(() => [...stages].sort((a, b) => a.sort_order - b.sort_order), [stages]);
  const dealsByCampaign = useMemo(() => {
    const m = new Map<string, TimelineDeal[]>();
    for (const d of deals) {
      if (!d.campaign_id) continue;
      const arr = m.get(d.campaign_id) ?? [];
      arr.push(d);
      m.set(d.campaign_id, arr);
    }
    for (const arr of m.values()) arr.sort(hqFirst);
    return m;
  }, [deals]);
  const standalone = useMemo(() => [...deals].filter((d) => !d.campaign_id).sort(hqFirst), [deals]);

  // Only campaigns that have at least one deal in THIS pipeline (campaigns have
  // no pipeline_id of their own; membership is derived from the board's deals).
  const pipelineCampaignIds = useMemo(() => {
    const ids = new Set<string>();
    for (const d of deals) if (d.campaign_id) ids.add(d.campaign_id);
    return ids;
  }, [deals]);
  const pcampaigns = useMemo(
    () => campaigns.filter((c) => pipelineCampaignIds.has(c.id)),
    [campaigns, pipelineCampaignIds]
  );

  const dated = pcampaigns.filter((c) => {
    const s = parse(c.start_date), e = parse(c.end_date);
    return s && e && e.getTime() >= s.getTime();
  });
  const undated = pcampaigns.filter((c) => !dated.includes(c));

  let min = 0, max = 0;
  if (dated.length) {
    min = parse(dated[0]!.start_date)!.getTime();
    max = parse(dated[0]!.end_date)!.getTime();
    for (const c of dated) {
      min = Math.min(min, parse(c.start_date)!.getTime());
      max = Math.max(max, parse(c.end_date)!.getTime());
    }
  }
  const span = Math.max(max - min, 86400000);
  const pct = (t: number) => ((t - min) / span) * 100;
  const ticks: Array<{ left: number; label: string }> = [];
  if (dated.length) {
    const cur = new Date(new Date(min).getFullYear(), new Date(min).getMonth(), 1);
    while (cur.getTime() <= max) {
      ticks.push({ left: pct(cur.getTime()), label: cur.toLocaleDateString('en-US', { month: 'short', year: '2-digit' }) });
      cur.setMonth(cur.getMonth() + 1);
    }
  }

  if (pcampaigns.length === 0 && standalone.length === 0) {
    return (
      <div className="p-6 text-sm text-muted-foreground">
        No campaigns in this pipeline yet. Attach a deal in this pipeline to a campaign (New deal &rarr; &ldquo;Part of a campaign&rdquo;), and it will appear here as a campaign with a stage axis and its participating companies.
      </div>
    );
  }

  // Stage axis header: one column per stage, numbered 1..N (+ name; truncates when narrow).
  const StageHeader = () => (
    <div className="flex items-stretch border-y bg-muted/40 text-[10px]">
      <div className={NAME_W + ' shrink-0 border-r px-2 py-1 font-medium text-muted-foreground'}>Company</div>
      <div className="flex flex-1">
        {ordered.map((s, i) => (
          <div key={s.id} className="flex min-w-0 flex-1 items-center justify-center gap-1 border-r px-1 py-1" title={i + 1 + '. ' + s.name}>
            <span className="font-semibold text-foreground">{i + 1}</span>
            <span className="truncate text-muted-foreground">{s.name}</span>
          </div>
        ))}
      </div>
      <div className={LABEL_W + ' shrink-0 px-2 py-1 text-right text-muted-foreground'}>Current stage</div>
    </div>
  );

  // One company row: progress cells aligned to the stage axis + "N (Stage name)".
  const CompanyRow = ({ d }: { d: TimelineDeal }) => {
    const idx = ordered.findIndex((s) => s.id === d.current_stage_id);
    const current = idx >= 0 ? ordered[idx] : undefined;
    return (
      <div className="flex items-center hover:bg-muted/30">
        <button onClick={() => onOpen(d.id)} className={NAME_W + ' shrink-0 truncate border-r py-1 pl-6 pr-2 text-left text-[11px] hover:underline'} title={companyTitle(d)}>
          {companyLabel(d)}
        </button>
        <div className="flex flex-1 items-center gap-0.5 px-1 py-1">
          {ordered.map((s, i) => {
            const reached = idx >= 0 && i <= idx;
            const isCurrent = i === idx;
            const cellStyle = {
              backgroundColor: reached ? stageColor(s) : '#e2e8f0',
              opacity: reached && !isCurrent ? 0.5 : 1,
              outline: isCurrent ? '2px solid #0f172a' : 'none',
              outlineOffset: isCurrent ? '1px' : '0',
            };
            return onStageChange ? (
              <button
                key={s.id}
                onClick={() => onStageChange(d.id, s.id)}
                title={'Move to ' + (i + 1) + '. ' + s.name}
                className="h-3.5 min-w-0 flex-1 cursor-pointer rounded-sm transition hover:brightness-90"
                style={cellStyle}
              />
            ) : (
              <div
                key={s.id}
                title={i + 1 + '. ' + s.name}
                className="h-3.5 min-w-0 flex-1 rounded-sm"
                style={cellStyle}
              />
            );
          })}
        </div>
        <div className={LABEL_W + ' shrink-0 truncate px-2 text-right text-[11px] font-medium'} style={{ color: stageColor(current) }} title={current?.name ?? ''}>
          {idx >= 0 ? idx + 1 + ' (' + (current?.name ?? '') + ')' : 'No stage'}
        </div>
      </div>
    );
  };

  return (
    <div className="p-4">
      {dated.length > 0 && (
        <>
          {/* shared month axis for the schedule strips */}
          <div className="mb-2 flex items-stretch text-[10px] text-muted-foreground">
            <div className={NAME_W + ' shrink-0'} />
            <div className="relative h-5 flex-1 border-b">
              {ticks.map((t, i) => (
                <div key={i} className="absolute top-0 border-l border-muted-foreground/20 pl-1" style={{ left: t.left + '%' }}>{t.label}</div>
              ))}
            </div>
            <div className={LABEL_W + ' shrink-0'} />
          </div>

          <div className="space-y-4">
            {dated.map((c) => {
              const s = parse(c.start_date)!, e = parse(c.end_date)!;
              const left = pct(s.getTime());
              const width = Math.max(pct(e.getTime()) - left, 1.5);
              const cdeals = dealsByCampaign.get(c.id) ?? [];
              return (
                <div key={c.id} className="overflow-hidden rounded-md border">
                  {/* schedule strip (the campaign period), moved to the top */}
                  <div className="flex items-center bg-muted/20">
                    <div className={NAME_W + ' shrink-0 truncate border-r px-2 py-2 text-xs font-semibold'} title={c.name}>
                      <span className="mr-1 inline-block h-2 w-2 rounded-full align-middle" style={{ backgroundColor: c.color ?? '#94a3b8' }} />
                      {c.name}
                    </div>
                    <div className="relative h-8 flex-1">
                      {ticks.map((t, i) => (
                        <div key={i} className="absolute top-0 h-full border-l border-muted-foreground/10" style={{ left: t.left + '%' }} />
                      ))}
                      <div className="absolute top-1.5 flex h-5 items-center rounded px-2 text-[10px] font-medium text-white" style={{ left: left + '%', width: width + '%', backgroundColor: c.color ?? '#64748b' }} title={ymd(s) + ' ~ ' + ymd(e)}>
                        {ymd(s)} ~ {ymd(e)}
                      </div>
                    </div>
                    <div className={LABEL_W + ' shrink-0 px-2 py-2 text-right text-[10px] text-muted-foreground'}>schedule</div>
                  </div>

                  {/* stage axis + participating companies */}
                  {cdeals.length === 0 ? (
                    <div className="border-t px-3 py-2 text-[11px] text-muted-foreground/70">No companies from this pipeline in this campaign</div>
                  ) : (
                    <>
                      <StageHeader />
                      <div className="divide-y">
                        {cdeals.map((d) => <CompanyRow key={d.id} d={d} />)}
                      </div>
                    </>
                  )}
                </div>
              );
            })}
          </div>
        </>
      )}

      {undated.length > 0 && (
        <div className="mt-4 rounded-md border border-dashed p-3 text-xs text-muted-foreground">
          <div className="mb-1 font-medium text-foreground">Campaigns without a period (set start/end to show on the timeline):</div>
          {undated.map((c) => (
            <div key={c.id} className="py-0.5">• {c.name}</div>
          ))}
        </div>
      )}

      {standalone.length > 0 && (
        <div className="mt-4 overflow-hidden rounded-md border">
          <div className="bg-muted/20 px-2 py-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Not in a campaign</div>
          <StageHeader />
          <div className="divide-y">
            {standalone.map((d) => <CompanyRow key={d.id} d={d} />)}
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================================
// Calendar: campaign start/end markers + deals on their key dates
// ============================================================
export function DealCalendar({
  campaigns,
  deals,
  stages,
  onOpen,
}: {
  campaigns: TimelineCampaign[];
  deals: TimelineDeal[];
  stages: TimelineStage[];
  onOpen: (id: string) => void;
}) {
  const stageMap = useMemo(() => new Map(stages.map((s) => [s.id, s])), [stages]);
  const [cursor, setCursor] = useState(() => {
    const n = new Date();
    return new Date(n.getFullYear(), n.getMonth(), 1);
  });

  type Ev = { label: string; color: string; dealId?: string };
  const pipelineCampaignIds = useMemo(() => {
    const ids = new Set<string>();
    for (const d of deals) if (d.campaign_id) ids.add(d.campaign_id);
    return ids;
  }, [deals]);
  const pcampaigns = useMemo(
    () => campaigns.filter((c) => pipelineCampaignIds.has(c.id)),
    [campaigns, pipelineCampaignIds]
  );
  const byDay = useMemo(() => {
    const m = new Map<string, Ev[]>();
    const add = (date: Date | null, ev: Ev) => {
      if (!date) return;
      const k = ymd(date);
      const arr = m.get(k) ?? [];
      arr.push(ev);
      m.set(k, arr);
    };
    for (const c of pcampaigns) {
      add(parse(c.start_date), { label: '▶ ' + c.name, color: c.color ?? '#64748b' });
      add(parse(c.end_date), { label: '■ ' + c.name, color: c.color ?? '#64748b' });
    }
    for (const d of deals) {
      add(keyDate(d), { label: companyLabel(d), color: stageColor(stageMap.get(d.current_stage_id)), dealId: d.id });
    }
    return m;
  }, [pcampaigns, deals, stageMap]);

  const year = cursor.getFullYear();
  const month = cursor.getMonth();
  const firstDow = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells: Array<Date | null> = [];
  for (let i = 0; i < firstDow; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(new Date(year, month, d));
  while (cells.length % 7 !== 0) cells.push(null);
  const monthLabel = cursor.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  const todayKey = ymd(new Date());

  return (
    <div className="p-4">
      <div className="mb-3 flex items-center gap-2">
        <button onClick={() => setCursor(new Date(year, month - 1, 1))} className="rounded-md border px-2 py-1 text-sm hover:bg-muted">‹</button>
        <span className="min-w-40 text-center text-sm font-medium">{monthLabel}</span>
        <button onClick={() => setCursor(new Date(year, month + 1, 1))} className="rounded-md border px-2 py-1 text-sm hover:bg-muted">›</button>
        <button onClick={() => { const n = new Date(); setCursor(new Date(n.getFullYear(), n.getMonth(), 1)); }} className="ml-1 rounded-md border px-2 py-1 text-xs text-muted-foreground hover:bg-muted">Today</button>
        <span className="ml-auto text-xs text-muted-foreground">▶ campaign start · ■ campaign end</span>
      </div>
      <div className="grid grid-cols-7 overflow-hidden rounded-md border text-xs">
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) => (
          <div key={d} className="border-b bg-muted/50 px-2 py-1 font-medium text-muted-foreground">{d}</div>
        ))}
        {cells.map((cell, i) => {
          const key = cell ? ymd(cell) : '';
          const items = cell ? (byDay.get(key) ?? []) : [];
          const isToday = key === todayKey;
          return (
            <div key={i} className={'min-h-24 border-b border-r p-1 ' + (cell ? '' : 'bg-muted/20')}>
              {cell && (
                <>
                  <div className={'mb-1 text-right text-[11px] ' + (isToday ? 'font-bold text-foreground' : 'text-muted-foreground')}>{cell.getDate()}</div>
                  <div className="space-y-1">
                    {items.map((ev, j) => (
                      <button
                        key={j}
                        onClick={() => ev.dealId && onOpen(ev.dealId)}
                        title={ev.label}
                        className="block w-full truncate rounded px-1 py-0.5 text-left text-[11px] text-white"
                        style={{ backgroundColor: ev.color }}
                      >
                        {ev.label}
                      </button>
                    ))}
                  </div>
                </>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
