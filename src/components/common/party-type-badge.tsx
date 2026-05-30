/**
 * components/common/party-type-badge.tsx
 *
 * 7개 모듈에 대한 시각적 식별 배지. 어디서든 행을 모듈별로 구분할 때 사용.
 */

'use client';

import { useTranslations } from 'next-intl';
import type { PartyTypeCode } from '@/types/ai';
import { cn } from '@/lib/utils';

interface PartyTypeBadgeProps {
  partyType: PartyTypeCode;
  size?: 'sm' | 'md';
  className?: string;
}

const PARTY_TYPE_STYLES: Record<PartyTypeCode, string> = {
  investor: 'bg-party-investor text-party-investor-foreground',
  paper_mill: 'bg-party-buyer text-party-buyer-foreground',
  partner: 'bg-party-partner text-party-partner-foreground',
  customer: 'bg-party-customer text-party-customer-foreground',
  filler_supplier: 'bg-amber-100 text-amber-700',
  buyer: 'bg-yellow-100 text-yellow-700',
  government_grant: 'bg-gray-100 text-gray-700',  // tailwind 표준 색상; 추후 module-filler 토큰 추가 가능
};

export function PartyTypeBadge({
  partyType,
  size = 'md',
  className,
}: PartyTypeBadgeProps) {
  const t = useTranslations('partyTypes');
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full font-medium',
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm',
        PARTY_TYPE_STYLES[partyType],
        className,
      )}
    >
      {t(partyType)}
    </span>
  );
}
