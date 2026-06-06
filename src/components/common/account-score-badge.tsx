/**
 * components/common/account-score-badge.tsx
 *
 * ABM account-score badge: an A/B/C tier chip (color-coded) followed by the
 * 0..100 score. Distinct from the legacy LeadScoreBadge (which shows a bare
 * 0..100 number from module_data) so other pages that still use LeadScoreBadge
 * are unaffected.
 *
 *   A  -> emerald   (score >= 60)
 *   B  -> amber     (30..59)
 *   C  -> slate     (< 30)
 */
'use client';
import { cn } from '@/lib/utils';

export type AccountTier = 'A' | 'B' | 'C';

interface AccountScoreBadgeProps {
  score: number | null | undefined;
  tier: AccountTier | null | undefined;
  size?: 'sm' | 'md';
  className?: string;
}

const TIER_STYLE: Record<AccountTier, string> = {
  A: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300',
  B: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
  C: 'bg-slate-100 text-slate-600 dark:bg-slate-800/50 dark:text-slate-300',
};

export function AccountScoreBadge({
  score,
  tier,
  size = 'md',
  className,
}: AccountScoreBadgeProps) {
  const pad = size === 'sm' ? 'px-1.5 py-0.5 text-xs' : 'px-2 py-0.5 text-sm';

  // Unscored account -> neutral dash chip.
  if (score === null || score === undefined || !tier) {
    return (
      <span
        className={cn(
          'inline-flex items-center rounded-full font-medium bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-500',
          pad,
          className,
        )}
      >
        &mdash;
      </span>
    );
  }

  const rounded = Math.round(score);
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full font-semibold tabular-nums',
        pad,
        TIER_STYLE[tier],
        className,
      )}
      title={`Tier ${tier} \u00b7 score ${rounded}`}
    >
      <span>{tier}</span>
      <span className="font-medium opacity-80">{rounded}</span>
    </span>
  );
}
