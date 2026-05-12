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
 * 만료 시각까지 남은 시간을 사람 친화적으로 표시.
 *   - 이미 만료: "만료됨" + 빨강
 *   - 오늘 만료: "오늘 만료" + 빨강
 *   - 24시간 이내: "N시간 남음" + 주황
 *   - 그 외: "N일 남음" + 회색
 *
 * 매 분마다 자동 갱신.
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
      // 1시간 이내
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
