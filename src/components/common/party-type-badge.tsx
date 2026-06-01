/**
 * components/common/party-type-badge.tsx
 *
 * Visual identifier badge for the 7 modules. Used anywhere to distinguish rows by module.
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
  government_grant: 'bg-gray-100 text-gray-700',  // standard tailwind colors; a module-filler token can be added later
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
