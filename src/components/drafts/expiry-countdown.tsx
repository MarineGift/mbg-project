'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Clock, AlertTriangle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ExpiryCountdownProps {
  expiresAt: string; // ISO 8601
  className?: string;
}

/**
 * Displays the time left until expiry in a human-friendly way.
 *   - already expired: "Expired" + red
 *   - expires today: "Expires today" + red
 *   - within 24 hours: "N hours left" + orange
 *   - otherwise: "N days left" + gray
 *
 * Auto-refreshes every minute.
 */
export function ExpiryCountdown({ expiresAt, className }: ExpiryCountdownProps) {
  const t = useTranslations('drafts.expiry');
  const [, setTick] = useState(0);

  useEffect(() => {
    const id = setInterval(() => setTick((n) => n + 1), 60_000);
    return () => clearInterval(id);
  }, []);

  const target = new Date(expiresAt);
  if (!Number.isFinite(target.getTime())) {
    return <span className={className}>—</span>;
  }

  const now = Date.now();
  const diffMs = target.getTime() - now;
  const diffMin = diffMs / 60_000;
  const diffHours = diffMs / (60 * 60_000);
  const diffDays = diffMs / (24 * 60 * 60_000);

  let label: string;
  let tone: 'expired' | 'today' | 'soon' | 'normal';
  let icon = <Clock className="h-3 w-3" />;

  if (diffMs <= 0) {
    label = t('expired');
    tone = 'expired';
    icon = <AlertTriangle className="h-3 w-3" />;
  } else if (diffDays < 1) {
    if (diffHours < 1) {
      // within 1 hour
      label = t('hoursLeft', { hours: 1 });
      tone = 'soon';
    } else {
      label = t('hoursLeft', { hours: Math.floor(diffHours) });
      tone = diffHours < 6 ? 'soon' : 'today';
    }
    if (Math.floor(diffHours) === 0 && diffMin < 60) {
      label = t('today');
      tone = 'today';
    }
  } else {
    label = t('daysLeft', { days: Math.floor(diffDays) });
    tone = diffDays < 2 ? 'today' : 'normal';
  }

  const toneCls: Record<typeof tone, string> = {
    expired: 'text-destructive',
    today: 'text-orange-600 dark:text-orange-400',
    soon: 'text-orange-600 dark:text-orange-400',
    normal: 'text-muted-foreground',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 text-xs',
        toneCls[tone],
        className,
      )}
      title={target.toLocaleString()}
    >
      {icon}
      {label}
    </span>
  );
}
