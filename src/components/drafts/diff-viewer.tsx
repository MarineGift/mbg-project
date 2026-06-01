'use client';

import { useMemo } from 'react';
import { diffLines, type Change } from 'diff';
import { cn } from '@/lib/utils';

interface Props {
  original: string;
  edited: string;
  className?: string;
}

/**
 * Shows a line diff between the original AI output and the user's edited version.
 * - added: green background
 * - removed: red background (strikethrough)
 * - unchanged: gray
 */
export function DiffViewer({ original, edited, className }: Props) {
  const parts = useMemo(() => diffLines(original, edited), [original, edited]);

  const hasChanges = parts.some((p) => p.added || p.removed);

  if (!hasChanges) {
    return (
      <div
        className={cn(
          'rounded-md border bg-muted/30 p-3 text-xs text-muted-foreground',
          className,
        )}
      >
        No changes from AI original.
      </div>
    );
  }

  return (
    <div
      className={cn(
        'rounded-md border bg-background overflow-hidden text-sm font-mono leading-relaxed',
        className,
      )}
    >
      <pre className="p-3 whitespace-pre-wrap max-h-[280px] overflow-y-auto scrollbar-thin">
        {parts.map((part: Change, idx) =>
          part.added ? (
            <span
              key={idx}
              className="bg-emerald-100 text-emerald-900 dark:bg-emerald-950 dark:text-emerald-100 block"
            >
              + {part.value}
            </span>
          ) : part.removed ? (
            <span
              key={idx}
              className="bg-red-100 text-red-900 dark:bg-red-950 dark:text-red-100 line-through block"
            >
              − {part.value}
            </span>
          ) : (
            <span key={idx} className="text-muted-foreground block">
              {part.value}
            </span>
          ),
        )}
      </pre>
    </div>
  );
}
