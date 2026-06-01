/**
 * components/common/relative-time.tsx
 *
 * Displays time relatively ("just now", "3 hours ago", "yesterday", etc.).
 * The absolute time is shown in a tooltip.
 */

'use client';

import { useEffect, useState } from 'react';
import { useLocale } from 'next-intl';
import { formatDistanceToNow, format } from 'date-fns';
import { enUS, ko, ja } from 'date-fns/locale';
import type { Locale as DateLocale } from 'date-fns';
import type { Locale } from '@/i18n/routing';

interface RelativeTimeProps {
  /** ISO 8601 string or Date */
  date: string | Date;
  /** auto-refresh every minute (default true) */
  live?: boolean;
  className?: string;
}

const LOCALE_MAP: Record<Locale, DateLocale> = {
  ko,
  en: enUS,
  ja,
};

export function RelativeTime({ date, live = true, className }: RelativeTimeProps) {
  const localeCode = useLocale() as Locale;
  const dateLocale = LOCALE_MAP[localeCode] ?? enUS;
  const target = typeof date === 'string' ? new Date(date) : date;

  // re-render every minute (only when live=true)
  const [, setTick] = useState(0);
  useEffect(() => {
    if (!live) return;
    const id = setInterval(() => setTick((t) => t + 1), 60_000);
    return () => clearInterval(id);
  }, [live]);

  if (!Number.isFinite(target.getTime())) {
    return <span className={className}>—</span>;
  }

  const relative = formatDistanceToNow(target, {
    addSuffix: true,
    locale: dateLocale,
  });
  const absolute = format(target, 'PPp', { locale: dateLocale });

  return (
    <time
      dateTime={target.toISOString()}
      title={absolute}
      className={className}
    >
      {relative}
    </time>
  );
}
