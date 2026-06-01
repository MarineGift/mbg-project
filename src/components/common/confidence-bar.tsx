'use client';

import { useTranslations } from 'next-intl';
import { cn } from '@/lib/utils';

interface ConfidenceBarProps {
  /** between 0 and 1 */
  value: number;
  showLabel?: boolean;
  showValue?: boolean;
  className?: string;
}

/**
 * Confidence thresholds:
 *   - low:    < 0.7
 *   - medium: 0.7 ~ 0.9
 *   - high:   ≥ 0.9
 */
function classify(value: number): 'low' | 'medium' | 'high' {
  if (value < 0.7) return 'low';
  if (value < 0.9) return 'medium';
  return 'high';
}

const TIER_BG: Record<ReturnType<typeof classify>, string> = {
  low: 'bg-confidence-low',
  medium: 'bg-confidence-medium',
  high: 'bg-confidence-high',
};

const TIER_TEXT: Record<ReturnType<typeof classify>, string> = {
  low: 'text-confidence-low',
  medium: 'text-confidence-medium',
  high: 'text-confidence-high',
};

export function ConfidenceBar({
  value,
  showLabel = false,
  showValue = true,
  className,
}: ConfidenceBarProps) {
  const t = useTranslations('confidence');
  // safely handle negatives and values over 1
  const v = Math.max(0, Math.min(1, value));
  const tier = classify(v);

  return (
    <div className={cn('flex items-center gap-2 min-w-[80px]', className)}>
      <div className="flex-1 h-1.5 bg-muted rounded-full overflow-hidden">
        <div
          className={cn('h-full transition-all', TIER_BG[tier])}
          style={{ width: `${(v * 100).toFixed(0)}%` }}
        />
      </div>
      {showValue && (
        <span className={cn('text-xs font-medium tabular-nums', TIER_TEXT[tier])}>
          {(v * 100).toFixed(0)}%
        </span>
      )}
      {showLabel && (
        <span className={cn('text-xs', TIER_TEXT[tier])}>{t(tier)}</span>
      )}
    </div>
  );
}
