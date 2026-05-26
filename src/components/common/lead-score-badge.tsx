/**
 * components/common/lead-score-badge.tsx
 *
 * Lead score visualization badge. Score range 0-100, color-coded by tier.
 */
'use client';
import { cn } from '@/lib/utils';

interface LeadScoreBadgeProps {
  score: number | null | undefined;
  size?: 'sm' | 'md';
  className?: string;
}

function getScoreStyle(score: number): string {
  if (score >= 80) return 'bg-emerald-100 text-emerald-700';
  if (score >= 60) return 'bg-lime-100 text-lime-700';
  if (score >= 40) return 'bg-amber-100 text-amber-700';
  if (score >= 20) return 'bg-orange-100 text-orange-700';
  return 'bg-rose-100 text-rose-700';
}

export function LeadScoreBadge({
  score,
  size = 'md',
  className,
}: LeadScoreBadgeProps) {
  if (score === null || score === undefined) {
    return (
      <span
        className={cn(
          'inline-flex items-center rounded-full font-medium bg-gray-100 text-gray-500',
          size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm',
          className,
        )}
      >
        —
      </span>
    );
  }

  const rounded = Math.round(score);
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full font-medium',
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm',
        getScoreStyle(rounded),
        className,
      )}
    >
      {rounded}
    </span>
  );
}