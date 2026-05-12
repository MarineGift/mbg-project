/**
 * components/common/module-badge.tsx
 *
 * 7개 모듈에 대한 시각적 식별 배지. 어디서든 행을 모듈별로 구분할 때 사용.
 */

'use client';

import { useTranslations } from 'next-intl';
import type { ModuleType } from '@/types/ai';
import { cn } from '@/lib/utils';

interface ModuleBadgeProps {
  module: ModuleType;
  size?: 'sm' | 'md';
  className?: string;
}

const MODULE_STYLES: Record<ModuleType, string> = {
  investor: 'bg-module-investor text-module-investor-foreground',
  buyer: 'bg-module-buyer text-module-buyer-foreground',
  partner: 'bg-module-partner text-module-partner-foreground',
  customer: 'bg-module-customer text-module-customer-foreground',
  crowdfunding: 'bg-module-crowdfunding text-module-crowdfunding-foreground',
  product_launch: 'bg-module-product_launch text-module-product_launch-foreground',
  sales: 'bg-module-sales text-module-sales-foreground',
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
