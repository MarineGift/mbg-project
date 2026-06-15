// src/app/(app)/pipelines/[code]/kanban-client.tsx
// Client kanban board with:
//   - Drag-and-drop stage moves (8px activation; click-vs-drag preserved)
//   - DragOverlay for smooth visual feedback
//   - Optimistic state + server action; revert on failure
//   - "+ New deal" button opening NewDealModal (quick-create form)
//   - Round dimension (Investor only): round badge on each card + top filter.
//
// Multi-company / Stage 1-B (2026-06-02):
//   - A deal now has many companies via deal_parties (M:N), each with its own
//     commitment_amount. The card shows every company (first + "+N") and the
//     deal total = sum(commitment_amount). Column/board totals aggregate those.

'use client';

import { useEffect, useMemo, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  DndContext,
  DragEndEvent,
  DragOverlay,
  DragStartEvent,
  PointerSensor,
  useDraggable,
  useDroppable,
  useSensor,
  useSensors,
} from '@dnd-kit/core';
import { CSS } from '@dnd-kit/utilities';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { moveDealStage } from './actions';
import { NewDealModal } from './new-deal-modal';
import { DealCalendar, DealGantt } from './deal-timeline-views';

// ============================================================
// Types
// ============================================================

type Pipeline = { id: string; code: string; name: string; description: string | null };
type Stage = { id: string; code: string; name: string; sort_order: number };
type RoundOption = { id: string; name: string };
type CampaignOption = { id: string; name: string; color: string | null; start_date: string | null; end_date: string | null };

type DealPartyRow = {
  id: string;
  party_id: string;
  role: string;
  commitment_amount: number | string | null;
  currency: string;
  parties: { party_name: string; country_code: string | null } | null;
};

type Deal = {
  id: string;
  deal_name: string;
  current_stage_id: string;
  value_amount: number | null;
  value_currency: string;
  last_activity_at: string | null;
  status: string;
  campaign_id: string | null;
  start_date: string | null;
  end_date: string | null;
  expected_close_date: string | null;
  deal_parties: DealPartyRow[] | null;
  round: { id: string; name: string } | null;
};

interface Props {
  pipeline: Pipeline;
  stages: Stage[];
  deals: Deal[];
  /** Investor pipeline only; [] elsewhere. */
  rounds: RoundOption[];
  /** All active campaigns (any pipeline) for the New Deal modal. */
  campaigns: CampaignOption[];
}

// ============================================================
// Helpers
// ============================================================

function toNum(v: number | string | null | undefined): number | null {
  if (v == null) return null;
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// Sum a deal's commitments, keyed by currency (a deal may mix currencies).
function commitmentTotals(deal: Deal): Record<string, number> {
  const out: Record<string, number> = {};
  for (const p of deal.deal_parties ?? []) {
    const n = toNum(p.commitment_amount);
    if (n != null) out[p.currency] = (out[p.currency] ?? 0) + n;
  }
  return out;
}

const ROLE_ORDER: Record<string, number> = {
  lead: 0,
  co_investor: 1,
  participant: 2,
  advisor: 3,
  primary: 4,
};

function sortedParties(deal: Deal): DealPartyRow[] {
  return [...(deal.deal_parties ?? [])].sort(
    (a, b) =>
      (ROLE_ORDER[a.role] ?? 9) - (ROLE_ORDER[b.role] ?? 9) ||
      (a.parties?.party_name ?? '').localeCompare(b.parties?.party_name ?? '')
  );
}

function fmtMoney(amount: number | null, currency: string): string {
  if (amount == null) return '\u2014';
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return amount.toLocaleString() + ' ' + currency;
  }
}

function fmtTotals(totals: Record<string, number>): string {
  const entries = Object.entries(totals);
  if (entries.length === 0) return '\u2014';
  return entries.map(([cur, sum]) => fmtMoney(sum, cur)).join(' \u00b7 ');
}

function fmtRelative(iso: string | null): string {
  if (!iso) return '';
  const ms = Date.now() - new Date(iso).getTime();
  if (ms < 0) return '';
  const days = Math.floor(ms / 86_400_000);
  if (days < 1) return 'today';
  if (days < 30) return days + 'd ago';
  if (days < 365) return Math.floor(days / 30) + 'mo ago';
  return Math.floor(days / 365) + 'y ago';
}

function mergeTotals(into: Record<string, number>, add: Record<string, number>): void {
  for (const [cur, sum] of Object.entries(add)) {
    into[cur] = (into[cur] ?? 0) + sum;
  }
}

// ============================================================
// Component
// ============================================================

export function KanbanClient({ pipeline, stages, deals, rounds, campaigns }: Props) {
  const router = useRouter();

  const [optimisticDeals, setOptimisticDeals] = useState<Deal[]>(deals);
  const [activeDealId, setActiveDealId] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const [roundFilter, setRoundFilter] = useState<string>('all');
  const [campaignFilter, setCampaignFilter] = useState<string>('all');
  const [view, setView] = useState<'kanban' | 'calendar' | 'gantt'>('kanban');
  const [modalOpen, setModalOpen] = useState(false);

  const showRounds = pipeline.code === 'investors' && rounds.length > 0;

  useEffect(() => {
    setOptimisticDeals(deals);
  }, [deals]);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 8 } })
  );

  const handleDragStart = (event: DragStartEvent) => {
    setActiveDealId(String(event.active.id));
  };

  const handleDragCancel = () => {
    setActiveDealId(null);
  };

  // Shared stage-move logic, used by drag-and-drop AND the Gantt's clickable
  // stage cells. Optimistic update -> persist -> rollback on failure. Because
  // the Gantt and Kanban share this same optimisticDeals state, a move made in
  // the Gantt is reflected on the Kanban immediately (and saved to the DB).
  const applyStageMove = (dealId: string, newStageId: string) => {
    const current = optimisticDeals.find((d) => d.id === dealId);
    if (!current || current.current_stage_id === newStageId) return;
    const previousStageId = current.current_stage_id;
    setOptimisticDeals((prev) =>
      prev.map((d) => (d.id === dealId ? { ...d, current_stage_id: newStageId } : d))
    );
    startTransition(async () => {
      const result = await moveDealStage(dealId, newStageId, pipeline.code);
      if (!result.ok) {
        console.error('Failed to move deal:', result.error);
        setOptimisticDeals((prev) =>
          prev.map((d) => (d.id === dealId ? { ...d, current_stage_id: previousStageId } : d))
        );
      }
    });
  };

  const handleDragEnd = (event: DragEndEvent) => {
    setActiveDealId(null);
    const { active, over } = event;
    if (!over) return;
    applyStageMove(String(active.id), String(over.id));
  };

  const visibleDeals = useMemo(() => {
    let list = optimisticDeals;
    if (roundFilter !== 'all') list = list.filter((d) => d.round?.id === roundFilter);
    if (campaignFilter !== 'all') list = list.filter((d) => d.campaign_id === campaignFilter);
    return list;
  }, [optimisticDeals, roundFilter, campaignFilter]);

  const stageBuckets = useMemo(() => {
    const byStage = new Map<string, Deal[]>();
    for (const s of stages) byStage.set(s.id, []);
    for (const d of visibleDeals) {
      const arr = byStage.get(d.current_stage_id);
      if (arr) arr.push(d);
    }
    return stages.map((s) => {
      const ds = byStage.get(s.id) ?? [];
      const sums: Record<string, number> = {};
      for (const d of ds) mergeTotals(sums, commitmentTotals(d));
      return { stage: s, deals: ds, count: ds.length, sums };
    });
  }, [stages, visibleDeals]);

  const totalValue: Record<string, number> = {};
  for (const d of visibleDeals) mergeTotals(totalValue, commitmentTotals(d));

  const activeDeal = activeDealId
    ? optimisticDeals.find((d) => d.id === activeDealId) ?? null
    : null;

  return (
    <>
      <DndContext
        sensors={sensors}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
        onDragCancel={handleDragCancel}
      >
        <div className="flex h-full flex-col">
          {/* Page header */}
          <div className="flex items-center justify-between gap-4 border-b bg-background px-6 py-4">
            <div className="min-w-0">
              <h1 className="truncate text-xl font-semibold text-foreground">
                {pipeline.name}
              </h1>
              {pipeline.description ? (
                <p className="mt-0.5 line-clamp-1 text-xs text-muted-foreground">
                  {pipeline.description}
                </p>
              ) : null}
            </div>
            <div className="flex items-center gap-3 whitespace-nowrap">
              <div className="flex items-center gap-3 text-xs text-muted-foreground">
                <span>{visibleDeals.length} deals</span>
                {Object.entries(totalValue).map(([cur, sum]) => (
                  <span key={cur} className="font-medium text-foreground">
                    {fmtMoney(sum, cur)}
                  </span>
                ))}
              </div>
              {campaigns.length > 0 && (
                <div className="flex items-center gap-2">
                  <select
                    value={campaignFilter}
                    onChange={(e) => setCampaignFilter(e.target.value)}
                    className="rounded-md border bg-background px-2 py-1.5 text-sm text-muted-foreground focus:text-foreground focus:outline-none"
                  >
                    <option value="all">All campaigns</option>
                    {campaigns.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                  {campaignFilter !== 'all' && (
                    <Link
                      href={'/campaigns/' + campaignFilter}
                      className="inline-flex items-center gap-1 rounded-md border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                    >
                      View detail
                    </Link>
                  )}
                </div>
              )}
              <Button
                size="sm"
                onClick={() => setModalOpen(true)}
                className="gap-1.5"
              >
                <Plus className="h-3.5 w-3.5" />
                New deal
              </Button>
            </div>
          </div>

          {/* View tabs */}
          <div className="flex items-center gap-1 border-b bg-background px-6">
            {(['kanban', 'calendar', 'gantt'] as const).map((v) => (
              <button
                key={v}
                onClick={() => setView(v)}
                className={'border-b-2 px-3 py-2 text-sm capitalize transition-colors ' + (view === v ? 'border-foreground font-medium text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground')}
              >
                {v}
              </button>
            ))}
          </div>

          {view === 'kanban' && (
          <>
          {/* Round filter bar (Investor only) */}
          {showRounds ? (
            <div className="flex items-center gap-2 border-b bg-background px-6 py-2 text-xs">
              <span className="text-muted-foreground">Round</span>
              <RoundPill
                active={roundFilter === 'all'}
                onClick={() => setRoundFilter('all')}
              >
                All
              </RoundPill>
              {rounds.map((r) => (
                <RoundPill
                  key={r.id}
                  active={roundFilter === r.id}
                  onClick={() => setRoundFilter(r.id)}
                >
                  {r.name}
                </RoundPill>
              ))}
            </div>
          ) : null}

          {/* Board */}
          <div className="flex-1 overflow-hidden bg-muted/30 lg:overflow-y-auto">
            {stages.length === 0 ? (
              <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                No stages configured for this pipeline.
              </div>
            ) : (
              <div className="flex h-full snap-x snap-mandatory gap-3 overflow-x-auto p-4 sm:grid sm:h-auto sm:snap-none sm:grid-cols-2 sm:overflow-x-visible lg:grid-cols-4 xl:grid-cols-5">
                {stageBuckets.map(({ stage, deals: stageDeals, count, sums }, i) => (
                  <DroppableColumn
                    key={stage.id}
                    stage={stage}
                    count={count}
                    sums={sums}
                    accent={STAGE_PALETTE[i % STAGE_PALETTE.length]!}
                  >
                    {stageDeals.length === 0 ? (
                      <div className="px-2 py-6 text-center text-xs text-muted-foreground/70">
                        No deals
                      </div>
                    ) : (
                      stageDeals.map((d) => (
                        <DraggableCard
                          key={d.id}
                          deal={d}
                          onOpen={() =>
                            router.push('/pipelines/' + pipeline.code + '/deals/' + d.id)
                          }
                        />
                      ))
                    )}
                  </DroppableColumn>
                ))}
              </div>
            )}
          </div>
          </>
          )}

          {view === 'calendar' && (
            <div className="flex-1 overflow-y-auto bg-background">
              <DealCalendar campaigns={campaigns} deals={visibleDeals} stages={stages} onOpen={(id) => router.push('/pipelines/' + pipeline.code + '/deals/' + id)} />
            </div>
          )}
          {view === 'gantt' && (
            <div className="flex-1 overflow-y-auto bg-background">
              <DealGantt campaigns={campaigns} deals={visibleDeals} stages={stages} onStageChange={applyStageMove} onOpen={(id) => router.push('/pipelines/' + pipeline.code + '/deals/' + id)} />
            </div>
          )}
        </div>

        <DragOverlay dropAnimation={null}>
          {activeDeal ? <CardContent deal={activeDeal} isOverlay /> : null}
        </DragOverlay>
      </DndContext>

      {/* New deal modal */}
      <NewDealModal
        open={modalOpen}
        onOpenChange={setModalOpen}
        pipelineCode={pipeline.code}
        pipelineName={pipeline.name}
        stages={stages}
        rounds={rounds}
        campaigns={campaigns}
      />
    </>
  );
}

// ============================================================
// Round filter pill
// ============================================================

function RoundPill({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'rounded-full px-2.5 py-0.5 text-xs transition-colors',
        active
          ? 'bg-foreground text-background'
          : 'border text-muted-foreground hover:text-foreground'
      )}
    >
      {children}
    </button>
  );
}

// ============================================================
// Column (droppable)
// ============================================================

// Pastel accents cycled by column order so stages are visually distinct.
// [top accent bar, header background+text] — light & dark variants.
const STAGE_PALETTE: Array<{ bar: string; head: string }> = [
  { bar: 'bg-rose-300 dark:bg-rose-700',       head: 'bg-rose-50 text-rose-900 dark:bg-rose-950/40 dark:text-rose-100' },
  { bar: 'bg-amber-300 dark:bg-amber-700',     head: 'bg-amber-50 text-amber-900 dark:bg-amber-950/40 dark:text-amber-100' },
  { bar: 'bg-emerald-300 dark:bg-emerald-700', head: 'bg-emerald-50 text-emerald-900 dark:bg-emerald-950/40 dark:text-emerald-100' },
  { bar: 'bg-sky-300 dark:bg-sky-700',         head: 'bg-sky-50 text-sky-900 dark:bg-sky-950/40 dark:text-sky-100' },
  { bar: 'bg-violet-300 dark:bg-violet-700',   head: 'bg-violet-50 text-violet-900 dark:bg-violet-950/40 dark:text-violet-100' },
  { bar: 'bg-fuchsia-300 dark:bg-fuchsia-700', head: 'bg-fuchsia-50 text-fuchsia-900 dark:bg-fuchsia-950/40 dark:text-fuchsia-100' },
  { bar: 'bg-teal-300 dark:bg-teal-700',       head: 'bg-teal-50 text-teal-900 dark:bg-teal-950/40 dark:text-teal-100' },
  { bar: 'bg-orange-300 dark:bg-orange-700',   head: 'bg-orange-50 text-orange-900 dark:bg-orange-950/40 dark:text-orange-100' },
  { bar: 'bg-indigo-300 dark:bg-indigo-700',   head: 'bg-indigo-50 text-indigo-900 dark:bg-indigo-950/40 dark:text-indigo-100' },
  { bar: 'bg-lime-300 dark:bg-lime-700',       head: 'bg-lime-50 text-lime-900 dark:bg-lime-950/40 dark:text-lime-100' },
];

function DroppableColumn({
  stage,
  count,
  sums,
  accent,
  children,
}: {
  stage: Stage;
  count: number;
  sums: Record<string, number>;
  accent: { bar: string; head: string };
  children: React.ReactNode;
}) {
  const { setNodeRef, isOver } = useDroppable({ id: stage.id });

  return (
    <div
      ref={setNodeRef}
      className={cn(
        'flex h-full w-[84vw] shrink-0 snap-start flex-col overflow-hidden rounded-lg border bg-card transition-colors sm:h-[26rem] sm:w-full',
        isOver && 'border-foreground/40 bg-card/80 ring-2 ring-foreground/10'
      )}
    >
      <div className={cn('h-1 w-full', accent.bar)} />
      <div className={cn('border-b px-3 py-2', accent.head)}>
        <div className="flex items-baseline justify-between">
          <span className="truncate text-sm font-semibold">
            {stage.name}
          </span>
          <span className="ml-2 tabular-nums text-xs opacity-70">
            {count}
          </span>
        </div>
        {Object.keys(sums).length > 0 ? (
          <div className="mt-0.5 text-[11px] opacity-70">
            {fmtTotals(sums)}
          </div>
        ) : null}
      </div>

      <div className="scrollbar-visible flex-1 space-y-2 overflow-y-auto p-2">
        {children}
      </div>
    </div>
  );
}

// ============================================================
// Card (draggable)
// ============================================================

function DraggableCard({ deal, onOpen }: { deal: Deal; onOpen: () => void }) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: deal.id,
  });

  const style: React.CSSProperties = {
    transform: CSS.Translate.toString(transform),
    opacity: isDragging ? 0.2 : 1,
    cursor: 'grab',
    touchAction: 'none',
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      onClick={onOpen}
      className="block rounded-md border bg-background p-3 text-sm shadow-sm transition hover:border-foreground/20 hover:shadow"
    >
      <CardContent deal={deal} />
    </div>
  );
}

function CardContent({ deal, isOverlay = false }: { deal: Deal; isOverlay?: boolean }) {
  const parties = sortedParties(deal);
  const lead = parties[0];
  const extra = parties.length - 1;
  const totals = commitmentTotals(deal);

  return (
    <div
      className={cn(
        isOverlay &&
          'w-72 rounded-md border bg-background p-3 text-sm shadow-lg ring-2 ring-foreground/20'
      )}
    >
      <div className="line-clamp-2 font-medium leading-tight text-foreground">
        {deal.deal_name}
      </div>

      {lead ? (
        <div className="mt-1.5 line-clamp-1 text-xs text-muted-foreground">
          {lead.parties?.party_name ?? '(unknown party)'}
          {lead.parties?.country_code ? (
            <span className="ml-1 opacity-60">{'\u00b7'} {lead.parties.country_code}</span>
          ) : null}
          {extra > 0 ? (
            <span className="ml-1 font-medium text-foreground">+{extra}</span>
          ) : null}
        </div>
      ) : (
        <div className="mt-1.5 text-xs text-muted-foreground/70">No companies</div>
      )}

      {deal.round ? (
        <div className="mt-1.5">
          <span className="inline-flex items-center rounded bg-primary/10 px-1.5 py-0.5 text-[10px] font-medium text-primary">
            {deal.round.name}
          </span>
        </div>
      ) : null}

      <div className="mt-2 flex items-center justify-between text-xs">
        <span className="font-medium tabular-nums text-foreground">
          {fmtTotals(totals)}
        </span>
        {deal.last_activity_at ? (
          <span className="text-muted-foreground">
            {fmtRelative(deal.last_activity_at)}
          </span>
        ) : null}
      </div>
    </div>
  );
}
