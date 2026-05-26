// src/components/inbox/tracking-badge.tsx
'use client';

import { Eye, MousePointer, Clock, Send } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { cn } from '@/lib/utils';

interface TrackingBadgeProps {
  openCount: number;
  clickCount: number;
  firstOpenedAt?: string | null;
  /** If true, renders compact (icon only + count) — for table rows */
  compact?: boolean;
  className?: string;
}

export function TrackingBadge({
  openCount,
  clickCount,
  firstOpenedAt,
  compact = false,
  className,
}: TrackingBadgeProps) {
  const notOpened = openCount === 0 && clickCount === 0;

  if (notOpened) {
    return (
      <span
        className={cn(
          'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium',
          'bg-muted/60 text-muted-foreground',
          className
        )}
      >
        <Send className="h-3 w-3" />
        {!compact && 'Sent'}
      </span>
    );
  }

  return (
    <span className={cn('inline-flex items-center gap-1.5', className)}>
      {openCount > 0 && (
        <span
          title={
            firstOpenedAt
              ? `First opened ${formatDistanceToNow(new Date(firstOpenedAt), { addSuffix: true })}`
              : `Opened ${openCount}×`
          }
          className={cn(
            'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium',
            'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
          )}
        >
          <Eye className="h-3 w-3" />
          {openCount}
        </span>
      )}
      {clickCount > 0 && (
        <span
          title={`${clickCount} link click${clickCount !== 1 ? 's' : ''}`}
          className={cn(
            'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium',
            'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
          )}
        >
          <MousePointer className="h-3 w-3" />
          {clickCount}
        </span>
      )}
    </span>
  );
}

/** Loading skeleton for TrackingBadge */
export function TrackingBadgeSkeleton() {
  return (
    <span className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs bg-muted/40 text-transparent animate-pulse w-12">
      ----
    </span>
  );
}
