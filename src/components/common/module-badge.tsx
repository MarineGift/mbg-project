/**
 * components/common/module-badge.tsx
 *
 * 7개 모듈에 대한 시각적 식별 배지. 어디서든 행을 모듈별로 구분할 때 사용.
 */

'use client';

import { useTranslations } from 'next-intl';
import type { PartyTypeCode } from '@/types/ai';
import { cn } from '@/lib/utils';

interface ModuleBadgeProps {
  partyType: PartyTypeCode;
  size?: 'sm' | 'md';
  className?: string;
}

const MODULE_STYLES: Record<PartyTypeCode, string> = {
  investor: 'bg-module-investor text-module-investor-foreground',
  paper_mill: 'bg-module-buyer text-module-buyer-foreground',
  partner: 'bg-module-partner text-module-partner-foreground',
  customer: 'bg-module-customer text-module-customer-foreground',
  filler_supplier: 'bg-amber-100 text-amber-700',  // tailwind 표준 색상; 추후 module-filler 토큰 추가 가능
};

export function ModuleBadge({
  module,
  size = 'md',
  className,
}: ModuleBadgeProps) {
  const t = useTranslations('modules');
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full font-medium',
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm',
        MODULE_STYLES[module],
        className,
      )}
    >
      {t(module)}
    </span>
  );
}
