'use client';

import { AlertTriangle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface RiskFlagChipProps {
  flag: string;
  className?: string;
}

/**
 * Displays the risk_flags array from the AI classification result as visual chips.
 * e.g. ['price_topic', 'legal_topic', 'urgency_high']
 */
export function RiskFlagChip({ flag, className }: RiskFlagChipProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full bg-risk/10 px-2 py-0.5 text-xs font-medium text-risk',
        className,
      )}
    >
      <AlertTriangle className="h-3 w-3" />
      {humanize(flag)}
    </span>
  );
}

/**
 * Converts 'price_topic' -> 'Price Topic' form.
 * A 'riskFlags' namespace can be added for future i18n translation.
 */
function humanize(flag: string): string {
  return flag
    .split('_')
    .map((s) => (s.length > 0 ? s[0]!.toUpperCase() + s.slice(1) : s))
    .join(' ');
}
