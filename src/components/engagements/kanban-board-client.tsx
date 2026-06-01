'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core';
import { useTranslations } from 'next-intl';
import { toast } from 'sonner';
import { KanbanColumn } from './kanban-column';
import { KanbanCardComponent } from './kanban-card';
import { moveEngagementStage } from '@/lib/actions/engagements';
import type { KanbanBoard, KanbanCard, KanbanStage } from '@/types/engagement';

interface Props {
  board: KanbanBoard;
}

export function KanbanBoardClient({ board }: Props) {
  const router = useRouter();
  const t = useTranslations('engagements');
  const [isPending, startTransition] = useTransition();

  // Optimistic state - update card positions ahead of the Server Action response.
  // syncs when the board prop changes after router.refresh.
  const [optimisticCardsByStage, setOptimisticCardsByStage] = useState<
    Record<string, KanbanCard[]>
  >(board.cardsByStage);
  const [activeCard, setActiveCard] = useState<KanbanCard | null>(null);

  useEffect(() => {
    setOptimisticCardsByStage(board.cardsByStage);
  }, [board.cardsByStage]);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 6 },
    }),
  );

  const handleDragStart = (e: DragStartEvent) => {
    const card = e.active.data.current?.card as KanbanCard | undefined;
    setActiveCard(card ?? null);
  };

  const handleDragEnd = (e: DragEndEvent) => {
    setActiveCard(null);
    const { active, over } = e;
    if (!over) return;

    const card = active.data.current?.card as KanbanCard | undefined;
    const targetStage = over.data.current?.stage as KanbanStage | undefined;
    if (!card || !targetStage) return;
    if (card.currentStageId === targetStage.id) return;

    // Optimistic - update the UI immediately
    setOptimisticCardsByStage((prev) => {
      const next: Record<string, KanbanCard[]> = {};
      for (const stageId of Object.keys(prev)) {
        next[stageId] = (prev[stageId] ?? []).filter((c) => c.id !== card.id);
      }
      const updatedCard: KanbanCard = {
        ...card,
        currentStageId: targetStage.id,
      };
      next[targetStage.id] = [updatedCard, ...(next[targetStage.id] ?? [])];
      return next;
    });

    // Server Action - on failure, toast + revert
    startTransition(async () => {
      const result = await moveEngagementStage({
        engagementId: card.id,
        toStageId: targetStage.id,
      });
      if (!result.ok) {
        toast.error(result.errorMessage ?? 'Move failed');
        setOptimisticCardsByStage(board.cardsByStage);
      } else {
        if (targetStage.isWon) {
          toast.success(t('toast.movedToWon', { name: card.name }));
        } else if (targetStage.isLost) {
          toast.info(t('toast.movedToLost', { name: card.name }));
        }
        router.refresh();
      }
    });
  };

  return (
    <DndContext
      sensors={sensors}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div
        className="flex gap-3 overflow-x-auto p-4 h-full scrollbar-thin"
        aria-busy={isPending}
      >
        {board.stages.map((stage) => (
          <KanbanColumn
            key={stage.id}
            stage={stage}
            cards={optimisticCardsByStage[stage.id] ?? []}
            draggingCardId={activeCard?.id ?? null}
          />
        ))}

        {board.uncategorizedCards.length > 0 && (
          <UncategorizedColumn cards={board.uncategorizedCards} />
        )}
      </div>

      <DragOverlay>
        {activeCard ? <KanbanCardComponent card={activeCard} asOverlay /> : null}
      </DragOverlay>
    </DndContext>
  );
}

function UncategorizedColumn({ cards }: { cards: readonly KanbanCard[] }) {
  const t = useTranslations('engagements');
  return (
    <div className="flex flex-col w-72 shrink-0 rounded-lg bg-muted/20 border border-dashed">
      <header className="px-3 py-2 border-b">
        <h3 className="font-medium text-sm text-muted-foreground">
          {t('uncategorized')}
        </h3>
        <p className="text-xs text-muted-foreground">{cards.length}</p>
      </header>
      <div className="flex-1 overflow-y-auto p-2 space-y-2 scrollbar-thin">
        {cards.map((c) => (
          <KanbanCardComponent key={c.id} card={c} />
        ))}
      </div>
    </div>
  );
}
