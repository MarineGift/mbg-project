'use client';

import { AlertTriangle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface RiskFlagChipProps {
  flag: string;
  className?: string;
}

/**
 * AI 분류 결과의 risk_flags 배열을 시각적 칩으로 표시.
 * 예: ['price_topic', 'legal_topic', 'urgency_high']
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
 * 'price_topic' → 'Price Topic' 형태로 변환.
 * 향후 i18n 번역 시 namespace 'riskFlags' 추가 가능.
 */
function humanize(flag: string): string {
  return flag
    .split('_')
    .map((s) => (s.length > 0 ? s[0]!.toUpperCase() + s.slice(1) : s))
    .join(' ');
}
