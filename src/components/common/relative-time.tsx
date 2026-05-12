/**
 * components/common/relative-time.tsx
 *
 * 시간을 상대적으로 표시 ("방금 전", "3시간 전", "어제" 등).
 * 절대 시간은 tooltip에 표시.
 */

'use client';

import { useEffect, useState } from 'react';
import { useLocale } from 'next-intl';
import { formatDistanceToNow, format } from 'date-fns';
import { enUS, ko, ja } from 'date-fns/locale';
import type { Locale as DateLocale } from 'date-fns';
import type { Locale } from '@/i18n/routing';

interface RelativeTimeProps {
  /** ISO 8601 문자열 또는 Date */
  date: string | Date;
  /** 1분마다 자동 갱신 (기본 true) */
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

  // 매 분마다 재렌더 (live=true일 때만)
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
