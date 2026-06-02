// src/app/(app)/pipelines/[code]/kanban-client.tsx
// Client kanban board with:
//   - Drag-and-drop stage moves (8px activation; click-vs-drag preserved)
//   - DragOverlay for smooth visual feedback
//   - Optimistic state + server action; revert on failure
//   - "+ New deal" button opening NewDealModal (quick-create form)
//   - Round dimension (Investor only): a round badge on each card + a top
//     "Round" filter bar (client-side filter by deals.round_id).

'use client';

import { useEffect, useMemo, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
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

// ============================================================
// Types
// ============================================================

type Pipeline = { id: string; code: string; name: string; description: string | null };
type Stage = { id: string; code: string; name: string; sort_order: number };
type RoundOption = { id: string; name: string };
type Deal = {
  id: string;
  deal_name: string;
  current_stage_id: string;
  value_amount: number | null;
  value_currency: string;
  last_activity_at: string | null;
  status: string;
  primary_contact_id: string | null;
  party: { id: string; party_name: string; country_code: string | null } | null;
  round: { id: string; name: string } | null;
};

interface Props {
  pipeline: Pipeline;
  stages: Stage[];
  deals: Deal[];
  /** Investor pipeline only; [] elsewhere. */
  rounds: RoundOption[];
}

// ============================================================
// Formatters
// ============================================================

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

// ============================================================
// Component
// ============================================================

export function KanbanClient({ pipeline, stages, deals, rounds }: Props) {
  const router = useRouter();

  // Optimistic state for drag moves
  const [optimisticDeals, setOptimisticDeals] = useState<Deal[]>(deals);
  const [activeDealId, setActiveDealId] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  // Round filter ('all' | round id). Only used on the Investor board.
  const [roundFilter, setRoundFilter] = useState<string>('all');

  // Modal state
  const [modalOpen, setModalOpen] = useState(false);

  const showRounds = pipeline.code === 'investor' && rounds.length > 0;

  // Resync when server data refreshes (after revalidatePath)
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

  const handleDragEnd = (event: DragEndEvent) => {
    setActiveDealId(null);
    const { active, over } = event;
    if (!over) return;

    const dealId = String(active.id);
    const newStageId = String(over.id);

    const current = optimisticDeals.find((d) => d.id === dealId);
    if (!current || current.current_stage_id === newStageId) return;

    const previousStageId = current.current_stage_id;

    setOptimisticDeals((prev) =>
      prev.map((d) =>
        d.id === dealId ? { ...d, current_stage_id: newStageId } : d
      )
    );

    startTransition(async () => {
      const result = await moveDealStage(dealId, newStageId, pipeline.code);
      if (!result.ok) {
        console.error('Failed to move deal:', result.error);
        setOptimisticDeals((prev) =>
          prev.map((d) =>
            d.id === dealId ? { ...d, current_stage_id: previousStageId } : d
          )
        );
      }
    });
  };

  // Apply the round filter before bucketing.
  const visibleDeals = useMemo(() => {
    if (roundFilter === 'all') return optimisticDeals;
    return optimisticDeals.filter((d) => d.round?.id === roundFilter);
  }, [optimisticDeals, roundFilter]);

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
      for (const d of ds) {
        if (d.value_amount != null) {
          sums[d.value_currency] = (sums[d.value_currency] ?? 0) + d.value_amount;
        }
      }
      return { stage: s, deals: ds, count: ds.length, sums };
    });
  }, [stages, visibleDeals]);

  const totalValue: Record<string, number> = {};
  for (const d of visibleDeals) {
    if (d.value_amount != null) {
      totalValue[d.value_currency] = (totalValue[d.value_currency] ?? 0) + d.value_amount;
    }
  }

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
          <div className="flex-1 overflow-x-auto overflow-y-hidden bg-muted/30">
            {stages.length === 0 ? (
              <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                No stages configured for this pipeline.
              </div>
            ) : (
              <div className="flex h-full min-w-max gap-3 p-4">
                {stageBuckets.map(({ stage, deals: stageDeals, count, sums }) => (
                  <DroppableColumn
                    key={stage.id}
                    stage={stage}
                    count={count}
                    sums={sums}
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

function DroppableColumn({
  stage,
  count,
  sums,
  children,
}: {
  stage: Stage;
  count: number;
  sums: Record<string, number>;
  children: React.ReactNode;
}) {
  const { setNodeRef, isOver } = useDroppable({ id: stage.id });

  return (
    <div
      ref={setNodeRef}
      className={cn(
        'flex w-72 shrink-0 flex-col rounded-lg border bg-card transition-colors',
        isOver && 'border-foreground/40 bg-card/80 ring-2 ring-foreground/10'
      )}
    >
      <div className="border-b px-3 py-2">
        <div className="flex items-baseline justify-between">
          <span className="truncate text-sm font-medium text-foreground">
            {stage.name}
          </span>
          <span className="ml-2 tabular-nums text-xs text-muted-foreground">
            {count}
          </span>
        </div>
        {Object.keys(sums).length > 0 ? (
          <div className="mt-0.5 text-[11px] text-muted-foreground">
            {Object.entries(sums)
              .map(([cur, sum]) => fmtMoney(sum, cur))
              .join(' \u00b7 ')}
          </div>
        ) : null}
      </div>

      <div className="scrollbar-thin flex-1 space-y-2 overflow-y-auto p-2">
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
      {deal.party ? (
        <div className="mt-1.5 line-clamp-1 text-xs text-muted-foreground">
          {deal.party.party_name}
          {deal.party.country_code ? (
            <span className="ml-1 opacity-60">{'\u00b7'} {deal.party.country_code}</span>
          ) : null}
        </div>
      ) : null}
      {deal.round ? (
        <div className="mt-1.5">
          <span className="inline-flex items-center rounded bg-primary/10 px-1.5 py-0.5 text-[10px] font-medium text-primary">
            {deal.round.name}
          </span>
        </div>
      ) : null}
      <div className="mt-2 flex items-center justify-between text-xs">
        <span className="font-medium tabular-nums text-foreground">
          {fmtMoney(deal.value_amount, deal.value_currency)}
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
