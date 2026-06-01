'use client';

import { useDroppable } from '@dnd-kit/core';
import { useTranslations } from 'next-intl';
import { Trophy, X } from 'lucide-react';
import { KanbanCardComponent } from './kanban-card';
import type { KanbanCard, KanbanStage } from '@/types/engagement';
import { cn } from '@/lib/utils';

interface Props {
  stage: KanbanStage;
  cards: readonly KanbanCard[];
  /** id of the card being dragged (for optimistic display after drop) */
  draggingCardId?: string | null;
}

export function KanbanColumn({ stage, cards, draggingCardId }: Props) {
  const t = useTranslations('engagements');
  const droppable = useDroppable({
    id: stage.id,
    data: { stage },
  });

  const totalValue = cards.reduce(
    (sum, c) => sum + (c.weightedAmount ?? c.valueAmount ?? 0),
    0,
  );

  const stageStyle = stage.colorHex
    ? { borderTopColor: stage.colorHex }
    : undefined;

  const stageIcon = stage.isWon ? (
    <Trophy className="h-3.5 w-3.5 text-emerald-600" />
  ) : stage.isLost ? (
    <X className="h-3.5 w-3.5 text-muted-foreground" />
  ) : null;

  return (
    <div
      ref={droppable.setNodeRef}
      className={cn(
        'flex flex-col w-72 shrink-0 rounded-lg bg-muted/40 border-t-2 transition-colors',
        droppable.isOver && 'bg-accent/40 outline outline-2 outline-primary/40',
      )}
      style={stageStyle}
    >
      <header className="px-3 py-2 border-b">
        <div className="flex items-center gap-2 mb-0.5">
          {stageIcon}
          <h3 className="font-medium text-sm truncate flex-1">{stage.name}</h3>
          <span className="text-xs text-muted-foreground tabular-nums">
            {cards.length}
          </span>
        </div>
        {totalValue > 0 && (
          <p className="text-xs text-muted-foreground tabular-nums">
            {t('weightedSum', { value: Math.round(totalValue).toLocaleString() })}
          </p>
        )}
      </header>

      <div className="flex-1 overflow-y-auto p-2 space-y-2 scrollbar-thin">
        {cards.length === 0 ? (
          <p className="text-xs text-muted-foreground italic text-center py-6">
            {t('emptyStage')}
          </p>
        ) : (
          cards.map((card) => (
            <KanbanCardComponent
              key={card.id}
              card={card}
              isDragging={card.id === draggingCardId}
            />
          ))
        )}
      </div>
    </div>
  );
}
