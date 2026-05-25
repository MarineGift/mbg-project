'use client';

import Link from 'next/link';
import { useDraggable } from '@dnd-kit/core';
import { CSS } from '@dnd-kit/utilities';
import { Calendar, DollarSign, GripVertical } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Card, CardContent } from '@/components/ui/card';
import { RelativeTime } from '@/components/common/relative-time';
import type { KanbanCard as KanbanCardType } from '@/types/engagement';
import { cn } from '@/lib/utils';

interface Props {
  card: KanbanCardType;
  isDragging?: boolean;
  /** drag overlay 모드일 때 true (Server Action 호출 중 등) */
  asOverlay?: boolean;
}

export function KanbanCardComponent({ card, isDragging, asOverlay }: Props) {
  const t = useTranslations('engagements.card');
  const draggable = useDraggable({
    id: card.id,
    data: { card },
    disabled: asOverlay,
  });

  const style = asOverlay
    ? undefined
    : {
        transform: CSS.Translate.toString(draggable.transform),
        opacity: draggable.isDragging || isDragging ? 0.4 : 1,
      };

  // 만료 임박 체크
  const isCloseSoon =
    card.expectedCloseDate != null &&
    new Date(card.expectedCloseDate).getTime() - Date.now() < 7 * 24 * 60 * 60 * 1000;

  return (
    <Card
      ref={asOverlay ? undefined : draggable.setNodeRef}
      style={style}
      className={cn(
        'cursor-grab active:cursor-grabbing transition-shadow hover:shadow-md',
        asOverlay && 'rotate-2 shadow-xl ring-2 ring-primary/30',
      )}
      {...(asOverlay ? {} : { ...draggable.attributes, ...draggable.listeners })}
    >
      <CardContent className="p-3 space-y-1.5">
        <div className="flex items-start gap-1">
          <GripVertical className="h-3 w-3 text-muted-foreground mt-0.5 shrink-0 opacity-50" />
          <div className="flex-1 min-w-0">
            <Link
              href={`/engagements/${card.id}`}
              className="font-medium text-sm hover:underline block truncate"
              // drag 시 클릭 방지
              onClick={(e) => {
                if (draggable.isDragging) e.preventDefault();
              }}
              onPointerDown={(e) => e.stopPropagation()}
            >
              {card.name}
            </Link>
            <Link
              href={`/${card.partyType}/parties/${card.partyId}`}
              className="text-xs text-muted-foreground hover:underline truncate block"
              onPointerDown={(e) => e.stopPropagation()}
            >
              {card.partyName}
            </Link>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs pl-4">
          {card.valueAmount != null && (
            <span className="inline-flex items-center gap-1 text-muted-foreground tabular-nums">
              <DollarSign className="h-3 w-3" />
              {card.valueCurrency} {card.valueAmount.toLocaleString()}
            </span>
          )}
          {card.probabilityPct > 0 && (
            <span className="text-muted-foreground tabular-nums">
              {card.probabilityPct}%
            </span>
          )}
          {card.expectedCloseDate && (
            <span
              className={cn(
                'inline-flex items-center gap-1',
                isCloseSoon ? 'text-orange-600 dark:text-orange-400' : 'text-muted-foreground',
              )}
            >
              <Calendar className="h-3 w-3" />
              {new Date(card.expectedCloseDate).toLocaleDateString()}
            </span>
          )}
        </div>

        <RelativeTime
          date={card.updatedAt}
          live={false}
          className="text-[10px] text-muted-foreground pl-4 block"
        />

        {/* 사용 안 함 회피 */}
        <span hidden>{t('open')}</span>
      </CardContent>
    </Card>
  );
}
