'use client';

import { useTranslations } from 'next-intl';
import type { DraftStatus } from '@/types/ai';
import { cn } from '@/lib/utils';

interface StatusBadgeProps {
  status: DraftStatus;
  size?: 'sm' | 'md';
  className?: string;
}

const STATUS_STYLES: Record<DraftStatus, string> = {
  pending_review: 'bg-status-pending_review text-white',
  approved: 'bg-status-approved text-white',
  sent: 'bg-status-sent text-white',
  rejected: 'bg-status-rejected text-white',
  expired: 'bg-status-expired text-white',
  auto_sent: 'bg-status-auto_sent text-white',
};

export function StatusBadge({
  status,
  size = 'md',
  className,
}: StatusBadgeProps) {
  const t = useTranslations('draftStatus');
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full font-medium',
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm',
        STATUS_STYLES[status],
        className,
      )}
    >
      {t(status)}
    </span>
  );
}
